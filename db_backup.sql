-- InfraLab Local Dev Stack
-- Database: accounts

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- ----------------------------
-- Table: role
-- ----------------------------
DROP TABLE IF EXISTS `role`;
CREATE TABLE `role` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;

INSERT INTO `role` VALUES
(1,'ROLE_USER'),
(2,'ROLE_ADMIN');

-- ----------------------------
-- Table: user
-- ----------------------------
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(255) DEFAULT NULL,
  `userEmail` varchar(255) DEFAULT NULL,
  `dateOfBirth` varchar(255) DEFAULT NULL,
  `fatherName` varchar(255) DEFAULT NULL,
  `motherName` varchar(255) DEFAULT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `maritalStatus` varchar(255) DEFAULT NULL,
  `permanentAddress` varchar(255) DEFAULT NULL,
  `nationality` varchar(255) DEFAULT NULL,
  `language` varchar(255) DEFAULT NULL,
  `primaryOccupation` varchar(255) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

INSERT INTO `user` VALUES
(1,'admin','admin@infralab.local','25/09/1997','Francisco Iglesias','Clara Reguant','male','Married','Barcelona, Spain','Spanish','Catalan, Spanish, English','System Administrator','$2b$11$xtX1r8mu8YS80aBSsLq/nO5/ztnCodlfrXNdZtZIg.1FlKCwBJ.By'),
(2,'jon.snow','jon@infralab.local','N/A','Eddard Stark','N/A','male','Single','Castle Black, The Wall','Northerner','Common Tongue','Lord Commander','$2b$11$tkzgoAYJALjCRVsB1EBNBui5UqZrXfWjoOHGfRns/XS1fDssdxtfa'),
(3,'arya.stark','arya@infralab.local','N/A','Eddard Stark','Catelyn Tully','female','Single','Braavos','Northerner','Common Tongue','Faceless Assassin','$2b$11$tkzgoAYJALjCRVsB1EBNBui5UqZrXfWjoOHGfRns/XS1fDssdxtfa'),
(4,'tyrion.lannister','tyrion@infralab.local','N/A','Tywin Lannister','Joanna Lannister','male','Divorced','Casterly Rock','Westerosi','Common Tongue, High Valyrian','Hand of the Queen','$2b$11$tkzgoAYJALjCRVsB1EBNBui5UqZrXfWjoOHGfRns/XS1fDssdxtfa'),
(5,'daenerys.targaryen','dany@infralab.local','N/A','Aerys Targaryen','Rhaella Targaryen','female','Widowed','Dragonstone','Valyrian','Common Tongue, High Valyrian, Dothraki','Queen of the Seven Kingdoms','$2b$11$tkzgoAYJALjCRVsB1EBNBui5UqZrXfWjoOHGfRns/XS1fDssdxtfa');

-- ----------------------------
-- Table: user_role
-- ----------------------------
DROP TABLE IF EXISTS `user_role`;
CREATE TABLE `user_role` (
  `user_id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  PRIMARY KEY (`user_id`,`role_id`),
  KEY `fk_user_role_roleid_idx` (`role_id`),
  CONSTRAINT `fk_user_role_roleid` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_user_role_userid` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `user_role` VALUES
(1,2),  -- admin             -> ROLE_ADMIN
(2,1),  -- jon.snow          -> ROLE_USER
(3,1),  -- arya.stark        -> ROLE_USER
(4,1),  -- tyrion.lannister  -> ROLE_USER
(5,1);  -- daenerys          -> ROLE_USER

/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;
/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;
