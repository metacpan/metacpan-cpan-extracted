use strict;
use warnings;
use Test::More;
use Test::PPPort;

use File::Spec;

chdir File::Spec->catfile(qw/ . t sandbox success /);

ppport_ok;

