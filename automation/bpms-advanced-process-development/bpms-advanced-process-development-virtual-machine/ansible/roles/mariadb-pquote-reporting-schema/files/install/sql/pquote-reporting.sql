DROP TABLE if exists `PQUOTE_REPORTING`;

CREATE TABLE `FACT_QUOTES`
  (
    `age`  int(11) NOT NULL,
    `creditScore` int(11) NOT NULL,
    `dlNumber` VARCHAR(50) NULL,
    `driverName`   VARCHAR(100) NOT NULL,
    `numberOfAccidents` int(11) NOT NULL,
    `numberOfTickets` int(11) NOT NULL,
    `ssn` int(11) NOT NULL,
    `policyType` VARCHAR(20) NULL,
    `price` int(11) NOT NULL,
    `priceDiscount` int(11) NOT NULL,
    `vehicleYear` int(11) NOT NULL,
    `processInstanceId` int(11) NOT NULL,
    `quote_month` int(11) NOT NULL,
    `quote_year` int(11) NOT NULL,
    `purchased` bit(1) NOT NULL DEFAULT 0,
    `bounced` bit(1) NOT NULL DEFAULT 0,
    `bounced_price` bit(1) NOT NULL DEFAULT 0,
    `bounced_beneffits` bit(1) NOT NULL DEFAULT 0,
    `bounced_terms` bit(1) NOT NULL DEFAULT 0,
    `bounced_service` bit(1) NOT NULL DEFAULT 0,
    `bounced_other` bit(1) NOT NULL DEFAULT 0
);

CREATE TABLE `FACT_INCIDENTS`
  (
    `incident_month`  INT(11) NOT NULL,
    `incident_year` INT(11) NOT NULL,
    `driver_age` INT(11) NOT NULL,
    `policy_age_months` INT(11) NOT NULL,
    `reason_texting` bit(1) NOT NULL DEFAULT 0,
    `reason_calling` bit(1) NOT NULL DEFAULT 0,
    `reason_eating` bit(1) NOT NULL DEFAULT 0,
    `reason_chatting` bit(1) NOT NULL DEFAULT 0,
    `reason_drinking` bit(1) NOT NULL DEFAULT 0,
    `reason_intoxicated` bit(1) NOT NULL DEFAULT 0,
    `reason_illness` bit(1) NOT NULL DEFAULT 0,
    `reason_weather` bit(1) NOT NULL DEFAULT 0,
    `reason_wrong_road_signals` bit(1) NOT NULL DEFAULT 0,
    `reason_road_visibility` bit(1) NOT NULL DEFAULT 0,
    `reason_mechanical_failure` bit(1) NOT NULL DEFAULT 0,
    `reason_missed_signal` bit(1) NOT NULL DEFAULT 0,
    `reason_other` bit(1) NOT NULL DEFAULT 0,
    `state` varchar(30) NOT NULL,
    `driver_young` bit(1) NOT NULL DEFAULT 0,
    `driver_adult` bit(1) NOT NULL DEFAULT 0,
    `driver_elder` bit(1) NOT NULL DEFAULT 0
);

DELIMITER //
CREATE FUNCTION `randomRangePicker`
(
  minRange INT,
  maxRange INT
) RETURNS int(11)
BEGIN
  DECLARE pick INT;
  SET pick = minRange + FLOOR(RAND() * (maxRange - minRange + 1));
  RETURN pick;
END //
CREATE FUNCTION `randomSSN`
() RETURNS VARCHAR(9)
BEGIN
  DECLARE ssn VARCHAR(9);
  DECLARE i TINYINT;
  SET i = 0;
  SET SSN = CONCAT('', randomRangePicker(1,9));
  label_s: LOOP
    SET i = i + 1;
    IF i < 8 THEN
      SET SSN = CONCAT(SSN, randomRangePicker(0,9));
      ITERATE label_s;
    END IF;
    LEAVE label_s;
  END LOOP label_s;
  RETURN ssn;
END //
CREATE PROCEDURE prc_generate_quote_mock (IN idx INT)
BEGIN
  DECLARE lAgeMin INT;
  DECLARE lAgeMax INT;
  DECLARE lAge INT;

  DECLARE lBounced BIT;
  DECLARE lBounceReasonCode TINYINT;
  SET lBounceReasonCode = randomRangePicker(0,9);
  SET lBounced = 0;

  SET lAgeMin = 16;
  SET lAgeMax = 80;
  SET lAge = randomRangePicker(lAgeMin, lAgeMax);

  CASE WHEN randomRangePicker(1,4) < 4
    THEN
      SET lBounced = 0;
    ELSE
      BEGIN
        SET lBounced = 1;
      END;
  END CASE;

  INSERT INTO FACT_QUOTES(
      age,
      creditScore,
      dlnumber,
      driverName,
      numberOfAccidents,
      numberOfTickets,
      ssn,
      policyType,
      price,
      priceDiscount,
      vehicleYear,
      processInstanceId,
      quote_month,
      quote_year,
      purchased,
      bounced,
      bounced_price,
      bounced_beneffits,
      bounced_terms,
      bounced_service,
      bounced_other)
  VALUES(
    lAge,
    randomRangePicker(250, 750),
    CONCAT('DL', randomRangePicker(1000, 10000)),
    CONCAT_WS(' ', 'DRIVER', randomRangePicker(1000, 10000)),
    randomRangePicker(0,4),
    randomRangePicker(0,4),
    randomSSN(),
    'CAR',
    randomRangePicker(150,750),
    randomRangePicker(0,25),
    randomRangePicker(2007, 2017),
    idx,
    randomRangePicker(1,12),
    randomRangePicker(2015,2016),
    CASE WHEN lBounced = 0 THEN 1 ELSE 0 END,
    lBounced,
    CASE WHEN lBounceReasonCode <= 1 AND lBounced = 1 THEN 1 ELSE 0 END,
    CASE WHEN lBounceReasonCode <= 2 AND lBounceReasonCode > 1 AND lBounced = 1 THEN 1 ELSE 0 END,
    CASE WHEN lBounceReasonCode <= 5 AND lBounceReasonCode > 1 AND lBounced = 1 THEN 1 ELSE 0 END,
    CASE WHEN lBounceReasonCode > 5 AND lBounceReasonCode < 9 AND lBounced = 1 THEN 1 ELSE 0 END,
    CASE WHEN lBounceReasonCode = 9 AND lBounced = 1 THEN 1 ELSE 0 END
  );
END //

CREATE PROCEDURE prc_generate_mocks (IN records INT)
BEGIN
  DECLARE i INT;
  SET i = 0;
  label_q: LOOP
    SET i = i + 1;
    IF i < records THEN
      CALL prc_generate_quote_mock(i);
      ITERATE label_q;
    END IF;
    LEAVE label_q;
  END LOOP label_q;
  SET i = 0;
END //
DELIMITER ;
CALL prc_generate_mocks(1500);
