
use inc::Module::Install;

name 'Xmldoom';
abstract 'Xmldoom is a framework that allows you to bind database tables to Perl objects, a technique commonly referred to as object persistence, similar in purpose to Propel and Apache Torque';
author 'David Snopek';
version '0.0.16';
license 'gpl';

# Xmldoom and Romani versions must match!
requires 'DBIx::Romani' => '0.0.16';

build_requires 'DBD::SQLite';
build_requires 'Test::More';
build_requires 'Test::Class';
build_requires 'Data::Dumper';
build_requires 'Carp';
build_requires 'POSIX::strptime';
build_requires 'Callback';
build_requires 'Date::Calc';
build_requires 'Module::Util';
requires 'XML::SAX';
requires 'XML::DOM';
requires 'XML::GDOME';
requires 'XML::Writer';
requires 'XML::Writer::String';
requires 'Scalar::Util';
requires 'Carp';
requires 'Data::Dumper';
requires 'IO::File';
requires 'SQL::Translator';
requires 'Getopt::Long';
#requires 'File::ShareDir';
#requires 'File::Spec';
requires 'Module::Runtime';
requires 'Exception::Class';
requires 'Exception::Class::DBI';
requires 'Exception::Class::TryCatch';

# Not strictly necessary, but Xmldoom will run ungodly slow with the default
# PurePerl SAX parser...
requires 'XML::SAX::ExpatXS';

no_index directory => 'test';
no_index directory => 'example';

if ( $ARGV[0] ne 'dist' )
{
	auto_install;
}

install_script 'bin/xmldoom-generate';
install_script 'bin/xmldoom-schema';
install_share;

WriteAll;

