#!perl -w
use strict;

use Text::ClearSilver;
use FindBin qw($Bin);

my $VarEscapeMode = shift(@ARGV) || 'html';

my $tcs = Text::ClearSilver->new(VarEscapeMode => $VarEscapeMode);

my %var = (lang => '<ClearSilver>');
$tcs->process("$Bin/hello.tcs", \%var);

