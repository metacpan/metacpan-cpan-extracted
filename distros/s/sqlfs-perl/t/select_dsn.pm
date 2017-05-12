package select_dsn;
use base Exporter;
our @EXPORT = qw(first_dsn all_dsn);

use strict;
use warnings;
use DBI;
use FindBin '$Bin';

sub all_dsn {
    return split /\s+/,$ENV{TEST_DSN} if $ENV{TEST_DSN};
    my @result;

    my %drivers = map {$_=>1} DBI->available_drivers;
    my $base = "$Bin/../lib/DBI/Filesystem/DBD";
    foreach (keys %drivers) {
	next unless eval {require "$base/${_}.pm"};
	my $class    = 'DBI::Filesystem::DBD::'.$_;
	my $dsn      = eval{$class->test_dsn} or next;
	my $dbh      = DBI->connect($dsn,undef,undef,{PrintError=>0}) or next;
	push @result,$dsn;
    }
    $ENV{TEST_DSN} = join ' ',@result;
    return @result;
}

sub first_dsn {
    my @dsn = all_dsn() or return;
    return $dsn[0];
}

1;
