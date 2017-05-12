use strict;
use warnings;
use FindBin ();
use File::Spec;
use Test::More tests => 14;

# Load the module.
use_ok 'Test::Fixme';

{    # Check that listing a directory that does not exist dies.
    local $SIG{__WARN__} = sub { 1 };
    eval { my @files = Test::Fixme::list_files('t/i/do/not/exist'); };
    ok $@, 'list_files died';
    ok $@ =~ m:^'t/i/do/not/exist' does not exist:,
      "check that non-existent directory causes 'die'";
}

{    # Test that sub croaks unless a path is passed.
    local $SIG{__WARN__} = sub { 1 };
    eval { my @files = Test::Fixme::list_files(); };
    ok $@, 'list_files died';
    like $@,
qr{^You must specify a single directory, or reference to a list of directories},
      "check that no directory causes 'die'";
}

{    # Test the list_files function.
    my $dir    = 't/dirs/normal';
    my @files  = Test::Fixme::list_files($dir);
    my @wanted = sort map { "$dir/$_" } qw( one.txt two.pl three.pm four.pod );
    is_deeply( \@files, \@wanted, "check correct files returned from '$dir'" );
}

{    # Check that the search descends into sub folders.
    my $dir    = 't/dirs/deep';
    my @files  = Test::Fixme::list_files($dir);
    my @wanted = sort map { "$dir/$_" }
      map { "$_.txt" }
      qw'deep_a deep_b
      one/deep_one_a one/deep_one_b
      two/deep_two_a two/deep_two_b';
    is_deeply( \@files, \@wanted, "check correct files returned from '$dir'" );
}

{    # Check that we can scan a reference to a list of dirnames
    my @dirs  = qw( t/dirs/normal t/dirs/deep/one );
    my @files = Test::Fixme::list_files( \@dirs );
    my @wanted =
      sort qw(t/dirs/deep/one/deep_one_a.txt t/dirs/deep/one/deep_one_b.txt ),
      map { "t/dirs/normal/$_" } qw( one.txt two.pl three.pm four.pod );
    is_deeply( \@files, \@wanted,
        "check correct files returned from " . join( ', ', @dirs ) );
}

{    # Test the list_files function with a filename_match regex
    my $dir    = 't/dirs/normal';
    my @files  = Test::Fixme::list_files( $dir, qr/\.(?:pl|pm)$/ );
    my @wanted = sort map { "$dir/$_" } qw( two.pl three.pm );
    is_deeply( \@files, \@wanted, "check correct files returned from '$dir'" );
}

SKIP: {    # Check that non files do not get returned.
    skip( "MSYS2 does not support symlinks", 4 ) if $^O eq 'msys';
    skip( "cannot create symlink", 4 ) unless eval { symlink( "", "" ); 1 };

    my $dir         = "t/dirs/types";
    my $target      = "normal.txt";
    my $target_file = "$dir/$target";
    my $symlink     = "$dir/symlink";

    # Make a symbolic link
    ok symlink( $target, $symlink ), "create symlinked file";
    ok -e $symlink, "symlink now exists";

    my @files  = Test::Fixme::list_files($dir);
    my @wanted = ($target_file);

    is_deeply( \@files, \@wanted,
        "check that non files are not returned from '$dir'" );

    ok unlink($symlink), "delete symlinked file";
}

{   # Test that you can pass in just a file
    my @list = eval { Test::Fixme::list_files(File::Spec->catfile($FindBin::Bin, 'dirs', 'normal', 'three.pm')) };
    diag $@ if $@;
    like $list[0], qr{three.pm$}, "can give list_files directories or files";
}
