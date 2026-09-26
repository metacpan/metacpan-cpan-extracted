use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl emit_kdl);

eval { parse_kdl("foo {\n") };
ok $@, 'unclosed brace dies';
like $@, qr/KDL/i, 'error mentions KDL';

eval { parse_kdl("== invalid ==\n") };
ok $@, 'malformed input dies';

eval { parse_kdl(undef) };
ok $@, 'undef source dies';

# Parse errors carry ckdl's reason.
eval { parse_kdl("foo {\n") };
like $@, qr/\AKDL parse error: Unexpected end of data \(unclosed lists of children\) at /, 'reason for an unclosed block';
eval { parse_kdl("a /-\n") };
like $@, qr/\AKDL parse error: Dangling slashdash \(\/-\) at /, 'reason for a dangling slashdash';

# Errors are reported at the caller's line.
my $here = qr/ at \Q$0\E line \d+\.$/;
eval { parse_kdl("foo {\n") };
like $@, $here, 'a parse error points at the caller';
eval { my $parser = Text::KDL::XS::Parser->new("foo {\n"); $parser->next_event for 1 .. 2 };
like $@, $here, 'a next_event error points at the caller';
eval { parse_kdl([]) };
like $@, $here, 'an unsupported source points at the caller';
eval { parse_kdl("a\n", version => 3) };
like $@, $here, 'a bad option points at the caller';
eval { emit_kdl({ n => "\x{D800}" }) };
like $@, $here, 'an emitter error points at the caller';
eval { Text::KDL::XS::Value->new(type => 'bogus') };
like $@, $here, 'a constructor error points at the caller';

# After an error every call fails the same way; after the end, undef.
{
    my $parser = Text::KDL::XS::Parser->new("a 1\nb )\nc 3\n");
    my @kinds;
    while (my $event = eval { $parser->next_event }) { push @kinds, $event->{event} }
    my $first = $@;
    like $first, qr/\AKDL parse error: /, 'malformed input fails';
    is_deeply \@kinds, [qw(start_node argument end_node start_node)], 'after the events before the error';
    eval { $parser->next_event };
    (my $again = $@) =~ s/ at .*//s;
    (my $first_reason = $first) =~ s/ at .*//s;
    is $again, $first_reason, 'the error is raised again by the next call';
}
{
    my $parser = Text::KDL::XS::Parser->new("a 1\n");
    1 while $parser->next_event;
    is $parser->next_event, undef, 'next_event returns undef after the end';
    is $parser->next_event, undef, 'and keeps returning undef';
}

done_testing;
