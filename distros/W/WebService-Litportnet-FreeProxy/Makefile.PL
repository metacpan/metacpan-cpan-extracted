use strict;
use warnings;

use ExtUtils::MakeMaker;

my %args = (
    NAME             => 'WebService::Litportnet::FreeProxy',
    VERSION_FROM     => 'lib/WebService/Litportnet/FreeProxy.pm',
    ABSTRACT_FROM    => 'lib/WebService/Litportnet/FreeProxy.pm',
    AUTHOR           => 'Litport <litport@cpan.org>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.016',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.52',
    },
    PREREQ_PM => {
        'HTTP::Tiny'   => 0,
        'JSON::PP'     => 0,
        'Time::Local'  => 0,
        'Scalar::Util' => 0,
        'POSIX'        => 0,

        # The default snapshot endpoint is https, and HTTP::Tiny needs both of
        # these to speak TLS at all.
        'IO::Socket::SSL' => '1.42',
        'Net::SSLeay'     => '1.49',
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://litport.net/free-proxy',
            repository => {
                type => 'git',
                url  => 'https://github.com/litportnet/free-proxy-sdk.git',
                web  => 'https://github.com/litportnet/free-proxy-sdk/tree/main/packages/perl',
            },
            bugtracker => {
                web => 'https://github.com/litportnet/free-proxy-sdk/issues',
            },
        },
        x_documentation => 'https://litport.net/docs/free-proxy-api',
    },
);

# Older ExtUtils::MakeMaker releases, including the one bundled with perl 5.16,
# do not understand these keys and would silently drop the declarations.
my $eumm = eval { ExtUtils::MakeMaker->VERSION } || 0;

if ( $eumm < 6.64 ) {
    my $test_requires = delete $args{TEST_REQUIRES} || {};
    $args{PREREQ_PM} = { %{ $args{PREREQ_PM} }, %$test_requires };
}

delete $args{CONFIGURE_REQUIRES} if $eumm < 6.52;
delete $args{META_MERGE}         if $eumm < 6.46;
delete $args{MIN_PERL_VERSION}   if $eumm < 6.48;
delete $args{LICENSE}            if $eumm < 6.31;

WriteMakefile(%args);
