#############################################################################
## Name:        Entity.pm
## Purpose:     XML::Smart::Entity - Handle entities
## Author:      Graciliano M. P.
## Modified by: Harish Madabushi
## Created:     28/09/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package XML::Smart::Entity                                     ;

use strict                                                     ;
use warnings                                                   ;

require Exporter                                               ;

use XML::Smart::Shared qw( _unset_sig_warn _reset_sig_warn )   ;

our ($VERSION , @ISA) ;
$VERSION = '0.03'     ;

@ISA = qw(Exporter)        ;

our @EXPORT = qw(_parse_basic_entity _add_basic_entity) ;
our @EXPORT_OK = @EXPORT ;



#######################
# _PARSE_BASIC_ENTITY #
#######################

sub _parse_basic_entity {

    my $entity = $_[0] ;
    if( $entity ) { 
	$_[0] =~ s/&lt;/</gs ;
	$_[0] =~ s/&gt;/>/gs ;
	$_[0] =~ s/&amp;/&/gs ;
	$_[0] =~ s/&apos;/'/gs ;
	$_[0] =~ s/&quot;/"/gs ;
	
	$_[0] =~ s/&#(\d+);/ $1 > 255 ? pack("U",$1) : pack("C",$1)/egs ;
	$_[0] =~ s/&#x([a-fA-F\d]+);/pack("U",hex($1))/egs ;
    }
  
  return( $entity ) ;
}

#####################
# _ADD_BASIC_ENTITY #
#####################

sub _add_basic_entity {

    my $entity = $_[0] ;
    if( $entity ) { 
	$_[0] =~ s/(&(?:\w+;)?)/{_is_amp($1) or $1}/sgex ;
	$_[0] =~ s/</&lt;/gs ;
	$_[0] =~ s/>/&gt;/gs ;
    }

    return( $entity ) ;
}
    
###########
# _IS_AMP #
###########

sub _is_amp {

    my $entity = $_[0] ;
    if( $entity ) { 
	if($entity eq '&') { 
	    return( '&amp;' ) ;
	}
    }

    return( undef ) ;

}

#######
# END #
#######

1;


