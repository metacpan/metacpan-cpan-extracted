use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
	NAME         => "Net::Curl::Multi::EV",
	DISTNAME     => "curl_ev",
	ABSTRACT     => 'Using Net::Curl::Multi with EV',
	AUTHOR       => '<kni@cpan.org>',
	LICENSE      => "perl",
	VERSION_FROM => "CurlEV.pm",
	PREREQ_PM    => { EV => 4, 'Net::Curl' => 0.29, 'Scalar::Util' => 1.38 },
	PM           => { 'CurlEV.pm' => '$(INST_LIBDIR)/EV.pm' },
);
