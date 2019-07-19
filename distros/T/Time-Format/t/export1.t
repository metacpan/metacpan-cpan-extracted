#!/perl -I..

use Test::More tests => 7;

BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format' }

# hashes exported properly?
is ref tied %time, Time::Format    => '%time exported by default';
is ref tied %strftime, ''          => '%strftime not exported by default';
is ref tied %manip,    ''          => '%manip not exported by default';
eval {%strftime = ()};   # suppress "used only once" warning
eval {%manip    = ()};   # suppress "used only once" warning

# functions exported properly?
ok  defined &time_format            => 'time_format exported by default';
ok !defined &time_strftime          => 'time_strftime not exported by default';
ok !defined &time_manip             => 'time_manip not exported by default';
