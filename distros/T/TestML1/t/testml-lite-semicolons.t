use strict;
use lib -e 't' ? 't' : 'test';
use TestML1;
use TestML1::Compiler::Lite;
use TestML1Bridge;

TestML1->new(
    testml => 'testml/semicolons.tml',
    bridge => 'TestML1Bridge',
    compiler => 'TestML1::Compiler::Lite',
)->run;
