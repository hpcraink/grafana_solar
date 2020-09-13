USE solardb;

set @germanyID = (select id from country where namede = 'Deutschland');

INSERT INTO address (id, poboxNr, streetAndNr, postcode, town, countryID) VALUES
    (1, '', 'Kernerweg 22/1', '73773', 'Aichwald', @germanyID),
    (2, '', 'Glockenbrunnen 4c', '78465', 'Konstanz', @germanyID),
    (3, '', 'Stittholzhof 1', '78655', 'Dunningen', @germanyID);

INSERT INTO person(id, addressID, firstname, name, gender, eMailaddress, landlineNr, mobileNr, personType) VALUES
	(1, 1, 'Rainer', 'Keller', 'male', 'rainer.keller@hs-esslingen.de', '+49 711 xxx',  '+49 172 xxx', 'admin'),
    (2, 2, 'Walter', 'Keller', 'male', 'xxx@t-online.de', '+49 7533 xxx', '+49 172 xxx', 'owner'),
    (3, 2, 'Klaus', 'Keller', 'male', 'xxx@t-online.de', '+49 7533 xxx', '+49 172 xxx', 'owner');

INSERT INTO roles (personID, role) VALUES (1, 'ADMIN');
INSERT INTO roles (personID, role) VALUES (1, 'TECHNICIAN');
INSERT INTO roles (personID, role) VALUES (1, 'OWNING_MEMBER');
INSERT INTO roles (personID, role) VALUES (2, 'OWNER');
INSERT INTO roles (personID, role) VALUES (2, 'TECHNICIAN');
INSERT INTO roles (personID, role) VALUES (3, 'TECHNICIAN');
INSERT INTO roles (personID, role) VALUES (3, 'OWNING_MEMBER');

-- -----------------------------------------------------------------------

INSERT INTO inverter(id, name, nr, maxpower, installedpower, maxstrings, installedstrings) VALUES
	(1, 'Huawei SUN 2000-36KTL', 0, 36000, 43400, 4, 4),
    (2, 'Huawei SUN 2000-36KTL', 1, 36000, 38750, 4, 4);

INSERT INTO site(id, name, addressID, location) VALUES
    (1, 'Stittholzhof', 3, POINT(48.215012, 8.541057) );

INSERT INTO installation (siteID, inverterID, installdate) VALUES
    (1, 1, '2020-05-01'),
    (1, 2, '2020-05-01');
