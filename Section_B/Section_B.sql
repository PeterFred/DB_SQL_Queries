--158337 Assignment Part B
--Peter Fredatovich 98141269
--Leonard Phillips 15232331

--######################################
--SECTION B
--#######################################

SET SERVEROUTPUT ON

--K)ROW LEVEL TRIGGER
--A row-level trigger that uses a sequence to allow customers to be inserted with a null number value
--(As per the STATEMENT LEVEL TRIGGER test code)

--CREATE SEQUENCE
CREATE SEQUENCE seq_cust_num
    INCREMENT BY 1
    START WITH 1
    maxvalue 1000
    nocache
    nocycle;

CREATE OR REPLACE TRIGGER trg_dept_add
    BEFORE INSERT ON customer
    FOR EACH ROW 
    DECLARE
    v_custr_num customer.cust_num%TYPE;
BEGIN
	IF :NEW.cust_num IS NULL THEN
		SELECT seq_cust_num.NextVal
		INTO v_custr_num
		FROM dual;
		:NEW.cust_num := v_custr_num;
		END IF;
END;
/
show error;

--K) ROW LEVEL TRIGGER Test Code
INSERT INTO customer VALUES(NULL, 'DOE', 'JOHN', 'P.O BOX 1231', 'LOS ANGELES','CA','27389', 1001);
--See JPEG images for test results

-- k) STATEMENT LEVEL TRIGGER This trigger logs which users inserts, updates or deletes a value in the 
-- customer table in the user_log_table. It inserts the user ID and a current datetime stamp
-- when the customer table was altered. If the customer table is altered outside of normal
-- business hours, user information is still inserted into the user_log_table and a flag (Y) 
-- is logged in the 'USER_OUTSIDE_HOURS' column.
-- The business hours are all week days between 9am and 4pm.

DROP TABLE user_log_table; --Wouldn't be used in final version.

CREATE TABLE user_log_table(
    user_num VARCHAR2(60 BYTE) NOT NULL,
    user_log_date VARCHAR2(60),
    user_outside_hours VARCHAR2(1)
);

CREATE OR REPLACE TRIGGER tr_log_customer
BEFORE INSERT OR UPDATE OR DELETE ON customer
DECLARE
    cur_date_temp VARCHAR2(10) := TO_CHAR(SYSDATE, 'Day');--'Sunday'; Used to test (outside business hours)
	cur_date VARCHAR2(3);
    cur_time INTEGER := TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')); --2;-- Used to test (outside business hours)
BEGIN
cur_date := SUBSTR(cur_date_temp, 0, 3);
IF (cur_date != 'Sat' AND cur_date != 'Sun') AND (cur_time >= 9 AND cur_time <= 16) THEN
    INSERT INTO user_log_table VALUES(USER, TO_CHAR(SYSDATE, 'DD-MON-YYYY HH:MM:SS'), 'N');
ELSE
    INSERT INTO user_log_table VALUES(USER, TO_CHAR(SYSDATE, 'DD-MON-YYYY HH:MM:SS'), 'Y');
END IF;
END;
/
show error


--k) STATEMENT LEVEL TRIGGER Test Code (uses the sequence from above to insert null ID)
--NB variables manipulated to check validility
INSERT INTO customer VALUES(NULL, 'MORALES', 'BONITA', 'P.O. BOX 651', 'EASTPOINT', 'FL', '32328', NULL);
--See JPEG images for test results


--l)
--Write a procedure to insert a new book record. The procedure should also automatically calculate the book retail value. 
--This retail is calculated as 112.5% of the book cost price plus 8.5% of the average cost price of the existing books. 
--Provide rest of the attributes’ values as input parameters. Execute your procedure to insert at least one book record. (3 marks)
CREATE OR REPLACE PROCEDURE InsertBookRecord
(b_isbn IN VARCHAR2, b_title IN VARCHAR2, b_pubdate IN DATE, b_pubid IN NUMBER, b_cost IN NUMBER, b_category IN VARCHAR2)
IS
	b_retail NUMBER(5,2);
BEGIN
	SELECT 0.085*(AVG(book_cost))
	INTO b_retail
	FROM BOOK;
	b_retail := b_retail +( 1.125*b_cost);
	
	INSERT INTO book(book_isbn, book_title, book_pubdate, book_pubid, book_cost, book_retail, book_category)
	VALUES (b_isbn, b_title, b_pubdate, b_pubid, b_cost, b_retail, b_category);

EXCEPTION
	WHEN OTHERS THEN
	dbms_output.put_line('Invlaid data entry. REASON: '||SQLERRM);
END;
/
show error
	
--Test Code --PASS --Correctly increases RRP
EXECUTE InsertBookRecord(98141269, 'Database Theory', TO_DATE('19-04-2019', 'DD-MM-YYYY'), 4, 20, 'business' );

--m. Write a trigger that does not allow the book retail price to be updated when the increase (in retail price) is over 25%. 
--Provide test data and corresponding results to confirm that the trigger works. (4 marks)
CREATE OR REPLACE TRIGGER retail_price_update
BEFORE UPDATE OF book_retail ON book
FOR EACH ROW
DECLARE
    max_price exception;
BEGIN
    IF :NEW.book_retail > (1.25*:OLD.book_retail)
    THEN
    RAISE max_price;
    END IF;
EXCEPTION
WHEN max_price THEN
    raise_application_error(-20020, 'Price increase is over 25%');
END;
/
show error

--Test Code FAIL - Book retail increase over 25%
UPDATE book SET book_retail = book_retail*1.27 WHERE book_isbn = 0401140733;

--Test Code PASS 
UPDATE book SET book_retail = book_retail*1.2 WHERE book_isbn = 0401140733;


--n. Write a trigger that does not allow more than three author names to be associated 
--with books under FITNESS category e.g. if a Book is added, it should only allow up to 
--3 book authors to be recorded in BookAuthor table for category FITNESS books). 
--Provide the appropriate test data and results. (4 marks)

create or replace TRIGGER max_3_author_update
BEFORE INSERT OR UPDATE  ON bookauthor
FOR EACH ROW
DECLARE
    max_3_authors EXCEPTION;
    num_authors NUMBER;
BEGIN
    SELECT COUNT(*) 
    INTO num_authors 
    FROM book b, bookauthor ba
    WHERE b.book_isbn = ba.ba_isbn
    AND b.book_category = 'FITNESS'; 
    IF num_authors >2
    THEN
        RAISE max_3_authors;
    END IF;
EXCEPTION
WHEN max_3_authors THEN
    raise_application_error(-20030, 'Only 3 authors allowed within FITNESS category');
    END
;
/
show error

--TEST CODE
INSERT INTO bookauthor VALUES('1059831198','J100');
INSERT INTO bookauthor VALUES('1059831198','K100');
INSERT INTO bookauthor VALUES('1059831198','P105');

--UNDO TEST CODE
DELETE FROM bookauthor WHERE ba_isbn = '1059831198' AND ba_authorid = 'J100';
DELETE FROM bookauthor WHERE ba_isbn = '1059831198' AND ba_authorid = 'K100';
DELETE FROM bookauthor WHERE ba_isbn = '1059831198' AND ba_authorid = 'P105';


--o. Write a cursor to list book authors for all the COMPUTER category books (along with their book title, cost and retail). 
--Use appropriate exception handling. (3 marks)
DECLARE 
CURSOR book_cursor IS
	SELECT b.book_title, a.author_fname, a.author_lname, b.book_cost, b.book_retail
	FROM book b, author a, bookauthor ba
	WHERE b.book_isbn = ba.ba_isbn 
	AND ba.ba_authorid = a.author_id
	AND LOWER(book_category) = LOWER('COMPUTER');

BEGIN
FOR book IN book_cursor
LOOP
    dbms_output.put_line(book.book_title || ','|| ' Author: '|| book.author_fname || ' '||  
		book.author_lname ||' Cost: ' || book.book_cost || ' RRP: '|| book.book_retail);
    END LOOP; 
EXCEPTION
    WHEN OTHERS
    THEN
        IF book_cursor%ISOPEN
        THEN CLOSE book_cursor;
        END IF;
END;
/


--p. Write a function to format book cost, retail price to $99.99. Use this function in a SQL statement 
--for displaying books’ costs and retail prices. (2 marks)
CREATE OR REPLACE 
FUNCTION FormatBookCost(b_cost NUMBER)
RETURN VARCHAR2
IS
book_price VARCHAR2(10);
BEGIN
SELECT TO_CHAR(b_cost, '$99.99')
INTO book_price
FROM dual;
RETURN book_price;
END;

--Test code
SELECT book_title "Book Title", FormatBookCost(book_cost) "Book Cost", FormatBookCost(book_retail) "Book Retail"
FROM book;

