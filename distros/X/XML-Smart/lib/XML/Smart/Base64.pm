#############################################################################
## Name:        Base64.pm
## Purpose:     XML::Smart::Base64
## Author:      Graciliano M. P.
## Modified by:
## Created:     25/5/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself


#############################################################################


## 
## Modified by Harish to fix bugs in xml creation and to errors more readable.
##     Tue Nov  1 21:18:43 IST 2011


############################################################################


package XML::Smart::Base64                                     ;

use strict                                                     ;
use warnings                                                   ;

use Carp                                                       ;

use XML::Smart::Shared qw( _unset_sig_warn _reset_sig_warn )   ;

our $VERSION = '1.3'       ;


my ($BASE64_PM) ;
eval("use MIME::Base64 ()") ;
if ( defined &MIME::Base64::encode_base64 ) { $BASE64_PM = 1 ;}




#################
# ENCODE_BASE64 #
#################

sub encode_base64 {

    my $value   = $_[0] ;
	
    if( $BASE64_PM ) { 
	
	eval { 
	    _unset_sig_warn() ;
	    my $encoded = MIME::Base64::encode_base64( $value  ) ;
	    my $decoded = MIME::Base64::decode_base64( $encoded) ;
	    _reset_sig_warn() ;
	    
	    my $tmp_decoded =  $decoded ;
	    $tmp_decoded    =~ s/\n//g  ;
	    
	    my $tmp_value   =  $value   ;
	    $tmp_value      =~ s/\n//g  ;
	    
	    return $encoded if( $tmp_decoded eq $tmp_value ) ;
	}; 

    }

    { 
	my $encoded     ;
	my $decoded     ;
	my $tmp_value   ;
	my $tmp_decoded ;
	eval {
	    _unset_sig_warn() ;
	    $encoded = _encode_base64_pure_perl( $value   ) ;
	    $decoded = _decode_base64_pure_perl( $encoded ) ;
	    _reset_sig_warn() ;
	
	    $tmp_decoded    =  $decoded ;
	    $tmp_decoded    =~ s/\n//g  ;
	    
	    $tmp_value      =  $value   ;
	    $tmp_value      =~ s/\n//g  ;
	} ; unless( $@ ) {
	    return $encoded if( $tmp_decoded eq $tmp_value ) ;
	}
    }
    
    { 
	_unset_sig_warn() ;
	my $encoded = _encode_ord_special( $value   ) ;
	my $decoded = _decode_ord_special( $encoded ) ;
	_reset_sig_warn() ;
	
	my $tmp_decoded =  $decoded ;
	$tmp_decoded    =~ s/\n//g  ;
	
	my $tmp_value   =  $value   ;
	$tmp_value      =~ s/\n//g  ;
	
	return $encoded if( $tmp_decoded eq $tmp_value ) ;
    }
    


    croak( "Error Encoding\n" ) ;

}

############################
# _ENCODE_BASE64_PURE_PERL #
############################

sub _encode_base64_pure_perl {
    my $res = "";
    my $eol = $_[1];
    $eol = "\n" unless defined $eol;
    pos($_[0]) = 0;                          # ensure start at the beginning
    while ($_[0] =~ /(.{1,45})/gs) {
	my $text = $1 ;
	$res .= substr( pack('u', $text ), 1 ) ;
	chop($res);
    }
    $res =~ tr|` -_|AA-Za-z0-9+/|;               # `# help emacs
    # fix padding at the end
    my $padding = (3 - length($_[0]) % 3) % 3;
    $res =~ s/.{$padding}$/'=' x $padding/e if $padding;
    # break encoded string into lines of no more than 76 characters each
    if (length $eol) {
	$res =~ s/(.{1,76})/$1$eol/g;
    }
    $res;
}



############################
#   _ENCODE_ORD_SPECIAL    #
############################


sub _encode_ord_special { 

    my $value = shift ;

    my @chars = split( //, $value ) ;
    my @ords  ;
    foreach my $char ( @chars ) { 
	push @ords, ord( $char ) ;
    }

    return join( "|", @ords ) ;

}


############################
#   _DECODE_ORD_SPECIAL    #
############################


sub _decode_ord_special {

    my $value = shift ;
    my @ords = split( /\|/, $value ) ;
    my @chars  ;
    foreach my $ord ( @ords ) { 
	push @chars, chr( $ord ) ;
    }

    return join( "", @chars ) ;

}

#################
# DECODE_BASE64 #
#################

sub decode_base64 {
    
    my $value = $_[0] ;

    if( $BASE64_PM ) { 

	eval { 
	    _unset_sig_warn() ;
	    my $decoded = MIME::Base64::decode_base64( $value   ) ;
	    my $encoded = MIME::Base64::encode_base64( $decoded ) ;
	    _reset_sig_warn() ;
	    
	    my $tmp_value   = $value   ;
	    $tmp_value      =~ s/\n//g ;
	    
	    my $tmp_encoded = $encoded ;
	    $tmp_encoded    =~ s/\n//g ;
	    
	    return $decoded if( $tmp_encoded eq $tmp_value  ) ;
	}; 

    }

    {

	my $decoded     ;
	my $encoded     ;
	my $tmp_value   ;
	my $tmp_encoded ;
	eval { 
	    $decoded = _decode_base64_pure_perl( $value     ) ;
	    $encoded = _encode_base64_pure_perl( $decoded   ) ;
	
	    $tmp_value      = $value   ;
	    $tmp_value      =~ s/\n//g ;
	    
	    $tmp_encoded    = $encoded ;
	    $tmp_encoded    =~ s/\n//g ;
	} ; unless( $@ ) { 
	    return $decoded if( $tmp_encoded eq $tmp_value  ) ;
	}
	
    }

    {

	my $decoded = _decode_ord_special( $value     ) ;
	my $encoded = _encode_ord_special( $decoded   ) ;
	
	my $tmp_value   = $value   ;
	$tmp_value      =~ s/\n//g ;
	
	my $tmp_encoded = $encoded ;
	$tmp_encoded    =~ s/\n//g ;
	
	return $decoded if( $tmp_encoded eq $tmp_value  ) ;
	
    }

    croak "Error Decoding $value\n"  ;

}


############################
# _DECODE_BASE64_PURE_PERL #
############################

sub _decode_base64_pure_perl {
  local($^W) = 0 ;
  my $str = shift ;
  my $res = "";

  $str =~ tr|A-Za-z0-9+=/||cd;            # remove non-base64 chars
  if (length($str) % 4) {
	#require Carp;
	#Carp::carp("Length of base64 data not a multiple of 4")
  }
  $str =~ s/=+$//;                        # remove padding
  $str =~ tr|A-Za-z0-9+/| -_|;            # convert to uuencoded format
  while ($str =~ /(.{1,60})/gs) {
	my $len = chr(32 + length($1)*3/4); # compute length byte
	$res .= unpack("u", $len . $1 );    # uudecode
  }
  $res;
}

#######
# END #
#######

1;

