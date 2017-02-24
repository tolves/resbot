-- phpMyAdmin SQL Dump
-- version 4.5.1
-- http://www.phpmyadmin.net
--
-- Host: 127.0.0.1
-- Generation Time: Feb 23, 2017 at 10:55 AM
-- Server version: 10.1.13-MariaDB
-- PHP Version: 5.6.23

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `salt_res`
--

-- --------------------------------------------------------

--
-- Table structure for table `activity`
--

CREATE TABLE `activity` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `detail` text NOT NULL,
  `secret_level` int(11) NOT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL,
  `active` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `activity`
--

INSERT INTO `activity` (`id`, `name`, `detail`, `secret_level`, `created_on`, `updated_on`, `active`) VALUES
(1, 'df', '', 0, '2017-02-23 17:08:13', '0000-00-00 00:00:00', 1),
(2, 'fsdf', '', 0, '2017-02-23 17:08:15', '0000-00-00 00:00:00', 1),
(3, '瑞特人他', '', 0, '2017-02-23 17:08:27', '0000-00-00 00:00:00', 1),
(4, '味儿', '', 0, '2017-02-23 17:18:54', '0000-00-00 00:00:00', 1),
(5, '水电费', '', 0, '2017-02-23 17:49:51', '0000-00-00 00:00:00', 1),
(6, '味儿', '', 0, '2017-02-23 17:52:33', '0000-00-00 00:00:00', 1);

-- --------------------------------------------------------

--
-- Table structure for table `activity_duty`
--

CREATE TABLE `activity_duty` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `activity_duty`
--

INSERT INTO `activity_duty` (`id`, `name`) VALUES
(1, '碎片地面组mod位'),
(2, '碎片地面组清障');

-- --------------------------------------------------------

--
-- Table structure for table `activity_users`
--

CREATE TABLE `activity_users` (
  `id` int(11) NOT NULL,
  `activity_id` int(11) NOT NULL,
  `telegram_id` int(11) NOT NULL,
  `duty` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `activity_users`
--

INSERT INTO `activity_users` (`id`, `activity_id`, `telegram_id`, `duty`) VALUES
(1, 6, 75708608, 1);

-- --------------------------------------------------------

--
-- Table structure for table `authority_name`
--

CREATE TABLE `authority_name` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `authority_name`
--

INSERT INTO `authority_name` (`id`, `name`) VALUES
(1, 'admin'),
(2, 'approver'),
(3, 'trusted'),
(4, 'rookie'),
(5, 'untrusted'),
(6, 'waiting');

-- --------------------------------------------------------

--
-- Table structure for table `profile`
--

CREATE TABLE `profile` (
  `id` int(11) NOT NULL,
  `telegram_id` int(11) NOT NULL,
  `level` tinyint(4) NOT NULL,
  `ap` bigint(20) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `profile`
--

INSERT INTO `profile` (`id`, `telegram_id`, `level`, `ap`) VALUES
(1, 0, 16, 49931676);

-- --------------------------------------------------------

--
-- Table structure for table `secret_level`
--

CREATE TABLE `secret_level` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `secret_level`
--

INSERT INTO `secret_level` (`id`, `name`) VALUES
(1, '十分机密'),
(2, '一般保密'),
(3, '普通'),
(4, '开放');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(8) NOT NULL,
  `agent_id` varchar(255) NOT NULL,
  `telegram_id` int(8) NOT NULL,
  `telegram_username` varchar(255) NOT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL,
  `authority` int(11) NOT NULL DEFAULT '6'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `agent_id`, `telegram_id`, `telegram_username`, `created_on`, `updated_on`, `authority`) VALUES
(1, 'tolves', 75708608, 'tolves', '2017-02-08 00:00:00', '2017-02-01 00:00:00', 1),
(2, 'jiamin', 234234, 'jiamin', '2017-02-02 00:00:00', '2017-02-03 00:00:00', 4);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `activity`
--
ALTER TABLE `activity`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `activity_duty`
--
ALTER TABLE `activity_duty`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `activity_users`
--
ALTER TABLE `activity_users`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `authority_name`
--
ALTER TABLE `authority_name`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `profile`
--
ALTER TABLE `profile`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `secret_level`
--
ALTER TABLE `secret_level`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `agent_id` (`agent_id`),
  ADD UNIQUE KEY `telegram_id` (`telegram_id`),
  ADD KEY `authority` (`authority`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity`
--
ALTER TABLE `activity`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `activity_duty`
--
ALTER TABLE `activity_duty`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `activity_users`
--
ALTER TABLE `activity_users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `authority_name`
--
ALTER TABLE `authority_name`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;
--
-- AUTO_INCREMENT for table `profile`
--
ALTER TABLE `profile`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `secret_level`
--
ALTER TABLE `secret_level`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;
--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(8) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
--
-- Constraints for dumped tables
--

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `users_ibfk_1` FOREIGN KEY (`authority`) REFERENCES `authority_name` (`id`);

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
