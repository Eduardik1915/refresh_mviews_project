CREATE OR REPLACE PROCEDURE set_mview_refresh_queue_ready AS
BEGIN
	UPDATE mview_refresh_queue
	SET status = 'ready';
	
	COMMIT;
END;