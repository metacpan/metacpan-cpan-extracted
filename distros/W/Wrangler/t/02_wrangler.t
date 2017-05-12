#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 78;

use Wrangler;
use Wrangler::FileSystem::Linux;
use File::Temp ();

## prepare a test-dir
my $dir = File::Temp::tempdir( CLEANUP => 1 );
# print STDOUT "temp-dir: $dir\n";
for('text.txt','video.mp4','image.jpg'){
	open(my $FILE, '>', File::Spec->catfile($dir, $_) ) or die "Failed to open ". File::Spec->catfile($dir, $_) .": $!";
	print $FILE "foobar\n";
	close($FILE)
}


## low-level fs tests
{
	diag('Testing Wrangler::FileSystem::Linux');
	my ($ok,$ref);

	my $fsl = Wrangler::FileSystem::Linux->new();
	$ref = $fsl->list($dir);
	# use Data::Dumper;
	# print STDOUT Dumper($ref);
	is(ref($ref), 'ARRAY', 'low level list: returns an array-ref');
	is(@$ref, 5, 'low level list: test dir contains 5 items');


	$ref = $fsl->list($dir.'not-there');
	ok(ref($ref) eq 'error', 'low level list: returns non-ref/0 on error');
}


## higher-level fs tests
{
	diag('Testing Wrangler::FileSystem::Layers');
	my ($ok,$ref,%testhash);

	my $wrangler = Wrangler->new();
	isa_ok( $wrangler, 'Wrangler' );

	$ref = $wrangler->{fs}->richlist($dir.'not-there');
	is(ref($ref), 'error', 'richlist on non-existing returns array-ref blessed with error');


	($ref,my $path) = $wrangler->{fs}->richlist($dir);
	is(ref($ref), 'ARRAY', 'richlist returns array-ref on success');
	is($path, $dir, 'richlist returns $path in array-context');


	($ref) = $wrangler->{fs}->richlist($dir);
	# use Data::Dumper;
	# print STDOUT Dumper($ref);
	is(ref($ref), 'ARRAY', 'richlist returns array-ref in scalar context');
	is(@$ref, 5, 'richlist: test dir contains 5 items');


	%testhash = (
		'.'		=> 1,
		'..'		=> 1,
		'text.txt'	=> 1,
		'video.mp4'	=> 1,
		'image.jpg'	=> 1,
	);
	for(@$ref){
		delete($testhash{ $_->{'Filesystem::Filename'} });
	}
	is(keys %testhash, 0, 'test dir contains expected items');


	$ok = $wrangler->{fs}->rename(
		File::Spec->catfile($dir, 'video.mp4'),
		File::Spec->catfile($dir, 'renamedvideo.mp4'),
	);
	ok( $ok, 'rename() returns true'); # CORE:: returns true for success
	ok( -f File::Spec->catfile($dir, 'renamedvideo.mp4'), 'PerlIO test f: renamed file exists');
	ok(
		$wrangler->{fs}->test(
			'f',
			File::Spec->catfile($dir, 'renamedvideo.mp4')
		),
		"WranglerFS test f: renamed file exists"
	);


	$ok = $wrangler->{fs}->delete(  File::Spec->catfile($dir, 'renamedvideo.mp4')  );
	ok( $ok, 'delete() returns true'); # CORE:: returns cnt/values deleted
	ok( !-e File::Spec->catfile($dir, 'renamedvideo.mp4'), 'PerlIO test e: renamed file deleted');
	ok(
		!$wrangler->{fs}->test(
			'e',
			File::Spec->catfile($dir, 'renamedvideo.mp4')
		),
		"WranglerFS test e: renamed file deleted"
	);
	$ref = $wrangler->{fs}->richlist($dir);
	is(@$ref, 4, 'test dir contains 4 items, one less');


	$ok = $wrangler->{fs}->mkdir(  File::Spec->catfile($dir, 'subdir')  );
	ok( $ok, 'mkdir() returns true'); # CORE:: returns true on success
	ok( -d File::Spec->catfile($dir, 'subdir'), 'PerlIO test d: new subdir exists');
	ok(
		$wrangler->{fs}->test(
			'd',
			File::Spec->catfile($dir, 'subdir')
		),
		"WranglerFS test d: new subdir exists"
	);


	$ref = $wrangler->{fs}->richlist(  File::Spec->catfile($dir, 'subdir')  );
	is(@$ref, 2, 'test dir "subdir" contains 2 items');
	%testhash = (
		'.'		=> 1,
		'..'		=> 1,
	);
	for(@$ref){
		delete($testhash{ $_->{'Filesystem::Filename'} });
	}
	is(keys %testhash, 0, 'test dir "subdir" contains expected items');


	$ok = $wrangler->{fs}->rename(
		File::Spec->catfile($dir, 'text.txt'),
		File::Spec->catfile($dir, 'subdir', 'renamedtext.txt'),
	);
	ok( $ok, 'rename() returns true'); # CORE:: returns true for success
	ok( -f File::Spec->catfile($dir, 'subdir', 'renamedtext.txt'), 'PerlIO test f: renamed into subdir file exists');
	ok(
		$wrangler->{fs}->test(
			'f',
			File::Spec->catfile($dir, 'subdir', 'renamedtext.txt')
		),
		"WranglerFS test f: renamed into subdir file exists"
	);


	$ok = $wrangler->{fs}->rmdir(  File::Spec->catfile($dir, 'subdir') );
	ok( !$ok, 'rmdir() returns false on non-empty dir'); # CORE:: returns true for success, chokes on non-epty dirs
	  ok( -d File::Spec->catfile($dir, 'subdir'), 'PerlIO test d: just to be sure subdir is still there');
	  $ok = $wrangler->{fs}->delete(  File::Spec->catfile($dir, 'subdir', 'renamedtext.txt')  );
	  ok( $ok, 'delete() file in order to empty subdir');
	$ok = $wrangler->{fs}->rmdir(  File::Spec->catfile($dir, 'subdir')  );
	ok( $ok, 'rmdir() returns true on empty dir'); # CORE:: returns true for success, chokes on non-epty dirs
	ok( !-d File::Spec->catfile($dir, 'subdir'), 'PerlIO test d: subdir is gone');
	ok(
		!$wrangler->{fs}->test(
			'd',
			File::Spec->catfile($dir, 'subdir')
		),
		"WranglerFS test d: subdir is gone"
	);


	$ok = $wrangler->{fs}->mknod(
		File::Spec->catfile($dir, 'newfile'),
	);
	ok( $ok, 'mknod() returns true'); # based on CORE::open which returns true for success
	ok( -f File::Spec->catfile($dir, 'newfile'), 'PerlIO test f: new file exists');
	ok(
		$wrangler->{fs}->test(
			'f',
			File::Spec->catfile($dir, 'newfile')
		),
		"WranglerFS test f: new file exists"
	);


	## gvfs-trash changed behaviour somewehere between Ubuntu 12.x and 14.x, so that
	## it's not able to trash file outside of user's home anymore, so we don't test
	## in /tmp/ but in ~/
	require File::HomeDir;
	my $home_tmpdir = File::Spec->catfile(File::HomeDir->my_home, 'testing-wrangler-'.time());
	ok( $wrangler->{fs}->mkdir(  $home_tmpdir ), 'create a user temp dir');

	$ok = $wrangler->{fs}->mknod(
		File::Spec->catfile($home_tmpdir, 'new file with (uncommon chars ä % $ ! è)'),
	);
	ok( $ok, 'mknod() returns true'); # based on CORE::open which returns true for success
	ok( -f File::Spec->catfile($home_tmpdir, 'new file with (uncommon chars ä % $ ! è)'), 'PerlIO test f: new uncommon-chars file exists');
	ok(
		$wrangler->{fs}->test(
			'f',
			File::Spec->catfile($home_tmpdir, 'new file with (uncommon chars ä % $ ! è)')
		),
		"WranglerFS test f: new uncommon-chars exists"
	);

	$ok = $wrangler->{fs}->trash(
		File::Spec->catfile($home_tmpdir, 'new file with (uncommon chars ä % $ ! è)'),
	);
	ok( $ok, 'trash() returns true'); # based on CORE::open which returns true for success
	ok( !-e File::Spec->catfile($home_tmpdir, 'new file with (uncommon chars ä % $ ! è)'), 'PerlIO test f: trashed uncommon-chars file is gone');
	ok(
		!$wrangler->{fs}->test(
			'e',
			File::Spec->catfile($home_tmpdir, 'new file with (uncommon chars ä % $ ! è)')
		),
		"WranglerFS test f: trashed uncommon-chars file is gone"
	);

	SKIP: {
		skip("testing if file arrived in trash() is currently *nix only", 1) if $^O !~ /nix$|ux$/;

		my $trash_checked;
#		SKIP: {
#			eval { require File::Trash::FreeDesktop };
#
#			skip("File::Trash::FreeDesktop not installed", 1) if $@;
#
#			my $trash = File::Trash::FreeDesktop->new;
#
#			my %testhash;
#			for( $trash->list_contents() ){
#				$testhash{ $_->{entry} } = 1;
#			}
#
#			ok( $testhash{'new file with (uncommon chars ä % $ ! è)'}, 'trashed uncommon-chars file seems to have arrived in system trash');
#			$trash_checked = 1;
#		}

		unless($trash_checked){
			SKIP: {
				eval { require File::HomeDir };

				skip("File::HomeDir not installed", 1) if $@;

				ok( -f File::Spec->catfile(File::HomeDir->my_home, '.local/share/Trash/files/', 'new file with (uncommon chars ä % $ ! è)'), 'trashed uncommon-chars file seems to have arrived in system trash');
			}
		}
	}

	if(-d $home_tmpdir){
		# rmdir($home_tmpdir) or print STDOUT "unable to remove testing directory '$home_tmpdir': $!";
		ok( $wrangler->{fs}->rmdir( $home_tmpdir ),  "remove testing directory '$home_tmpdir'");
	}


	# copy a file
	$ok = $wrangler->{fs}->copy(
		File::Spec->catfile($dir, 'image.jpg'),
		File::Spec->catfile($dir, 'image ä copy.jpg'),
	);
	ok( $ok, 'copy() returns true'); # based on system + cp, returns true for success
	ok( -f File::Spec->catfile($dir, 'image ä copy.jpg'), 'PerlIO test f: file copy exists');
	ok(
		$wrangler->{fs}->test(
			'f',
			File::Spec->catfile($dir, 'image ä copy.jpg')
		),
		"WranglerFS test f: file copy exists"
	);


	# copy a directory (recursively)
	  $ok = $wrangler->{fs}->mkdir(  File::Spec->catfile($dir, 'another_subdir')  );
	  ok( $ok, 'mkdir() returns true'); # CORE:: returns true on success
	  ok( -d File::Spec->catfile($dir, 'another_subdir'), 'PerlIO test d: new subdir exists');
	  $ok = $wrangler->{fs}->rename(  File::Spec->catfile($dir, 'newfile') , File::Spec->catfile($dir, 'another_subdir', 'newfile')  );
	  ok( $ok, 'rename() returns true'); # CORE:: returns true on success
	  ok( -f File::Spec->catfile($dir, 'another_subdir', 'newfile'), 'PerlIO test f: renamed into subdir file exists');
	$ok = $wrangler->{fs}->copy(
		File::Spec->catfile($dir),
		File::Spec->catfile($dir .'_ä copy'),
	);
	ok( $ok, 'copy() returns true'); # based on system + cp, returns true for success
	ok( -d File::Spec->catfile($dir .'_ä copy'), 'PerlIO test f: dir copy exists');
	ok(
		$wrangler->{fs}->test(
			'd',
			File::Spec->catfile($dir .'_ä copy')
		),
		"WranglerFS test f: dir copy exists"
	);
	ok(
		   -d File::Spec->catfile($dir .'_ä copy', 'another_subdir')
		&& -f File::Spec->catfile($dir .'_ä copy', 'another_subdir', 'newfile')
		&& -f File::Spec->catfile($dir, 'image ä copy.jpg'), 'PerlIO multiple-tests: dir copy seems to contain all recursive items');


	## wishlist
	{
		require Test::Deep;
		Test::Deep->import();

		is( $wrangler->{fs}->can_mod('Filesystem::inode'), 0, 'can_mod(): inode reported immutable');
		is( $wrangler->{fs}->can_mod('Filesystem::nlink'), 0, 'can_mod(): nlink reported immutable');
		is( $wrangler->{fs}->can_mod('Filesystem::Type'), 0, 'can_mod(): Type reported immutable');
		is( $wrangler->{fs}->can_mod('Filesystem::Accessed'), 0, 'can_mod(): atime reported immutable');
		is( $wrangler->{fs}->can_mod('Filesystem::Filename'), 1, 'can_mod(): Filename reported modifiable');
		is( $wrangler->{fs}->can_mod('Filesystem::Modified'), 1, 'can_mod(): mtime reported modifiable');

		$ok = $wrangler->{fs}->set_property($dir.'/image.jpg', 'Extended Attributes::testkey', 'testvalue');
		# use File::ExtAttr ();
		# $ok = File::ExtAttr::setfattr($dir.'/image.jpg', 'testkey', 'testvalue', { namespace => 'user' });
		ok( $ok, 'set testing xattr');


		# no $wishlist -> get everything
		my $props = $wrangler->{fs}->richproperties($dir.'/image.jpg');
		cmp_deeply($props, {
			'Filesystem::inode' => re('\d+'),
			'Filesystem::uid' => 1000,
			'Filesystem::gid' => 1000,
			'Filesystem::nlink' => 1,
			'Filesystem::Hidden' => 0,
			'Filesystem::Type' => 'File',
			'Filesystem::rdef' => 0,
			'Filesystem::dev' => re('\d+'),
			'Filesystem::Blocks' => 8,
			'Filesystem::Size' => 7,
			'Filesystem::Modified' => re('\d{10}'),
			'Filesystem::Accessed' => re('\d{10}'),
			'Filesystem::Changed' => re('\d{10}'),
			'Filesystem::Blocksize' => 4096,
			'Filesystem::Suffix' => 'jpg',
			'Filesystem::Path' => re('\/image.jpg$'),
			'Filesystem::Filename' => 'image.jpg',
			'Filesystem::Basename' => 'image',
			'Filesystem::Directory' => re('^/tmp/'),
			'Filesystem::Xattr' => 1,
			'Filesystem::mode' => 33204,
			'MIME::Type' => 'image/jpeg',
			'MIME::mediaType' => 'image',
			'MIME::subType' => 'jpeg',
			'MIME::Description' => 'JPEG Image',
			'Extended Attributes::testkey' => 'testvalue',
		}, 'richproperties() returns expected metadata');


		$props = $wrangler->{fs}->richproperties($dir.'/image.jpg', ['Filesystem']);
		is( scalar(keys %$props), 20, 'richproperties() + $wishlist(Filesystem) returns expected metadata');

		$props = $wrangler->{fs}->richproperties($dir.'/image.jpg', ['MIME']);
		is( scalar(keys %$props), 24, 'richproperties() + $wishlist(MIME) returns expected metadata');

		$props = $wrangler->{fs}->richproperties($dir.'/image.jpg', ['Extended Attributes']);
		# is( scalar(keys %$props), 2, 'richproperties() + $wishlist(Extended Attributes) returns expected metadata');
		cmp_deeply($props, {
			'Extended Attributes::testkey' => 'testvalue',
			'Filesystem::Xattr' => 1	 # this Filesystem property comes for free, but should it?; MIME must be missing
		}, 'richproperties() + $wishlist(Extended Attributes) returns expected metadata');

		$props = $wrangler->{fs}->richproperties($dir.'/image.jpg', ['Filesystem','MIME']);
		is( scalar(keys %$props), 24, 'richproperties() + $wishlist(Filesystem,MIME) returns expected metadata');

		$props = $wrangler->{fs}->richproperties($dir.'/image.jpg', ['Filesystem','MIME','Extended Attributes']);
		is( scalar(keys %$props), 26, 'richproperties() + $wishlist(Filesystem,MIME,Extended Attributes) returns expected metadata');

		$props = $wrangler->{fs}->richproperties($dir.'/image.jpg', ['Extended Attributes::testkey']);
		# is( scalar(keys %$props), 1, 'richproperties() + $wishlist(Extended Attributes::testkey) returns expected metadata');
		cmp_deeply($props, {
			'Extended Attributes::testkey' => 'testvalue',
		}, 'richproperties() + $wishlist(Extended Attributes::testkey) returns expected metadata');

		$props = $wrangler->{fs}->richproperties($dir.'/image.jpg', ['Filesystem::Xattr']);
		is( scalar(keys %$props), 22, 'richproperties() + $wishlist(Filesystem::Xattr) returns expected metadata');
		# cmp_deeply($props, {
		#	'Extended Attributes::testkey' => 'testvalue',	 # this xattr property comes for free, but should it?; MIME must be missing
		#	'Filesystem::Xattr' => 1
		# }, 'richproperties() + $wishlist(Filesystem::Xattr) returns expected metadata');
		# use Data::Dumper;
		# print STDOUT Dumper($props);

		$props = $wrangler->{fs}->richproperties($dir.'/image.jpg', ['Filesystem::Modified']);
		is( scalar(keys %$props), 20, 'richproperties() + $wishlist(Filesystem::Modified) returns expected metadata');


		## available_properties()
		my $properties = $wrangler->{fs}->available_properties();
		is( scalar(@$properties), 25, 'available_properties() returns expected keys');

		$properties = $wrangler->{fs}->available_properties($dir);
		is( scalar(@$properties), 26, 'available_properties($dir) returns expected keys');


		## tests of richlist() -> list():
		my $richlist = $wrangler->{fs}->richlist($dir, ['Plain']);
		is( scalar(@$richlist), 5, 'richlist() returns expected items');
		my $cnt = 0;
		for(@$richlist){
			$cnt += scalar(keys %$_);
		}
		is( $cnt, 35, ' and each item seems to hold 7 key-value pairs');

		$richlist = $wrangler->{fs}->richlist($dir);
		is( scalar(@$richlist), 5, 'richlist() returns expected items');

		$richlist = $wrangler->{fs}->richlist($dir, []);
		$cnt = 0;
		for(@$richlist){
			$cnt += scalar(keys %$_);
		}
		is( $cnt, 126, 'richlist() corrects empty $wishlist ref');

		$richlist = $wrangler->{fs}->richlist($dir, ['Filesystem::Modified', 'Extended Attributes::testkey']);
		$cnt = 0;
		for(@$richlist){
			$cnt += scalar(keys %$_);
		}
		is( $cnt, 101, 'richlist(Filesystem::Modified, Extended Attributes::testkey) returns expected items');

		$richlist = $wrangler->{fs}->richlist($dir, ['Extended Attributes::testkey', 'Filesystem::Modified']);
		$cnt = 0;
		for(@$richlist){
			$cnt += scalar(keys %$_);
		}
		is( $cnt, 101, 'richlist(Extended Attributes::testkey, Filesystem::Modified) returns expected items (alt. ordering)'); #  # wishlist must not behave different on different ordering
		# use Data::Dumper;
		# print STDOUT Dumper($richlist);
	} # / $wishlist
}

