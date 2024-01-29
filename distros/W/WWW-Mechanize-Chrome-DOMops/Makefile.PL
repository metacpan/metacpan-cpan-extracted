use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~  /^push_to_GIT$/; # SKIP the git dir
    return if $file =~ /\.lock.*$/; # SKIP editor files
    return $file;
}

my %WriteMakefileArgs = (
    NAME             => 'WWW::Mechanize::Chrome::DOMops',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/WWW/Mechanize/Chrome/DOMops.pm',
    ABSTRACT_FROM    => 'lib/WWW/Mechanize/Chrome/DOMops.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
	'Test2::Plugin::UTF8' => '0',
	'FindBin' => '0',
	'File::Temp' => '0',
	'File::Spec' => '0',
	'Log::Log4perl' => '0',
	'WWW::Mechanize::Chrome' => '0',
	'Data::Roundtrip' => '0',
    },
    PREREQ_PM => {
	'Data::Roundtrip' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'WWW-Mechanize-Chrome-DOMops-*' },
    postamble => {
        BENCHMARK_FILES => 'xt/benchmarks/*.b' },
	# Thanks to marto @ Perlmonks.org
	# see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
        META_MERGE => {
          'meta-spec' => { version => 2 },
	  requires    => { perl => '5.0.6' },
          resources   => {
            license    => 'artistic_2',
	    homepage   => 'https://metacpan.org/module/WWW::Mechanize::Chrome::DOMops',
            repository => {
                url  => 'https://github.com/hadjiprocopis/www-mechanize-chrome-domops',
                web  => 'https://github.com/hadjiprocopis/www-mechanize-chrome-domops',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/hadjiprocopis/www-mechanize-chrome-domops/issues',
            }
        },
    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
    my (undef,%h) = @_;
    #require Data::Dumper; print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    return "BENCHMARK_FILES=$h{BENCHMARK_FILES}\n"
	. <<'POSTAMBLE';
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

benchmarks :: $(BENCHMARK_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^
POSTAMBLE
}
