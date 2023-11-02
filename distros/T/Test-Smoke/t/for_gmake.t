#! perl -w
use strict;

use File::Spec;
use File::Temp 'tempdir';
use File::Copy 'copy';

use Test::More tests => 77;
BEGIN { use_ok( 'Test::Smoke::Util' ); }

my $tmpdir = tempdir(CLEANUP => ($ENV{SMOKE_DEBUG} ? 0 : 1));
mkdir File::Spec->catdir($tmpdir, 'win32');
{ # cp -r t/win32/ $tmpdir
    my $source_dir = File::Spec->catdir('t', 'win32');
    local *SRCDIR;
    opendir SRCDIR, $source_dir or die "Cannot open '$source_dir': $!";
    while (my $entry = readdir(SRCDIR)) {
        my $full_name = File::Spec->catfile($source_dir, $entry);
        next unless -f $full_name;
        copy($full_name, File::Spec->catdir($tmpdir, 'win32'));
    }
    close SRCDIR;
}

chdir $tmpdir or die "chdir: $!";
my $smoke_mk = 'win32/smoke.mk';

# Force the options that have a different default in
# the makefile.mk and in Configure_win32()
my $dft_args =  '-Duseithreads -Duselargefiles';
my $config   = $dft_args .
               ' -DINST_VER=\5.9.0 -DINST_ARCH=\$(ARCHNAME)';
Configure_win32( './Configure ' . $config, 'gmake' );

ok( -f $smoke_mk, "New makefile ($config)" );
ok( my_unlink( $smoke_mk ), "Remove makefile" );

$config =  '-DINST_DRV=F:';
Configure_win32( './Configure ' . $config, 'gmake' );
ok( -f $smoke_mk, "New makefile ($config)" );

SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 7 if !defined($makefile);

    # This should be set
    like( $makefile, '/^INST_DRV\s*:=\s*F:\n/m', '$(INST_DRV)' );
    like( $makefile, '/^INST_DRV\t= untuched\n/m', "Untuched 1" );
    like( $makefile, '/^# INST_DRV\t= untuched\n/m', "Untuched 2" );

    # These should be set as -Duseithreads is default T::S>=1.79_05
    like($makefile, qr/^USE_MULTI\s*:= define/m,    '#$(USE_MULTI)');
    like($makefile, qr/^USE_ITHREADS\s*:= define/m, '#$(USE_ITHREADS)');
    like($makefile, qr/^USE_IMP_SYS\s*:= define/m,  '#$(USE_IMP_SYS)');

    # These should be unset
    like($makefile, qr/^#USE_LARGE_FILES\s*:= define/m, '#$(USE_LARGE_FILES)');

}

# Here we test the setting of CCTYPE
ok( my_unlink( $smoke_mk ), "Remove makefile" );

$config = '-DCCTYPE=MSVC60';
Configure_win32( './Configure ' . $config, 'gmake' );
ok( -f $smoke_mk, "New makefile ($config)" );

SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 5 if !defined($makefile);

    # This should now be set twice
    like( $makefile, '/^CCTYPE\s*:= MSVC60\nCCTYPE\s*:= MSVC60\n/m',
          '$(CCTYPE) set twice' );
    like( $makefile, '/^\s*CCTYPE=\$\(CCTYPE\) > somewhere\n/m',
          "Untuched CCTYPE" );

    #These should be unset
    like( $makefile, '/^USE_MULTI\s*:= define\n/m', '#$(USE_MULTI)' );
    like( $makefile, '/^USE_ITHREADS\s*:= define\n/m', '#$(USE_ITHREADS)' );
    like( $makefile, '/^USE_IMP_SYS\s*:= define\n/m', '#$(USE_IMP_SYS)' );
    like( $makefile, '/^#BUILD_STATIC\s*:= define\n/m', '#$(BUILD_STATIC)' );
}

# Check that all three are set for -Duseithreads
ok( my_unlink( $smoke_mk ), "Remove makefile" );

$config = '-Uusethreads';
Configure_win32( './Configure ' . $config, 'gmake' );
ok( -f $smoke_mk, "New makefile ($config)" );

SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 3 if !defined($makefile);

    #These should be set
    like( $makefile, '/^#USE_MULTI\s*:= define\n/m', '$(USE_MULTI) set' );
    like( $makefile, '/^#USE_ITHREADS\s*:= define\n/m', '$(USE_ITHREADS) set' );
    like( $makefile, '/^#USE_IMP_SYS\s*:= define\n/m', '$(USE_IMP_SYS) set' );
}

# This will be a full configuration:
ok( my_unlink( $smoke_mk ), "Remove makefile" );

$config = '-Duselargefiles';
Configure_win32( './Configure ' . $config, 'gmake' );
ok( -f $smoke_mk, "New makefile ($config)" );

SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 1 if !defined($makefile);

    #These should be set
    like(
        $makefile,
        qr/^USE_LARGE_FILES\s*:= define/m,
        '$(USE_LARGE_FILES) set'
    );
}

# This will be a full configuration:
ok( my_unlink( $smoke_mk ), "Remove makefile" );

$config = '-des -Dusedevel -Duseithreads -Dusemymalloc ' .
          '-DCCTYPE=MSVC60 -Dcf_email=abeltje@cpan.org';
Configure_win32( './Configure ' . $config, 'gmake' );
ok( -f $smoke_mk, "New makefile ($config)" );

SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 7 if !defined($makefile);

    #These should be set
    like( $makefile, '/^USE_MULTI\s*:= define\n/m', '$(USE_MULTI) set' );
    like( $makefile, '/^USE_ITHREADS\s*:= define\n/m', '$(USE_ITHREADS) set' );
    like( $makefile, '/^USE_IMP_SYS\s*:= define\n/m', '$(USE_IMP_SYS) set' );
    like( $makefile, '/^\s*PERL_MALLOC\s*:= define\n/m', '$(PERL_MALLOC) set' );
    like( $makefile, '/^EMAIL\s*:= abeltje\@cpan\.org\n/m', '$(EMAIL) set' );

    # This should now be set twice
    like(
        $makefile,
        '/^CCTYPE\s*:= MSVC60\nCCTYPE\s*:= MSVC60\n/m',
        '$(CCTYPE) set twice'
    );
    like($makefile, '/^\s*CCTYPE=\$\(CCTYPE\) > somewhere\n/m',     "Untuched CCTYPE");
}

ok( my_unlink( $smoke_mk ), "Remove makefile" );

$config = '-des -Dusedevel';
my @cfg_args = ( 'osvers=5.0 W2000Pro' );

Configure_win32( './Configure ' . $config, 'gmake', @cfg_args );
ok( -f $smoke_mk, "New makefile ($config/[@cfg_args])" );

SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 1 if !defined($makefile);

    like( $makefile, '/
          ^CFG_VARS \s* = \s* \\\\\n
           \s*"osvers=5\.0\ W2000Pro"\t+\\\\\n
           \s*"config_args=-Dusedevel"\t+\\\\\n
           \s*"INST_DRV=
    /mx', "CFG_VARS macro for Config.pm" );
}

ok( my_unlink( $smoke_mk ), "Remove makefile" );

$config = '-des -Dusedevel';
@cfg_args = ( 'osvers=5.0 W2000Pro', "", 'ccversion=cl 6.0' );

Configure_win32( './Configure ' . $config, 'gmake', @cfg_args );
ok( -f $smoke_mk, "New makefile ($config/[@cfg_args])" );

SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 1 if !defined($makefile);

    like( $makefile, qr/
          ^CFG_VARS \s* = \s* \\ \n
           \s*\Q"osvers=5.0 W2000Pro"\E \s+ \\ \n
           \s*\Q"ccversion=cl 6.0"\E \s+ \\ \n
           \s*\Q"config_args=-Dusedevel"\E \s+ \\ \n
           \s*\Q"INST_DRV=\E
    /mx, "CFG_VARS macro for Config.pm" );
}

ok( my_unlink( $smoke_mk ), "Remove makefile" );

$config = '-des -Dusedevel';
@cfg_args = (
    'osvers=Win10 Build 19044 (64-bit)',
    "trash",
    'ccversion=86_64-posix-seh, 8.3.0'
);

Configure_win32( './Configure ' . $config, 'gmake', @cfg_args );
ok( -f $smoke_mk, "New makefile ($config/[@cfg_args])" );

SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 1 if !defined($makefile);

    like( $makefile, qr/
          ^CFG_VARS \s* = \s+ \\ \n
           \s*\Q"osvers=Win10 Build 19044 (64-bit)"\E \s+ \\ \n
           \s*\Q"ccversion=86_64-posix-seh, 8.3.0"\E \s+ \\ \n
           \s*\Q"config_args=-Dusedevel"\E \s+ \\ \n
           \s*\Q"INST_DRV=\E
    /mx, "CFG_VARS macro for Config.pm" );
}

ok( my_unlink( $smoke_mk ), "Remove makefile" );

$config = $dft_args . " -Accflags='-DPERL_COPY_ON_WRITE'";
Configure_win32( './Configure '. $config, 'gmake' );
ok( -f $smoke_mk, "New makefile ($config)" );
SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 1 if !defined($makefile);

    like(
        $makefile,
        qr/^BUILDOPTEXTRA\t\:=\s*-DPERL_COPY_ON_WRITE\n
           BUILDOPT\s*:=\ \$\(BUILDOPTEXTRA\) 
        /mx,
        "-Accflags= is translated to BUILDOPTEXTRA := ..."
    );
}

ok( my_unlink( $smoke_mk ), "Remove makefile" );

$config = $dft_args . " -Accflags='-DPERL_COPY_ON_WRITE'".
                      " -Accflags='-DPERL_POLLUTE'";
Configure_win32( './Configure '. $config, 'gmake' );
ok( -f $smoke_mk, "New makefile ($config)" );
SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 1 if !defined($makefile);

    like(
        $makefile,
        qr/^BUILDOPTEXTRA\t\:=\s*-DPERL_COPY_ON_WRITE \s+ -DPERL_POLLUTE\n
            BUILDOPT\t:=\ \$\(BUILDOPTEXTRA\)
        /mx,
        "2 x -Accflags= is translated to BUILDOPTEXTRA := ..."
    );
}

# Testing: -Duseithreads -Uuseimpsys
$config = $dft_args . " -Uuseimpsys";
Configure_win32( './Configure ' . $config, 'gmake' );
ok( -f $smoke_mk, "New makefile ($config)" );
SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 3 if !defined($makefile);

    #These should be unset
    like( $makefile, '/^USE_MULTI\s*:= define\n/m', '$(USE_MULTI)' );
    like( $makefile, '/^USE_ITHREADS\s*:= define\n/m', '$(USE_ITHREADS)' );
    like( $makefile, '/^#USE_IMP_SYS\s*:= define\n/m', '#$(USE_IMP_SYS)' );
}

# Testing: -Uuseshrplib
$config = $dft_args . " -Uuseshrplib";
Configure_win32( './Configure ' . $config, 'gmake' );
ok( -f $smoke_mk, "New makefile ($config)" );
SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 1 if !defined($makefile);

    #These should be unset
    like( $makefile, '/^BUILD_STATIC\s*:= define\n/m', '$(BUILD_STATIC)' );
}

ok( my_unlink( $smoke_mk ), "Remove makefile" );

note("Testing -Duseithreads -UWIN64...");
$config = $dft_args . " -UWIN64";
Configure_win32( './Configure ' . $config, 'gmake' );
ok( -f $smoke_mk, "New makefile ($config)" );
SKIP: {
    my $makefile = get_smoke_mk_ok($smoke_mk);
    skip "Can't read from '$smoke_mk': $!", 4 if !defined($makefile);

    like($makefile, '/^USE_MULTI\s*:= define$/m',       '$(USE_MULTI)');
    like($makefile, '/^USE_ITHREADS\s*:= define$/m',    '$(USE_ITHREADS)');
    like($makefile, '/^USE_LARGE_FILES\s*:= define$/m', '$(USE_LARGE_FILES)');
    like($makefile, '/^WIN64\s*:= undef$/m',            '$(WIN64)');
}

ok( my_unlink( $smoke_mk ), "Remove makefile" );

sub my_unlink {
    my $file = shift;
    1 while unlink $file;
    return ! -e $file;
}

sub get_smoke_mk_ok {
    my ($smoke_mk) = @_;
    my $content;
    if ( open(my $fh, "<:crlf", $smoke_mk) ) {
        $content = do {local $/; <$fh>};
        close($fh);
    }
    else {
        diag("Cannot open '$smoke_mk': $!");
    }
    ok(defined($content), "Reading makefile");
    return $content;
}
