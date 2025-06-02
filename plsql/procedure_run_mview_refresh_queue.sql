CREATE OR REPLACE PROCEDURE run_mview_refresh_queue AS 
	l_mview_name mview_refresh_queue.mview_name%TYPE := NULL;
	l_error_count INTEGER := 0; 
	e_object_does_not_exist EXCEPTION;
	PRAGMA EXCEPTION_INIT(e_object_does_not_exist, -942);

BEGIN
    LOOP
        BEGIN
            UPDATE mview_refresh_queue mrq
            SET status = 'in progress'
            WHERE mrq.mview_name = (
                    SELECT mview_name
                    FROM (
                        SELECT mrq2.mview_name
                        FROM mview_refresh_queue mrq2
                        WHERE mrq2.status = 'ready'
                          AND NOT EXISTS (
                                SELECT 1
                                FROM mview_refresh_queue mrq3
                                JOIN mview_dependency_map mdm
                                  ON mrq3.mview_name = mdm.depends_on
                                WHERE mdm.mview_name = mrq2.mview_name
                                  AND mrq3.status != 'done'
                        )
                        ORDER BY mrq2.priority
                    )
                    WHERE ROWNUM = 1
            )
            RETURNING mview_name INTO l_mview_name;

            IF SQL%ROWCOUNT = 0 THEN
                EXIT;
            END IF;
            
            COMMIT;
            
        EXCEPTION
			WHEN OTHERS THEN
				l_error_count := l_error_count + 1;
            	IF l_error_count = 3 THEN
            		EXIT;
            	END IF;
        		 save_refresh_trace(l_mview_name, 'error', 'update status error: ' || SQLERRM);
            	CONTINUE;	
        END;  
        
        BEGIN
	       drop_indexes(l_mview_name);   
           save_refresh_trace(l_mview_name, 'in progress', 'dropped indexes and starting refresh.');
           --Placeholder: here dbms_mview.refresh would be invoked in production
           --dbms_mview.refresh(l_mview_name, METHOD => 'C', ATOMIC_REFRESH => FALSE);
           update_status(l_mview_name, 'done', 'refreshing completed.');
           create_indexes(l_mview_name);
           save_refresh_trace(l_mview_name, 'done', 'created indexes.');

        EXCEPTION
        	WHEN e_object_does_not_exist THEN
        		save_refresh_trace(l_mview_name, 'error', 'mview does not exist.');
        		update_status(l_mview_name, 'error');
            WHEN OTHERS THEN
                save_refresh_trace(l_mview_name, 'error', 'refresh error:' || SQLERRM);
        		update_status(l_mview_name, 'error');
        END;
        
        COMMIT;

    END LOOP;

END;