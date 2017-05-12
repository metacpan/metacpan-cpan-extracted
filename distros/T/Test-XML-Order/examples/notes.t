# @(#) $Id$
use strict;
use warnings;

use Test::More tests => 2;
use Test::XML::Order;

my $input1 = q(<a a="b"/>x<b></b>);
my $input2 = q(<a><b/></a>);

is_xml_in_order(
    $input1,
    q(<a/><b a="c">asdf</b>)
);

isnt_xml_in_order(
    $input2,
    q(<a/><b/>)
);

__END__

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim: set ai et sw=4 syntax=perl :
