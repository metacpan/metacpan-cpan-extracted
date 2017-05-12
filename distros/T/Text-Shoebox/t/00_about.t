
require 5;
# Time-stamp: "2004-04-03 20:23:04 ADT"
use Test;
BEGIN { plan tests => 1; }
use Text::Shoebox;
use Text::Shoebox::Lexicon;
use Text::Shoebox::Entry;

print "#\n#\n",
 "# Text::Shoebox v$Text::Shoebox::VERSION\n",
 "# Text::Shoebox::Lexicon v$Text::Shoebox::Lexicon::VERSION\n",
 "# Text::Shoebox::Entry v$Text::Shoebox::Entry::VERSION\n",
 "#\n#\n",
;

print "# Running under perl version $] for $^O",
      (chr(65) eq 'A') ? "\n" : " in a non-ASCII world\n";

print "# Win32::BuildNumber ", &Win32::BuildNumber(), "\n"
 if defined(&Win32::BuildNumber) and defined &Win32::BuildNumber();

print "# MacPerl verison $MacPerl::Version\n"
 if defined $MacPerl::Version;

printf
 "# Current time local: %s\n# Current time GMT:   %s\n",
 scalar(   gmtime($^T)), scalar(localtime($^T));

print "# Using Test.pm v", $Test::VERSION || "?", "\n";

ok 1;


