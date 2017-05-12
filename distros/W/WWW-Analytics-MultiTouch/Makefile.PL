use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WWW::Analytics::MultiTouch',
    AUTHOR              => 'Jon Schutz <jon at jschutz.net>',
    VERSION_FROM        => 'lib/WWW/Analytics/MultiTouch.pm',
    ABSTRACT_FROM       => 'lib/WWW/Analytics/MultiTouch.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES           => [ qw{bin/multitouch_report.pl} ],
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Deep' => 0,
	'Net::Google::Analytics' => 3.00,
	'DateTime' => 0,
	'DateTime::Duration' => 0,
	'Params::Validate' => 0,
	'Data::Dumper' => 0,
	'List::Util' => 0,
	'Pod::Usage' => 0,
	'Getopt::Long' => 0,
	'Text::Table' => 0,
	'Text::CSV_XS' => '0.73',
	'Spreadsheet::WriteExcel' => '2.37',
	'IO::File' => 0,
	'Digest::MD5' => 0,
	'Config::General' => 0,
	'Hash::Merge' => 0,
	'POSIX' => 0,
	'LWP::UserAgent' => 0,
	'File::Temp' => 0,
        'Path::Class' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WWW-Analytics-MultiTouch-*' },
);
