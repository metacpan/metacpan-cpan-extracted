# Thread::SharedTreeSet
# Version 0.01
# Copyright (C) 2013 David Helkowski

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.  You may also can
# redistribute it and/or modify it under the terms of the Perl
# Artistic License.
  
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

=head1 NAME

Thread::SharedTreeSet - Shared set of recursive hashes/arrays using serialization

=head1 VERSION

0.01

=cut

package Thread::SharedTreeSet;
use threads::shared;
use Thread::Semaphore;
use XML::Bare 0.51;
use strict;

use vars qw( $VERSION );
$VERSION = "0.01";

my @arrs :shared;
my @maxdex :shared;
my @sema :shared;

sub init {
}

sub new {
    my $class = shift;
    my $self = { @_ };
    
    if( !defined $self->{'id'} ) {
        lock( @arrs );
        my $id = $self->{'id'} = $#arrs + 1;
        my $newset = {};
        my $semaset = {};
        share( $newset );
        share( $semaset );
        $arrs[ $id ] = $self->{'set'} = $newset;
        $sema[ $id ] = $self->{'semaset'} = $semaset;
    }
    else {
        lock( @arrs );
        $self->{'set'} = $arrs[ $self->{'id'} ];
        $self->{'semaset'} = $sema[ $self->{'id'} ];
    }
    return bless $self, $class;
}

sub ilock {
    my ( $self, $i ) = @_;
    my $semaset = $self->{'semaset'};
    my $s;
    {
        lock( $semaset );
        $s = $semaset->{ $i };
        if( !$s ) {
            $semaset->{ $i } = Thread::Semaphore->new(0);
        }
    }
    if( $s ) {
        $s->down();
    }
}

sub iunlock {
    my ( $self, $i ) = @_;
    my $semaset = $self->{'semaset'};
    {
        lock( $semaset );
        my $s = $semaset->{ $i };
        if( $s ) {
            $s->up();
            delete $semaset->{ $i };
        }
        else {
            # error
        }
    }
}

sub push {
    my ( $self, $hash ) = @_;
    my $set = $self->{'set'};
    my $xmltext = _hash2xml( $hash );
    {
        lock( $set );
        lock( @maxdex );
        my $max = $maxdex[ $self->{'id'} ]++;
        $set->{ "i_$max" } = $xmltext;
        return "i_$max";
    }
}

sub get {
    my ( $self, $i ) = @_;
    my $set = $self->{'set'};
    my $xmltext;
    {
        lock( $set );
        $xmltext = $set->{ $i };
        return undef if( ! defined $xmltext );
    }
    my ( $ob, $xml ) = XML::Bare->simple( text => $xmltext );
    return $xml;
}

sub set {
    my ( $self, $i, $hash ) = @_;
    my $set = $self->{'set'};
    my $xmltext = _hash2xml( $hash );
    {
        lock( $set );
        $set->{ $i } = $xmltext;
    }
    return 1;
}

sub shift {
    my $self = shift;
    my $set = $self->{'set'};
    my $xmltext;
    {
        lock( $set );
        lock( @maxdex );
        my $max = $maxdex[ $self->{'id'} ]--;
        $xmltext = delete $set->{"i_$max"};
    }
    my ( $ob, $xml ) = XML::Bare->simple( text => $xmltext );
    return $xml;
}

sub shiftn {
    my ( $self, $n ) = @_;
    my $set = $self->{'set'};
    my $xmltext;
    my @ret;
    {
        lock( $set );
        lock( @maxdex );
        my $max = $maxdex[ $self->{'id'} ];
        # TODO
        #return undef if( ( $#$set + 1 ) < $n );
        #$xmltext = CORE::shift @$set;
        #my ( $ob, $xml ) = XML::Bare->new( text => $xmltext );
        #CORE::push( @ret, simplify( $xml ) );
    }
    return \@ret;
}

sub getall {
    my ( $self ) = @_;
    my $set = $self->{'set'};
    my $xmlall = '';
    {
        lock( $set );
        my @keys = keys %$set;
        for my $key ( @keys ) {
            my $xmltext = $set->{ $key };
            $xmlall .= "<$key>$xmltext</$key>";
        }
    }
    my ( $ob, $simple ) = XML::Bare->simple( text => $xmlall );
    return $simple
}

sub get_these {
    my ( $self, $arr ) = @_;
    my $set = $self->{'set'};
    my $xmlall = '';
    {
        lock( $set );
        for my $key ( @$arr ) {
            my $text = $set->{ $key };
            $xmlall .= "<$key>$text</$key>";
        }
    }
    my ( $ob, $simple ) = XML::Bare->simple( text => $xmlall );
    return $simple;
}

sub popall {
    my ( $self, $arr ) = @_;
    my $set = $self->{'set'};
    my $xmlall = '';
    {
        lock( $set );
        my @keys = keys %$set;
        for my $key ( @$arr ) {
            my $text = $set->{ $key };
            $xmlall .= "<$key>$text</$key>";
        }
        %$set = ();
    }
    my ( $ob, $simple ) = XML::Bare->simple( text => $xmlall );
    return $simple;
}

sub _hash2xml {
    my ( $node, $name ) = @_;
    my $ref = ref( $node );
    return '' if( $name && $name =~ m/^\_/ );
    my $txt = $name ? "<$name>" : '';
    if( $ref eq 'ARRAY' ) {
       $txt = '';
       for my $sub ( @$node ) {
           $txt .= _hash2xml( $sub, $name );
       }
       return $txt;
    }
    elsif( $ref eq 'HASH' ) {
       for my $key ( keys %$node ) {
           $txt .= _hash2xml( $node->{ $key }, $key );
       }
    }
    else {
        $node ||= '';
        if( $node =~ /[<]/ ) { $txt .= '<![CDATA[' . $node . ']]>'; }
        else { $txt .= $node; }
    }
    if( $name ) {
        $txt .= "</$name>";
    }
        
    return $txt;
}

1;

__END__

=head1 SYNOPSIS

  use threads;
  use Thread::SharedTree;
  use Data::Dumper;
  
  my $h = Thread::SharedTree->new();
  
  threads->create( 'a', $h->{'id'} );
  threads->create( 'b', $h->{'id'} );
  
  wait_for_threads();
  
  sub a {
      my $hid = shift;
      my $h = Thread::SharedTree->new( id => $hid );
      $h->set( 'a', { test => 'blah' } );
      $h->ilock('a');
      sleep(4);
      $h->iunlock('a');
  }
  
  sub b {
      my $hid = shift;
      my $h = Thread::SharedTree->new( id => $hid );
      sleep(1);
      $h->ilock('a');
      my $data = $h->get('a');
      $h->iunlock('a');
      print Dumper( $data );
  }
  
  sub wait_for_threads {
      while( 1 ) {
          my @joinable = threads->list(0);#joinable
          my @running = threads->list(1);#running
          
          for my $thr ( @joinable ) { $thr->join(); }
          last if( !@running );
          sleep(1);
      }
  }

=head1 DESCRIPTION

Thread::SharedTreeSet makes it possible to share a set of recursive hashes/arrays between threads.
Each shared tree set created has a unique scalar identifier that can be used to fetch that
same shared tree set from another thread.

=head1 LICENSE

  Copyright (C) 2013 David Helkowski
  
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