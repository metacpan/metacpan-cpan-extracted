#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Test::Settings qw(:all);

# Clean up our ENV first...
for my $k (qw(
	AUTOMATED_TESTING
	NONINTERACTIVE_TESTING
	EXTENDED_TESTING
	AUTHOR_TESTING
	RELEASE_TESTING
)) {
	delete $ENV{$k};
}

# Test getters
is(want_smoke(), undef, 'We do not want smoke testing');
is(want_non_interactive(), undef, 'We do not want non-interactive testing');
is(want_extended(), undef, 'We do not want extended testing');
is(want_author(), undef, 'We do not want author tests');
is(want_release(), undef, 'We do not want release tests');
is(want_all(), undef, 'We do not want all tests');

# Test enablers
enable_smoke();
is(want_smoke(), 1, 'We want smoke testing now');

enable_non_interactive();
is(want_non_interactive(), 1, 'We want non-interactive testing now');

enable_extended();
is(want_extended(), 1, 'We want extended testing now');

enable_author();
is(want_author(), 1, 'We want author testing now');

is(want_all(), undef, 'We do not want all tests');

enable_release();
is(want_release(), 1, 'We want release testing now');

is(want_all(), 1, 'We now want all tests');

# Test output
is(current_settings, <<EOF, "current_settings is correct");
want_smoke:           1
want_non_interactive: 1
want_extended:        1
want_author:          1
want_release:         1
EOF

is(current_settings_env, <<EOF, "current_settings_env is correct");
AUTHOR_TESTING=1
EXTENDED_TESTING=1
NONINTERACTIVE_TESTING=1
RELEASE_TESTING=1
AUTOMATED_TESTING=1
EOF

is(current_settings_env_all, <<EOF, "current_settings_env is correct");
AUTHOR_TESTING=1
EXTENDED_TESTING=1
NONINTERACTIVE_TESTING=1
RELEASE_TESTING=1
AUTOMATED_TESTING=1
EOF

# Test disablers
disable_smoke();
is(want_smoke(), undef, 'We do not want smoke testing now');

disable_non_interactive();
is(want_non_interactive(), undef, 'We do not want non-interactive testing now');

disable_extended();
is(want_extended(), undef, 'We do not want extended testing now');

disable_author();
is(want_author(), undef, 'We do not want author testing now');

disable_release();
is(want_release(), undef, 'We do not want release testing now');

is(want_all(), undef, 'We do not want all tests');

# Test output
is(current_settings, <<EOF, "current_settings is correct");
want_smoke:           
want_non_interactive: 
want_extended:        
want_author:          
want_release:         
EOF

is(current_settings_env, '', "current_settings_env is correct");

is(current_settings_env_all, <<EOF, "current_settings_env_all is correct");
AUTHOR_TESTING=0
EXTENDED_TESTING=0
NONINTERACTIVE_TESTING=0
RELEASE_TESTING=0
AUTOMATED_TESTING=0
EOF

# Enable/disable all
enable_all();

is(want_all(), 1, 'We want all tests');

disable_all();

is(want_all(), undef, 'We do not want all tests');

is(want_smoke(), undef, 'We do not want smoke testing now');
is(want_non_interactive(), undef, 'We do not want non-interactive testing now');
is(want_extended(), undef, 'We do not want extended testing now');
is(want_author(), undef, 'We do not want author testing now');
is(want_release(), undef, 'We do not want release testing now');

done_testing;
