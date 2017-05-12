use strict;
use warnings;

use inc::Module::Install;

name 'WebService-Pushwoosh';

all_from 'lib/WebService/Pushwoosh.pm';

requires 'Furl' => 1.00;
requires 'Try::Tiny' => 0.12;
requires 'JSON' => 2.53;
requires 'Params::Validate' => 1.07;

test_requires 'Test::More' => 0.98;
test_requires 'Test::Exception' => 0.31;

tests 't/*.t';

repository 'http://github.com/mcartmell/WebService-Pushwoosh';
bugtracker 'http://github.com/mcartmell/WebService-Pushwoosh/issues';

WriteAll;
