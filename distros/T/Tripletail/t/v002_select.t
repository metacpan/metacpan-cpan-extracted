#!/usr/local/ymir/perl/bin/perl
use Tripletail '/dev/null';
use Test::More tests => 1;

my $tmpl = $TL->newTemplate()->setTemplate(<<EOF);
<form>
<select name="s1">
<option value="1">1
</select>
<select name="s2">
<option value="2">2
</select>
</form>
EOF
$tmpl->setForm( $TL->newForm( s1=>1, s2=>2 ) );

my $str = $tmpl->toStr();
my @lines = $str=~/.*/g;
#diag($str);
is(scalar(grep{/selected/}@lines), 2, "`selected' appears twice for two select tags");

