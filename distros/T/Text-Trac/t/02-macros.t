use strict;
use warnings;
use t::TestTextTrac;

run_tests;

__DATA__

### macro with no arguments
--- input
[[HelloWorld]]
--- expected
<p>
Hello World, args = 
</p>

### macro with quoted arguments
--- input
[[HelloWorld( "one, one", "two, two", 'three, three' )]]
--- expected
<p>
Hello World, args = one, one, two, two, three, three
</p>

### macro with embedded terminators
--- input
[[HelloWorld( func(arg), ]] )]]
--- expected
<p>
Hello World, args = func(arg), ]]
</p>

### macros with extra ws aren't valid
--- input
[[ HelloWorld(foo) ]]
--- expected
<p>
[[ HelloWorld(foo) ]]
</p>

### unknown macro doesn't die
--- input
[[TheUnknownMacro]]
--- expected
<p>
[[TheUnknownMacro]]
</p>
