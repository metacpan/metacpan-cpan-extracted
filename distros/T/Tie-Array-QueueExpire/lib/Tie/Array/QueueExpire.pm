package Tie::Array::QueueExpire;
###########################################################
# Tie::Array::QueueExpire package
# Gnu GPL2 license
#
#
# Fabrice Dulaunoy <fabrice@dulaunoy.com>
###########################################################
# ChangeLog:
#
###########################################################

=head1  NAME

  Tie::Array::QueueExpire - Introduction


  Tie an ARRAY over a SQLite  DB with expiration of elements
  Revision: 1.03

=head1 SYNOPSIS

  use Tie::Array::QueueExpire;
  use Data::Dumper;
  my $t = tie( my @myarray, "Tie::Array::QueueExpire", '/tmp/db_test.bdb' );
  push @myarray, int rand 1000;
  
  # normal ARRAY function
  my $data = shift @myarray;
  my $data = pop @myarray;
  print "this elem exists\n"  if (exists( $myarray[6]));
  print "size = ". scalar( @myarray )."\n";
  
  # using the PUSH with an extra parameter to put the new element in futur
  # also return the key of the inserted value
  for ( 1 .. 10 )
  {
    say  "t=".time.'  '.  int (($t->PUSH( $_ . ' ' . time, 10 ))/1000);
    sleep 1;
  }
  sleep 10;  
  # Get the expired elements ( 7 seconds before now )
  my $ex = $t->EXPIRE( 7 );
 
  # Get the expired elements
  my @EXP = @{$t->EXPIRE($exp)};
  # Get and delete the expired elements ( 20 seconds before now )
  $ex =  $t->EXPIRE(20,1);
  my @EXP = @{$t->EXPIRE($exp,1)};
  
  # fetch element
  # in scalar context return the value 
  # in array context return in first element the key and in second, the value
  my $a =$t->FETCH(6);
  my @b = $t->FETCH(6);
  # the normal array fetch is always in scalar mode
  my @c=$myarray[6];
  say Dumper( $a );
  say Dumper( \@b );
  say Dumper( \@c );
  # a convenient way to get all the elements from the array directly by the object
  my @all = $t->SLICE();
  
=head1 DESCRIPTION

  Tie an ARRAY over a TokyCabinet Btree DB and allow to get or deleted expired data;
  
  This module require Time::HiRes, TokyoCabinet (database and perl module.)
  The insertion is ms unique ( 0.001 seconds )
  
  The normal ARRAY function present are
  
  push    PUSH   ( the object call allow to PUSH data with a specific expiration offset )
  pop     POP    ( the object call return when called in ARRAY context an array with [ key, value ] )
  shift   SHIFT  ( the object call return when called in ARRAY context an array with [ key, value ] )
  exists  EXISTS
  scalar  FETCHSIZE
  clear
  unshift  ( but put data 1 micro-second before the first entry)
  DESTROY

  The following function is not completely iplemented.
  
  splice SPLICE (no replacement allowed and  the object call return when called in ARRAY context an array with [ key, value ] )

  
  The following function are not implemented.
  
  extend
  store
  STORESIZE

  The following function are specific of this module.
  
  EXPIRE
  PUSH
  FETCH
  SLICE
  SPLICE
  CLEAR
 
=cut

use 5.008008;
use strict;
use warnings;
use Tie::Array;
use Time::HiRes qw{ gettimeofday };
require Exporter;

use Carp;
use DBI;
use DBD::SQLite;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

$VERSION = '1.04';
# use Data::Dumper;

our @ISA = qw( Exporter Tie::StdArray );

=head1 Basic ARRAY functions
	
I< >
	
=head2 tie
	
	
	Tie an array over a TokyoCabinet DB
	my $t = tie( my @myarray, "Tie::Array::QueueExpire", '/tmp/db_test.bdb' );
	The fist parameter if the TokyoCabinet file used (or created)
        Four optional parameter are allowed
	In place two, a flag to serialize the data in the DB
	In place three, an octal MASK allow to set the permission of the DB created
		The default permission is 0600 (-rw-------) 
        In place four a parameter to delete the DB file, if present, at start
       		The default value is 0 (don't delete the file)
      
=cut

sub TIEARRAY
{
    my $class = $_[0];
    my %data;
    $data{ _file }            = $_[1];
    $data{ _serialize }       = $_[2] || 0;
    $data{ _mode }            = $_[3] || 0600;
    $data{ _delete_on_start } = $_[4] || 0;

    my $serialiser;
    if ( $data{ _serialize } )
    {
        use Data::Serializer;
        $serialiser = Data::Serializer->new( compress => 0 );
        $data{ _serialize } = $serialiser;
    }
    my $dbfile = $data{ _file };
    unlink $dbfile if ( -f $dbfile && $data{ _delete_on_start } );
    my $dbh            = DBI->connect( "dbi:SQLite:dbname=$dbfile", "", "" );
    my $sql_list_table = "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;";
    my $ary_ref        = $dbh->selectall_hashref( $sql_list_table, 'name' );
    unless ( exists( $ary_ref->{ 'queue' } ) )
    {
        my $sql = "CREATE TABLE queue( key text , val text );";
        my $res = $dbh->do( $sql );
    }
    my $mode = $data{ _mode };
    chmod $mode, $data{ _file };
    $data{ _bdb } = $dbh;
    bless \%data, $class;
    return \%data;
}

=head2 FETCH
	
	Retrieve a specific key from the array
	my $data = $myarray[6];
	or
	my $data = $t->FETCH(6);
	or 
	my @data = $t->FETCH(6);
	where 
	  $data[0] = insertion key
	and 
	  $data[1] = value 
      
=cut

sub FETCH
{
    my $self = shift;
    my $key  = shift || 0;
    if ( $key < 0 )
    {
        $key += $self->FETCHSIZE();
    }
    $key++;
    my $dbh      = $self->{ _bdb };
    my $sql_view = "CREATE TEMP VIEW head_fetch AS   SELECT  * FROM queue ORDER BY key LIMIT $key;";
    my $res      = $dbh->do( $sql_view );
    my $count    = $dbh->selectall_arrayref( "SELECT COUNT(*) FROM head_fetch;" );
    if ( ( $count->[0][0] ) < $key )
    {
        $res = $dbh->do( "DROP VIEW head_fetch " );
        if ( wantarray )
        {
            return undef, undef;
        }
        else
        {
            return undef;
        }
    }
    my $sql = "SELECT  * FROM head_fetch ORDER BY key DESC LIMIT 1;";
    my $row = $dbh->selectall_arrayref( $sql );
    my $ticks = $row->[0][0];
    my $val   = $row->[0][1];
    $val = $self->__deserialize__( $val ) if ( $self->{ _serialize } );
    $res = $dbh->do( "DROP VIEW head_fetch " );
    if ( wantarray )
    {
        return $ticks, $val;
    }
    else
    {
        return $val;
    }
}

=head2 FETCHSIZE
	
	Get the size of the array
	my $data = scalar(@myarray);
      
=cut

sub FETCHSIZE
{
    my $self = shift;
    my $dbh  = $self->{ _bdb };
    my $row  = $dbh->selectrow_hashref( "select count(*) from queue;" );
    return $row->{ 'count(*)' };
}

=head2 PUSH
	
	Add an element at the end of the array
	push @myarray , 45646;
	or 
	$t->PUSH( 'some text' );
	it is also possible to add an elemnt with a offset expiration 
	$t->PUSH( 'some text in futur' , 10 );
	add element in the array to be expired in 10 seconds
	if the offset is negative, add the expiration in past
      
=cut

sub PUSH
{
    my $self  = shift;
    my $value = shift;
    my $time  = shift || 0;
    my $dbh   = $self->{ _bdb };
    $value = $self->__serialize__( $value ) if ( $self->{ _serialize } );
    my ( $sec, $usec ) = gettimeofday;
    $sec += $time if ( $time != 0 );
    my $key = sprintf( "%010d%06d", $sec, $usec );
    my $sql = "INSERT INTO queue ( key , val ) VALUES ( '$key','$value' );";
    my $res = $dbh->do( $sql );
    return $key;
}

=head2 EXISTS
	
	Test if en element in the array exist
	print "element exists\n" if (exits $myarray[5]);
	return the insertion key
      
=cut

sub EXISTS
{
    my $self = shift;
    my $key  = shift;
    my $dbh  = $self->{ _bdb };
    return ( $self->FETCH( $key ) );
}

=head2 POP
	
	Extract the latest element from the array (the youngest)
	my $data = pop @myarray;
      	or
	my $data = $t->POP();
	or 
	my @data = $t->POP();
	where 
	  $data[0] = insertion key
	and 
	  $data[1] = value 
=cut

sub POP
{
    my $self = shift;
    my $dbh  = $self->{ _bdb };
    my $sql = "SELECT  * FROM queue ORDER BY key DESC LIMIT 1;";
    my $row = $dbh->selectall_arrayref( $sql );
    my $ticks = $row->[0][0];
    my $val   = $row->[0][1];
    $val = $self->__deserialize__( $val ) if ( $self->{ _serialize } );
    my $sql_del = "DELETE FROM queue WHERE key = $ticks;";
    my $res     = $dbh->do( $sql_del );
    if ( wantarray )
    {
        return $ticks, $val;
    }
    else
    {
        return $val;
    }
}

=head2 SHIFT
	
	Extract the first element from the array  (the oldest)
	my $data = shift @myarray;
	or
	my $data = $t->SHIFT();
	or 
	my @data = $t->SHIFT();
       where 
	  $data[0] = insertion key
	and 
	  $data[1] = value 
=cut

sub SHIFT
{
    my $self = shift;
    my $dbh  = $self->{ _bdb };
    my $sql  = "SELECT  * FROM queue ORDER BY key  LIMIT 1;";
    my $row  = $dbh->selectall_arrayref( $sql );
    my $ticks = $row->[0][0];
    my $val   = $row->[0][1];
    $val = $self->__deserialize__( $val ) if ( $self->{ _serialize } );
    my $sql_del = "DELETE FROM queue WHERE key = $ticks;";
    my $res     = $dbh->do( $sql_del );
    if ( wantarray )
    {
        return $ticks, $val;
    }
    else
    {
        return $val;
    }
}

=head2 UNSHIFT
	
	Add an element in the front of the array
	unshift @myarray , 45646;
	UNSHIFT data 1 mili-second before the first item
	
=cut

sub UNSHIFT
{
    my $self  = shift;
    my $value = shift;
    my $dbh   = $self->{ _bdb };
    my ( $k, $val ) = $self->FETCH( 0 );
    my $sec = substr $k, 0, 10;
    my $usec = substr $k, 10;
    $usec--;
    my $key = sprintf( "%010d%06d", $sec, $usec );
    $value = $self->__serialize__( $value ) if ( $self->{ _serialize } );
    my $sql = "INSERT INTO queue ( key , val ) VALUES ( '$key','$value' );";
    my $res = $dbh->do( $sql );
    return $key;
}

=head2 CLEAR
	
	Delete all element in the array
	$t->CLEAR;
      
=cut

sub CLEAR
{
    my $self    = shift;
    my $dbh     = $self->{ _bdb };
    my $sql_del = "DELETE FROM queue;";
    my $res     = $dbh->do( $sql_del );
    return $res;
}

=head2 DESTROY
	
	Normal destructor call when untied the array
	Normaly never called by user
	
=cut

sub DESTROY
{
    my $self = shift;
    my $dbh  = $self->{ _bdb };
    $dbh->disconnect;
}

=head1 Specific functions from this module

I< >

=head2 SPLICE
	
	SPLICE don't allow a list replacement 
	because the insert order is made by time.
	in scalar context return the latest element 
	in array context return all the elements selected
	my @tmp   = splice @myarray, 5 ,3;
	or
	my @res = $t->SPLICE( 1 , 7 );
=cut

sub SPLICE
{
    my $self   = shift;
    my $offset = shift || 0;
    my $length = shift || 0;
    my $dbh    = $self->{ _bdb };
    if ( $length == 0 )
    {
       $length = $self->FETCHSIZE();
    }
    if ( $offset < 0 )
    {
        $offset += $self->FETCHSIZE();
    }
    my $key      = $offset + $length;
    my $sql_view = "CREATE TEMP VIEW head_splice AS   SELECT  * FROM queue ORDER BY key LIMIT $key;";
    my $res      = $dbh->do( $sql_view );
#    my $count = $dbh->selectall_arrayref( "SELECT COUNT(*) FROM head_splice;" );

    my $sql = "SELECT  * FROM head_splice ORDER BY key DESC LIMIT $length;";
    my ( $start, undef ) = $self->FETCH( $offset );
    my ( $end,   undef ) = $self->FETCH( $key );
    if ( wantarray )
    {
        my $row = $dbh->selectall_arrayref( $sql );
        $res = $dbh->do( "DROP VIEW head_splice " );
        my $sql_del = "DELETE FROM queue WHERE key >= $start AND key < $end;";
        my $res     = $dbh->do( $sql_del );
        return sort { $a->[0] <=> $b->[0] } @{ $row };
    }
    my $row = $dbh->selectcol_arrayref( $sql, { Columns => [2] } );
    $res = $dbh->do( "DROP VIEW head_splice " );
    my $sql_del = "DELETE FROM queue WHERE key >= $start AND key < $end;";
    $res = $dbh->do( $sql_del );
    my @REVERSED = reverse @$row;
    return \@REVERSED;
}

=head2 SLICE
	
	SLICE like SPLICE but don't delete elements
	in scalar context return the latest element 
	in array context return all the elements selected
	
	my @res = $t->SPLICE( 1 , 7 );
	
=cut

sub SLICE
{
    my $self   = shift;
    my $offset = shift || 0;
    my $length = shift || 0;
    my $dbh    = $self->{ _bdb };
    if ( $length == 0 )
    {
       $length = $self->FETCHSIZE();
    }
    if ( $offset < 0 )
    {
        $offset += $self->FETCHSIZE();
    }
    my $key      = $offset + $length;
    my $sql_view = "CREATE TEMP VIEW head_slice AS   SELECT  * FROM queue ORDER BY key LIMIT $key;";
    my $res      = $dbh->do( $sql_view );
#     my $count = $dbh->selectall_arrayref( "SELECT COUNT(*) FROM head_slice;" );
    my $sql = "SELECT  * FROM head_slice ORDER BY key DESC LIMIT $length;";
    if ( wantarray )
    {
        my $row = $dbh->selectall_arrayref( $sql );
        $res = $dbh->do( "DROP VIEW head_slice " );
        return sort { $a->[0] <=> $b->[0] } @{ $row };
    }
    my $row = $dbh->selectcol_arrayref( $sql, { Columns => [2] } );
    $res = $dbh->do( "DROP VIEW head_slice " );
    my @REVERSED = reverse @$row;
    return \@REVERSED;
}

=head2 EXPIRE
	
	Get the elements expired in the array.
	my @ALL = $t->EXPIRE( 1207840028) ;
	return a refernce to an array with all the expired value.
	
	If a second parameter is provided and not null, the data are also deleted from the array.
	my @ALL = $t->EXPIRE( 1207840028 , 1 ) ;
	return a refernce to an array with all the expired value.
	
=cut

sub EXPIRE
{
    my $self = shift;
    my $time = shift;
    my $to_del = shift || 0;
     my $dbh      = $self->{ _bdb };
    
    my ( $sec, $usec ) = gettimeofday;
    $sec += $time if ( $time != 0 );
    my $key = sprintf( "%010d%06d", $sec, $usec );
    my $sql = "SELECT  * FROM queue WHERE key <= $key ORDER BY key ;";    
    if ( wantarray )
    {
        my $row = $dbh->selectall_arrayref( $sql );
        my $res = $dbh->do( "DELETE FROM queue WHERE key <= $key;") if ($to_del) ;
        return sort { $a->[0] <=> $b->[0] } @{ $row };
    }
    my $row = $dbh->selectcol_arrayref( $sql, { Columns => [2] } );
    my $res = $dbh->do( "DELETE FROM queue WHERE key <= $key;") if ($to_del) ;
    my @REVERSED =  @$row;
    return \@REVERSED;
   
}

=head1 Functions not Implemented

I< >


=head2 EXTEND
	
	Not implemented because not signifiant for a expiration queue
	
=cut

sub EXTEND { carp "no EXTEND function"; }

=head2 STORE
	
	Not implemented because not signifiant for a expiration queue
	
=cut

sub STORE { carp "no STORE function"; }

=head2 STORESIZE
	
	Not implemented because not signifiant for a expiration queue
	
=cut

sub STORESIZE { carp "no STORESIZE function"; }

sub __serialize__
{
    my $self       = shift;
    my $val        = shift;
    my $serializer = $self->{ _serialize };
    return $serializer->serialize( $val ) if $val;
    return $val;
}

sub __deserialize__
{
    my $self       = shift;
    my $val        = shift;
    my $serializer = $self->{ _serialize };
    return $serializer->deserialize( $val ) if $val;
    return $val;
}
1;
__END__

		

=head1 AUTHOR

	Fabrice Dulaunoy <fabrice_at_dulaunoy_dot_com> 
	

=head1 SEE ALSO

	- Data::Queue::Persistent from Mischa Spiegelmock, <mspiegelmock_at_gmail_dot_com>
        - TokyoCabinet from Mikio Hirabayashi <mikio_at_users_dot_sourceforge_dot_net>


=head1 TODO

        - make test
        - implementation of EXTEND to allow clear of array with @myarray = ();
	- implementation of STORESIZE to allow clear of array with $#myarray = -1;
	
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

	Tie::Array::QueueExpire  Copyright (C) 2004 2005 2006 2007 2008 2009 2010 DULAUNOY Fabrice  
	Tie::Array::QueueExpire comes with ABSOLUTELY NO WARRANTY; 
	for details See: L<http://www.gnu.org/licenses/gpl.html> 
	This is free software, and you are welcome to redistribute 
	it under certain conditions;
   
   
=cut
