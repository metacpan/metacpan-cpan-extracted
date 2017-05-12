use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'Provide fetchrow_hashref() for CSV files',
 ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST Text-CSV_PP-Iterator-*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'Text-CSV_PP-Iterator',
 NAME      => 'Text::CSV_PP::Iterator',
 PL_FILES  => {},
 PREREQ_PM =>
 {
	 Exception::Class => 0,
	 Iterator         => 0,
	 Iterator::IO     => 0,
	 Test::More       => 0,
	 Test::Pod        => 0,
	 Text::CSV_PP     => 0,
 },
 VERSION_FROM => 'lib/Text/CSV_PP/Iterator.pm',
);
