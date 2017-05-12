package # put package name on different line to skip pause indexing
    CodeGenNonCallRequestResponseType;

use strict;
use warnings;

use Exporter;
use CodeGenRequestResponseType;
our @ISA = ('Exporter'
	    ,'CodeGenRequestResponseType'
           );


sub _determineFullPackageName {
   
   my $self = shift;	
   
   my $str = $self->getRootPackageName()
                 . '::' . 'DataType' 
                 . '::' . $self->getName();
    
   return $str;
}


1;
