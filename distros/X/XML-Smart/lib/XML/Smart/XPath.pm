#############################################################################
## Name:        XPath.pm
## Purpose:     XML::Smart::XPath - Compatibility with XPath (through XML::XPath).
## Author:      Graciliano M. P.
## Modified by: Harish Madabushi
## Created:     01/10/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


### MAINTAINER NOTE: Contains MEMLeak #### 

package XML::Smart::XPath                                      ;

use 5.006                                                      ;

use strict                                                     ;
use warnings                                                   ;

require Exporter                                               ;

use XML::Smart::Shared qw( _unset_sig_warn _reset_sig_warn )   ;

our ($VERSION , @ISA) ;
$VERSION = '0.05' ;

@ISA = qw(Exporter) ;

our @EXPORT = qw(xpath XPath xpath_pointer XPath_pointer) ;
our @EXPORT_OK = @EXPORT ;

my $load_XPath ;

##############
# LOAD_XPATH #
##############

sub load_XPath {

  return $load_XPath if $load_XPath ;
  eval(q`use XML::XPath ;`);
  if ($@) {
    warn("Error loading module XML::XPath! Can't use XPath with XML::Smart! Please install XML::XPath.");
    $load_XPath = undef ;
  }
  else { 
      $load_XPath           = 1 ;
      $XML::XPath::SafeMode = 1 ;
  }

  return $load_XPath ;
}

#########
# XPATH #
#########

sub XPath { &xpath } ;

sub xpath {
  my $this = shift ;
  
  load_XPath() ;

  my $xpath ;
  
  if ( $$this->{XPATH} ) { $xpath = ${$$this->{XPATH}} ;}
  
  if (!$xpath){
      $xpath = XML::XPath->new(
	  xml => $this->data(nospace => 1 , noheader => 1)
	  ) ;  
      $$this->{XPATH} = \$xpath ;
  }
  
  if ( !@_ ) { return $xpath ;}
  return ;
}

#################
# XPATH_POINTER #
#################

sub XPath_pointer { &xpath_pointer } ;

sub xpath_pointer {
  my $this = shift ;
  
  load_XPath() ;

  my $xpath = XML::XPath->new(xml => $this->data_pointer(nospace => 1 , noheader => 1)) ;
  
  if ( !@_ ) { return $xpath ;}
  return ;
}

#######
# END #
#######

1;


