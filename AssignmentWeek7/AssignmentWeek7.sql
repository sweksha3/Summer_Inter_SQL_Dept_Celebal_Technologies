CREATE DATABASE Hospital;
USE Hospital;
Go

-- Source Table
CREATE TABLE SourceDoctor (
    DoctorID INT,
    DoctorName VARCHAR(100),
    Specialization VARCHAR(100),
    Phone VARCHAR(15)
);

-- Target Dimension Table
CREATE TABLE DimDoctor (
    DoctorID INT,
    DoctorName VARCHAR(100),
    Specialization VARCHAR(100),
    PreviousSpecialization VARCHAR(100),
    Phone VARCHAR(15),
    EffectiveDate DATETIME,
    EndDate DATETIME,
    IsCurrent BIT
);
-- Insert into SourceDoctor
INSERT INTO SourceDoctor VALUES
(101, 'Dr. Meera Sharma', 'Cardiologist', '9876543210'),
(102, 'Dr. Ramesh Iyer', 'Neurologist', '8765432109'),
(103, 'Dr. Alok Gupta', 'Orthopedic', '7654321098'),
(104, 'Dr. Neetu Jain', 'Pediatrician', '9564781234'),
(105, 'Dr. Anil Kapoor', 'Surgeon', '9823456712');

-- Insert into DimDoctor
INSERT INTO DimDoctor VALUES
(101, 'Dr. Meera Sharma', 'General Physician', NULL, '9876543210', '2024-01-01', NULL, 1),
(102, 'Dr. Ramesh Iyer', 'Neurologist', NULL, '8765432109', '2024-01-01', NULL, 1),
(103, 'Dr. Alok Gupta', 'Physician', NULL, '7654321098', '2024-01-01', NULL, 1),
(104, 'Dr. Neetu Jain', 'Pediatrician', NULL, '9564781234', '2024-01-01', NULL, 1),
(105, 'Dr. Anil Kapoor', 'General Surgeon', NULL, '9823456712', '2024-01-01', NULL, 1);

SELECT * FROM SourceDoctor;
SELECT * FROM DimDoctor;
GO

-- Stored Procedure
-- SCD Type-0
CREATE PROCEDURE sp_SCD0_Doctor
AS
BEGIN
    PRINT 'Checking for changes that will be ignored (SCD Type 0)...';

    SELECT s.DoctorID, s.DoctorName, s.Specialization, s.Phone
    FROM SourceDoctor s
    JOIN DimDoctor d ON s.DoctorID = d.DoctorID
    WHERE 
        s.DoctorName <> d.DoctorName OR
        s.Specialization <> d.Specialization OR
        s.Phone <> d.Phone;

    PRINT 'No updates made as per SCD Type 0 (read-only records).';
END;
GO

-- SCD Type-1
CREATE PROCEDURE sp_SCD1_Doctor
AS
BEGIN
    UPDATE d
    SET 
        DoctorName = s.DoctorName,
        Specialization = s.Specialization,
        Phone = s.Phone
    FROM DimDoctor d
    JOIN SourceDoctor s ON d.DoctorID = s.DoctorID;
END;
GO

-- SCD Type-2
CREATE PROCEDURE sp_SCD2_Doctor
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE();

    UPDATE d
    SET EndDate = @Now, IsCurrent = 0
    FROM DimDoctor d
    JOIN SourceDoctor s ON d.DoctorID = s.DoctorID
    WHERE d.IsCurrent = 1 AND (
        d.DoctorName <> s.DoctorName OR
        d.Specialization <> s.Specialization OR
        d.Phone <> s.Phone
    );

    INSERT INTO DimDoctor
    (DoctorID, DoctorName, Specialization, PreviousSpecialization, Phone, EffectiveDate, EndDate, IsCurrent)
    SELECT s.DoctorID, s.DoctorName, s.Specialization, NULL, s.Phone, @Now, NULL, 1
    FROM SourceDoctor s
    WHERE EXISTS (
        SELECT 1
        FROM DimDoctor d
        WHERE d.DoctorID = s.DoctorID AND d.IsCurrent = 1 AND (
            d.DoctorName <> s.DoctorName OR
            d.Specialization <> s.Specialization OR
            d.Phone <> s.Phone
        )
    );
END;
GO

-- SCD Type-3
CREATE PROCEDURE sp_SCD3_Doctor
AS
BEGIN
    UPDATE d
    SET 
        PreviousSpecialization = d.Specialization,
        Specialization = s.Specialization
    FROM DimDoctor d
    JOIN SourceDoctor s ON d.DoctorID = s.DoctorID
    WHERE d.Specialization <> s.Specialization;
END;
GO

-- SCD Type-4 (Also create the history table before this step)
CREATE TABLE Doctor_History (
    DoctorID INT,
    DoctorName VARCHAR(100),
    Specialization VARCHAR(100),
    Phone VARCHAR(15),
    ChangeDate DATETIME
);
GO

CREATE PROCEDURE sp_SCD4_Doctor
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE();

    INSERT INTO Doctor_History
    SELECT d.DoctorID, d.DoctorName, d.Specialization, d.Phone, @Now
    FROM DimDoctor d
    JOIN SourceDoctor s ON d.DoctorID = s.DoctorID
    WHERE d.DoctorName <> s.DoctorName OR
          d.Specialization <> s.Specialization OR
          d.Phone <> s.Phone;

    UPDATE d
    SET 
        DoctorName = s.DoctorName,
        Specialization = s.Specialization,
        Phone = s.Phone
    FROM DimDoctor d
    JOIN SourceDoctor s ON d.DoctorID = s.DoctorID;
END;
GO

-- SCD Type-6
CREATE PROCEDURE sp_SCD6_Doctor
AS
BEGIN
    DECLARE @Now DATETIME = GETDATE();

    UPDATE d
    SET EndDate = @Now, IsCurrent = 0
    FROM DimDoctor d
    JOIN SourceDoctor s ON d.DoctorID = s.DoctorID
    WHERE d.IsCurrent = 1 AND (
        d.DoctorName <> s.DoctorName OR
        d.Specialization <> s.Specialization OR
        d.Phone <> s.Phone
    );

    INSERT INTO DimDoctor
    (DoctorID, DoctorName, Specialization, PreviousSpecialization, Phone, EffectiveDate, EndDate, IsCurrent)
    SELECT 
        s.DoctorID, 
        s.DoctorName, 
        s.Specialization, 
        d.Specialization, 
        s.Phone, 
        @Now, 
        NULL, 
        1
    FROM SourceDoctor s
    JOIN DimDoctor d ON s.DoctorID = d.DoctorID AND d.IsCurrent = 0
    WHERE d.DoctorName <> s.DoctorName OR
          d.Specialization <> s.Specialization OR
          d.Phone <> s.Phone;
END;
GO

EXEC sp_SCD0_Doctor;
EXEC sp_SCD1_Doctor;
EXEC sp_SCD2_Doctor;
EXEC sp_SCD3_Doctor;
EXEC sp_SCD4_Doctor;
EXEC sp_SCD6_Doctor;

SELECT * FROM DimDoctor;
SELECT * FROM Doctor_History;  
