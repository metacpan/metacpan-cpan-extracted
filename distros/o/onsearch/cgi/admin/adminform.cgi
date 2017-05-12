#!/usr/bin/perl -w

#$Id: adminform.cgi,v 1.1 2005/07/15 01:07:12 kiesling Exp $

##  Path is relative to lib in parent directory.
BEGIN { use Config; unshift @INC, ("./../lib", "./../lib/$Config{archname}"); }

use POSIX qw/strftime/;
use OnSearch;
use OnSearch::UI;
use OnSearch::AppConfig;
use OnSearch::Utils;
use Carp;

my $lastindex = 'Not Indexed.';

###
###  To do - find latest modtime for multiple document roots.
###

my $c = OnSearch::AppConfig -> new;
my $SearchRoot = $c -> str ('SearchRoot');

my $app_dir = $SearchRoot . '/' . $c -> str ('OnSearchDir');
my $idx_prog = 'onindex';
my $IndexInterval = $c -> str('IndexInterval');
my $BackupIndexes = $c -> str('BackupIndexes');
my $DigitsOnly = $c -> str ('DigitsOnly');

if (-f "$SearchRoot/.onindex.idx") {
    $lastindex = strftime ("%a %b %e %H:%M:%S %Y", 
		   localtime ((stat ("$SearchRoot/.onindex.idx"))[9]));
    $lastindex =~ s/\s/\&nbsp\;/g;
}

my $ui = OnSearch::UI -> new;

### Expire after a day.
my $expires = http_date (86400);
$ui -> header_expires ('OnSearch', $expires) -> wprint;
$ui -> navbar_map -> wprint;
$ui -> javascripts -> wprint;
$ui -> navbar -> wprint;
$ui -> admin_page ($lastindex, $IndexInterval, $BackupIndexes, $DigitsOnly)
    -> wprint;
$ui -> html_footer -> wprint;
