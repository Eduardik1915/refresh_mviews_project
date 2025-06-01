CREATE OR REPLACE procedure run_mview_refresh_queue AS
    l_mview_name mview_refresh_queue.mview_name%TYPE;
BEGIN
    LOOP

        BEGIN
	        SELECT mview_name
	        INTO l_mview_name
	        FROM
	           (SELECT mrq.mview_name
	            FROM mview_refresh_queue mrq
	            WHERE mrq.status = 'ready'
	            AND NOT EXISTS (
	                SELECT 1
	                FROM mview_refresh_queue mv
	                JOIN mview_dependency_map mdm
	                ON mv.mview_name = mdm.depends_on
	                WHERE mdm.mview_name = mrq.mview_name
	                AND mv.status != 'done'
	            )
	            ORDER BY mrq.priority)
	            WHERE rownum = 1
	            FOR UPDATE SKIP LOCKED;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EXIT;
        END;

        UPDATE mview_refresh_queue
        SET status = 'in progress'
        WHERE mview_name = l_mview_name;

        COMMIT;

        BEGIN
            dbms_mview.refresh(l_mview_name, METHOD => 'C', ATOMIC_REFRESH => FALSE);

            UPDATE mview_refresh_queue
            SET status = 'done'
            WHERE mview_name = l_mview_name;
        
        EXCEPTION
            WHEN OTHERS THEN
                UPDATE mview_refresh_queue
                SET status = 'error'
                WHERE mview_name = l_mview_name;
        END;

        COMMIT;
    END LOOP;
END;
     