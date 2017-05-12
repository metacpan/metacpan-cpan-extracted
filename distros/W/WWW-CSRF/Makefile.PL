use ExtUtils::MakeMaker;

my %PREREQ_PM = (
	'Bytes::Random::Secure' => 0,
	'Digest::HMAC_SHA1' => 0
);

WriteMakefile(
	NAME              => "WWW::CSRF",
	VERSION_FROM      => "lib/WWW/CSRF.pm",
	PREREQ_PM         => \%PREREQ_PM
);

