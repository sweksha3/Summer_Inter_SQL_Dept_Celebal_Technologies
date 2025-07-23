CREATE DATABASE Employee;
USE Employee;
Go

-- Create Employee_Master Teable and Insert value into the table
CREATE TABLE Employee_Master(
	EmployeeID VARCHAR(5) PRIMARY KEY, 
	ReportingTo NVARCHAR(50), 
	EmailID NVARCHAR(50));

INSERT INTO Employee_Master (EmployeeID, ReportingTo, EmailID) VALUES
('H1', NULL, 'john.doe@example.com'),
('H2', NULL, 'jane.smith@example.com'),
('H3', 'John Smith H1', 'alice.jones@example.com'),
('H4', 'Jane Doe H1', 'bob.white@example.com'),
('H5', 'John Smith H3', 'charlie.brown@example.com'),
('H6', 'Jane Doe H3', 'david.green@example.com'),
('H7', 'John Smith H4', 'emily.gray@example.com'),
('H8', 'Jane Doe H4', 'frank.wilson@example.com'),
('H9', 'John Smith H5', 'george.harris@example.com'),
('H10', 'Jane Doe H5', 'hannah.taylor@example.com'),
('H11', 'John Smith H6', 'irene.martin@example.com'),
('H12', 'Jane Doe H6', 'jack.roberts@example.com'),
('H13', 'John Smith H7', 'kate.evans@example.com'),
('H14', 'Jane Doe H7', 'laura.hall@example.com'),
('H15', 'John Smith H8', 'mike.anderson@example.com'),
('H16', 'Jane Doe H8', 'natalie.clark@example.com'),
('H17', 'John Smith H9', 'oliver.davis@example.com'),
('H18', 'Jane Doe H9', 'peter.edwards@example.com'),
('H19', 'John Smith H10', 'quinn.fisher@example.com'),
('H20', 'Jane Doe H10', 'rachel.garcia@example.com'),
('H21', 'John Smith H11', 'sarah.hernandez@example.com'),
('H22', 'Jane Doe H11', 'thomas.lee@example.com'),
('H23', 'John Smith H12', 'ursula.lopez@example.com'),
('H24', 'Jane Doe H12', 'victor.martinez@example.com'),
('H25', 'John Smith H13', 'william.nguyen@example.com'),
('H26', 'Jane Doe H13', 'xavier.ortiz@example.com'),
('H27', 'John Smith H14', 'yvonne.perez@example.com'),
('H28', 'Jane Doe H14', 'zoe.quinn@example.com'),
('H29', 'John Smith H15', 'adam.robinson@example.com'),
('H30', 'Jane Doe H15', 'barbara.smith@example.com');

SELECT * FROM Employee_Master;
Go

-- Create Employee_Hierarchy Table
CREATE TABLE Employee_Hierarchy(
	EmployeeID VARCHAR(5),
	ReportingTo NVARCHAR(50),
	EmailID NVARCHAR(50),
	Level INT,
	FirstName NVARCHAR(50),
	LastName NVARCHAR(50));
Go

-- Function to Extract First Name
CREATE FUNCTION dbo.FirstName(@EmailID NVARCHAR(50))
RETURNS NVARCHAR(50)
AS
BEGIN
	RETURN LEFT(@EmailID, CHARINDEX('.', @EmailID) - 1)
END
Go

-- Function to Extract Last Name
CREATE FUNCTION dbo.LastName(@EmailID NVARCHAR(50))
RETURNS NVARCHAR(50)
AS
BEGIN
	RETURN LEFT(
		SUBSTRING(@EmailID, CHARINDEX('.', @EmailID) + 1, LEN(@EmailID)),
		CHARINDEX('@', @EmailID) - CHARINDEX('.', @EmailID) - 1)
END
Go

-- Stored Procedure
CREATE PROCEDURE SP_employee_hierarchy
AS
BEGIN
	
	TRUNCATE TABLE Employee_Hierarchy;   -- Truncate the Employee_Hierarchy table

	WITH RecursiveCTE AS(    -- To calculate levels
		SELECT
			EmployeeID,
			ReportingTo,
			EmailID, 
			1 AS Level,
			CONCAT(dbo.FirstName(EmailID), ' ', dbo.LastName(EmailID), ' ', EmployeeID) AS IdentityKey
		FROM Employee_Master
		WHERE ReportingTo IS NULL

		UNION ALL

		SELECT e.EmployeeID, e.ReportingTo, e.EmailID, r.Level + 1,
		CONCAT(dbo.FirstName(e.EmailID), ' ', dbo.LastName(e.EmailID), ' ', e.EmployeeID)
		FROM Employee_Master e
		INNER JOIN RecursiveCTE r
		ON e.ReportingTo = r.IdentityKey
	)

	-- Insert data into Employee_Hierarchy table
	INSERT INTO Employee_Hierarchy (EmployeeID, ReportingTo, EmailID, Level, FirstName, LastName)
	SELECT
		r.EmployeeID,
		r.ReportingTo,
		r.EmailID,
		r.Level,
		dbo.FirstName(r.EmailID),
		dbo.LastName(r.EmailID)
	FROM RecursiveCTE r
	OPTION (MAXRECURSION 1000)
END
Go

EXEC SP_employee_hierarchy;
SELECT * FROM Employee_Hierarchy;