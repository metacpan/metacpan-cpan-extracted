package Unicode::Unihan;
use strict;
use 5.006;

=encoding utf8

=head1 The build file for Unicode::Unihan

This build file is a modulino; it works as both a build script and
a module.

To build the distribution, run this file normally:

	% perl Makefile.PL

But, it's more interesting than that. You can load it with C<require>
and call C<arguments> to get the data structure it passes to
C<WriteMakefile>:

	my $package = require '/path/to/Makefile.PL';
	my $arguments = $package->arguments;

Note that C<require>-ing a file makes an entry in C<%INC> for exactly
that name. If you try to C<require> another file with the same name,
even from a different path, C<require> thinks it has already loaded
the file. As such, I recommend you always require the full path to the
file.

The return value of the C<require> is a package name (in this case,
the name of the main module. Use that to call the C<arguments> method.

Even if this distribution needs a higher version of Perl, this bit
only needs v5.8. You can play with the data structure with a primitive
Perl.

=cut

use ExtUtils::MakeMaker;
use File::Basename qw(basename);
use File::Spec::Functions qw(catfile);

my $module    = __PACKAGE__;
( my $dist = $module ) =~ s/::/-/g;

my $github    = 'https://github.com/briandfoy/unicode-unihan';
my $main_file = catfile( 'lib', split /::/, "$module.pm" );

my %WriteMakefile = (
	'MIN_PERL_VERSION' => '5.006',

	'NAME'          => $module,
	'ABSTRACT_FROM' => $main_file,
	'VERSION_FROM'  => $main_file,
	'LICENSE'       => 'perl',
	'AUTHOR'        => 'Dan Kogai <dankogai@dan.co.jp>',

	'CONFIGURE_REQUIRES' => {
		'ExtUtils::MakeMaker'   => '6.64',
		'File::Basename'        => '0',
		'File::Spec::Functions' => '0',
		},

	'BUILD_REQUIRES' => {
		'version' => '0.86',
		},

	'TEST_REQUIRES' => {
		'Test::More' => '1',
		},

	'PREREQ_PM'     => {
		},

	'META_MERGE' => {
		'meta-spec' => { version => 2 },
		'keywords'  => ['unicode','unihan'],
		resources => {
			repository => {
				type => 'git',
				url  => $github,
				web  => $github,
				},
			bugtracker => {
				web    => "$github/issues",
				},
			homepage => $github,
			},
		},

	clean => { FILES => "$dist-*" },
	);

sub arguments { \%WriteMakefile }

do_it() unless caller;
sub do_it {
	require File::Spec;
	my $MM ='ExtUtils::MakeMaker';
	my $MM_version =
		eval{ "$MM " . $WriteMakefile{'CONFIGURE_REQUIRES'}{'ExtUtils::MakeMaker'} }
			||
		"$MM 6.64";
	eval "use $MM_version; 1" or die "Could not load $MM_version: $@";
	eval "use Test::Manifest 1.21"
		if -e File::Spec->catfile( qw(t test_manifest) );

	my $arguments = arguments();
	my $minimum_perl = $arguments->{MIN_PERL_VERSION} || '5.008';
	eval "require $minimum_perl;" or die $@;

	# We are going to install a bunch of database files in the same
	# directory as the main module file. So we build that first and
	# add the module file later since we can't use the default
	# behavior anymore.
	print "=" x 64, "\n";
	print "Preprocessing source text\n";
	$arguments->{PM} = mkdbm("srctxt", "db");
	print "done.\n";
	print "=" x 64, "\n";

	$arguments->{PM}{$main_file} = catfile( '$(INST_LIB)', split /::/, "$module.pm" );;


	WriteMakefile( %$arguments );
	}

sub mkdbm{
    BEGIN{  @AnyDBM_File::ISA = qw(DB_File GDBM_File SDBM_File) ; }
    use AnyDBM_File;
    use Fcntl;
    use File::Path;
    my ($srcdir, $dstdir) = @_;
    opendir my $dh, $srcdir or die "$srcdir:$!";
    -d $dstdir or mkpath [ $dstdir ], 0, 0755 or die "$dstdir:$!";
    my %PM = ();
    for my $src (grep /\.txt$/io, readdir($dh)){
    my $dst = $src; $dst =~ s/\.txt$/.db/o;

    if (-f "$dstdir/$dst"){
        print "$dstdir/$dst exists. skipping\n";
        next;
    }
    print "Processing $src...";
    tie my %hash, 'AnyDBM_File', "$dstdir/$dst", O_RDWR|O_CREAT, 0644
        or die "$dstdir/$dst: $!";
    my $n = 0;
    open my $fh, "$srcdir/$src" or die "$srcdir/$src:$!";
    while(<$fh>){
        chomp;
        my ($uni, $val) = split(/\t/, $_);
        $uni or next;
        $hash{hex($uni)} = $val;
        $n++;
    }
    close $fh;
    print "$n characters processed.\n";
    }
    close $dh;

    # Some DB implementations, such as SDBM, put extra extensions on
    # the files. We'll install anything that shows up in dstdir.
    for my $file ( glob( "$dstdir/*" ) ) {
        $PM{$file} = "\$(INST_LIBDIR)/Unihan/" . basename($file);
    }

    return \%PM;
}

no warnings;
__PACKAGE__;

