use telecom;

###############################################################
## Creates a table with one fixedbb price per country per year
## The cheapest price is taken of all those available per 
## country/year with a speed in the range 0.25-30 Mbit/s
## and at least 1GB/month of usage. 256 kbit/s is the OECD/ITU
## min speed for broadband, 30 Mbit/s is the EU threshold for
## high speed. 1GB/month: defined bb usage per month by ITU
## Obvious outliers removed (probable errors data entry/currency
###############################################################

DROP TABLE IF EXISTS fixedbb_summary;
CREATE TABLE fixedbb_summary AS
SELECT 	CountryCode,
		`Year` AS IndicatorYear,
        min(Price) as IndicatorValue
FROM
	(SELECT CountryCode,
			`Year`,
			Price,
			Speed,
			CASE
				WHEN Cap = "Unlimited" THEN convert(10000,decimal(10,2))
				ELSE convert(Cap, decimal(10,2))
			END CapConverted
            FROM fixedbb_prices) b
WHERE b.Speed >= 0.256 AND b.Speed < 30 AND b.CapConverted >= 1000 AND Price > 5 AND Price < 500
GROUP BY CountryCode, IndicatorYear;


###############################################################
## Creates a table with one mobilebb price per country per year
## The cheapest price is taken of all those available per 
## country/year with a cap of 1 GB/month and a 30 day validity
## Those packages with a lower cap and/or validity are taken
## X times to reach the min validity/cap. Then min is taken.
## 1GB/month, 30 day validity: defined bb usage per month by ITU
###############################################################

DROP TABLE IF EXISTS mobilebb_summary;
CREATE TABLE mobilebb_summary AS
SELECT 	CountryCode,
		`Year` AS IndicatorYear,
        min(PriceConverted) as IndicatorValue
FROM
	(SELECT CountryCode,
			`Year`,
			Price,
            Cap,
            Validity,
            Contract,
            CASE
				WHEN (Cap = "Unlimited" OR Cap >= 1000)  AND (VALIDITY = "UNLIMITED" OR VALIDITY >= 30) THEN Price
				WHEN (Cap = "Unlimited" OR Cap >= 1000) THEN Price * 30 / convert(Validity, decimal(10,2))
                WHEN (VALIDITY = "UNLIMITED" OR VALIDITY >= 30) THEN Price * 1000/convert(Cap, decimal(10,2))
                WHEN (1000/convert(Cap, decimal(10,2)) > 30 / convert(Validity, decimal(10,2))) THEN 
						Price * 1000/convert(Cap, decimal(10,2))
                ELSE Price * 30 / convert(Validity, decimal(10,2))
			END PriceConverted
	FROM mobilebb_prices) b
WHERE PriceConverted < 500 
GROUP BY CountryCode, IndicatorYear;


###############################################################
## Creates a table with the data from the LCC table
## plus a column indicating whether a given value is estimated 
## (TRUE) or not estimated (FALSE). This table will be filled
## in by the classification algorithm.
###############################################################

DROP TABLE IF EXISTS LCCs_completed;
CREATE TABLE LCCs_completed AS
SELECT 	*,
		CASE
			WHEN LCC IS NULL THEN true
            ELSE false
		END estimate
FROM LCCs;

ALTER TABLE LCCs_completed
ADD PRIMARY KEY (CountryCode, `Year`);
