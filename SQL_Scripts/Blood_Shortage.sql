ALTER AUTHORIZATION ON DATABASE::BloodShortage TO sa;
CREATE DATABASE Blood_Shortage;
USE Blood_Shortage;

-- ==========================================
-- 1️⃣ Hospitals Table
-- ==========================================
CREATE TABLE Hospitals (
    hospital_id INT IDENTITY(1,1) PRIMARY KEY,
    hospital_name NVARCHAR(255) NOT NULL,
    governorate NVARCHAR(100),
    address NVARCHAR(255),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6)
);

-- ==========================================
-- 2️⃣ Donors Table
-- ==========================================
CREATE TABLE Donors (
    donor_id INT IDENTITY(1,1) PRIMARY KEY,
    donor_name NVARCHAR(255) NOT NULL,
    blood_type NVARCHAR(3) NOT NULL,  -- e.g., A+, O-
    last_donation_date DATE,
    donation_amount DECIMAL(5,2),     -- Blood volume in milliliters (ml)
    committed BIT,                    -- 1 = Committed, 0 = Not Committed
    hospital_id INT,
    CONSTRAINT FK_Donors_Hospitals FOREIGN KEY (hospital_id)
        REFERENCES Hospitals(hospital_id)
);

-- ==========================================
-- 3️⃣ Patients Table
-- ==========================================
CREATE TABLE Patients (
    patient_id INT IDENTITY(1,1) PRIMARY KEY,
    patient_name NVARCHAR(255) NOT NULL,
    blood_type NVARCHAR(3) NOT NULL,
    required_amount DECIMAL(5,2),    -- Required blood volume
    request_date DATE,
    expected_discharge DATE,
    hospital_id INT,
    CONSTRAINT FK_Patients_Hospitals FOREIGN KEY (hospital_id)
        REFERENCES Hospitals(hospital_id)
);

IF COL_LENGTH('Patients', 'received') IS NULL
BEGIN
    ALTER TABLE Patients
    ADD received BIT DEFAULT 0;
END

IF COL_LENGTH('Patients', 'blood_pressure_status') IS NULL
BEGIN
    ALTER TABLE Patients
    ADD blood_pressure_status NVARCHAR(10);
END

-- ==========================================
-- 4️⃣ Fact Table / Analytics Table
-- ==========================================
CREATE TABLE BloodStockForecast (
    forecast_id INT IDENTITY(1,1) PRIMARY KEY,
    hospital_id INT NOT NULL,
    blood_type NVARCHAR(3) NOT NULL,
    total_donated DECIMAL(8,2) DEFAULT 0,
    total_required DECIMAL(8,2) DEFAULT 0,
    deficit AS (total_required - total_donated) PERSISTED,
    forecast_date DATE DEFAULT GETDATE(),
    shortage_flag AS (CASE WHEN (total_required - total_donated) > 0 THEN 1 ELSE 0 END) PERSISTED,
    CONSTRAINT FK_Forecast_Hospitals FOREIGN KEY (hospital_id)
        REFERENCES Hospitals(hospital_id)
);

USE BloodShortage;
GO

-- 1️⃣ Clean existing tables before population
DELETE FROM BloodStockForecast;
DELETE FROM Patients;
DELETE FROM Donors;

DBCC CHECKIDENT ('Patients', RESEED, 0);
DBCC CHECKIDENT ('Donors', RESEED, 0);

-- 2️⃣ Prepare the valid hospitals reference list
DROP TABLE IF EXISTS #ValidHospitals;
CREATE TABLE #ValidHospitals (RowNum INT IDENTITY(1,1), hospital_id INT);
INSERT INTO #ValidHospitals (hospital_id) 
SELECT hospital_id FROM Hospitals ORDER BY hospital_id;

DECLARE @TotalHospitals INT = (SELECT COUNT(*) FROM #ValidHospitals);
PRINT 'Total Hospitals Found: ' + CAST(@TotalHospitals AS NVARCHAR(10));

-- ==========================================
-- 💉 Populate massive list of First and Last Names
-- ==========================================
DECLARE @FirstNames TABLE (name NVARCHAR(50));
INSERT INTO @FirstNames (name) VALUES
('Mohamed'),('Ahmed'),('Ali'),('Mahmoud'),('Hossam'),('Khaled'),('Omar'),('Youssef'),
('Ibrahim'),('Tarek'),('Samir'),('Nasser'),('Fathy'),('Adel'),('Gamal'),('Hany'),
('Sara'),('Fatima'),('Maryam'),('Amina'),('Amal'),('Hoda'),('Rania'),('Dina'),
('Nadia'),('Lamia'),('Mona'),('Hana'),('Salma'),('Reem'),('Nour'),('Laila'),
('Rana'),('Leen'),('Nada'),('Mariam'),('Samar'),('Maha'),('Dalia'),('Nourhan'),
('Heba'),('Eman'),('Doaa'),('Aya'),('Malak'),('Yara'),('Reema'),('Jana'),('Lina'),('Ruba'),
('Haifa'),('Raghad'),('Asmaa'),('Sawsan'),('Nisreen'),('Lamiaa'),('Manar'),('Rita'),('Farah');

DECLARE @LastNames TABLE (name NVARCHAR(50));
INSERT INTO @LastNames (name) VALUES
('Hassan'),('Mahmoud'),('El-Sayed'),('Mohamed'),('Ali'),('Ibrahim'),
('Fathy'),('El-Shafei'),('El-Masry'),('El-Sherbiny'),('El-Gamal'),('Hassan'),
('Kamel'),('AbdelRahman'),('Hafez'),('Said'),('Naguib'),('AbdelAziz'),('Rashad'),('Tawfik'),
('Farouk'),('Nabil'),('Salem'),('Hany'),('Younes'),('Sharif'),('Zaki'),('Fahmy'),('Adly'),('Mokhtar'),
('Gaber'),('Shoukry'),('Hussein'),('Mostafa'),('Ashraf'),('Eid'),('Magdy'),('Atef'),('Lotfy'),('Hamdy');

-- ==========================================
-- 💉 Generate 10,000 unique donor records without repeating names
-- ==========================================
PRINT 'Starting Donors Insert...';

WITH DonorNames AS (
    SELECT TOP (10000) FN.name + ' ' + LN.name AS FullName
    FROM @FirstNames FN
    CROSS JOIN @LastNames LN
    ORDER BY NEWID()
),
Numbered AS (
    SELECT FullName, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS RN
    FROM DonorNames
)
INSERT INTO Donors (donor_name, blood_type, last_donation_date, donation_amount, committed, hospital_id)
SELECT 
    FullName,
    CASE 
        WHEN RN % 10 IN (0,1) THEN 'O+'
        WHEN RN % 10 IN (2,3) THEN 'A+'
        WHEN RN % 10 IN (4,5) THEN 'B+'
        WHEN RN % 10 = 6 THEN 'AB+'
        WHEN RN % 10 = 7 THEN 'O-'
        WHEN RN % 10 = 8 THEN 'A-'
        ELSE 'B-'
    END,
    DATEADD(DAY, -RN % 180, GETDATE()),
    CHOOSE((RN % 3) + 1, 400.00, 450.00, 500.00),
    RN % 2,
    (SELECT hospital_id FROM #ValidHospitals WHERE RowNum = (RN % @TotalHospitals) + 1)
FROM Numbered;

-- ==========================================
-- 🩸 Generate 20,000 unique patient records without repeating names
-- ==========================================
PRINT 'Starting Patients Insert...';

WITH PatientNames AS (
    SELECT TOP (20000) FN1.name + ' ' + LN.name + ' ' + FN2.name AS FullName
    FROM @FirstNames FN1
    CROSS JOIN @LastNames LN
    CROSS JOIN @FirstNames FN2
    ORDER BY NEWID()
),
Numbered AS (
    SELECT FullName, ROW_NUMBER() OVER(ORDER BY (SELECT NULL)) AS RN
    FROM PatientNames
)
INSERT INTO Patients (patient_name, blood_type, required_amount, request_date, expected_discharge, hospital_id, received, blood_pressure_status)
SELECT 
    FullName,
    CASE 
        WHEN RN % 10 IN (0,1) THEN 'O+'
        WHEN RN % 10 IN (2,3) THEN 'A+'
        WHEN RN % 10 IN (4,5) THEN 'B+'
        WHEN RN % 10 = 6 THEN 'AB+'
        WHEN RN % 10 = 7 THEN 'O-'
        WHEN RN % 10 = 8 THEN 'A-'
        ELSE 'B-'
    END,
    200 + (RN % 500),
    DATEADD(DAY, -RN % 30, GETDATE()),
    DATEADD(DAY, RN % 15, GETDATE()),
    (SELECT hospital_id FROM #ValidHospitals WHERE RowNum = (RN % @TotalHospitals) + 1),
    CASE WHEN RN % 10 IN (6,7,8,9) THEN 0 ELSE 1 END,
    CHOOSE((RN % 3) + 1, 'Normal', 'High', 'Low')
FROM Numbered;

-- ==========================================
-- 📊 Update Forecast Fact Table (Analytics)
-- ==========================================
PRINT 'Updating BloodStockForecast...';
INSERT INTO BloodStockForecast (hospital_id, blood_type, total_donated, total_required, forecast_date)
SELECT 
    COALESCE(D.hospital_id, P.hospital_id), 
    COALESCE(D.blood_type, P.blood_type),
    ISNULL(SUM(D.donated_amt), 0), 
    ISNULL(SUM(P.req_amt), 0), 
    GETDATE()
FROM (SELECT hospital_id, blood_type, SUM(donation_amount) as donated_amt FROM Donors GROUP BY hospital_id, blood_type) D
FULL OUTER JOIN (SELECT hospital_id, blood_type, SUM(required_amount) as req_amt FROM Patients GROUP BY hospital_id, blood_type) P 
ON D.hospital_id = P.hospital_id AND D.blood_type = P.blood_type
GROUP BY COALESCE(D.hospital_id, P.hospital_id), COALESCE(D.blood_type, P.blood_type);

-- Final statistics checks
SELECT 'Donors' AS TableName, COUNT(*) AS Total FROM Donors
UNION ALL
SELECT 'Patients', COUNT(*) FROM Patients
UNION ALL
SELECT 'Forecast Rows', COUNT(*) FROM BloodStockForecast;

SELECT 'Patients Without Blood', COUNT(*) FROM Patients WHERE received = 0;
SELECT 'Patients With Blood', COUNT(*) FROM Patients WHERE received = 1;

SELECT blood_type, COUNT(*) AS PatientCount, 
       SUM(CASE WHEN received = 0 THEN 1 ELSE 0 END) AS WithoutBlood,
       SUM(CASE WHEN received = 1 THEN 1 ELSE 0 END) AS WithBlood
FROM Patients 
GROUP BY blood_type
ORDER BY blood_type;

-- Random sampling to verify uniqueness
SELECT TOP 20 donor_name FROM Donors ORDER BY NEWID();
SELECT TOP 20 patient_name FROM Patients ORDER BY NEWID();

SELECT COUNT(*) AS Hospitals FROM Hospitals;
SELECT COUNT(*) AS Donors FROM Donors;
SELECT COUNT(*) AS Patients FROM Patients;
SELECT COUNT(*) AS Forecast FROM BloodStockForecast;

select * from Hospitals;
select * from Donors;
SELECT * FROM Patients;
SELECT * FROM BloodStockForecast;

delete from Donors;
delete from Patients;

INSERT INTO Hospitals (hospital_name, governorate, address, latitude, longitude) VALUES
('Kasr Al Ainy Hospital', 'Cairo', 'Kasr Al Ainy St, Cairo', 30.0276, 31.2336),
('Ain Shams University Hospital', 'Cairo', 'El-Khalifa El-Mamoun St, Abbassia', 30.0740, 31.2833),
('El Demerdash Hospital', 'Cairo', 'Abbassia Square', 30.0773, 31.2778),
('Dar Al Fouad Hospital', 'Giza', '26th of July Corridor, Sheikh Zayed', 30.0463, 31.0165),
('Sheikh Zayed Specialized Hospital', 'Giza', 'Sheikh Zayed City', 30.0500, 31.0000),
('Alexandria Main University Hospital', 'Alexandria', 'El-Khartoum Square', 31.2001, 29.9187),
('Gamal Abdel Nasser Hospital', 'Alexandria', 'Smouha', 31.2156, 29.9553),
('Assiut University Hospital', 'Assiut', 'Assiut University Campus', 27.1886, 31.1714),
('El Rajhi Liver Hospital', 'Assiut', 'Assiut University', 27.1900, 31.1720),
('Sohag University Hospital', 'Sohag', 'Sohag University', 26.5622, 31.6951),
('Qena General Hospital', 'Qena', 'Qena City Center', 26.1642, 32.7267),
('Luxor International Hospital', 'Luxor', 'Kornish El Nile', 25.6872, 32.6396),
('Aswan University Hospital', 'Aswan', 'Aswan University', 24.0889, 32.8998),
('Mansoura University Hospital', 'Dakahlia', 'El-Gomhoria St', 31.0419, 31.3785),
('Tanta University Hospital', 'Gharbia', 'El-Geish St', 30.7865, 31.0004),
('Zagazig University Hospital', 'Sharqia', 'Zagazig University', 30.5877, 31.5020),
('Benha University Hospital', 'Qalyubia', 'Benha City', 30.4695, 31.1837),
('Minya University Hospital', 'Minya', 'Minya University', 28.0871, 30.7618),
('Beni Suef University Hospital', 'Beni Suef', 'Beni Suef University', 29.0661, 31.0994),
('Fayoum General Hospital', 'Fayoum', 'Fayoum City', 29.3084, 30.8428),
('Nasser Institute Hospital', 'Cairo', 'Corniche El Nile, Shubra', 30.0875, 31.2450),
('Al Salam International Hospital', 'Cairo', 'Maadi', 29.9602, 31.2575),
('Saudi German Hospital Cairo', 'Cairo', 'New Cairo', 30.0156, 31.4913),
('Cleopatra Hospital', 'Cairo', 'Heliopolis', 30.0912, 31.3228),
('Dar Al Shefa Hospital', 'Cairo', 'Abbassia', 30.0725, 31.2760),
('Al Mokattam Hospital', 'Cairo', 'Mokattam', 30.0193, 31.3037),
('El Maadi Military Hospital', 'Cairo', 'Maadi', 29.9681, 31.2696),
('Cairo Specialized Hospital', 'Cairo', 'Heliopolis', 30.0935, 31.3176),
('New Cairo Hospital', 'Cairo', '5th Settlement', 30.0285, 31.4919),
('Helwan General Hospital', 'Cairo', 'Helwan', 29.8482, 31.3349),

('6th October Central Hospital', 'Giza', '6th October City', 29.9737, 30.9445),
('October University Hospital', 'Giza', '6th October City', 29.9792, 30.9516),
('Al Haram Hospital', 'Giza', 'Al Haram', 29.9889, 31.1423),
('Imbaba General Hospital', 'Giza', 'Imbaba', 30.0711, 31.2114),
('Omrania Hospital', 'Giza', 'Omrania', 29.9983, 31.2015),

('El Mowasat Hospital', 'Alexandria', 'Smouha', 31.2057, 29.9245),
('Alexandria Fever Hospital', 'Alexandria', 'El Hadara', 31.1960, 29.9190),
('Borg El Arab Hospital', 'Alexandria', 'Borg El Arab', 30.8856, 29.5647),
('El Amreya General Hospital', 'Alexandria', 'Amreya', 31.1342, 29.8031),
('Victoria Hospital', 'Alexandria', 'Victoria', 31.2436, 29.9674),

('Minya General Hospital', 'Minya', 'Minya City', 28.1099, 30.7503),
('Beni Mazar Central Hospital', 'Minya', 'Beni Mazar', 28.5035, 30.8021),
('Mallawi General Hospital', 'Minya', 'Mallawi', 27.7314, 30.8413),

('Beni Suef General Hospital', 'Beni Suef', 'Beni Suef City', 29.0731, 31.0978),
('El Wasta Central Hospital', 'Beni Suef', 'El Wasta', 29.3375, 31.2054),

('Sohag General Hospital', 'Sohag', 'Sohag City', 26.5591, 31.6948),
('Tahta Central Hospital', 'Sohag', 'Tahta', 26.7694, 31.4970),

('Qena University Hospital', 'Qena', 'South Valley University', 26.1573, 32.7160),
('Nag Hammadi General Hospital', 'Qena', 'Nag Hammadi', 26.0497, 32.2420),

('Luxor General Hospital', 'Luxor', 'Luxor City', 25.6872, 32.6396),
('Esna Central Hospital', 'Luxor', 'Esna', 25.2934, 32.5535),

('Kom Ombo Central Hospital', 'Aswan', 'Kom Ombo', 24.4761, 32.9463),
('Edfu General Hospital', 'Aswan', 'Edfu', 24.9792, 32.8734),
('Shibin El Kom Teaching Hospital', 'Menoufia', 'Shibin El Kom City', 30.5539, 31.0123),
('Menoufia University Hospital', 'Menoufia', 'Menoufia University', 30.5671, 31.0126),
('Kafr El Sheikh General Hospital', 'Kafr El Sheikh', 'Kafr El Sheikh City', 31.1117, 30.9390),
('Desouk General Hospital', 'Kafr El Sheikh', 'Desouk City', 31.1310, 30.6450),
('Damietta General Hospital', 'Damietta', 'Damietta City', 31.4175, 31.8144),
('New Damietta Hospital', 'Damietta', 'New Damietta', 31.4300, 31.8200),
('Damanhur Teaching Hospital', 'Beheira', 'Damanhur City', 31.0341, 30.4682),
('Kafr El Dawar General Hospital', 'Beheira', 'Kafr El Dawar', 31.1325, 30.1294),
('Ismailia General Hospital', 'Ismailia', 'Ismailia City', 30.5965, 32.2715),
('Suez General Hospital', 'Suez', 'Suez City', 29.9668, 32.5498),
('Port Said General Hospital', 'Port Said', 'Port Said City', 31.2653, 32.3019),
('Arish General Hospital', 'North Sinai', 'El Arish', 31.1313, 33.7984),
('Sharm El Sheikh International Hospital', 'South Sinai', 'Sharm El Sheikh', 27.9158, 34.3299),
('Hurghada General Hospital', 'Red Sea', 'Hurghada City', 27.2579, 33.8116),
('Safaga Central Hospital', 'Red Sea', 'Safaga City', 26.7498, 33.9389),
('Marsa Matruh General Hospital', 'Matrouh', 'Marsa Matruh City', 31.3543, 27.2373),
('Siwa Central Hospital', 'Matrouh', 'Siwa Oasis', 29.2041, 25.5197),
('El Tor General Hospital', 'South Sinai', 'El Tor City', 28.2394, 33.6228),
('Banha Teaching Hospital', 'Qalyubia', 'Banha City', 30.4695, 31.1837),
('Shubra El Kheima Central Hospital', 'Qalyubia', 'Shubra El Kheima', 30.1240, 31.2422),
('Heliopolis General Hospital','Cairo','Heliopolis',30.1040,31.3350),
('Nasr City General Hospital','Cairo','Nasr City',30.0600,31.3300),
('Ain Shams Specialized Hospital','Cairo','Ain Shams',30.0810,31.2900),
('Mataria Teaching Hospital','Cairo','Mataria',30.1160,31.2905),
('El Marg Central Hospital','Cairo','El Marg',30.1630,31.3356),

('Dokki General Hospital','Giza','Dokki',30.0380,31.2120),
('Agouza Hospital','Giza','Agouza',30.0540,31.2115),
('Bulaq El Dakrour Hospital','Giza','Bulaq El Dakrour',30.0335,31.2001),
('Haram Specialized Hospital','Giza','Al Haram',29.9900,31.1400),
('Sheikh Zayed Central Hospital','Giza','Sheikh Zayed',30.0495,31.0022),

('Sidi Gaber Hospital','Alexandria','Sidi Gaber',31.2150,29.9420),
('Gleem Hospital','Alexandria','Gleem',31.2345,29.9552),
('Montaza Hospital','Alexandria','Montaza',31.2850,30.0120),
('Agami Central Hospital','Alexandria','Agami',31.1315,29.7660),
('Abu Qir Hospital','Alexandria','Abu Qir',31.3201,30.0625),

('Mahalla General Hospital','Gharbia','El Mahalla El Kubra',30.9701,31.1665),
('Kafr El Zayat Hospital','Gharbia','Kafr El Zayat',30.8240,30.8162),
('Zefta Central Hospital','Gharbia','Zefta',30.7131,31.2440),
('Basyoun General Hospital','Gharbia','Basyoun',30.9390,30.8190),
('Samannoud Central Hospital','Gharbia','Samannoud',30.9610,31.2410),

('Belqas Central Hospital','Dakahlia','Belqas',31.2150,31.3570),
('Mit Ghamr Hospital','Dakahlia','Mit Ghamr',30.7152,31.2600),
('Aga Central Hospital','Dakahlia','Aga',30.9390,31.2905),
('Sherbin Hospital','Dakahlia','Sherbin',31.1972,31.5230),
('Dekernes General Hospital','Dakahlia','Dekernes',31.0885,31.5941),

('Faqous General Hospital','Sharqia','Faqous',30.7252,31.7964),
('Belbeis Central Hospital','Sharqia','Belbeis',30.4200,31.5620),
('Abu Hammad Hospital','Sharqia','Abu Hammad',30.6750,31.6760),
('Hehia Central Hospital','Sharqia','Hehia',30.6735,31.5870),
('Minya El Qamh Hospital','Sharqia','Minya El Qamh',30.3120,31.3620),

('El Fashn Central Hospital','Beni Suef','El Fashn',28.8240,30.8990),
('Nasser Central Hospital','Beni Suef','Nasser',29.1390,31.1250),
('Biba General Hospital','Beni Suef','Biba',28.9190,31.0900),

('Samalut General Hospital','Minya','Samalut',28.3120,30.7100),
('Abu Qurqas Central Hospital','Minya','Abu Qurqas',27.9310,30.8380),
('Maghagha Hospital','Minya','Maghagha',28.6480,30.8420),

('Girga General Hospital','Sohag','Girga',26.3380,31.8910),
('El Balyana Central Hospital','Sohag','El Balyana',26.2400,32.0020),

('Qus Central Hospital','Qena','Qus',25.9150,32.7630),
('Farshout Hospital','Qena','Farshout',26.0540,32.1620),

('Armant Central Hospital','Luxor','Armant',25.6190,32.5430),
('Tod Hospital','Luxor','Tod',25.7000,32.6700),

('Daraw Central Hospital','Aswan','Daraw',24.4160,32.9440),
('Nasr El Nuba Hospital','Aswan','Nasr El Nuba',24.7080,32.9980),

('Ras Gharib Hospital','Red Sea','Ras Gharib',28.3510,33.0810),
('Quseir Central Hospital','Red Sea','Quseir',26.1030,34.2780),

('Bir El Abd Hospital','North Sinai','Bir El Abd',31.0170,33.0080),
('Sheikh Zuweid Hospital','North Sinai','Sheikh Zuweid',31.2150,34.0030),
('Al-Munira Hospital','Cairo','El-Munira, Cairo',30.0450,31.2300),
('El-Zahraa Hospital','Cairo','El-Zahraa, Cairo',30.0620,31.2430),
('El-Nozha Hospital','Cairo','El-Nozha, Cairo',30.1045,31.3135),
('El-Maadi General Hospital','Cairo','Maadi, Cairo',29.9720,31.2715),
('El-Hekma Hospital','Cairo','Heliopolis, Cairo',30.1000,31.3300),
('El-Shorouk Hospital','Cairo','Shorouk City',30.1650,31.4850),
('New Cairo Specialized Hospital','Cairo','5th Settlement, New Cairo',30.0180,31.4960),
('El-Salam Hospital','Cairo','Nasr City, Cairo',30.0605,31.3305),
('Helwan Central Hospital','Cairo','Helwan, Cairo',29.8500,31.3400),
('Imbaba Specialized Hospital','Giza','Imbaba, Giza',30.0650,31.2150),

('6th October International Hospital','Giza','6th October City',29.9750,30.9450),
('Agouza Teaching Hospital','Giza','Agouza, Giza',30.0545,31.2110),
('Dokki Central Hospital','Giza','Dokki, Giza',30.0385,31.2125),
('Bulaq El-Dakrour Hospital','Giza','Bulaq El-Dakrour',30.0330,31.2010),
('Haram Specialized Hospital','Giza','Al-Haram, Giza',29.9875,31.1420),
('Sheikh Zayed Teaching Hospital','Giza','Sheikh Zayed City',30.0480,31.0050),
('El-Giza General Hospital','Giza','Giza City',30.0130,31.2080),
('El-Omraniya Hospital','Giza','Omraniya, Giza',30.0000,31.2000),
('Al-Hawamdeya Hospital','Giza','Al-Hawamdeya',30.0105,31.2200),
('El-Warraq Hospital','Giza','El-Warraq',30.0630,31.1820),

('Sidi Gaber Teaching Hospital','Alexandria','Sidi Gaber',31.2155,29.9410),
('Gleem General Hospital','Alexandria','Gleem',31.2340,29.9550),
('Montaza International Hospital','Alexandria','Montaza',31.2850,30.0125),
('Agami Specialized Hospital','Alexandria','Agami',31.1310,29.7665),
('Victoria Central Hospital','Alexandria','Victoria',31.2430,29.9670),
('El-Maamoura Hospital','Alexandria','El-Maamoura',31.2315,29.9645),
('El-Hadara Teaching Hospital','Alexandria','El-Hadara',31.1965,29.9195),
('El-Montazah Specialized Hospital','Alexandria','El-Montazah',31.2855,30.0110),
('Borg El-Arab Hospital','Alexandria','Borg El-Arab',30.8835,29.5620),
('El-Amreya Central Hospital','Alexandria','El-Amreya',31.1345,29.8025),

('Assiut University Teaching Hospital','Assiut','Assiut University',27.1885,31.1715),
('El-Rajhi Hospital','Assiut','Assiut City',27.1905,31.1725),
('Assiut Specialized Hospital','Assiut','Assiut City',27.2000,31.1800),
('Abnoub Hospital','Assiut','Abnoub',27.1650,31.1805),
('El-Ghanayem Hospital','Assiut','El-Ghanayem',27.1500,31.1850),
('Sahel Selim Hospital','Assiut','Sahel Selim',27.1105,31.1950),
('Manfalout Hospital','Assiut','Manfalout',27.1805,31.1705),
('Al-Fath Hospital','Assiut','Al-Fath',27.1750,31.1735),
('El-Badari Hospital','Assiut','El-Badari',27.1250,31.1800),
('El-Desouky Hospital','Assiut','El-Desouky',27.1405,31.1825),

('Sohag University Hospital','Sohag','Sohag University',26.5625,31.6950),
('Tahta Central Hospital','Sohag','Tahta',26.7705,31.4975),
('Girga Specialized Hospital','Sohag','Girga',26.3385,31.8915),
('El-Balyana Hospital','Sohag','El-Balyana',26.2405,32.0025),
('Akhmim General Hospital','Sohag','Akhmim',26.6005,31.7000),
('Sohag Central Hospital','Sohag','Sohag City',26.5600,31.6930),
('Juhayna Hospital','Sohag','Juhayna',26.2800,31.8100),
('Dar El Salam Hospital','Sohag','Dar El Salam',26.2700,31.7900),
('Sohag International Hospital','Sohag','Sohag City',26.5650,31.6980),
('El-Maragha Hospital','Sohag','El-Maragha',26.2550,31.7850),

('Qena General Hospital','Qena','Qena City',26.1640,32.7260),
('Nag Hammadi Hospital','Qena','Nag Hammadi',26.0485,32.2425),
('Dendera Hospital','Qena','Dendera',26.1575,32.7005),
('Abu Tesht Hospital','Qena','Abu Tesht',26.1420,32.6800),
('Qena University Hospital','Qena','Qena University',26.1600,32.7200),
('Naqada Hospital','Qena','Naqada',26.1875,32.6775),
('Farshout Hospital','Qena','Farshout',26.0535,32.1625),
('Qus Central Hospital','Qena','Qus',25.9155,32.7635),
('El-Waqf Hospital','Qena','El-Waqf',26.1505,32.7205),
('El-Karnak Hospital','Luxor','Luxor City',25.6975,32.6410),

('Armant Hospital','Luxor','Armant',25.6195,32.5435),
('Tod Hospital','Luxor','Tod',25.7005,32.6705),
('Esna Central Hospital','Luxor','Esna',25.2935,32.5535),
('Deir El-Bahari Hospital','Luxor','Deir El-Bahari',25.7200,32.6400),
('Luxor Specialized Hospital','Luxor','Luxor City',25.6905,32.6395),
('Kom Ombo Hospital','Aswan','Kom Ombo',24.4765,32.9465),
('Edfu Central Hospital','Aswan','Edfu',24.9795,32.8735),
('Aswan University Hospital','Aswan','Aswan University',24.0895,32.8995),
('Daraw Central Hospital','Aswan','Daraw',24.4165,32.9445),
('Nasr El Nuba Hospital','Aswan','Nasr El Nuba',24.7085,32.9985),

('Sharm El Sheikh International Hospital','South Sinai','Sharm El Sheikh',27.9165,34.3305),
('El-Tor Hospital','South Sinai','El-Tor',28.2405,33.6235),
('Nuweiba Central Hospital','South Sinai','Nuweiba',29.0315,34.7525),
('Dahab Hospital','South Sinai','Dahab',28.4975,34.5145),
('Taba General Hospital','South Sinai','Taba',29.4915,34.8955),
('Hurghada International Hospital','Red Sea','Hurghada',27.2585,33.8125),
('Marsa Alam Central Hospital','Red Sea','Marsa Alam',25.0665,34.8765),
('Safaga Hospital','Red Sea','Safaga',26.7505,33.9395),
('Ras Gharib Hospital','Red Sea','Ras Gharib',28.3525,33.0825),
('Quseir Central Hospital','Red Sea','Quseir',26.1045,34.2795),
('57357 Children Cancer Hospital','Cairo','El Haram, Cairo',30.0163,31.1820),
('National Cancer Institute','Cairo','Kasr Al Ainy',30.0301,31.2305),
('Abdel Kader Fahmy Hospital','Cairo','Bab El Louk',30.0550,31.2270),
('Adam International Hospital','Cairo','Zamalek',30.0776,31.2111),
('Al Hussein University Hospital','Cairo','El Hussein',30.0598,31.2391),
('Ain Shams Specialized Hospital','Cairo','Abbasia, Cairo',30.0750,31.2850),
('Anglo American Hospital','Cairo','Zamalek',30.0810,31.2140),
('Arab Contractors Medical Center','Cairo','Gamaleya, Cairo',30.0590,31.2480),
('Behman Hospital','Cairo','Maadi',29.9685,31.2735),
('Cairo Kidney Center','Cairo','Dokki',30.0408,31.2218),

('El Badary Central Hospital','Cairo','El Badary, Cairo',30.0930,31.2350),
('El Galaa Hospital for Armed Forces','Cairo','Nasr City',30.0590,31.3090),
('ElQassasin Central Hospital','Sharqia','El Qassasin',30.4760,31.4810),
('El Mahalla Cardiac Center','Gharbia','El Mahalla El Kobra',30.9680,31.1680),
('El Mahalla El Kobra General Hospital','Gharbia','El Mahalla El Kobra',30.9690,31.1690),
('El Mebarrah Hospital','Cairo','El Mebarrah',30.0450,31.2400),
('El Moalemeen Hospital','Cairo','El Moalemeen',30.0340,31.2260),
('El Rahma Hospital','Cairo','El Rahma',30.0290,31.2220),
('El Ramad Hospital of Zagazig','Sharqia','Zagazig',30.5710,31.5070),
('El Salloum Central Hospital','Matrouh','El Salloum',31.1300,27.2640),

('Children''s Cancer Hospital 57357 - Branch','Giza','Imbaba, Giza',30.0700,31.2070),
('Misr International Hospital','Giza','Dokki, Giza',30.0385,31.2070),
('El Salam International Hospital of Alameda','Cairo','Maadi, Cairo',29.9580,31.2670),
('Italian Hospital','Cairo','Abbassieh, Cairo',30.0300,31.2600),
('El Zahraa Specialized Hospital','Cairo','El Zahraa',30.0620,31.2440),
('National Heart Institute','Cairo','Lycée El Horreya St',30.0465,31.2365),
('Theodor Bilharz Research Institute','Cairo','Rod El Farag',30.0980,31.2240),
('Abou Mannaa Hospital','Cairo','Abou Mannaa',30.0720,31.2540),
('El Qantara Sharq Central Hospital','Ismailia','El Qantara Sharq',30.5450,32.2670),
('Shifa Specialist Hospital','Cairo','Cairo',30.0470,31.2330),
('Sidi Salem Central Hospital','Beheira','Sidi Salem',31.0250,30.4470),

('El Hamoul Central Hospital','Beheira','El Hamoul',31.1260,30.6980),
('El Hegaz Specialized Hospital','Cairo','Cairo',30.0480,31.2250),
('Qalioub Central Hospital','Qalyubia','Qalyubia',30.1250,31.2430),
('Giza International Hospital for Applicants','Giza','Giza City',30.0150,31.2050),
('Hawaa Hospital','Cairo','Cairo',30.0400,31.2300),
('El Manial Specialized University Hospital','Cairo','El Manial',30.0620,31.2320),
('El Eman General Hospital','Assiut','Assiut City',27.2000,31.1800),
('El Bayadeya Hospital','Assiut','Assiut City',27.1950,31.1750),
('El Qenaiat Central Hospital','Giza','Giza City',30.0200,31.2150),
('El Qornaa Hospital','Giza','Giza City',30.0280,31.2250),

('One Day Surgery Hospital - Samallout','Minya','Samallout',28.3130,30.7100),
('El Badary Hospital','Asyut','Asyut City',27.1800,31.1830),
('Ankawa Central Hospital','Minya','Minya City',28.1090,30.7510),
('El Eman Specialized Hospital','Minya','Minya City',28.1070,30.7560),
('Mekka Specialized Hospital','Cairo','Cairo',30.0500,31.2300),
('Rashid General Hospital','Cairo','Cairo',30.0485,31.2310),
('Salah El Din Hospital','Cairo','Cairo',30.0475,31.2335),
('Sohag Cancer Centre','Sohag','Sohag City',26.5620,31.6960),
('Tanta New General Hospital','Gharbia','Tanta',30.7860,31.0010),
('Luxor International Hospital','Luxor','Luxor City',25.6900,32.6400),

('Nasser Institute for Research & Treatment','Cairo','Cairo',30.0490,31.2350),
('National Women’s Health Center','Cairo','Cairo',30.0480,31.2400),
('Al Borg Hospital','Cairo','Mohandessin',30.0470,31.2170),
('Egyptian Red Crescent Hospital','Cairo','Cairo',30.0460,31.2300),
('New Gezira Hospital','Cairo','Zamalek',30.0760,31.2180),
('Gezira Polyclinic','Cairo','Zamalek',30.0750,31.2140),
('Orthopedic Specialty Hospital','Cairo','Cairo',30.0420,31.2340),
('Dar el Oyoun Hospital','Cairo','Cairo',30.0480,31.2320),
('El Mabarra Hospital','Cairo','Cairo',30.0440,31.2330),
('El Merghany Hospital','Cairo','Cairo',30.0460,31.2310),

('El Qouseya Central Hospital','Sharqia','El Qouseya',30.4720,31.5840),
('El Quseir Hospital','Red Sea','Quseir',26.1040,34.2790),
('South Sinai Hospital','South Sinai','Sharm El Sheikh',27.9160,34.3300),
('Hassab Hospital','Alexandria','Alexandria',31.2000,29.9170),
('Al Hadra University Hospital','Alexandria','Al Hadrah',31.2100,29.9150),
('Borg El Arab University Hospital','Alexandria','New Borg El Arab',31.1790,29.8890),
('Elite Hospital','Alexandria','Alexandria',31.1717,29.9435),
('Andalusia Al Shalalat Clinics','Alexandria','Alexandria',31.2110,29.9210),
('Al Amal Physical Therapy Center','Cairo','Maadi',29.9585,31.2620),
('OsteoEgypt Medical Park Premier','Cairo','Cairo',30.0500,31.2350),
('Dr. Hossam Abol Atta Hospital','Cairo','Cairo',30.0105,31.2945),
('Golden Heart Center','Cairo','Cairo',30.0200,31.2350),
('Islamic Awareness Hospital','Cairo','Cairo',30.0150,31.2370),
('Dar El Salam Hospital','Cairo','Cairo',30.0480,31.2330);

SELECT COUNT(*) AS Hospitals FROM Hospitals;
SELECT COUNT(*) AS Donors FROM Donors;
SELECT COUNT(*) AS Patients FROM Patients;
SELECT COUNT(*) AS Forecast FROM BloodStockForecast;

-- 1️⃣ Drop Foreign Key constraint between Donors and DateDimension if it exists
IF EXISTS (
    SELECT * FROM sys.foreign_keys 
    WHERE name = 'FK_Donors_DateDimension'
)
BEGIN
    ALTER TABLE Donors
    DROP CONSTRAINT FK_Donors_DateDimension;
END

-- 2️⃣ Drop added column in Donors table if it exists
IF EXISTS (
    SELECT * FROM sys.columns 
    WHERE Name = 'LastDonationDateKey' 
    AND Object_ID = Object_ID('Donors')
)
BEGIN
    ALTER TABLE Donors
    DROP COLUMN LastDonationDateKey;
END

-- 3️⃣ Drop DateDimension table if it exists
IF OBJECT_ID('DateDimension', 'U') IS NOT NULL
BEGIN
    DROP TABLE DateDimension;
END

-- 4️⃣ Drop Foreign Key constraint between BloodStockForecast and Hospitals if it exists
IF EXISTS (
    SELECT * FROM sys.foreign_keys 
    WHERE name = 'FK_BloodStockForecast_Hospital'
)
BEGIN
    ALTER TABLE BloodStockForecast
    DROP CONSTRAINT FK_BloodStockForecast_Hospital;
END

CREATE TABLE DateDimension (
    DateKey INT PRIMARY KEY,
    FullDate DATE,
    Year INT,
    Quarter INT,
    Month INT,
    MonthName NVARCHAR(20),
    DayOfMonth INT,
    DayOfWeek INT,
    DayName NVARCHAR(20),
    IsWeekend BIT,
    WeekOfYear INT
);

ALTER TABLE BloodStockForecast
ADD DateKey INT;

INSERT INTO DateDimension
SELECT DISTINCT
    CONVERT(INT, FORMAT(forecast_date,'yyyyMMdd')) AS DateKey,
    forecast_date,
    YEAR(forecast_date),
    DATEPART(QUARTER, forecast_date),
    MONTH(forecast_date),
    DATENAME(MONTH, forecast_date),
    DAY(forecast_date),
    DATEPART(WEEKDAY, forecast_date),
    DATENAME(WEEKDAY, forecast_date),
    CASE WHEN DATEPART(WEEKDAY, forecast_date) IN (6,7) THEN 1 ELSE 0 END,
    DATEPART(WEEK, forecast_date)
FROM BloodStockForecast;

UPDATE BloodStockForecast
SET DateKey = CONVERT(INT, FORMAT(forecast_date,'yyyyMMdd'));

ALTER TABLE BloodStockForecast
ADD CONSTRAINT FK_Forecast_Date
FOREIGN KEY (DateKey)
REFERENCES DateDimension(DateKey);

USE BloodShortage;
GO

-- ============================
-- 1️⃣ Create DateDimension table if it does not exist
-- ============================
IF OBJECT_ID('DateDimension', 'U') IS NULL
BEGIN
    CREATE TABLE DateDimension (
        DateKey INT PRIMARY KEY,
        FullDate DATE,
        Year INT,
        Quarter INT,
        Month INT,
        MonthName NVARCHAR(20),
        DayOfMonth INT,
        DayOfWeek INT,
        DayName NVARCHAR(20),
        IsWeekend BIT,
        WeekOfYear INT
    );
END
GO

-- ============================
-- 2️⃣ Add DateKey column to Fact Table if it does not exist
-- ============================
IF COL_LENGTH('BloodStockForecast', 'DateKey') IS NULL
BEGIN
    ALTER TABLE BloodStockForecast
    ADD DateKey INT;
END
GO

-- ============================
-- 3️⃣ Populate DateDimension with records from BloodStockForecast
-- ============================
INSERT INTO DateDimension (DateKey, FullDate, Year, Quarter, Month, MonthName, DayOfMonth, DayOfWeek, DayName, IsWeekend, WeekOfYear)
SELECT DISTINCT
    CONVERT(INT, FORMAT(forecast_date,'yyyyMMdd')) AS DateKey,
    forecast_date,
    YEAR(forecast_date),
    DATEPART(QUARTER, forecast_date),
    MONTH(forecast_date),
    DATENAME(MONTH, forecast_date),
    DAY(forecast_date),
    DATEPART(WEEKDAY, forecast_date),
    DATENAME(WEEKDAY, forecast_date),
    CASE WHEN DATEPART(WEEKDAY, forecast_date) IN (6,7) THEN 1 ELSE 0 END,
    DATEPART(WEEK, forecast_date)
FROM BloodStockForecast b
WHERE NOT EXISTS (
    SELECT 1 FROM DateDimension d
    WHERE d.DateKey = CONVERT(INT, FORMAT(b.forecast_date,'yyyyMMdd'))
);
GO

-- ============================
-- 4️⃣ Update DateKey values in BloodStockForecast table
-- ============================
UPDATE BloodStockForecast
SET DateKey = CONVERT(INT, FORMAT(forecast_date,'yyyyMMdd'))
WHERE DateKey IS NULL;
GO

-- ============================
-- 5️⃣ Establish the Foreign Key relationship between BloodStockForecast and DateDimension
-- ============================
IF NOT EXISTS (
    SELECT * FROM sys.foreign_keys 
    WHERE name = 'FK_Forecast_Date'
)
BEGIN
    ALTER TABLE BloodStockForecast
    ADD CONSTRAINT FK_Forecast_Date
    FOREIGN KEY (DateKey)
    REFERENCES DateDimension(DateKey);
END
GO

-- Fix Donor Distribution (Force 20% Commitment Rate)
UPDATE Donors
SET committed = CASE 
    WHEN ABS(CHECKSUM(NEWID())) % 100 < 20 THEN 1 
    ELSE 0 
END;
GO

-- Fix Patient Distribution (Force 65% Received / 35% Pending Rate)
-- First, skew the numeric boolean logic
UPDATE Patients
SET received = CASE 
    WHEN ABS(CHECKSUM(NEWID())) % 100 < 65 THEN 1 
    ELSE 0 
END;
GO
-- Second, synchronize the text status to match the exact math above
UPDATE Patients
SET status = CASE 
    WHEN received = 1 THEN 'Received' 
    ELSE 'Pending' 
END;
GO

-- Apply clinical probability distribution to Patient Blood Pressure
-- 70% Normal, 20% High, 10% Low
UPDATE Dim_Patients
SET blood_pressure_level = 
    CASE 
        WHEN RAND() <= 0.70 THEN 'Normal'
        WHEN RAND() <= 0.90 THEN 'High'
        ELSE 'Low' 
    END;

-- Convert Donor Commitment from Binary to Descriptive Text
ALTER TABLE Dim_Donors 
ALTER COLUMN committed VARCHAR(20);

UPDATE Dim_Donors
SET committed = 
    CASE 
        WHEN committed = '1' THEN 'Committed'
        ELSE 'Not Committed' 
    END;