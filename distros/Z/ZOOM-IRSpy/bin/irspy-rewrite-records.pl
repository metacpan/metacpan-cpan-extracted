#!/usr/bin/perl
#
# perl -I ../lib irspy-rewrite-records.pl localhost:8018/IR-Explain---1

use lib '../lib';
use Data::Dumper;
use Getopt::Long;
use ZOOM::IRSpy;
use ZOOM::IRSpy::Utils qw(render_record validate_record);

use strict;
use warnings;

my $irspy_to_zeerex_xsl = '../xsl/irspy2zeerex.xsl';
my $debug               = 1;
my $cql_query           = "cql.allRecords=1";

sub usage {
    my $message = shift;

    warn "$message\n" if defined $message;

    <<EOF
usage $0 [ options ] database

--xslt=$irspy_to_zeerex_xsl	set xslt sheet
--debug=0..2              	verbose level
--query=$cql_query
EOF
}

GetOptions(
    "xslt"    => \$irspy_to_zeerex_xsl,
    "debug=i" => \$debug,
    "query=s" => \$cql_query,
);

my $dbname = shift;
die usage("no database name specified\n") if !defined $dbname;

$ZOOM::IRSpy::irspy_to_zeerex_xsl = $irspy_to_zeerex_xsl
  if $irspy_to_zeerex_xsl;

my $spy = new ZOOM::IRSpy( $dbname, "admin", "fruitbat" );
my $rs = $spy->{conn}->search( new ZOOM::Query::CQL($cql_query) );
print STDERR "rewriting ", $rs->size(), " target records\n" if $debug;

foreach my $i ( 1 .. $rs->size() ) {
    my $xml = render_record( $rs, $i - 1, "zeerex" );
    my $rec = $spy->{libxml}->parse_string($xml)->documentElement();

    if ( $debug >= 2 ) {
        my ( $ok, $errors ) = validate_record($rec);
        if ( !$ok ) {
            my @e  = @$errors;
            my $id = shift @e;
            print "Id: $id => ", join( " / ", @e ), "\n";
        }
    }
    ZOOM::IRSpy::_rewrite_zeerex_record( $spy->{conn}, $rec );
    print STDERR "." if $debug == 1;
}
print STDERR "Done\n" if $debug;

