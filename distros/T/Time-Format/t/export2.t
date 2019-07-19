#!/perl -I..

use Test::More tests => 7;

BEGIN { $Time::Format::NOXS = 1 }
BEGIN { use_ok 'Time::Format', ':all' }

# hashes exported properly?
is ref tied %time,     Time::Format  => '%time exported by :all';
is ref tied %strftime, Time::Format  => '%strftime exported by :all';
is ref tied %manip,    Time::Format  => '%manip exported by :all';

# functions exported properly?
ok  defined &time_format              => 'time_format exported by :all';
ok  defined &time_strftime            => 'time_strftime exported by :all';
ok  defined &time_manip               => 'time_manip exported by :all';
