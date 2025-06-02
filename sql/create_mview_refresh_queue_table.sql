CREATE TABLE mview_refresh_queue (
    mview_name VARCHAR2(100) PRIMARY KEY,
    status VARCHAR2(20) DEFAULT 'ready',
    priority NUMBER(2),
    CONSTRAINT check_status_in_queue CHECK(status IN ('ready', 'in progress', 'done', 'error'))
)