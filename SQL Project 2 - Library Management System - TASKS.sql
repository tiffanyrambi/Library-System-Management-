select * from books;
select * from branch;
select * from employees;
select * from issued_status;
select * from return_status;


-- PROJECT TASKS:
-- CRUD
-- CTA (Create Table As Select)
-- Data Analysis & Findings
-- Advanced SQL Operations


-- CRUD
--Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"
INSERT INTO books (isbn, book_title, category, rental, status, author, publisher) 
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')

--Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '456 Back St'
WHERE member_id = 'C101'

--Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.
DELETE FROM issued_status
WHERE issued_id = 'IS121'

--Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101'

--Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.
SELECT 
	issued_member_id, 
	COUNT(*) AS issued_times 
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*) > 1


-- CTA (Create Table As Select)
--Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
SELECT 
	b.isbn, 
	b.book_title, 
	COUNT(ist.issued_id) no_issued
INTO book_counts
FROM books b
JOIN issued_status ist
ON b.isbn = ist.issued_book_isbn
GROUP BY b.isbn, b.book_title
 
--Data Analysis & Findings
--Task 7. Retrieve All Books in a Specific Category:
SELECT * FROM books
WHERE category = 'Fantasy'

--Task 8: Find Total Rental Income by Category:
SELECT	
	b.category, 
	SUM(b.rental) AS total_rent_by_category
FROM books b
JOIN issued_status ist
ON b.isbn = ist.issued_book_isbn
GROUP BY b.category

--Task 9. List Members Who Registered in the Last 180 Days:
SELECT 
	*
	--DATEDIFF(day, reg_date, GETDATE()) AS days_difference
FROM members
WHERE DATEDIFF(DAY, reg_date, GETDATE()) <= 180
  
--Task 10. List Employees with Their Branch Manager's Name and their branch details:
SELECT 
	e1.emp_name,
	e1.position emp_position,
	e2.emp_name AS manager_name,
	--b.manager_id,
	b.branch_address,
	b.contact_no
FROM branch b
JOIN
employees e1
ON e1.branch_id = b.branch_id
JOIN
employees e2
ON e2.emp_id = b.manager_id

--Task 11. Create a Table of Books with Rental Price Above a Certain Threshold: 
SELECT * 
INTO cheap_books
FROM books
WHERE rental < 4

select * from cheap_books

--Task 12: Retrieve the List of Books Not Yet Returned
SELECT * FROM issued_status i
LEFT JOIN return_status r
ON i.issued_id = r.issued_id
WHERE r.return_id IS NULL


--Advanced SQL Operations

--Task 13: Identify Members with Overdue Books
--Write a query to identify members who have overdue books (assume a 60-day return period). 
--Display the member's_id, member's name, book title, issue date, and days overdue
WITH overdue_return 
AS 
(
	SELECT 
		m.member_id,
		m.member_name,
		i.issued_book_name AS book_title,
		i.issued_date,
		r.return_date,
		CASE
			WHEN r.return_date IS NOT NULL THEN DATEDIFF(DAY, i.issued_date, r.return_date) - 60
			ELSE DATEDIFF(DAY, i.issued_date, GETDATE()) - 60
		END AS days_overdue
	FROM issued_status i
	LEFT JOIN return_status r
	ON i.issued_id = r.issued_id
	JOIN members m
	ON m.member_id = i.issued_member_id
)
SELECT *
FROM overdue_return
WHERE days_overdue > 0

--Task 14: Update Book Status on Return
--Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
select * from books 
select * from return_status
select * from issued_status

GO
CREATE PROCEDURE add_return_records
    @p_return_id VARCHAR(10),
    @p_issued_id VARCHAR(10)
AS
BEGIN
    -- Declare variables for storing book details
    DECLARE 
        @v_isbn VARCHAR(50),
        @v_book_name VARCHAR(80);
    
    -- Insert the return record into the return_status table
    INSERT INTO return_status (return_id, issued_id, return_date)
    VALUES (@p_return_id, @p_issued_id, GETDATE());

    -- Select book details based on the issued_id
    SELECT 
        @v_isbn = issued_book_isbn,
        @v_book_name =  issued_book_name
    FROM issued_status
    WHERE issued_id = @p_issued_id;

    -- Update the book status to 'yes' (meaning the book has been returned)
    UPDATE books
    SET status = 'yes'
    WHERE isbn = @v_isbn;

    -- Output a message to the user
    PRINT 'Thank you for returning the book: ' + @v_book_name;
END;
GO

-- Testing FUNCTION add_return_records

--issued_id = IS135
--ISBN = WHERE isbn = '978-0-307-58837-1'

SELECT * FROM books
WHERE status ='no'

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS135';

-- calling function
EXEC add_return_records @p_return_id = 'R119', @p_issued_id = 'IS135';

UPDATE return_status
	SET return_id = 'RS119'
	WHERE return_id = 'R119';


--Task 15: Branch Performance Report
--Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, 
--and the total revenue generated from book rentals.
select * from branch
select * from issued_status
select * from return_status
select * from employees
select * from books

SELECT 
	b.branch_id,
	b.manager_id,
	COUNT(i.issued_id) num_of_issued_books,
	COUNT(r.return_id) num_of_returned_books,
	SUM(bk.rental) revenue
INTO branch_reports
FROM branch b
JOIN employees e
ON b.branch_id = e.branch_id
JOIN issued_status i
ON i.issued_emp_id = e.emp_id
LEFT JOIN return_status r
ON r.issued_id = i.issued_id
JOIN books bk
ON bk.isbn = i.issued_book_isbn
GROUP BY b.branch_id, b.manager_id

select * from branch_reports

--Task 16: CTAS: Create a Table of Active Members
--Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing 
--members who have issued at least one book in the last 2 months.
select * from issued_status
select * from members

-- update some dates (cause all the dates are over 7 months ago)
 UPDATE issued_status
  SET issued_date = '2024-10-04'
  WHERE issued_member_id = 'C106'

 UPDATE issued_status
  SET issued_date = '2024-11-04'
  WHERE issued_member_id = 'C101'

SELECT * 
INTO active_members
FROM members
WHERE member_id in (
SELECT 
	DISTINCT issued_member_id
FROM issued_status
WHERE
	DATEDIFF(MONTH, issued_date, GETDATE()) < 2
)

SELECT * FROM active_members

--Task 17: Find Employees with the Most Book Issues Processed
--Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
select * from issued_status
select * from employees

SELECT TOP 3 
	i.issued_emp_id, 
	e.emp_name,
	COUNT(*) total_book_issued,
	e.branch_id
FROM issued_status i
JOIN employees e
ON i.issued_emp_id = e.emp_id
GROUP BY e.emp_name, e.branch_id, i.issued_emp_id
ORDER BY 2 DESC

--Task 18: Identify Members Issuing High-Risk Books
--Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. 
--Display the member name, book title, and the number of times they've issued damaged books.
select * from return_status
--skipped cause no book_condition column 


--Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 
--Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
--The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
--The procedure should first check if the book is available (status = 'yes'). 
--If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
--If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
GO
CREATE PROCEDURE issue_book
	@p_issued_id VARCHAR(10),
	@p_issued_member_id VARCHAR(10),
	@p_issued_book_isbn VARCHAR(20),
    @p_issued_emp_id VARCHAR(10)
AS
BEGIN
    -- Declare variables
    DECLARE 
        @v_book_status VARCHAR(15),
		@v_book_name VARCHAR(75);
    
    -- Select book details to chech book status
	SELECT 
		@v_book_status = status,
		@v_book_name = book_title
	FROM books 
	WHERE isbn = @p_issued_book_isbn

	IF @v_book_status = 'yes'
		BEGIN
			INSERT INTO issued_status (issued_id, issued_member_id, issued_book_name, issued_date, issued_book_isbn, issued_emp_id)
			VALUES (@p_issued_id, @p_issued_member_id, @v_book_name, GETDATE(), @p_issued_book_isbn, @p_issued_emp_id);

			-- Update the book status to 'no'
			UPDATE books
			SET status = 'no'
			WHERE isbn = @p_issued_book_isbn;
		
			PRINT 'Book record added successfully for book isbn: ' + @p_issued_book_isbn;
		END
	ELSE 
		BEGIN
			PRINT 'Sorry to inform you the book you have requested is unavailable book_isbn ' + @p_issued_book_isbn;
		END
END;
GO

-- calling function -> status = yes
EXEC issue_book @p_issued_id = 'IS141', @p_issued_member_id = 'C102', @p_issued_book_isbn = '978-0-06-025492-6', @p_issued_emp_id = 'E105'

-- calling function -> status = no
EXEC issue_book @p_issued_id = 'IS142', @p_issued_member_id = 'C103', @p_issued_book_isbn = '978-0-375-41398-8', @p_issued_emp_id = 'E108'

-- check if status updated
SELECT * FROM books
WHERE isbn = '978-0-06-025492-6'
SELECT * FROM issued_status
ORDER BY issued_id

--Task 20: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
--Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. 
--The table should include: 
--The number of overdue books. 
--The total fines, with each day's fine calculated at $0.50. 
--The number of books issued by each member. 
--The resulting table should show: Member ID Number of overdue books Total fines
select * from issued_status
select * from return_status

WITH overdue_fine 
AS 
(
	select 
		i.issued_member_id,
		i.issued_id, 
		i.issued_date,
		r.return_date,
		DATEDIFF(DAY, i.issued_date, GETDATE()) - 30 AS overdue_days,
		--'$'+ CAST((DATEDIFF(DAY, i.issued_date, GETDATE()) - 30) * 0.5 AS VARCHAR(25)) AS total_fine,
		(DATEDIFF(DAY, i.issued_date, GETDATE()) - 30) * 0.5 AS total_fine,
		COUNT(*) AS num_of_book
	FROM issued_status i
	LEFT JOIN return_status r
	ON i.issued_id = r.issued_id
	GROUP BY i.issued_member_id, i.issued_id, i.issued_date, r.return_date
	HAVING return_date IS NULL
	--order by i.issued_member_id
) 
SELECT 
	issued_member_id,
	COUNT(*) AS num_of_overdue_books,
	SUM(total_fine) AS sum_fine
FROM overdue_fine
GROUP BY issued_member_id

-- just to check 
SELECT * FROM issued_status i
LEFT JOIN return_Status r
ON i.issued_id = r.issued_id
WHERE i.issued_member_id = 'C106'