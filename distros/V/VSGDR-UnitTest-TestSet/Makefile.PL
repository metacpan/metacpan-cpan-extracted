use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'VSGDR::UnitTest::TestSet',
    AUTHOR              => q{Ded MedVed <dedmedved@cpan.org>},
    VERSION_FROM        => 'lib/VSGDR/UnitTest/TestSet.pm',
    ABSTRACT_FROM       => 'lib/VSGDR/UnitTest/TestSet.pm',
    MIN_PERL_VERSION    => 5.10.0,
    ($ExtUtils::MakeMaker::VERSION >= 6.48
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES => [ "delGDRTest.pl", 
                   "disableGDRTestCondition.pl", 
                   "dumpGDRSql.pl", 
                   "genGDRTests.pl", 
                   "mergeGDRTests.pl", 
                   "replaceGDRSql.pl",
                   "reportGDRTests.pl", 
                   "runGDRTests.pl", 
                   "splitGDRTests.pl", 
                   "trGDRTests.pl" 
                 ],
    PREREQ_PM => {
        'Test::More'                => 0,
        'Array::Diff'               => 0,
        'Carp'                      => 0,
        'Clone'                     => 0,
        'DBD::ODBC'                 => 0,
        'DBI'                       => 0,
        'Data::Dumper'              => 0,
        'English'                   => 0,
        'File::Basename'            => 0,
        'Getopt::Euclid'            => 0,
        'IO::File'                  => 0,
        'IPC::System::Simple'       => 0,
        'List::MoreUtils'           => 0,
        'List::Util'                => 0,
        'Modern::Perl'              => 0,
        'Parse::RecDescent'         => 0,
        'Readonly'                  => 0,
        'Smart::Comments'           => 0,
        'Spreadsheet::WriteExcel'   => 0,
        'Spreadsheet::ParseExcel'   => 0,
        'Storable'                  => 0,
        'Text::Diff'                => 0,
        'Try::Tiny'                 => 0,
        'XML::Quote'                => 0,
        'XML::Simple'               => 0,
        'autodie'                   => 0,
        'indirect'                  => 0,
        'version'                   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'VSGDR-UnitTest-TestSet-*' },
);



