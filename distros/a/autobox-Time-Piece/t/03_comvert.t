use Time::Piece;
use File::stat;
use Test::More;
use autobox::Time::Piece;
use strict;

# use_ok("autobox::Time::Piece");

my $localtime = localtime();
my $mtime = stat(__FILE__)->mtime;

ok($mtime->strptime->strftime("%Y-%m-%d %H:%M:%S"), localtime($mtime)->strftime("%Y-%m-%d %H:%M:%S"));
ok($localtime->strftime("%Y-%m-%d")->convert("%Y-%m-%d", "%A %e %B"), $localtime->strftime("%A %e %B"));

done_testing()
