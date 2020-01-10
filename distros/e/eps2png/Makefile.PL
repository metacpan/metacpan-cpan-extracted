#! perl

# Makefile.PL -- Makefile for eps2png
# Author          : Johan Vromans
# Created On      : Sat Jun  6 16:08:33 1998
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jan  6 22:45:34 2020
# Update Count    : 88
# Status          : Released

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010001;

use strict;
use warnings;
use Config;
# EU::MM 6.5503 is the first version to understand *_REQUIRES.
use ExtUtils::MakeMaker 6.5503;

my @scripts = qw( eps2png );
my $usrbin = "/usr/bin";
my $installscript = $Config{installscript};

print STDERR <<EOD unless $installscript eq $usrbin;

WARNING: This Makefile will install user accessible scripts.
The location for these scripts is $installscript.
You may consider to pass INSTALLSCRIPT=$usrbin (or some other
convenient location) to "make install".
EOD

print STDERR <<EOD;

IMPORTANT: This program requires Ghostscript and may require the
Portable Bitmap package (PBM) for additional conversions.

IMPORTANT: Due to ongoing development of the Ghostscript output
drivers, some xt tests may fail. See README for details.

EOD

$ENV{LC_ALL} = "C";
my $gs = `gs --help`;
unless ( $gs =~ /^available devices:/im ) {
    warn("Ghostscript not found. Cannot continue\n");
    exit 0;
}
my $gv;
if ( $gs =~ /ghostscript\s+(\d+\.\d+.*?)\s+/i ) {
    $gv = $1;
    print STDERR ("Ghostscript version $gv detected.\n");
}

foreach my $type ( qw(pngmono pnggray png16 png256 pngalpha jpeggray) ) {
    next if $gs =~ / $type( |$)/m;
    warn("No Ghostscript driver for $type. You won't be able to use these.\n");
}
foreach my $type ( qw(png16m jpeg) ) {
    next if $gs =~ / $type( |$)/m;
    warn("No Ghostscript driver for $type. Some tests will fail.\n");
}
my $needpbm = 0;
foreach my $type ( qw(gif gifmono) ) {
    next if $gs =~ / $type( |$)/m;
    warn("No Ghostscript driver for $type. PBM fallback required.\n");
    $needpbm = 1;
}

if ( $needpbm ) {
    my ( $pbm ) = `ppmtogif --version 2>&1` =~ /pbm version: (.*)/i;
    if ( $pbm ) {
	print STDERR ("PBM version $pbm detected.\n");
    }
    else {
	warn("No PBM found. You won't be able to generate GIF images.\n");
    }
}

my $name = 'eps2png';
my $master = "lib/App/${name}.pm";
my $version = MM->parse_version($master);
unless ( -f "${name}.spec" ) {
    open( my $fd, ">", "${name}.spec" );
    print $fd "Placeholder, will be overwritten by Makefile.PL.\n";
    close($fd);
}

WriteMakefile(
    NAME                => $name,
    AUTHOR              => 'Johan Vromans <jv@cpan.org>',
    VERSION	        => $version,
    ABSTRACT            => 'convert EPS files to PNG, JPG or GIF images',
    LICENSE		=> 'perl',
    PL_FILES            => {},
    EXE_FILES		=> [ map { "script/$_" } @scripts ],
    MIN_PERL_VERSION	=> '5.010001',

    CONFIGURE_REQUIRES => {
        "ExtUtils::MakeMaker" => 6.5503,
    },

#   BUILD_REQUIRES => {
#   },

    TEST_REQUIRES  => {
      'Test::More'  => 0,
    },

    META_MERGE => {
      resources    => {
        repository => {
          type => 'git',
	   web  => "https://github.com/sciurius/${name}",
	   url  => "https://github.com/sciurius/${name}.git",
	 },
	bugtracker => "https://github.com/sciurius/${name}/issues",
	},
      'meta-spec' => {
	version => '2',
	url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
	},
      provides => {
	'App::eps2png' => { file => "lib/App/${name}.pm", version => $version },
	eps2png => { file => "script/${name}", version => $version },
      }
    }
);

warn("Creating script\n");
open(my $src, "<", "lib/App/${name}.pm")
  or die("script/${name}: $!\n");
open(my $dst, ">", "script/${name}")
  or die("script/${name}: $!\n");

while ( <$src> ) {
    s/^\$use_pbm = .;/\$use_pbm = $needpbm;/;
    print { $dst } $_;
}

close($dst);
close($src);
chmod( 0755, "script/${name}" );

WriteSpecfile( $name, $version );

1;

use POSIX 'strftime';

sub WriteSpecfile {
    my $name    = shift;
    my $version = shift;
    my @tm = localtime;

    vcopy( _tag	    => "RPM spec file",
	   _dst	    => "$name.spec",
	   pkgname  => $name,
	   version  => $version,
	   rpmdate  => strftime("%a %b %e %Y", @tm),
	 );
}

sub vcopy {
    my (%ctrl) = @_;

    $ctrl{_src} ||= $ctrl{_dst} . ".in";

    return unless open(my $fh, "<", $ctrl{_src});

    print("Writing ", $ctrl{_tag}, "...\n") if $ctrl{_tag};

    my $newfh;
    open ($newfh, ">", $ctrl{_dst})
      or die($ctrl{_dst}, ": $!\n");

    my $pat = "(";
    foreach ( grep { ! /^_/ } keys(%ctrl) ) {
	$pat .= quotemeta($_) . "|";
    }
    chop($pat);
    $pat .= ")";

    $pat = qr/\[\%\s+$pat\s+\%\]/;

    while ( <$fh> ) {
	s/$pat/$ctrl{$1}/ge;
	print { $newfh } $_;
    }
    close($newfh);
}
