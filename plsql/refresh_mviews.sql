CREATE OR REPLACE procedure refresh_mviews_procedure AS
    l_mview_name refresh_mviews.mview_name%TYPE;
BEGIN
    LOOP

        BEGIN
            SELECT rm.mview_name
            INTO l_mview_name
            FROM refresh_mviews rm
            WHERE rm.status = 'ready'
            AND NOT EXISTS (
                SELECT 1
                FROM refresh_mviews mv
                JOIN refresh_mview_dependencies mvd
                ON mv.mview_name = mvd.depends_on
                WHERE mvd.mview_name = rm.mview_name
                AND mv.status != 'done'
            )
            AND rownum = 1
            FOR UPDATE SKIP LOCKED;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EXIT;
        END;

        UPDATE refresh_mviews
        SET status = 'in progress'
        WHERE mview_name = l_mview_name;

        COMMIT;

        BEGIN
            dbms_mview.refresh(l_mview_name, METHOD => 'C', ATOMIC_REFRESH => FALSE);

            UPDATE refresh_mviews
            SET status = 'done'
            WHERE mview_name = l_mview_name;
        
        EXCEPTION
            WHEN OTHERS THEN
                UPDATE refresh_mviews
                SET status = 'error'
                WHERE mview_name = l_mview_name;
        END;

        COMMIT;
    END LOOP;
END;
     