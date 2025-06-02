CREATE OR REPLACE PROCEDURE DROP_INDEXES(mview_name VARCHAR2)
IS
BEGIN
	DBMS_OUTPUT.PUT_LINE('Drop indexes called for ' || mview_name || ' - stub, no action.');
END;