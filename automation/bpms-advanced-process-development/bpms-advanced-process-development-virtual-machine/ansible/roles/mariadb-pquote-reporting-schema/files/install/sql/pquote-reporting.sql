DROP TABLE if exists `PQUOTE_REPORTING`;

CREATE TABLE `PQUOTE_REPORTING`
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
    `processInstanceId` int(11) NOT NULL
);
