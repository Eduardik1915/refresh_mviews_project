CREATE OR REPLACE PROCEDURE update_status(p_mview_name IN VARCHAR2, p_status IN VARCHAR2, p_message IN VARCHAR2 DEFAULT NULL) AS
BEGIN
  UPDATE mview_refresh_queue SET status = p_status WHERE mview_name = p_mview_name;
  save_refresh_trace(p_mview_name, p_status, p_message);
EXCEPTION
  WHEN OTHERS THEN
    save_refresh_trace(p_mview_name, 'error', 'update_status failed: ' || SQLERRM);
END;
