------------ GENEL FRAUD GÖRÜNÜMÜ ----------------
SELECT Is_Fraud,
		COUNT(*) AS 'Total_Transactions',
		SUM(Transaction_Amount) AS 'Total_Volume',
		ROUND(AVG(Transaction_Amount),2) AS Avg_Transaction_Value
FROM Fraud
GROUP BY Is_Fraud

------------ Riskli Zaman Dilimi Analizi (Time-Based Risk) ------------
-- Time_Segment sütununu kullanarak, dolandırıcıların en aktif olduğu saatleri bulalım.
SELECT 
	Time_Segment,
	COUNT(*) AS 'Fraud_Count',
	SUM(CASE WHEN Is_Fraud=1 THEN 1 ELSE 0 END)*100/COUNT(*) AS 'Fraud_Percentage'
FROM Fraud
GROUP BY Time_Segment
ORDER BY 'Fraud_Percentage' DESC;

------------Şüpheli Müşteri Segmentleri (Demographic Risk) ------------
-- Hangi yaş grubundaki müşteriler daha çok hedef alınmış veya hangi hesap türlerinde.
SELECT 
    Age_Group,
    Account_Type,
    COUNT(*) AS Total_Transactions,
    SUM(CAST(Is_Fraud AS INT)) AS Fraud_Transactions,
    ROUND(AVG(Transaction_Amount), 2) AS Avg_Fraud_Amount
FROM Fraud
WHERE Is_Fraud = 1
GROUP BY Age_Group, Account_Type
ORDER BY Fraud_Transactions DESC;

------------ Cihaz ve Lokasyon İlişkisi (Device vs. Fraud) ------------
-- Hangi cihazlar (Device_Type) üzerinden yapılan işlemler daha riskli? Bu, bankanın hangi platformlara daha fazla güvenlik önlemi (2FA vb.) eklemesi gerektiğini gösterir.
SELECT 
    Device_Type,
    COUNT(*) AS Total_TX,
    SUM(CAST(Is_Fraud AS INT)) AS Fraud_TX,
    (SUM(CAST(Is_Fraud AS INT)) * 100.0 / COUNT(*)) AS Risk_Rate
FROM Fraud
GROUP BY Device_Type
ORDER BY Risk_Rate DESC;