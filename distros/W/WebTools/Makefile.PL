require 5.004;
use strict;
use Config;

my $path;

print '-' x 65, "\n";
print "WebTools installer...\n\n";
my @INPUT = @ARGV;
if($INPUT[0] =~ m/LIB=(.*)/si)
 {
  shift(@INPUT);
  $path = $1.join('',@INPUT);
 }
else
 {
  print "Please enter full path to place where you want WebTools to be installed!\n";
  print "NOTE: The module must be installed in your cgi-bin directory\n";
  print "(it is strongly recommended to enter your real\n\n";
  print "WEB_SERVER_ROOT/cgi-bin/webtools/ directory!\n \tor \n";
  print "~/YOUR_USER_NAME/cgi-bin/webtools/ directory!\n\n";
  print "Please specify directory: ";
  $path = <STDIN>;
  print "\n";
 }
  chomp($path);
  $path =~ s/\\/\//sg;
  if (!($path =~ m/\/$/))
   {
    $path .= '/';
   }
  if($path eq '') {print "\n Error: Empty directory name!\n"; exit;}

my %opts =
    ('NAME' => 'webtools',
     'VERSION_FROM' => 'lib/modules/webtools.pm',
     'dist'    => { 'SUFFIX' => '.gz',
		    'COMPRESS' => 'gzip -9f' },     
     );
$opts{'AUTHOR'} = 'Julian Lishev (julian@proscriptum.com)';

local $ARGV[0] = 'LIB='.$path;

require ExtUtils::MakeMaker;
ExtUtils::MakeMaker::WriteMakefile(%opts);
my $make = $^O =~ /Win/si ? 'nmake' : 'make';
print "\n\nDone...\n";
print "\nPlease run follow commands: \n";
print "$make\n";
print "$make install\n";
print "$make permissions\n";
print "$make clean\n";

package MY;
sub postamble 
{
 my $q1 = $^O =~ /Win/si ? '"' : "\'";
 my $q2 = $^O =~ /Win/si ? "\'" : '"';
 return << "EOF";
permissions :
	\@\$(PERL) -e $q1 chmod (0755,$q2\$(INSTALLPRIVLIB)process.cgi$q2,$q2\$(INSTALLPRIVLIB)install.cgi$q2); $q1
EOF
}
