--Problem 1
CREATE DATABASE tests
GO
USE tests
GO

--Problem 2

CREATE TABLE Product(
	maker CHAR(1),
	model CHAR(4),
	type VARCHAR(7)
)

CREATE TABLE Printer(
	code INT,
	model CHAR(4),
	color CHAR(1) DEFAULT 'n',
	price DECIMAL(6, 2)
)

CREATE TABLE Classes(
	class VARCHAR(50),
	type CHAR(2)
)

--Problem 3

INSERT INTO Product
VALUES ('A', '1100', 'Printer')

INSERT INTO Printer
VALUES (1, '1100', 'y', 100.50)

INSERT INTO Printer(code, model)
VALUES (1, '1111')

INSERT INTO Classes
VALUES ('A', 'bb')

--Problem 4

ALTER TABLE Classes
ADD bore FLOAT

--Problem 5

ALTER TABLE Printer
DROP COLUMN price

--Problem 6

DROP TABLE Classes
DROP TABLE Printer
DROP TABLE Product

USE master
GO
DROP DATABASE tests