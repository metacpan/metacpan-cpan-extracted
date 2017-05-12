
# This -*-perl-*- file is run as part of "make test".
# See "perldoc Test" (or the appropriate Test::* module) for details.
#
BEGIN { print "# Perl version $] under $^O\n" }
BEGIN { require Win32::Autoglob } 
print 	'',
  "# Win32::Autoglob version $Win32::Autoglob::VERSION\n",
  "# Time now: " . scalar(gmtime), " GMT\n",
  "# I'm ", ((chr(65) eq 'A') ? '' : 'not '), "in an ASCII world.\n",
  "#------------------------\n",
;

use Test;
BEGIN { plan tests => 1 }
require Win32::Autoglob;
ok(1);
print "# No real tests to run.
";
# See "perldoc makepmdist" for info on inserting
#  "=for makepmdist-tests" blocks into your module.



