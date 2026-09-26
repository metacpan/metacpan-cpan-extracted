use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl);

sub nested { my ($depth) = @_; return ("a {\n" x ($depth - 1)) . "a\n" . ("}\n" x ($depth - 1)) }
sub dies_like (&$$) {
    my ($code, $pattern, $name) = @_;
    my $lived = eval { $code->(); 1 };
    ok !$lived && $@ =~ $pattern, $name or diag $lived ? 'did not die' : $@;
}

ok parse_kdl(nested(512)), 'nesting 512 levels deep is allowed by default';
dies_like { parse_kdl(nested(513)) } qr/\AKDL parse error: nesting depth exceeds max_depth \(512\)/,
    'nesting 513 levels deep dies by default';
dies_like { parse_kdl(nested(4), max_depth => 3) } qr/exceeds max_depth \(3\)/, 'a smaller max_depth';
is scalar @{ parse_kdl(nested(2000), max_depth => 0)->nodes }, 1, 'max_depth 0 means unlimited';

{
    my $parser = Text::KDL::XS::Parser->new(nested(3), max_depth => 2);
    my $events = 0;
    $events++ while eval { $parser->next_event };
    like $@, qr/exceeds max_depth \(2\)/, 'the streaming parser enforces max_depth';
    is $events, 2, 'after the events within the limit';
}

for my $bad (-1, 'deep', 1.5) {
    dies_like { parse_kdl("a\n", max_depth => $bad) } qr/max_depth must be a non-negative integer/,
        "max_depth '$bad' dies";
}

done_testing;
