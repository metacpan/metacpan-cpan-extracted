use ExtUtils::MakeMaker;
use strict;

require 5.6.0;

WriteMakefile (
    NAME            => 'Variable::Watcher',
    VERSION_FROM    => 'lib/Variable/Watcher.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => { 
                        'Test::More'                => 0, 
                        'Log::Message'              => 0,
                        'Params::Check'             => 0.07,
                        'Attribute::Handlers'       => 0.04,
                        'Tie::Scalar'               => 0,
                        'Tie::Array'                => 0,
                        'Tie::Hash'                 => 0,
              },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	ABSTRACT        => 'Deubgging tool to keep track of variable '.
	                   ' access and mutations'
);     
