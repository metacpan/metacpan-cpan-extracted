#!perl
# changes.t: Make sure the Changes file is updated

use 5.012;
use strict;
use warnings;

use Test::More tests => 1;
use File::Grep qw(fgrep);
use DateTime;
#use Test::OnlySome;    # TODO also check the version

# Make a regex for the current date

my $now;
eval { $now = DateTime->now( timezone => 'local' ); };
$now = DateTime->now() if $@;

# Which date formats we will accept.  For now, numeric only, so that I
# don't have to worry about locales.
my @valid_dates = ( $now->ymd, $now->ymd('/'), $now->mdy, $now->mdy('/'),
    $now->dmy, $now->dmy('/') );
my $re = join('|', map { quotemeta } @valid_dates);
#diag "Regex is $re";

# "Changes" header line format: ^<version> <date>$.  Assume Changes is in cwd.
ok( scalar fgrep { /^\S+\s+$re$/ } 'Changes',
    "Changes file contains an entry for today's date");

# vi: set ft=perl: #
