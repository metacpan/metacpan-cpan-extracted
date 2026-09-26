use strict;
use warnings;
use Test::More;
use Text::KDL::XS;

sub events {
    my ($kdl, @options) = @_;
    my $parser = Text::KDL::XS::Parser->new($kdl, @options);
    my @events;
    while (my $event = $parser->next_event) { push @events, $event }
    return @events;
}

# Comment events carry the comment text with its delimiters.
{
    my @comments = grep { $_->{event} eq 'comment' }
        events("// caf\x{e9}\n/* multi\n   line */ a\nb // trailing\n", emit_comments => 1);
    is_deeply [ map { $_->{text} } @comments ], [ "// caf\x{e9}", "/* multi\n   line */", '// trailing' ],
        'comment text includes the delimiters';
    is_deeply [ map { $_->{commented} } @comments ], [ 1, 1, 1 ], 'comment events are flagged commented';
}
is scalar(grep { $_->{event} eq 'comment' } events("// note\na\n")), 0, 'no comment events without emit_comments';

# Slashdashed elements are reported with commented => 1.
{
    my @events = events("/-a 1\nb /-2 3 /-k=4 /-{\n    c\n}\n", emit_comments => 1);
    my @summary = map { join ' ', $_->{event}, $_->{commented}, $_->{name} // (ref $_->{value} ? $_->{value}->as_string : '') } @events;
    is_deeply \@summary, [
        'start_node 1 a', 'argument 1 1', 'end_node 1 ',
        'start_node 0 b', 'argument 1 2', 'argument 0 3', 'property 1 k',
        'start_node 1 c', 'end_node 1 ', 'end_node 0 ',
    ], 'nodes, arguments, properties and children blocks carry the commented flag';
}

done_testing;
