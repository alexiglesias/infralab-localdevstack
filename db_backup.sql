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
  `profileImg` varchar(255) DEFAULT NULL,
  `profileImgPath` varchar(255) DEFAULT NULL,
  `dateOfBirth` varchar(255) DEFAULT NULL,
  `fatherName` varchar(255) DEFAULT NULL,
  `motherName` varchar(255) DEFAULT NULL,
  `gender` varchar(255) DEFAULT NULL,
  `maritalStatus` varchar(255) DEFAULT NULL,
  `permanentAddress` varchar(255) DEFAULT NULL,
  `tempAddress` varchar(255) DEFAULT NULL,
  `primaryOccupation` varchar(255) DEFAULT NULL,
  `secondaryOccupation` varchar(255) DEFAULT NULL,
  `skills` varchar(255) DEFAULT NULL,
  `phoneNumber` varchar(255) DEFAULT NULL,
  `secondaryPhoneNumber` varchar(255) DEFAULT NULL,
  `nationality` varchar(255) DEFAULT NULL,
  `language` varchar(255) DEFAULT NULL,
  `workingExperience` varchar(255) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

INSERT INTO `user` VALUES
(1,'admin','admin@infralab.local',NULL,NULL,'01/01/1990','N/A','N/A','N/A','N/A','Barcelona, Spain','Barcelona, Spain','System Administrator','DevOps Engineer','Linux Bash Docker Kubernetes','600000001','600000001','Spanish','Catalan, Spanish, English','10','$2a$11$0a7VdTr4rfCQqtsvpng6GuJnzUmQ7gZiHXgzGPgm5hkRa3avXgBLK'),
(2,'jon.snow','jon@infralab.local',NULL,NULL,'01/01/1279','Eddard Stark','Lyanna Stark','male','Single','Castle Black, The Wall','Winterfell, The North','Lord Commander','King in the North','Leadership Swordsmanship Stealth','600000002','600000002','Northerner','Common Tongue','10','$2a$11$UgG9TkHcgl02LxlqxRHYhOf7Xv4CxFmFEgS0FpUdk42OeslI.6JAW'),
(3,'arya.stark','arya@infralab.local',NULL,NULL,'15/03/1286','Eddard Stark','Catelyn Tully','female','Single','Braavos','Winterfell, The North','Faceless Assassin','Water Dancer','Stealth Swordsmanship Disguise','600000003','600000003','Northerner','Common Tongue, High Valyrian','5','$2a$11$gwvsvUrFU.YirMM1Yb7NweFudLUM91AzH5BDFnhkNzfzpjG.FplYO'),
(4,'tyrion.lannister','tyrion@infralab.local',NULL,NULL,'22/07/1273','Tywin Lannister','Joanna Lannister','male','Single','Casterly Rock','Kings Landing','Hand of the Queen','Master of Coin','Strategy Diplomacy Wine Tasting','600000004','600000004','Westerosi','Common Tongue, High Valyrian','8','$2a$11$6oZEgfGGQAH23EaXLVZ2WOSKxcEJFnBSw2N2aghab0s2kcxSQwjhC'),
(5,'daenerys.targaryen','dany@infralab.local',NULL,NULL,'10/11/1280','Aerys Targaryen','Rhaella Targaryen','female','Widowed','Dragonstone','Meereen','Queen of the Seven Kingdoms','Breaker of Chains','Dragon Riding Leadership Diplomacy','600000005','600000005','Valyrian','Common Tongue, High Valyrian, Dothraki','6','$2a$11$EXwpna1MlFFlKW5ut1iVi.AoeIulkPPmcOHFO8pOoQt1IYU9COU0m');

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
