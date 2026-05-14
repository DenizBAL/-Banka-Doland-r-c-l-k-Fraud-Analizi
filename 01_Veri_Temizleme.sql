------------------------ Null değer kontrolü ---------------------
DECLARE @TableName NVARCHAR(255) = 'Fraud'; -- Buraya tablo adınızı yazın
DECLARE @SQL NVARCHAR(MAX) = 'SELECT * FROM ' + @TableName + ' WHERE ';

SELECT @SQL = @SQL + COLUMN_NAME + ' IS NULL OR '
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = @TableName;

SET @SQL = LEFT(@SQL, LEN(@SQL) - 3);

EXEC sp_executesql @SQL;

--Tabloda boş (null) değer bulunamamıştır.

--- Standardizasyon İşlemleri
UPDATE Fraud
SET	
	Customer_Name=TRIM(Customer_Name),
	Gender=TRIM(Gender),
	State=TRIM(State),
	City=TRIM(City),
	Bank_Branch=TRIM(Bank_Branch),
	Account_Type=TRIM(Account_Type),
	Transaction_Type=TRIM(Transaction_Type),
	Transaction_Device=TRIM(Transaction_Device),
	Merchant_Category=TRIM(Merchant_Category),
	Transaction_Location=TRIM(Transaction_Location),
	Device_Type=TRIM(Device_Type)

UPDATE Fraud
SET
	Gender=UPPER(Gender),
	State=UPPER(State)


------------------------ Mantıksal Hataların Ayıklanması ---------------------
--Negatif Tutarlı işlemler ve 18 yaş sınırı.
SELECT * FROM Fraud WHERE Transaction_Amount<=0 OR Age<18 OR Age>100

--İleride Olabilecek İşlemler
SELECT * FROM Fraud WHERE Transaction_Date > GETDATE()
--Mantıksal hatalar bulunamamıştır.

------------------------Duplicate Veri Kontrolü---------------------
SELECT Transaction_ID, COUNT(*) as Tekrar_Sayisi
FROM Fraud
GROUP BY Transaction_ID
HAVING COUNT(*) > 1;

WITH CTE AS (
    SELECT Transaction_ID, 
           ROW_NUMBER() OVER (PARTITION BY Transaction_ID ORDER BY Transaction_Date) as RowNum
    FROM Fraud
)
DELETE FROM CTE WHERE RowNum > 1;
-- Duplicate veri bulunmamıştır.

------------------------ Feature Engineering ---------------------
--Analizini kolaylaştırmak için 'Transaction_Date' ve 'Transaction_Time' sütunlarını tek bir 'Full_Date' olarak birleştirelim.

ALTER TABLE Fraud ADD Full_Transaction_Date DATETIME
UPDATE Fraud SET Full_Transaction_Date= CAST(Transaction_Date AS DATETIME) + CAST(Transaction_Time AS DATETIME)
ALTER TABLE Fraud DROP COLUMN Transaction_Date,Transaction_Time

SELECT TOP 10 Transaction_Date,Transaction_Time,Full_Transaction_Date FROM Fraud

------------------------Aykırı (OUTLIER) Değer Tespiti---------------------
DECLARE @AvgAmount FLOAT
SELECT @AvgAmount =AVG(Transaction_Amount) FROM Fraud

SELECT * FROM Fraud
WHERE Transaction_Amount>(@AvgAmount*5) -- Ortalamanın 5 katı para akışı olursa.
ORDER BY Transaction_Amount DESC
-- Aykırı değer tespit edilmemiştir.

--------------------- Veriyi Daha İyi Anlamlandırmak---------------------

---Riskli Saatler
---Dolandırıcılık vakaları genellikle normal kullanıcıların uyuduğu veya bankaların daha az izleme yaptığı saatlerde yoğunlaşabilir.

ALTER TABLE Fraud ADD Time_Segment nvarchar(20);

UPDATE Fraud
SET Time_Segment = 
    CASE 
        WHEN DATEPART(HOUR, Full_Transaction_Date) BETWEEN 0 AND 6 THEN 'Gece Yarısı'
        WHEN DATEPART(HOUR, Full_Transaction_Date) BETWEEN 7 AND 12 THEN 'Sabah'
        WHEN DATEPART(HOUR, Full_Transaction_Date) BETWEEN 13 AND 18 THEN 'Öğleden Sonra'
        ELSE 'Akşam/Gece'
    END;


---Yaş Grupları
---Bazı dolandırıcılık türleri yaşlıları hedef alırken, bazıları gençlerin dijital alışkanlıklarını kullanır.
ALTER TABLE Fraud ADD Age_Group nvarchar(20);
UPDATE Fraud
SET Age_Group = 
    CASE 
        WHEN Age < 25 THEN 'Genç'
        WHEN Age BETWEEN 25 AND 50 THEN 'Yetişkin'
        WHEN Age BETWEEN 51 AND 65 THEN 'Orta Yaş'
        ELSE 'Yaşlı'
    END;
---Harcama Büyüklüğü Kategorisi
---Sadece tutara bakmak yerine, bu tutarın o hesap için ne ifade ettiğini anlamak zordur ama genel bir "İşlem Büyüklüğü" etiketi analizi kolaylaştırır.

ALTER TABLE Fraud ADD Transaction_Size NVARCHAR(10)
UPDATE Fraud
SET Transaction_Size=
        CASE    
            WHEN Transaction_Amount<100 THEN 'Küçük'
            WHEN Transaction_Amount BETWEEN 100 AND 1000 THEN 'Orta'
            WHEN Transaction_Amount BETWEEN 1001 AND 5000 THEN 'Büyük'
            ELSE 'Çok Büyük'
        END;

