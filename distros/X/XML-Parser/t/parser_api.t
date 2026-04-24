use strict;
use warnings;
use Test::More;
use XML::Parser;

# Test the XML::Parser API surface: setHandlers, parsefile error paths,
# parser reuse, parsestring alias, and void-context behavior.

my $simple_xml = '<root><child>text</child></root>';

# --- setHandlers returns previous handlers ---
{
    my $h1 = sub { };
    my $h2 = sub { };

    my $p = XML::Parser->new(Handlers => { Start => $h1 });

    my @old = $p->setHandlers(Start => $h2);
    is($old[0], 'Start', 'setHandlers returns handler type');
    is($old[1], $h1, 'setHandlers returns previous handler ref');

    # Setting to undef unsets the handler
    @old = $p->setHandlers(Start => undef);
    is($old[1], $h2, 'setHandlers returns handler that was just set');
}

# --- setHandlers with multiple pairs ---
{
    my $start = sub { };
    my $end   = sub { };
    my $p = XML::Parser->new;

    my @old = $p->setHandlers(Start => $start, End => $end);
    is(scalar @old, 4, 'setHandlers returns pair for each input pair');
    is($old[0], 'Start', 'first returned type');
    ok(!defined $old[1], 'first old handler is undef (was not set)');
    is($old[2], 'End', 'second returned type');
    ok(!defined $old[3], 'second old handler is undef (was not set)');
}

# --- setHandlers croaks on unknown handler type ---
{
    my $p = XML::Parser->new;
    eval { $p->setHandlers(BogusHandler => sub { }) };
    like($@, qr/Unknown Parser handler type/, 'setHandlers croaks on unknown type');
}

# --- setHandlers croaks on odd number of arguments ---
{
    my $p = XML::Parser->new;
    eval { $p->setHandlers('Start') };
    like($@, qr/Uneven number/, 'setHandlers croaks on odd arg count');
}

# --- parsefile croaks on non-existent file ---
{
    my $p = XML::Parser->new;
    eval { $p->parsefile('/nonexistent/path/to/file.xml') };
    like($@, qr/Couldn't open/, 'parsefile croaks on missing file');
}

# --- parsestring is an alias for parse ---
{
    my @starts;
    my $p = XML::Parser->new(
        Handlers => { Start => sub { push @starts, $_[1] } },
    );
    $p->parsestring($simple_xml);
    is_deeply(\@starts, ['root', 'child'], 'parsestring works as parse alias');
}

# --- Parser reuse: same parser, multiple documents ---
{
    my @all_starts;
    my $p = XML::Parser->new(
        Handlers => { Start => sub { push @all_starts, $_[1] } },
    );

    $p->parse('<a/>');
    $p->parse('<b><c/></b>');
    $p->parse('<d/>');

    is_deeply(\@all_starts, ['a', 'b', 'c', 'd'],
        'parser reuse: handlers accumulate across multiple parses');
}

# --- Parser reuse with setHandlers between parses ---
{
    my (@first, @second);
    my $p = XML::Parser->new(
        Handlers => { Start => sub { push @first, $_[1] } },
    );

    $p->parse('<x/>');
    $p->setHandlers(Start => sub { push @second, $_[1] });
    $p->parse('<y/>');

    is_deeply(\@first, ['x'], 'first parse uses first handler');
    is_deeply(\@second, ['y'], 'second parse uses swapped handler');
}

# --- parse in scalar context returns 1 without Final handler ---
{
    my $p = XML::Parser->new;
    my $ret = $p->parse($simple_xml);
    is($ret, 1, 'parse returns 1 in scalar context without Final handler');
}

# --- parse with Final handler returns its value ---
{
    my $p = XML::Parser->new(
        Handlers => { Final => sub { return 'done' } },
    );
    my $ret = $p->parse($simple_xml);
    is($ret, 'done', 'parse returns Final handler result in scalar context');
}

# --- parse with Final handler in list context ---
{
    my $p = XML::Parser->new(
        Handlers => { Final => sub { return ('a', 'b') } },
    );
    my @ret = $p->parse($simple_xml);
    is_deeply(\@ret, ['a', 'b'], 'parse returns Final list in list context');
}

# --- Init handler is called ---
{
    my $init_called = 0;
    my $p = XML::Parser->new(
        Handlers => { Init => sub { $init_called = 1 } },
    );
    $p->parse($simple_xml);
    ok($init_called, 'Init handler is called during parse');
}

# --- parse with extra Expat options overriding constructor ---
{
    my $got_context;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { $got_context = $_[0]->{ErrorContext} },
        },
    );
    $p->parse($simple_xml, ErrorContext => 3);
    is($got_context, 3, 'extra options to parse override constructor');
}

# --- Custom style with full package name ---
{
    # Define a minimal style package
    {
        package My::Custom::Style;
        sub Init  { $_[0]->{_custom_init} = 1 }
        sub Final { return 'custom_result' }
    }

    my $p = XML::Parser->new(Style => 'My::Custom::Style');
    my $ret = $p->parse($simple_xml);
    is($ret, 'custom_result', 'custom style with full package name works');
}

# --- Pkg defaults to caller ---
{
    my $p = XML::Parser->new;
    is($p->{Pkg}, 'main', 'Pkg defaults to caller package');
}

# --- parsefile with actual file ---
{
    use File::Temp qw(tempfile);
    my ($fh, $tmpfile) = tempfile(UNLINK => 1, SUFFIX => '.xml');
    print $fh '<?xml version="1.0"?><doc attr="1">content</doc>';
    close $fh;

    my @events;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { push @events, "S:$_[1]" },
            Char  => sub { push @events, "C:$_[1]" },
            End   => sub { push @events, "E:$_[1]" },
        },
    );
    $p->parsefile($tmpfile);
    is_deeply(\@events, ['S:doc', 'C:content', 'E:doc'],
        'parsefile parses a real file correctly');
}

# --- parsefile restores Base after parse ---
{
    use File::Temp qw(tempfile);
    my ($fh, $tmpfile) = tempfile(UNLINK => 1, SUFFIX => '.xml');
    print $fh '<r/>';
    close $fh;

    my $p = XML::Parser->new;
    $p->{Base} = 'original_base';
    $p->parsefile($tmpfile);
    is($p->{Base}, 'original_base', 'parsefile restores Base after parse');
}

# --- parsefile restores Base even on parse error ---
{
    use File::Temp qw(tempfile);
    my ($fh, $tmpfile) = tempfile(UNLINK => 1, SUFFIX => '.xml');
    print $fh '<unclosed>';  # malformed XML
    close $fh;

    my $p = XML::Parser->new;
    $p->{Base} = 'saved_base';
    eval { $p->parsefile($tmpfile) };
    ok($@, 'parsefile dies on malformed XML');
    is($p->{Base}, 'saved_base', 'parsefile restores Base even after error');
}

# --- Init handler die releases parser (no circular ref leak) ---
{
    my $released = 0;
    my $p = XML::Parser->new(
        Handlers => {
            Init => sub { die "init failed\n" },
        },
    );
    eval { $p->parse('<root/>') };
    like($@, qr/init failed/, 'Init handler die propagates correctly');
    # Parser should still be usable after Init failure
    my $ok = eval {
        $p->setHandlers(Init => undef);
        $p->parse('<root/>');
        1;
    };
    ok($ok, 'Parser reusable after Init handler failure');
}

# --- Final handler die still releases parser ---
{
    my $p = XML::Parser->new(
        Handlers => {
            Final => sub { die "final failed\n" },
        },
    );
    eval { $p->parse('<root/>') };
    like($@, qr/final failed/, 'Final handler die propagates correctly');
    # Parser should still be usable
    my $ok = eval {
        $p->setHandlers(Final => undef);
        $p->parse('<root/>');
        1;
    };
    ok($ok, 'Parser reusable after Final handler failure');
}

# --- parse_start Init handler die releases parser ---
{
    my $p = XML::Parser->new(
        Handlers => {
            Init => sub { die "init_nb failed\n" },
        },
    );
    eval { $p->parse_start() };
    like($@, qr/init_nb failed/, 'parse_start Init handler die propagates correctly');
}

done_testing;
