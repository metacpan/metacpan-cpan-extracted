#############################################################################
## Name:        Smart.pm
## Purpose:     XML::Smart
## Author:      Graciliano M. P.
## Modified by: Harish Madabushi
## Created:     10/05/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################


package XML::Smart                                             ;

use 5.006                                                      ; 

use strict                                                     ;
use warnings                                                   ;

use Carp                                                       ;

use Object::MultiType                                          ;

use XML::Smart::Shared qw( _unset_sig_warn _reset_sig_warn )   ;

use vars qw(@ISA)                                              ;
@ISA = qw(Object::MultiType)                                   ;

use XML::Smart::Tie                                            ;
use XML::Smart::Tree                                           ;


=head1 NAME

XML::Smart - A smart, easy and powerful way to access or create XML from fiels, data and URLs.

=head1 VERSION

Version 1.78

=cut

our $VERSION = '1.78' ;

=head1 SYNOPSIS

This module provides an easy way to access/create XML data. It's based on a HASH
tree created from the XML data, and enables dynamic access to it through the 
standard Perl syntax for Hash and Array, without necessarily caring about which 
you are working with. In other words, B<each point in the tree works as a Hash and
an Array at the same time>!

This module additionally provides special resources such as: search for nodes by 
attribute, select an attribute value in each multiple node,  change the returned 
format, and so on.

The module also automatically handles binary data (encoding/decoding to/from base64),
CDATA (like contents with <tags>) and Unicode. It can be used to create XML files,
load XML from the Web ( just by using an URL as the file path ) and has an easy
way to send XML data through sockets - just adding the length of the data in
the <?xml?> header.

You can use I<XML::Smart> with L<XML::Parser>, or with the 2 standard parsers of
XML::Smart:

=over 10

=item I<XML::Smart::Parser>

=item I<XML::Smart::HTMLParser>.

=back

I<XML::Smart::HTMLParser> can be used to load/parse wild/bad XML data, or HTML tags.

=head1 Tutorial and F.A.Q.

You can find some extra documents about I<XML::Smart> at:

=over 2

=item L<XML::Smart::Tutorial> - Tutorial and examples for XML::Smart.

=item L<XML::Smart::FAQ>      - Frequently Asked Questions about XML::Smart.

=back

=cut

=head1 USAGE

  ## Create the object and load the file:
  my $XML = XML::Smart->new('file.xml') ;
  
  ## Force the use of the parser 'XML::Smart::Parser'.
  my $XML = XML::Smart->new('file.xml' , 'XML::Smart::Parser') ;
  
  ## Get from the web:
  my $XML = XML::Smart->new('http://www.perlmonks.org/index.pl?node_id=16046') ;

  ## Cut the root:
  $XML = $XML->cut_root ;

  ## Or change the root:
  $XML = $XML->{hosts} ;

  ## Get the address [0] of server [0]:
  my $srv0_addr0 = $XML->{server}[0]{address}[0] ;
  ## ...or...
  my $srv0_addr0 = $XML->{server}{address} ;
  
  ## Get the server where the attibute 'type' eq 'suse':
  my $server = $XML->{server}('type','eq','suse') ;
  
  ## Get the address again:
  my $addr1 = $server->{address}[1] ;
  ## ...or...
  my $addr1 = $XML->{server}('type','eq','suse'){address}[1] ;
  
  ## Get all the addresses of a server:
  my @addrs = @{$XML->{server}{address}} ;
  ## ...or...
  my @addrs = $XML->{server}{address}('@') ;
  
  ## Get a list of types of all the servers:
  my @types = $XML->{server}('[@]','type') ;
  
  ## Add a new server node:
  my $newsrv = {
  os      => 'Linux' ,
  type    => 'Mandrake' ,
  version => 8.9 ,
  address => [qw(192.168.3.201 192.168.3.202)]
  } ;
  
  push(@{$XML->{server}} , $newsrv) ;

  ## Get/rebuild the XML data:
  my $xmldata = $XML->data ;
  
  ## Save in some file:
  $XML->save('newfile.xml') ;
  
  ## Send through a socket:
  print $socket $XML->data(length => 1) ; ## show the 'length' in the XML header to the
                                          ## socket know the amount of data to read.
  
  __DATA__
  <?xml version="1.0" encoding="iso-8859-1"?>
  <hosts>
    <server os="linux" type="redhat" version="8.0">
      <address>192.168.0.1</address>
      <address>192.168.0.2</address>
    </server>
    <server os="linux" type="suse" version="7.0">
      <address>192.168.1.10</address>
      <address>192.168.1.20</address>
    </server>
    <server address="192.168.2.100" os="linux" type="conectiva" version="9.0"/>
  </hosts>

=cut

###############
# AUTOLOADERS #
###############

## Lead to mem leak? ##

sub data {
    require XML::Smart::Data ;
    _unset_sig_warn() ;
    *data = \&XML::Smart::Data::data ;
    _reset_sig_warn() ;
    &XML::Smart::Data::data(@_) ;
}

sub apply_dtd {
    require XML::Smart::DTD ;
    _unset_sig_warn() ;
    *apply_dtd = \&XML::Smart::DTD::apply_dtd ;
    _reset_sig_warn() ;
    &XML::Smart::DTD::apply_dtd(@_) ;
}

sub xpath { _load_xpath() ; &XML::Smart::XPath::xpath(@_) ;}
sub XPath { _load_xpath() ; &XML::Smart::XPath::XPath(@_) ;}
sub xpath_pointer { _load_xpath() ; &XML::Smart::XPath::xpath_pointer(@_) ;}
sub XPath_pointer { _load_xpath() ; &XML::Smart::XPath::XPath_pointer(@_) ;}

sub _load_xpath {

    require XML::Smart::XPath ;
    _unset_sig_warn() ;
    *xpath = \&XML::Smart::XPath::xpath ;
    *XPath = \&XML::Smart::XPath::XPath ;
    *xpath_pointer = \&XML::Smart::XPath::xpath_pointer ;
    *XPath_pointer = \&XML::Smart::XPath::XPath_pointer ;
    *_load_xpath = sub {} ;
    _reset_sig_warn() ;

}

#################
# NO_XML_PARSER #
#################

sub NO_XML_PARSER {
    $XML::Smart::Tree::NO_XML_PARSER = !@_ ? 1 : ( $_[0] ? 1 : undef ) ;
}

#######
# NEW #
#######

sub new {

    my $class = shift ;
    my $file  = shift ;
    my $parser = ($_[0] and $_[0] !~ /^(?:uper|low|arg|on|no|use)\w+$/i) ? shift(@_) : '' ;
    
    my $this = Object::MultiType->new(
	boolsub   => \&boolean ,
	scalarsub => \&content ,
	tiearray  => 'XML::Smart::Tie::Array' ,
	tiehash   => 'XML::Smart::Tie::Hash' ,
	tieonuse  => 1 ,
	code      => \&find_arg , 
	) ;


    $$this->{ parser } = $parser ;

    $parser = &XML::Smart::Tree::load($parser) ;

    if ( !($file) or $file eq '') { $$this->{tree} = {} ;}
    else { 
	eval { 
	    $$this->{tree} = &XML::Smart::Tree::parse($file,$parser,@_) ;
	}; croak( $@ ) if( $@ );
    }
    
    $$this->{point} = $$this->{tree} ;
    bless($this,$class) ;

    return $this ;

}

#########
# CLONE #
#########

sub clone {
    
    my $saver = shift ;
    
    my ($pointer , $back , $array , $key , $i , $null_clone) ;
    
    if ($#_ == 0 && !ref $_[0]) {
	my $nullkey = shift ;
	$pointer = {} ;
	$back = {} ;
	$null_clone = 1 ;
	
	($i) = ( $nullkey =~ /(?:^|\/)\/\[(\d+)\]$/s );
	($key) = ( $nullkey =~ /(.*?)(?:\/\/\[\d+\])?$/s );
	if ($key =~ /^\/\[\d+\]$/) { $key = undef ;}
    }
    
    else {
	$pointer = shift ;
	$back = shift ;
	$array = shift ;
	$key = shift ;
	$i = shift ;
    }
    
    my $clone = Object::MultiType->new(
	boolsub   => \&boolean ,
	scalarsub => \&content ,
	tiearray  => 'XML::Smart::Tie::Array' ,
	tiehash   => 'XML::Smart::Tie::Hash' ,
	tieonuse  => 1 ,
	code      => \&find_arg ,
	) ;
    bless($clone,__PACKAGE__) ;  
  
    if ( !$saver->is_saver ) { $saver = $$saver ;}
    
    if (!$back) {
	if (!$pointer) { $back = $saver->{back} ;}
	else { $back = $saver->{point} ;}
    }
    
    if (!$array && !$pointer) { $array = $saver->{array} ;}
    
    my @keyprev ;
    
    if (defined $key) { @keyprev = $key ;}
    elsif (defined $i) { @keyprev = "[$i]" ;}
    
    if (!defined $key) { $key = $saver->{key} ;}
    if (!defined $i) { $i = $saver->{i} ;}
    
    if (!$pointer) { $pointer = $saver->{point} ;}
    
    # my @call = caller ;
    # print STDERR "CLONE>> $key , $i >> @{$saver->{keyprev}} >> @_\n" ;


    $$clone->{tree} = $saver->{tree} ;
    $$clone->{point} = $pointer ;
    $$clone->{back} = $back ;
    $$clone->{array} = $array ;
    $$clone->{key} = $key ;
    $$clone->{i} = $i ;
    
    if ( @keyprev ) {
	$$clone->{keyprev} = ( $saver->{keyprev} ) ? [@{$saver->{keyprev}}]  : [] ;
	push(@{$$clone->{keyprev}} , @keyprev) ;
    }
    
    if (defined $_[0]) { $$clone->{content} = \$_[0] ;}
    
    if ( $null_clone || $saver->{null} ) {
	$$clone->{null} = 1 ;
	## $$clone->{self} = $clone ;
    }
    
    $$clone->{XPATH} = $saver->{XPATH} if $saver->{XPATH} ;
    
    return( $clone ) ;

}

###########
# BOOLEAN #
###########

sub boolean {

    my $this = shift ;
    
    if ( $this->null ) { 
	return 0 ;
    } else {
	return 1 ;
    }
    
}

########
# NULL #
########

sub null {

    my $this = shift ;

    if( $$this->{null} ) { 
	return 1 ;
    }
    
    if( (keys %{$$this->{tree}}) < 1 ) { 
	return 1 ;
    }
    
    return ;

}

########
# BASE #
########

sub base {

    my $this = shift ;
    
    my $base = Object::MultiType->new(
	boolsub   => \&boolean ,
	scalarsub => \&content ,
	tiearray  => 'XML::Smart::Tie::Array' ,
	tiehash   => 'XML::Smart::Tie::Hash' ,
	tieonuse  => 1 ,
	code      => \&find_arg , 
	) ;
    
    bless($base,__PACKAGE__) ;
    
    $$base->{tree} = $this->tree ;
    $$base->{point} = $$base->{tree} ;
    
    return( $base ) ;

}

########
# BACK #
########

sub back {

    my $this = shift ;
    
    my @tree ;
    if( $$this->{keyprev} ) { 
	@tree = @{$$this->{keyprev}} ;
    }
    
    if( !@tree ) { 
	return $this ;
    }
    
    my $last = pop(@tree) ;
    my $i = 0 ;
    if( $last =~ /^\[(\d+)\]$/ ) { 
	$i = $1 ; 
	$last = pop(@tree) ;
    }
    
    my $back = $this->base ;
    
    foreach my $tree_i ( @tree ) {
	if ($tree_i =~ /^\[(\d+)\]$/) {
	    my $i = $1 ;
	    $back = $back->[$i] ;
	} else { 
	    $back = $back->{$tree_i} ;
	}
    }
    
    if ( wantarray ) { 
	return( $back , $last , $i ) ;
    }

    return( $back ) ;

}

########
# PATH #
########

sub path {

    my $this = shift ;
    my @tree = @{$$this->{keyprev}} ;

    my $path ;
    
    foreach my $tree_i ( @tree ) {
	$path .= '/' if $tree_i !~ /^\[\d+\]$/ ;
	$path .= $tree_i ;
    }
    
    return $path ;

}

#################
# PATH_AS_XPATH #
#################

sub path_as_xpath {

    my $this = shift ;
    my @tree = @{$$this->{keyprev}} ;
    
    my $path ;
    
    foreach my $tree_i ( @tree ) {
	if ( $tree_i =~ /^\[(\d+)\]$/ ) {
	    my $i = $1 + 1 ;
	    $path .= "[$i]" ;
	} else { 
	    $path .= "/$tree_i" ;
	}
    }
    
    $path =~ s/\[1\]$// ;
    
    my $t = $this->is_node ;
    
    if ( !$this->is_node ) {
	$path =~ s/\/([^\/]+)$/\/\@$1/s ;
    }
    
    return $path ;

}

########
# ROOT #
########

sub root {

    my $this = shift ;
    
    my $root = ( $this->base->nodes_keys )[0] ;
    
    return $root ;

}

#######
# KEY #
#######

sub key {

    my $this = shift ;
    my $k = @{$$this->{keyprev}}[ $#{$$this->{keyprev}} ] ;
    if ($k =~ /^\[(\d+)\]$/) {
	$k = @{$$this->{keyprev}}[ $#{$$this->{keyprev}} -1 ] ;
    }
    
    return $k ;

}

#####
# I #
#####

sub i {

    my $this = shift ;
    my $i = $$this->{i} ;

    return $i ;
}

########
# COPY #
########

sub copy {

    my $this = shift ;

    my $data = $this->data( noheader => 1 ) ;
    my $copy = XML::Smart->new( $data, $$this->{ parser } ) ;


    if( $$this->{keyprev} ) { 
	my @old_array = @{ $$this->{keyprev} } ;
	my @new_array = @old_array             ;
	$$copy->{keyprev} = \@new_array        ;
    }
    
    my ( $back , $key , $i ) = $copy->back ;
    
    _unset_sig_warn() ;
    if( $key ne '' ) {
	$copy = $back->{$key} ;
	$copy = $back->[$i] if $i ;
    }
    _reset_sig_warn() ;

    return $copy ;

}

##############
# _COPY_HASH #
##############

sub _copy_hash {

    my ( $ref ) = @_ ;
    my $copy         ;
    
    if( ref $ref eq 'HASH' ) {
	$copy = {} ;
	foreach my $Key ( keys %$ref ) {
	    if( ref $$ref{$Key} ) {
		$$copy{$Key} =&_copy_hash($$ref{$Key}) ;
	    } else { 
		$$copy{$Key} = $$ref{$Key} ;
	    }
	}
    } elsif( ref $ref eq 'ARRAY' ) {
	$copy = [] ;
	foreach my $i ( @$ref ) {
	    if( ref $i ) {
		push( @$copy, &_copy_hash($i) ) ;
	    } else { 
		push( @$copy, $i ) ;
	    }
	}
    } elsif( ref $ref eq 'SCALAR' ) {
	my $copy = $$ref ;
	return( \$copy ) ;
    } else { 
	return( {} ) ;
    }
    
    return( $copy ) ;
    
}

###########
# TREE_OK #
###########

sub tree_ok {
    return _tree_ok_parse( &tree ) ;
}

##############
# POINTER_OK #
##############

sub pointer_ok {
    return _tree_ok_parse( &pointer ) ;
}

sub tree_pointer_ok { 
    &pointer_ok ;
}

##################
# _TREE_OK_PARSE #
##################

sub _tree_ok_parse {

    my ( $ref ) = @_ ;
    my $copy         ;
  
    if( ref $ref eq 'HASH' ) {
	$copy = {} ;
	foreach my $Key ( keys %$ref ) {
	    next if $Key eq '/order' || $Key eq '/nodes' || $Key =~ /\/\.CONTENT\// ;
	    if( ref $$ref{$Key} ) {
		$$copy{$Key} =&_tree_ok_parse($$ref{$Key}) ;
	    } else { 
		$$copy{$Key} = $$ref{$Key} ;
	    }
	}
    } elsif( ref $ref eq 'ARRAY' ) {
	$copy = [] ;
	foreach my $i ( @$ref ) {
	    if( ref $i ) {
		push( @$copy, &_tree_ok_parse($i) ) ;
	    } else { 
		push( @$copy, $i                  ) ;
	    }
	}
    } elsif( ref $ref eq 'SCALAR' ) {
	my $copy = $$ref ;
	return( \$copy ) ;
    } else { 
	return( {} ) ;
    }
    
    return( $copy ) ;

}

########
# TREE #
########

sub tree { 

    my $hash_to_return = ${$_[0]}->{tree} ;
    
    return ( $hash_to_return ) ;
    
}

sub tree_pointer { 
    &pointer ;
}

#############
# DUMP_TREE #
#############

sub dump_tree {
    require Data::Dumper ;
    local $Data::Dumper::Sortkeys = 1 ;
    return Data::Dumper::Dumper( &tree ) ;
}

sub dump_tree_ok {
    require Data::Dumper ;
    local $Data::Dumper::Sortkeys = 1 ;
    return Data::Dumper::Dumper( &tree_ok ) ;
}


################
# DUMP_POINTER #
################

sub dump_pointer {
    require Data::Dumper ;
    local $Data::Dumper::Sortkeys = 1 ;
    return Data::Dumper::Dumper( &pointer ) ;
}

sub dump_pointer_ok {
    require Data::Dumper ;
    local $Data::Dumper::Sortkeys = 1 ;
    return Data::Dumper::Dumper( &pointer_ok ) ;
}


sub dump_tree_pointer { 
    &dump_pointer ;
}

sub dump_tree_pointer_ok { 
    &dump_pointer_ok ;
}

###########
# POINTER #
###########

sub pointer {
    
    my $hash_to_return ;
    
    if ( ${$_[0]}->{content} ) { 
	$hash_to_return = ${${$_[0]}->{content}} ;
    } else {
	$hash_to_return = ${$_[0]}->{point}      ;
    }
    
    return ( $hash_to_return ) ;
}

############
# CUT_ROOT #
############

sub cut_root {

    my $this = shift ;
    
    my @nodes = $this->nodes_keys ;
    
    if( $#nodes > 0 ) { 
	return $this ;
    }
    
    my $root = $nodes[0] ;
    return( $this->{$root} ) ;

}

###########
# IS_NODE #
###########

sub is_node {

    my $this = shift ;

    return if $this->null ;
    
    my $key  = $this->key  ;
    my $back = $this->back ;
    
    return 1 if( $back->{'/nodes'}{$key} || $back->{$key}->nodes_keys ) ;
    return undef ;
    
}

########
# ARGS #
########

sub args {

    my $this = shift ;

    return () if $this->null ;
    
    my @args ;
    
    my $nodes   = $this->back->{'/nodes'} ;
    my $pointer = $$this->{point}         ;
    
    foreach my $Key ( keys %$this ) {

	next if( $$nodes{$Key} ) ;

	if( 
	    ( !ref $$pointer{ $Key} ) || 
	    ( ref( $$pointer{ $Key} ) eq 'HASH') || 
	    ( ref( $$pointer{ $Key} ) eq 'ARRAY' && $#{$$pointer{$Key}} == 0 ) 
	    ) {
	    
	    push(@args , $Key) ;
	    
	}
    }
    
    return @args ;
}

###############
# ARGS_VALUES #
###############

sub args_values {

    my $this = shift ;
    
    return () if $this->null ;
    
    my @args = $this->args ;
    
    my @values ;
    
    foreach my $args_i ( @args ) {
	push( @values, $this->{$args_i} ) ;
    }
    
    return @values ;
    
}

#########
# NODES #
#########

sub nodes {

    my $this = shift ;
    
    return () if $this->null ;
    
    my $nodes   = $this->{'/nodes'}->pointer ;
    my $pointer = $$this->{point}            ;
    
    my @nodes ;
    
    foreach my $Key ( keys %$this ) {

	if( 
	    $$nodes{$Key} || 
	    (ref($$pointer{$Key}) eq 'HASH') || 
	    (ref($$pointer{$Key}) eq 'ARRAY' && $#{$$pointer{$Key}} > 0)  
	    ) {

	    if( ref($$pointer{$Key}) eq 'ARRAY' ) {
		my $n = $#{$$pointer{$Key}} ;
		for my $i (0..$n) {
		    push( @nodes, $this->{$Key}[$i] ) ;
		}
	    } else {
		push( @nodes, $this->{$Key}[0] ) ;
	    }
	}
    }
    
    return @nodes ;

}

##############
# NODES_KEYS #
##############

sub nodes_keys {

    my $this = shift ;
    
    return () if $this->null ;
    
    
    my $nodes   = $this->{'/nodes'}->pointer ;
    my $pointer = $$this->{point}            ;
    
    my @nodes ;
    foreach my $Key ( keys %$this ) {
	if( 
	    $$nodes{$Key} || 
	    (ref($$pointer{$Key}) eq 'HASH') || 
	    (ref($$pointer{$Key}) eq 'ARRAY' && $#{$$pointer{$Key}} > 0)  
	    ) {
	    push(@nodes , $Key) ;
	}
    }
    
    return @nodes ;
}

############
# SET_NODE #
############

sub set_node {

    my $this     = shift ;
    my ( $bool ) = @_    ;
    
    if( !@_ ) { 
	$bool = 1 ;
    }
    
    my $key  = $this->key  ;
    my $back = $this->back ;
    
    $back->{'/nodes'} = {} if( $back->{'/nodes'}->null ) ;
    my $nodes = $back->{'/nodes'}->pointer ;
    
    if( $bool ) {

	if( $$nodes{$key} && $$nodes{$key} =~ /^(\w+,\d+),(\d*)/ ) { 
	    $$nodes{$key} = "$1,1" ;
	} else { 
	    $$nodes{$key} = 1      ;
	}
      
	if ( !$this->{CONTENT} ) {
	    my $content = $this->content ;
	    $this->{CONTENT} = $content if $content ne '' ;
	}

    } else {
	
	delete $$nodes{$key} ;
	my @keys = keys %$this ;
	if( $#keys == 0 && $keys[0] eq 'CONTENT' ) {
	    my $content = ( !$this->{CONTENT}->null ) ? $this->{CONTENT}('.') : $this->content ;
	    $this->back->pointer->{$key} = $content ;
	}
    }
    
}

###########
# SET_TAG #
###########

sub set_tag { 
    &set_node ;
}

#############
# SET_ORDER #
#############

sub set_order {
    my $this    = shift           ;
    my $pointer = $$this->{point} ;
    @{$$pointer{'/order'}} = @_   ;
}

sub order {
    my $this = shift ;
    my $pointer = $$this->{point} ;
    return @{$$pointer{'/order'}} if defined $$pointer{'/order'} && ref($$pointer{'/order'}) eq 'ARRAY' ;
    return() ;
}

#############
# SET_CDATA #
#############

sub set_node_type {

    my $this = shift ;

    my ( $type, $bool ) = @_ ;
    if( $#_ < 1 ) { 
	$bool = 1 ;
    }
    
    my $key  = $this->key  ;
    my $back = $this->back ;
    
    $back->{'/nodes'} = {} if( $back->{'/nodes'}->null );
    my $nodes = $back->{'/nodes'}->pointer ;
    
    if( $bool ) {

	if( $$nodes{$key} && $$nodes{$key} =~ /^\w+,\d+,(\d*)/ ) {
	    my $val = $1                   ;
	    $$nodes{$key} = "$type,1,$val" ;
	} else { 
	    my $existing_node_data = ( $$nodes{$key} ) ? $$nodes{$key} : "" ;
	    $$nodes{$key} = "$type,1," . $existing_node_data ;
	}
	
	if( !$this->{CONTENT} ) {
	    my $content = $this->content ;
	    $this->{CONTENT} = $content if $content ne '' ;
	}

    } else {

	if( !$$nodes{$key} ) {
	    my $tp = _data_type( $back->{$key} ) ;
	    if ( $tp > 2 ) { $$nodes{$key} = "$type,0," ;}
	} elsif( $$nodes{$key} eq '1' ) { 
	    $$nodes{$key} = "$type,0,1" ;
	} elsif( $$nodes{$key} =~ /^\w+,\d+,1/ ) { 
	    $$nodes{$key} = "$type,0,1" ;
	} elsif( $$nodes{$key} =~ /^\w+,\d+,0?$/ ) {

	    delete $$nodes{$key} ;
	    my @keys = keys %$this ;

	    if( $#keys == 0 && $keys[0] eq 'CONTENT') {
		my $content = $this->{CONTENT}('.') ;
		$this->back->pointer->{$key} = $content ;
	    }

	}
    }
    
}

#############
# SET_CDATA #
#############

sub set_cdata {
    my $this = shift ;
    $this->set_node_type('cdata',@_) ;
}

##############
# SET_BINARY #
##############

sub set_binary {
    my $this = shift ;
    $this->set_node_type('binary',@_) ;
}

#################
# SET_AUTO_NODE #
#################

sub set_auto_node {

    my $this = shift ;
    
    my $key  = $this->key  ;
    my $back = $this->back ;
    
    $back->{'/nodes'} = {} if( $back->{'/nodes'}->null );
    my $nodes = $back->{'/nodes'}->pointer ;
    
    if( !$$nodes{$key} || $$nodes{$key} eq '1' ) { 
	# Do nothing. ; 
    } elsif( $$nodes{$key} =~ /^\w+,\d+,1/   ) { 
	$$nodes{$key} = 1 ;
    } elsif( $$nodes{$key} =~ /^\w+,\d+,0?$/ ) {

	delete $$nodes{$key} ;
	my @keys = keys %$this ;

	if( $#keys == 0 && $keys[0] eq 'CONTENT') {
	    my $content = $this->{CONTENT}('.') ;
	    $this->back->pointer->{$key} = $content ;
	}

    }

}

############
# SET_AUTO #
############

sub set_auto {
    
    my $this = shift ;
    
    my $key  = $this->key  ;
    my $back = $this->back ;
    
    $back->{'/nodes'} = {} if $back->{'/nodes'}->null ;
    my $nodes = $back->{'/nodes'}->pointer ;
    
    delete $$nodes{$key} ;
    my @keys = keys %$this ;
    if( $#keys == 0 && $keys[0] eq 'CONTENT') {
	my $content = $this->{CONTENT}('.') ;
	$this->back->pointer->{$key} = $content ;
    }

}

##############
# _DATA_TYPE #
##############

## 4 binary
## 3 CDATA
## 2 content
## 1 value

sub _data_type {


    my $data = shift ;

    # TODO: 0x80, 0x81, 0x8d, 0x8f, 0x90, 0xa0 
    my @bin_data = (     
	0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8e, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 
	0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9e, 0x9f, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 
	0xab, 0xac, 0xad, 0xae, 0xaf, 0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 
	0xbd, 0xbe, 0xbf, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 
	0xcf, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf, 0xe0, 
	0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef, 0xf0, 0xf1, 0xf2, 
	0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff, 0x20, 
	);


    my $bin_string = join( '', ( map( pack("H*", $_), @bin_data ) ) ) ;
    
    return 4 if( $data && ( 
		     $data =~ /[^\w\d\s!"#\$\%&'\(\)\*\+,\-\.\/:;<=>\?\@\[\\\]\^\`\{\|}~~$bin_string]/s 
		     or 
		     $data =~ /(\240|\351|\361|\363|\341|\374|\340|\350|\366|\343|\355|\366|\344|\372|\364|\324|\301|\342)/s 
		 )
	) ;
    return 3 if( $data && $data =~ /<.*?>/s    ) ;
    return 2 if( $data && $data =~ /[\r\n\t]/s ) ;
    return 1                                     ;
}

#######
# RET #
#######

sub ret {

    my $this = shift ;
    my $type = shift ;
    
    if ($type =~ /^\s*<xml>\s*$/si ) {
	return $this->data_pointer( noheader => 1 ) ;
    }
    
    my @ret ;
    $type =~ s/[^<\$\@\%\.k]//gs ;
    
    if ($type =~ /^</) {
	$type =~ s/^<+// ;    
	
	my ($back , $key , $i) = $this->back ;
	
	if(     $type =~ /\$$/  ) { 
	    @ret = $back->{$key}[$i]->content ;
	} elsif( $type =~ /\@$/ ) {

	    @ret = @{$back} ;

	    foreach my $ret_i ( @ret ) {
		$ret_i = $ret_i->{$key}[$i] ;
	    }
	    
	} elsif( $type =~ /\%$/ ) { 
	    @ret = %{$back->{$key}[$i]} ;
	}
    } else {

	if( $this->null ) { 
	    return ;
	}
	
	if    ($type =~ /\$$/) { @ret = $this->content ; }
	elsif ($type =~ /\@$/) { @ret = @{$this}       ; }
	elsif ($type =~ /\%$/) { @ret = %{$this}       ; }
	elsif ($type =~ /\.$/) { @ret = $this->pointer ; }
	elsif ($type =~ /[\@\%]k$/) {

	    my @keys = keys %{$this} ;

	    foreach my $key ( @keys ) {
		my $n = $#{ $this->{$key} } ;
		if ($n > 0) {
		    my @multi = ($key) x ($n+1) ;
		    push(@ret , @multi) ;
		} else { 
		    push(@ret , $key) ;
		}
	    }

	}
    }
    
    if( $type =~ /^\$./ ) {
	foreach my $ret_i ( @ret ) {
	    if(ref($ret_i) eq 'XML::Smart') { 
		$ret_i = $ret_i->content ;
	    }
	}
    }
    

    if( wantarray ) { 
	return( @ret ) ;
    }
    return $ret[0] ;

}

########
# FIND #
########

sub find { 
    &find_arg 
} 

############
# FIND_ARG #
############

sub find_arg {

    my $this = shift ;
    if( $#_ == 0 && ref($_[0]) ne 'ARRAY' ) { 
	return $this->ret(@_) ;
    }
    
    if( $#_ == 1 && $_[0] eq '[@]'        ) {
	my $arg = $_[1] ;
	return $this->{$arg}('<@') ;
    }
    
    my @search ;
  
    for( my $i = 0; $i <= $#_ ; ++$i ) {
	if( ref($_[$i]) eq 'ARRAY' ) { 
	    push(@search , $_[$i]) ;
	} elsif( ref($_[$i]) ne 'ARRAY' && ref($_[$i+1]) ne 'ARRAY' && ref($_[$i+2]) ne 'ARRAY' ) {
	    push(@search , [$_[$i] , $_[$i+1] , $_[$i+2]]) ;
	    $i += 2 ;
	}
    }
    
    #use Data::Dumper ; print Dumper(\@search);
    #print "*** @search\n" ;
    
    if ( !@search ) { 
	return ;
    }
    
    my $key = $$this->{key} ;
    
    my @hashes ;
    
    if( ref($$this->{array}) ) {
	push( @hashes, @{$$this->{array}} ) ;
    } else {

	push( @hashes, $$this->{point}    ) ;

	if( ref $$this->{point} eq 'HASH' ) {
	    foreach my $k ( sort keys %{$$this->{point}} ) {
		push( @hashes, [$k,$$this->{point}{$k}]) if( ref($$this->{point}{$k}) eq 'HASH' ) ;
	    }
	}
    }
    
    my $i = -1 ;
    my (@hash , @i) ;
    my $notwant = !wantarray ;
    
    foreach my $hash_i ( @hashes ) {

	foreach my $search_i ( @search ) {

	    my ($name , $type , $value) = @{$search_i} ;
	    $type =~ s/\s//gs ;
	    
	    $i++ ;
	    my $hash ;
	    if (ref $hash_i eq 'ARRAY') { $hash = @$hash_i[1] ;}
	    else { $hash = $hash_i ;}
	    
	    my $data ;
	    if ($name =~ /^content$/i) { $name = 'CONTENT' ;}
	    $data = ref($hash) eq 'HASH' ? $$hash{$name} : $hash ;
	    $data = $$data{CONTENT} if ref($data) eq 'HASH' ;
	    
	    _unset_sig_warn() ;
	    if    ($type eq 'eq'  && $data eq $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last ;}
	    elsif ($type eq 'ne'  && $data ne $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last ;}
	    elsif ($type eq '=='  && $data == $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last ;}
	    elsif ($type eq '!='  && $data != $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last ;}
	    elsif ($type eq '<='  && $data <= $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last ;}
	    elsif ($type eq '>='  && $data >= $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last ;}
	    elsif ($type eq '<'   && $data <  $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last ;}
	    elsif ($type eq '>'   && $data >  $value)     { push(@hash,$hash_i) ; push(@i,$i) ; last ;}
	    elsif ($type eq '=~'  && $data =~ /$value/s)  { push(@hash,$hash_i) ; push(@i,$i) ; last ;}
	    elsif ($type eq '=~i' && $data =~ /$value/is) { push(@hash,$hash_i) ; push(@i,$i) ; last ;}
	    elsif ($type eq '!~'  && $data !~ /$value/s)  { push(@hash,$hash_i) ; push(@i,$i) ; last ;}
	    elsif ($type eq '!~i' && $data !~ /$value/is) { push(@hash,$hash_i) ; push(@i,$i) ; last ;}
	    _reset_sig_warn() ;
	}

	if( $notwant && @hash ) { 
	    last ;
	}
    }
    
    my $back = $$this->{back} ;
    
    #print "FIND>> @{$$this->{keyprev}} >> $i\n" ;
    
    if( @hash ) {
	if( $notwant ) {
	    my ($k,$hash) = (undef) ;
	    if (ref $hash[0] eq 'ARRAY') { ($k,$hash) = @{$hash[0]} ;}
	    else { $hash = $hash[0] ;}
	    return &XML::Smart::clone($this,$hash,$back,undef, $k,$i[0]) ;
	}
	else {
	    my $c = -1 ;
	    foreach my $hash_i ( @hash ) {
		$c++ ;
		my ($k,$hash) = (undef) ;
		if (ref $hash_i eq 'ARRAY') { ($k,$hash) = @{$hash_i} ;}
		else { $hash = $hash_i ;}        
		$hash_i = &XML::Smart::clone($this,$hash,$back,undef, $k,$i[$c]) ;
	    }
	    return( @hash ) ;
	}
    }
    
    if (wantarray) { return() ;}
    return &XML::Smart::clone($this,'') ;
}

###########
# CONTENT #
###########
sub content {

    my $this = shift ;
    my $set_i = $#_ > 0 ? shift : undef ;
  
    if ( $this->null ) {
	&XML::Smart::Tie::_generate_nulltree( $$this ) ;
    }
  
    ##use Data::Dumper; print Dumper($$this) ;
  
    my $content_to_return ;
    if ( defined $$this->{content} and ( !defined( $content_to_return ) ) ) {
	if (@_) { ${$$this->{content}} = $_[0] ;}
	$content_to_return = ${$$this->{content}} ;
    }

    my $key = 'CONTENT' ;
    my $i = $$this->{i} ;
  
    if( ( ref($$this->{point}) eq 'ARRAY' ) and ( !defined( $content_to_return ) ) ) {
	$content_to_return = $this->[0]->content($set_i,@_) ;
    }

    if( ( ref($$this->{point}) ne 'HASH' ) and ( !defined( $content_to_return ) ) ) { 
	$content_to_return = '' ;
    }
  
    if( ( !exists $$this->{point}{$key} ) and ( !defined( $content_to_return ) ) ) {
	if( @_ ) { 
	    $content_to_return = $$this->{point}{$key} = $_[0] ;
	} else {
	    $content_to_return = '' ;
	}
    }
  
    if( defined( $content_to_return ) ) { 
	return $content_to_return ;
    }

  
    if( ( ref($$this->{point}{$key}) eq 'ARRAY' ) and ( !defined( $content_to_return ) ) ) {

	if($i eq '') { 
	    $i = 0 ;
	}

	if(@_) { 
	    $$this->{point}{$key}[$i] = $_[0] ;
	}

	$content_to_return = $$this->{point}{$key}[$i] ;

    } elsif( ( exists $$this->{point}{$key} ) and ( !defined( $content_to_return ) ) ) {
	
	if ( @_ ) {
	    if ( my $tie = tied($$this->{point}{$key}) ) { 
		$tie->STORE($set_i , $_[0]) ;
	    } else { 
		$$this->{point}{$key} = $_[0] ;
	    }
	}

	if( wantarray && ( my $tie = tied($$this->{point}{$key} ) ) ) { 
	    my @tmp = $tie->FETCH(1)   ;
	    $content_to_return = \@tmp ;
	} else {
	    $content_to_return = $$this->{point}{$key} ;
	}

    }

    unless( defined( $content_to_return ) ) { 
	$content_to_return = '' ;
    }
  
    if( wantarray ) { 
	return @{ $content_to_return } ;
    } else {
	return $content_to_return ;
    }

}

########
# SAVE #
########

sub save {

    my $this = shift ;
    my $file = shift ;
    
    if(-d $file || (-e $file && !-w $file)) { 
	return ;
    }
    
    my( $data, $unicode ) = $this->data(@_) ;
    
    my $fh ;
    open($fh,">$file") ; 
    binmode($fh) if $unicode ;
    print $fh $data ;
    close($fh) ;
    
    return( 1 ) ;
    
}

################
# DATA_POINTER #
################

sub data_pointer {

    my $this = shift ;
    if( $this->null ) { 
	return ;
    }
    
    my( $point, $key ) ;
    
    if ( exists $$this->{content} ) {
	my $back = $this->back ;
	my $root = $back->key ;
	my $k = $this->key ;
	$point = $back->pointer ;
	$point = $$point{ $this->key } ;
	$point = {$root => {$k => $point} } ;
    } else {
	$point = $$this->{point} ;
	$key = $this->key ;
    }
    
    $this->data( tree => $point , root => $key , @_) ;
    
}

###########
# DESTROY #
###########

sub DESTROY {

    my $this = shift ;
    
    if( $$this->{ DEV_DEBUG } ) {
	require Devel::Cycle ;
	my $circ_ref = 0     ;
	my $tmp = Devel::Cycle::find_cycle(
	    $this, 
	    sub {
		my $path = shift;
		foreach (@$path) {
		    my ($type,$index,$ref,$value) = @$_;
		    $circ_ref = 1 ;
		    
		}
		
	    });
	
	if( $circ_ref ) { 
	    $this->ANNIHILATE() ;
	    my $tmp = Devel::Cycle::find_cycle( 
		$this, 
		sub {
		    print STDERR "Circular reference found while destroying object - AFTER ANNIHILATE\n" ;
		});
	}
    } 
    
    $$this->clean if( $this && $$this ) ; # In case object was messed with ( bug 62091 ) 
    
    
}

sub ANNIHILATE {
    
    my $this = shift ;
    my $base = shift ;
    
    if( ref $$this->{ point } eq 'HASH' ) { 
	my %clean ;
	$$this->{ point } = \%clean ;
    } else { 
	$this->{ point }->ANNIHILATE( ) ;
    }
    
    if( ref $$this->{ tree } eq 'HASH' ) { 
	my %clean ;
	$$this->{ tree } = \%clean ;
    } else { 
      $this->{ tree }->ANNIHILATE( ) ;
    }
    
    
    if( ref $$this->{ back } eq 'HASH' ) { 
	my %clean ;
	$$this->{ back } = \%clean ;
    } else { 
	$this->{ back }->ANNIHILATE( ) ;
    }
    
    if( $$this->{ XPATH } ) { # and ( ref $$this->{ XPATH } eq 'XML::XPath' ) ) { 
	my $xpath = $$this->{ XPATH } ;
	$$xpath->cleanup() ;
	my $context = $$xpath->{ _context } ;
	my $context_ref = ref $context ;
	if( $context_ref =~ /XML\:\:XPath\:\:Node\:\:/ ) {
	    _xml_xpath_clean( $context ) ;
	} 
    }
    
    $$this->DESTROY();

    return 1 ;
    
}


sub _xml_xpath_clean { 
    
    my $path = shift ;
    
    $path->dispose() ;
    # Data::Structure::Util::unbless( $path ) ;
    
    return ;
    
}

###################
# STORABLE_FREEZE #
###################

sub STORABLE_freeze {
    my $this = shift ;
    return($this , [$$this->{tree} , $$this->{pointer}])  ;
}

#################
# STORABLE_THAW #
#################

sub STORABLE_thaw {
    my $this = shift ;
    $$this->{tree} = $_[1]->[0] ;
    $$this->{pointer} = $_[1]->[1] ;
    return ;
}

#######
# END #
#######

1;

__END__

=head1 METHODS

=head2 new (FILE|DATA|URL , PARSER , OPTIONS)

Create a XML object.

B<Arguments:>

=over 10

=item FILE|DATA|URL

The first argument can be:

  - XML data as string.
  - File path.
  - File Handle (GLOB).
  - URL (Need LWP::UserAgent).

If not passed, a null XML tree is started, where you should create your own
XML data, than build/save/send it.

=item PARSER B<(optional)>

Set the XML parser to use. Options:

  XML::Parser
  XML::Smart::Parser
  XML::Smart::HTMLParser

I<XML::Smart::Parser> can only handle basic XML data (not supported PCDATA, and any header like: ENTITY, NOTATION, etc...),
but is a good choice when you don't want to install big modules to parse XML, since it
comes with the main module. But it still can handle CDATA and binary data.

** See I<"PARSING HTML as XML"> for B<XML::Smart::HTMLParser>.

Aliases for the options:

  SMART|REGEXP   => XML::Smart::Parser
  HTML           => XML::Smart::HTMLParser

I<Default:>

If not set it will look for XML::Parser and load it.
If XML::Parser can't be loaded it will use XML::Smart::Parser, which is actually a
clone of XML::Parser::Lite with some fixes.

=item OPTIONS

You can force the uper case and lower case for tags (nodes) and arguments (attributes), and other extra things.

=over 10

=item lowtag

Make the tags lower case.

=item lowarg

Make the arguments lower case.

=item upertag

Make the tags uper case.

=item uperarg

Make the arguments uper case.

=item arg_single

Set the value of arguments to 1 when they have a I<undef> value. 

I<** This option will work only when the XML is parsed by B<XML::Smart::HTMLParser>, since it accept arguments without values:>

  my $xml = new XML::Smart(
  '<root><foo arg1="" flag></root>' ,
  'XML::Smart::HTMLParser' ,
  arg_single => 1 ,
  ) ;

In this example the option "arg_single" was used, what will define I<flag> to 1, but I<arg1> will still have a null string value ("").

Here's the tree of the example above:

  'root' => {
              'foo' => {
                         'flag' => 1,
                         'arg1' => ''
                       },
            },

=item use_spaces

Accept contents that have only spaces.

=item on_start (CODE) I<*optional>

Code/sub to call on start a tag.

I<** This will be called after XML::Smart parse the tag, should be used only if you want to change the tree.>

=item on_char (CODE) I<*optional>

Code/sub to call on content.

I<** This will be called after XML::Smart parse the tag, should be used only if you want to change the tree.>

=item on_end (CODE) I<*optional>

Code/sub to call on end a tag.

I<** This will be called after XML::Smart parse the tag, should be used only if you want to change the tree.>

=back

I<** This options are applied when the XML data is loaded. For XML generation see data() OPTIONS.>

=back

B<Examples of use:>

  my $xml_from_url = XML::Smart->new("http://www.perlmonks.org/index.pl?node_id=16046") ;
  
  ...
  
  my $xml_from_str = XML::Smart->new(q`<?xml version="1.0" encoding="iso-8859-1" ?>
  <root>
    <foo arg="xyz"/>
  </root>
  `) ;

  ...

  my $null_xml = XML::Smart->new() ;

  ...

  my $xml_from_html = XML::Smart->new($html_data , 'html' ,
  lowtag => 1 ,
  lowarg => 1 ,
  on_char => sub {
               my ( $tag , $pointer , $pointer_back , $cont) = @_ ;
               $pointer->{extra_arg} = 123 ; ## add an extrar argument.
               $pointer_back->{$tag}{extra_arg} = 123 ; ## Same, but using the previous pointer.
               $$cont .= "\n" ; ## append data to the content.
             }
  ) ;

=head2  apply_dtd (DTD , OPTIONS)

Apply the I<DTD> to the XML tree.

I<DTD> can be a source, file, GLOB or URL.

This method is usefull if you need to have the XML generated by I<data()>
formated in a specific DTD, so, elements will be nodes automatically,
attributes will be checked, required elements and attributes will be created,
the element order will be set, etc...

B<OPTIONS:>

=over 10

=item no_delete BOOL

If TRUE tells that not defined elements and attributes in the DTD won't be deleted
from the XML tree.

=back

B<Example of use:>

  $xml->apply_dtd(q`
  <!DOCTYPE cds [
  <!ELEMENT cds (album+)>
  <!ATTLIST cds
            creator  CDATA
            date     CDATA #REQUIRED
            type     (a|b|c) #REQUIRED "a"
  >
  <!ELEMENT album (#PCDATA)>
  ]>
  ` ,
  no_delete => 1 ,
  );


=head2  args()

Return the arguments names (not nodes).

=head2  args_values()

Return the arguments values (not nodes).

=head2  back()

Get back one level the pointer in the tree.

** Se I<base()>.

=head2  base()

Get back to the base of the tree.

Each query to the XML::Smart object return an object pointing to a different place
in the tree (and share the same HASH tree). So, you can get the main object
again (an object that points to the base):

  my $srv = $XML->{root}{host}{server} ;
  my $addr = $srv->{adress} ;
  my $XML2 = $srv->base() ;
  $XML2->{root}{hosts}...

=head2  content()

Return the content of a node:

  ## Data:
  <foo>my content</foo>
  
  ## Access:
  
  my $content = $XML->{foo}->content ;
  print "<<$content>>\n" ; ## show: <<my content>>
  
  ## or just:
  my $content = $XML->{foo} ;

B<Also can be used with multiple contents:>

For this XML data:

  <root>
  content0
  <tag1 arg="1"/>
  content1
  </root>

Getting all the content:

  my $all_content = $XML->{root}->content ;
  print "[$all_content]\n" ;

Output:

  [
  content0
  
  content1
  ]

Getting in parts:

  my @contents = $XML->{root}->content ;
  print "[@contents[0]]\n" ;
  print "[@contents[1]]\n" ;

Output

  [
  content0
  ]
  [
  content1
  ]

B<Setting multiple contents:>

  $XML->{root}->content(0,"aaaaa") ;
  $XML->{root}->content(1,"bbbbb") ;

Output now will be:

  [aaaaa]
  [bbbbb]

And now the XML data generated will be:

  <root>aaaaa<tag1 arg="1"/>bbbbb</root>

=head2  copy()

Return a copy of the XML::Smart object (pointing to the base).

** This is good when you want to keep 2 versions of the same XML tree in the memory,
since one object can't change the tree of the other!

B<WARNING:> set_node(), set_cdata() and set_binary() changes are not persistant over copy - 
Once you create a second copy these states are lost.

b<warning:> do not copy after apply_dtd() unless you have checked for dtd errors.

=head2  cut_root()

Cut the root key:

  my $srv = $XML->{rootx}{host}{server} ;
  
  ## Or if you don't know the root name:
  $XML = $XML->cut_root() ;
  my $srv = $XML->{host}{server} ;

** Note that this will cut the root of the pointer in the tree.
So, if you are in some place that have more than one key (multiple roots), the
same object will be retuned without cut anything.

=head2 data (OPTIONS)

Return the data of the XML object (rebuilding it).

B<Options:>

=over 11

=item nodtd

Do not add in the XML content the DTD applied by the method I<apply_dtd()>.

=item noident

If set to true the data isn't idented.

=item nospace

If set to true the data isn't idented and doesn't have space between the
tags (unless the CONTENT have).

=item lowtag

Make the tags lower case.

=item lowarg

Make the arguments lower case.

=item upertag

Make the tags uper case.

=item uperarg

Make the arguments uper case.

=item length

If set true, add the attribute 'length' with the size of the data to the xml header (<?xml ...?>).
This is useful when you send the data through a socket, since the socket can know the total amount
of data to read.

=item noheader

Do not add  the <?xml ...?> header.

=item nometagen

Do not add the meta generator tag: <?meta generator="XML::Smart" ?>

=item meta

Set the meta tags of the XML document.

=item decode

As of VERSION 1.73 there are three different base64 encodings that are used. They are picked
based on which of them support the data provided. If you want to retrieve data using the 'data' function
the resultant xml will have dt:dt="binary.based" contained within it. To retrieve the decoded data
use: $XML->data( decode => 1 ) 


Examples:

    my $meta = {
    build_from => "wxWindows 2.4.0" ,
    file => "wx26.htm" ,
    } ;
    
    print $XML->data( meta => $meta ) ;
    
    __DATA__
    <?meta build_from="wxWindows 2.4.0" file="wx283.htm" ?>

Multiple meta:

    my $meta = [
    {build_from => "wxWindows 2.4.0" , file => "wx26.htm" } ,
    {script => "genxml.pl" , ver => "1.0" } ,
    ] ;
    
    __DATA__
    <?meta build_from="wxWindows 2.4.0" file="wx26.htm" ?>
    <?meta script="genxml.pl" ver="1.0" ?>

Or set directly the meta tag:

    my $meta = '<?meta foo="bar" ?>' ;

    ## For multiple:
    my $meta = ['<?meta foo="bar" ?>' , '<?meta x="1" ?>'] ;
    
    print $XML->data( meta => $meta ) ;

=item tree

Set the HASH tree to parse. If not set will use the tree of the XML::Smart object (I<tree()>). ;

=item wild

Accept wild tags and arguments.

** This wont fix wrong keys and tags.

=item sortall

Sort all the tags alphabetically. If not set will keep the order of the document loaded, or the order of tag creation.
I<Default:> off

=back

=head2 data_pointer (OPTIONS)

Make the tree from current point in the XML tree (not from the base as data()).

Accept the same OPTIONS of the method B<I<data()>>.

=head2  dump_tree()

Dump the tree of the object using L<Data::Dumper>.

=head2  dump_tree_pointer()

Dump the tree of the object, from the pointer, using L<Data::Dumper>.

=head2  dump_pointer()

I<** Same as dump_tree_pointer()>.

=head2  i()

Return the index of the value.

** If the value is from an hash key (not an ARRAY ref) undef is returned.

=head2  is_node()

Return if a key is a node.

=head2  key()

Return the key of the value.

If wantarray return the index too: return(KEY , I) ;

=head2  nodes()

Return the nodes (objects) in the pointer (keys that aren't arguments).

=head2  nodes_keys()

Return the nodes names (not the object) in the pointer (keys that aren't arguments).

=head2  null()

Return I<true> if the XML object has a null tree or if the pointer is in some place that doesn't exist.

=head2  order()

Return the order of the keys. See I<set_order()>.

=head2  path()

Return the path of the pointer.

I<Example>:

  /hosts/server[1]/address[0]

B<Note that the index is 0 based and 'address' can be an attribute or a node, what is not compatible with XPath.>

B<** See I<path_as_xpath()>.>

=head2  path_as_xpath()

Return the path of the pointer in the XPath format.

=head2  pointer

Return the HASH tree from the pointer.

=head2  pointer_ok

Return a copy of the tree of the object, B<from the pointer>, but without internal keys added by I<XML::Smart>.

=head2 root

Return the ROOT name of the XML tree (main key).

** See also I<key()> for sub nodes.

=head2 save (FILEPATH , OPTIONS)

Save the XML data inside a file.

Accept the same OPTIONS of the method B<I<data()>>.

=head2  set_auto

Define the key to be handled automatically. Soo, data() will define automatically if it's a node, content or attribute.

I<** This method is useful to remove set_node(), set_cdata() and set_binary() changes.>


=head2  set_auto_node

Define the key as a node, and data() will define automatically if it's CDATA or BINARY.

I<** This method is useful to remove set_cdata() and set_binary() changes.>

=head2  set_binary(BOOL)

Define the node as a BINARY content when TRUE, or force to B<not> handle it as a BINARY on FALSE.

Example of node handled as BINARY:

  <root><foo dt:dt="binary.base64">PGgxPnRlc3QgAzwvaDE+</foo></root>

Original content of foo (the base64 data):

  <h1>test \x03</h1>

=head2  set_cdata(BOOL)

Define the node as CDATA when TRUE, or force to B<not> handle it as CDATA on FALSE.

Example of CDATA node:

  <root><foo><![CDATA[bla bla bla <tag> bla bla]]></foo></root>

=head2  set_node(BOOL)

Set/unset the current key as a node (tag).

** If BOOL is not defined will use I<TRUE>.

B<WARNING:> You cannot set_node, copy the object and then set_node( 0 ) [ Unset node ]

=head2  set_order(KEYS)

Set the order of the keys (nodes and attributes) in this point.

=head2  set_tag

Same as set_node.

=head2  tree()

Return the HASH tree of the XML data.

** Note that the real HASH tree is returned here. All the other ways return an
object that works like a HASH/ARRAY through tie.

=head2  tree_pointer()

Same as I<pointer()>.

=head2  tree_ok()

Return a copy of the tree of the object, but without internal keys added by I<XML::Smart>, like I</order> and I</nodes>.

=head2  tree_pointer_ok()

Return a copy of the tree of the object, B<from the pointer>, but without internal keys added by I<XML::Smart>.

=head2  xpath() || XPath()

Return a XML::XPath object, based in the XML root in the tree.

  ## look from the root:
  my $data = $XML->XPath->findnodes_as_string('/') ;

I<** Need XML::XPath installed, but only load when is needed.>

=head2  xpath_pointer() || XPath_pointer() 

Return a XML::XPath object, based in the XML::Smart pointer in the tree.

  ## look from this point, soo XPath '/' actually starts at /server/:
  
  my $srvs = $XML->{server} ;
  my $data = $srvs->XPath_pointer->findnodes_as_string('/') ;

I<** Need XML::XPath installed, but only load when is needed.>


=head2 ANNIHILATE

XML::Smart uses XML::XPath that, for perfomance reasons, leaks memory. The ensure that this memory is freed you can 
explicitly call ANNIHILATE before the XML::Smart object goes out of scope. 


=head1 ACCESS

To access the data you use the object in a way similar to HASH and ARRAY:

  my $XML = XML::Smart->new('file.xml') ;
  
  my $server = $XML->{server} ;

But when you get a key {server}, you are actually accessing the data through tie(),
not directly to the HASH tree inside the object, (This will fix wrong accesses): 

  ## {server} is a normal key, not an ARRAY ref:

  my $server = $XML->{server}[0] ; ## return $XML->{server}
  my $server = $XML->{server}[1] ; ## return UNDEF
  
  ## {server} has an ARRAY with 2 items:

  my $server = $XML->{server} ;    ## return $XML->{server}[0]
  my $server = $XML->{server}[0] ; ## return $XML->{server}[0]
  my $server = $XML->{server}[1] ; ## return $XML->{server}[1]

To get all the values of multiple elements/keys:

  ## This work having only a string inside {address}, or with an ARRAY ref:
  my @addrsses = @{$XML->{server}{address}} ;

=head2 Select search

When you don't know the position of the nodes, you can select it by some attribute value:

  my $server = $XML->{server}('type','eq','suse') ; ## return $XML->{server}[1]

Syntax for the select search:

  (NAME, CONDITION , VALUE)


=over 10

=item NAME

The attribute name in the node (tag).

=item CONDITION

Can be

  eq  ne  ==  !=  <=  >=  <  >

For REGEX:

  =~  !~
  
  ## Case insensitive:
  =~i !~i

=item VALUE

The value.

For REGEX use like this:

  $XML->{server}('type','=~','^s\w+$') ;

=back

=head2 Select attributes in multiple nodes:

You can get the list of values of an attribute looking in all multiple nodes:

  ## Get all the server types:
  my @types = $XML->{server}('[@]','type') ;

Also as:

  my @types = $XML->{server}{type}('<@') ;

Without the resource:

  my @list ;
  my @servers = @{$XML->{server}} ;
  
  foreach my $servers_i ( @servers ) {
    push(@list , $servers_i->{type} ) ;
  }

=head2 Return format

You can change the returned format:

Syntax:

  (TYPE)

Where TYPE can be:

  $  ## the content.
  @  ## an array (list of multiple values).
  %  ## a hash.
  .  ## The exact point in the tree, not an object.
  
  $@  ## an array, but with the content, not an objects.
  $%  ## a hash, but the values are the content, not an object.
  
  ## The use of $@ and $% is good if you don't want to keep the object
  ## reference (and save memory).
  
  @keys  ## The keys of the node. note that if you have a key with
         ## multiple nodes, it will be replicated (this is the
         ## difference of "keys %{$this->{node}}" ).

  <@ ## Return the attribute in the previous node, but looking for
     ## multiple nodes. Example:
     
  my @names = $this->{method}{wxFrame}{arg}{name}('<@') ;
  #### @names = (parent , id , title) ;
  
  <xml> ## Return a XML data from this point.
     
  __DATA__
  <method>
    <wxFrame return="wxFrame">
      <arg name="parent" type="wxWindow" /> 
      <arg name="id" type="wxWindowID" /> 
      <arg name="title" type="wxString" /> 
    </wxFrame>
  </method>

Example:

  ## A servers content
  my $name = $XML->{server}{name}('$') ;
  ## ... or:
  my $name = $XML->{server}{name}->content ;
  ## ... or:
  my $name = $XML->{server}{name} ;
  $name = "$name" ;
  
  ## All the servers
  my @servers = $XML->{server}('@') ;
  ## ... or:
  my @servers = @{$XML->{server}} ;
  
  ## It still has the object reference:
  @servers[0]->{name} ;
  
  ## Without the reference:
  my @servers = $XML->{server}('$@') ;
  
  ## A XML data, same as data_pointer():
  my $xml_data = $XML->{server}('<xml>') ;


=head2 CONTENT

If a {key} has a content you can access it directly from the variable or
from the method:

  my $server = $XML->{server} ;

  print "Content: $server\n" ;
  ## ...or...
  print "Content: ". $server->content ."\n" ;

So, if you use the object as a string it works as a string,
if you use as an object it works as an object! ;-P

I<**See the method content() for more.>

=head1 CREATING XML DATA

To create XML data is easy, you just use as a normal HASH, but you don't need
to care with multiple nodes, and ARRAY creation/convertion!

  ## Create a null XML object:
  my $XML = XML::Smart->new() ;
  
  ## Add a server to the list:
  $XML->{server} = {
  os => 'Linux' ,
  type => 'mandrake' ,
  version => 8.9 ,
  address => '192.168.3.201' ,
  } ;
  
  ## The data now:
  <server address="192.168.3.201" os="Linux" type="mandrake" version="8.9"/>
  
  ## Add a new address to the server. Have an ARRAY creation, convertion
  ## of the previous key to ARRAY:
  $XML->{server}{address}[1] = '192.168.3.202' ;
  
  ## The data now:
  <server os="Linux" type="mandrake" version="8.9">
    <address>192.168.3.201</address>
    <address>192.168.3.202</address>
  </server>

After create your XML tree you just save it or get the data:

  ## Get the data:
  my $data = $XML->data ;
  
  ## Or save it directly:
  $XML->save('newfile.xml') ;
  
  ## Or send to a socket:
  print $socket $XML->data(length => 1) ;

=head1 BINARY DATA & CDATA

From version 1.2 I<XML::Smart> can handle binary data and CDATA blocks automatically.

B<When parsing>, binary data will be detected as:

  <code dt:dt="binary.base64">f1NPTUUgQklOQVJZIERBVEE=</code>

I<Since this is the oficial automatically format for binary data at L<XML.com|http://www.xml.com/pub/a/98/07/binary/binary.html>.>
The content will be decoded from base64 and saved in the object tree.

CDATA will be parsed as any other content, since CDATA is only a block that
won't be parsed.

B<When creating XML data>, like at $XML->data(), the binary format and CDATA are
detected using these rules:

  BINARY:
  - If your data has characters that can't be in XML.

  * Characters accepted:
    
    \s \w \d
    !"#$%&'()*+,-./:;<=>?@[\]^`{|}~
    0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8e, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 
    0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9e, 0x9f, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 
    0xab, 0xac, 0xad, 0xae, 0xaf, 0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 
    0xbd, 0xbe, 0xbf, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 
    0xcf, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf, 0xe0, 
    0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef, 0xf0, 0xf1, 0xf2, 
    0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff, 0x20

  TODO: 0x80, 0x81, 0x8d, 0x8f, 0x90, 0xa0 
  
  CDATA:
  - If have tags: <...>
  
  CONTENT: (<tag>content</tag>)
  - If have \r\n\t, or ' and " at the same time.


So, this will be a CDATA content:

  <code><![CDATA[
    line1
    <tag_not_parsed>
    line2
  ]]></code>

If binary content is detected, it will be converted to B<base64> and a B<dt:dt>
attribute added in the tag to tell the format.

  <code dt:dt="binary.base64">f1NPTUUgQklOQVJZIERBVEE=</code>


B<NOTE:> As of VERSION 1.73 there are three different base64 encodings that are used. They are picked
based on which of them support the data provided. If you want to retrieve data using the 'data' function
the resultant xml will have dt:dt="binary.based" contained within it. To retrieve the decoded data
use: $XML->data( decode => 1 ) 

=head1 UNICODE and ASCII-extended (ISO-8859-1)

I<XML::Smart> support only thse 2 encode types, Unicode (UTF-8) and ASCII-extended (ISO-8859-1),
and must be enough. (B<Note that UTF-8 is only supported on Perl-5.8+>).

When creating XML data, if any UTF-8 character is detected the I<encoding> attribute
in the <?xml ...?> header will be set to UTF-8:

  <?xml version="1.0" encoding="utf-8" ?>
  <data>0x82, 0x83</data>

If not, the I<iso-8859-1> is used:

  <?xml version="1.0" encoding="iso-8859-1" ?>
  <data>0x82</data>

When loading XML data with UTF-8, Perl (5.8+) should make all the work internally.

=head1 PARSING HTML as XML, or BAD XML formats

You can use the special parser B<XML::Smart::HTMLParser> to "use" HTML as XML
or not well-formed XML data.

The differences between an normal XML parser and I<XML::Smart::HTMLParser> are:

  - Accept values without quotes:
    <foo bar=x>
    
  - Accept any data in the values, including <> and &:
    <root><echo sample="echo \"Hello!\">out.txt"></root>
    
  - Accpet URI values without quotes:
    <link url=http://www.foo.com/dir/file?query?q=v&x=y target=#_blank>
  
  - Don't need to close the tags adding the '/' before '>':
    <root><foo bar="1"></root>
    
    ** Note that the parse will try hard to detect the nodes, and where
       auto-close or not.
  
  - Don't need to have only one root:
    <foo>data</foo><bar>data</bar>

So, I<XML::Smart::HTMLParser> is a willd way to load markuped data (like HTML),
or if you don't want to care with quotes, end tags, etc... when writing by hand your XML data.
So, you can write by hand a bad XML file, load it with I<XML::Smart::HTMLParser>, and B<rewrite well>
saving it again! ;-P

** Note that <SCRIPT> tags will only parse right if the content is inside
comments <!--...-->, since they can have tags:

  <SCRIPT LANGUAGE="JavaScript"><!--
  document.writeln("some <tag> in the string");
  --></SCRIPT>

=head1 ENTITIES

Entities (ENTITY) are handled by the parser. So, if you use L<XML::Parser> it will do all the job fine.
But If you use I<XML::Smart::Parser> or I<XML::Smart::HMLParser>, only the basic entities (defaults)
will be parsed:

  &lt;   => The less than sign (<).
  &gt;   => The greater than sign (>).
  &amp;  => The ampersand (&).
  &apos; => The single quote or apostrophe (').
  &quot; => The double quote (").
  
  &#ddd;  => An ASCII character or an Unicode character (>255). Where ddd is a decimal.
  &#xHHH; => An Unicode character. Where HHH is in hexadecimal.

B<When creating XML data>, already existent Entities won't be changed, and the
characters '<', '&' and '>' will be converted to the appropriated entity.

** Note that if a content have a <tag>, the characters '<' and '>' won't be converted
to entities, and this content will be inside a CDATA block.

=head1 WHY AND HOW IT WORKS

Every one that have tried to use Perl HASH and ARRAY to access XML data, like in L<XML::Simple>,
have some problems to add new nodes, or to access the node when the user doesn't know if it's
inside an ARRAY, a HASH or a HASH key. I<XML::Smart> create around it a very dynamic way to
access the data, since at the same time any node/point in the tree can be a HASH and
an ARRAY. You also have other extra resources, like a search for nodes by attribute:

  my $server = $XML->{server}('type','eq','suse') ; ## This syntax is not wrong! ;-)

  ## Instead of:
  my $server = $XML->{server}[1] ;
  
  __DATA__
  <hosts>
    <server os="linux" type="redhat" version="8.0">
    <server os="linux" type="suse" version="7.0">
  </hosts>

The idea for this module, came from the problem that exists to access a complex struture in XML.
You just need to know how is this structure, something that is generally made looking the XML file (what is wrong).
But at the same time is hard to always check (by code) the struture, before access it.
XML is a good and easy format to declare your data, but to extrac it in a tree way, at least in my opinion,
isn't easy. To fix that, came to my mind a way to access the data with some query language, like SQL.
The first idea was to access using something like:

  XML.foo.bar.baz{arg1}

  X = XML.foo.bar*
  X.baz{arg1}
  
  XML.hosts.server[0]{argx}

And saw that this is very similar to Hashes and Arrays in Perl:

  $XML->{foo}{bar}{baz}{arg1} ;
  
  $X = $XML->{foo}{bar} ;
  $X->{baz}{arg1} ;
  
  $XML->{hosts}{server}[0]{argx} ;

But the problem of Hash and Array, is not knowing when you have an Array reference or not.
For example, in XML::Simple:

  ## This is very diffenrent
  $XML->{server}{address} ;
  ## ... of this:
  $XML->{server}{address}[0] ;

So, why don't make both ways work? Because you need to make something crazy!

To create I<XML::Smart>, first I have created the module L<Object::MultiType>.
With it you can have an object that works at the same time as a HASH, ARRAY, SCALAR,
CODE & GLOB. So you can do things like this with the same object:

  $obj = Object::MultiType->new() ;
  
  $obj->{key} ;
  $obj->[0] ;
  $obj->method ;  
  
  @l = @{$obj} ;
  %h = %{$obj} ;
  
  &$obj(args) ;
  
  print $obj "send data\n" ;

Seems to be crazy, and can be more if you use tie() inside it, and this is what I<XML::Smart> does.

For I<XML::Smart>, the access in the Hash and Array way paste through tie(). In other words, you have a tied HASH
and tied ARRAY inside it. This tied Hash and Array work together, soo B<you can access a Hash key
as the index 0 of an Array, or access an index 0 as the Hash key>:

  %hash = (
  key => ['a','b','c']
  ) ;
  
  $hash->{key}    ## return $hash{key}[0]
  $hash->{key}[0] ## return $hash{key}[0]  
  $hash->{key}[1] ## return $hash{key}[1]
  
  ## Inverse:
  
  %hash = ( key => 'a' ) ;
  
  $hash->{key}    ## return $hash{key}
  $hash->{key}[0] ## return $hash{key}
  $hash->{key}[1] ## return undef

The best thing of this new resource is to avoid wrong access to the data and warnings when you try to
access a Hash having an Array (and the inverse). Thing that generally make the script die().

Once having an easy access to the data, you can use the same resource to B<create> data!
For example:

  ## Previous data:
  <hosts>
    <server address="192.168.2.100" os="linux" type="conectiva" version="9.0"/>
  </hosts>
  
  ## Now you have {address} as a normal key with a string inside:
  $XML->{hosts}{server}{address}
  
  ## And to add a new address, the key {address} need to be an ARRAY ref!
  ## So, XML::Smart make the convertion: ;-P
  $XML->{hosts}{server}{address}[1] = '192.168.2.101' ;
  
  ## Adding to a list that you don't know the size:
  push(@{$XML->{hosts}{server}{address}} , '192.168.2.102') ;
  
  ## The data now:
  <hosts>
    <server os="linux" type="conectiva" version="9.0"/>
      <address>192.168.2.100</address>
      <address>192.168.2.101</address>
      <address>192.168.2.102</address>
    </server>
  </hosts>

Than after changing your XML tree using the Hash and Array resources you just
get the data remade (through the Hash tree inside the object):

  my $xmldata = $XML->data ;

B<But note that I<XML::Smart> always return an object>! Even when you get a final
key. So this actually returns another object, pointhing (inside it) to the key:

  $addr = $XML->{hosts}{server}{address}[0] ;
  
  ## Since $addr is an object you can TRY to access more data:
  $addr->{foo}{bar} ; ## This doens't make warnings! just return UNDEF.

  ## But you can use it like a normal SCALAR too:

  print "$addr\n" ;

  $addr .= ':80' ; ## After this $addr isn't an object any more, just a SCALAR!

=head1 TODO

  * Finish XPath implementation.
  * DTD - Handle <!DOCTYPE> gracefully.
  * Implement a better way to declare meta tags.
  * Add 0x80, 0x81, 0x8d, 0x8f, 0x90, 0xa0 ( multi byte characters to the list of accepted binary characters )
  * Ensure object copy holds more in state including: ->data( wild => 1 ) 



=head1 SEE ALSO

L<XML::Parser>, L<XML::Parser::Lite>, L<XML::XPath>, L<XML>.

L<Object::MultiType> - This is the module that make everything possible,
and was created specially for I<XML::Smart>. ;-P

** See the test.pl script for examples of use.

L<XML.com|http://www.xml.com>

=head1 AUTHOR

Graciliano M. P. C<< <gm at virtuasites.com.br> >>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

Enjoy and thanks for who are enjoying this tool and have sent e-mails! ;-P

=head1 CURRENT MAINTAINER

Harish Madabushi, C<< <harish.tmh at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-smart at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Smart>.  Both the author and the
maintainer will be notified, and then you'll automatically be notified of progress on your bug as changes are made.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Smart

You can also look for information at:

=over 5

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Smart>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Smart>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Smart>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Smart/>

=item * GitHub CPAN

L<https://github.com/harishmadabushi/XML-Smart>

=back

=head1 THANKS

Thanks to Rusty Allen for the extensive tests of CDATA and BINARY handling of XML::Smart.

Thanks to Ted Haining to point a Perl-5.8.0 bug for tied keys of a HASH.

Thanks to everybody that have sent ideas, patches or pointed bugs.

=head1 LICENSE AND COPYRIGHT

Copyright 2003 Graciliano M. P.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


