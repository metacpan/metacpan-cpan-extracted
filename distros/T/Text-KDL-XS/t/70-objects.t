use strict;
use warnings;
use Config;
use Test::More;
use Scalar::Util qw(weaken);
use Text::KDL::XS qw(parse_kdl emit_kdl);

sub dies_like (&$$) {
    my ($code, $pattern, $name) = @_;
    my $lived = eval { $code->(); 1 };
    ok !$lived && $@ =~ $pattern, $name or diag $lived ? 'did not die' : $@;
}

# Parser objects can be subclassed and re-blessed.
{
    @Local::Parser::ISA = ('Text::KDL::XS::Parser');
    my $parser = Local::Parser->new("a 1\n");
    isa_ok $parser, 'Local::Parser';
    is $parser->next_event->{name}, 'a', 'a subclass object parses';

    my $plain = Text::KDL::XS::Parser->new("b 1\n");
    bless $plain, 'Local::Parser';
    is $plain->next_event->{name}, 'b', 'a re-blessed object keeps working';
}
dies_like { Text::KDL::XS::Parser::_new_string_parser('Local::Unrelated', "a\n", Text::KDL::XS::_OPT_DETECT(), 0) }
    qr/'Local::Unrelated' is not Text::KDL::XS::Parser or a subclass of it/, 'an unrelated class is refused';

# The C structure belongs to the object and is freed exactly once with it.
{
    ok !Text::KDL::XS::Parser->can('DESTROY'), 'there is no DESTROY method to call twice';
    my $parser = Text::KDL::XS::Parser->new("a 1\n");
    weaken(my $weak = $parser);
    undef $parser;
    ok !defined $weak, 'the parser is freed with its last reference';
}

# Forged or modified objects cannot reach the C structure.
dies_like { Text::KDL::XS::Parser::_next_event(bless \(my $fake = 0), 'Text::KDL::XS::Parser') }
    qr/not a valid Text::KDL::XS::Parser object/, 'a forged scalar object dies';
dies_like { Text::KDL::XS::Parser::_next_event(bless {}, 'Text::KDL::XS::Parser') }
    qr/not a valid Text::KDL::XS::Parser object/, 'a forged hash object dies';
dies_like { Text::KDL::XS::Emitter::_emit_end(bless [], 'Text::KDL::XS::Emitter') }
    qr/not a valid Text::KDL::XS::Emitter object/, 'a forged emitter dies';
{
    my $parser = Text::KDL::XS::Parser->new("a 1\n");
    $$parser = 1;
    is $parser->next_event->{name}, 'a', 'overwriting the object scalar does not affect the parser';
}

# Parsed values are ordinary hashes that may be changed.
{
    my $value = parse_kdl("n #null\n")->nodes->[0]->args->[0];
    $value->{type_annotation} = 'u8';
    $value->{value} = 5;
    is_deeply [ @$value{qw(type_annotation value)} ], [ 'u8', 5 ], 'a parsed value can be modified';
}

# Threads started while parser and emitter objects exist do not clone them.
SKIP: {
    skip 'this perl has no ithreads', 3 unless $Config{useithreads};
    require threads;
    my $parser  = Text::KDL::XS::Parser->new("a 1\nb 2\n");
    my $emitter = Text::KDL::XS::Emitter->_new(0, -1, -1, -1);
    $parser->next_event;
    my $child = threads->create(sub { emit_kdl(parse_kdl("x 1\n")) . ref $parser })->join;
    is $child, "x 1\nSCALAR", 'a thread can parse and emit; it sees the objects of its parent unblessed';
    is $parser->next_event->{event}, 'argument', 'the parent parser continues after the thread ends';
    $emitter->_emit_node('z', undef);
    $emitter->_emit_end;
    is $emitter->_get_buffer, "z\n", 'the parent emitter continues after the thread ends';
}

done_testing;
