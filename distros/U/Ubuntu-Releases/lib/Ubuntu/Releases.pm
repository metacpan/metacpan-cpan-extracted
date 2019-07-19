package Ubuntu::Releases;

our $DATE = '2019-06-28'; # DATE
our $VERSION = '0.111'; # VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       list_ubuntu_releases
               );

our %SPEC;

our $meta = {
    summary => 'Ubuntu releases',
    fields => {
        version         => { pos => 0, schema => "str*", sortable => 1, summary => "Version", unique => 1 },
        code_name       => { pos => 1, schema => "str*", sortable => 1, summary => "Code name", unique => 1 },
        reldate         => { pos => 2, schema => "date*", sortable => 1, summary => "Release date" },
        eoldate         => { pos => 3, schema => "date*", sortable => 1, summary => "Supported until" },

        linux_version   => {pos=> 4, schema=>'str*'},

        mysql_version        => {pos=> 5, schema=>'str*'},
        mariadb_version      => {pos=> 6, schema=>'str*'},
        postgresql_version   => {pos=> 7, schema=>'str*'},
        apache_httpd_version => {pos=> 8, schema=>'str*'},
        nginx_version        => {pos=> 9, schema=>'str*'},

        perl_version         => {pos=>10, schema=>'str*'},
        python_version       => {pos=>11, schema=>'str*'},
        php_version          => {pos=>12, schema=>'str*'},
        ruby_version         => {pos=>13, schema=>'str*'},
        bash_version         => {pos=>14, schema=>'str*'},
    },
    pk => "version",
};

our $data = do {
    no warnings 'void';
    [];
 [
   {
     apache_httpd_version => "--",
     bash_version         => "2.05b",
     code_name            => "warty",
     eoldate              => undef,
     linux_version        => "2.6.8.1",
     mariadb_version      => "--",
     mysql_version        => "--",
     nginx_version        => undef,
     perl_version         => "5.8.4",
     php_version          => "--",
     postgresql_version   => "--",
     python_version       => " ()",
     reldate              => "2004-10-20",
     ruby_version         => undef,
     version              => "4.10",
   },
   {
     apache_httpd_version => "--",
     bash_version         => "3.0",
     code_name            => "hoary",
     eoldate              => undef,
     linux_version        => "2.6.10",
     mariadb_version      => "--",
     mysql_version        => "--",
     nginx_version        => undef,
     perl_version         => "5.8.4",
     php_version          => "--",
     postgresql_version   => "--",
     python_version       => "2.3.4",
     reldate              => "2005-04-08",
     ruby_version         => undef,
     version              => 5.04,
   },
   {
     apache_httpd_version => "--",
     bash_version         => "3.0",
     code_name            => "breezy",
     eoldate              => undef,
     linux_version        => "2.6.12",
     mariadb_version      => "--",
     mysql_version        => "--",
     nginx_version        => undef,
     perl_version         => "5.8.7",
     php_version          => "--",
     postgresql_version   => "--",
     python_version       => "2.4.1",
     reldate              => "2005-10-13",
     ruby_version         => undef,
     version              => "5.10",
   },
   {
     apache_httpd_version => "--",
     bash_version         => 3.1,
     code_name            => "dapper",
     eoldate              => undef,
     linux_version        => "2.6.15",
     mariadb_version      => "--",
     mysql_version        => "--",
     nginx_version        => undef,
     perl_version         => "5.8.7",
     php_version          => "--",
     postgresql_version   => "--",
     python_version       => "2.4.2",
     reldate              => "2006-06-01",
     ruby_version         => undef,
     version              => "6.06 LTS",
   },
   {
     apache_httpd_version => "--",
     bash_version         => 3.1,
     code_name            => "edgy",
     eoldate              => undef,
     linux_version        => "2.6.17",
     mariadb_version      => "--",
     mysql_version        => "--",
     nginx_version        => undef,
     perl_version         => "5.8.8",
     php_version          => "--",
     postgresql_version   => "--",
     python_version       => "2.4.3",
     reldate              => "2006-10-26",
     ruby_version         => undef,
     version              => "6.10",
   },
   {
     apache_httpd_version => "--",
     bash_version         => 3.2,
     code_name            => "feisty",
     eoldate              => undef,
     linux_version        => "2.6.20",
     mariadb_version      => "--",
     mysql_version        => "--",
     nginx_version        => undef,
     perl_version         => "5.8.8",
     php_version          => "--",
     postgresql_version   => "--",
     python_version       => "2.4.4",
     reldate              => "2007-04-19",
     ruby_version         => undef,
     version              => 7.04,
   },
   {
     apache_httpd_version => "--",
     bash_version         => 3.2,
     code_name            => "gutsy",
     eoldate              => undef,
     linux_version        => "2.6.22",
     mariadb_version      => "--",
     mysql_version        => "--",
     nginx_version        => undef,
     perl_version         => "5.8.8",
     php_version          => "--",
     postgresql_version   => "--",
     python_version       => "2.5.1rc1",
     reldate              => "2007-10-18",
     ruby_version         => undef,
     version              => "7.10",
   },
   {
     apache_httpd_version => "--",
     bash_version         => 3.2,
     code_name            => "hardy",
     eoldate              => undef,
     linux_version        => "2.6.24",
     mariadb_version      => "--",
     mysql_version        => "--",
     nginx_version        => undef,
     perl_version         => "5.8.8",
     php_version          => "--",
     postgresql_version   => "--",
     python_version       => "2.5.1",
     reldate              => "2008-04-24",
     ruby_version         => undef,
     version              => "8.04 LTS",
   },
   {
     apache_httpd_version => "--",
     bash_version         => 3.2,
     code_name            => "intrepid",
     eoldate              => undef,
     linux_version        => "2.6.27",
     mariadb_version      => "--",
     mysql_version        => "--",
     nginx_version        => undef,
     perl_version         => "5.10.0",
     php_version          => "--",
     postgresql_version   => "--",
     python_version       => "2.5.2",
     reldate              => "2008-10-30",
     ruby_version         => undef,
     version              => "8.10",
   },
   {
     apache_httpd_version => "--",
     bash_version         => 3.2,
     code_name            => "jaunty",
     eoldate              => undef,
     linux_version        => "2.6.28",
     mariadb_version      => "--",
     mysql_version        => "--",
     nginx_version        => undef,
     perl_version         => "5.10.0",
     php_version          => "--",
     postgresql_version   => "--",
     python_version       => "2.5.2",
     reldate              => "2009-04-23",
     ruby_version         => undef,
     version              => 9.04,
   },
   {
     apache_httpd_version => "2.2.12",
     bash_version         => "4.0",
     code_name            => "karmic",
     eoldate              => undef,
     linux_version        => "2.6.31",
     mariadb_version      => "--",
     mysql_version        => "5.1.37",
     nginx_version        => undef,
     perl_version         => "5.10.0",
     php_version          => "5.2.10",
     postgresql_version   => "8.4.1",
     python_version       => "2.6.2",
     reldate              => "2009-10-29",
     ruby_version         => undef,
     version              => "9.10",
   },
   {
     apache_httpd_version => "2.2.14",
     bash_version         => 4.1,
     code_name            => "lucid",
     eoldate              => "2013-05",
     linux_version        => "2.6.32",
     mariadb_version      => "--",
     mysql_version        => "5.1.41",
     nginx_version        => undef,
     perl_version         => "5.10.1",
     php_version          => "5.3.2",
     postgresql_version   => "8.4.3",
     python_version       => "2.6.4rc2",
     reldate              => "2010-04-29",
     ruby_version         => undef,
     version              => "10.04 LTS",
   },
   {
     apache_httpd_version => "2.2.16",
     bash_version         => 4.1,
     code_name            => "maverick",
     eoldate              => "2012-04",
     linux_version        => "2.6.35",
     mariadb_version      => "--",
     mysql_version        => "5.1.49",
     nginx_version        => undef,
     perl_version         => "5.10.1",
     php_version          => "5.3.3",
     postgresql_version   => "8.4.4",
     python_version       => "2.6.5",
     reldate              => "2010-10-10",
     ruby_version         => undef,
     version              => "10.10",
   },
   {
     apache_httpd_version => "2.2.17",
     bash_version         => 4.2,
     code_name            => "natty",
     eoldate              => "2012-10",
     linux_version        => "2.6.38",
     mariadb_version      => "--",
     mysql_version        => "5.1.54",
     nginx_version        => undef,
     perl_version         => "5.10.1",
     php_version          => "5.3.5",
     postgresql_version   => "8.4.8",
     python_version       => "2.6.6",
     reldate              => "2011-04-28",
     ruby_version         => undef,
     version              => 11.04,
   },
   {
     apache_httpd_version => "2.2.20",
     bash_version         => 4.2,
     code_name            => "oneiric",
     eoldate              => "2013-05",
     linux_version        => "3.0",
     mariadb_version      => "--",
     mysql_version        => "5.1.58",
     nginx_version        => undef,
     perl_version         => "5.12.4",
     php_version          => "5.3.6",
     postgresql_version   => "9.1.1",
     python_version       => "2.7.1",
     reldate              => "2011-10-13",
     ruby_version         => undef,
     version              => "11.10",
   },
   {
     apache_httpd_version => "2.2.22",
     bash_version         => 4.2,
     code_name            => "precise",
     eoldate              => "2017-04",
     linux_version        => 3.2,
     mariadb_version      => "--",
     mysql_version        => "5.5.22",
     nginx_version        => undef,
     perl_version         => "5.14.2",
     php_version          => "5.3.10",
     postgresql_version   => "9.1.3",
     python_version       => "2.7.2",
     reldate              => "2012-04-26",
     ruby_version         => undef,
     version              => "12.04 LTS",
   },
   {
     apache_httpd_version => "2.2.22",
     bash_version         => 4.2,
     code_name            => "quantal",
     eoldate              => "2014-05",
     linux_version        => 3.5,
     mariadb_version      => "--",
     mysql_version        => "5.5.27",
     nginx_version        => undef,
     perl_version         => "5.14.2",
     php_version          => "5.4.6",
     postgresql_version   => "9.1.6",
     python_version       => "2.7.3",
     reldate              => "2012-10-18",
     ruby_version         => undef,
     version              => "12.10",
   },
   {
     apache_httpd_version => "2.2.22",
     bash_version         => 4.2,
     code_name            => "raring",
     eoldate              => "2014-01",
     linux_version        => 3.8,
     mariadb_version      => "--",
     mysql_version        => "5.5.29",
     nginx_version        => undef,
     perl_version         => "5.14.2",
     php_version          => "5.4.9",
     postgresql_version   => "9.1.9",
     python_version       => "2.7.3",
     reldate              => "2013-04-25",
     ruby_version         => undef,
     version              => 13.04,
   },
   {
     apache_httpd_version => "2.4.6",
     bash_version         => 4.2,
     code_name            => "saucy",
     eoldate              => "2014-07",
     linux_version        => 3.11,
     mariadb_version      => "--",
     mysql_version        => "5.5.32",
     nginx_version        => undef,
     perl_version         => "5.14.2",
     php_version          => "5.5.3",
     postgresql_version   => "9.1.10",
     python_version       => "2.7.4",
     reldate              => "2013-10-17",
     ruby_version         => undef,
     version              => "13.10",
   },
   {
     apache_httpd_version => "2.4.7",
     bash_version         => 4.3,
     code_name            => "trusty",
     eoldate              => "2019-04",
     linux_version        => 3.13,
     mariadb_version      => "--",
     mysql_version        => "5.5.35",
     nginx_version        => undef,
     perl_version         => "5.18.2",
     php_version          => "5.5.9",
     postgresql_version   => "9.3.4",
     python_version       => "2.7.5",
     reldate              => "2014-04-17",
     ruby_version         => undef,
     version              => "14.04 LTS",
   },
   {
     apache_httpd_version => "2.4.10",
     bash_version         => 4.3,
     code_name            => "utopic",
     eoldate              => "2015-07",
     linux_version        => 3.16,
     mariadb_version      => "--",
     mysql_version        => "5.5.39",
     nginx_version        => undef,
     perl_version         => "5.20.0",
     php_version          => "5.5.12",
     postgresql_version   => "9.4beta2",
     python_version       => "2.7.6",
     reldate              => "2014-10-23",
     ruby_version         => undef,
     version              => "14.10",
   },
   {
     apache_httpd_version => "2.4.10",
     bash_version         => 4.3,
     code_name            => "vivid",
     eoldate              => "2016-01",
     linux_version        => 3.19,
     mariadb_version      => "--",
     mysql_version        => "5.6.24",
     nginx_version        => undef,
     perl_version         => "5.20.2",
     php_version          => "5.6.4",
     postgresql_version   => "9.4.1",
     python_version       => "2.7.8",
     reldate              => "2015-04-23",
     ruby_version         => undef,
     version              => 15.04,
   },
   {
     apache_httpd_version => "2.4.12",
     bash_version         => 4.3,
     code_name            => "wily",
     eoldate              => "2016-07",
     linux_version        => 4.2,
     mariadb_version      => "--",
     mysql_version        => "5.6.25",
     nginx_version        => undef,
     perl_version         => "5.20.2",
     php_version          => "5.6.11",
     postgresql_version   => "9.4.5",
     python_version       => "2.7.9",
     reldate              => "2015-10-22",
     ruby_version         => undef,
     version              => "15.10",
   },
   {
     apache_httpd_version => "2.4.18",
     bash_version         => 4.3,
     code_name            => "xenial",
     eoldate              => "2021-04",
     linux_version        => 4.4,
     mariadb_version      => "--",
     mysql_version        => "5.7.11",
     nginx_version        => undef,
     perl_version         => "5.22.1",
     php_version          => "7.0.4",
     postgresql_version   => "9.5.2",
     python_version       => "3.5.1",
     reldate              => "2016-04-21",
     ruby_version         => undef,
     version              => "16.04 LTS",
   },
   {
     apache_httpd_version => "2.4.18",
     bash_version         => 4.3,
     code_name            => "yakkety",
     eoldate              => "2017-07",
     linux_version        => 4.8,
     mariadb_version      => "--",
     mysql_version        => "5.7.15",
     nginx_version        => undef,
     perl_version         => "5.22.2",
     php_version          => "7.0.8",
     postgresql_version   => "9.5.4",
     python_version       => "2.7.11",
     reldate              => "2016-10-13",
     ruby_version         => undef,
     version              => "16.10",
   },
   {
     apache_httpd_version => "2.4.25",
     bash_version         => 4.4,
     code_name            => "zesty",
     eoldate              => "2018-01",
     linux_version        => "4.10",
     mariadb_version      => "--",
     mysql_version        => "5.7.17",
     nginx_version        => undef,
     perl_version         => "5.24.1",
     php_version          => "7.0.15",
     postgresql_version   => "9.6.2",
     python_version       => "2.7.13",
     reldate              => "2017-04-13",
     ruby_version         => undef,
     version              => 17.04,
   },
   {
     apache_httpd_version => "2.4.27",
     bash_version         => 4.4,
     code_name            => "artful",
     eoldate              => "2018-07",
     linux_version        => 4.13,
     mariadb_version      => "--",
     mysql_version        => "5.7.19",
     nginx_version        => undef,
     perl_version         => "5.26.0",
     php_version          => "7.1.8",
     postgresql_version   => "9.6.5",
     python_version       => "2.7.14",
     reldate              => "2017-10-19",
     ruby_version         => undef,
     version              => "17.10",
   },
   {
     apache_httpd_version => "2.4.29",
     bash_version         => "4.4.18",
     code_name            => "bionic",
     eoldate              => "2023-04",
     linux_version        => 4.15,
     mariadb_version      => "--",
     mysql_version        => "5.7.21",
     nginx_version        => undef,
     perl_version         => "5.26.1",
     php_version          => "7.2.3",
     postgresql_version   => 10.3,
     python_version       => "2.7.15rc1",
     reldate              => "2018-04-26",
     ruby_version         => undef,
     version              => "18.04 LTS",
   },
   {
     apache_httpd_version => "2.4.34",
     bash_version         => "4.4.18",
     code_name            => "cosmic",
     eoldate              => "2019-07",
     linux_version        => 4.18,
     mariadb_version      => "--",
     mysql_version        => "5.7.23",
     nginx_version        => undef,
     perl_version         => "5.26.2",
     php_version          => "7.2.10",
     postgresql_version   => 10.5,
     python_version       => "3.6.6",
     reldate              => "2018-10-18",
     ruby_version         => undef,
     version              => "18.10",
   },
   {
     apache_httpd_version => "--",
     bash_version         => "5.0",
     code_name            => "disco",
     eoldate              => "2020-01",
     linux_version        => "5.0.0",
     mariadb_version      => "--",
     mysql_version        => "--",
     nginx_version        => undef,
     perl_version         => "5.28.1",
     php_version          => "--",
     postgresql_version   => "--",
     python_version       => "3.7.3",
     reldate              => "2019-04-18",
     ruby_version         => undef,
     version              => 19.04,
   },
 ]

};

my $res = gen_read_table_func(
    name => 'list_ubuntu_releases',
    table_data => $data,
    table_spec => $meta,
    #langs => ['en_US', 'id_ID'],
);
die "BUG: Can't generate func: $res->[0] - $res->[1]" unless $res->[0] == 200;

1;
# ABSTRACT: List Ubuntu releases

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubuntu::Releases - List Ubuntu releases

=head1 VERSION

This document describes version 0.111 of Ubuntu::Releases (from Perl distribution Ubuntu-Releases), released on 2019-06-28.

=head1 SYNOPSIS

 use Ubuntu::Releases;
 my $res = list_ubuntu_releases(detail=>1);
 # raw data is in $Ubuntu::Releases::data;

=head1 DESCRIPTION

This module contains list of Ubuntu releases. Data source is
currently at: L<https://github.com/sharyanto/gudangdata-distrowatch>
(table/redhat_release) which in turn is retrieved from
L<http://distrowatch.com>.

=head1 FUNCTIONS


=head2 list_ubuntu_releases

Usage:

 list_ubuntu_releases(%args) -> [status, msg, payload, meta]

Ubuntu releases.

REPLACE ME

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<apache_httpd_version> => I<str>

Only return records where the 'apache_httpd_version' field equals specified value.

=item * B<apache_httpd_version.contains> => I<str>

Only return records where the 'apache_httpd_version' field contains specified text.

=item * B<apache_httpd_version.in> => I<array[str]>

Only return records where the 'apache_httpd_version' field is in the specified values.

=item * B<apache_httpd_version.is> => I<str>

Only return records where the 'apache_httpd_version' field equals specified value.

=item * B<apache_httpd_version.isnt> => I<str>

Only return records where the 'apache_httpd_version' field does not equal specified value.

=item * B<apache_httpd_version.max> => I<str>

Only return records where the 'apache_httpd_version' field is less than or equal to specified value.

=item * B<apache_httpd_version.min> => I<str>

Only return records where the 'apache_httpd_version' field is greater than or equal to specified value.

=item * B<apache_httpd_version.not_contains> => I<str>

Only return records where the 'apache_httpd_version' field does not contain specified text.

=item * B<apache_httpd_version.not_in> => I<array[str]>

Only return records where the 'apache_httpd_version' field is not in the specified values.

=item * B<apache_httpd_version.xmax> => I<str>

Only return records where the 'apache_httpd_version' field is less than specified value.

=item * B<apache_httpd_version.xmin> => I<str>

Only return records where the 'apache_httpd_version' field is greater than specified value.

=item * B<bash_version> => I<str>

Only return records where the 'bash_version' field equals specified value.

=item * B<bash_version.contains> => I<str>

Only return records where the 'bash_version' field contains specified text.

=item * B<bash_version.in> => I<array[str]>

Only return records where the 'bash_version' field is in the specified values.

=item * B<bash_version.is> => I<str>

Only return records where the 'bash_version' field equals specified value.

=item * B<bash_version.isnt> => I<str>

Only return records where the 'bash_version' field does not equal specified value.

=item * B<bash_version.max> => I<str>

Only return records where the 'bash_version' field is less than or equal to specified value.

=item * B<bash_version.min> => I<str>

Only return records where the 'bash_version' field is greater than or equal to specified value.

=item * B<bash_version.not_contains> => I<str>

Only return records where the 'bash_version' field does not contain specified text.

=item * B<bash_version.not_in> => I<array[str]>

Only return records where the 'bash_version' field is not in the specified values.

=item * B<bash_version.xmax> => I<str>

Only return records where the 'bash_version' field is less than specified value.

=item * B<bash_version.xmin> => I<str>

Only return records where the 'bash_version' field is greater than specified value.

=item * B<code_name> => I<str>

Only return records where the 'code_name' field equals specified value.

=item * B<code_name.contains> => I<str>

Only return records where the 'code_name' field contains specified text.

=item * B<code_name.in> => I<array[str]>

Only return records where the 'code_name' field is in the specified values.

=item * B<code_name.is> => I<str>

Only return records where the 'code_name' field equals specified value.

=item * B<code_name.isnt> => I<str>

Only return records where the 'code_name' field does not equal specified value.

=item * B<code_name.max> => I<str>

Only return records where the 'code_name' field is less than or equal to specified value.

=item * B<code_name.min> => I<str>

Only return records where the 'code_name' field is greater than or equal to specified value.

=item * B<code_name.not_contains> => I<str>

Only return records where the 'code_name' field does not contain specified text.

=item * B<code_name.not_in> => I<array[str]>

Only return records where the 'code_name' field is not in the specified values.

=item * B<code_name.xmax> => I<str>

Only return records where the 'code_name' field is less than specified value.

=item * B<code_name.xmin> => I<str>

Only return records where the 'code_name' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<eoldate> => I<date>

Only return records where the 'eoldate' field equals specified value.

=item * B<eoldate.in> => I<array[date]>

Only return records where the 'eoldate' field is in the specified values.

=item * B<eoldate.is> => I<date>

Only return records where the 'eoldate' field equals specified value.

=item * B<eoldate.isnt> => I<date>

Only return records where the 'eoldate' field does not equal specified value.

=item * B<eoldate.max> => I<date>

Only return records where the 'eoldate' field is less than or equal to specified value.

=item * B<eoldate.min> => I<date>

Only return records where the 'eoldate' field is greater than or equal to specified value.

=item * B<eoldate.not_in> => I<array[date]>

Only return records where the 'eoldate' field is not in the specified values.

=item * B<eoldate.xmax> => I<date>

Only return records where the 'eoldate' field is less than specified value.

=item * B<eoldate.xmin> => I<date>

Only return records where the 'eoldate' field is greater than specified value.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<linux_version> => I<str>

Only return records where the 'linux_version' field equals specified value.

=item * B<linux_version.contains> => I<str>

Only return records where the 'linux_version' field contains specified text.

=item * B<linux_version.in> => I<array[str]>

Only return records where the 'linux_version' field is in the specified values.

=item * B<linux_version.is> => I<str>

Only return records where the 'linux_version' field equals specified value.

=item * B<linux_version.isnt> => I<str>

Only return records where the 'linux_version' field does not equal specified value.

=item * B<linux_version.max> => I<str>

Only return records where the 'linux_version' field is less than or equal to specified value.

=item * B<linux_version.min> => I<str>

Only return records where the 'linux_version' field is greater than or equal to specified value.

=item * B<linux_version.not_contains> => I<str>

Only return records where the 'linux_version' field does not contain specified text.

=item * B<linux_version.not_in> => I<array[str]>

Only return records where the 'linux_version' field is not in the specified values.

=item * B<linux_version.xmax> => I<str>

Only return records where the 'linux_version' field is less than specified value.

=item * B<linux_version.xmin> => I<str>

Only return records where the 'linux_version' field is greater than specified value.

=item * B<mariadb_version> => I<str>

Only return records where the 'mariadb_version' field equals specified value.

=item * B<mariadb_version.contains> => I<str>

Only return records where the 'mariadb_version' field contains specified text.

=item * B<mariadb_version.in> => I<array[str]>

Only return records where the 'mariadb_version' field is in the specified values.

=item * B<mariadb_version.is> => I<str>

Only return records where the 'mariadb_version' field equals specified value.

=item * B<mariadb_version.isnt> => I<str>

Only return records where the 'mariadb_version' field does not equal specified value.

=item * B<mariadb_version.max> => I<str>

Only return records where the 'mariadb_version' field is less than or equal to specified value.

=item * B<mariadb_version.min> => I<str>

Only return records where the 'mariadb_version' field is greater than or equal to specified value.

=item * B<mariadb_version.not_contains> => I<str>

Only return records where the 'mariadb_version' field does not contain specified text.

=item * B<mariadb_version.not_in> => I<array[str]>

Only return records where the 'mariadb_version' field is not in the specified values.

=item * B<mariadb_version.xmax> => I<str>

Only return records where the 'mariadb_version' field is less than specified value.

=item * B<mariadb_version.xmin> => I<str>

Only return records where the 'mariadb_version' field is greater than specified value.

=item * B<mysql_version> => I<str>

Only return records where the 'mysql_version' field equals specified value.

=item * B<mysql_version.contains> => I<str>

Only return records where the 'mysql_version' field contains specified text.

=item * B<mysql_version.in> => I<array[str]>

Only return records where the 'mysql_version' field is in the specified values.

=item * B<mysql_version.is> => I<str>

Only return records where the 'mysql_version' field equals specified value.

=item * B<mysql_version.isnt> => I<str>

Only return records where the 'mysql_version' field does not equal specified value.

=item * B<mysql_version.max> => I<str>

Only return records where the 'mysql_version' field is less than or equal to specified value.

=item * B<mysql_version.min> => I<str>

Only return records where the 'mysql_version' field is greater than or equal to specified value.

=item * B<mysql_version.not_contains> => I<str>

Only return records where the 'mysql_version' field does not contain specified text.

=item * B<mysql_version.not_in> => I<array[str]>

Only return records where the 'mysql_version' field is not in the specified values.

=item * B<mysql_version.xmax> => I<str>

Only return records where the 'mysql_version' field is less than specified value.

=item * B<mysql_version.xmin> => I<str>

Only return records where the 'mysql_version' field is greater than specified value.

=item * B<nginx_version> => I<str>

Only return records where the 'nginx_version' field equals specified value.

=item * B<nginx_version.contains> => I<str>

Only return records where the 'nginx_version' field contains specified text.

=item * B<nginx_version.in> => I<array[str]>

Only return records where the 'nginx_version' field is in the specified values.

=item * B<nginx_version.is> => I<str>

Only return records where the 'nginx_version' field equals specified value.

=item * B<nginx_version.isnt> => I<str>

Only return records where the 'nginx_version' field does not equal specified value.

=item * B<nginx_version.max> => I<str>

Only return records where the 'nginx_version' field is less than or equal to specified value.

=item * B<nginx_version.min> => I<str>

Only return records where the 'nginx_version' field is greater than or equal to specified value.

=item * B<nginx_version.not_contains> => I<str>

Only return records where the 'nginx_version' field does not contain specified text.

=item * B<nginx_version.not_in> => I<array[str]>

Only return records where the 'nginx_version' field is not in the specified values.

=item * B<nginx_version.xmax> => I<str>

Only return records where the 'nginx_version' field is less than specified value.

=item * B<nginx_version.xmin> => I<str>

Only return records where the 'nginx_version' field is greater than specified value.

=item * B<perl_version> => I<str>

Only return records where the 'perl_version' field equals specified value.

=item * B<perl_version.contains> => I<str>

Only return records where the 'perl_version' field contains specified text.

=item * B<perl_version.in> => I<array[str]>

Only return records where the 'perl_version' field is in the specified values.

=item * B<perl_version.is> => I<str>

Only return records where the 'perl_version' field equals specified value.

=item * B<perl_version.isnt> => I<str>

Only return records where the 'perl_version' field does not equal specified value.

=item * B<perl_version.max> => I<str>

Only return records where the 'perl_version' field is less than or equal to specified value.

=item * B<perl_version.min> => I<str>

Only return records where the 'perl_version' field is greater than or equal to specified value.

=item * B<perl_version.not_contains> => I<str>

Only return records where the 'perl_version' field does not contain specified text.

=item * B<perl_version.not_in> => I<array[str]>

Only return records where the 'perl_version' field is not in the specified values.

=item * B<perl_version.xmax> => I<str>

Only return records where the 'perl_version' field is less than specified value.

=item * B<perl_version.xmin> => I<str>

Only return records where the 'perl_version' field is greater than specified value.

=item * B<php_version> => I<str>

Only return records where the 'php_version' field equals specified value.

=item * B<php_version.contains> => I<str>

Only return records where the 'php_version' field contains specified text.

=item * B<php_version.in> => I<array[str]>

Only return records where the 'php_version' field is in the specified values.

=item * B<php_version.is> => I<str>

Only return records where the 'php_version' field equals specified value.

=item * B<php_version.isnt> => I<str>

Only return records where the 'php_version' field does not equal specified value.

=item * B<php_version.max> => I<str>

Only return records where the 'php_version' field is less than or equal to specified value.

=item * B<php_version.min> => I<str>

Only return records where the 'php_version' field is greater than or equal to specified value.

=item * B<php_version.not_contains> => I<str>

Only return records where the 'php_version' field does not contain specified text.

=item * B<php_version.not_in> => I<array[str]>

Only return records where the 'php_version' field is not in the specified values.

=item * B<php_version.xmax> => I<str>

Only return records where the 'php_version' field is less than specified value.

=item * B<php_version.xmin> => I<str>

Only return records where the 'php_version' field is greater than specified value.

=item * B<postgresql_version> => I<str>

Only return records where the 'postgresql_version' field equals specified value.

=item * B<postgresql_version.contains> => I<str>

Only return records where the 'postgresql_version' field contains specified text.

=item * B<postgresql_version.in> => I<array[str]>

Only return records where the 'postgresql_version' field is in the specified values.

=item * B<postgresql_version.is> => I<str>

Only return records where the 'postgresql_version' field equals specified value.

=item * B<postgresql_version.isnt> => I<str>

Only return records where the 'postgresql_version' field does not equal specified value.

=item * B<postgresql_version.max> => I<str>

Only return records where the 'postgresql_version' field is less than or equal to specified value.

=item * B<postgresql_version.min> => I<str>

Only return records where the 'postgresql_version' field is greater than or equal to specified value.

=item * B<postgresql_version.not_contains> => I<str>

Only return records where the 'postgresql_version' field does not contain specified text.

=item * B<postgresql_version.not_in> => I<array[str]>

Only return records where the 'postgresql_version' field is not in the specified values.

=item * B<postgresql_version.xmax> => I<str>

Only return records where the 'postgresql_version' field is less than specified value.

=item * B<postgresql_version.xmin> => I<str>

Only return records where the 'postgresql_version' field is greater than specified value.

=item * B<python_version> => I<str>

Only return records where the 'python_version' field equals specified value.

=item * B<python_version.contains> => I<str>

Only return records where the 'python_version' field contains specified text.

=item * B<python_version.in> => I<array[str]>

Only return records where the 'python_version' field is in the specified values.

=item * B<python_version.is> => I<str>

Only return records where the 'python_version' field equals specified value.

=item * B<python_version.isnt> => I<str>

Only return records where the 'python_version' field does not equal specified value.

=item * B<python_version.max> => I<str>

Only return records where the 'python_version' field is less than or equal to specified value.

=item * B<python_version.min> => I<str>

Only return records where the 'python_version' field is greater than or equal to specified value.

=item * B<python_version.not_contains> => I<str>

Only return records where the 'python_version' field does not contain specified text.

=item * B<python_version.not_in> => I<array[str]>

Only return records where the 'python_version' field is not in the specified values.

=item * B<python_version.xmax> => I<str>

Only return records where the 'python_version' field is less than specified value.

=item * B<python_version.xmin> => I<str>

Only return records where the 'python_version' field is greater than specified value.

=item * B<query> => I<str>

Search.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<reldate> => I<date>

Only return records where the 'reldate' field equals specified value.

=item * B<reldate.in> => I<array[date]>

Only return records where the 'reldate' field is in the specified values.

=item * B<reldate.is> => I<date>

Only return records where the 'reldate' field equals specified value.

=item * B<reldate.isnt> => I<date>

Only return records where the 'reldate' field does not equal specified value.

=item * B<reldate.max> => I<date>

Only return records where the 'reldate' field is less than or equal to specified value.

=item * B<reldate.min> => I<date>

Only return records where the 'reldate' field is greater than or equal to specified value.

=item * B<reldate.not_in> => I<array[date]>

Only return records where the 'reldate' field is not in the specified values.

=item * B<reldate.xmax> => I<date>

Only return records where the 'reldate' field is less than specified value.

=item * B<reldate.xmin> => I<date>

Only return records where the 'reldate' field is greater than specified value.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<ruby_version> => I<str>

Only return records where the 'ruby_version' field equals specified value.

=item * B<ruby_version.contains> => I<str>

Only return records where the 'ruby_version' field contains specified text.

=item * B<ruby_version.in> => I<array[str]>

Only return records where the 'ruby_version' field is in the specified values.

=item * B<ruby_version.is> => I<str>

Only return records where the 'ruby_version' field equals specified value.

=item * B<ruby_version.isnt> => I<str>

Only return records where the 'ruby_version' field does not equal specified value.

=item * B<ruby_version.max> => I<str>

Only return records where the 'ruby_version' field is less than or equal to specified value.

=item * B<ruby_version.min> => I<str>

Only return records where the 'ruby_version' field is greater than or equal to specified value.

=item * B<ruby_version.not_contains> => I<str>

Only return records where the 'ruby_version' field does not contain specified text.

=item * B<ruby_version.not_in> => I<array[str]>

Only return records where the 'ruby_version' field is not in the specified values.

=item * B<ruby_version.xmax> => I<str>

Only return records where the 'ruby_version' field is less than specified value.

=item * B<ruby_version.xmin> => I<str>

Only return records where the 'ruby_version' field is greater than specified value.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<version> => I<str>

Only return records where the 'version' field equals specified value.

=item * B<version.contains> => I<str>

Only return records where the 'version' field contains specified text.

=item * B<version.in> => I<array[str]>

Only return records where the 'version' field is in the specified values.

=item * B<version.is> => I<str>

Only return records where the 'version' field equals specified value.

=item * B<version.isnt> => I<str>

Only return records where the 'version' field does not equal specified value.

=item * B<version.max> => I<str>

Only return records where the 'version' field is less than or equal to specified value.

=item * B<version.min> => I<str>

Only return records where the 'version' field is greater than or equal to specified value.

=item * B<version.not_contains> => I<str>

Only return records where the 'version' field does not contain specified text.

=item * B<version.not_in> => I<array[str]>

Only return records where the 'version' field is not in the specified values.

=item * B<version.xmax> => I<str>

Only return records where the 'version' field is less than specified value.

=item * B<version.xmin> => I<str>

Only return records where the 'version' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hash/associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Ubuntu-Releases>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Ubuntu-Releases>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Ubuntu-Releases>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Debian::Releases>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
