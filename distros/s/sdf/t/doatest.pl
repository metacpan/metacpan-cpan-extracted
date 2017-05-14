print "1..2\n";
my $path = $0;
$path =~ m|([^/\\]+)\.t$|;
my $name = $1;
my $file = "$1.sdf";
$path =~ m|^(.*[/\\]+)|;
my $dir = $1;

## sdf below should at least output something like that:
##	 print "not" if -x "$name.log";
##	 print "ok 1\n";
##	 print "not" if -x "$name.out";
##	 print "ok 2\n";
## could not be done after the require because sdf calls
## exit;

chdir $dir;
@ARGV = ( '-2raw', '-.test=1', $name);
require '../../blib/script/sdf';

1;
