CREATE TABLE refresh_mview_dependencies (
    mview_name VARCHAR2(100),
    depends_on VARCHAR2(100),
    CONSTRAINT fk_dep_mview FOREIGN KEY (mview_name) REFERENCES refresh_mview_control(mview_name),
    CONSTRAINT fk_dep_depends_on FOREIGN KEY (depends_on) REFERENCES refresh_mview_control(mview_name)
)