package XML::ED::Bare;

use Carp;
use strict;
use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use utf8;
require Exporter;
require DynaLoader;
@ISA = qw(DynaLoader);

$VERSION = "0.0.2";

use vars qw($VERSION *AUTOLOAD);

*AUTOLOAD = \&XML::ED::Bare::AUTOLOAD;
bootstrap XML::ED::Bare $VERSION;

=head1 NAME

XML::ED::Bare - Minimal XML parser implemented via a C state engine

=head1 VERSION

0.45

=cut

sub new {
  my $class = shift; 
  my $self  = { @_ };
  
  if( $self->{ 'text' } ) {
    XML::ED::Bare::c_parse( $self->{'text'} );
  }
  else {
    my $res = open( XML, $self->{ 'file' } );
    if( !$res ) {
      $self->{ 'xml' } = 0;
      return 0;
    }
    {
      local $/ = undef;
      $self->{'text'} = <XML>;
    }
    close( XML );
    XML::ED::Bare::c_parse( $self->{'text'} );
  }
  bless $self, $class;
  return $self if( !wantarray );
  return ( $self, $self->parse() );
}

sub DESTROY {
  my $self = shift;
  undef $self->{'xml'};
}

# Load a file using XML::ED::DOM, convert it to a hash, and return the hash
sub parse {
  my $self = shift;
  
  my $res = XML::ED::Bare::xml2obj();
  $self->{'structroot'} = XML::ED::Bare::get_root();
  $self->free_tree();
  
  if( defined( $self->{'scheme'} ) ) {
    $self->{'xbs'} = new XML::ED::Bare( %{ $self->{'scheme'} } );
  }
  if( defined( $self->{'xbs'} ) ) {
    my $xbs = $self->{'xbs'};
    my $ob = $xbs->parse();
    $self->{'xbso'} = $ob;
    readxbs( $ob );
  }
  
  if( $res < 0 ) { croak "Error at ".$self->lineinfo( -$res ); }
  $self->{ 'xml' } = $res;
  
  if( defined( $self->{'xbso'} ) ) {
    my $ob = $self->{'xbso'};
    my $cres = $self->check( $res, $ob );
    croak( $cres ) if( $cres );
  }
  
  return $self->{ 'xml' };
}

sub lineinfo {
  my $self = shift;
  my $res  = shift;
  my $line = 1;
  my $j = 0;
  for( my $i=0;$i<$res;$i++ ) {
    my $let = substr( $self->{'text'}, $i, 1 );
    if( ord($let) == 10 ) {
      $line++;
      $j = $i;
    }
  }
  my $part = substr( $self->{'text'}, $res, 10 );
  $part =~ s/\n//g;
  $res -= $j;
  if( $self->{'offset'} ) {
    my $off = $self->{'offset'};
    $line += $off;
    return "$off line $line char $res \"$part\"";
  }
  return "line $line char $res \"$part\"";
}

# xml bare schema
sub check {
  my ( $self, $node, $scheme, $parent ) = @_;
  
  my $fail = '';
  if( ref( $scheme ) eq 'ARRAY' ) {
    for my $one ( @$scheme ) {
      my $res = $self->checkone( $node, $one, $parent );
      return 0 if( !$res );
      $fail .= "$res\n";
    }
  }
  else { return $self->checkone( $node, $scheme, $parent ); }
  return $fail;
}

sub checkone {
  my ( $self, $node, $scheme, $parent ) = @_;
  
  for my $key ( keys %$node ) {
    next if( substr( $key, 0, 1 ) eq '_' || $key eq '_att' || $key eq 'comment' );
    if( $key eq 'value' ) {
      my $val = $node->{ 'value' };
      my $regexp = $scheme->{'value'};
      if( $regexp ) {
        if( $val !~ m/^($regexp)$/ ) {   
          my $linfo = $self->lineinfo( $node->{'_i'} );
          return "Value of '$parent' node ($val) does not match /$regexp/ [$linfo]";
        }
      }
      next;
    }
    my $sub = $node->{ $key };
    my $ssub = $scheme->{ $key };
    if( !$ssub ) { #&& ref( $schemesub ) ne 'HASH'
      my $linfo = $self->lineinfo( $sub->{'_i'} );
      return "Invalid node '$key' in xml [$linfo]";
    }
    if( ref( $sub ) eq 'HASH' ) {
      my $res = $self->check( $sub, $ssub, $key );
      return $res if( $res );
    }
    if( ref( $sub ) eq 'ARRAY' ) {
      my $asub = $ssub;
      if( ref( $asub ) eq 'ARRAY' ) {
        $asub = $asub->[0];
      }
      if( $asub->{'_t'} ) {
        my $max = $asub->{'_max'} || 0;
        if( $#$sub >= $max ) {
          my $linfo = $self->lineinfo( $sub->[0]->{'_i'} );
          return "Too many nodes of type '$key'; max $max; [$linfo]"
        }
        my $min = $asub->{'_min'} || 0;
        if( ($#$sub+1)<$min ) {
          my $linfo = $self->lineinfo( $sub->[0]->{'_i'} );
          return "Not enough nodes of type '$key'; min $min [$linfo]"
        }
      }
      for( @$sub ) {
        my $res = $self->check( $_, $ssub, $key );
        return $res if( $res );
      }
    }
  }
  if( my $dem = $scheme->{'_demand'} ) {
    for my $req ( @{$scheme->{'_demand'}} ) {
      my $ck = $node->{ $req };
      if( !$ck ) {
        my $linfo = $self->lineinfo( $node->{'_i'} );
        return "Required node '$req' does not exist [$linfo]"
      }
      if( ref( $ck ) eq 'ARRAY' ) {
        my $linfo = $self->lineinfo( $node->{'_i'} );
        return "Required node '$req' is empty array [$linfo]" if( $#$ck == -1 );
      }
    }
  }
  return 0;
}


sub readxbs { # xbs = xml bare schema
  my $node = shift;
  my @demand;
  for my $key ( keys %$node ) {
    next if( substr( $key, 0, 1 ) eq '_' || $key eq '_att' || $key eq 'comment' );
    if( $key eq 'value' ) {
      my $val = $node->{'value'};
      delete $node->{'value'} if( $val =~ m/^\W*$/ );
      next;
    }
    my $sub = $node->{ $key };
    
    if( $key =~ m/([a-z_]+)([^a-z_]+)/ ) {
      my $name = $1;
      my $t = $2;
      my $min;
      my $max;
      if( $t eq '+' ) {
        $min = 1;
        $max = 1000;
      }
      elsif( $t eq '*' ) {
        $min = 0;
        $max = 1000;
      }
      elsif( $t eq '?' ) {
        $min = 0;
        $max = 1;
      }
      elsif( $t eq '@' ) {
        $name = 'multi_'.$name;
        $min = 1;
        $max = 1;
      }
      elsif( $t =~ m/\{([0-9]+),([0-9]+)\}/ ) {
        $min = $1;
        $max = $2;
        $t = 'r'; # range
      }
      
      if( ref( $sub ) eq 'HASH' ) {
        my $res = readxbs( $sub );
        $sub->{'_t'} = $t;
        $sub->{'_min'} = $min;
        $sub->{'_max'} = $max;
      }
      if( ref( $sub ) eq 'ARRAY' ) {
        for my $item ( @$sub ) {
          my $res = readxbs( $item );
          $item->{'_t'} = $t;
          $item->{'_min'} = $min;
          $item->{'_max'} = $max;
        }
      }
      
      push( @demand, $name ) if( $min );
      $node->{$name} = $node->{$key};
      delete $node->{$key};
    }
    else {
      if( ref( $sub ) eq 'HASH' ) {
        readxbs( $sub );
        $sub->{'_t'} = 'r';
        $sub->{'_min'} = 1;
        $sub->{'_max'} = 1;
      }
      if( ref( $sub ) eq 'ARRAY' ) {
        for my $item ( @$sub ) {
          readxbs( $item );
          $item->{'_t'} = 'r';
          $item->{'_min'} = 1;
          $item->{'_max'} = 1;
        }
      }
      
      push( @demand, $key );
    }
  }
  if( @demand ) { $node->{'_demand'} = \@demand; }
}

sub free_tree { my $self = shift; XML::ED::Bare::free_tree_c( $self->{'structroot'} ); }

1;

__END__

=head1 SYNOPSIS

  use XML::ED::Bare;
  
  my $ob = new XML::ED::Bare( text => '<xml><name>Bob</name></xml>' );
  
=head2 Module Functions

=over 2

=item * C<< $ob = new XML::ED::Bare( text => "[some xml]" ) >>

Create a new XML object, with the given text as the xml source.

=item * C<< $tree = $object->parse() >>

Parse the xml of the object and return a tree reference

=back

=head2 Functions Used Internally

=over 2

=item * C<< check() checkone() readxbs() free_tree_c() >>

=item * C<< lineinfo() c_parse() c_parsefile() free_tree() xml2obj() >>

=item * C<< obj2xml() get_root() obj2html() xml2obj_simple() >>

=back

=head1 LICENSE

  Copyright (C) 2008 David Helkowski
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 2 of the
  License, or (at your option) any later version.  You may also can
  redistribute it and/or modify it under the terms of the Perl
  Artistic License.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

=cut
