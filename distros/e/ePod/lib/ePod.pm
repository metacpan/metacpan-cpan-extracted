#############################################################################
## Name:        ePod.pm
## Purpose:     ePod - easy-POD converter to POD.
## Author:      Graciliano M. P. 
## Modified by:
## Created:     2004-01-13
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P. 
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package ePod ;
use 5.006 ;

use strict qw(vars);
no warnings ;

use vars qw($VERSION @ISA) ;

$VERSION = '0.05' ;

require Exporter;
@ISA = qw(Exporter);

our @EXPORT = qw(to_pod epod2pod) ;
our @EXPORT_OK = @EXPORT ;

########
# VARS #
########

  my $OVER_SIZE_DEF = 4 ;
  
  my $OVER_SIZE = $OVER_SIZE_DEF ;

#######
# NEW #
#######

sub new {
  my $this = shift ;
  return( $this ) if ref($this) ;
  my $class = $this || __PACKAGE__ ;
  $this = bless({} , $class) ;
  
  my ( %args ) = @_ ;
  
  foreach my $Key ( keys %args ) {
    my $k = $Key ;
    $k =~ s/[\W_]//gs ; $k = uc($k) ;
    $this->{$k} = $args{$Key} ;
  }
  
  $this->{OVERSIZE} = $OVER_SIZE_DEF if !$this->{OVERSIZE} || $this->{OVERSIZE} !~ /^\d+$/s ;

  return $this ;
}

##########
# TO_POD #
##########

sub to_pod {
  my $this = UNIVERSAL::isa($_[0] , 'ePod') ? shift : undef ;
  $this = ePod->new() if !$this ;
  
  my ($data , $file) ;
  
  if ( ref($_[0]) eq 'GLOB' ) {
    1 while( read($_[0], $data , 1024*8 , length($data) ) ) ;
    shift ;
  }
  elsif ( $_[0] !~ /[\r\n]/s && -s $_[0] ) {
    $file = shift ;
    open (my $fh,$file) ; binmode($fh) ;
    1 while( read($fh, $data , 1024*8 , length($data) ) ) ;
    close ($fh) ;
  }
  else { $data = shift ;}
  
  my $new_file = ( $_[0] =~ /\.pod$/i && $_[0] !~ /[\r\n]/s ) ? shift : $file ;
  my $replace = shift ;
  
  if ($new_file eq '') { 'unamed' ;}

  $new_file =~ s/\.epod$/.pod/i ;
  if ( $new_file !~ /\.pod$/i) { $new_file .= '.pod' ;}
  
  while ( !$replace && -e $new_file ) {
    $new_file =~ s/(?:-?(\d+))?(\.pod)$/ my $n = $1 + 1 ; "-$n$2" /gei ;
  }

  $data = $this->epod2pod($data) ;

  open (my $fh,">$new_file") ; binmode($fh) ;
  print $fh $data ;
  close ($fh) ;
  
  if ( wantarray ) { return( $new_file , $data ) ;}
  return $new_file ;
}

############
# EPOD2POD #
############

sub epod2pod {
  my $this = UNIVERSAL::isa($_[0] , 'ePod') ? shift : undef ;
  $this = ePod->new() if !$this ;
  
  $OVER_SIZE = $this->{OVERSIZE} ;
  
  my ($data , $fh , $no_close) ;
  if ( ref($_[0]) eq 'GLOB' ) { $fh = $_[0] ; $no_close = 1 ;}
  elsif ( $_[0] =~ /[\r\n]/s && !-e $_[0] ) { $data = $_[0] ;}
  else { open ($fh,$_[0]) ;}
  
  if ( $fh ) {
    binmode($fh) ;
    1 while( read($fh, $data , 1024*8 , length($data) ) ) ;
    close ($fh) if !$no_close ;
  }

  $data =~ s/\r\n?/\n/gs ;
  
  $data = "\n\n$data\n" ;
  
  $data =~ s/(\S)[ \t]+\n/$1\n/gs ;
  
  1 while( $data =~ s/(\n\S[^\n]*)(?:\n[ \t]*){2,}(\n\S[^\n]*\n)/$1\n$2/gxs );

  1 while( $data =~ s/((?:^|\n)\S[^\n]*\n)([ \t]+\n)+/
    my $init = $1 ;
    my $ns = $2 ;
    $ns =~ s~[ \t]~~gs ;
    "$init$ns"
  /gexs ) ;
  
  $data =~ s/\n=((?:head\d+|item)\s)/\n=EPOD_FIX_$1/gs ;
  
  $data =~ s/\n(?:=(>+)|(=+)>)[ \t]*/ my $n = length($1||$2) ; "\n=head$n " /ges ;
  
  my @blocks = split(/\n+=head[ \t]*/s , $data) ;
  foreach my $blocks_i ( @blocks ) {
    $blocks_i = adjust_spaces($blocks_i) ;
    $blocks_i = adjust_itens($blocks_i) ;
    $blocks_i = adjust_itens($blocks_i) ;
  }
  $data = join("\n=head", @blocks) ;
  
  return undef if $data !~ /\S/s ;
  
  $data =~ s/\n=EPOD_FIX_(\w+)/\n=$1/gs ;

  $data =~ s/\n(=\w)/\r$1/gs ;

  $data =~ s/((?:\r|^)=\w+[^\r\n]*)\n+/$1\r\n\n/gs ;
  
  $data =~ s/\r\n\n\r/\n\n/gs ;
  $data =~ s/\r(=\w)/\n$1/gs ;
  $data =~ s/\r//gs ;
  
  $data =~ s/^\s*/\n\n/s ;
  
  $data =~ s/^\s*/\n\n=pod\n\n/s if $data !~ /^\s*?\n=\w+\s/s ;
  
  $data =~ s/\s*$/\n\n=cut\n\n/s if $data !~ /\n=cut\s*$/ ;

  return $data ;
}

###########
# IS_EPOD #
###########

sub is_epod {
  if ( $_[0] =~ /(?:[\r\n]|^)(?:=+>|=>+|\*+>|\*>+)[^>]/ ) { return 1 ;}
  return 1 ;
}

#################
# ADJUST_SPACES #
#################

sub adjust_spaces {
  my $block = shift ;
  my ( $not_init ) = @_ ;
  $block =~ s/^((?:[^\n]+\n))\n*/$1\n\n/s if !$not_init ;
  $block =~ s/\n*$/\n/s ;
  return( $block ) ;
}

################
# ADJUST_ITENS #
################

sub adjust_itens {
  my $block = shift ;
  my $level = shift ;

  {
    my (@items) = ( $block =~ /(?:\n|^)
                              (
                                \/?
                                (?:
                                  \*>+
                                  |
                                  \*+>
                                )
                                |
                                \*+\/
                              )
                              /sxg ) ;
  
    return( $block ) if !@items ;
    
    if ( !$level ) {
      foreach my $items_i ( @items ) {
        my ($n1,$n2) = ( $items_i =~ /^(?:(\*+)>|\*(>+))$/ );
        my $n = length($n1 || $n2)  ;
        next if !$n ;
        $level = $n ;
        last ;
      }
    }
    else {
      my $min_level ;
      
      foreach my $items_i ( @items ) {
        my ($n1,$n2) = ( $items_i =~ /^(?:(\*+)>|\*(>+))$/ );
        my $n = length($n1 || $n2)  ;
        next if !$n ;
        $min_level = $n if $n < $min_level || !$min_level ;
      }
  
      if ( $min_level > $level ) { $level = $min_level ;}
    }
  }
  
  $level = 1 if $level < 1 ;  

  ##########################

  my ($block_itens , $block_rest) = split(/
  \n
  (?:
    \/\*>{$level}
    |
    \/\*{$level}>
    |
    \*{$level}\/
  )
  [^>]
  \n*
  /sx , "$block\n" , 2) ;
  
  if ( $block_rest ) { $block_rest =~ s/\n$//s ;}
  else { $block_itens =~ s/\n$//s ;}
  
  $block_itens =~ s/\n=(item\s)/\n=EPOD_FIX_$1/gs ;
  
  ##########################

  $block_itens =~ s/
  (?:\n|^)
  (?:
    \*>{$level}
    |
    \*{$level}>
  )
  ([^>])
  [ \t]*
  /\n=item$1/gsx ;
  
  ##########################

  my @itens = split(/\n+=item[ \t]*/s , $block_itens) ;
  
  my $top = shift(@itens) ; 
  
  foreach my $itens_i ( @itens ) {
    $itens_i = adjust_spaces($itens_i) ;
    $itens_i = adjust_itens($itens_i , $level+1) ;
  }
  
  if ( $top =~ /(?:\n|^)(?:\*+>|\*>+)[^>]/s ) {
    $top = adjust_itens( adjust_spaces($top,1) ) ;
  }
  
  $top =~ s/\s*$/\n\n=over $OVER_SIZE\n/s if @itens ;

  $itens[ $#itens ] =~ s/\s*$/\n\n=back\n/s if @itens ;

  $block_rest = adjust_itens( adjust_spaces($block_rest,1) ) if $block_rest ;
  $block_rest =~ s/^\s*/\n/s ;
  
  $block = join("\n=item ", $top , @itens ) . $block_rest ;
  
  $block = adjust_spaces($block , 1) ;
  
  return $block ;
}

#######
# END #
#######

1;


__END__

=head1 NAME

ePod - Handles easy-POD: write easy and simple, convert to POD, and from there you know the way.

=head1 DESCRIPTION

This module is used to conver easy-POD files to POD.

easy-POD is a simplier version of POD, and is made to write POD files without worry about:

=over 10

=item Lines and spaces between commands.

=item The use of =over and =back for itens.

=item Case sensitive of X<> formatters.

=back

Soo, easy-POD let you make some mistakes when writing POD, than it will fixe them for you when converting to POD.

Actually ePod was created to enable non-programmer persons to writed well formated, structured and indexed documentation, and was inspirated in POD.

I<** See .epod files in the "B<./test>" directory of the distribution.>

=head1 USAGE

  use ePod ;

  my $epod = new ePod( over_size => 10 ) ;

  my $pod = $epod->epod2pod( "Foo.epod" ) ;

  print $pod ;

=head1 METHODS

=head2 new ( %OPTIONS )

Create a new I<ePod> object.

B<OPTIONS:>

=over 10

=item over_size ( N )

Set the size/level of I<"=over N">, where I<N> is a number.

=back

=head2 epod2pod ( FILE|DATA|FILEHANDLE )

Convert the given ePod FILE|DATA|GLOB to POD.

=over 10

=item FILE|DATA|FILEHANDLE

Can be a FILE path, DATA (SCALAR) or FILEHANDLE (GLOB)

=back

=head2 to_pod ( FILE|DATA|FILEHANDLE , NEW_POD_FILE , REPLACE )

Convert the given ePod FILE|DATA|GLOB to a POD file.

=over 10

=item FILE|DATA|FILEHANDLE

Can be a FILE path, DATA (SCALAR) or FILEHANDLE (GLOB)

=item NEW_POD_FILE

The file path to the new pod file. If not defined will use the same path and name from the ePod file, or I<"unamed.pod">.

=item REPLACE

If I<TRUE> tells to that the file (I<NEW_POD_FILE>) can be replaced.

If I<FALSE|undef> and the file already exists this format will be used: "%name-%x.pod", where I<%name> is the file name and I<%x> is a number free.

=back

=head2 is_epod (DATA)

Check if a given DATA has ePod syntax.

=head1 easy-POD Syntax

=over 10

=item =headx

Use => for the I<head> command, and the level is set with I<"=">.

  =>   same as =head1
  ==>  same as =head2
  ===> same as =head3

=item =item

Use *> for the =item command, and the level is set with I<"*">.

Note that you don't need to declare =over and =back to use *>.

Example:

  *> item1
  item2 text
  **> item1.1

  *> item2
  item2 text
  
  **> item2.1
  ***> item2.1.1
  *> item3

Equivalent POD:

  =over 10
  
  =item item1
  
  item2 text
  
  =over 10
  
  =item item1.1
  
  =back
  
  =item item2
  
  item2 text
  
  =over 10
  
  =item item2.1
  
  =over 10
  
  =item item2.1.1
  
  =back
  
  =back
  
  =item item3
  
  =back

=item Explicity end of a item:

To explicity end a item, use I<"/"> before the item level. Soo to end *> will be /*>, and for **> is /**>

You need to explocity end a item only when you want a text after an item outside of it. Example:

  *> item1
  the item text.
  *> item2
  the item text again.
  
  and more item text.
  /*>
  
  Text outside of itens.

Equivalent POD:

  =over 10
  
  =item item1
  
  the item text.
  
  =item item2
  
  the item text again.
  
  and more item text.
  
  =back
  
  Text outside of itens.

=back

B<Note that if you want to use POD syntax with easy-POD you won't be able to use =head and =item commands.>

B<All the other POD syntax can be used with easy-POD syntax.>

=head1 SEE ALSO

L<Pod::HtmlEasy>, L<Pod::Parser>, L<Pod::Master>, L<Pod::Master::Html>.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


