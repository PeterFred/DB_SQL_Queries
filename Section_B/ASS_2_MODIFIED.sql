--158337 Assignment Part B
--Peter Fredatovich 98141269
--Leonard Phillips 15232331

--######################################
--SECTION B
--#######################################

SET SERVEROUTPUT ON

-- k) STATEMENT LEVEL TRIGGER This trigger logs which users inserts, updates or deletes a value in the 
-- customer table in the user_log_table. It inserts the user ID and a current datetime stamp
-- when the customer table was altered. If the customer table is altered outside of normal
-- business hours, user information is still inserted into the user_log_table and an exception is raised.
-- The business hours are all week days between 9am and 4pm.

drop table user_log_table;
--CREATE TABLE
create table user_log_table(
    user_num varchar2(60 BYTE) NOT NULL,
    user_log_date varchar2(60)
);

create or replace trigger tr_log_customer
before insert or update or delete on customer
declare
    cur_date varchar2(10) := to_char(sysdate, 'Day');
    cur_time number := to_number(to_char(sysdate, 'HH24'));
    invalid_date exception;
begin
if (cur_date != 'Sat' and cur_time >= 9) or (cur_date != 'Sun' and cur_time <= 16) then
    insert into user_log_table values(user, to_char(sysdate, 'DD-MON-YYYY HH:MM:SS'));
else
    insert into user_log_table values(user, to_char(sysdate, 'DD-MON-YYYY HH:MM:SS'));
    raise invalid_date;
end if;
exception
 when invalid_date then
    raise_application_error(-20001, 'Invalid date. Outside business hours');
end;
/

insert into customer values(1095, 'MORALES', 'BONITA', 'P.O. BOX 651', 'EASTPOINT', 'FL', '32328', NULL);
commit;


--k) ROW LEVEL TRIGGER A trigger to check an instance inserted into BOOKORDER has an order date PRIOR to todays date 
--(ie a BOOKORDER cannot be placed in the future)
create or replace TRIGGER ORDER_DATE_CHECK
BEFORE INSERT OR UPDATE ON BOOKORDER
FOR EACH ROW
DECLARE
    future_date exception;
BEGIN
    IF (:NEW.BO_ORDERDATE > SYSDATE)
    THEN RAISE future_date;
    END IF;
EXCEPTION
WHEN future_date THEN
    raise_application_error(-20090, 'The order date is after todays date');
END;
/
show error;


--Test code
insert into bookorder values(1021, 1001, TO_DATE('28-05-19', 'DD,MM,YY'), null, '95812 HIGHWAY 98**', 'EASTPOINT', 'FL', 32328);

--K) ALTERNATIVE ROW LEVEL TRIGGER
--A row-level trigger that uses a sequence to allow customers to be inserted with a null number value
create sequence seq_cust_num
    increment by 1
    start with 1
    maxvalue 1000
    nocache
    nocycle;

create or replace trigger trg_dept_add
    before insert on customer
    for each row 
    declare
    v_custr_num customer.cust_num%type;
	newCustomer exception;
begin
	IF :new.cust_num IS NULL THEN
		select seq_cust_num.NextVal
		into v_custr_num
		from dual;
		:NEW.cust_num := v_custr_num;
		END IF;
END;
/
show error;

--K) ALTERNATIVE ROW LEVEL TRIGGER Test Code
insert into customer values(null, 'AAA', 'BBBB', 'd','e','f','g',123 );


--l)
--Write a procedure to insert a new book record. The procedure should also automatically calculate the book retail value. 
--This retail is calculated as 112.5% of the book cost price plus 8.5% of the average cost price of the existing books. 
--Provide rest of the attributes’ values as input parameters. Execute your procedure to insert at least one book record. (3 marks)
create or replace PROCEDURE InsertBookRecord
(b_isbn IN VARCHAR2, b_title IN VARCHAR2, b_pubdate IN DATE, b_pubid IN NUMBER, b_cost IN NUMBER, b_category IN VARCHAR2)
IS
	b_retail NUMBER(5,2);
BEGIN
	SELECT 0.085*(AVG(BOOK_COST))
	INTO b_retail
	FROM BOOK;
	b_retail := b_retail +( 1.125*b_cost);
	
	INSERT INTO BOOK(BOOK_ISBN, BOOK_TITLE, BOOK_PUBDATE, BOOK_PUBID, BOOK_COST, BOOK_RETAIL, BOOK_CATEGORY)
	VALUES (b_isbn, b_title, b_pubdate, b_pubid, b_cost, b_retail, b_category);

EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
	dbms_output.put_line('The book ISBN: '||b_isbn||' Title: '||b_title||' already exists.');
	--BELOW EXCEPTION PROBABLY NOT REQUIRED
	WHEN OTHERS THEN
	dbms_output.put_line('Invlaid data entry. REASON: '||SQLERRM);
END;

--Test Code --FAIL - To many chars
EXECUTE InsertBookRecord(98141269, 'Database Theory123456789123456789123456789', 
	TO_DATE('19-04-2019', 'DD-MM-YYYY'), 4, 20, 'business' );

--Test Code --FAIL - ISBN already in DB
EXECUTE InsertBookRecord(98141269, 'Database Theory', TO_DATE('19-04-2019', 'DD-MM-YYYY'), 4, 20, 'business' );

--Test Code --PASS --Correctly increases RRP
EXECUTE InsertBookRecord(98141269, 'Database Theory', TO_DATE('19-04-2019', 'DD-MM-YYYY'), 4, 20, 'business' );

--m. Write a trigger that does not allow the book retail price to be updated when the increase (in retail price) is over 25%. 
--Provide test data and corresponding results to confirm that the trigger works. (4 marks)
CREATE OR REPLACE TRIGGER RETAIL_PRICE_UPDATE
BEFORE UPDATE OF BOOK_RETAIL ON BOOK
FOR EACH ROW
DECLARE
    max_price exception;
BEGIN
    IF :NEW.BOOK_RETAIL > (1.25*:OLD.BOOK_RETAIL)
    THEN
    RAISE max_price;
    END IF;
EXCEPTION
WHEN max_price THEN
    raise_application_error(-20020, 'Price increase is over 25%');
END;

--Test Code FAIL - Book retail increase over 25%
UPDATE BOOK SET BOOK_RETAIL = BOOK_RETAIL*1.27 WHERE BOOK_ISBN = 0401140733;

--Test Code PASS (up to 25% increase acceptable)
UPDATE BOOK SET BOOK_RETAIL = BOOK_RETAIL*1.25 WHERE BOOK_ISBN = 0401140733;


--n. Write a trigger that does not allow more than three author names to be associated with books under FITNESS category 
--(e.g. if a Book is added, it should only allow up to 3 book authors to be recorded in BookAuthor table for category FITNESS books). 
--Provide the appropriate test data and results. (4 marks)
--##REFERENCE https://stackoverflow.com/questions/22290933/plsql-before-insert-trigger-check-value-in-column-from-other-table-before-allo

create or replace TRIGGER MAX_3_AUTHOR_UPDATE
BEFORE INSERT OR UPDATE  ON BOOKAUTHOR--OF BA_AUTHORID ON BOOKAUTHOR
FOR EACH ROW
DECLARE
    max_3_authors EXCEPTION;
    --PRAGMA EXCEPTION_INIT(max_3_authors, -20030);
    num_authors NUMBER;
BEGIN
    SELECT COUNT(*) 
    INTO num_authors 
    FROM BOOK B, BOOKAUTHOR BA
    WHERE B.BOOK_ISBN = BA.BA_ISBN
    AND B.BOOK_CATEGORY = 'FITNESS'; 

    IF num_authors >2
    THEN
        RAISE max_3_authors;
    END IF;
EXCEPTION
WHEN max_3_authors THEN
    raise_application_error(-20030, 'Only 3 authors allowed within FITNESS category');
    END
;

--TEST CODE
INSERT INTO BOOKAUTHOR VALUES('1059831198','J100');
INSERT INTO BOOKAUTHOR VALUES('1059831198','K100');
INSERT INTO BOOKAUTHOR VALUES('1059831198','P105');

--UNDO TEST CODE
DELETE FROM BOOKAUTHOR WHERE BA_ISBN = '1059831198' AND BA_AUTHORID = 'J100';
DELETE FROM BOOKAUTHOR WHERE BA_ISBN = '1059831198' AND BA_AUTHORID = 'K100';
DELETE FROM BOOKAUTHOR WHERE BA_ISBN = '1059831198' AND BA_AUTHORID = 'P105';


--o. Write a cursor to list book authors for all the COMPUTER category books (along with their book title, cost and retail). 
--Use appropriate exception handling. (3 marks)
DECLARE 
CURSOR book_cursor IS

SELECT B.BOOK_TITLE, A.AUTHOR_FNAME, A.AUTHOR_LNAME, B.BOOK_COST, B.BOOK_RETAIL
FROM BOOK B, AUTHOR A, BOOKAUTHOR BA
WHERE B.BOOK_ISBN = BA.BA_ISBN 
AND BA.BA_AUTHORID = A.AUTHOR_ID
AND BOOK_CATEGORY = 'COMPUTER';

BEGIN
FOR book IN book_cursor
LOOP
    dbms_output.put_line(book.book_title || ','|| ' AUTHOR: '|| book.AUTHOR_FNAME || ' '||  
		book.AUTHOR_LNAME ||' Cost: ' || book.BOOK_COST || ' RRP: '|| book.BOOK_RETAIL);
    END LOOP;
EXCEPTION
    WHEN OTHERS
    THEN
        IF book_cursor%ISOPEN
        THEN CLOSE book_cursor;
        END IF;
	--CLOSE book_cursor; NOT REQUIRED
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
SELECT BOOK_TITLE "Book Title", FORMATBOOKCOST(BOOK_COST) "Book Cost", FORMATBOOKCOST(BOOK_RETAIL) "Book Retail"
FROM BOOK;

