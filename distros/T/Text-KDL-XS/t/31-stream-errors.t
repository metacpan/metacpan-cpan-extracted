use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Text::KDL::XS qw(parse_kdl);

# A source that delivers the given chunks, then dies with $error.
sub failing_source {
    my ($error, @chunks) = @_;
    return sub { return shift @chunks if @chunks; die $error };
}

{
    my $lived = eval { parse_kdl(failing_source("boom\n")); 1 };
    ok !$lived, 'a dying source makes parse_kdl die';
    is $@, "boom\n", 'with the exception of the source, unchanged';
}
{
    my $error = bless { reason => 'disk' }, 'Local::Error';
    eval { parse_kdl(failing_source($error, "a 1\n")) };
    is $@, $error, 'an exception object from the source is passed through as the same object';
}
{
    my $parser = Text::KDL::XS::Parser->new(failing_source("disk error\n", "a 1\nb 2 {\n", "  c 3\n"));
    my @events;
    while (my $event = eval { $parser->next_event }) { push @events, $event->{event} }
    is $@, "disk error\n", 'a source failing mid-stream raises its exception';
    is_deeply \@events, [qw(start_node argument end_node start_node argument start_node argument end_node)],
        'after the events read so far';
    eval { $parser->next_event };
    is $@, "disk error\n", 'the error is raised again by every later call';
}
{
    my $sent = 0;
    eval { parse_kdl(sub { $sent++ ? '' : [] }) };
    like $@, qr/source callback must return a string or undef/, 'a source returning a reference dies';
}
{
    my (undef, $path) = tempfile(UNLINK => 1);
    open my $write_only, '>', $path or die "open: $!";
    local $SIG{__WARN__} = sub { };    # perl warns "opened only for output"
    my $lived = eval { parse_kdl($write_only); 1 };
    ok !$lived && $@ =~ /read failed/, 'a handle that cannot be read dies';
    close $write_only;
}
{
    my ($parser, $inner_error);
    my $chunks = 0;
    $parser = Text::KDL::XS::Parser->new(sub {
        return '' if $chunks++ > 1;
        eval { $parser->next_event } if $chunks == 2;
        $inner_error = $@ if $chunks == 2;
        return "a 1\n";
    });
    my $count = 0;
    $count++ while $parser->next_event;
    like $inner_error, qr/next_event called from inside the parser's own source callback/,
        'calling next_event from the source callback dies';
    is $count, 6, 'and the outer parse is not disturbed';
}
{
    my $parser;
    my $chunks = 0;
    $parser = Text::KDL::XS::Parser->new(sub {
        undef $parser if ++$chunks == 2;
        return $chunks < 4 ? "b 2\n" x 500 : '';
    });
    my $events = 0;
    $events++ while $parser && $parser->next_event;
    ok $events > 0 && !defined $parser, 'a source may drop the last reference to its parser';
}

done_testing;
