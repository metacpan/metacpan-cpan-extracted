use Test::More tests => 5;
use lib '.';

BEGIN { use_ok("t::ToolSet::Null"); }

# ToolSet API
can_ok( "ToolSet", "set_strict" );
can_ok( "ToolSet", "set_warnings" );
can_ok( "ToolSet", "export" );

# Available in subclass
can_ok( "t::ToolSet::Null", "import" );

