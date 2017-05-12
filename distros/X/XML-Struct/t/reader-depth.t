use strict;
use Test::More;
use XML::Struct qw(readXML simpleXML);
use Scalar::Util qw(reftype);

sub sample { return readXML('t/nested.xml', @_) }

my $simple = sample(simple => 1);

is_deeply sample( simple => 1, depth => -1 ),
    $simple, 'simple, depth -1';

is_deeply sample( simple => 1, depth => undef ),
    $simple, 'simple, depth undef';

is_deeply sample( simple => 1, depth => 1, deep => 'simple'),
    $simple, 'simple, depth overridden by deep';

is_deeply sample( depth => 0, deep => 'simple'),
    $simple, 'depth 0, deep simple implies simple';

is_deeply sample( depth => 0, deep => 'simple', root => 1 ),
    sample( simple => 1, root => 1), 'depth 0, deep simple, root';

is_deeply sample( simple => 1, depth => 1 )->{foo},
    [ [ foo => {}, [ [ 'bar' => {}, [] ] ] ] ],
    'simple, depth 1';

is_deeply sample( simple => 1, depth => 2 )->{foo}->{bar},
    [ [ bar => {}, [] ] ],
    'simple, depth 2';

is_deeply sample( simple => 1, depth => 2, root => 1 )->{nested}->{foo},
    [ [ foo => {}, [ [ bar => {}, [] ] ] ] ],
    'simple, depth 2, root';

is_deeply sample( simple => 1, depth => 1, root => 1 )->{nested},
    readXML('t/nested.xml'), 'simple 1, depth 1, root 1';
  

ok sample( depth => 0, deep => 'dom' )->isa('XML::LibXML::Element'),
    'depth 0, deep dom';

like sample( depth => 0, deep => 'raw' ), qr{^<nested>.+</nested>$}sm,
    'depth 0, deep raw';

done_testing;
