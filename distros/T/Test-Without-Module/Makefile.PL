use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

my $module = 'Test::Without::Module';
(my $main_file = "lib/$module.pm") =~ s!::!/!g;
(my $distname = $module) =~ s!::!-!g;
my $content = do { local(*ARGV,$/)=[$main_file]; <> };
(my $main_version)
    = $content =~ m/ [^\n]* \$VERSION \s* = [^=] '([\d_.]+) [^\n]+ /gxms;

my @tests = map {glob $_ } 't/*.t', 't/*/*.t';

my %module = (
    'NAME'    => 'Test::Without::Module',
    'VERSION_FROM'  => 'lib/Test/Without/Module.pm', # finds $VERSION
    'PREREQ_PM'    => {
        'Carp' => 0,
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM => 'lib/Test/Without/Module.pm', # retrieve abstract from module
    AUTHOR     => 'Max Maischein <corion@cpan.org>',

    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                web => 'https://github.com/Corion/test-without-module',
                url => 'git://github.com/Corion/test-without-module.git',
                type => 'git',
            },
            bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=' . $distname,
            license    => 'http://dev.perl.org/licenses/',        
        },
        dynamic_config   => 0, # we promise to keep META.* up-to-date
        x_static_install => 1, # we are pure Perl and don't do anything fancy
        provides => {
            $module => {
                file    => $main_file,
                version => $main_version,
            }
        }
    },
    BUILD_REQUIRES => {
        # Fairly long in core
        'File::Find' => 0,
        'File::Spec' => 0,
        'Test::More' => 0,
    },

    # Make the version metadata explicit
    'LICENSE' => 'perl',
);

sub get_module_info { %module }

if ( ! caller ) {
    regen_README($main_file);
    #regen_EXAMPLES();
    WriteMakefile1(get_module_info);
} 

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;

    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;
    
    WriteMakefile(%params);
}

sub regen_README {
    eval {
        require Pod::Readme;
        
        my $parser = Pod::Readme->new();      

        # Read POD from Module.pm and write to README
        $parser->parse_from_file($_[0], 'README');
    };
    eval {
        require Pod::Markdown;
        
        my $parser = Pod::Markdown->new();      

        # Read POD from Module.pm and write to README
        $parser->parse_from_file($_[0]);
        open my $fh, '>', 'README.mkdn'
            or die "Couldn't open 'README.mkdn': $!";
        print $fh <<STATUS;

[![Build Status](https://travis-ci.org/Corion/test-without-module.svg?branch=master)](https://github.com/Corion/test-without-module)

STATUS
        print $fh $parser->as_markdown;
    };
}

1;

