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
