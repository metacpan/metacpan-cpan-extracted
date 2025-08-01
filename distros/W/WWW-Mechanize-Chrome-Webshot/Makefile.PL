use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~ m!^bin/!; # SKIP the bin dir
    return if $file =~ m!^push_to_GIT/!; # SKIP the git dir
    return if $file =~ m!^experiments/!; # private folder
    return if $file =~ m!\.lock.*$!; # SKIP editor files
    return if $file =~ m!\.test-script-.*!; # SKIP editor files
    return $file;
}

my %WriteMakefileArgs = (
    NAME             => 'WWW::Mechanize::Chrome::Webshot',
    AUTHOR           => q{Andreas Hadjiprocopis <bliako@cpan.org>},
    VERSION_FROM     => 'lib/WWW/Mechanize/Chrome/Webshot.pm',
    ABSTRACT_FROM    => 'lib/WWW/Mechanize/Chrome/Webshot.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    EXE_FILES        => [
        'script/www-mechanize-webshot.pl',
    ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
    },
    TEST_REQUIRES => {
	'Mojo::Log' => '0',
	'Test::More::UTF8' => '0',
	'Test::TempDir::Tiny' => '0',
        'Test::More' => '0',
        'File::Spec' => '0',
        'FindBin' => '0',
        'Cwd' => '0',
        'File::Basename' => '0',
	'Data::Roundtrip' => '0',
	'Image::ExifTool' => '0',
    },
    PREREQ_PM => {
	'Config::JSON::Enhanced' => '0',
	'FindBin' => '0',
	'Mojo::Log' => '0',
	'WWW::Mechanize::Chrome' => '0',
	'WWW::Mechanize::Chrome::DOMops' => '0',
	'Data::Roundtrip' => '0',
	'Encode' => '0',
	'Image::ExifTool' => '5.31', # which supports EXIF for png files
	'Log::Log4perl' => '0',
	'IO::Socket::SSL' => '0',
	'Crypt::OpenSSL::AES' => '0',
	'Authen::SASL' => '0',
	'HTTP::CookieJar::LWP' => '0',
	'LWP::ConsoleLogger::Easy' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => [ 'WWW-Mechanize-Chrome-Webshot-*', '.test-script-*'] },
    postamble => {
        LIVE_FILES => 'xt/live/*.t'
    },
    # Thanks to marto @ Perlmonks.org
    # see https://perlmonks.org/?displaytype=displaycode;node_id=359256;part=1;abspart=1
    META_MERGE => {
          'meta-spec' => { version => 2 },
	  requires    => { perl => '5.0.8' },
          resources   => {
            license    => 'artistic_2',
	    homepage   => 'https://metacpan.org/module/WWW::Mechanize::Chrome::Webshot',
            repository => {
                url  => 'https://github.com/hadjiprocopis/WWW-Mechanize-Chrome-Webshot',
                web  => 'https://github.com/hadjiprocopis/WWW-Mechanize-Chrome-Webshot',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/hadjiprocopis/WWW-Mechanize-Chrome-Webshot/issues',
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
    return "LIVE_FILES=$h{LIVE_FILES}\n"
	. <<'POSTAMBLE';
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

livetest :: $(LIVE_FILES)
	prove --blib $(INST_LIB) --blib $(INST_ARCHLIB) --verbose $^
POSTAMBLE
}

