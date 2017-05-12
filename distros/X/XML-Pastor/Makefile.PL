# $Id: Makefile.PL,v 1.1 2006/11/11 12:00:38 ayhan Exp $
#
use utf8;
use ExtUtils::MakeMaker;
require 5.008;

my @programs = qw(pastorize);

 
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	
    NAME          	=> 'XML::Pastor',
    VERSION_FROM	=> 'lib/XML/Pastor.pm',    
    ABSTRACT   		=> 'Generate Perl classes with XML bindings starting from a W3C XSD Schema',    
    DISTNAME      	=> 'XML-Pastor',
    LICENSE			=> 'perl',
    AUTHOR        	=> 'Ayhan Ulusoy <dev@ulusoy.name>',
    EXE_FILES     	=> [ map {"bin/$_"} @programs],
    
    PREREQ_PM	    =>  {
    			'Carp'							=> 0,
                'Class::Accessor'  				=> 0,
                'Class::Data::Inheritable'  	=> 0,
    			'Cwd'							=> 0,
    			'Data::Dumper'					=> 0,
    			'Data::HashArray'				=> 0,    			
    			'File::Path'					=> 0,
    			'File::Spec'					=> 0,
    			'File::chdir'					=> 0,    	
    			'Getopt::Long'					=> 0,    	    					
    			'IO::File'						=> 0,
    			'LWP::UserAgent'				=> 0,    			
    			'MIME::Base64'					=> 0,
    			'Pod::Usage'					=> 0,
    			'Scalar::Util'					=> 0,
                'Test::More'  					=> 0,
                'URI'  							=> 0,                
                'XML::LibXML'  					=> '1.66',       # Unicode problems before         
                 },
	    

    clean        	=> { FILES =>"*.bak *~ *.old *.orig */*.bak */*~ */*.old */*.orig */*/*.bak */*/*~ */*/*.old */*/*.orig */*/*/*.bak */*/*/*~ */*/*/*.old */*/*/*.orig"}, 	

    
);



# =====================================================================

package MY;

sub libscan {
    my($self, $path) = @_;
    
    if 	  ($path =~ /(\~|\.bak|\.old|\.orig)$/) 			{	return undef;	}    # Backups, old files
    elsif ($path =~ /\.(\#|swp)$/) 					{	return undef;	}    # Temporaries & swap files.
    elsif ( ($path =~ /\b(RCS|CVS)\b/) 	||
    		($path =~ /\B\.svn\b/) 	   	||
    		($path =~ /,v$/)
    	)											{	return undef;	}    # CVS files
    
    else 											{	return $path;	}
}


1;



         
         
         
         

