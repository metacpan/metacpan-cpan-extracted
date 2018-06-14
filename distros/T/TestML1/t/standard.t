use lib -e 't' ? 't' : 'test';
use TestML1;
use TestML1Bridge;

TestML1->new(
    testml => 'testml/standard.tml',
    bridge => 'TestML1Bridge',
)->run;
