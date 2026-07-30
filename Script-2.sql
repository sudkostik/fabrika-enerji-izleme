USE TestDB;

SELECT * FROM Satislar;

USE TestDB;   -- Kendi veritabani adinizla degistirin


/* ---------- 1) Tabloyu (varsa) sil ve yeniden olustur ---------- */
IF OBJECT_ID('dbo.SayacVerileri','U') IS NOT NULL
    DROP TABLE dbo.SayacVerileri;


CREATE TABLE dbo.SayacVerileri (
    Id         INT IDENTITY(1,1) PRIMARY KEY,
    [DateTime] DATETIME       NOT NULL,   -- Saat basi zaman damgasi
    [Type]     NVARCHAR(3)    NOT NULL,   -- 'In' = giris, 'Out' = cikis
    [Name]     NVARCHAR(50)   NOT NULL,   -- Sayac adi
    [Index]    DECIMAL(18,2)  NOT NULL    -- kWh cinsinden artan endeks
);


BEGIN
DECLARE @Start DATETIME = '2026-06-01 00:00:00';
DECLARE @End   DATETIME = '2026-07-01 00:00:00';

IF OBJECT_ID('tempdb..#Cikislar') IS NOT NULL DROP TABLE #Cikislar;
CREATE TABLE #Cikislar (
    Name       NVARCHAR(50),
    Amps       INT,                       -- Salter akim kapasitesi (A)
    StartIndex DECIMAL(18,2)              -- Baslangic endeksi (10.000 - 100.000)
);

INSERT INTO #Cikislar (Name, Amps, StartIndex) VALUES
(N'Döküm 1',       160, 0),
(N'Döküm 2',       160, 0),
(N'Döküm 3',       160, 0),
(N'Döküm 8',       100, 0),
(N'Döküm 10',      100, 0),
(N'Kumlamalar',    160, 0),
(N'Kompresörler',  400, 0),
(N'Transfer',      160, 0),
(N'Chiller',       160, 0),
(N'Boyahane',      100, 0),
(N'Beyaz Chiller', 100, 0),
(N'CNC',           100, 0),
(N'Ortak Alan',    100, 0),
(N'Pota Besleme',  160, 0);

/* Her cikis icin 10.000 - 100.000 arasi rastgele baslangic endeksi */
UPDATE #Cikislar
SET StartIndex = 10000 + ABS(CHECKSUM(NEWID())) % 90001;

/* ---------- 3) Saatlik zaman damgalari + saatlik artislar ---------- */
/* Artis (kWh) = Amps * rastgele(0.15 - 0.45)
   -> 160 A icin ~24-72 kWh/saat, 400 VAC yuk profiline uygun     */
IF OBJECT_ID('tempdb..#Artis') IS NOT NULL DROP TABLE #Artis;

;WITH Saatler AS (
    SELECT @Start AS Ts
    UNION ALL
    SELECT DATEADD(HOUR, 1, Ts) FROM Saatler WHERE Ts < @End
)
SELECT
    c.Name,
    c.StartIndex,
    s.Ts,
    CAST(c.Amps * (15 + ABS(CHECKSUM(NEWID())) % 31) / 100.0 AS DECIMAL(18,2)) AS Artis
INTO #Artis
FROM Saatler s
CROSS JOIN #Cikislar c
OPTION (MAXRECURSION 1000);   -- 721 saat icin recursion limitini yukselt

/* ---------- 4) CIKIS (Out) satirlarini yaz ---------- */
/* Endeks = baslangic + o ana kadarki artislarin kumulatif toplami */
INSERT INTO dbo.SayacVerileri ([DateTime], [Type], [Name], [Index])
SELECT
    a.Ts,
    'Out',
    a.Name,
    a.StartIndex
      + SUM(a.Artis) OVER (PARTITION BY a.Name ORDER BY a.Ts
                           ROWS UNBOUNDED PRECEDING)
FROM #Artis a;

/* ---------- 5) GIRIS (In) satirlarini yaz ---------- */
/* Ana giris endeksi, her saat tum cikislarin artis toplami kadar artar
   -> giris sayaci alt cikislarin toplamiyla tutarli ilerler          */
DECLARE @GirisStart DECIMAL(18,2) = 500000 + ABS(CHECKSUM(NEWID())) % 100001;

;WITH SaatToplam AS (
    SELECT Ts, SUM(Artis) AS ToplamArtis
    FROM #Artis
    GROUP BY Ts
)
INSERT INTO dbo.SayacVerileri ([DateTime], [Type], [Name], [Index])
SELECT
    Ts,
    'In',
    N'Ana Giriş',
    @GirisStart
      + SUM(ToplamArtis) OVER (ORDER BY Ts ROWS UNBOUNDED PRECEDING)
FROM SaatToplam;

/* ---------- 6) Temizlik ---------- */
DROP TABLE #Artis;
DROP TABLE #Cikislar;

END


