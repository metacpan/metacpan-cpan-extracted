use strict;
use Test::More tests => 1;
use Wiki::Toolkit;
use Wiki::Toolkit::TestConfig::Utilities;

# Reinitialise every configured storage backend.
Wiki::Toolkit::TestConfig::Utilities->reinitialise_stores;

pass( "Reinitialised stores" );
