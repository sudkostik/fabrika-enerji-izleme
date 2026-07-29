USE TestDB;   -- Kendi veritabani adinizla degistirin


/* ---------- View'i (varsa) sil ve yeniden olustur ---------- */
IF OBJECT_ID('dbo.vw_GunlukTuketim', 'V') IS NOT NULL
    DROP VIEW dbo.vw_GunlukTuketim;


CREATE VIEW dbo.vw_GunlukTuketim AS
SELECT
    CAST([DateTime] AS DATE)                            AS Gun,
    [Type],
    [Name],
    MIN([Index])                                        AS GunBasiEndeks,
    MAX([Index])                                        AS GunSonuEndeks,
    CAST(MAX([Index]) - MIN([Index]) AS DECIMAL(18,2))  AS GunlukTuketim_kWh
FROM dbo.SayacVerileri
GROUP BY
    CAST([DateTime] AS DATE),
    [Type],
    [Name];


/* ============================================================
   KULLANIM ORNEKLERI
   ============================================================ */

-- 1) Tum sayaclarin gunluk tuketimi (tarihe ve isme gore sirali)
SELECT *
FROM dbo.vw_GunlukTuketim
ORDER BY Gun, [Type], [Name];

-- 2) Sadece cikislarin gunluk tuketimi
SELECT Gun, [Name], GunlukTuketim_kWh
FROM dbo.vw_GunlukTuketim
WHERE [Type] = 'Out'
ORDER BY Gun, [Name];

-- 3) Gunluk toplam: tum cikislar vs. ana giris (tutarlilik kontrolu)
SELECT
    Gun,
    SUM(CASE WHEN [Type] = 'Out' THEN GunlukTuketim_kWh END) AS Cikislar_Toplam_kWh,
    SUM(CASE WHEN [Type] = 'In'  THEN GunlukTuketim_kWh END) AS Giris_kWh
FROM dbo.vw_GunlukTuketim
GROUP BY Gun
ORDER BY Gun;

-- 4) Her cikisin bir aylik toplam tuketimi
SELECT [Name], SUM(GunlukTuketim_kWh) AS Aylik_Toplam_kWh
FROM dbo.vw_GunlukTuketim
WHERE [Type] = 'Out'
GROUP BY [Name]
ORDER BY Aylik_Toplam_kWh DESC;

/* ============================================================
   NOT - GUN SINIRI HASSASIYETI
   MIN/MAX yontemi, bir gunun son saati (23:00) ile ertesi gunun
   ilk saati (00:00) arasindaki tuketimi ilgili gune eklemez.
   Daha kesin gunluk tuketim isteniyorsa (bir onceki gunun son
   endeksini baz alan) LAG'li surumu asagida verilmistir.
   ============================================================ */

-- Alternatif (daha kesin) view: gun sonu endeksleri farki
IF OBJECT_ID('dbo.vw_GunlukTuketim_Kesin', 'V') IS NOT NULL
    DROP VIEW dbo.vw_GunlukTuketim_Kesin;


CREATE VIEW dbo.vw_GunlukTuketim_Kesin AS
WITH GunSonu AS (
    -- Her sayac + gun icin gunun EN SON endeksi
    SELECT
        [Type],
        [Name],
        CAST([DateTime] AS DATE) AS Gun,
        MAX([Index])             AS GunSonuEndeks
    FROM dbo.SayacVerileri
    GROUP BY [Type], [Name], CAST([DateTime] AS DATE)
)
SELECT
    Gun,
    [Type],
    [Name],
    GunSonuEndeks,
    CAST(
        GunSonuEndeks
        - LAG(GunSonuEndeks) OVER (PARTITION BY [Name] ORDER BY Gun)
        AS DECIMAL(18,2)
    ) AS GunlukTuketim_kWh
FROM GunSonu;
