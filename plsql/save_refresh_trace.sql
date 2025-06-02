CREATE OR REPLACE PROCEDURE save_refresh_trace(
    p_mview_name VARCHAR2,
    p_status     VARCHAR2,
    p_message    VARCHAR2,
    p_log_time   DATE := SYSDATE
)
AS
BEGIN
    INSERT INTO mview_refresh_log (mview_name, status, message, log_time)
    VALUES (p_mview_name, p_status, p_message, p_log_time);

    COMMIT;
END;