use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %http_module = (Furl => '1.01');
eval {
    require Furl::HTTP;
};if ($@) {
    %http_module = (
        'LWP::UserAgent' => '6.04',
        'LWP::Protocol::https' => '6.03'
    );
} else {
    $http_module{'IO::Socket::SSL'} = '1.77';
}

WriteMakefile(
    NAME                => 'WebService::CloudPT',
    AUTHOR              => q{Bruno Martins <bruno-martins@telecom.pt>},
    VERSION_FROM        => 'lib/WebService/CloudPT.pm',
    ABSTRACT_FROM       => 'lib/WebService/CloudPT.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
		%http_module,
        'Test::More' => 0,
		'JSON' => '2.53',
        'Net::OAuth' => '0.28',
        'URI' => '1.60',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-CloudPT-*' },
);
