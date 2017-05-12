#
# $Id: Makefile.PL,v 1.8 2005/09/01 08:19:27 patrick Exp $
#
use ExtUtils::MakeMaker;

WriteMakefile(
    'VERSION'   => '0.22' ,
    'AUTHOR'    => 'Patrick Hochstenbach <Patrick.Hochstenbach@UGent.be>' ,
    'NAME'      => 'XML::Tape' ,
    'PMLIBDIRS' => [ 'lib' ] ,
    'EXE_FILES' => [ 'bin/xmltape' , 'bin/xmlindex' ] ,
    'PREREQ_PM' => {
        DB_File => 0,
        Digest::MD5 => 0,
        File::Temp => 0,
        IO::File => 0,
        XML::Parser => 0,
        Test::More => 0,
	XML::LibXML => 0,
	HTTP::OAI => 0,
	XML::SAX::Writer => 0,
    }
);
