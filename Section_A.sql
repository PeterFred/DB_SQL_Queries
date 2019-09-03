--158337 Assignment Part B
--Peter Fredatovich 98141269
--Leonard Phillips 15232331


--######################################
--SECTION A
--#######################################

--a. Write a query that will list all the books with the price difference (between retail 
--and cost) of $10 or more. Display your results in the decreasing order of the price difference. (1 mark)
SELECT book_title "Book Title", book_cost "Cost", book_retail "RRP", (book_retail- book_cost) AS "Difference"
	FROM book
	WHERE (book_retail- book_cost )>= 10
	ORDER BY "Difference" DESC;

--b. Write a query that will list books in COMPUTER category along with other details (e.g. author(s), etc.). 
--The query should work for all the case-variations of category values (i.e. 'computer', 'Computer', etc.) 
--in the database. (1.5 mark)
SELECT b.book_title "Title", b.book_cost "Cost", b.book_retail "RRP", a.author_fname ||', '||  a.author_lname "Author"
	FROM bookauthor ba, book b, author a
	WHERE  b.book_isbn = ba.ba_isbn
	AND Ba.ba_authorid = a.author_id
	AND LOWER(b.book_category) = LOWER('COMPUTER')
	ORDER BY b.book_title; 

--c. Write a query that will list books that have retail price $30 or less and were published 
--in any of the years 1999 or 2001. Display results in the increasing order of the publication year 
--(and not the publication date) and decreasing retail price. Display the year of publication with 
--the column titled Publication Year. (1.5 mark)
SELECT book_title "Book Title", book_retail "RRP", book_pubdate "Publication Year"
	FROM book
	WHERE book_retail <= 30
	AND (EXTRACT(YEAR FROM book_pubdate)=1999
	OR EXTRACT(YEAR FROM book_pubdate)=2001)
	ORDER BY EXTRACT(YEAR FROM book_pubdate), "RRP" DESC;

--d. Write a query that lists both customer and author details (only their ids, first and last names). 
--Provide suitable headings for the merged list. (1.5 mark)
SELECT author_id AS "ID", author_fname ||', '|| author_lname AS "Name" FROM author
	UNION
	SELECT TO_CHAR(cust_num), cust_fname ||', '|| cust_lname FROM customer;

--e. Write a query that will list all the publishers, their details (name, etc.) and total number of published books. 
--Display your output in the decreasing order of total number of publications. (1.5 marks)
SELECT p.pub_name "Publisher Name", p.pub_contact "Contact", p.pub_phone "Phone", COUNT(b.book_pubid) AS "Published Books"
	FROM publisher p , book b
	WHERE b.book_pubid = p.pub_id
	GROUP BY p.pub_name, p.pub_contact, p.pub_phone
	ORDER BY "Published Books" DESC;

--f. Write a query that will display the states with more than one customer. 
--Display the state with maximum customers first. (2 marks)
SELECT cust_state "Customer State", COUNT(cust_state) "# of customers"
	FROM customer
	GROUP BY cust_state
	HAVING COUNT(cust_state)>1
	ORDER BY COUNT(cust_state) DESC;

--g. Write a query that will list the publisher(s) with the maximum number of published books. If there is more than 
--one publisher (e.g. 2 publishers) with maximum publications, your query should and list all (i.e. both if 2). (3 marks)
SELECT p.pub_name, COUNT(b.book_pubid)
    FROM book b, publisher p
    WHERE  b.book_pubid = p.pub_id
    GROUP BY p.pub_name
    HAVING COUNT(book_pubid)=(SELECT MAX(COUNT(book_pubid)) 
								FROM book GROUP BY book_pubid);
	
--h. Write a query that will list the customer(s) who had ordered maximum number of items (two copies of the same book 
--will be counted as two items). Again, like g) there can be more than one customer. (3 marks)
SELECT c.cust_num "Customer Number", c.cust_fname||' '|| c.cust_lname "Customer", SUM(boi.boi_qty) "Total Order Qty"
	FROM bookorder bo, customer c, bookorderitem boi
	WHERE c.cust_num = bo.bo_custnum
	AND boi.boi_ordernum = bo.bo_ordernum
	GROUP BY c.cust_num, c.cust_fname||' '|| c.cust_lname
	HAVING SUM(boi.boi_qty) = (SELECT MAX(SUM(boi.boi_qty)) 
                                FROM bookorderitem boi, customer c, bookorder bo
                                where c.cust_num = bo.bo_custnum                           
                                and boi.boi_ordernum = bo.bo_ordernum
                                GROUP BY c.cust_num);
								
--i. Write a query that will display the customer(s) that referred maximum number of customers. Again, like g) there can 
--be more than one customer. (3 marks)	
SELECT  cust_referred, COUNT(cust_referred)
	FROM customer 
	GROUP BY cust_referred
	HAVING COUNT(cust_referred)=(SELECT MAX(mycount) 
	FROM (select cust_referred, 
			COUNT(cust_referred) mycount 
			FROM customer 
			GROUP BY cust_referred));


--j. Write a query to list all the books that have multiple authors. 
--Also, display the number of authors who wrote the book. (2 marks)
SELECT b.book_title, a.author_fname ||', '|| a.author_lname "Author"
	FROM bookauthor ba, book b, author a
	WHERE b.book_isbn = ba.ba_isbn
	AND a.author_id = ba.ba_authorid
	AND ba.ba_isbn IN(
		SELECT ba_isbn
		FROM bookauthor
		GROUP BY ba_isbn
		HAVING COUNT(*)>1	)
	ORDER BY b.book_title;

