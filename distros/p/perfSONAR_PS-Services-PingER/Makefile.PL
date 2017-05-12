#      $Id$
#
#	File:		Makefile.PL
#
#	Author:		Maxim Grigoriev, Fermilab
#                       Jared Greeno, SLAC
#                       Yee-Ting Li, SLAC
#
#	Date:		12.2007
#
#	Description:	
#		Build for perfSONAR-PS
#
use inc::Module::Install;

name             'perfSONAR_PS-Services-PingER';
author_from      'lib/perfSONAR_PS/Datatypes/PingER.pm';
license_from     'LICENSE';
license          'perl';
version          '0.09';
perl_version     '5.008';
all_from 	 'lib/perfSONAR_PS/';

build_requires  'Test::Exception' => 0;

#requires  'YAML' => '0.60';
#requires  'DateTime' => '0.41';
#requires  'DateTime::Locale' => '0.35';
#requires  'DateTime::TimeZone' => '0.59';
#requires  'DateTime::Format::Builder' => 0;

requires  'Bit::Vector' => 0;
requires  'Error' => '0.17';

#requires  'Carp' => 0;
#build_requires  'Object::Deadly' => 0;
#build_requires  'Carp::Clan' => 0;
requires  'XML::LibXML' => '1.60';
requires  'XML::NamespaceSupport' => 0;
requires  'XML::LibXML::Common'  => '0.13';

requires  'Log::Log4perl' => 0;

requires  'Class::Accessor'  => 0;
requires  'Class::Fields'  => 0; 

requires  'Config::General'  => 0; 
requires  'Statistics::Descriptive'  => 0; 

requires  'LWP' => '5';
requires  'DBI'  => '1.5'; 
requires  'DBD::SQLite'  => 0;
requires  'DBD::mysql'  => 0;  

requires  'base'  => 0; 
requires  'version'  => 0; 
requires  'fields'  => 0; 
requires  'Clone::Fast'  => 0; 
requires  'Clone'  => 0; 
requires  'Data::Compare'  => 0; 
requires  'Crypt::CBC'  => '2'; 
requires  'FreezeThaw' => 0;
requires  'Readonly' => 0;
requires  'Params::Validate' => '0.70';
requires  'Module::Load' => 0;

#requires  'Rose::DB'  => 0; 
#requires  'Rose::DB::Object'  => 0; 

# perfsonar dependencies
requires 'perfSONAR_PS::Common' => 0.09;
requires 'perfSONAR_PS::Transport' => 0.09;
requires 'perfSONAR_PS::Messages' => 0.09;
requires 'perfSONAR_PS::DB::SQL' => 0.09;
requires 'perfSONAR_PS::DB::File' => 0.09;
requires 'perfSONAR_PS::Services::Base' => 0.09;
requires 'perfSONAR_PS::Services::MA::General' => 0.09;
requires 'perfSONAR_PS::XML::Document_string' => 0.09;
requires 'perfSONAR_PS::Error_compat' => 0.09;
requires 'perfSONAR_PS::Client::LS::Remote' => 0.09;


###requires_external_bin 'mysql';
requires_external_bin 'sqlite3';
#requires_external_bin 'xml2-config';

no_index directory  => 't';
install_scripts => 'bin/';

auto_install;
WriteAll;


