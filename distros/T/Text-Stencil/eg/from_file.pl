#!/usr/bin/env perl
use v5.20;
use File::Temp 'tempfile';
use Text::Stencil;

# create a template file with section markers
my ($fh, $fname) = tempfile(SUFFIX => '.tpl', UNLINK => 1);
print $fh <<'TPL';
__HEADER__
<ul>
__ROW__
  <li>{name:html} ({score:int})</li>
__FOOTER__
</ul>
TPL
close $fh;

my $s = Text::Stencil->from_file($fname);

say $s->render([
    { name => 'Alice & Bob', score => 95 },
    { name => '<Eve>',       score => 87 },
]);
