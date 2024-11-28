# Library Management System 
Using SQL Server Management Studio

## Project Overview

**Project Title**: Library Management System  
**Level**: Intermediate  
**Database**: `library_db`

This project demonstrates the implementation of a Library Management System using SQL. It includes creating and managing tables, performing CRUD operations, and executing advanced SQL queries. The goal is to showcase skills in database design, manipulation, and querying.

## Objectives

1. **Set up the Library Management System Database**: Create and populate the database with tables for branches, employees, members, books, issued status, and return status.
2. **CRUD Operations**: Perform Create, Read, Update, and Delete operations on the data.
3. **CTAS (Create Table As Select)**: Utilize CTAS to create new tables based on query results.
4. **Advanced SQL Queries**: Develop complex queries to analyze and retrieve specific data.

## Project Structure

### 1. Database Setup
![ERD](https://github.com/tiffanyrambi/Library-System-Management-/blob/main/LMS%20ERD.png)

- **Database Creation**: Created a database named `Library_Management_System`.
- **Table Creation**: Created tables for branches, employees, members, books, issued status, and return status. Each table includes relevant columns and relationships.

```sql
-- Creating Tables
DROP TABLE IF EXISTS branch 
CREATE TABLE branch
(	
	branch_id VARCHAR(25) PRIMARY KEY,
	manager_id VARCHAR(10),
	branch_address VARCHAR(55),
	contact_no VARCHAR(10)
)

ALTER TABLE branch
ALTER COLUMN contact_no VARCHAR(20)

DROP TABLE IF EXISTS employees;
CREATE TABLE employees
(	
	emp_id VARCHAR(10) PRIMARY KEY,
	emp_name VARCHAR(25),
	position VARCHAR(15),
	salary INT,
	branch_id VARCHAR(25) --FK
);

DROP TABLE IF EXISTS books;
CREATE TABLE books
(
	isbn VARCHAR(20) PRIMARY KEY,
	book_title VARCHAR(75) ,
	category VARCHAR(10),
	rental FLOAT,
	status VARCHAR(15),
	author VARCHAR(35),
	publisher varchar(55)
);

ALTER TABLE books
ALTER COLUMN category VARCHAR(20)

DROP TABLE IF EXISTS members;
CREATE TABLE members
(	
	member_id VARCHAR(10) PRIMARY KEY,
	member_name VARCHAR(25),
	member_address VARCHAR(75),
	reg_date DATE
);

DROP TABLE IF EXISTS issued_status;
CREATE TABLE issued_status
(	
	issued_id VARCHAR(10) PRIMARY KEY,
	issued_member_id VARCHAR(10), --FK
	issued_book_name VARCHAR(75), 
	issued_date DATE,
	issued_book_isbn VARCHAR(20), --FK
	issued_emp_id VARCHAR(10), --FK
);

DROP TABLE IF EXISTS return_status;
CREATE TABLE return_status
(	
	return_id VARCHAR(10) PRIMARY KEY,
	issued_id VARCHAR(10), --FK
	return_book_name VARCHAR(75),
	return_date DATE,
	return_book_isbn VARCHAR(20)
);

-- ADDING CONSTRAINTS
ALTER TABLE issued_status 
ADD CONSTRAINT fk_members
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id);

ALTER TABLE issued_status 
ADD CONSTRAINT fk_books
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn);

ALTER TABLE issued_status 
ADD CONSTRAINT fk_employees
FOREIGN KEY (issued_emp_id)
REFERENCES employees(emp_id);

ALTER TABLE employees 
ADD CONSTRAINT fk_branch
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id);

ALTER TABLE return_status 
ADD CONSTRAINT fk_issued_status
FOREIGN KEY (issued_id)
REFERENCES issued_status(issued_id);
```

### 2. CRUD Operations

- **Create**: Inserted sample records into the `books` table.
- **Read**: Retrieved and displayed data from various tables.
- **Update**: Updated records in the `employees` table.
- **Delete**: Removed records from the `members` table as needed.

**Task 1. Create a New Book Record**
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

```sql
INSERT INTO books (isbn, book_title, category, rental, status, author, publisher) 
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
```

**Task 2: Update an Existing Member's Address**

```sql
UPDATE members
SET member_address = '456 Back St'
WHERE member_id = 'C101'
```

**Task 3: Delete a Record from the Issued Status Table**
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

```sql
DELETE FROM issued_status
WHERE issued_id = 'IS121'
```

**Task 4: Retrieve All Books Issued by a Specific Employee**
-- Objective: Select all books issued by the employee with emp_id = 'E101'.
```sql
SELECT * FROM issued_status
WHERE issued_emp_id = 'E101'
```

**Task 5: List Members Who Have Issued More Than One Book**
-- Objective: Use GROUP BY to find members who have issued more than one book.

```sql
SELECT 
	issued_member_id, 
	COUNT(*) AS issued_times 
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(*) > 1
```

### 3. CTAS (Create Table As Select)

- **Task 6: Create Summary Tables**: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

```sql
SELECT 
	b.isbn, 
	b.book_title, 
	COUNT(ist.issued_id) no_issued
INTO book_counts
FROM books b
JOIN issued_status ist
ON b.isbn = ist.issued_book_isbn
GROUP BY b.isbn, b.book_title
```

### 4. Data Analysis & Findings

The following SQL queries were used to address specific questions:

Task 7. **Retrieve All Books in a Specific Category**:

```sql
SELECT * FROM books
WHERE category = 'Fantasy'
```

8. **Task 8: Find Total Rental Income by Category**:

```sql
SELECT	
	b.category, 
	SUM(b.rental) AS total_rent_by_category
FROM books b
JOIN issued_status ist
ON b.isbn = ist.issued_book_isbn
GROUP BY b.category
```

9. **List Members Who Registered in the Last 180 Days**:
```sql
SELECT * FROM members
WHERE DATEDIFF(DAY, reg_date, GETDATE()) <= 180
```

10. **List Employees with Their Branch Manager's Name and their branch details**:

```sql
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
```

Task 11. **Create a Table of Books with Rental Price Above a Certain Threshold**:
```sql
SELECT * 
INTO cheap_books
FROM books
WHERE rental < 4
```

Task 12: **Retrieve the List of Books Not Yet Returned**
```sql
SELECT
  *
FROM issued_status i
LEFT JOIN return_status r
ON i.issued_id = r.issued_id
WHERE r.return_id IS NUL
```

## Advanced SQL Operations

**Task 13: Identify Members with Overdue Books**  
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue.

```sql
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
```

**Task 14: Update Book Status on Return**  
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).

```sql 
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
```

**Task 15: Branch Performance Report**  
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from book rentals.

```sql
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
```

**Task 16: CTAS: Create a Table of Active Members**  
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.

```sql
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
```


**Task 17: Find Employees with the Most Book Issues Processed**  
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.

```sql
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
```

**Task 18: Identify Members Issuing High-Risk Books**  
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. Display the member name, book title, and the number of times they've issued damaged books.    


**Task 19: Stored Procedure**
Objective:
Create a stored procedure to manage the status of books in a library system.
Description:
Write a stored procedure that updates the status of a book in the library based on its issuance. The procedure should function as follows:
The stored procedure should take the book_id as an input parameter.
The procedure should first check if the book is available (status = 'yes').
If the book is available, it should be issued, and the status in the books table should be updated to 'no'.
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.

```sql
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
```

**Task 20: Create Table As Select (CTAS)**
Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include:
    The number of overdue books.
    The total fines, with each day's fine calculated at $0.50.
    The number of books issued by each member.
    The resulting table should show:
    Member ID
    Number of overdue books
    Total fines

```sql
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
```


## Reports

- **Database Schema**: Detailed table structures and relationships.
- **Data Analysis**: Insights into book categories, employee salaries, member registration trends, and issued books.
- **Summary Reports**: Aggregated data on high-demand books and employee performance.

## Conclusion

This project demonstrates the application of SQL skills in creating and managing a library management system. It includes database setup, data manipulation, and advanced querying, providing a solid foundation for data management and analysis.
