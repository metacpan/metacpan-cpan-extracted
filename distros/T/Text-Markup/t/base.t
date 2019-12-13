#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::More tests => 38;
#use Test::More 'no_plan';
use File::Spec::Functions qw(catdir);
use HTML::Entities;

BEGIN { use_ok 'Text::Markup' or die; }

can_ok 'Text::Markup' => qw(
    register
    formats
    new
    parse
    default_format
    _get_parser
);

# Find core parsers.
my $dir = catdir qw(lib Text Markup);
opendir my $dh, $dir or die "Cannot open diretory $dir: $!\n";
my @core_parsers;
while (my $f = readdir $dh) {
    next if $f eq '.' || $f eq '..' || $f eq 'None.pm';
    $f =~ s{[.]pm$}{} or next;
    push @core_parsers => lc $f;
}

is_deeply [Text::Markup->formats], [sort @core_parsers],
    'Should have core formats';

ok my %matchers = Text::Markup->format_matchers,
    'Get format matchers';
is_deeply [sort keys %matchers], [sort @core_parsers],
    'Should have core format matchers';
isa_ok $_, 'Regexp', $_ for values %matchers;

# Register one.
PARSER: {
    package My::Cool::Parser;
    use Text::Markup;
    Text::Markup->register(cool => qr{cool});
    sub parser {
        return $_[2] ? $_[2]->[0] : 'hello';
    }
}

is_deeply [Text::Markup->formats], [sort @core_parsers, 'cool'],
    'Should be now have the "cool" parser';

my $parser = new_ok 'Text::Markup';
is $parser->default_format, undef, 'Should have no default format';

$parser = new_ok 'Text::Markup', [default_format => 'cool'];
is $parser->default_format, 'cool', 'Should have default format';

is $parser->_get_parser({ format => 'cool' }), My::Cool::Parser->can('parser'),
    'Should be able to find specific parser';

is $parser->_get_parser({ file => 'foo' }), My::Cool::Parser->can('parser'),
    'Should be able to find default format parser';

$parser->default_format(undef);
is $parser->_get_parser({ file => 'foo'}), Text::Markup::None->can('parser'),
    'Should be find the specified default parser';

# Now make it guess the format.
$parser->default_format(undef);
is $parser->_get_parser({ file => 'foo.cool'}),
    My::Cool::Parser->can('parser'),
    'Should be able to guess the parser file the file name';

# Now test guess_format.
is $parser->guess_format('foo.cool'), 'cool',
    'Should guess "cool" format file "foo.cool"';
is $parser->guess_format('foocool'), undef,
    'Should not guess "cool" format file "foocool"';
is $parser->guess_format('foo.cool.txt'), undef,
    'Should not guess "cool" format file "foo.cool.txt"';

# Add another parser.
PARSER: {
    package My::Funky::Parser;
    Text::Markup->register(funky => qr{funky(?:[.]txt)?});
    sub parser {
        # Must return a UTF-8 encoded string.
        use utf8;
        my $ret = 'fünky';
        utf8::encode($ret);
        return $ret;
    }
}

is_deeply [Text::Markup->formats], [sort @core_parsers, qw(cool funky)],
    'Should be now have the "cool" and "funky" parsers';
is $parser->guess_format('foo.cool'), 'cool',
    'Should still guess "cool" format file "foo.cool"';
is $parser->guess_format('foo.funky'), 'funky',
    'Should guess "funky" format file "foo.funky"';
is $parser->guess_format('foo.funky.txt'), 'funky',
    'Should guess "funky" format file "foo.funky.txt"';

# Now try parsing.
is $parser->parse(
    file   => 'README.md',
    format => 'cool',
), 'hello', 'Test the "cool" parser';

# Send output to a file.
is $parser->parse(
    file   => 'README.md',
    format => 'funky',
), 'fünky', 'Test the "funky" parser';

# Test opts to the parser.
is $parser->parse(
    file    => 'README.md',
    format  => 'cool',
    options => ['goodbye'],
), 'goodbye', 'Test the "cool" parser with options';

my $pod_dir = catdir (qw(t markups));

like $parser->parse(
        file => "$pod_dir/pod.txt",
        format => "pod",
        options => [
            html_header => '',
            ],
        ), qr|</html>|, 'Test pod option to suppress HTML header';

unlike $parser->parse(
        file => "$pod_dir/pod.txt",
        format => "pod",
        options => [
            html_header => '',
            html_footer => '',
            ],
        ), qr|</html>|, 'Test pod options to suppress HTML header and footer';

# Test the "none" parser.
my $output = do {
    my $f = __FILE__;
    open my $fh, '<:utf8', $f or die "Cannot open $f: $!\n";
    local $/;
    my $html = encode_entities(<$fh>, '<>&"');
    utf8::encode($html);
    qq{<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
</head>
<body>
<pre>$html</pre>
</body>
</html>
};
};
$parser->default_format(undef);
is $parser->parse(
    file => __FILE__,
), $output, 'Test the "none" parser';
