#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockFile qw< nostrict >;

note "-------------- Two read handles to the same file (#27) --------------";
{
    my $mock = Test::MockFile->file( '/fake/multi', "line1\nline2\nline3\n" );

    ok( open( my $fh1, '<', '/fake/multi' ), "open first read handle" );
    ok( open( my $fh2, '<', '/fake/multi' ), "open second read handle" );

    is( <$fh1>, "line1\n", "fh1 reads line 1" );
    is( <$fh1>, "line2\n", "fh1 reads line 2" );

    # fh2 should start at position 0, independent of fh1
    is( <$fh2>, "line1\n", "fh2 reads line 1 independently" );

    is( <$fh1>, "line3\n", "fh1 reads line 3" );
    is( <$fh2>, "line2\n", "fh2 reads line 2 independently" );

    close $fh1;

    # fh2 should still work after fh1 is closed
    is( <$fh2>, "line3\n", "fh2 reads line 3 after fh1 is closed" );
    ok( eof($fh2), "fh2 is at EOF" );

    close $fh2;
}

note "-------------- Read + write handles to the same file (#27) --------------";
{
    my $mock = Test::MockFile->file( '/fake/rw', "original\n" );

    ok( open( my $fhr, '<', '/fake/rw' ),  "open read handle" );
    ok( open( my $fhw, '>>', '/fake/rw' ), "open append handle" );

    is( <$fhr>, "original\n", "read handle sees original content" );

    print {$fhw} "appended\n";

    # Read handle should now see the appended content (shared contents)
    is( <$fhr>, "appended\n", "read handle sees appended content" );

    close $fhw;
    close $fhr;

    is( $mock->contents(), "original\nappended\n", "file contents after both handles closed" );
}

note "-------------- fhs tracking cleanup (#27) --------------";
{
    my $mock = Test::MockFile->file( '/fake/track', "data\n" );
    my $path = '/fake/track';

    # Before any open, fhs should be empty or nonexistent
    ok(
        !$Test::MockFile::files_being_mocked{$path}->{'fhs'}
          || !grep { defined $_ } @{ $Test::MockFile::files_being_mocked{$path}->{'fhs'} },
        "no open handles before open"
    );

    open( my $fh1, '<', $path ) or die $!;
    my $fhs = $Test::MockFile::files_being_mocked{$path}->{'fhs'};
    is( scalar( grep { defined $_ } @{$fhs} ), 1, "one handle tracked after first open" );

    open( my $fh2, '<', $path ) or die $!;
    $fhs = $Test::MockFile::files_being_mocked{$path}->{'fhs'};
    is( scalar( grep { defined $_ } @{$fhs} ), 2, "two handles tracked after second open" );

    close $fh1;
    $fhs = $Test::MockFile::files_being_mocked{$path}->{'fhs'};
    is( scalar( grep { defined $_ } @{$fhs} ), 1, "one handle tracked after closing first" );

    close $fh2;
    $fhs = $Test::MockFile::files_being_mocked{$path}->{'fhs'};
    is( scalar( grep { defined $_ } @{$fhs} ), 0, "zero handles tracked after closing both" );
}

note "-------------- Sysopen multiple handles (#27) --------------";
{
    use Fcntl;

    my $mock = Test::MockFile->file( '/fake/sysopen', "sysdata\n" );

    ok( sysopen( my $fh1, '/fake/sysopen', O_RDONLY ), "sysopen first handle" );
    ok( sysopen( my $fh2, '/fake/sysopen', O_RDONLY ), "sysopen second handle" );

    my $buf1;
    my $buf2;
    sysread( $fh1, $buf1, 4 );
    sysread( $fh2, $buf2, 4 );

    is( $buf1, "sysd", "sysread from first handle" );
    is( $buf2, "sysd", "sysread from second handle (independent position)" );

    close $fh1;
    close $fh2;
}

done_testing();
