-- Title: Create Tables to initialize DB Solar
--
-- Description: This creates the tables with the proper referential
-- integrity for storing data from SolarLog CSV files.
-- Please note, that these need to be preprocessed for correction first.
--
-- Caveats:
--
-- Prerequisites:
--  - None, so far;

CREATE DATABASE IF NOT EXISTS solardb;
CREATE USER IF NOT EXISTS 'solar'@'localhost' IDENTIFIED BY 'password' WITH MAX_QUERIES_PER_HOUR 200;
GRANT SELECT ON solardb.* to 'solar'@'localhost';

USE solardb;

SET NAMES 'UTF8';

SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS address;
DROP TABLE IF EXISTS country;
DROP TABLE IF EXISTS inverter;
DROP TABLE IF EXISTS person;
DROP TABLE IF EXISTS sample;
DROP TABLE IF EXISTS samplePerInverter;
DROP TABLE IF EXISTS site;
-- Next the relation tables:
DROP TABLE IF EXISTS installation;
DROP TABLE IF EXISTS roles;

SET FOREIGN_KEY_CHECKS=1;

-- Please keep the tables sorted by name
-- all referential integrity is added after the commit

CREATE TABLE address(
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'The unique ID of the address',
    poboxNr VARCHAR(16) COMMENT 'The optional Post Office Box number',
	countryID INT COMMENT 'The unique ID of the country',
    streetAndNr VARCHAR(64) COMMENT 'The street and the house number',
    postcode VARCHAR(64) COMMENT 'The postal code / ZIP code',
    town VARCHAR(64) COMMENT 'The name of the town',
    version INT NOT NULL DEFAULT 1 COMMENT 'The version of this row, necessary for optimistic logging'
) COMMENT='entity Address';

CREATE TABLE country (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'The unique ID of the country (defined by the UN)',
    iso2 CHAR(2) NOT NULL UNIQUE COMMENT 'The unique 2-letter code as defined by ISO 3166-1',
    iso3 CHAR(3) NOT NULL UNIQUE COMMENT 'The unique 3-letter code as defined by ISO 3166-1',
    namede VARCHAR(64) CHARACTER SET utf8 DEFAULT NULL COMMENT 'The official name in german',
    nameen VARCHAR(64) CHARACTER SET utf8 DEFAULT NULL COMMENT 'The official name in english',
    namefr VARCHAR(64) CHARACTER SET utf8 DEFAULT NULL COMMENT 'The official name in french',
    version INT NOT NULL DEFAULT 1 COMMENT 'The version of this row, necessary for optimistic logging'
) COMMENT='entity Country';

CREATE TABLE inverter (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'The unique ID of the inverter',
    name VARCHAR(64) COMMENT 'Inverter name',
    nr INT NOT NULL COMMENT 'The number of this inverter within the site (from 0)',
    maxpower INT NOT NULL COMMENT 'Maximum power as supported by vendor (installed may be higher, still) in Watts',
    installedpower INT NOT NULL COMMENT 'Installed Power in Watts',
    maxstrings INT NOT NULL COMMENT 'Maximum number of supported strings',
    installedstrings INT NOT NULL COMMENT 'Installed number of strings',
    version INT NOT NULL DEFAULT 1 COMMENT 'The version of this row, necessary for optimistic logging'
) COMMENT='entity Inverter';

CREATE TABLE person (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'The unique ID of the person',
    addressID INT NOT NULL COMMENT 'ID of the assigned address',
    firstName VARCHAR(64) COMMENT 'First name',
    name VARCHAR(64) COMMENT 'Last name',
    gender VARCHAR(16) DEFAULT 'UNSPECIFIED' COMMENT 'Gender (always in English)',
    eMailaddress VARCHAR(100) COMMENT 'E-Mail Address',
    landLineNr VARCHAR(32) COMMENT 'Telephone number of landline phone',
    mobileNr VARCHAR(32) COMMENT 'Telephone number of mobile phone',
    personType VARCHAR(32) COMMENT 'type of this person, e.g. owner, technician, etc. (see roles)',
    version INT NOT NULL DEFAULT 1 COMMENT 'The version of this row, necessary for optimistic logging'
)  COMMENT='entity Person';

/*
CREATE TABLE sample (
    -- XXX: If our primary key is dateAndTime and siteID, then we don't need an ID...
    -- Also, this is just aggregated data -- this could be delivered as a view
    -- id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'The unique ID of the sample',
    siteID INT NOT NULL COMMENT 'ID of the assigned site',
    dateAndTime DATETIME NOT NULL COMMENT 'Date and time of the sample taken',
    totalEnergy INT NOT NULL COMMENT 'The total amount of energy supplied thus far (over all inverters) today',
    currentPower INT NOT NULL COMMENT 'The current energy over all strings (over all inverters)',
    currentTemp INT NOT NULL COMMENT 'The current maximum temperature (over all inverters)',
    PRIMARY KEY (siteID, dateAndTime)
    -- version INT NOT NULL DEFAULT 1 COMMENT 'The version of this row, necessary for optimistic logging'
) COMMENT='entity Sample';
*/

CREATE TABLE samplePerInverter (
    -- id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'The unique ID of the sampleInverter',
    -- sampleID INT NOT NULL PRIMARY KEY COMMENT 'ID of the corresponding sample',
    dateAndTime DATETIME NOT NULL COMMENT 'Date and time of the sample taken',
    inverterID INT NOT NULL COMMENT 'ID of the assigned inverter',
    PRIMARY KEY (dateAndTime, inverterID),
    totalEnergy INT NOT NULL COMMENT 'The total amount of energy supplied by this inverter thus far today (Wh)',
    pac INT NOT NULL COMMENT 'The current power (AC) over all strings (Watt)',
    uac INT NOT NULL COMMENT 'The current voltage (AC) over all strings (Volt)',
    iac INT NOT NULL COMMENT 'The actual current (AC) over all strings (Ampere)',
    pdc0 INT NOT NULL COMMENT 'The current power (DC) over string 0 (Watt)',
    udc0 INT NOT NULL COMMENT 'The current voltage (DC) over string 0 (Volt)',
    idc0 INT NOT NULL COMMENT 'The actual current (DC) over string 0 (Ampere)',
    pdc1 INT NULL COMMENT 'The current power (DC) over string 1 (Watt) -- which may be NULL',
    udc1 INT NULL COMMENT 'The current voltage (DC) over string 1 (Volt) -- which may be NULL',
    idc1 INT NULL COMMENT 'The actual current (DC) over string 1 (Ampere) -- which may be NULL',
    pdc2 INT NULL COMMENT 'The current power (DC) over string 2 (Watt) -- which may be NULL',
    udc2 INT NULL COMMENT 'The current voltage (DC) over string 2 (Volt) -- which may be NULL',
    idc2 INT NULL COMMENT 'The actual current (DC) over string 2 (Ampere) -- which may be NULL',
    pdc3 INT NULL COMMENT 'The current power (DC) over string 3 (Watt) -- which may be NULL',
    udc3 INT NULL COMMENT 'The current voltage (DC) over string 3 (Volt) -- which may be NULL',
    idc3 INT NULL COMMENT 'The actual current (DC) over string 3 (Ampere) -- which may be NULL',
    temp INT NULL COMMENT 'The current temperature (Celsius) -- which may be optional',
    status INT NOT NULL COMMENT 'The current status',
    error INT NOT NULL COMMENT 'The current error'
    -- version INT NOT NULL DEFAULT 1 COMMENT 'The version of this row, necessary for optimistic logging'
) COMMENT='entity SamplePerInverter';

CREATE TABLE site (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY COMMENT 'The unique ID of the site',
    name VARCHAR(64) NOT NULL COMMENT 'The site name with optional description',
    addressID INT COMMENT 'ID of the assigned address',
    location POINT COMMENT 'The spatial geometry',
    version INT NOT NULL DEFAULT 1 COMMENT 'The version of this row, necessary for optimistic logging'
) COMMENT='entity Site';

-- -----------------------------------------------------------------------------;
-- Create Statements for Relation Tables
-- -----------------------------------------------------------------------------;

CREATE TABLE installation (
  siteID INT NOT NULL COMMENT 'The unique ID of the site',
  inverterID INT NOT NULL COMMENT 'The unique ID of the inverter',
  installdate DATE NOT NULL COMMENT 'The installation date',
  PRIMARY KEY (siteID, inverterID)
) COMMENT='relation between site and inverters';

CREATE TABLE roles (
    personID INT NOT NULL COMMENT 'The unique ID of the member',
    role SET('OWNING_MEMBER', 'TECHNICIAN', 'OWNER', 'ADMIN') NOT NULL COMMENT 'The name of the role for this member',
    PRIMARY KEY (personID , role)
)  COMMENT='collection of roles for one member';

-- -----------------------------------------------------------------------------;
COMMIT;
-- -----------------------------------------------------------------------------;
-- Create Statements for Foreign Keys
-- -----------------------------------------------------------------------------;
ALTER TABLE address ADD CONSTRAINT address_countryID
  FOREIGN KEY (countryID)
  REFERENCES country(id)
  ON DELETE SET NULL
  ON UPDATE RESTRICT;

ALTER TABLE person ADD CONSTRAINT person_addressID
  FOREIGN KEY (addressID)
  REFERENCES address(id)
  ON DELETE CASCADE
  ON UPDATE RESTRICT;

/*
ALTER TABLE sample ADD CONSTRAINT sample_siteID
  FOREIGN KEY (siteID)
  REFERENCES site(id)
  ON DELETE RESTRICT
  ON UPDATE RESTRICT;
*/

-- ALTER TABLE sampleInverter ADD CONSTRAINT sampleInverter_sampleID
--   FOREIGN KEY (sampleID)
--   REFERENCES sample(id)
--   ON DELETE CASCADE
--   ON UPDATE RESTRICT;

-- ALTER TABLE samplePerInverter ADD CONSTRAINT sampleInverter_sample
--   FOREIGN KEY (sampleID)
--   REFERENCES sample(siteID, dateAndTime)
--   ON DELETE CASCADE
--   ON UPDATE RESTRICT;


ALTER TABLE samplePerInverter ADD CONSTRAINT samplePerInverter_inverterID
  FOREIGN KEY (inverterID)
  REFERENCES inverter(id)
  ON DELETE CASCADE
  ON UPDATE RESTRICT;

ALTER TABLE site ADD CONSTRAINT site_addressID
  FOREIGN KEY (addressID)
  REFERENCES address(id)
  ON DELETE CASCADE
  ON UPDATE RESTRICT;

-- -----------------------------------------------------------------------;
-- Creation of the SummaryViews
-- -----------------------------------------------------------------------;  
CREATE VIEW viewTotalEnergy AS SELECT dateAndTime, SUM(s.totalEnergy) AS WattHours FROM samplePerInverter s WHERE s.inverterID IN (SELECT inverterID FROM installation WHERE siteID=1) GROUP BY dateAndTime;
CREATE VIEW viewCurrentPower AS SELECT dateAndTime, SUM(s.pac) AS Watt FROM samplePerInverter s WHERE s.inverterID IN (SELECT inverterID FROM installation WHERE siteID=1) GROUP BY dateAndTime;
CREATE VIEW viewMaxTemperature AS SELECT dateAndTime, MAX(s.temp) AS Temperature FROM samplePerInverter s WHERE s.inverterID IN (SELECT inverterID FROM installation WHERE siteID=1) GROUP BY dateAndTime;

CREATE VIEW viewDay AS SELECT YEAR(dateAndTime) AS Year, MONTH(dateAndTime) AS Month, DAY(dateAndTime) AS Day,  MAX(WattHours) AS WattHours FROM viewTotalEnergy GROUP BY YEAR(dateAndTime), MONTH(dateAndTime), DAY(dateAndTime);
CREATE VIEW viewMonth AS SELECT YEAR(dateAndTime) AS Year, MONTH(dateAndTime) AS Month, SUM(WattHours) AS WattHours FROM viewTotalEnergy GROUP BY YEAR(dateAndTime), MONTH(dateAndTime);
CREATE VIEW viewYear AS SELECT YEAR(dateAndTime) AS Year, SUM(WattHours) AS WattHours FROM viewTotalEnergy GROUP BY YEAR(dateAndTime);


-- -----------------------------------------------------------------------;
-- Initialisation of the most important tables
-- -----------------------------------------------------------------------;

-- Country, see UNstat:  http://unstats.un.org/unsd/methods/m49/m49.htm / ISO3166
INSERT INTO country (id, iso2, iso3, nameen, namefr, namede) VALUES
    (4,'AF','AFG','Afghanistan','Afghanistan','Afghanistan'),
    (8,'AL','ALB','Albania','Albanie','Albanien'),
    (10,'AQ','ATA','Antarctica','Antarctique','Antarktis'),
    (12,'DZ','DZA','Algeria','Algérie','Algerien'),
    (16,'AS','ASM','American Samoa','Samoa américaines','Amerikanisch-Samoa'),
    (20,'AD','AND','Andorra','Andorre','Andorra'),
    (24,'AO','AGO','Angola','Angola','Angola'),
    (28,'AG','ATG','Antigua and Barbuda','Antigua-et-Barbuda','Antigua und Barbuda'),
    (31,'AZ','AZE','Azerbaijan','Azerbaïdjan','Aserbaidschan'),
    (32,'AR','ARG','Argentina','Argentine','Argentinien'),
    (36,'AU','AUS','Australia','Australie','Australien'),
    (40,'AT','AUT','Austria','Autriche','Österreich'),
    (44,'BS','BHS','Bahamas','Bahamas','Bahamas'),
    (48,'BH','BHR','Bahrain','Bahreïn','Bahrain'),
    (50,'BD','BGD','Bangladesh','Bangladesh','Bangladesh'),
    (51,'AM','ARM','Armenia','Arménie','Armenien'),
    (52,'BB','BRB','Barbados','Barbade','Barbados'),
    (56,'BE','BEL','Belgium','Belgique','Belgien'),
    (60,'BM','BMU','Bermuda','Bermudes','Bermudas'),
    (64,'BT','BTN','Bhutan','Bhoutan','Bhutan'),
    (68,'BO','BOL','Bolivia (Plurinational State of)','Bolivie (État plurinational de)','Bolivien'),
    (70,'BA','BIH','Bosnia and Herzegovina','Bosnie-Herzégovine','Bosnien-Herzegowina'),
    (72,'BW','BWA','Botswana','Botswana','Botswana'),
    (74,'BV','BVT','Bouvet Island','Bouvet (l\'Île)','Bouvetinsel'),
    (76,'BR','BRA','Brazil','Brésil','Brasilien'),
    (84,'BZ','BLZ','Belize','Belize','Belize'),
    (86,'IO','IOT','British Indian Ocean Territory','Indien (le Territoire britannique de l\'océan)','Brit. Territorium im Indischen Ozean'),
    (90,'SB','SLB','Solomon Islands','Salomon (Îles)','Solomonen'),
    (92,'VG','VGB','Virgin Islands (British)','Vierges britanniques (les Îles)','Jungferninseln (Brit.)'),
    (96,'BN','BRN','Brunei Darussalam','Brunéi Darussalam','Brunei'),
    (100,'BG','BGR','Bulgaria','Bulgarie','Bulgarien'),
    (104,'MM','MMR','Myanmar','Myanmar','Myanmar'),
    (108,'BI','BDI','Burundi','Burundi','Burundi'),
    (112,'BY','BLR','Belarus','Bélarus','Weißrussland'),
    (116,'KH','KHM','Cambodia','Cambodge','Kambodscha'),
    (120,'CM','CMR','Cameroon','Cameroun','Kamerun'),
    (124,'CA','CAN','Canada','Canada','Kanada'),
    (132,'CV','CPV','Cabo Verde','Cabo Verde','Kap Verde'),
    (136,'KY','CYM','Cayman Islands','Caïmans (les Îles)','Kaiman Inseln'),
    (140,'CF','CAF','Central African Republic','République centrafricaine','Zentralafrikanische Republik'),
    (144,'LK','LKA','Sri Lanka','Sri Lanka','Sri Lanka'),
    (148,'TD','TCD','Chad','Tchad','Tschad'),
    (152,'CL','CHL','Chile','Chili','Chile'),
    (156,'CN','CHN','China','Chine','China'),
    (158,'TW','TWN','Taiwan (Province of China)','Taïwan (Province de Chine)','Taiwan'),
    (162,'CX','CXR','Christmas Island','Christmas (l\'Île)','Weihnachtsinsel'),
    (166,'CC','CCK','Cocos (Keeling) Islands','Cocos (les Îles)/ Keeling (les Îles)','Kokosinseln'),
    (170,'CO','COL','Colombia','Colombie','Kolumbien'),
    (174,'KM','COM','Comoros','Comores','Komoren'),
    (175,'YT','MYT','Mayotte','Mayotte','Mayotte'),
    (178,'CG','COG','Congo','Congo','Kongo'),
    (180,'CD','COD','Congo (the Democratic Republic of the)','Congo (la République démocratique du)','Kongo, Demokr. Republik'),
    (184,'CK','COK','Cook Islands','Cook (les Îles)','Cookinseln'),
    (188,'CR','CRI','Costa Rica','Costa Rica','Costa Rica'),
    (191,'HR','HRV','Croatia','Croatie','Kroatien'),
    (192,'CU','CUB','Cuba','Cuba','Kuba'),
    (196,'CY','CYP','Cyprus','Chypre','Zypern'),
    (203,'CZ','CZE','Czech Republic','tchèque (la République)','Tschechische Republik'),
    (204,'BJ','BEN','Benin','Bénin','Benin'),
    (208,'DK','DNK','Denmark','Danemark','Dänemark'),
    (212,'DM','DMA','Dominica','Dominique','Dominika'),
    (214,'DO','DOM','Dominican Republic','dominicaine (la République)','Dominikanische Republik'),
    (218,'EC','ECU','Ecuador','Équateur','Ecuador'),
    (222,'SV','SLV','El Salvador','El Salvador','El Salvador'),
    (226,'GQ','GNQ','Equatorial Guinea','Guinée équatoriale','Äquatorial Guinea'),
    (231,'ET','ETH','Ethiopia','Éthiopie','Äthiopien'),
    (232,'ER','ERI','Eritrea','Érythrée','Eritrea'),
    (233,'EE','EST','Estonia','Estonie','Estland'),
    (234,'FO','FRO','Faroe Islands','Féroé (les Îles)','Färöer Inseln'),
    (238,'FK','FLK','Falkland Islands [Malvinas]','Falkland (les Îles)/Malouines (les Îles)','Falkland Inseln'),
    (239,'GS','SGS','South Georgia and the South Sandwich Islands','Géorgie du Sud-et-les Îles Sandwich du Sud','Südgeorgien und südl. Sandwichinseln'),
    (242,'FJ','FJI','Fiji','Fidji','Fidschi'),
    (246,'FI','FIN','Finland','Finlande','Finnland'),
    (248,'AX','ALA','Åland Islands','Åland(les Îles)','Åland'),
    (250,'FR','FRA','France','France','Frankreich'),
    (254,'GF','GUF','French Guiana','Guyane française (la )','Franz. Guyana'),
    (258,'PF','PYF','French Polynesia','Polynésie française','Franz. Polynesien'),
    (260,'TF','ATF','French Southern Territories','Terres australes françaises','Franz. Süd-Territorium'),
    (262,'DJ','DJI','Djibouti','Djibouti','Djibuti'),
    (266,'GA','GAB','Gabon','Gabon','Gabun'),
    (268,'GE','GEO','Georgia','Géorgie','Georgien'),
    (270,'GM','GMB','Gambia','Gambie','Gambia'),
    (275,'PS','PSE','Palestine, State of','Palestine, État de','Palästina'),
    (276,'DE','DEU','Germany','Allemagne','Deutschland'),
    (288,'GH','GHA','Ghana','Ghana','Ghana'),
    (292,'GI','GIB','Gibraltar','Gibraltar','Gibraltar'),
    (296,'KI','KIR','Kiribati','Kiribati','Kiribati'),
    (300,'GR','GRC','Greece','Grèce','Griechenland'),
    (304,'GL','GRL','Greenland','Groenland','Grönland'),
    (308,'GD','GRD','Grenada','Grenade','Grenada'),
    (312,'GP','GLP','Guadeloupe','Guadeloupe','Guadeloupe'),
    (316,'GU','GUM','Guam','Guam','Guam'),
    (320,'GT','GTM','Guatemala','Guatemala','Guatemala'),
    (324,'GN','GIN','Guinea','Guinée','Guinea'),
    (328,'GY','GUY','Guyana','Guyana','Guyana'),
    (332,'HT','HTI','Haiti','Haïti','Haiti'),
    (334,'HM','HMD','Heard Island and McDonald Islands','Heard-et-Îles MacDonald (l\'Île)','Heard und McDonaldinseln'),
    (336,'VA','VAT','Holy See','Saint-Siège','Staat Vatikanstadt'),
    (340,'HN','HND','Honduras','Honduras','Honduras'),
    (344,'HK','HKG','Hong Kong','Hong Kong','Hong Kong'),
    (348,'HU','HUN','Hungary','Hongrie','Ungarn'),
    (352,'IS','ISL','Iceland','Islande','Island'),
    (356,'IN','IND','India','Inde','Indien'),
    (360,'ID','IDN','Indonesia','Indonésie','Indonesien'),
    (364,'IR','IRN','Iran (Islamic Republic of)','Iran (République Islamique d\')','Iran'),
    (368,'IQ','IRQ','Iraq','Iraq','Irak'),
    (372,'IE','IRL','Ireland','Irlande','Irland'),
    (376,'IL','ISR','Israel','Israël','Israel'),
    (380,'IT','ITA','Italy','Italie','Italien'),
    (384,'CI','CIV','Côte d\'Ivoire','Côte d\'Ivoire','Elfenbeinküste'),
    (388,'JM','JAM','Jamaica','Jamaïque','Jamaika'),
    (392,'JP','JPN','Japan','Japon','Japan'),
    (398,'KZ','KAZ','Kazakhstan','Kazakhstan','Kasachstan'),
    (400,'JO','JOR','Jordan','Jordanie','Jordanien'),
    (404,'KE','KEN','Kenya','Kenya','Kenia'),
    (408,'KP','PRK','Korea (the Democratic People\'s Republic of)','Corée (la République populaire démocratique de)','Demokr. Volksrepublik Korea'),
    (410,'KR','KOR','Korea (the Republic of)','Corée (la République de)','Südkorea'),
    (414,'KW','KWT','Kuwait','Koweït','Kuwait'),
    (417,'KG','KGZ','Kyrgyzstan','Kirghizistan','Kirgisistan'),
    (418,'LA','LAO','Lao People\'s Democratic Republic','Lao, République démocratique populaire','Laos'),
    (422,'LB','LBN','Lebanon','Liban','Libanon'),
    (426,'LS','LSO','Lesotho','Lesotho','Lesotho'),
    (428,'LV','LVA','Latvia','Lettonie','Lettland'),
    (430,'LR','LBR','Liberia','Libéria','Liberia'),
    (434,'LY','LBY','Libya','Libye','Libyen'),
    (438,'LI','LIE','Liechtenstein','Liechtenstein','Liechtenstein'),
    (440,'LT','LTU','Lithuania','Lituanie','Litauen'),
    (442,'LU','LUX','Luxembourg','Luxembourg','Luxemburg'),
    (446,'MO','MAC','Macao','Macao','Macau'),
    (450,'MG','MDG','Madagascar','Madagascar','Madagaskar'),
    (454,'MW','MWI','Malawi','Malawi','Malawi'),
    (458,'MY','MYS','Malaysia','Malaisie','Malaysia'),
    (462,'MV','MDV','Maldives','Maldives','Malediven'),
    (466,'ML','MLI','Mali','Mali','Mali'),
    (470,'MT','MLT','Malta','Malte','Malta'),
    (474,'MQ','MTQ','Martinique','Martinique','Martinique'),
    (478,'MR','MRT','Mauritania','Mauritanie','Mauretanien'),
    (480,'MU','MUS','Mauritius','Maurice','Mauritius'),
    (484,'MX','MEX','Mexico','Mexique','Mexiko'),
    (492,'MC','MCO','Monaco','Monaco','Monaco'),
    (496,'MN','MNG','Mongolia','Mongolie','Mongolei'),
    (498,'MD','MDA','Moldova (the Republic of)','Moldova , République de','Moldavien'),
    (499,'ME','MNE','Montenegro','Monténégro','Montenegro'),
    (500,'MS','MSR','Montserrat','Montserrat','Montserrat'),
    (504,'MA','MAR','Morocco','Maroc','Marokko'),
    (508,'MZ','MOZ','Mozambique','Mozambique','Mosambik'),
    (512,'OM','OMN','Oman','Oman','Oman'),
    (516,'NA','NAM','Namibia','Namibie','Namibia'),
    (520,'NR','NRU','Nauru','Nauru','Nauru'),
    (524,'NP','NPL','Nepal','Népal','Nepal'),
    (528,'NL','NLD','Netherlands','Pays-Bas','Niederlande'),
    (531,'CW','CUW','Curaçao','Curaçao','Curaçao'),
    (533,'AW','ABW','Aruba','Aruba','Aruba'),
    (534,'SX','SXM','Sint Maarten (Dutch part)','Saint-Martin (partie néerlandaise)','Sint Maarten (holl. Teil)'),
    (535,'BQ','BES','Bonaire, Sint Eustatius and Saba','Bonaire, Saint-Eustache et Saba','Bonaire, Sint Eustatius, Saba'),
    (540,'NC','NCL','New Caledonia','Nouvelle-Calédonie','Neukaledonien'),
    (548,'VU','VUT','Vanuatu','Vanuatu','Vanuatu'),
    (554,'NZ','NZL','New Zealand','Nouvelle-Zélande','Neuseeland'),
    (558,'NI','NIC','Nicaragua','Nicaragua','Nicaragua'),
    (562,'NE','NER','Niger','Niger','Niger'),
    (566,'NG','NGA','Nigeria','Nigéria','Nigeria'),
    (570,'NU','NIU','Niue','Niue','Niue'),
    (574,'NF','NFK','Norfolk Island','Norfolk (l\'Île)','Norfolk Inseln'),
    (578,'NO','NOR','Norway','Norvège','Norwegen'),
    (580,'MP','MNP','Northern Mariana Islands','Mariannes du Nord (les Îles)','Marianen'),
    (581,'UM','UMI','United States Minor Outlying Islands','Îles mineures éloignées des États-Unis','U.S. Minor Outlying Islands'),
    (583,'FM','FSM','Micronesia (Federated States of)','Micronésie (États fédérés de)','Mikronesien'),
    (584,'MH','MHL','Marshall Islands','Marshall (Îles)','Marshall Inseln'),
    (585,'PW','PLW','Palau','Palaos','Palau'),
    (586,'PK','PAK','Pakistan','Pakistan','Pakistan'),
    (591,'PA','PAN','Panama','Panama','Panama'),
    (598,'PG','PNG','Papua New Guinea','Papouasie-Nouvelle-Guinée','Papua Neuguinea'),
    (600,'PY','PRY','Paraguay','Paraguay','Paraguay'),
    (604,'PE','PER','Peru','Pérou','Peru'),
    (608,'PH','PHL','Philippines','Philippines','Philippinen'),
    (612,'PN','PCN','Pitcairn','Pitcairn','Pitcairn'),
    (616,'PL','POL','Poland','Pologne','Polen'),
    (620,'PT','PRT','Portugal','Portugal','Portugal'),
    (624,'GW','GNB','Guinea-Bissau','Guinée-Bissau','Guinea Bissau'),
    (626,'TL','TLS','Timor-Leste','Timor-Leste','Osttimor'),
    (630,'PR','PRI','Puerto Rico','Porto Rico','Puerto Rico'),
    (634,'QA','QAT','Qatar','Qatar','Qatar'),
    (638,'RE','REU','Réunion','Réunion (La)','Reunion'),
    (642,'RO','ROU','Romania','Roumanie','Rumänien'),
    (643,'RU','RUS','Russian Federation','Russie (la Fédération de)','Rußland'),
    (646,'RW','RWA','Rwanda','Rwanda','Ruanda'),
    (652,'BL','BLM','Saint Barthélemy','Saint-Barthélemy','Saint-Barthélemy'),
    (654,'SH','SHN','Saint Helena, Ascension and Tristan da Cunha','Sainte-Hélène, Ascension et Tristan da Cunha','St. Helena'),
    (659,'KN','KNA','Saint Kitts and Nevis','Saint-Kitts-et-Nevis','St. Kitts Nevis Anguilla'),
    (660,'AI','AIA','Anguilla','Anguilla','Anguilla'),
    (662,'LC','LCA','Saint Lucia','Sainte-Lucie','Saint Lucia'),
    (663,'MF','MAF','Saint Martin (French part)','Saint-Martin (partie française)','Saint Martin (franz. Teil)'),
    (666,'PM','SPM','Saint Pierre and Miquelon','Saint-Pierre-et-Miquelon','St. Pierre und Miquelon'),
    (670,'VC','VCT','Saint Vincent and the Grenadines','Saint-Vincent-et-les Grenadines','St. Vincent'),
    (674,'SM','SMR','San Marino','Saint-Marin','San Marino'),
    (678,'ST','STP','Sao Tome and Principe','Sao Tomé-et-Principe','São Tomé und Príncipe'),
    (682,'SA','SAU','Saudi Arabia','Arabie saoudite','Saudi-Arabien'),
    (686,'SN','SEN','Senegal','Sénégal','Senegal'),
    (688,'RS','SRB','Serbia','Serbie','Serbien'),
    (690,'SC','SYC','Seychelles','Seychelles','Seychellen'),
    (694,'SL','SLE','Sierra Leone','Sierra Leone','Sierra Leone'),
    (702,'SG','SGP','Singapore','Singapour','Singapur'),
    (703,'SK','SVK','Slovakia','Slovaquie','Slowakei'),
    (704,'VN','VNM','Viet Nam','Viet Nam','Vietnam'),
    (705,'SI','SVN','Slovenia','Slovénie','Slowenien'),
    (706,'SO','SOM','Somalia','Somalie','Somalia'),
    (710,'ZA','ZAF','South Africa','Afrique du Sud','Südafrika'),
    (716,'ZW','ZWE','Zimbabwe','Zimbabwe','Zimbabwe'),
    (724,'ES','ESP','Spain','Espagne','Spanien'),
    (728,'SS','SSD','South Sudan','Soudan du Sud','Südsudan'),
    (729,'SD','SDN','Sudan','Soudan','Sudan'),
    (732,'EH','ESH','Western Sahara*','Sahara occidental*','Westsahara'),
    (740,'SR','SUR','Suriname','Suriname','Surinam'),
    (744,'SJ','SJM','Svalbard and Jan Mayen','Svalbard et l\'Île Jan Mayen','Svalbard und Jan Mayen'),
    (748,'SZ','SWZ','Swaziland','Swaziland','Swasiland'),
    (752,'SE','SWE','Sweden','Suède','Schweden'),
    (756,'CH','CHE','Switzerland','Suisse','Schweiz'),
    (760,'SY','SYR','Syrian Arab Republic','République arabe syrienne','Syrien'),
    (762,'TJ','TJK','Tajikistan','Tadjikistan','Tadschikistan'),
    (764,'TH','THA','Thailand','Thaïlande','Thailand'),
    (768,'TG','TGO','Togo','Togo','Togo'),
    (772,'TK','TKL','Tokelau','Tokelau','Tokelau'),
    (776,'TO','TON','Tonga','Tonga','Tonga'),
    (780,'TT','TTO','Trinidad and Tobago','Trinité-et-Tobago','Trinidad Tobago'),
    (784,'AE','ARE','United Arab Emirates','Émirats arabes unis','Vereinigte Arabische Emirate'),
    (788,'TN','TUN','Tunisia','Tunisie','Tunesien'),
    (792,'TR','TUR','Turkey','Turquie','Türkei'),
    (795,'TM','TKM','Turkmenistan','Turkménistan','Turkmenistan'),
    (796,'TC','TCA','Turks and Caicos Islands','Turks-et-Caïcos (les Îles)','Turks und Kaikos Inseln'),
    (798,'TV','TUV','Tuvalu','Tuvalu','Tuvalu'),
    (800,'UG','UGA','Uganda','Ouganda','Uganda'),
    (804,'UA','UKR','Ukraine','Ukraine','Ukraine'),
    (807,'MK','MKD','Macedonia (the former Yugoslav Republic of)','Macédoine (l\'ex_République yougoslave de)','Mazedonien'),
    (818,'EG','EGY','Egypt','Égypte','Ägypten'),
    (826,'GB','GBR','United Kingdom of Great Britain and Northern Ireland','Royaume-Uni de Grande-Bretagne et d\'Irlande du Nord','Großbritannien (UK)'),
    (831,'GG','GGY','Guernsey','Guernesey','Guernsey (Kanalinsel)'),
    (832,'JE','JEY','Jersey','Jersey','Jersey (Kanalinsel)'),
    (833,'IM','IMN','Isle of Man','Île de Man','Isle of Man'),
    (834,'TZ','TZA','Tanzania, United Republic of','Tanzanie, République-Unie de','Tansania'),
    (840,'US','USA','United States of America','États-Unis d\'Amérique','Vereinigte Staaten von Amerika'),
    (850,'VI','VIR','Virgin Islands (U.S.)','Vierges des États-Unis (les Îles)','Jungferninseln (USA)'),
    (854,'BF','BFA','Burkina Faso','Burkina Faso','Burkina Faso'),
    (858,'UY','URY','Uruguay','Uruguay','Uruguay'),
    (860,'UZ','UZB','Uzbekistan','Ouzbékistan','Usbekistan'),
    (862,'VE','VEN','Venezuela (Bolivarian Republic of)','Venezuela (République bolivarienne du)','Venezuela'),
    (876,'WF','WLF','Wallis and Futuna','Wallis-et-Futuna','Wallis und Futuna'),
    (882,'WS','WSM','Samoa','Samoa','Samoa'),
    (887,'YE','YEM','Yemen','Yémen','Jemen'),
    (894,'ZM','ZMB','Zambia','Zambie','Sambia');

-- -----------------------------------------------------------------------------;
-- Finally:
COMMIT;
