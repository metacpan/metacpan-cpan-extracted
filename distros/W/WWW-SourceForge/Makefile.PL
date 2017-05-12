

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'WWW::SourceForge',
    VERSION_FROM => 'lib/WWW/SourceForge.pm',                # finds \$VERSION
    AUTHOR       => 'Rich Bowen (rbowen@rcbowen.com)',
    ABSTRACT =>
'Interface to SourceForge\'s APIs - http://sourceforge.net/p/forge/documentation/API/',
    PREREQ_PM => {
        'Test::Simple'       => 0.44,
        'Test::More'         => 0,
        'JSON::Parse'        => 0,
        'XML::Feed'          => 0,
        'LWP::Simple'        => 0,
        'Data::Dumper'       => 0,
        'LWP::UserAgent'     => 0,
        'LWP::Authen::OAuth' => 0,
	'File::HomeDir'      => 0,
    },
);
