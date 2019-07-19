#!/perl -I..

use Test::More tests => 7;

BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', qw(%manip time_format time_manip) }

# hashes exported properly?
is ref tied %time,     ''            => '%time not xported when it should not be';
is ref tied %strftime, ''            => '%strftime not exported when it should not be';
is ref tied %manip,    Time::Format  => '%manip exported when explicitly requested';
eval {%time     = ()};   # suppress "used only once" warning
eval {%strftime = ()};   # suppress "used only once" warning

# functions exported properly?
ok  defined &time_format              => 'time_format exported when explicitly requested';
ok !defined &time_strftime            => 'time_strftime not exported when not requested';
ok  defined &time_manip               => 'time_manip exported when explicitly requested';
