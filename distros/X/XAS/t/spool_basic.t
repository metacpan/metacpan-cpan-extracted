use strict;
use lib '../lib';

use Test::More;
use Badger::Filesystem 'Dir cwd';
use Data::Dumper;

my $spooldir = Dir(cwd, 'spool');

unless ( $ENV{RELEASE_TESTING} ) {

    plan skip_all => "Author tests not required for installation" ;

} else {

    plan tests => 21 ;
    use_ok("XAS::Lib::Modules::Spool");

    unless ( -e $spooldir->path) {
        mkdir($spooldir->path);
    }

}

my $data = 'this is data';
my $spl = XAS::Lib::Modules::Spool->new(
    -directory => $spooldir,
    -lock      => Dir($spooldir, 'spool')->path,
);
isa_ok($spl, "XAS::Lib::Modules::Spool");

ok($spl->write($data));
ok($spl->write($data));
ok($spl->write($data));
ok($spl->write($data));

my $packet;
my @files = $spl->scan();
my $count = $spl->count();
is(scalar(@files), $count);

foreach my $file (@files) {

    ok($packet = $spl->read($file));
    is($packet, $data);
    ok($spl->delete($file));

}

ok(unlink('spool/.SEQ'));
ok(rmdir('spool'));

