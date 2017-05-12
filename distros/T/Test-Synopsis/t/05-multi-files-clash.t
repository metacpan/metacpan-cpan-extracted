use Test::More tests => 2;
use Test::Synopsis;

# Test tests whether SYNOPSIS in separate files clashes
# See RT#76856

synopsis_ok("t/lib/Test03.pm", "t/lib/Test03Other.pm");
