use strict;
use lib -e 't' ? 't' : 'test';
use TestML1;
use TestML1Bridge;

TestML1->new(
    testml => 'testml/edge-cases.tml',
    bridge => 'TestML1Bridge',
)->run;
