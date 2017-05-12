use Test::More tests => 2;
use Test::Exception;
use Test::Directory;

my $dir = 'bad-dir';
my $obj = Test::Directory->new($dir);
rmdir($dir);
foreach my $method ( qw(count_unknown is_ok) ) {
  dies_ok { $obj->$method } "$method dies without directory";
};
