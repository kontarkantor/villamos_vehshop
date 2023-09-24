CREATE TABLE IF NOT EXISTS `owned_vehicles` (
	`owner` varchar(60) NOT NULL,
	`plate` varchar(12) NOT NULL,
	`vehicle` longtext NOT NULL,
	`type` VARCHAR(20) NOT NULL DEFAULT 'car',
	`job` VARCHAR(20) NOT NULL DEFAULT 'civ',
	`stored` TINYINT(1) NOT NULL DEFAULT '0',

	PRIMARY KEY (`plate`)
);

CREATE TABLE `vehicles` (
	`model` VARCHAR(60) NOT NULL,
	`shop` VARCHAR(60) NULL DEFAULT NULL,
	`name` VARCHAR(60) NOT NULL,
	`price` INT(11) NOT NULL,
	`category` VARCHAR(60) NULL DEFAULT NULL,
	`image` TEXT NULL DEFAULT NULL,
	UNIQUE INDEX `car` (`model`, `shop`) USING BTREE
);
