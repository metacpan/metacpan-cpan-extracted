use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/time is restricted by facet minExclusive with value 00:00:00." => sub {
	my $type = mk_type('Time', {'minExclusive' => '00:00:00'});
	should_pass("00:00:01", $type, 0);
	should_pass("03:11:11", $type, 0);
	should_pass("13:07:31", $type, 0);
	should_pass("23:06:10", $type, 0);
	should_pass("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minExclusive with value 02:57:29." => sub {
	my $type = mk_type('Time', {'minExclusive' => '02:57:29'});
	should_pass("02:57:30", $type, 0);
	should_pass("04:40:10", $type, 0);
	should_pass("08:05:06", $type, 0);
	should_pass("16:53:43", $type, 0);
	should_pass("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minExclusive with value 13:38:10." => sub {
	my $type = mk_type('Time', {'minExclusive' => '13:38:10'});
	should_pass("13:38:11", $type, 0);
	should_pass("15:10:50", $type, 0);
	should_pass("15:56:14", $type, 0);
	should_pass("20:23:46", $type, 0);
	should_pass("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minExclusive with value 18:16:28." => sub {
	my $type = mk_type('Time', {'minExclusive' => '18:16:28'});
	should_pass("18:16:29", $type, 0);
	should_pass("23:15:39", $type, 0);
	should_pass("22:44:24", $type, 0);
	should_pass("20:07:23", $type, 0);
	should_pass("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minExclusive with value 23:59:58." => sub {
	my $type = mk_type('Time', {'minExclusive' => '23:59:58'});
	should_pass("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minInclusive with value 00:00:00." => sub {
	my $type = mk_type('Time', {'minInclusive' => '00:00:00'});
	should_pass("00:00:00", $type, 0);
	should_pass("06:37:23", $type, 0);
	should_pass("17:22:07", $type, 0);
	should_pass("01:39:25", $type, 0);
	should_pass("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minInclusive with value 21:11:44." => sub {
	my $type = mk_type('Time', {'minInclusive' => '21:11:44'});
	should_pass("21:11:44", $type, 0);
	should_pass("21:14:21", $type, 0);
	should_pass("23:40:37", $type, 0);
	should_pass("21:37:20", $type, 0);
	should_pass("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minInclusive with value 01:03:08." => sub {
	my $type = mk_type('Time', {'minInclusive' => '01:03:08'});
	should_pass("01:03:08", $type, 0);
	should_pass("02:38:50", $type, 0);
	should_pass("05:59:03", $type, 0);
	should_pass("16:51:26", $type, 0);
	should_pass("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minInclusive with value 19:31:35." => sub {
	my $type = mk_type('Time', {'minInclusive' => '19:31:35'});
	should_pass("19:31:35", $type, 0);
	should_pass("20:53:52", $type, 0);
	should_pass("22:28:34", $type, 0);
	should_pass("23:40:04", $type, 0);
	should_pass("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minInclusive with value 23:59:59." => sub {
	my $type = mk_type('Time', {'minInclusive' => '23:59:59'});
	should_pass("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxExclusive with value 00:00:01." => sub {
	my $type = mk_type('Time', {'maxExclusive' => '00:00:01'});
	should_pass("00:00:00", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxExclusive with value 08:19:11." => sub {
	my $type = mk_type('Time', {'maxExclusive' => '08:19:11'});
	should_pass("00:00:00", $type, 0);
	should_pass("00:57:42", $type, 0);
	should_pass("06:00:38", $type, 0);
	should_pass("06:26:36", $type, 0);
	should_pass("08:19:10", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxExclusive with value 23:35:02." => sub {
	my $type = mk_type('Time', {'maxExclusive' => '23:35:02'});
	should_pass("00:00:00", $type, 0);
	should_pass("08:50:26", $type, 0);
	should_pass("05:19:06", $type, 0);
	should_pass("10:35:34", $type, 0);
	should_pass("23:35:01", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxExclusive with value 12:25:37." => sub {
	my $type = mk_type('Time', {'maxExclusive' => '12:25:37'});
	should_pass("00:00:00", $type, 0);
	should_pass("03:02:54", $type, 0);
	should_pass("02:53:04", $type, 0);
	should_pass("00:23:56", $type, 0);
	should_pass("12:25:36", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxExclusive with value 23:59:59." => sub {
	my $type = mk_type('Time', {'maxExclusive' => '23:59:59'});
	should_pass("00:00:00", $type, 0);
	should_pass("19:23:13", $type, 0);
	should_pass("10:54:21", $type, 0);
	should_pass("06:20:41", $type, 0);
	should_pass("23:59:58", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxInclusive with value 00:00:00." => sub {
	my $type = mk_type('Time', {'maxInclusive' => '00:00:00'});
	should_pass("00:00:00", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxInclusive with value 13:46:08." => sub {
	my $type = mk_type('Time', {'maxInclusive' => '13:46:08'});
	should_pass("00:00:00", $type, 0);
	should_pass("05:22:29", $type, 0);
	should_pass("02:13:46", $type, 0);
	should_pass("06:23:18", $type, 0);
	should_pass("13:46:08", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxInclusive with value 05:07:34." => sub {
	my $type = mk_type('Time', {'maxInclusive' => '05:07:34'});
	should_pass("00:00:00", $type, 0);
	should_pass("00:07:23", $type, 0);
	should_pass("04:49:01", $type, 0);
	should_pass("02:17:28", $type, 0);
	should_pass("05:07:34", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxInclusive with value 18:06:59." => sub {
	my $type = mk_type('Time', {'maxInclusive' => '18:06:59'});
	should_pass("00:00:00", $type, 0);
	should_pass("03:11:39", $type, 0);
	should_pass("07:07:10", $type, 0);
	should_pass("03:30:13", $type, 0);
	should_pass("18:06:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxInclusive with value 23:59:59." => sub {
	my $type = mk_type('Time', {'maxInclusive' => '23:59:59'});
	should_pass("00:00:00", $type, 0);
	should_pass("14:43:02", $type, 0);
	should_pass("12:26:24", $type, 0);
	should_pass("02:23:22", $type, 0);
	should_pass("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet pattern with value \\d9:\\d2:5\\d." => sub {
	my $type = mk_type('Time', {'pattern' => qr/(?ms:^\d9:\d2:5\d$)/});
	should_pass("09:12:57", $type, 0);
	should_pass("19:12:57", $type, 0);
	should_pass("09:12:56", $type, 0);
	should_pass("19:12:58", $type, 0);
	should_pass("19:32:56", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet pattern with value \\d6:\\d9:\\d9." => sub {
	my $type = mk_type('Time', {'pattern' => qr/(?ms:^\d6:\d9:\d9$)/});
	should_pass("16:49:59", $type, 0);
	should_pass("06:59:19", $type, 0);
	should_pass("06:49:39", $type, 0);
	should_pass("06:09:49", $type, 0);
	should_pass("06:49:49", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet pattern with value 1\\d:3\\d:\\d5." => sub {
	my $type = mk_type('Time', {'pattern' => qr/(?ms:^1\d:3\d:\d5$)/});
	should_pass("10:33:45", $type, 0);
	should_pass("16:36:05", $type, 0);
	should_pass("15:35:55", $type, 0);
	should_pass("14:38:55", $type, 0);
	should_pass("16:37:05", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet pattern with value \\d8:\\d4:\\d6." => sub {
	my $type = mk_type('Time', {'pattern' => qr/(?ms:^\d8:\d4:\d6$)/});
	should_pass("18:54:16", $type, 0);
	should_pass("18:34:46", $type, 0);
	should_pass("08:14:16", $type, 0);
	should_pass("18:14:56", $type, 0);
	should_pass("18:44:06", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet pattern with value \\d0:3\\d:2\\d." => sub {
	my $type = mk_type('Time', {'pattern' => qr/(?ms:^\d0:3\d:2\d$)/});
	should_pass("00:37:22", $type, 0);
	should_pass("00:37:20", $type, 0);
	should_pass("00:33:24", $type, 0);
	should_pass("00:34:25", $type, 0);
	should_pass("10:31:23", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet enumeration." => sub {
	my $type = mk_type('Time', {'enumeration' => ['01:44:56','07:44:41','05:55:52','21:59:07','12:41:23','02:47:45','03:43:07','02:00:14','01:42:27']});
	should_pass("02:47:45", $type, 0);
	should_pass("07:44:41", $type, 0);
	should_pass("05:55:52", $type, 0);
	should_pass("01:42:27", $type, 0);
	should_pass("07:44:41", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet enumeration." => sub {
	my $type = mk_type('Time', {'enumeration' => ['10:32:33','11:18:46','06:00:33','14:01:48','11:14:02','02:02:10']});
	should_pass("11:14:02", $type, 0);
	should_pass("11:18:46", $type, 0);
	should_pass("14:01:48", $type, 0);
	should_pass("02:02:10", $type, 0);
	should_pass("06:00:33", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet enumeration." => sub {
	my $type = mk_type('Time', {'enumeration' => ['03:47:11','16:04:46','01:35:26','22:39:51','15:13:10','23:32:59','02:39:19']});
	should_pass("23:32:59", $type, 0);
	should_pass("23:32:59", $type, 0);
	should_pass("22:39:51", $type, 0);
	should_pass("15:13:10", $type, 0);
	should_pass("01:35:26", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet enumeration." => sub {
	my $type = mk_type('Time', {'enumeration' => ['18:04:07','05:41:14','15:07:15','01:18:17','01:13:21','23:24:35','15:25:08','18:20:35','03:53:17']});
	should_pass("01:18:17", $type, 0);
	should_pass("23:24:35", $type, 0);
	should_pass("05:41:14", $type, 0);
	should_pass("01:18:17", $type, 0);
	should_pass("23:24:35", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet enumeration." => sub {
	my $type = mk_type('Time', {'enumeration' => ['06:18:04','07:45:10','12:06:46','21:01:58','05:34:33','22:22:06','12:17:04']});
	should_pass("07:45:10", $type, 0);
	should_pass("05:34:33", $type, 0);
	should_pass("22:22:06", $type, 0);
	should_pass("05:34:33", $type, 0);
	should_pass("21:01:58", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('Time', {'whiteSpace' => 'collapse'});
	should_pass("00:00:00", $type, 0);
	should_pass("18:13:01", $type, 0);
	should_pass("05:12:21", $type, 0);
	should_pass("01:41:44", $type, 0);
	should_pass("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minInclusive with value 02:50:21." => sub {
	my $type = mk_type('Time', {'minInclusive' => '02:50:21'});
	should_fail("00:00:00", $type, 0);
	should_fail("01:56:56", $type, 0);
	should_fail("01:29:31", $type, 0);
	should_fail("00:24:24", $type, 0);
	should_fail("02:50:20", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minInclusive with value 06:43:33." => sub {
	my $type = mk_type('Time', {'minInclusive' => '06:43:33'});
	should_fail("00:00:00", $type, 0);
	should_fail("01:31:46", $type, 0);
	should_fail("00:06:50", $type, 0);
	should_fail("00:50:44", $type, 0);
	should_fail("06:43:32", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minInclusive with value 11:03:36." => sub {
	my $type = mk_type('Time', {'minInclusive' => '11:03:36'});
	should_fail("00:00:00", $type, 0);
	should_fail("05:39:21", $type, 0);
	should_fail("01:35:20", $type, 0);
	should_fail("00:50:16", $type, 0);
	should_fail("11:03:35", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minInclusive with value 09:12:46." => sub {
	my $type = mk_type('Time', {'minInclusive' => '09:12:46'});
	should_fail("00:00:00", $type, 0);
	should_fail("05:36:48", $type, 0);
	should_fail("00:50:52", $type, 0);
	should_fail("04:26:25", $type, 0);
	should_fail("09:12:45", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minInclusive with value 23:59:59." => sub {
	my $type = mk_type('Time', {'minInclusive' => '23:59:59'});
	should_fail("00:00:00", $type, 0);
	should_fail("04:00:40", $type, 0);
	should_fail("01:43:09", $type, 0);
	should_fail("21:44:22", $type, 0);
	should_fail("23:59:58", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxInclusive with value 00:00:00." => sub {
	my $type = mk_type('Time', {'maxInclusive' => '00:00:00'});
	should_fail("00:00:01", $type, 0);
	should_fail("03:50:03", $type, 0);
	should_fail("05:17:58", $type, 0);
	should_fail("22:25:09", $type, 0);
	should_fail("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxInclusive with value 18:28:53." => sub {
	my $type = mk_type('Time', {'maxInclusive' => '18:28:53'});
	should_fail("18:28:54", $type, 0);
	should_fail("20:12:28", $type, 0);
	should_fail("19:43:30", $type, 0);
	should_fail("22:15:48", $type, 0);
	should_fail("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxInclusive with value 13:09:12." => sub {
	my $type = mk_type('Time', {'maxInclusive' => '13:09:12'});
	should_fail("13:09:13", $type, 0);
	should_fail("22:37:25", $type, 0);
	should_fail("14:00:03", $type, 0);
	should_fail("15:19:17", $type, 0);
	should_fail("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxInclusive with value 13:51:43." => sub {
	my $type = mk_type('Time', {'maxInclusive' => '13:51:43'});
	should_fail("13:51:44", $type, 0);
	should_fail("18:14:02", $type, 0);
	should_fail("22:45:18", $type, 0);
	should_fail("18:47:55", $type, 0);
	should_fail("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxInclusive with value 02:55:06." => sub {
	my $type = mk_type('Time', {'maxInclusive' => '02:55:06'});
	should_fail("02:55:07", $type, 0);
	should_fail("18:51:45", $type, 0);
	should_fail("15:36:18", $type, 0);
	should_fail("23:34:55", $type, 0);
	should_fail("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minExclusive with value 00:00:00." => sub {
	my $type = mk_type('Time', {'minExclusive' => '00:00:00'});
	should_fail("00:00:00", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minExclusive with value 00:09:21." => sub {
	my $type = mk_type('Time', {'minExclusive' => '00:09:21'});
	should_fail("00:00:00", $type, 0);
	should_fail("00:01:37", $type, 0);
	should_fail("00:07:26", $type, 0);
	should_fail("00:09:09", $type, 0);
	should_fail("00:09:21", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minExclusive with value 10:11:47." => sub {
	my $type = mk_type('Time', {'minExclusive' => '10:11:47'});
	should_fail("00:00:00", $type, 0);
	should_fail("01:54:01", $type, 0);
	should_fail("00:29:05", $type, 0);
	should_fail("09:06:13", $type, 0);
	should_fail("10:11:47", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minExclusive with value 13:55:42." => sub {
	my $type = mk_type('Time', {'minExclusive' => '13:55:42'});
	should_fail("00:00:00", $type, 0);
	should_fail("10:04:41", $type, 0);
	should_fail("10:03:21", $type, 0);
	should_fail("04:11:15", $type, 0);
	should_fail("13:55:42", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet minExclusive with value 23:59:58." => sub {
	my $type = mk_type('Time', {'minExclusive' => '23:59:58'});
	should_fail("00:00:00", $type, 0);
	should_fail("23:18:52", $type, 0);
	should_fail("19:52:19", $type, 0);
	should_fail("13:35:32", $type, 0);
	should_fail("23:59:58", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxExclusive with value 00:00:01." => sub {
	my $type = mk_type('Time', {'maxExclusive' => '00:00:01'});
	should_fail("00:00:01", $type, 0);
	should_fail("02:05:24", $type, 0);
	should_fail("00:10:23", $type, 0);
	should_fail("16:26:28", $type, 0);
	should_fail("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxExclusive with value 22:37:46." => sub {
	my $type = mk_type('Time', {'maxExclusive' => '22:37:46'});
	should_fail("22:37:46", $type, 0);
	should_fail("23:51:55", $type, 0);
	should_fail("23:00:04", $type, 0);
	should_fail("23:07:53", $type, 0);
	should_fail("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxExclusive with value 08:48:12." => sub {
	my $type = mk_type('Time', {'maxExclusive' => '08:48:12'});
	should_fail("08:48:12", $type, 0);
	should_fail("09:36:32", $type, 0);
	should_fail("10:57:53", $type, 0);
	should_fail("22:32:25", $type, 0);
	should_fail("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxExclusive with value 10:24:23." => sub {
	my $type = mk_type('Time', {'maxExclusive' => '10:24:23'});
	should_fail("10:24:23", $type, 0);
	should_fail("15:44:07", $type, 0);
	should_fail("13:43:09", $type, 0);
	should_fail("19:46:06", $type, 0);
	should_fail("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet maxExclusive with value 23:59:59." => sub {
	my $type = mk_type('Time', {'maxExclusive' => '23:59:59'});
	should_fail("23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet pattern with value 1\\d:2\\d:\\d4." => sub {
	my $type = mk_type('Time', {'pattern' => qr/(?ms:^1\d:2\d:\d4$)/});
	should_fail("56:42:06", $type, 0);
	should_fail("41:49:38", $type, 0);
	should_fail("24:51:31", $type, 0);
	should_fail("57:19:49", $type, 0);
	should_fail("41:37:05", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet pattern with value 1\\d:0\\d:3\\d." => sub {
	my $type = mk_type('Time', {'pattern' => qr/(?ms:^1\d:0\d:3\d$)/});
	should_fail("44:26:28", $type, 0);
	should_fail("06:17:26", $type, 0);
	should_fail("47:42:05", $type, 0);
	should_fail("33:34:02", $type, 0);
	should_fail("59:17:12", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet pattern with value 0\\d:1\\d:\\d1." => sub {
	my $type = mk_type('Time', {'pattern' => qr/(?ms:^0\d:1\d:\d1$)/});
	should_fail("41:48:13", $type, 0);
	should_fail("17:38:26", $type, 0);
	should_fail("21:48:06", $type, 0);
	should_fail("25:38:35", $type, 0);
	should_fail("22:51:53", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet pattern with value 0\\d:4\\d:\\d9." => sub {
	my $type = mk_type('Time', {'pattern' => qr/(?ms:^0\d:4\d:\d9$)/});
	should_fail("58:22:17", $type, 0);
	should_fail("47:32:47", $type, 0);
	should_fail("36:37:38", $type, 0);
	should_fail("35:38:14", $type, 0);
	should_fail("28:03:27", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet pattern with value \\d0:\\d6:\\d7." => sub {
	my $type = mk_type('Time', {'pattern' => qr/(?ms:^\d0:\d6:\d7$)/});
	should_fail("03:01:42", $type, 0);
	should_fail("17:30:11", $type, 0);
	should_fail("17:39:45", $type, 0);
	should_fail("06:44:41", $type, 0);
	should_fail("06:15:33", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet enumeration." => sub {
	my $type = mk_type('Time', {'enumeration' => ['05:50:46','08:19:59','18:25:29','18:17:12','16:58:48','05:47:40','02:13:18','13:13:27','20:57:19']});
	should_fail("21:33:28", $type, 0);
	should_fail("09:52:14", $type, 0);
	should_fail("22:38:25", $type, 0);
	should_fail("16:42:35", $type, 0);
	should_fail("21:49:16", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet enumeration." => sub {
	my $type = mk_type('Time', {'enumeration' => ['22:31:41','14:22:25','01:05:23','18:15:39','13:03:07','08:53:02','19:11:09','23:10:24']});
	should_fail("22:44:51", $type, 0);
	should_fail("16:28:23", $type, 0);
	should_fail("08:39:14", $type, 0);
	should_fail("06:29:29", $type, 0);
	should_fail("21:12:57", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet enumeration." => sub {
	my $type = mk_type('Time', {'enumeration' => ['05:55:55','05:44:40','20:59:49','21:57:22','23:16:05','19:47:39','23:29:45']});
	should_fail("21:20:53", $type, 0);
	should_fail("00:23:42", $type, 0);
	should_fail("06:08:54", $type, 0);
	should_fail("19:38:44", $type, 0);
	should_fail("10:21:30", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet enumeration." => sub {
	my $type = mk_type('Time', {'enumeration' => ['08:50:27','09:36:04','15:17:44','03:09:02','00:12:41']});
	should_fail("16:26:32", $type, 0);
	should_fail("02:52:00", $type, 0);
	should_fail("19:49:30", $type, 0);
	should_fail("22:47:05", $type, 0);
	should_fail("17:23:58", $type, 0);
	done_testing;
};

subtest "Type atomic/time is restricted by facet enumeration." => sub {
	my $type = mk_type('Time', {'enumeration' => ['18:17:03','10:18:31','07:16:40','16:34:47','08:06:50','19:52:55','18:22:17','10:14:45','12:03:21','01:02:49']});
	should_fail("10:52:55", $type, 0);
	should_fail("01:35:14", $type, 0);
	should_fail("23:47:21", $type, 0);
	should_fail("18:02:39", $type, 0);
	should_fail("20:06:44", $type, 0);
	done_testing;
};

done_testing;

