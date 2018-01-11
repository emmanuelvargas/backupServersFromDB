-- phpMyAdmin SQL Dump
-- version 4.1.9
-- http://www.phpmyadmin.net
--
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `production`
--

-- --------------------------------------------------------

--
-- Table structure for table `AccountProcess`
--

CREATE TABLE IF NOT EXISTS `AccountProcess` (
	  `idAccount` char(36) NOT NULL,
	  `idProcess` int(10) unsigned NOT NULL,
	  PRIMARY KEY (`idAccount`,`idProcess`),
	  KEY `idAccount` (`idAccount`),
	  KEY `idProcess` (`idProcess`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;

	-- --------------------------------------------------------

--
-- Table structure for table `Cabinet`
--

CREATE TABLE IF NOT EXISTS `Cabinet` (
	  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
	  `idRoom` int(11) unsigned NOT NULL,
	  `cabinet_name` varchar(150) CHARACTER SET latin1 NOT NULL,
	  `cabinet_height` int(2) unsigned NOT NULL,
	  `air_flow` enum('cold corridor','front to back','back to front') DEFAULT NULL,
	  `sockets_type` int(2) unsigned NOT NULL,
	  `voltage` int(4) unsigned NOT NULL,
	  `sockets_number` int(2) unsigned NOT NULL,
	  `primary_power` int(5) unsigned NOT NULL,
	  `backup_power` int(5) unsigned NOT NULL,
	  `setup_date` date NOT NULL,
	  `service_term` int(2) unsigned DEFAULT NULL,
	  `setup_fees` int(4) unsigned DEFAULT NULL,
	  `monthly_costs` int(4) unsigned DEFAULT NULL,
	  `gallery_url` varchar(255) DEFAULT NULL,
	  `archive` enum('0','1') NOT NULL DEFAULT '0',
	  `archive_date` date DEFAULT NULL,
	  `archive_note` varchar(256) DEFAULT NULL,
	  `note` text CHARACTER SET latin1,
	  PRIMARY KEY (`id`)
	) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=149 ;

	-- --------------------------------------------------------

--
-- Table structure for table `Cabinet_Files`
--

CREATE TABLE IF NOT EXISTS `Cabinet_Files` (
	  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	  `id_cabinet` int(10) unsigned NOT NULL,
	  `id_file` int(10) unsigned NOT NULL,
	  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	  PRIMARY KEY (`id`)
	) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

	-- --------------------------------------------------------

--
-- Table structure for table `Datacenter`
--

CREATE TABLE IF NOT EXISTS `Datacenter` (
	  `id` int(11) unsigne--------------------------------------------

--
-- Table structure for table `Process`
--

CREATE TABLE IF NOT EXISTS `Process` (
	  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
	  `id_process_type` int(10) unsigned NOT NULL,
	  `miscprocess` enum('0','1') NOT NULL DEFAULT '0',
	  `idServer` int(11) unsigned DEFAULT NULL,
	  `name` varchar(255) CHARACTER SET latin1 NOT NULL,
	  `usage_name` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
	  `service_desk_ticket_creation_request` int(6) unsigned DEFAULT NULL,
	  `service_desk_ticket_misc` varchar(50) DEFAULT NULL,
	  `internal_usage` enum('0','1') DEFAULT '0',
	  `orderforms` varchar(255) DEFAULT NULL,
	  `OBSOLETE_nb_CPU_used` int(11) unsigned DEFAULT NULL,
	  `taMARY KEY (`id`)
	) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=2239 ;

	-- --------------------------------------------------------

--
-- Table structure for table `Process_Connection`
--

CREATE TABLE IF NOT EXISTS `Process_Connection` (
	  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
	  `child` int(10) unsigned NOT NULL,
	  `parent` int(10) unsigned NOT NULL,
	  `feed_type` varchar(50) NOT NULL,
	  `protocol` enum('tcp','mcast') NOT NULL,
	  `mcast_id` varchar(7) NOT NULL,
	  `ref_dl_time` varchar(50) NOT NULL,
	  `ref_exchange_name` varchar(200) NOT NULL,
	  `ref_exchange_mcast_id` varchar(7) NOT NULL,
	  `creation_date` r(60)
	,`server_DRAC` varchar(60)
	,`process_id` int(11) unsigned
	,`process_type` varchar(50)
	,`process_name` varchar(255)
	,`process_usage_name` varchar(255)
	,`process_tag` varchar(50)
	,`process_is_backup` enum('0','1')
	,`process_backup` varchar(255)
	,`process_prod` enum('0','1')
	,`process_archive` enum('0','1')
	,`process_display_dashboard` enum('0','1')
	,`process_timeperiod` varchar(200)
	,`process_timezone` varchar(50)
	,`process_swarm` enum('0','1')
	,`process_swarmIP` varchar(60)
	,`process_multicastID` varchar(100)
	,`process_source_id` varchar(50)
	,`process_intraday` enum('0','1')
	,`process_daily` enum('0','1')
	,`process_internalIP` varchar(60)
	,`process_port` bigint(11)
	);
	-- --------------------------------------------------------

--
-- Stand-in structure for view `Prod_Processes_Light`
--
CREATE TABLE IF NOT EXISTS `Prod_Processes_Light` (
	`process_id` int(11) unsigned
	,`process_type` varchar(50)
	,`process_name` varchar(255)
	,`process_usage_name` varchar(255)
	,`process_prod` enum('0','1')
	,`process_swarm` enum('0','1')
	,`process_archive` enum('0','1')
	,`process_internalIP` varchar(60)
	,`process_port` int(5)
	);
	-- --------------------------------------------------------


--
-- Stand-in structure for view `Prod_Servers`
--
CREATE TABLE IF NOT EXISTS `Prod_Servers` (
	`server_id` int(11) unsigned
	,`server_name` varchar(255)
	,`server_tag` varchar(255)
	,`server_operating_system` varchar(250)
	,`server_owner` varchar(150)
	,`server_managed_by` varchar(150)
	,`server_used_by` varchar(150)
	,`server_region` varchar(20)
	,`server_archive` enum('0','1')
	,`server_reachable` enum('0','1')
	);
	-- --------------------------------------------------------

