use lib -e 't' ? 't' : 'test';
use TestML;
use TestMLBridge;

TestML->new(
    testml => 'testml/standard.tml',
    bridge => 'TestMLBridge',
)->run;
