use ExtUtils::MakeMaker;
use Config;
use strict;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $name = 'BLADE';
my $distname = 'pBLADE';

# Objects to be combined into the shared library.
my @objects = qw(
		 BLADE.o
		 blade_obj_simple_init.o
		 blade_page.o
		 blade_run.o
		 blade_theme_simple_init.o
		 util.o
		 );

# Extra compile parameters needed.
open(CONFIG,"libblade-config --cflags --libs |") or
    die "Could not execute libblade-config: $!";
my ($cflags, $libs) = <CONFIG>;
close CONFIG;

# Location of BLADE files.
open(CONFIG,"blade-config --prefix |") or
    die "Could not execute blade-config: $!";
my $blade_prefix = <CONFIG>;
close CONFIG;

chomp ($cflags, $libs, $blade_prefix);

my $perl_prefix=$Config{prefix};

my $pmfile = $name.'.pm';
my $specfile = $distname.'.spec';
my $version = get_version($pmfile);

# create spec file before WriteMakefile(), since it is listed in MANIFEST
write_spec_file($distname, $version, $Config{prefix}, $specfile);

WriteMakefile(
    'NAME'	=> $name,
    'DISTNAME' => $distname,
    'VERSION_FROM' => $pmfile, # finds $VERSION
    'LIBS'	=> [$libs],
    'DEFINE'	=> '',
    'INC'	=> $cflags,
    'OBJECT' => join(' ',@objects),
    'dist' => { 'COMPRESS' => 'gzip -f --best' },
);

exit 0;

# create the rpm, special document targets
sub MY::postamble {

    my $doc_dir = "\$(install_prefix)/$blade_prefix/doc/blade/pBLADE";

    my $pod2text = "$Config{prefix}/bin/pod2text";
    (-x $pod2text) or $pod2text = undef;
    my $pod2html = "$Config{prefix}/bin/pod2html";
    (-x $pod2html) or $pod2html = undef;

    my @doc_files = ('README', 'ChangeLog', 'LICENSE', $specfile);

    $pod2text and push @doc_files, "$distname.txt";
    $pod2html and push @doc_files, "$distname.html";

    my $postamble = <<EOP;
rpm: dist
	rpm -ta $distname-$version.tar.gz

install :: install_mydocs

uninstall :: uninstall_mydocs

install_mydocs: uninstall_mydocs
EOP
    $pod2text and $postamble .= "\t$pod2text $pmfile > $distname.txt\n";
    $pod2html and $postamble .= "\t$pod2html $pmfile > $distname.html\n";
    $postamble .= <<EOP;
	\$(MKPATH) $doc_dir
EOP
    foreach my $file (@doc_files) {
	$postamble .= "\t\$(CP) $file $doc_dir/$file\n";
    }

    $postamble .= "\nuninstall_mydocs:\n";
    foreach my $file (@doc_files) {
	$postamble .= "\t\$(RM_F) $doc_dir/$file\n";
    }

    return $postamble;
}


# function for writing an rpm spec file
sub write_spec_file($$$$) {
    my ($distname, $version, $prefix, $outfile) = @_;

    open(SPEC,">$outfile") or die "Could not open output spec file '$outfile': $!";
    print SPEC <<EOP;
# Note that this is NOT a relocatable package
\%define rel      1

Summary:   Write BLADE applications in Perl
Name:      $distname
Version:   $version
Release:   \%rel
License:   GPL or Artistic License
Group:     Development/Libraries
Source:    $distname-$version.tar.gz
URL:       http://www.thestuff.net/bob/projects/blade
BuildRoot: /tmp/$distname-\%{PACKAGE_VERSION}-root
Packager:  Pete Ratzlaff <pratzlaff\@cfa.harvard.edu>

\%description
$distname is a Perl interface to the BLADE web development environment.

\%changelog

\%prep

\%setup
perl Makefile.PL PREFIX=\$RPM_BUILD_ROOT$prefix

\%build
make

\%install
rm -rf \$RPM_BUILD_ROOT
make install install_prefix=\$RPM_BUILD_ROOT

\%clean
rm -rf \$RPM_BUILD_ROOT

\%files
\%defattr(-, root, root)

/*
EOP
}

# not pretty, but gets the job done
sub get_version($) {
    my $pmfile = shift;

    open(PMFILE,$pmfile) or die "Could not open file '$pmfile': $!";
    my @lines = grep /^\s*\$VERSION\s*=\s*\'.*\'/, <PMFILE> or
	die "No version found in file '$pmfile'";

    my $version;
    ($version) = ($lines[0] =~ /^\$VERSION\s*=\s*\'(.*)\'/);

    return $version;
}
