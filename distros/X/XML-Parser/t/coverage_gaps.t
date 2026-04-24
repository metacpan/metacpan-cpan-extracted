use strict;
use warnings;
use Test::More;
use XML::Parser;
use XML::Parser::Expat;
use File::Temp qw(tempfile);
use IO::File;

# ===== Debug style: Proc handler (processing instructions) =====

{
    my $tmpfile = IO::File->new_tmpfile();
    open( my $olderr, '>&', \*STDERR ) or die "Cannot dup STDERR: $!";
    open( STDERR, '>&', $tmpfile->fileno ) or die "Cannot redirect STDERR: $!";

    my $p = XML::Parser->new( Style => 'Debug' );
    $p->parse('<root><?mypi some data?></root>');

    open( STDERR, '>&', $olderr ) or die "Cannot restore STDERR: $!";
    close $olderr;

    seek( $tmpfile, 0, 0 );
    my @lines = <$tmpfile>;
    chomp @lines;

    # Find PI line — format: "root mypi(some data)"
    my @pi_lines = grep { /mypi/ } @lines;
    is( scalar @pi_lines, 1, 'Debug: Proc handler produces output for PI' );
    like( $pi_lines[0], qr/mypi\(some data\)/, 'Debug: PI format is target(data)' );
    like( $pi_lines[0], qr/root/, 'Debug: PI line includes context' );
}

# ===== Stream style: Proc/PI handler =====

{
    my @events;
    {
        package StreamPITest;
        no warnings 'once';
        sub StartTag { }
        sub EndTag   { }
        sub Text     { }
        sub PI       { push @events, ['PI', $_[1], $_[2], $_] }
    }
    package main;

    XML::Parser->new( Style => 'Stream', Pkg => 'StreamPITest' )
        ->parse('<root><?target data?></root>');

    is( scalar @events, 1, 'Stream: PI handler called' );
    is( $events[0][0], 'PI', 'Stream: PI event type' );
    is( $events[0][1], 'target', 'Stream: PI target' );
    is( $events[0][2], 'data', 'Stream: PI data' );
    like( $events[0][3], qr/<\?target\s+data\?>/, 'Stream: $_ contains PI markup' );
}

# Stream: PI default handler (no PI sub defined) prints to STDOUT
{
    my $output = '';
    {
        package StreamPIDefault;
        no warnings 'once';
        sub StartTag { }
        sub EndTag   { }
        sub Text     { }
        # No PI handler — should print to STDOUT
    }
    package main;

    # Capture STDOUT
    open( my $oldout, '>&', \*STDOUT ) or die "Cannot dup STDOUT: $!";
    my $tmpfile = IO::File->new_tmpfile();
    open( STDOUT, '>&', $tmpfile->fileno ) or die "Cannot redirect STDOUT: $!";

    XML::Parser->new( Style => 'Stream', Pkg => 'StreamPIDefault' )
        ->parse('<root><?target data?></root>');

    open( STDOUT, '>&', $oldout ) or die "Cannot restore STDOUT: $!";
    close $oldout;

    seek( $tmpfile, 0, 0 );
    $output = join '', <$tmpfile>;
    like( $output, qr/<\?target\s+data\?>/, 'Stream: default PI prints to STDOUT' );
}

# ===== Expat::parsestring() =====

{
    my @tags;
    my $expat = XML::Parser::Expat->new;
    $expat->setHandlers( Start => sub { push @tags, $_[1] } );
    $expat->parsestring('<root><child/></root>');
    is_deeply( \@tags, ['root', 'child'], 'Expat::parsestring parses correctly' );
    $expat->release;
}

# ===== Expat::parsefile() =====

{
    my ( $fh, $filename ) = tempfile( SUFFIX => '.xml', UNLINK => 1 );
    print $fh '<doc><item/></doc>';
    close $fh;

    my @tags;
    my $expat = XML::Parser::Expat->new;
    $expat->setHandlers( Start => sub { push @tags, $_[1] } );
    $expat->parsefile($filename);
    is_deeply( \@tags, ['doc', 'item'], 'Expat::parsefile parses file correctly' );
    $expat->release;
}

# Expat::parsefile croak on reuse
{
    my ( $fh, $filename ) = tempfile( SUFFIX => '.xml', UNLINK => 1 );
    print $fh '<a/>';
    close $fh;

    my $expat = XML::Parser::Expat->new;
    $expat->parsefile($filename);

    eval { $expat->parsefile($filename) };
    like( $@, qr/already been used/, 'Expat::parsefile croaks on reuse' );
    $expat->release;
}

# ===== ContentModel MIXED asString =====

{
    my %models;
    my $parser = XML::Parser->new(
        Handlers => {
            Element => sub { $models{ $_[1] } = $_[2] },
        },
    );

    $parser->parse(<<'XML');
<?xml version="1.0"?>
<!DOCTYPE doc [
  <!ELEMENT doc (#PCDATA|alpha|beta)*>
  <!ELEMENT alpha EMPTY>
  <!ELEMENT beta EMPTY>
]>
<doc/>
XML

    ok( exists $models{doc}, 'MIXED model captured' );
    ok( $models{doc}->ismixed, 'model is MIXED type' );
    my $str = "$models{doc}";
    like( $str, qr/^\(#PCDATA/, 'MIXED asString starts with (#PCDATA' );
    like( $str, qr/alpha/, 'MIXED asString contains child name alpha' );
    like( $str, qr/beta/, 'MIXED asString contains child name beta' );
    like( $str, qr/\)\*?$/, 'MIXED asString ends with ) or )*' );
}

# ===== Namespace methods without Namespaces enabled =====

{
    my $expat = XML::Parser::Expat->new;
    $expat->setHandlers(
        Start => sub {
            my @new = $_[0]->new_ns_prefixes;
            is( scalar @new, 0, 'new_ns_prefixes returns empty without Namespaces' );

            my $uri = $_[0]->expand_ns_prefix('foo');
            is( $uri, undef, 'expand_ns_prefix returns undef without Namespaces' );

            my @cur = $_[0]->current_ns_prefixes;
            is( scalar @cur, 0, 'current_ns_prefixes returns empty without Namespaces' );
        },
    );
    $expat->parse('<root/>');
    $expat->release;
}

# ===== Parser.pm parsefile in list context =====

{
    my ( $fh, $filename ) = tempfile( SUFFIX => '.xml', UNLINK => 1 );
    print $fh '<root>content</root>';
    close $fh;

    my @tags;
    my $parser = XML::Parser->new(
        Handlers => {
            Start => sub { push @tags, $_[1] },
        },
    );

    # Call parsefile in list context
    my @result = $parser->parsefile($filename);

    ok( scalar @tags > 0, 'parsefile in list context calls handlers' );
    is( $tags[0], 'root', 'parsefile in list context: correct element' );
}

# ===== Parser.pm parsefile in scalar context =====

{
    my ( $fh, $filename ) = tempfile( SUFFIX => '.xml', UNLINK => 1 );
    print $fh '<root/>';
    close $fh;

    my $result = XML::Parser->new->parsefile($filename);
    ok( defined $result, 'parsefile returns defined value in scalar context' );
}

# ===== Objects style: adjacent text concatenation =====
# Line 37: when consecutive Char events fire, text is merged into one node

{
    # Use an entity to force multiple Char callbacks
    my $tree = XML::Parser->new( Style => 'Objects', Pkg => 'ConcatObj' )
        ->parse('<!DOCTYPE r [<!ENTITY x "world">]><r>hello &x;</r>');

    my @kids = @{ $tree->[0]{Kids} };
    # Should have merged into a single Characters node
    is( scalar @kids, 1, 'Objects: adjacent text nodes merged' );
    like( $kids[0]{Text}, qr/hello\s*world/, 'Objects: merged text content correct' );
}

# ===== Security API: error on undef argument =====

{
    my $p = XML::Parser::Expat->new;

    eval { $p->billion_laughs_attack_protection_maximum_amplification(undef) };
    like( $@, qr/Usage:/, 'BL max amplification croaks on undef' );

    eval { $p->billion_laughs_attack_protection_activation_threshold(undef) };
    like( $@, qr/Usage:/, 'BL activation threshold croaks on undef' );

    eval { $p->alloc_tracker_maximum_amplification(undef) };
    like( $@, qr/Usage:/, 'AllocTracker max amplification croaks on undef' );

    eval { $p->alloc_tracker_activation_threshold(undef) };
    like( $@, qr/Usage:/, 'AllocTracker activation threshold croaks on undef' );

    eval { $p->reparse_deferral_enabled(undef) };
    like( $@, qr/Usage:/, 'ReparseDeferral croaks on undef' );

    $p->release;
}

done_testing;
