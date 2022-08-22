use 5.006;
use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile1(
    'NAME'		=> 'Test::Warn',
    'VERSION_FROM'	=> 'Warn.pm', # finds $VERSION
    'ABSTRACT_FROM'     => 'Warn.pm', # retrieve abstract from module
    'PREREQ_PM'		=> {
                            #'Array::Compare'        => 0,
                            #'Test::Exception'       => 0,
                            'Test::Builder'         => 0.13,
                            'Test::Builder::Tester' => 1.02,
                            'Sub::Uplevel'          => 0.12,
                            'Carp'                  => 1.22,
                            },
    'TEST_REQUIRES'    => {
                            'File::Spec'            => 0,
                            'Test::More'            => 0,
                           },
    'LICENSE'		=> 'perl',
    'MIN_PERL_VERSION'  => 5.006,
    #AUTHOR        => 'Alexandr Ciornii <alexchorny'.'@gmail.com>',
    AUTHOR         => 'Janek Schleicher <bigj'.'@kamelfreund.de>',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/hanfried/test-warn.git',
                web => 'https://github.com/hanfried/test-warn',
            },
        },
      keywords => ['testing', 'warnings'],
    },
    META_ADD => {
        provides => {
            'Test::Warn' => {
                file => 'Warn.pm',
                version => '0.37',
            },
        },
    },
    PL_FILES => {},
    $^O =~/win/i ? (
        dist => {
            TAR      => 'ptar',
            TARFLAGS => '-c -C -f',
        },
    ) : (),
);


sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
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

    WriteMakefile(%params);
}

