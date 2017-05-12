#!/usr/bin/perl -Ilib -I../lib

use maybe 'Does::Not::Exist';

printf "Does::Not::Exist %s loaded\n", (Does::Not::Exist->VERSION ? 'is' : 'is not');

use maybe 'File::Spec';

printf "File::Spec %s loaded\n", (File::Spec->VERSION ? 'is' : 'is not');

use maybe 'Cwd' => 666;

printf "Cwd %s loaded\n", (Cwd->VERSION ? 'is' : 'is not');

use maybe 'Carp' => 'confess';
use constant HAS_CARP => !! Carp->VERSION;

printf "Carp %s loaded\n", (HAS_CARP ? 'is' : 'is not');
confess("ok");
