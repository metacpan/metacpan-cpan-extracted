# This is a test for module WWW::CheckGzip.

use warnings;
use strict;
use Test::More;
use_ok ('WWW::CheckGzip');

if ($ENV{WEBSITE}) {
    my $wc = WWW::CheckGzip->new (\& mycheck);
    $wc->check ($ENV{WEBSITE});
}

done_testing ();

sub mycheck
{
    my ($ok, $message) = @_;
    ok ($ok, $message);
}

# Local variables:
# mode: perl
# End:
