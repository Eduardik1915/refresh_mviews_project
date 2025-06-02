CREATE OR REPLACE PROCEDURE EDUARDS.run_mview_refresh_queue AS 
	l_mview_name mview_refresh_queue.mview_name%TYPE := NULL;
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

        END;

        BEGIN
            dbms_output.put_line ('refresing: ' || l_mview_name);
            --dbms_mview.refresh(l_mview_name, METHOD => 'C', ATOMIC_REFRESH => FALSE);
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