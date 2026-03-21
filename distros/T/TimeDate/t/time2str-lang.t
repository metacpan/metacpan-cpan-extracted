use strict;
use warnings;
use Test::More tests => 8;
use Date::Format qw(time2str);

# Unix timestamp for Tue Sep 7 11:22:42 1999 GMT (used in format.t)
my $t = 936709362;

# Baseline: English (default)
is( time2str('%A', $t, 'GMT'),          'Tuesday',   'English day (no lang arg)'  );
is( time2str('%B', $t, 'GMT'),          'September', 'English month (no lang arg)');

# Explicit English via language argument
is( time2str('%A', $t, 'GMT', 'English'), 'Tuesday',   'English day (explicit)'  );
is( time2str('%B', $t, 'GMT', 'English'), 'September', 'English month (explicit)');

# German
is( time2str('%A', $t, 'GMT', 'German'), 'Dienstag', 'German day'  );
is( time2str('%B', $t, 'GMT', 'German'), 'September', 'German month');

# French
is( time2str('%A', $t, 'GMT', 'French'), 'mardi',     'French day'  );
is( time2str('%B', $t, 'GMT', 'French'), 'septembre', 'French month');
