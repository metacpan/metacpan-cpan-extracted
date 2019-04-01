use strict;
use warnings;

use lib 'inc';
use MyBuilder;
use Config;
use File::Spec::Functions qw.catdir catfile.;
use File::Copy;


my $version = get_version();

my $builder = MyBuilder->new(
    module_name => 'Text::BibTeX',
    license     => 'perl',
    dist_author =>
        [ 'Alberto Simões <ambs@cpan.org>', 'Greg Ward <gward@python.net>' ],
    needs_compiler => 1,
    meta_merge     => {
        resources => { repository => 'http://github.com/ambs/Text-BibTeX', },
    },
    configure_requires => {
        'Module::Build'        => '0.36',
        'Config::AutoConf'     => '0.16',
        'ExtUtils::LibBuilder' => '0.02',
    },
    requires => {
        'Scalar::Util'       => '1.42',
        'Unicode::Normalize' => '0',
        'Encode'             => '0',
    },
    build_requires => {
        'File::Copy'           => '0',
        'Config::AutoConf'     => '0.16',
        'ExtUtils::LibBuilder' => '0.02',
        'Capture::Tiny'        => '0.06',
        'ExtUtils::CBuilder'   => '0.27',
        'Module::Build'        => '0.3603',
	'Cwd'                  => '0',
    },
    add_to_cleanup => [
        'Text-BibTeX-*',

        # NOT SURE YET        'btparse/src/bt_config.h',
        'btparse/src/*.so',
        'btparse/src/*.dylib',
        'btparse/src/*.dll',
        'btparse/src/*.o',
        'xscode/*.o',
        'btparse/tests/*.o',
        'btparse/progs/*.o',
        'btparse/progs/dumpnames',
        'btparse/progs/bibparse',
        'btparse/progs/biblex',
        'btparse/tests/postprocess_test',
        'btparse/tests/read_test',
        'btparse/tests/simple_test',
        'btparse/tests/macro_test',
        'btparse/tests/case_test',
        'btparse/tests/name_test',
        'btparse/tests/purify_test',
        'btparse/tests/namebug'
    ],
);

## HACK  HACK  HACK  HACK
my $libdir = $builder->install_destination("bin");
my $hdrdir = undef;
if ( $^O =~ /mswin32/i ) {
    $libdir = undef;

    # Find a place where we can write.
    my @folders   = split /;/, $ENV{PATH};
    my $installed = 0;
    my $target    = "text-bibtex.$$";
    while ( @folders && !$installed ) {
        $libdir = shift @folders;

        copy( "MANIFEST", catfile( $libdir, $target ) );
        $installed = 1 if -f catfile( $libdir, $target );
    }
    if ( !$installed ) {
        warn("Wasn't able to find a suitable place for libbtparse.dll!");
    }
    else {
        print STDERR "libbtparse.dll will be installed in $libdir\n";
        unlink catfile( $libdir, $target );
    }
}
else {
    if ( $Config{archname} =~ /^x86_64|^ppc64|^s390x|^aarch64|^riscv64/ ) {
        $libdir =~ s/\bbin\b/lib64/;
        if ( !-d $libdir ) {
            my $test = $libdir;
            $test =~ s/lib64/lib/;
            $libdir = $test if -d $test;
        }
    }
    else {
        $libdir =~ s/\bbin\b/lib/;
    }
    $hdrdir = $libdir;
    $hdrdir =~ s!/[^/]+/?$!/include!
}
$builder->notes( 'btparse_version' => $version );
$builder->notes( 'lib_path'        => $libdir );
$builder->add_build_element('usrlib');
$builder->install_path( 'usrlib'     => $libdir );
if (defined($hdrdir)) {
    $builder->add_build_element('usrinclude');
    $builder->install_path( 'usrinclude' => $hdrdir );
}
$builder->create_build_script;

sub get_version {
    my $version = undef;
    open PM, "lib/Text/BibTeX.pm"
        or die "Cannot open 'lib/Text/BibTeX.pm' for reading: $!\n";
    while (<PM>) {
        if (m!^our\s+\$VERSION\s*=\s*'([^']+)'!) {
            $version = $1;
            last;
        }
    }
    close PM;
    die "Could not find VERSION on your .pm file. Weirdo!\n" unless $version;
}

