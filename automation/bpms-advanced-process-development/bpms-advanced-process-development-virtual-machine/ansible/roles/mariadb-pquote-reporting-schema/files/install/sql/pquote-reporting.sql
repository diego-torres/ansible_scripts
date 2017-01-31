DROP TABLE if exists `PQUOTE_REPORTING`;

DROP TABLE if exists `DIM_STATES`;

create table `DIM_STATES`
(
`state_id`   smallint    unsigned not null auto_increment comment 'PK: State ID',
`state_name` varchar(32) not null comment 'State name with first letter capital',
`state_abbr` varchar(8)  comment 'Optional state abbreviation (US 2 cap letters)',
primary key (state_id)
);

insert into `DIM_STATES`
values
(NULL, 'Alabama', 'AL'),
(NULL, 'Alaska', 'AK'),
(NULL, 'Arizona', 'AZ'),
(NULL, 'Arkansas', 'AR'),
(NULL, 'California', 'CA'),
(NULL, 'Colorado', 'CO'),
(NULL, 'Connecticut', 'CT'),
(NULL, 'Delaware', 'DE'),
(NULL, 'District of Columbia', 'DC'),
(NULL, 'Florida', 'FL'),
(NULL, 'Georgia', 'GA'),
(NULL, 'Hawaii', 'HI'),
(NULL, 'Idaho', 'ID'),
(NULL, 'Illinois', 'IL'),
(NULL, 'Indiana', 'IN'),
(NULL, 'Iowa', 'IA'),
(NULL, 'Kansas', 'KS'),
(NULL, 'Kentucky', 'KY'),
(NULL, 'Louisiana', 'LA'),
(NULL, 'Maine', 'ME'),
(NULL, 'Maryland', 'MD'),
(NULL, 'Massachusetts', 'MA'),
(NULL, 'Michigan', 'MI'),
(NULL, 'Minnesota', 'MN'),
(NULL, 'Mississippi', 'MS'),
(NULL, 'Missouri', 'MO'),
(NULL, 'Montana', 'MT'),
(NULL, 'Nebraska', 'NE'),
(NULL, 'Nevada', 'NV'),
(NULL, 'New Hampshire', 'NH'),
(NULL, 'New Jersey', 'NJ'),
(NULL, 'New Mexico', 'NM'),
(NULL, 'New York', 'NY'),
(NULL, 'North Carolina', 'NC'),
(NULL, 'North Dakota', 'ND'),
(NULL, 'Ohio', 'OH'),
(NULL, 'Oklahoma', 'OK'),
(NULL, 'Oregon', 'OR'),
(NULL, 'Pennsylvania', 'PA'),
(NULL, 'Rhode Island', 'RI'),
(NULL, 'South Carolina', 'SC'),
(NULL, 'South Dakota', 'SD'),
(NULL, 'Tennessee', 'TN'),
(NULL, 'Texas', 'TX'),
(NULL, 'Utah', 'UT'),
(NULL, 'Vermont', 'VT'),
(NULL, 'Virginia', 'VA'),
(NULL, 'Washington', 'WA'),
(NULL, 'West Virginia', 'WV'),
(NULL, 'Wisconsin', 'WI'),
(NULL, 'Wyoming', 'WY');

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
    `state_id` smallint NOT NULL REFERENCES `DIM_STATES`(`state_id`) ON DELETE CASCADE,
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
    IF i <= 8 THEN
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
CREATE PROCEDURE prc_generate_incidents_mock()
BEGIN

  DECLARE lAgeMin INT;
  DECLARE lAgeMax INT;
  DECLARE lAge INT;

  DECLARE lIncidentCode INT;

  SET lAgeMin = 16;
  SET lAgeMax = 80;
  SET lAge = randomRangePicker(lAgeMin, lAgeMax);

  SET lIncidentCode = randomRangePicker(0,30);

  INSERT INTO `FACT_INCIDENTS`
  (`incident_month`,
    `incident_year`,
    `driver_age`,
    `policy_age_months`,
    `reason_texting`,
    `reason_calling`,
    `reason_eating`,
    `reason_chatting`,
    `reason_drinking`,
    `reason_intoxicated`,
    `reason_illness`,
    `reason_weather`,
    `reason_wrong_road_signals`,
    `reason_road_visibility`,
    `reason_mechanical_failure`,
    `reason_missed_signal`,
    `reason_other`,
    `state_id`,
    `driver_young`,
    `driver_adult`,
    `driver_elder`)
  VALUES(
    randomRangePicker(1,12),
    randomRangePicker(2015,2016),
    lAge,
    randomRangePicker(1,72),
    CASE WHEN lIncidentCode <= 3 THEN 1 ELSE 0 END,
    CASE WHEN lIncidentCode <= 5 AND lIncidentCode > 3 THEN 1 ELSE 0 END,
    CASE WHEN lIncidentCode <= 7 AND lIncidentCode > 5 THEN 1 ELSE 0 END,
    CASE WHEN lIncidentCode <= 9 AND lIncidentCode > 7 THEN 1 ELSE 0 END,
    CASE WHEN lIncidentCode <= 11 AND lIncidentCode > 9 THEN 1 ELSE 0 END,
    CASE WHEN lIncidentCode <= 15 AND lIncidentCode > 11 THEN 1 ELSE 0 END,
    CASE WHEN lIncidentCode <= 18 AND lIncidentCode > 15 THEN 1 ELSE 0 END,
    CASE WHEN lIncidentCode <= 20 AND lIncidentCode > 18 THEN 1 ELSE 0 END,
    CASE WHEN lIncidentCode <= 22 AND lIncidentCode > 20 THEN 1 ELSE 0 END,
    CASE WHEN lIncidentCode <= 24 AND lIncidentCode > 22 THEN 1 ELSE 0 END,
    CASE WHEN lIncidentCode <= 26 AND lIncidentCode > 24 THEN 1 ELSE 0 END,
    CASE WHEN lIncidentCode <= 29 AND lIncidentCode > 26 THEN 1 ELSE 0 END,
    CASE WHEN lIncidentCode = 30 THEN 1 ELSE 0 END,
    randomRangePicker(1,50),
    CASE WHEN lAge < 25 THEN 1 ELSE 0 END,
    CASE WHEN lAge >= 25 AND lAge < 65 THEN 1 ELSE 0 END,
    CASE WHEN lAge >= 65 THEN 1 ELSE 0 END
  );
END //
CREATE PROCEDURE prc_generate_mocks (IN records INT)
BEGIN
  DECLARE i INT;
  SET i = 0;
  label_q: LOOP
    SET i = i + 1;
    IF i <= records THEN
      CALL prc_generate_quote_mock(i);
      CALL prc_generate_incidents_mock();
      ITERATE label_q;
    END IF;
    LEAVE label_q;
  END LOOP label_q;
  SET i = 0;
END //
DELIMITER ;
CALL prc_generate_mocks(1500);
