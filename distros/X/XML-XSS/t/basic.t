
use strict;
use warnings;

use Test::More;

use XML::XSS;
use Scalar::Util qw/ refaddr /;

my $xss = XML::XSS->new;

my $xml = '<doc><foo>bar</foo></doc>';

my $bare = $xss->render( $xml );

is $bare => $xml, 'no-op transform';

is refaddr( $xss->catchall_element->stylesheet ), refaddr $xss;

done_testing();



