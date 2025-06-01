CREATE TABLE mview_dependency_map (
    mview_name VARCHAR2(100),
    depends_on VARCHAR2(100),
    CONSTRAINT fk_dep_mview FOREIGN KEY (mview_name) REFERENCES mview_refresh_queue(mview_name),
    CONSTRAINT fk_dep_depends_on FOREIGN KEY (depends_on) REFERENCES mview_refresh_queue(mview_name)
)