#!/usr/bin/perl
#
# $Id: benchmark.pl,v 1.2 1999/10/24 13:31:55 tai Exp $
#
# Simple script to compare speed of Text::Template and this module.
#

use Benchmark;
use Text::Template;
use Text::SimpleTemplate;

$text = <<'EOF';
name: { $name }
type: { $type }
EOF

$text = $text x 1024;
$name = 'foobar';
$type = 'string';

timethese(10, {
    'Builtin::Eval'        => \&func_00,
    'Text::SimpleTemplate' => \&func_01,
    'Text::Template'       => \&func_02,
});

exit(0);

sub func_00 {
    $tmpl = $text;
    $tmpl =~ s/{(.*?)}/eval($1)/ge;
}

sub func_01 {
    $tmpl = new Text::SimpleTemplate;
    $tmpl->pack($text, LR_CHAR => [qw({ })])->fill;
}

sub func_02 {
    $tmpl = new Text::Template(TYPE => 'STRING', SOURCE => $text);
    $tmpl->fill_in(DELIMITERS => [qw({ })]);
}
