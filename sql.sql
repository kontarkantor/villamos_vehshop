CREATE TABLE `owned_vehicles` (
	`owner` varchar(60) NOT NULL,
	`plate` varchar(12) NOT NULL,
	`vehicle` longtext NOT NULL,
	`type` VARCHAR(20) NOT NULL DEFAULT 'car',
	`job` VARCHAR(20) NOT NULL DEFAULT 'civ',
	`stored` TINYINT(1) NOT NULL DEFAULT '0',

	PRIMARY KEY (`plate`)
);

CREATE TABLE `vehicles` (
	`name` varchar(60) NOT NULL,
	`model` varchar(60) NOT NULL,
	`price` int(11) NOT NULL,
    `category` varchar(60) NOT NULL,
	`image` longtext DEFAULT NULL,

	PRIMARY KEY (`model`)
);