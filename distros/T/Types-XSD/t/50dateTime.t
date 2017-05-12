use strict;
use warnings;
use utf8;

use Test::More;
use Test::TypeTiny;

use Types::XSD;

sub mk_type { "Types::XSD"->get_type($_[0])->parameterize(%{$_[1]}) }

subtest "Type atomic/dateTime is restricted by facet minExclusive with value 1970-01-01T00:00:00." => sub {
	my $type = mk_type('DateTime', {'minExclusive' => '1970-01-01T00:00:00'});
	should_pass("1970-01-01T00:00:01", $type, 0);
	should_pass("2027-06-01T06:03:52", $type, 0);
	should_pass("1972-03-04T12:42:23", $type, 0);
	should_pass("2012-02-17T19:25:05", $type, 0);
	should_pass("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minExclusive with value 1974-04-26T23:23:51." => sub {
	my $type = mk_type('DateTime', {'minExclusive' => '1974-04-26T23:23:51'});
	should_pass("1974-04-26T23:23:52", $type, 0);
	should_pass("1985-02-07T10:25:40", $type, 0);
	should_pass("1988-10-16T19:12:29", $type, 0);
	should_pass("2019-01-10T02:21:44", $type, 0);
	should_pass("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minExclusive with value 1981-06-08T06:29:37." => sub {
	my $type = mk_type('DateTime', {'minExclusive' => '1981-06-08T06:29:37'});
	should_pass("1981-06-08T06:29:38", $type, 0);
	should_pass("2017-06-14T03:12:11", $type, 0);
	should_pass("1983-05-12T11:48:28", $type, 0);
	should_pass("1998-02-06T16:36:46", $type, 0);
	should_pass("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minExclusive with value 2001-09-04T00:13:18." => sub {
	my $type = mk_type('DateTime', {'minExclusive' => '2001-09-04T00:13:18'});
	should_pass("2001-09-04T00:13:19", $type, 0);
	should_pass("2008-07-28T04:38:47", $type, 0);
	should_pass("2026-09-04T17:05:14", $type, 0);
	should_pass("2014-11-06T02:46:17", $type, 0);
	should_pass("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minExclusive with value 2030-12-31T23:59:58." => sub {
	my $type = mk_type('DateTime', {'minExclusive' => '2030-12-31T23:59:58'});
	should_pass("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minInclusive with value 1970-01-01T00:00:00." => sub {
	my $type = mk_type('DateTime', {'minInclusive' => '1970-01-01T00:00:00'});
	should_pass("1970-01-01T00:00:00", $type, 0);
	should_pass("1989-08-09T14:53:55", $type, 0);
	should_pass("2001-10-06T04:45:24", $type, 0);
	should_pass("2024-08-29T12:07:59", $type, 0);
	should_pass("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minInclusive with value 1972-10-10T11:07:03." => sub {
	my $type = mk_type('DateTime', {'minInclusive' => '1972-10-10T11:07:03'});
	should_pass("1972-10-10T11:07:03", $type, 0);
	should_pass("1985-06-18T11:28:03", $type, 0);
	should_pass("2005-03-07T13:01:30", $type, 0);
	should_pass("1991-09-12T05:14:01", $type, 0);
	should_pass("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minInclusive with value 1978-11-30T10:14:33." => sub {
	my $type = mk_type('DateTime', {'minInclusive' => '1978-11-30T10:14:33'});
	should_pass("1978-11-30T10:14:33", $type, 0);
	should_pass("2010-07-19T04:52:34", $type, 0);
	should_pass("1995-05-24T13:31:48", $type, 0);
	should_pass("2002-08-05T20:23:56", $type, 0);
	should_pass("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minInclusive with value 2006-07-21T01:32:21." => sub {
	my $type = mk_type('DateTime', {'minInclusive' => '2006-07-21T01:32:21'});
	should_pass("2006-07-21T01:32:21", $type, 0);
	should_pass("2017-08-28T19:07:05", $type, 0);
	should_pass("2009-02-10T19:11:06", $type, 0);
	should_pass("2020-12-28T10:12:14", $type, 0);
	should_pass("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minInclusive with value 2030-12-31T23:59:59." => sub {
	my $type = mk_type('DateTime', {'minInclusive' => '2030-12-31T23:59:59'});
	should_pass("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxExclusive with value 1970-01-01T00:00:01." => sub {
	my $type = mk_type('DateTime', {'maxExclusive' => '1970-01-01T00:00:01'});
	should_pass("1970-01-01T00:00:00", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxExclusive with value 1980-05-22T13:12:09." => sub {
	my $type = mk_type('DateTime', {'maxExclusive' => '1980-05-22T13:12:09'});
	should_pass("1970-01-01T00:00:00", $type, 0);
	should_pass("1977-04-13T14:25:05", $type, 0);
	should_pass("1971-08-21T22:26:27", $type, 0);
	should_pass("1978-04-13T16:51:02", $type, 0);
	should_pass("1980-05-22T13:12:08", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxExclusive with value 1996-08-13T00:44:39." => sub {
	my $type = mk_type('DateTime', {'maxExclusive' => '1996-08-13T00:44:39'});
	should_pass("1970-01-01T00:00:00", $type, 0);
	should_pass("1988-05-22T00:32:31", $type, 0);
	should_pass("1992-04-09T20:02:24", $type, 0);
	should_pass("1976-01-14T17:55:37", $type, 0);
	should_pass("1996-08-13T00:44:38", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxExclusive with value 2018-06-17T15:34:43." => sub {
	my $type = mk_type('DateTime', {'maxExclusive' => '2018-06-17T15:34:43'});
	should_pass("1970-01-01T00:00:00", $type, 0);
	should_pass("1988-02-05T04:45:18", $type, 0);
	should_pass("1986-07-28T23:17:07", $type, 0);
	should_pass("2002-06-24T02:55:38", $type, 0);
	should_pass("2018-06-17T15:34:42", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxExclusive with value 2030-12-31T23:59:59." => sub {
	my $type = mk_type('DateTime', {'maxExclusive' => '2030-12-31T23:59:59'});
	should_pass("1970-01-01T00:00:00", $type, 0);
	should_pass("1996-08-07T20:33:24", $type, 0);
	should_pass("1988-07-12T00:50:57", $type, 0);
	should_pass("1989-09-24T02:35:47", $type, 0);
	should_pass("2030-12-31T23:59:58", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxInclusive with value 1970-01-01T00:00:00." => sub {
	my $type = mk_type('DateTime', {'maxInclusive' => '1970-01-01T00:00:00'});
	should_pass("1970-01-01T00:00:00", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxInclusive with value 1982-05-22T18:01:37." => sub {
	my $type = mk_type('DateTime', {'maxInclusive' => '1982-05-22T18:01:37'});
	should_pass("1970-01-01T00:00:00", $type, 0);
	should_pass("1973-11-06T05:46:55", $type, 0);
	should_pass("1976-01-06T16:31:01", $type, 0);
	should_pass("1972-01-03T01:59:05", $type, 0);
	should_pass("1982-05-22T18:01:37", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxInclusive with value 2003-03-09T02:00:23." => sub {
	my $type = mk_type('DateTime', {'maxInclusive' => '2003-03-09T02:00:23'});
	should_pass("1970-01-01T00:00:00", $type, 0);
	should_pass("1984-04-06T04:33:04", $type, 0);
	should_pass("1985-09-14T06:20:20", $type, 0);
	should_pass("1979-11-20T13:55:06", $type, 0);
	should_pass("2003-03-09T02:00:23", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxInclusive with value 1972-09-29T19:51:19." => sub {
	my $type = mk_type('DateTime', {'maxInclusive' => '1972-09-29T19:51:19'});
	should_pass("1970-01-01T00:00:00", $type, 0);
	should_pass("1970-03-02T17:58:01", $type, 0);
	should_pass("1971-08-30T06:44:31", $type, 0);
	should_pass("1970-03-27T07:06:53", $type, 0);
	should_pass("1972-09-29T19:51:19", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxInclusive with value 2030-12-31T23:59:59." => sub {
	my $type = mk_type('DateTime', {'maxInclusive' => '2030-12-31T23:59:59'});
	should_pass("1970-01-01T00:00:00", $type, 0);
	should_pass("2011-01-30T06:50:16", $type, 0);
	should_pass("1989-01-21T04:59:59", $type, 0);
	should_pass("2010-12-10T06:21:51", $type, 0);
	should_pass("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet pattern with value 19\\d\\d-0\\d-\\d8T\\d8:\\d5:5\\d." => sub {
	my $type = mk_type('DateTime', {'pattern' => qr/(?ms:^19\d\d-0\d-\d8T\d8:\d5:5\d$)/});
	should_pass("1900-06-08T18:25:54", $type, 0);
	should_pass("1957-07-18T18:25:53", $type, 0);
	should_pass("1952-01-18T18:55:54", $type, 0);
	should_pass("1922-05-08T18:55:51", $type, 0);
	should_pass("1930-03-18T18:45:58", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet pattern with value \\d\\d55-0\\d-\\d8T\\d6:1\\d:0\\d." => sub {
	my $type = mk_type('DateTime', {'pattern' => qr/(?ms:^\d\d55-0\d-\d8T\d6:1\d:0\d$)/});
	should_pass("1955-03-28T16:11:07", $type, 0);
	should_pass("1955-05-18T16:15:05", $type, 0);
	should_pass("2055-08-18T16:13:07", $type, 0);
	should_pass("1855-04-28T06:14:09", $type, 0);
	should_pass("2055-04-28T16:10:07", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet pattern with value 19\\d\\d-0\\d-0\\dT\\d5:1\\d:3\\d." => sub {
	my $type = mk_type('DateTime', {'pattern' => qr/(?ms:^19\d\d-0\d-0\dT\d5:1\d:3\d$)/});
	should_pass("1958-07-04T15:13:32", $type, 0);
	should_pass("1961-08-08T15:12:38", $type, 0);
	should_pass("1953-08-03T05:18:33", $type, 0);
	should_pass("1974-07-07T05:14:32", $type, 0);
	should_pass("1947-04-03T05:10:38", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet pattern with value \\d\\d89-\\d2-\\d0T1\\d:2\\d:1\\d." => sub {
	my $type = mk_type('DateTime', {'pattern' => qr/(?ms:^\d\d89-\d2-\d0T1\d:2\d:1\d$)/});
	should_pass("1889-02-10T12:26:15", $type, 0);
	should_pass("1889-02-10T18:26:16", $type, 0);
	should_pass("1989-02-10T17:24:12", $type, 0);
	should_pass("1989-02-10T10:21:16", $type, 0);
	should_pass("1889-02-20T17:23:14", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet pattern with value \\d\\d77-0\\d-0\\dT1\\d:\\d5:\\d5." => sub {
	my $type = mk_type('DateTime', {'pattern' => qr/(?ms:^\d\d77-0\d-0\dT1\d:\d5:\d5$)/});
	should_pass("2077-02-04T11:05:35", $type, 0);
	should_pass("2077-02-04T14:15:25", $type, 0);
	should_pass("1777-03-02T13:15:15", $type, 0);
	should_pass("1877-02-07T11:25:55", $type, 0);
	should_pass("1977-04-01T13:35:05", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet enumeration." => sub {
	my $type = mk_type('DateTime', {'enumeration' => ['2010-02-12T03:22:00','1972-11-27T20:41:04','2015-08-04T06:44:16','2011-05-07T03:49:38','2029-12-13T21:03:46','2029-04-19T14:21:30']});
	should_pass("1972-11-27T20:41:04", $type, 0);
	should_pass("2029-04-19T14:21:30", $type, 0);
	should_pass("2029-12-13T21:03:46", $type, 0);
	should_pass("1972-11-27T20:41:04", $type, 0);
	should_pass("2010-02-12T03:22:00", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet enumeration." => sub {
	my $type = mk_type('DateTime', {'enumeration' => ['2016-12-24T10:20:27','2013-04-14T17:20:13','1997-07-18T03:59:37','2004-04-06T20:47:16','2024-07-02T09:44:13','1980-08-25T23:48:17']});
	should_pass("1997-07-18T03:59:37", $type, 0);
	should_pass("2016-12-24T10:20:27", $type, 0);
	should_pass("2004-04-06T20:47:16", $type, 0);
	should_pass("1980-08-25T23:48:17", $type, 0);
	should_pass("1980-08-25T23:48:17", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet enumeration." => sub {
	my $type = mk_type('DateTime', {'enumeration' => ['1978-10-23T05:45:02','1985-02-19T04:06:18','2019-08-14T05:07:30','2030-09-14T23:19:53','2000-08-25T10:14:42','1975-03-11T11:29:35','2019-01-15T02:01:47','1977-04-10T16:52:34','1996-03-21T14:27:49']});
	should_pass("1975-03-11T11:29:35", $type, 0);
	should_pass("1977-04-10T16:52:34", $type, 0);
	should_pass("2030-09-14T23:19:53", $type, 0);
	should_pass("2019-01-15T02:01:47", $type, 0);
	should_pass("1975-03-11T11:29:35", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet enumeration." => sub {
	my $type = mk_type('DateTime', {'enumeration' => ['2000-08-27T05:34:53','1999-01-22T23:05:35','2018-02-02T20:25:48','1990-10-27T15:40:41','1989-06-12T23:17:57','2019-11-24T15:12:13','2011-02-13T13:12:56','1975-03-26T02:01:19']});
	should_pass("2018-02-02T20:25:48", $type, 0);
	should_pass("2018-02-02T20:25:48", $type, 0);
	should_pass("2019-11-24T15:12:13", $type, 0);
	should_pass("2000-08-27T05:34:53", $type, 0);
	should_pass("1999-01-22T23:05:35", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet enumeration." => sub {
	my $type = mk_type('DateTime', {'enumeration' => ['1990-01-04T22:40:05','2011-07-27T05:09:10','1996-12-01T14:47:04','1998-08-05T19:34:41','1989-04-17T09:42:01','1980-08-05T22:54:49']});
	should_pass("1989-04-17T09:42:01", $type, 0);
	should_pass("1996-12-01T14:47:04", $type, 0);
	should_pass("1996-12-01T14:47:04", $type, 0);
	should_pass("1989-04-17T09:42:01", $type, 0);
	should_pass("2011-07-27T05:09:10", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet whiteSpace with value collapse." => sub {
	my $type = mk_type('DateTime', {'whiteSpace' => 'collapse'});
	should_pass("1970-01-01T00:00:00", $type, 0);
	should_pass("1986-07-08T16:33:18", $type, 0);
	should_pass("1989-05-06T16:03:34", $type, 0);
	should_pass("2009-06-16T02:15:50", $type, 0);
	should_pass("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minInclusive with value 1995-07-23T18:55:18." => sub {
	my $type = mk_type('DateTime', {'minInclusive' => '1995-07-23T18:55:18'});
	should_fail("1970-01-01T00:00:00", $type, 0);
	should_fail("1977-04-04T01:57:42", $type, 0);
	should_fail("1979-12-22T00:46:29", $type, 0);
	should_fail("1970-07-17T19:04:58", $type, 0);
	should_fail("1995-07-23T18:55:17", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minInclusive with value 2020-05-11T02:01:37." => sub {
	my $type = mk_type('DateTime', {'minInclusive' => '2020-05-11T02:01:37'});
	should_fail("1970-01-01T00:00:00", $type, 0);
	should_fail("1975-10-25T04:00:55", $type, 0);
	should_fail("1979-10-18T13:55:12", $type, 0);
	should_fail("1991-09-25T05:46:39", $type, 0);
	should_fail("2020-05-11T02:01:36", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minInclusive with value 2007-02-14T09:11:44." => sub {
	my $type = mk_type('DateTime', {'minInclusive' => '2007-02-14T09:11:44'});
	should_fail("1970-01-01T00:00:00", $type, 0);
	should_fail("1988-09-17T06:02:09", $type, 0);
	should_fail("1983-07-27T21:54:26", $type, 0);
	should_fail("2000-08-26T12:38:57", $type, 0);
	should_fail("2007-02-14T09:11:43", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minInclusive with value 2003-12-13T22:56:59." => sub {
	my $type = mk_type('DateTime', {'minInclusive' => '2003-12-13T22:56:59'});
	should_fail("1970-01-01T00:00:00", $type, 0);
	should_fail("1974-07-12T22:32:41", $type, 0);
	should_fail("1973-08-11T15:28:10", $type, 0);
	should_fail("1994-06-27T22:33:39", $type, 0);
	should_fail("2003-12-13T22:56:58", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minInclusive with value 2030-12-31T23:59:59." => sub {
	my $type = mk_type('DateTime', {'minInclusive' => '2030-12-31T23:59:59'});
	should_fail("1970-01-01T00:00:00", $type, 0);
	should_fail("1985-09-29T04:34:41", $type, 0);
	should_fail("1984-09-17T22:13:04", $type, 0);
	should_fail("2002-11-08T07:18:24", $type, 0);
	should_fail("2030-12-31T23:59:58", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxInclusive with value 1970-01-01T00:00:00." => sub {
	my $type = mk_type('DateTime', {'maxInclusive' => '1970-01-01T00:00:00'});
	should_fail("1970-01-01T00:00:01", $type, 0);
	should_fail("1978-11-22T17:37:16", $type, 0);
	should_fail("1975-09-30T17:03:00", $type, 0);
	should_fail("1989-06-27T18:42:04", $type, 0);
	should_fail("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxInclusive with value 1994-02-25T03:11:05." => sub {
	my $type = mk_type('DateTime', {'maxInclusive' => '1994-02-25T03:11:05'});
	should_fail("1994-02-25T03:11:06", $type, 0);
	should_fail("1996-08-18T07:44:57", $type, 0);
	should_fail("1999-07-22T13:11:01", $type, 0);
	should_fail("2005-04-11T16:31:40", $type, 0);
	should_fail("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxInclusive with value 1979-10-05T09:19:23." => sub {
	my $type = mk_type('DateTime', {'maxInclusive' => '1979-10-05T09:19:23'});
	should_fail("1979-10-05T09:19:24", $type, 0);
	should_fail("2003-04-10T16:45:22", $type, 0);
	should_fail("2020-10-15T19:51:38", $type, 0);
	should_fail("1984-06-25T08:40:37", $type, 0);
	should_fail("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxInclusive with value 2010-06-21T08:46:41." => sub {
	my $type = mk_type('DateTime', {'maxInclusive' => '2010-06-21T08:46:41'});
	should_fail("2010-06-21T08:46:42", $type, 0);
	should_fail("2019-10-25T02:13:37", $type, 0);
	should_fail("2023-07-02T01:50:00", $type, 0);
	should_fail("2027-01-03T05:59:32", $type, 0);
	should_fail("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxInclusive with value 2014-02-07T21:55:18." => sub {
	my $type = mk_type('DateTime', {'maxInclusive' => '2014-02-07T21:55:18'});
	should_fail("2014-02-07T21:55:19", $type, 0);
	should_fail("2024-12-06T20:15:18", $type, 0);
	should_fail("2016-11-03T15:51:28", $type, 0);
	should_fail("2028-11-30T22:31:00", $type, 0);
	should_fail("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minExclusive with value 1970-01-01T00:00:00." => sub {
	my $type = mk_type('DateTime', {'minExclusive' => '1970-01-01T00:00:00'});
	should_fail("1970-01-01T00:00:00", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minExclusive with value 1972-03-14T12:38:28." => sub {
	my $type = mk_type('DateTime', {'minExclusive' => '1972-03-14T12:38:28'});
	should_fail("1970-01-01T00:00:00", $type, 0);
	should_fail("1971-02-24T22:57:40", $type, 0);
	should_fail("1970-09-23T02:03:55", $type, 0);
	should_fail("1970-03-18T11:34:06", $type, 0);
	should_fail("1972-03-14T12:38:28", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minExclusive with value 1985-09-09T17:03:02." => sub {
	my $type = mk_type('DateTime', {'minExclusive' => '1985-09-09T17:03:02'});
	should_fail("1970-01-01T00:00:00", $type, 0);
	should_fail("1983-03-07T07:44:54", $type, 0);
	should_fail("1978-10-06T11:31:46", $type, 0);
	should_fail("1976-05-07T04:41:18", $type, 0);
	should_fail("1985-09-09T17:03:02", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minExclusive with value 2010-03-03T22:44:36." => sub {
	my $type = mk_type('DateTime', {'minExclusive' => '2010-03-03T22:44:36'});
	should_fail("1970-01-01T00:00:00", $type, 0);
	should_fail("1989-01-16T17:14:43", $type, 0);
	should_fail("1994-06-18T01:00:17", $type, 0);
	should_fail("1992-01-01T10:34:42", $type, 0);
	should_fail("2010-03-03T22:44:36", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet minExclusive with value 2030-12-31T23:59:58." => sub {
	my $type = mk_type('DateTime', {'minExclusive' => '2030-12-31T23:59:58'});
	should_fail("1970-01-01T00:00:00", $type, 0);
	should_fail("1997-03-24T19:39:12", $type, 0);
	should_fail("2030-12-14T12:32:08", $type, 0);
	should_fail("2005-11-16T03:56:15", $type, 0);
	should_fail("2030-12-31T23:59:58", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxExclusive with value 1970-01-01T00:00:01." => sub {
	my $type = mk_type('DateTime', {'maxExclusive' => '1970-01-01T00:00:01'});
	should_fail("1970-01-01T00:00:01", $type, 0);
	should_fail("2001-05-23T02:51:50", $type, 0);
	should_fail("2005-07-15T12:00:28", $type, 0);
	should_fail("1974-01-23T08:30:04", $type, 0);
	should_fail("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxExclusive with value 2005-05-16T14:28:30." => sub {
	my $type = mk_type('DateTime', {'maxExclusive' => '2005-05-16T14:28:30'});
	should_fail("2005-05-16T14:28:30", $type, 0);
	should_fail("2027-09-25T09:41:07", $type, 0);
	should_fail("2022-05-24T20:55:16", $type, 0);
	should_fail("2014-09-07T05:28:34", $type, 0);
	should_fail("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxExclusive with value 1999-05-23T06:56:49." => sub {
	my $type = mk_type('DateTime', {'maxExclusive' => '1999-05-23T06:56:49'});
	should_fail("1999-05-23T06:56:49", $type, 0);
	should_fail("2024-10-19T18:04:30", $type, 0);
	should_fail("2028-11-25T19:57:00", $type, 0);
	should_fail("2002-08-27T20:38:39", $type, 0);
	should_fail("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxExclusive with value 2025-12-09T05:41:30." => sub {
	my $type = mk_type('DateTime', {'maxExclusive' => '2025-12-09T05:41:30'});
	should_fail("2025-12-09T05:41:30", $type, 0);
	should_fail("2030-05-04T05:09:58", $type, 0);
	should_fail("2030-03-08T03:03:10", $type, 0);
	should_fail("2029-02-02T06:32:37", $type, 0);
	should_fail("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet maxExclusive with value 2030-12-31T23:59:59." => sub {
	my $type = mk_type('DateTime', {'maxExclusive' => '2030-12-31T23:59:59'});
	should_fail("2030-12-31T23:59:59", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet pattern with value \\d\\d69-\\d9-\\d9T\\d8:\\d1:3\\d." => sub {
	my $type = mk_type('DateTime', {'pattern' => qr/(?ms:^\d\d69-\d9-\d9T\d8:\d1:3\d$)/});
	should_fail("1804-03-13T14:44:07", $type, 0);
	should_fail("1857-04-20T12:48:24", $type, 0);
	should_fail("1844-06-17T11:28:01", $type, 0);
	should_fail("1837-02-13T03:46:42", $type, 0);
	should_fail("2053-07-20T14:07:26", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet pattern with value \\d\\d94-\\d9-\\d7T1\\d:0\\d:0\\d." => sub {
	my $type = mk_type('DateTime', {'pattern' => qr/(?ms:^\d\d94-\d9-\d7T1\d:0\d:0\d$)/});
	should_fail("1900-01-15T27:42:43", $type, 0);
	should_fail("1860-07-20T47:29:29", $type, 0);
	should_fail("1945-05-01T23:30:29", $type, 0);
	should_fail("1915-04-22T37:37:17", $type, 0);
	should_fail("1852-03-12T02:26:41", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet pattern with value 20\\d\\d-\\d8-\\d5T\\d1:\\d1:0\\d." => sub {
	my $type = mk_type('DateTime', {'pattern' => qr/(?ms:^20\d\d-\d8-\d5T\d1:\d1:0\d$)/});
	should_fail("1870-07-17T16:19:31", $type, 0);
	should_fail("1853-05-24T07:12:41", $type, 0);
	should_fail("1886-04-20T06:27:46", $type, 0);
	should_fail("1890-05-16T15:52:42", $type, 0);
	should_fail("1784-01-12T19:18:16", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet pattern with value \\d\\d58-\\d2-2\\dT0\\d:1\\d:3\\d." => sub {
	my $type = mk_type('DateTime', {'pattern' => qr/(?ms:^\d\d58-\d2-2\dT0\d:1\d:3\d$)/});
	should_fail("2088-09-01T58:01:14", $type, 0);
	should_fail("1822-04-03T48:25:22", $type, 0);
	should_fail("2045-05-17T25:35:03", $type, 0);
	should_fail("1984-06-12T22:54:26", $type, 0);
	should_fail("1757-07-03T24:21:49", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet pattern with value \\d\\d59-\\d3-\\d4T1\\d:\\d9:3\\d." => sub {
	my $type = mk_type('DateTime', {'pattern' => qr/(?ms:^\d\d59-\d3-\d4T1\d:\d9:3\d$)/});
	should_fail("1915-09-15T04:17:25", $type, 0);
	should_fail("2080-04-01T02:55:00", $type, 0);
	should_fail("1773-02-07T22:02:16", $type, 0);
	should_fail("1928-08-16T05:10:23", $type, 0);
	should_fail("1821-05-26T40:44:50", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet enumeration." => sub {
	my $type = mk_type('DateTime', {'enumeration' => ['1997-12-16T22:31:40','2024-07-08T09:19:42','1978-03-14T10:09:23','2017-06-20T05:24:09','1991-02-19T22:13:31','1983-02-06T22:19:51']});
	should_fail("1982-04-07T08:02:06", $type, 0);
	should_fail("2011-07-06T00:53:58", $type, 0);
	should_fail("1988-07-25T00:53:54", $type, 0);
	should_fail("1980-08-23T16:18:42", $type, 0);
	should_fail("2005-08-30T12:44:12", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet enumeration." => sub {
	my $type = mk_type('DateTime', {'enumeration' => ['1990-03-02T16:40:09','1994-04-25T04:42:21','1994-07-25T18:36:49','1996-12-08T17:57:34','2030-09-16T14:55:48','2029-07-09T10:05:42','2016-02-08T16:25:13','1987-11-01T04:17:26','1995-01-25T03:42:52','1996-04-12T03:42:54']});
	should_fail("2019-01-01T06:19:23", $type, 0);
	should_fail("1988-11-25T10:48:28", $type, 0);
	should_fail("2005-11-03T19:40:14", $type, 0);
	should_fail("1983-10-29T00:26:08", $type, 0);
	should_fail("2024-06-30T20:10:04", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet enumeration." => sub {
	my $type = mk_type('DateTime', {'enumeration' => ['2014-01-28T18:33:05','1994-11-11T22:16:25','2023-05-20T07:09:40','2029-02-22T18:22:38','1992-03-27T14:40:18','2009-05-13T08:53:45','2021-01-11T20:06:41','1985-02-24T23:46:33','1993-11-23T09:47:43']});
	should_fail("2028-06-22T03:58:25", $type, 0);
	should_fail("2014-06-11T03:26:09", $type, 0);
	should_fail("1983-09-29T15:42:36", $type, 0);
	should_fail("2027-11-04T16:09:15", $type, 0);
	should_fail("2007-08-29T05:30:08", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet enumeration." => sub {
	my $type = mk_type('DateTime', {'enumeration' => ['2016-10-14T16:26:22','1970-09-08T21:09:47','1997-01-26T13:30:30','2005-05-13T17:33:47','2029-09-17T03:28:03','2008-12-05T15:31:29','1997-07-19T02:18:36','2017-12-26T05:57:53','2023-02-01T12:53:10']});
	should_fail("1990-06-06T11:43:20", $type, 0);
	should_fail("1979-10-08T13:20:30", $type, 0);
	should_fail("2013-09-21T12:11:08", $type, 0);
	should_fail("1973-03-15T16:34:41", $type, 0);
	should_fail("2009-06-03T05:27:26", $type, 0);
	done_testing;
};

subtest "Type atomic/dateTime is restricted by facet enumeration." => sub {
	my $type = mk_type('DateTime', {'enumeration' => ['2026-01-13T22:29:02','1977-04-29T10:22:43','1984-02-02T17:09:49','1971-10-20T08:53:35','2022-01-16T21:19:09','2005-12-05T00:58:08','1970-10-30T16:36:45','1975-10-01T17:36:14','1990-08-28T16:51:38']});
	should_fail("2017-04-19T00:44:12", $type, 0);
	should_fail("2010-12-29T10:32:23", $type, 0);
	should_fail("1984-02-20T04:39:36", $type, 0);
	should_fail("2025-05-15T02:29:24", $type, 0);
	should_fail("2012-10-19T23:46:22", $type, 0);
	done_testing;
};

done_testing;

