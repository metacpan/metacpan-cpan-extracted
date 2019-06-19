#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
# use DBD::mysql;
use WWW::AzimuthAero::PriceCrawler;
use Data::Dumper;

# for testing:

=head1

docker run --name mysql-srv-demo \
    -e MYSQL_ROOT_PASSWORD=goodNewsEO1 \
    -e MYSQL_DATABASE=azimuth \
    -e MYSQL_USER=crawler \
    -e MYSQL_PASSWORD=r0v \
    -p 3333:3306 \
    mysql:5.7

=cut

$ENV{'DB_HOST'} ||= '127.0.0.1';
$ENV{'DB_PORT'} ||= '3333';
$ENV{'DATABASE'} ||= 'azimuth';
$ENV{'DB_USER'} ||= 'crawler';
$ENV{'DB_PASSWORD'} ||= 'r0v';

my $dsn = "DBI:mysql:database=".$ENV{'DATABASE'}.";host=".$ENV{'DB_HOST'}.";port=".$ENV{'DB_PORT'};
my $dbh = DBI->connect( $dsn, $ENV{'DB_USER'}, $ENV{'DB_PASSWORD'}, {'RaiseError' => 1} );

# my $work_table = 'azimuth';
# $dbh = DBI->connect($data_source, $username, $auth, \%attr);

# my $azo_price_crawler = WWW::AzimuthAero::PriceCrawler->new;

my $doc = {
    'date'   => '23.06.2019',
    'flight' => {
        'departure' => '07:45',
        'arrival'   => '09:45'
    },
    'to'    => 'MOW',
    'fares' => {
        'lowest'     => 5980,
        'svobodnyy'  => 10980,
        'optimalnyy' => 5980
    },
    'from' => 'ROV'
};

$dbh->do("INSERT INTO flights VALUES (?, ?)");

