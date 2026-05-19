--Problem 1
BEGIN TRAN
USE movies

INSERT INTO MOVIESTAR(NAME, GENDER)
VALUES ('Bruce Willis', 'M')
GO

CREATE TRIGGER tr1
ON MOVIE
AFTER INSERT
AS
	INSERT INTO STARSIN
	SELECT TITLE, YEAR, 'Bruce Willis'
	FROM inserted
	WHERE TITLE LIKE '%save%' AND TITLE LIKE '%world%'
GO

CREATE TRIGGER tr2
ON MOVIEEXEC
AFTER INSERT, UPDATE, DELETE
AS
	IF (SELECT AVG(NETWORTH) FROM MOVIEEXEC) < 500000
	BEGIN
		DELETE FROM MOVIEEXEC
		WHERE CERT# IN (SELECT CERT# FROM inserted)

		INSERT INTO MOVIEEXEC
		SELECT * FROM deleted

		RAISERROR('Average networth cannot be less than 500 000!', 15, 1)
	END
GO

CREATE OR ALTER TRIGGER tr3
ON MOVIEEXEC
INSTEAD OF DELETE
AS
	UPDATE MOVIE
	SET PRODUCERC# = NULL
	WHERE PRODUCERC# IN (SELECT CERT# FROM deleted)

	DELETE FROM MOVIEEXEC
	WHERE CERT# IN (SELECT CERT# FROM deleted)
GO

DROP TRIGGER tr1
GO

CREATE OR ALTER TRIGGER tr4
ON STARSIN
INSTEAD OF INSERT
AS
	INSERT INTO MOVIE(TITLE, YEAR)
	SELECT MOVIETITLE, MOVIEYEAR
	FROM inserted
	WHERE (SELECT COUNT(*) FROM MOVIE WHERE TITLE = MOVIETITLE AND YEAR = MOVIEYEAR) = 0
	
	INSERT INTO MOVIESTAR(NAME)
	SELECT STARNAME
	FROM inserted
	WHERE STARNAME NOT IN (SELECT NAME FROM MOVIESTAR)

	INSERT INTO STARSIN
	SELECT * FROM inserted
GO

DROP TRIGGER tr2
DROP TRIGGER tr3
DROP TRIGGER tr4
ROLLBACK

--Problem 2
USE pc
BEGIN TRAN
GO

CREATE TRIGGER tr5
ON laptop
AFTER DELETE
AS
	INSERT INTO pc
	SELECT code + 100, '1121', speed, ram, hd, '52x', price
	FROM deleted
GO

CREATE TRIGGER tr6
ON pc
INSTEAD OF UPDATE
AS
	IF UPDATE(code) 
    BEGIN
        RAISERROR('ERROR: You are not allowed to update the code. Update cancelled.', 10, 2)
		RETURN
    END

	DELETE FROM pc
	WHERE code IN (
		SELECT code 
		FROM inserted i
		WHERE price <= ALL(SELECT price FROM pc WHERE pc.speed = i.speed)
			AND price <= ALL(SELECT price FROM inserted i2 WHERE i2.speed = i.speed)
	)

	INSERT INTO pc
	SELECT *
	FROM inserted i
	WHERE price <= ALL(SELECT price FROM pc WHERE pc.speed = i.speed)
		AND price <= ALL(SELECT price FROM inserted i2 WHERE i2.speed = i.speed)
GO

CREATE TRIGGER tr7
ON product
INSTEAD OF INSERT, UPDATE
AS
	IF UPDATE(model) 
    BEGIN
        RAISERROR('ERROR: You are not allowed to update the model. Update cancelled.', 16, 2)
		RETURN
    END

	IF EXISTS(
		SELECT *
		FROM inserted i1
		JOIN inserted i2 ON i1.maker = i2.maker
		WHERE (i1.type = 'PC' AND i1.type = 'Printer') OR (i2.type = 'PC' AND i1.type = 'Printer')
	) OR EXISTS (
		SELECT *
		FROM inserted i
		JOIN product p ON p.maker = i.maker
		WHERE (i.type = 'PC' AND p.type = 'Printer') OR (p.type = 'PC' AND i.type = 'Printer')
	)
	BEGIN
		RAISERROR('A maker cannot be producing both PCs and printers!', 16, 3)
		RETURN
	END

	DELETE FROM product
	WHERE model IN (SELECT model FROM deleted)

	INSERT INTO product
	SELECT * FROM inserted
GO

CREATE TRIGGER tr8pc
ON pc
INSTEAD OF INSERT, UPDATE
AS
	IF UPDATE(code) AND EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
    BEGIN
        RAISERROR('ERROR: You are not allowed to update the code. Update cancelled.', 16, 4)
		RETURN
    END

	IF EXISTS(
		SELECT *
		FROM inserted i
		JOIN product p1 ON i.model = p1.model
		WHERE NOT EXISTS (
			SELECT *
			FROM laptop l
			JOIN product p2 ON l.model = p2.model
			WHERE p2.maker = p1.maker AND l.speed >= i.speed
		)
	)
	BEGIN
		RAISERROR('Each pc producer must have a faster laptop', 16, 5)
		RETURN
	END

	DELETE FROM pc
	WHERE code IN (SELECT code FROM deleted)

	INSERT INTO pc
	SELECT * FROM inserted
GO

CREATE TRIGGER tr8laptop
ON laptop
INSTEAD OF UPDATE, DELETE
AS
	IF UPDATE(code) 
    BEGIN
        RAISERROR('ERROR: You are not allowed to update the code. Update cancelled.', 16, 6)
		RETURN
    END

	IF EXISTS(
		SELECT *
		FROM pc
		JOIN product p ON pc.model = p.model
		WHERE NOT EXISTS(
			SELECT *
			FROM (
				(SELECT *
				FROM laptop
				WHERE code NOT IN (SELECT code FROM deleted))
				UNION
				(SELECT * FROM inserted)
			) AS l
			JOIN product p2 ON l.model = p2.model
			WHERE p2.maker = p.maker AND l.speed >= pc.speed
		)
	)
	BEGIN
		RAISERROR('Each pc producer must have a faster laptop', 16, 7)
		RETURN
	END

	DELETE FROM laptop
	WHERE code IN (SELECT code FROM deleted)

	INSERT INTO laptop
	SELECT * FROM inserted
GO

CREATE TRIGGER tr8product
ON product
INSTEAD OF UPDATE, DELETE
AS
BEGIN
	IF UPDATE(model) 
    BEGIN
        RAISERROR('ERROR: You are not allowed to update the model. Update cancelled.', 16, 8)
		RETURN
    END

	IF EXISTS(
		SELECT *
		FROM pc
		JOIN ((SELECT *
			FROM product
			WHERE model NOT IN (SELECT model FROM deleted))
			UNION
			(SELECT * FROM inserted)
		) AS p ON pc.model = p.model
		WHERE NOT EXISTS(
			SELECT *
			FROM laptop l
			JOIN ((SELECT *
				FROM product
				WHERE model NOT IN (SELECT model FROM deleted))
				UNION
				(SELECT * FROM inserted)
			) AS p2 ON l.model = p2.model
			WHERE p2.maker = p.maker AND l.speed >= pc.speed
		)
	)
	BEGIN
		RAISERROR('Each pc producer must have a faster laptop', 16, 9)
		RETURN
	END

	DELETE FROM product
	WHERE model IN (SELECT model FROM deleted)

	INSERT INTO product
	SELECT * FROM inserted
END
GO

CREATE TRIGGER tr9
ON laptop
INSTEAD OF INSERT, UPDATE, DELETE
AS
	IF UPDATE(code) AND EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
    BEGIN
        RAISERROR('ERROR: You are not allowed to update the code. Update cancelled.', 16, 10)
		RETURN
    END

	IF EXISTS(
		SELECT maker
		FROM ((SELECT *
			FROM laptop
			WHERE code NOT IN (SELECT code FROM deleted))
			UNION ALL
			(SELECT * FROM inserted)
		) AS l
		JOIN product p ON l.model = p.model
		GROUP BY maker
		HAVING AVG(price) < 2000
	)
	BEGIN
		RAISERROR('Each laptop maker should have an average price at least 2000', 16, 11)
		RETURN
	END

	DELETE FROM laptop
	WHERE code IN (SELECT code FROM deleted)

	INSERT INTO laptop
	SELECT * FROM inserted
GO

CREATE TRIGGER tr10pc
ON pc
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	IF UPDATE(code) AND EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
    BEGIN
        RAISERROR('ERROR: You are not allowed to update the code. Update cancelled.', 16, 12)
		RETURN
    END

	IF EXISTS(
		SELECT *
		FROM laptop l, ((SELECT *
			FROM pc
			WHERE code NOT IN (SELECT code FROM deleted))
			UNION 
			(SELECT * FROM inserted)
		) AS p
		WHERE l.ram > p.ram AND l.price <= p.price
	)
	BEGIN
		RAISERROR('Each laptop with more memory than a pc should be more expensive than it.', 16, 13)
		RETURN
	END

	DELETE FROM pc
	WHERE code IN (SELECT code FROM deleted)

	INSERT INTO pc
	SELECT * FROM inserted
END
GO

CREATE TRIGGER tr10laptop
ON laptop
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	IF UPDATE(code) AND EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
    BEGIN
        RAISERROR('ERROR: You are not allowed to update the code. Update cancelled.', 16, 14)
		RETURN
    END

	IF EXISTS(
		SELECT *
		FROM pc, ((SELECT *
			FROM laptop
			WHERE code NOT IN (SELECT code FROM deleted))
			UNION 
			(SELECT * FROM inserted)
		) AS l
		WHERE l.ram > pc.ram AND l.price <= pc.price
	)
	BEGIN
		RAISERROR('Each laptop with more memory than a pc should be more expensive than it.', 16, 15)
		RETURN
	END

	DELETE FROM laptop
	WHERE code IN (SELECT code FROM deleted)

	INSERT INTO laptop
	SELECT * FROM inserted
END
GO

CREATE TRIGGER tr11
ON printer
INSTEAD OF INSERT
AS
	INSERT INTO printer
	SELECT *
	FROM inserted
	WHERE color = 'n' OR type != 'Matrix'
GO

DROP TRIGGER tr5
DROP TRIGGER tr6
DROP TRIGGER tr7
DROP TRIGGER tr8pc
DROP TRIGGER tr8laptop
DROP TRIGGER tr8product
DROP TRIGGER tr9
DROP TRIGGER tr10pc
DROP TRIGGER tr10laptop
DROP TRIGGER tr11
ROLLBACK

--Problem 3
USE ships
BEGIN TRAN
GO

CREATE TRIGGER tr12
ON CLASSES
INSTEAD OF INSERT
AS
	INSERT INTO CLASSES
	SELECT CLASS, TYPE, COUNTRY, NUMGUNS, BORE, 
		CASE WHEN DISPLACEMENT > 35000 THEN 35000 ELSE DISPLACEMENT END
	FROM inserted
GO

CREATE VIEW ClassNumShips
AS
	SELECT c.CLASS, COUNT(NAME) AS ShipsCount
	FROM CLASSES c
	LEFT JOIN SHIPS s ON c.CLASS = s.CLASS
	GROUP BY c.CLASS
GO

CREATE OR ALTER TRIGGER tr13
ON ClassNumShips
INSTEAD OF DELETE
AS
BEGIN
	DELETE FROM SHIPS
	WHERE CLASS IN (SELECT CLASS FROM deleted)

	DELETE FROM CLASSES
	WHERE CLASS IN (SELECT CLASS FROM deleted)
END
GO

CREATE TRIGGER tr14
ON SHIPS
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	IF UPDATE(NAME) AND EXISTS(SELECT * FROM deleted)
	BEGIN
		RAISERROR('ERROR: You are not allowed to update the ship name. Update cancelled.', 16, 16)
		RETURN
	END

	IF EXISTS(
		SELECT c.CLASS
		FROM CLASSES c
		JOIN (
			(SELECT * 
			FROM SHIPS 
			WHERE NAME NOT IN (SELECT NAME FROM deleted))
			UNION ALL
			(SELECT * FROM inserted)
		) AS s ON c.CLASS = s.CLASS
		GROUP BY c.CLASS
		HAVING COUNT(NAME) > 2
	)
	BEGIN
		RAISERROR('Classes can not have more than 2 ships!', 16, 17)
		RETURN
	END

	DELETE FROM SHIPS
	WHERE NAME IN (SELECT NAME FROM deleted)

	INSERT INTO SHIPS
	SELECT * FROM inserted
END
GO

CREATE TRIGGER tr15
ON OUTCOMES
INSTEAD OF INSERT
AS
BEGIN
	IF EXISTS(
		SELECT i.SHIP
		FROM inserted i
		JOIN (
			(SELECT * FROM OUTCOMES)
			UNION ALL
			(SELECT * FROM inserted)
		) AS o ON i.BATTLE = o.BATTLE AND i.SHIP != o.SHIP
		JOIN SHIPS s1 ON i.SHIP = s1.NAME
		JOIN SHIPS s2 ON o.SHIP = s2.NAME
		JOIN CLASSES c1 ON s1.CLASS = c1.CLASS
		JOIN CLASSES c2 ON s2.CLASS = c2.CLASS
		WHERE (c1.NUMGUNS > 9 AND c2.NUMGUNS < 9)
			OR (c1.NUMGUNS < 9 AND c2.NUMGUNS > 9)
	)
	BEGIN
		RAISERROR('A ship with more than 9 guns can not fight a ship with less than 9 guns.', 16, 18)
		RETURN
	END

	INSERT INTO OUTCOMES
	SELECT * FROM inserted
END
GO

CREATE TRIGGER tr16o
ON OUTCOMES
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	IF (UPDATE(SHIP) OR UPDATE(BATTLE)) AND EXISTS(SELECT * FROM deleted)
	BEGIN
		RAISERROR('ERROR: You are not allowed to update the ship and battle. Update cancelled.', 16, 19)
		RETURN	
	END

	IF EXISTS(
		SELECT osunk.SHIP
		FROM (
			(SELECT * FROM OUTCOMES)
			EXCEPT
			(SELECT * FROM deleted)
			UNION ALL
			(SELECT * FROM inserted)
		) AS osunk
		JOIN (
			(SELECT * FROM OUTCOMES)
			EXCEPT
			(SELECT * FROM deleted)
			UNION ALL
			(SELECT * FROM inserted)
		) AS olater ON osunk.SHIP = olater.SHIP
		JOIN BATTLES bsunk ON bsunk.NAME = osunk.BATTLE
		JOIN BATTLES blater ON blater.NAME = olater.BATTLE
		WHERE osunk.RESULT = 'sunk' AND bsunk.DATE < blater.DATE
	)
	BEGIN
		RAISERROR('A ship can not battle after it has been sunk.', 16, 20)
		RETURN
	END

	DELETE FROM OUTCOMES
	WHERE SHIP IN (SELECT SHIP FROM deleted d WHERE d.BATTLE = OUTCOMES.BATTLE)

	INSERT INTO OUTCOMES
	SELECT * FROM inserted
END
GO

CREATE TRIGGER tr16b
ON BATTLES
INSTEAD OF INSERT, UPDATE
AS
BEGIN
	IF UPDATE(NAME) AND EXISTS(SELECT * FROM deleted)
	BEGIN
		RAISERROR('ERROR: You are not allowed to update the name. Update cancelled.', 16, 21)
		RETURN	
	END

	IF EXISTS(
		SELECT osunk.SHIP
		FROM OUTCOMES osunk
		JOIN OUTCOMES olater ON osunk.SHIP = olater.SHIP
		JOIN (
			(SELECT * FROM BATTLES)
			EXCEPT
			(SELECT * FROM deleted)
			UNION ALL
			(SELECT * FROM inserted)
		) AS bsunk ON bsunk.NAME = osunk.BATTLE
		JOIN (
			(SELECT * FROM BATTLES)
			EXCEPT
			(SELECT * FROM deleted)
			UNION ALL
			(SELECT * FROM inserted)
		) AS blater ON blater.NAME = olater.BATTLE
		WHERE osunk.RESULT = 'sunk' AND bsunk.DATE < blater.DATE
	)
	BEGIN
		RAISERROR('A ship can not battle after it has been sunk.', 16, 22)
		RETURN
	END

	DELETE FROM BATTLES
	WHERE NAME IN (SELECT NAME FROM deleted d)

	INSERT INTO BATTLES
	SELECT * FROM inserted
END
GO

DROP TRIGGER tr12
DROP TRIGGER tr13
DROP TRIGGER tr14
DROP TRIGGER tr15
DROP TRIGGER tr16o
DROP TRIGGER tr16b
ROLLBACK