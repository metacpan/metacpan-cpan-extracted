# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

    use Test::More qw(no_plan);
    BEGIN { use_ok( 'VMS::FindFile' ); }

#########################

my ($ff, $dir_fname, $ff_fname, $files);

$ff = VMS::FindFile->new("[]*.*;") || die
   "Couldn't create VMS::FindFile object\n";
    ok( defined $ff,            'new FindFile object OK' );

open IN, "directory/noheader/notrailer []*.*; |" || die "Couldn't open pipe\n";

$files = 0;

while (<IN>) {
    $dir_fname = $_;
    $files++;
    chomp $dir_fname;
    $ff_fname = $ff->search();
    is($ff_fname, $dir_fname, "filename compare for '$ff_fname'");
    if ($dir_fname ne $ff_fname) {
        BAIL_OUT("Directory and search filenames did not match");
    }
}
is($ff->search(), "", 'pull off result after EOF on directory');
close IN;

