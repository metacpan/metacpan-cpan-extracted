package Tie::Queue;
###########################################################
# Tie::Queue package
# Gnu GPL2 license
#
# copyright Fabrice Dulaunoy <fabrice@dulaunoy.com> 2009
###########################################################

=head1  Tie::Queue - Introduction

  Tie::Queue - Tie an ARRAY over a TokyTyrant  DB ( see http://tokyocabinet.sourceforge.net )

=head1 SYNOPSIS

  use Tie::Queue;
  use Data::Dumper;

  ## Queue creation
  # This queue is not re-initialised at each execution of the script
  # the default namespace is 'Tie-Queue'
  # and each item are non serialized 
  tie my @a, 'Tie::Queue', '127.0.0.1', 1978, 0;

  # This queue is NOT re-initialised at each execution of the script
  # and each item are non serialized 
  # the namespace is 'second_queue'
  tie my @b, 'Tie::Queue', '127.0.0.1', 1978, 1 , 0 , 'second_queue';

  ## put some data in the queue
  for ( 101 .. 110 )
  {
      push @a, $_;
  }

  for ( 1001 .. 1005 )
  {
      push @ab, $_;
  }

  push @b, 'some text';
  push 
  ## show the content of the queue
  print Dumper( \@a );
  ## print the size of the queue
  print "size of array=". scalar @a. "\n";
  ## remove the latest pushed element from the queue ( the newest)
  $res1 = pop @a;
  print  "latest element $res1\n";
  print "size of array=". scalar @a. "\n";
  print Dumper( \@a );
  $res2 = $a[3];
  print  "element 3 = $res2\n";
  ## remove the first element from the queue ( the oldest )
  $res3 = shift @a;
  print  "first element $res3\n";
  print "size of array=". scalar @a. "\n";
  print Dumper( \@a );
  if ( exists $a[4] )
  {
      print "elem 4 exists\n";
  }
  else
  {
      print "elem 4 NOT exists\n";
  }

  if ( exists $a[40] )
  {
      print "elem 40 exists\n";
  }
  else
  {
      print "elem 40 is NOT existing\n";
  }


  (tied @a)->CLEAR;
  print "size of array=". scalar @a. "\n";

  ########################
  # this queue is re-initialised at each execution of the script
  # and each item are serialized 
  # and the name space is 'third_queue_serialized'
  tie my @c, 'Tie::Queue', '127.0.0.1', 1978, 1 , 1 , 'third_queue_serialized';
  my %test = ( a => 'key_a', b => 'key_B' , c => 3 );
  print Dumper(\%test);
  push @d , \%test;
  my $r = pop @d;
  print Dumper($r)
  #######################


=head1 DESCRIPTION

  Tie an ARRAY over a TokyTyrant DB and allow to push, pop shift  data;
  
  This module require TokyoTyrant (database and perl module.)
  If the serialisation is required, the module Data::Serilizer is also required
  
  The normal ARRAY function present are
  
  push
  pop
  shift
  exists
  scalar
  storesize ( to allow undef @a)
  
  Specific function
  
  CLEAR
  SYNC
  REPAIR
  
  The following function are not implemented.
  
  EXTEND
  STORE
  DELETE
  SPLICE
 
=cut

use 5.008008;
use strict;
use warnings;
use Tie::Array;
require Exporter;

use Carp;
use TokyoTyrant;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

$VERSION = '0.19';

our @ISA = qw( Exporter Tie::StdArray );

=head1 Basic functions
	
I< only the queue relevant functions are present >
	
=head2 tie
	
	Tie an array over a DB
	my $t = tie( my @myarray, "Tie::Queue", '127.0.0.1', 1978, 1 , 1 , 'first_name' ,  1 , 0 );
	
	Six optional parameter are allowed
	    1) the IP where the TokyoTyrant is running ( default 127.0.0.1 )
	    2) the port on which the TokyoTyrant is listenning ( default 1978 )
	    3) a flag to delete at start the DB ( default 0 )
	    4) a flag to serialize/deserialize on the fly the data stored in the DB
	    5) a namespace to allow more than one queue on the same DB ( default Tie-Queue )
	    6) a flag to activate or deactivate auto_sync ( default 1 )
	    7) a flag to prevent undef value to be pushed ( default 0 )
	    8) a flag to use self-healing feature or reset a queue if the data queue is corrupted ( default 0 )
	    9) a flag to add some debug info on correctable error ( default 0 )
	   10) a flag to prevent insertion of duplicate value ( default 0 )
	    
=cut

sub TIEARRAY
{
    my $class = $_[0];
    my %data;

    $data{ _host }            = $_[1]  || '127.0.0.1';
    $data{ _port }            = $_[2]  || 1978;
    $data{ _delete_on_start } = $_[3]  || 0;
    $data{ _serialize }       = $_[4]  || 0;
    $data{ _prefix }          = $_[5]  || 'Tie-Queue';
    $data{ _auto_sync }       = $_[6]  || 1;
    $data{ _no_undef }        = $_[7]  || 0;
    $data{ _clear_on_error }  = $_[8]  || 0;
    $data{ _debug }           = $_[9]  || 0;
    $data{ _no_duplicate }    = $_[10] || 0;

    my $rdb = TokyoTyrant::RDB->new();
    if ( !$rdb->open( $data{ _host }, $data{ _port } ) )
    {
        my $ecode = $rdb->ecode();
        croak( 'Queue open error: ' . $rdb->errmsg( $ecode ) . "\n" );
    }
    else
    {
        $data{ _rdb } = $rdb;
    }

    my $serialiser;
    if ( $data{ _serialize } )
    {
        use Data::Serializer;
        $serialiser = Data::Serializer->new( compress => 0 );
        $data{ _serialize } = $serialiser;
    }
    my $head  = $rdb->get( $data{ _prefix } . 0 );
    my $first = $rdb->get( $data{ _prefix } . 1 ) || 3;
    my $last  = $rdb->get( $data{ _prefix } . 2 ) || 3;
    if ( !$last || !$first || ( $last !~ /^\d+\z/ ) || ( $first !~ /^\d+\z/ ) || $last < $first )
    {
        ( $first, $last ) = REPAIR( \%data );
    }

    if ( defined $head )
    {
        if ( $head !~ /^Tie::Queue$/ )
        {
            carp( "Data in queue corrupted: Wrong Head for " . $data{ _prefix } . "\n" )
              if ( $data{ _debug } );
            if ( $data{ _clear_on_error } )
            {
                $rdb->put( $data{ _prefix } . 0, 'Tie::Queue' );
            }
        }
        else
        {
            if ( $data{ _delete_on_start } )
            {
                for ( my $inx = $first ; $inx <= $last ; $inx++ )
                {
                    $rdb->out( $data{ _prefix } . $inx );
                }
                $rdb->put( $data{ _prefix } . 1, 3 );
                $rdb->put( $data{ _prefix } . 2, 3 );
            }
        }
    }
    else
    {
        if ( defined $first || defined $last )
        {
            carp( "Data in queue corrupted: Data without Head\n" ) if ( $data{ _debug } );
        }
        $rdb->put( $data{ _prefix } . 0, 'Tie::Queue' );
        if ( !$rdb->put( $data{ _prefix } . 1, 3 ) )
        {
            my $ecode = $rdb->ecode();
            carp( 'Could not initialise queue: ' . $rdb->errmsg( $ecode ) . "\n" );
        }
        if ( !$rdb->put( $data{ _prefix } . 2, 3 ) )
        {
            my $ecode = $rdb->ecode();
            carp( 'Could not initialise queue: ' . $rdb->errmsg( $ecode ) . "\n" );
        }
    }

    bless \%data, $class;
    return \%data;
}

=head2 PUSH
	
	Add an element at the end of the array
	push @myarray , 45646;
      
=cut

sub PUSH
{
    my $self  = shift;
    my $value = shift;

    if ( ( defined $value ) || ( !$self->{ _no_undef } ) )
    {
        my $rdb = $self->{ _rdb };
        $value = $self->__serialize__( $value ) if ( $self->{ _serialize } );
        my $first = $rdb->get( $self->{ _prefix } . 1 );
        if ( $first && $first =~ /^\d+\z/ )
        {
            my $last = $rdb->get( $self->{ _prefix } . 2 );

            if ( $last && $last =~ /^\d+\z/ )
            {
                if ( $self->{ _no_duplicate } )
                {

                    for ( my $inx = $first ; $inx <= $last ; $inx++ )
                    {
                        my $item_value = $rdb->get( $self->{ _prefix } . $inx ) || '';
                        return if ( $item_value eq $value );
                    }
                }
                $rdb->put( $self->{ _prefix } . 2,     $last + 1 );
                $rdb->put( $self->{ _prefix } . $last, $value );
            }
            else
            {
                if ( $self->{ _clear_on_error } )
                {
                    $self->CLEAR;
                }
                else
                {
                    $self->REPAIR;
                }
                $self->PUSH( $value );
            }
        }
        else
        {
            if ( $self->{ _clear_on_error } )
            {
                $self->CLEAR;
            }
            else
            {
                $self->REPAIR;
            }
            $self->PUSH( $value );

        }
        $rdb->sync() if ( $self->{ _auto_sync } );
    }
}

=head2 POP
	
	Extract the latest element from the array ( the newest )
	my $data = pop @myarray;
      
=cut

sub POP
{
    my $self = shift;

    my $rdb  = $self->{ _rdb };
    my $last = $rdb->get( $self->{ _prefix } . 2 );
    my $val;
    if ( $last && $last =~ /^\d+\z/ )
    {
        $last--;
        $val = $rdb->get( $self->{ _prefix } . $last );
        $rdb->put( $self->{ _prefix } . 2, $last );
        $rdb->out( $self->{ _prefix } . $last );
        $rdb->sync() if ( $self->{ _auto_sync } );
        $val = $self->__deserialize__( $val ) if ( $self->{ _serialize } );
    }
    else
    {
        if ( $self->{ _clear_on_error } )
        {
            $self->CLEAR;
        }
    }
    return $val;
}

=head2 SHIFT
	
	Extract the first element from the array  ( the oldest )
	my $data = shift @myarray;
      
=cut

sub SHIFT
{
    my $self = shift;

    my $rdb   = $self->{ _rdb };
    my $first = $rdb->get( $self->{ _prefix } . 1 );
    if ( $first && $first =~ /^\d+\z/ )
    {
        my $val = $rdb->get( $self->{ _prefix } . $first );
        $rdb->out( $self->{ _prefix } . $first );
        $rdb->put( $self->{ _prefix } . 1, $first + 1 );
        $rdb->sync() if ( $self->{ _auto_sync } );
        $val = $self->__deserialize__( $val ) if ( $self->{ _serialize } );
        return $val;
    }
    else
    {
        if ( $self->{ _clear_on_error } )
        {
            $self->CLEAR;
        }
    }
}

=head2 EXISTS
	
	Test if an element in the array exist
	print "element exists\n" if (exists $myarray[5]);
      
=cut

sub EXISTS
{
    my $self = shift;
    my $key  = shift;

    my $rdb = $self->{ _rdb };
    return 0 unless ( $rdb->rnum() );
    my $first = $rdb->get( $self->{ _prefix } . 1 ) || 0;
    if ( $first && $first =~ /^\d+\z/ )
    {
        $key += $first;
        my $val = $rdb->get( $self->{ _prefix } . $key );
        if ( defined $val )
        {
            return 1;
        }
    }
    else
    {
        if ( $self->{ _clear_on_error } )
        {
            $self->CLEAR;
        }
    }
}

=head2 FETCH
	
	Retrieve a specific element from the array
	my $data = $myarray[6];
      
=cut

sub FETCH
{
    my $self = shift;
    my $key  = shift;

    my $rdb = $self->{ _rdb };
    my $first = $rdb->get( $self->{ _prefix } . 1 ) || 0;
    if ( $first && $first =~ /^\d+\z/ )
    {
        $key += $first;
        my $val = $rdb->get( $self->{ _prefix } . $key );
        $val = $self->__deserialize__( $val ) if ( $self->{ _serialize } );
        return $val;
    }
    else
    {
        if ( $self->{ _clear_on_error } )
        {
            $self->CLEAR;
        }
    }
}

=head2 FETCHSIZE
	
	Get the size of the array
	my $data = scalar(@myarray);
      
=cut

sub FETCHSIZE
{
    my $self = shift;

    my $rdb   = $self->{ _rdb };
    my $last  = $rdb->get( $self->{ _prefix } . 2 );
    my $first = $rdb->get( $self->{ _prefix } . 1 );
    if ( !$last || !$first || ( $last !~ /^\d+\z/ ) || ( $first !~ /^\d+\z/ ) || $last < $first )
    {
        ( $first, $last ) = $self->REPAIR();
    }
    return $last - $first;
}

=head2 SYNC
	
	Force a sync of the DB ( not usefull is auto_sync is on)
	$t->SYNC;
      
=cut

sub SYNC
{
    my $self = shift;

    my $rdb = $self->{ _rdb };
    $rdb->sync();
}

=head2 CLEAR
	
	Delete all element in the array
	$t->CLEAR;
      
=cut

sub CLEAR
{
    my $self = shift;

    my $rdb = $self->{ _rdb };
    $rdb->iterinit();
    while ( my $item = $rdb->iternext() )
    {
        my $name = $self->{ _prefix };
        next unless $item =~ /^$name\d+$/;
        $rdb->out( $item );
    }

    $rdb->put( $self->{ _prefix } . 0, 'Tie::Queue' );
    $rdb->put( $self->{ _prefix } . 1, 3 );
    $rdb->put( $self->{ _prefix } . 2, 3 );
    $rdb->sync() if ( $self->{ _auto_sync } );
}

=head2 DESTROY
	
	Normal destructor call when untied the array
	Normaly never called by user
	
=cut

sub DESTROY
{
    my $self = shift;

    my $rdb = $self->{ _rdb };
    $rdb->close();
}

=head2 REPAIR
	
	Force a rescan of all elements in the queue and recreate the right indexes
	
=cut

sub REPAIR
{
    my $self = shift;
    my $rdb  = $self->{ _rdb };
    $rdb->sync();
    $rdb->iterinit();
    my $new_start = 3;
    my $new_end   = 3;
    my $tmp;
    while ( my $key = $rdb->iternext() )
    {
        my $name = $self->{ _prefix };
        next unless $key =~ /^$name(\d+)$/;
        $tmp = $1;
        next if ( $tmp < 3 );
        if ( $self->{ _no_undef } )
        {
            my $val = $rdb->get( $key );
            if ( !defined $val )
            {
                $rdb->out( $key );
                $new_start = $tmp if ( $tmp < $new_start );
                $new_end   = $tmp if ( $tmp > $new_end );
            }
        }
        else
        {
            $new_start = $tmp if ( $tmp < $new_start );
            $new_end   = $tmp if ( $tmp > $new_end );
        }
    }
    $rdb->put( $self->{ _prefix } . 1, $new_start );
    $rdb->put( $self->{ _prefix } . 2, $new_end + 1 );
    return $new_start, $new_end;
}

=head1 Functions not Implemented

I< Most of then are not related to a QUEUE >

=head2 UNSHIFT
	
	Not implemented 
	
=cut

sub UNSHIFT { carp "no UNSHIFT function"; }

=head2 EXTEND
	
	Not implemented
	
=cut

sub EXTEND { carp "no EXTEND function"; }

=head2 STORE
	
	Not implemented
	
=cut

sub STORE { carp "no STORE function"; }

=head2 STORESIZE
	
	to  resize the array ( this allow a re-initialisation of the array by undef @a )
	
=cut

sub STORESIZE
{
    my $self     = shift;
    my $new_size = shift;

    my $rdb   = $self->{ _rdb };
    my $first = $rdb->get( $self->{ _prefix } . 1 );
    my $last  = $rdb->get( $self->{ _prefix } . 2 );
    if ( $first && $last && $first =~ /^\d+\z/ && $last =~ /^\d+\z/ )
    {
        for ( ( $first + $new_size ) .. $last )
        {
            $self->POP;
        }
        $rdb->sync() if ( $self->{ _auto_sync } );
        $rdb->put( $self->{ _prefix } . 2, $first + $new_size );
    }
    return $last - $first;
}

=head2 DELETE
	
	Not implemented
	
=cut

sub DELETE { carp "no DELETE function"; }

########################
# internal function
########################

sub __serialize__
{
    my $self = shift;
    my $val  = shift;

    my $serializer = $self->{ _serialize };
    return $serializer->serialize( $val ) if $val;
    return $val;
}

sub __deserialize__
{
    my $self = shift;
    my $val  = shift;

    my $serializer = $self->{ _serialize };
    return $serializer->deserialize( $val ) if $val;
    return $val;
}

1;
__END__
		

=head1 AUTHOR

	Fabrice Dulaunoy <fabrice_at_dulaunoy_dot_com> 
	

=head1 SEE ALSO

        - TokyoTyrant from Mikio Hirabayashi <mikio_at_users_dot_sourceforge_dot_net>


=head1 TODO

        - make test
	
=head1 LICENSE

	Under the GNU GPL2

	This program is free software; you can redistribute it and/or modify it 
	under the terms of the GNU General Public 
	License as published by the Free Software Foundation; either version 2 
	of the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful, 
	but WITHOUT ANY WARRANTY;  without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
	See the GNU General Public License for more details.

	You should have received a copy of the GNU General Public License 
	along with this program; if not, write to the 
	Free Software Foundation, Inc., 59 Temple Place, 
	Suite 330, Boston, MA 02111-1307 USA

	Tie::Queue  Copyright (C) 2009 DULAUNOY Fabrice  
	Tie::Queue comes with ABSOLUTELY NO WARRANTY; 
	for details See: L<http://www.gnu.org/licenses/gpl.html> 
	This is free software, and you are welcome to redistribute 
	it under certain conditions;
   
   
=cut
