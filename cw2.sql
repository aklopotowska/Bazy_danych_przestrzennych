CREATE DATABASE spatialdb;
CREATE EXTENSION postgis;

-- 4. Wyznacz liczbę budynków (tabela: popp, atrybut: f_codedesc, reprezentowane, jako punkty) 
-- położonych w odległości mniejszej niż 1000 m od głównych rzek.
-- Budynki spełniające to kryterium zapisz do osobnej tabeli tableB.

SELECT DISTINCT popp.*
INTO "TableB"
FROM majrivers, popp
WHERE  ST_DWithin(popp.geom, majrivers.geom, 1000) AND popp.f_codedesc = 'Building';

SELECT COUNT(gid)
FROM "TableB";

-- 5. Utwórz tabelę o nazwie airportsNew. 
-- Z tabeli airports do zaimportuj nazwy lotnisk, 
-- ich geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.

SELECT name, geom, elev
INTO airportsNew
FROM airports;

--SELECT * FROM airportsNew;

-- a) Znajdź lotnisko, które położone jest najbardziej na zachód i najbardziej na wschód

-- zachód
SELECT * 
FROM airportsNew
ORDER BY ST_X(geom) LIMIT 1;

-- wschód
SELECT * 
FROM airportsNew
ORDER BY ST_X(geom) DESC LIMIT 1;

-- b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, 
-- które położone jest w punkcie środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. 
-- Lotnisko nazwij airportB. Wysokość n.p.m. przyjmij dowolną.

INSERT INTO airportsNew 
VALUES ('airportB', 
		(SELECT ST_Centroid (ST_MakeLine(
    	(SELECT geom FROM airportsNew WHERE name = 'ATKA'),
    	(SELECT geom FROM airportsNew WHERE name = 'ANNETTE ISLAND')))), 123);

-- 6. Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej 
-- linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”

SELECT ST_Area(ST_Buffer(ST_ShortestLine(IL.geom,AM.geom),1000))
FROM lakes IL, airports AM
WHERE IL.names = 'Iliamna Lake' and AM.name = 'AMBLER';

-- 7. Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów
-- reprezentujących poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).

--SELECT * FROM trees;

SELECT SUM(ST_Area(trees.geom)), trees.vegdesc
FROM trees, swamp, tundra
WHERE ST_Contains(trees.geom, swamp.geom) OR ST_Contains(trees.geom, tundra.geom)
GROUP BY trees.vegdesc;