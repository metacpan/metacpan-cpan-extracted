use strict;

use FindBin;
use File::Spec;
use lib File::Spec->catfile($FindBin::Bin, 'lib');

use Test::More tests => 2;

#------------------------------------------------------------------
open F, '<', "$FindBin::Bin/../lib/XHTML/Util.pm"
    or die "Couldn't open self module to read!";

my $synopsis = '';
while ( <F> ) {
    if ( /=head1 SYNOPSIS/i .. /=head\d (?!S)/
                   and not /^=/ )
    {
        $synopsis .= $_;
    }
}
close F;

ok( $synopsis,
    "Got code out of the SYNOPSIS space to evaluate" );

diag( $synopsis ) if $ENV{TEST_VERBOSE};


my $ok = eval "$synopsis; print qq{\n}; 1;";

ok( $ok,  "Synopsis eval'd" );

diag( $@ . "\n" . $synopsis ) if $@ and $ENV{TEST_VERBOSE};
