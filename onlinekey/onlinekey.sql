DROP TABLE IF EXISTS `t_bd_onlinekey`;
CREATE TABLE `t_bd_onlinekey` (
  `fid` varchar(255) NOT NULL DEFAULT '',
  `fcunum` varchar(20) DEFAULT NULL,
  `fclienttype` varchar(30) DEFAULT NULL,
  `fpersonid` varchar(50) DEFAULT NULL,
  `fexpiretime` datetime DEFAULT NULL,
  PRIMARY KEY (`fid`)
) DEFAULT CHARSET=utf8;
