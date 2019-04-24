--a. Write a query that will list all the books with the price difference (between retail 
--and cost) of $10 or more. Display your results in the decreasing order of the price difference.
-- (1 mark)
SELECT BOOK_TITLE "Book Title", BOOK_COST "Cost", BOOK_RETAIL "RRP", (BOOK_RETAIL- BOOK_COST) AS "Difference"
	FROM BOOK
	WHERE (BOOK_RETAIL- BOOK_COST )>= 10
	ORDER BY "Difference" DESC;

--b. Write a query that will list books in COMPUTER category along with other details (e.g. author(s), etc.). 
--The query should work for all the case-variations of category values (i.e. 'computer', 'Computer', etc.) 
--in the database. (1.5 mark)
SELECT B.BOOK_TITLE "Title",  A.AUTHOR_FNAME ||', '|| A.AUTHOR_LNAME "Author"
	FROM BOOKAUTHOR BA, BOOK B, AUTHOR A
	WHERE  B.BOOK_ISBN = BA.BA_ISBN
	AND BA.BA_AUTHORID = A.AUTHOR_ID
	AND LOWER(B.BOOK_CATEGORY) = LOWER('COMPUTER')
	ORDER BY B.BOOK_TITLE; 

--c. Write a query that will list books that have retail price $30 or less and were published 
--in any of the years 1999 or 2001. Display results in the increasing order of the publication year 
--(and not the publication date) and decreasing retail price. Display the year of publication with 
--the column titled Publication Year. (1.5 mark)
SELECT BOOK_TITLE "Book Title", BOOK_RETAIL "RRP", BOOK_PUBDATE "Publication Year"
	FROM BOOK
	WHERE BOOK_RETAIL <= 30
	AND
	(EXTRACT(YEAR FROM BOOK_PUBDATE)=1999
	OR EXTRACT(YEAR FROM BOOK_PUBDATE)=2001)
	ORDER BY EXTRACT(YEAR FROM BOOK_PUBDATE), "RRP" DESC;

--d. Write a query that lists both customer and author details (only their ids, first and last names). 
--Provide suitable headings for the merged list. (1.5 mark)
--################NOT FINISHED
SELECT AUTHOR_ID "Author ID", AUTHOR_FNAME ||', '|| AUTHOR_LNAME "Author", CUST_NUM "Customer Number", CUST_FNAME ||', '|| CUST_LNAME "Customer"
	FROM CUSTOMER, AUTHOR;

--Trying to list as one column, but different data types not working (CUST_NUM is NUMBER / AUTHOR_ID is VARCHAR2) 
SELECT AUTHOR_ID  + AUTHOR_FNAME AS id, AUTHOR_FNAME, 'Author' AS SOURCE
	FROM AUTHOR
	UNION ALL
	SELECT CUST_NUM + CUST_FNAME aS ID, CUST_NUM, 'Customer' AS SOURCE
	FROM CUSTOMER;

--e. Write a query that will list all the publishers, their details (name, etc.) and total number of published books. 
--Display your output in the decreasing order of total number of publications. (1.5 marks)
SELECT P.PUB_NAME "Publisher Name", P.PUB_CONTACT "Contact", P.PUB_PHONE "Phone", COUNT(B.BOOK_PUBID) AS "Published Books"
	FROM PUBLISHER P , BOOK B
	WHERE B.BOOK_PUBID = P.PUB_ID
	GROUP BY P.PUB_NAME, P.PUB_CONTACT, P.PUB_PHONE
	ORDER BY "Published Books" DESC;

--f. Write a query that will display the states with more than one customer. 
--Display the state with maximum customers first. (2 marks)
SELECT CUST_STATE "Customer State", COUNT(CUST_STATE) "# of customers"
	FROM CUSTOMER
	GROUP BY CUST_STATE
	HAVING COUNT(CUST_STATE)>1
	ORDER BY COUNT(CUST_STATE) DESC;

--g. Write a query that will list the publisher(s) with the maximum number of published books. If there is more than one publisher 
--(e.g. 2 publishers) with maximum publications, your query should and list all (i.e. both if 2). (3 marks)
--##NB Used as reference: https://stackoverflow.com/questions/1795198/sql-not-a-single-group-group-function
-- Query below lists multiple publishers if having same number of max publications
SELECT P.PUB_NAME, COUNT(B.BOOK_PUBID)
    FROM BOOK B
    JOIN PUBLISHER P ON  B.BOOK_PUBID = P.PUB_ID
    GROUP BY P.PUB_NAME
    HAVING COUNT(BOOK_PUBID)=(SELECT MAX(COUNT(BOOK_PUBID)) FROM BOOK GROUP BY BOOK_PUBID);
--##NB TESTED - WORKS FOR MULTIPLE MAX PUBLISHERS
	
--h. Write a query that will list the customer(s) who had ordered maximum number of items (two copies of the same book will be counted 
--as two items). Again, like g) there can be more than one customer. (3 marks)

--##count of books ordered by bookorder
SELECT boi.boi_ordernum "Order Num", SUM(BOI.BOI_QTY) "Order Qty"
	FROM BOOKORDERITEM BOI
	GROUP BY BOI.BOI_ORDERNUM
	ORDER BY boi.boi_ordernum;

--##Select maximum line order (max from the above)
SELECT BOI.BOI_ORDERNUM "Order Number" , SUM(BOI.BOI_QTY) "Total Items"
	FROM BOOKORDERITEM BOI
	GROUP BY BOI.BOI_ORDERNUM
	HAVING SUM(BOI.BOI_QTY) = (SELECT MAX(SUM(BOI_QTY)) from bookorderitem group by bookorderitem.boi_ordernum) 
	ORDER BY boi.boi_ordernum;

--##LIST ALL CUSTOMER TOTAL LINE ORDERS (just need to get the max from this)
SELECT C.CUST_NUM, C.CUST_FNAME||', '|| C.CUST_LNAME "Customer", SUM(BOI.BOI_QTY) "Total Order Qty"
	FROM BOOKORDER BO
	JOIN CUSTOMER C ON C.CUST_NUM = BO.BO_CUSTNUM
	JOIN BOOKORDERITEM BOI ON BOI.BOI_ORDERNUM = BO.BO_ORDERNUM
	GROUP BY C.CUST_NUM, C.CUST_FNAME||', '|| C.CUST_LNAME;

--##FINISHED QUERY ******CHECK FOR MULTIPLE ANSWERS DISPLAYING
--USING WHERE / AND RATHER THAN JOIN
SELECT C.CUST_NUM "Customer Number", C.CUST_FNAME||' '|| C.CUST_LNAME "Customer", SUM(BOI.BOI_QTY) "Total Order Qty"
	FROM BOOKORDER BO, CUSTOMER C, BOOKORDERITEM BOI
	WHERE C.CUST_NUM = BO.BO_CUSTNUM
	AND BOI.BOI_ORDERNUM = BO.BO_ORDERNUM
	GROUP BY C.CUST_NUM, C.CUST_FNAME||' '|| C.CUST_LNAME
	HAVING SUM(BOI.BOI_QTY) = (SELECT MAX(SUM(boi.BOI_QTY)) 
                                FROM BOOKORDERITEM BOI, Customer c, Bookorder bo
                                where C.CUST_NUM = BO.BO_CUSTNUM                           
                                and BOI.BOI_ORDERNUM = BO.BO_ORDERNUM
                                GROUP BY c.cust_num);
								
--## TESTED - WORKS FOR MULTIPLE CUSTOMERS WITH MAX
								
--i. Write a query that will display the customer(s) that referred maximum number of customers. Again, like g) there can 
--be more than one customer. (3 marks)
--##reference https://www.w3resource.com/sql/aggregate-functions/max-count.php
--##NOT FINISHED Need to be able to display customer details	
SELECT MAX(MYCOUNT) "Max number of referrals"
	FROM (SELECT CUST_REFERRED,COUNT(CUST_REFERRED) MYCOUNT
        FROM CUSTOMER
        GROUP BY CUST_REFERRED);

--Need to be able to display customer details	
SELECT  CUST_REFERRED, COUNT(CUST_REFERRED)
	FROM CUSTOMER 
	GROUP BY CUST_REFERRED
	HAVING COUNT(CUST_REFERRED)=(SELECT MAX(MYCOUNT) 
	FROM (select cust_referred, 
			COUNT(CUST_REFERRED) MYCOUNT 
			FROM CUSTOMER 
			GROUP BY CUST_REFERRED));


--j. Write a query to list all the books that have multiple authors. 
--Also, display the number of authors who wrote the book. (2 marks)
--reference https://stackoverflow.com/questions/16291075/oracle-duplicate-rows-based-on-a-single-column

SELECT B.BOOK_TITLE, A.AUTHOR_FNAME ||', '|| A.AUTHOR_LNAME "Author"
	FROM BOOKAUTHOR BA, BOOK B, AUTHOR A
	WHERE B.BOOK_ISBN = BA.BA_ISBN
	AND A.AUTHOR_ID = BA.BA_AUTHORID
	AND BA.BA_ISBN IN(
		SELECT BA_ISBN
		FROM BOOKAUTHOR
		GROUP BY BA_ISBN
		HAVING COUNT(*)>1
	)
	ORDER BY B.BOOK_TITLE;

--#####################################
--SECTION B
--#######################################
SET SERVEROUTPUT ON

--k
--Write two triggers - one statement level and one row level. Along with the purpose, code, display the successful creation and 
--running of the triggers in your report. Please ensure that you also display the relevant tables before and after (results of the trigger) 
--the triggers are fired. (10 marks)

--l 
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
EXECUTE InsertBookRecord(98141269, 'Database Theory123456789123456789123456789', TO_DATE('19-04-2019', 'DD-MM-YYYY'), 4, 20, 'business' );

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

--Test Code
UPDATE BOOK SET BOOK_RETAIL = BOOK_RETAIL*1.27 WHERE BOOK_ISBN = 0401140733;


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
    dbms_output.put_line(book.book_title || ','|| ' AUTHOR: '|| book.AUTHOR_FNAME || ' '||  book.AUTHOR_LNAME ||' Cost: ' || book.BOOK_COST || ' RRP: '|| book.BOOK_RETAIL);
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









--p. Write a function to format book cost, retail price to $99.99. Use this function in a SQL statement for displaying books’ 
--costs and retail prices. (2 marks)
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

