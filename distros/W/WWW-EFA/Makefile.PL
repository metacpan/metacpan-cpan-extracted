use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::EFA',
    AUTHOR              => q{Robin Clarke <perl@robinclarke.net>},
    VERSION_FROM        => 'lib/WWW/EFA.pm',
    ABSTRACT_FROM       => 'lib/WWW/EFA.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'Carp'				=> 0,
	'Class::Date'			=> 0,
	'Digest::SHA'			=> 0,
	'File::Spec::Functions'		=> 0,
	'HTTP::Request'			=> 0,
	'LWP::UserAgent'		=> 0,
	'Moose'				=> 0,
	'Moose::Util::TypeConstraints'	=> 0,
	'MooseX::Aliases'		=> 0,
	'MooseX::Params::Validate'	=> 0,
	'Test::More'			=> 0,
	'Try::Tiny'			=> 0,
	'URI'				=> 0,
	'XML::LibXML'			=> 0,
	'YAML'				=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-EFA-*' },
);
