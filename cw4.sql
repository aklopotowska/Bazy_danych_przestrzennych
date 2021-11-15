CREATE DATABASE cw4db;
CREATE EXTENSION postgis;

CREATE TABLE obiekty
(
	obiekt_id SERIAL PRIMARY KEY,
	geom GEOMETRY,
	nazwa NAME
);

INSERT INTO obiekty(geom, nazwa) 
VALUES(ST_GeomFromEWKT('COMPOUNDCURVE(LINESTRING(0 1, 1 1),
					   CIRCULARSTRING(1 1, 2 0, 3 1, 4 2, 5 1),LINESTRING(5 1, 6 1))') , 'obiekt1');

INSERT INTO obiekty(geom, nazwa) 
VALUES(ST_GeomFromEWKT('CURVEPOLYGON(COMPOUNDCURVE(LINESTRING(10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2, 12 0, 10 2),
					   LINESTRING(10 2, 10 6)), CIRCULARSTRING(11 2, 13 2, 11 2))') , 'obiekt2');
					   
INSERT INTO obiekty(geom, nazwa) 
VALUES(ST_GeomFromEWKT('MULTILINESTRING((7 15, 10 17, 12 13, 7 15))') , 'obiekt3');

INSERT INTO obiekty(geom, nazwa) 
VALUES(ST_GeomFromEWKT('MULTILINESTRING((20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5))') , 'obiekt4');

INSERT INTO obiekty(geom, nazwa) 
VALUES(ST_GeomFromEWKT('MULTIPOINT(30 30 59, 38 32 234)') , 'obiekt5');

INSERT INTO obiekty(geom, nazwa) 
VALUES(ST_GeomFromEWKT('GEOMETRYCOLLECTION(POINT(4 2), LINESTRING(1 1, 3 2))') , 'obiekt6');

--SELECT * FROM obiekty;

--1. Wyznacz pole powierzchni bufora o wielkości 5 jednostek, 
--	 który został utworzony wokół najkrótszej linii łączącej obiekty 3 i 4.

SELECT ST_Area(ST_Buffer(ST_ShortestLine(a.geom, b.geom), 5)) 
FROM obiekty a, obiekty b  WHERE a.nazwa = 'obiekt3' AND b.nazwa = 'obiekt4';

--2. Zamień obiekt 4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te warunki.

SELECT ST_MakePolygon(ST_LineMerge(ST_CollectionExtract(ST_Collect(a.geom, 'LINESTRING(20.5 19.5 , 20 20)'), 2)))
FROM obiekty a WHERE a.nazwa = 'obiekt4';

--3. W tabeli obiekty jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4.

INSERT INTO obiekty(geom, nazwa) 
VALUES((SELECT ST_Collect(a.geom, b.geom) 
		FROM obiekty a, obiekty b 
		WHERE a.nazwa = 'obiekt3' AND b.nazwa = 'obiekt4'),'obiekt7');

--4. Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek,
--   które zostały utworzone wokół obiektów nie posiadających łuków.

SELECT ST_Area(ST_Buffer(geom, 5)), nazwa FROM obiekty WHERE ST_HasArc(geom) = 'False';


