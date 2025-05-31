CREATE TABLE refresh_mview_control (
    mview_name VARCHAR2(100) PRIMARY KEY,
    status VARCHAR2(20) DEFAULT 'READY'
)