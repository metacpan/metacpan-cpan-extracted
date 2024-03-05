# -*- mode: perl; c-basic-offset: 4; indent-tabs-mode: nil; -*-

use strict;
use ExtUtils::MakeMaker qw(WriteMakefile);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

my $module = 'Test::HTTP::LocalServer';
(my $main_file = "lib/$module.pm" ) =~ s!::!/!g;
(my $distbase = $module) =~ s!::!-!g;
my $distlink = $distbase;

my @tests = map { glob $_ } 't/*.t', 't/*/*.t';

my %module = (
    MIN_PERL_VERSION => '5.008',
    NAME                => $module,
    AUTHOR              => q{Max Maischein <corion@cpan.org>},
    VERSION_FROM        => $main_file,
    ABSTRACT_FROM       => $main_file,
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                web => "https://github.com/Corion/$distlink",
                url => "git://github.com/Corion/$distlink.git",
                type => 'git',
            },
            bugtracker  => {
              web    => "https://github.com/Corion/$distbase/issues",
              # mailto => 'meta-bugs@example.com',
            },
            license    => "https://dev.perl.org/licenses/",
        },
        dynamic_config   => 0, # we promise to keep META.* up-to-date
        x_static_install => 0,
    },

    'LICENSE'=> 'perl',

    PL_FILES            => {},
    BUILD_REQUIRES => {
        # Fairly long in core
        'File::Path' => 0,
        'File::Copy' => 0,
        'File::Find' => 0,
        'File::Basename' => 0,
        'ExtUtils::MakeMaker' => 0,
    },

    PREREQ_PM => {
                        'Carp' => 0,
                        'Getopt::Long' => 0,
                        'File::Spec' => 0,
                        'File::Temp' => 0,
                        'Cwd' => 0,
                        'File::Basename' => 0,
                        'HTTP::Response' => 0,
                        'HTTP::Daemon' => 6.05,
                        'HTTP::Tiny'     => 0,
                        'IO::Socket::INET' => 0, # For port probing
                        'CGI' => 0,
                        'HTTP::Request::AsCGI' => 0,
                        'Socket' => 0, # for detecting 127.0.0.1 vs [::1]
                        'IO::Socket::IP' => 0.25, # for handling IPv6-only localhost
                        'URI'      => 0,
                        'URI::URL' => 0,
                        'Time::HiRes' => 0,
    },
    TEST_REQUIRES => {
        'Test::More'      => 0,
    },

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => "$distbase-*" },

    test            => { TESTS => join( ' ', @tests ) },
);

# This is so that we can do
#     require 'Makefile.PL'
# and then call get_module_info

sub get_module_info { %module }

if( ! caller ) {
    # I should maybe use something like Shipwright...
    regen_README($main_file);
    regen_EXAMPLES() if -d 'examples';
    WriteMakefile1(get_module_info);
};

1;

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
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
    # README is the short version that just tells people what this is
    # and how to install it
    eval {
        # Get description
        my $readme = join "\n",
            pod_section($_[0], 'NAME', 'no heading' ),
            pod_section($_[0], 'DESCRIPTION' ),
            <<INSTALL,

INSTALLATION

This is a Perl module distribution. It should be installed with whichever
tool you use to manage your installation of Perl, e.g. any of

  cpanm .
  cpan  .
  cpanp -i .

Consult https://www.cpan.org/modules/INSTALL.html for further instruction.
Should you wish to install this module manually, the procedure is

  perl Makefile.PL
  make
  make test
  make install

INSTALL
            pod_section($_[0], 'REPOSITORY'),
            pod_section($_[0], 'SUPPORT'),
            pod_section($_[0], 'TALKS'),
            pod_section($_[0], 'KNOWN ISSUES'),
            pod_section($_[0], 'BUG TRACKER'),
            pod_section($_[0], 'CONTRIBUTING'),
            pod_section($_[0], 'SEE ALSO'),
            pod_section($_[0], 'AUTHOR'),
            pod_section($_[0], 'LICENSE' ),
            pod_section($_[0], 'COPYRIGHT' ),
    ;
        update_file( 'README', $readme );
    };
    # README.mkdn is the documentation that will be shown as the main
    # page of the repository on Github. Hence we recreate the POD here
    # as Markdown
    eval {
        require Pod::Markdown;

        my $parser = Pod::Markdown->new();

        # Read POD from Module.pm and write to README
        $parser->parse_from_file($_[0]);
        my $readme_mkdn = <<STATUS . $parser->as_markdown;

[![Travis Build Status](https://travis-ci.org/Corion/$distlink.svg?branch=master)](https://travis-ci.org/Corion/$distlink)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github/Corion/$distlink?branch=master&svg=true)](https://ci.appveyor.com/project/Corion/$distlink)

STATUS
        update_file( 'README.mkdn', $readme_mkdn );
    };
}

sub pod_section {
    my( $filename, $section, $remove_heading ) = @_;
    open my $fh, '<', $filename
        or die "Couldn't read '$filename': $!";

    my @section =
        grep { /^=head1\s+$section/.../^=/ } <$fh>;

    # Trim the section
    if( @section ) {
        pop @section if $section[-1] =~ /^=/;
        shift @section if $remove_heading;

        pop @section
            while @section and $section[-1] =~ /^\s*$/;
        shift @section
            while @section and $section[0] =~ /^\s*$/;
    };

    @section = map { $_ =~ s!^=\w+\s+!!; $_ } @section;
    return join "", @section;
}

sub regen_EXAMPLES {
    my $perl = $^X;
    if ($perl =~/\s/) {
        $perl = qq{"$perl"};
    };
    (my $example_file = $main_file) =~ s!\.pm$!/Examples.pm!;
    my $examples = `$perl -w examples/gen_examples_pod.pl`;
    if ($examples) {
        warn "(Re)Creating $example_file\n";
        $examples =~ s/\r\n/\n/g;
        update_file( $example_file, $examples );
    };
};

sub update_file {
    my( $filename, $new_content ) = @_;
    my $content;
    if( -f $filename ) {
        open my $fh, '<:raw:encoding(UTF-8)', $filename
            or die "Couldn't read '$filename': $!";
        local $/;
        $content = <$fh>;
    };

    if( $content ne $new_content ) {
        if( open my $fh, '>:raw:encoding(UTF-8)', $filename ) {
            print $fh $new_content;
        } else {
            warn "Couldn't (re)write '$filename': $!";
        };
    };
}
