# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl VirtualFS-ISO9660.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1 	# use_ok()
												+ 1 # create object
												+ 1 # expect_ids
												+ 1 # expect_files
												+ 4 # copyright and biblio file checksum
												;

BEGIN { use_ok('VirtualFS::ISO9660') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# expect the following
%expect_ids = (
          'system' => 'VirtualFS',
          'volume' => 'VirtualFS Test ISO Image 1',
          'volume_set' => 'VirtualFS Test ISOs',
          'application' => 'VirtualFS::ISO9660',
          'publisher' => 'Lamers, Inc.',
          'preparer' => 'Stevie-O'
        	);

%expect_files = (
          'biblio' => 'heres/the/test/file/testfile.dat',
          'copyright' => 'COPYRIGH',
          'abstract' => ''
        	);

$copyright_checksum = 18845;
$biblio_checksum = 63908;

my $x = new VirtualFS::ISO9660 ('t/testfs.iso');
ok(defined $x, 'Create object for testfs.iso');

ok(eq_hash(\%expect_ids, +{ $x->identifier }), 'Parse volume descriptor identifiers');
ok(eq_hash(\%expect_files, +{ $x->id_file }),  'Parse volume descriptor filenames');

ok( $x->open(my $fh, '<', $x->id_file('copyright')), 'Open copyright file');
my $buf;
{ local $/; $buf = <$fh>; }
is(unpack('%n*', $buf), $copyright_checksum, 'Copyright file checksum');

ok( $x->open($fh, '<', $x->id_file('biblio')), 'Open bibliographic file');
{ local $/; $buf = <$fh>; }
is(unpack('%n*', $buf), $biblio_checksum, 'Bibliographic file checksum');
