package main;
use strict;
use warnings;

use Test::More 0.98;
use Scalar::Util qw(weaken);

use XML::Hash::XS qw(hash2xml);

my %data = (
    alpha => 'one',
    beta  => [ map { "value-$_" } 1 .. 20 ],
);

my $expected = hash2xml(\%data, canonical => 1, buf_size => 32);

{
    my @chunks;
    my @argc;
    my $result = hash2xml(
        \%data,
        canonical => 1,
        buf_size => 32,
        output_cb => sub {
            push @argc, scalar @_;
            push @chunks, $_[0];
        },
    );

    is($result, undef, 'callback output returns undef');
    cmp_ok(scalar @chunks, '>', 1, 'small buffer produces multiple chunks');
    is(join('', @chunks), $expected, 'chunks contain the complete XML document');
    is_deeply(\@argc, [ (1) x @argc ], 'callback receives exactly one argument');
}

{
    my @weak_chunks;
    hash2xml(
        \%data,
        canonical => 1,
        buf_size => 8,
        output_cb => sub {
            push @weak_chunks, \$_[0];
            weaken($weak_chunks[-1]);
        },
    );

    ok(!grep(defined, @weak_chunks), 'unretained callback chunks are released immediately');
}

{
    my @chunks;
    hash2xml(
        { value => 'abcdef' },
        xml_decl => 0,
        buf_size => 4,
        output_cb => sub {
            push @chunks, $_[0];
            $_[0] = 'changed';
        },
    );

    isnt(join('', @chunks), 'changed', 'callback receives stable independent chunks');
    is(join('', @chunks), '<root><value>abcdef</value></root>', 'mutating callback argument does not alter output');
}

{
    my @chunks;
    my $converter;
    my $weak;
    {
        my $callback = sub { push @chunks, $_[0] };
        $weak = $callback;
        weaken($weak);
        $converter = XML::Hash::XS->new(
            xml_decl => 0,
            output_cb => $callback,
        );
    }

    ok(defined $weak, 'object retains output callback');
    is($converter->hash2xml({ item => 'value' }), undef, 'OOP callback output returns undef');
    is(join('', @chunks), '<root><item>value</item></root>', 'OOP callback receives XML');
    undef $converter;
    ok(!defined $weak, 'object releases output callback');
}

{
    my $calls = 0;
    my $error;
    eval {
        hash2xml(
            \%data,
            canonical => 1,
            buf_size => 8,
            output_cb => sub {
                ++$calls;
                die "output callback failed\n";
            },
        );
    };
    $error = $@;

    like($error, qr/^output callback failed/, 'callback exception is propagated');
    is($calls, 1, 'failing callback is not called again during cleanup');
}

{
    my $error;
    eval { hash2xml({}, output_cb => 'not a callback') };
    $error = $@;
    like($error, qr/Parameter 'output_cb' is not CODE reference/, 'output_cb must be a code reference');
}

{
    open(my $fh, '>', \my $output) or die "Can't open scalar filehandle: $!";
    my $error;
    eval { hash2xml({}, output => $fh, output_cb => sub {}) };
    $error = $@;
    like($error, qr/mutually exclusive/, 'output and output_cb cannot be combined');
}

{
    my @utf8_chunks;
    hash2xml(
        { text => "\x{410}\x{411}" },
        xml_decl => 0,
        utf8 => 1,
        buf_size => 4,
        output_cb => sub { push @utf8_chunks, $_[0] },
    );
    ok(!grep(!utf8::is_utf8($_), @utf8_chunks), 'callback chunks carry the UTF-8 flag');

    my @byte_chunks;
    hash2xml(
        { text => "\x{410}\x{411}" },
        xml_decl => 0,
        utf8 => 0,
        buf_size => 4,
        output_cb => sub { push @byte_chunks, $_[0] },
    );
    ok(!grep(utf8::is_utf8($_), @byte_chunks), 'utf8 => 0 returns byte chunks');
}

SKIP: {
    my $encoded = eval {
        hash2xml(
            { text => "\x{410}\x{411}" },
            canonical => 1,
            encoding => 'cp1251',
            utf8 => 0,
            buf_size => 4096,
        );
    };
    skip 'external encoding support is not available', 3 if $@;

    my @chunks;
    hash2xml(
        { text => "\x{410}\x{411}" },
        canonical => 1,
        encoding => 'cp1251',
        utf8 => 0,
        buf_size => 4,
        output_cb => sub { push @chunks, $_[0] },
    );
    is(join('', @chunks), $encoded, 'callback receives externally encoded chunks');

    my $calls = 0;
    my $error;
    eval {
        hash2xml(
            \%data,
            canonical => 1,
            encoding => 'cp1251',
            utf8 => 0,
            buf_size => 4,
            output_cb => sub {
                ++$calls;
                die "encoded callback failed\n";
            },
        );
    };
    $error = $@;
    like($error, qr/^encoded callback failed/, 'encoded callback exception is propagated');
    is($calls, 1, 'failing encoded callback is not retried during cleanup');
}

{
    my @chunks;
    local $XML::Hash::XS::output_cb = sub { push @chunks, $_[0] };
    my $result = hash2xml({ item => 'global' }, xml_decl => 0);

    is($result, undef, 'global output_cb returns undef');
    is(join('', @chunks), '<root><item>global</item></root>', 'global output_cb receives XML');
}

done_testing;
