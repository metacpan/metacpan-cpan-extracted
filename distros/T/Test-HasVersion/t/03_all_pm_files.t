#!/usr/bin/perl

use Test::More tests => 7;

require_ok('Test::HasVersion');

# alias to have a short name
*all_pm_files = \&Test::HasVersion::all_pm_files;

# and here we test &all_pm_files

{
    my @pm_files = all_pm_files();
    is_deeply( \@pm_files, [qw(HasVersion.pm)] );
}

{
    ok( chdir "t/eg", "cd t/eg" );
    my @pm_files = all_pm_files();
    is_deeply( \@pm_files, [qw(A.pm lib/B.pm lib/B/C.pm)] );  # *.pm lib/**/*.pm
    ok( chdir "../..", "cd ../.." );
}

{
    my @pm_files = all_pm_files("t/eg");
    is_deeply( \@pm_files,
        [qw(t/eg/A.pm t/eg/inc/Foo.pm t/eg/lib/B.pm t/eg/lib/B/C.pm )] )
      ;    # every .pm under t/eg
}

{
    my @pm_files = all_pm_files( "t/eg/A.pm", "t/eg/MANIFEST" );
    is_deeply( \@pm_files, [qw(t/eg/A.pm t/eg/MANIFEST)] );
}
