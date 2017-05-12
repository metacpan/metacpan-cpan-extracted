#!/usr/bin/perl -w

use strict;
use Text::TemplateLite;
use Text::TemplateLite::Standard;

my $tpl = Text::TemplateLite->new;

Text::TemplateLite::Standard::register($tpl, qw/:numeric :template/);

# °F = 9/5 °C + 32
$tpl->set(q{<<tpl('c_to_f',+(/(*($1,9),5),32)' °F')
  'Under normal conditions, water freezes at '$c_to_f(0)
  ' and boils at '$c_to_f(100)'.'>>});
print $tpl->render->result, "\n";
