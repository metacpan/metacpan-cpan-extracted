use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl emit_kdl);

my $original = <<'KDL';
greeting "hello"
package "thing" {
    version "1.0"
    author "Kat" email="kat@example.com"
}
KDL

my $doc = parse_kdl($original);
my $out = emit_kdl($doc);

ok length($out) > 0, 'emitter produced output';

# Round-trip: re-parsing the emitted KDL must yield the same shape.
my $doc2 = parse_kdl($out);
is_deeply $doc->as_data, $doc2->as_data, 'round-trip preserves structure';

done_testing;
