package Tie::Hash::ImmutableKeys;

use 5.008008;
use strict;
use warnings;

require Exporter;

use Tie::Hash;
use Carp;

#use vars qw($VERSION @ISA);

our @ISA = qw(Exporter Tie::StdHash);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Tie::Hash::ImmutableKeys ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
#our %EXPORT_TAGS = (
#    'all' => [
#        qw(
#
#          )
#    ],
#);

our @EXPORT_OK = qw( error );

our @EXPORT = qw(

);

our $VERSION = sprintf "1.%02d", '$Revision: 14 $ ' =~ /(\d+)/;

our $__ERROR__ = "croak";

sub error
{
    $__ERROR__ = $_[1];
}

sub __HANDEL_ERROR__
{
    if ( $__ERROR__ =~ /croak/i )
    {
        Carp::croak "COULD NOT DELETE key=" . $_[0] . " the val=" . $_[1];
    }
    elsif ( $__ERROR__ =~ /exit/i )
    { 
        exit;
    }
    else
    {
        Carp::carp "COULD NOT DELETE key=" . $_[0] . " the val=" . $_[1];
    }
}

sub TIEHASH
{
    my $class = $_[0];
    my $list  = $_[1];
    my %all;
    foreach my $k ( keys %$list )
    {
        if ( ( ref( $list->{ $k } ) ) =~ /HASH/i )
        {
            tie my %c, 'Tie::Hash::ImmutableKeys', $list->{ $k };
            $all{ $k } = \%c;
        }
        else
        {
            $all{ $k } = $list->{ $k };
        }
    }
    bless \%all, $class;
    return \%all;
}

sub DELETE
{
    if ( $_[2] )
    {
        delete $_[0]{ $_[1] };
    }
    else
    {

        my $line = ( caller( 0 ) )[2];
        my $sub = ( caller( 1 ) )[3] || "main";
        __HANDEL_ERROR__( $_[1], $_[2] );
    }
}

sub FORCE_DELETE
{
    my $class = $_[0];
    my $key   = $_[1];
    my $leaf  = $_[2];
    if ( ( ref( $key ) ) =~ /HASH/i )
    {
        foreach my $k ( keys %$key )
        {
            my %all;
            if ( ( ref( $key->{ $k } ) ) =~ /HASH/i )
            {
                tie( %all, 'Tie::Hash::ImmutableKeys', $class->{ $k } );
                my $obj = tied( %all );
                tie my %c, 'Tie::Hash::ImmutableKeys', $key->{ $k };
                $obj->FORCE_DELETE( $key->{ $k } );
                $class->{ $k } = \%all;
            }
            else
            {
                tie( %all, 'Tie::Hash::ImmutableKeys', $class->{ $k } );
                my $obj = tied( %all );
                $obj->FORCE_DELETE( $key->{ $k }, 1 );
                $class->{ $k } = \%all;
            }
        }
    }
    else
    {
        $class->SUPER::DELETE( $key ) if $leaf;
    }

}

sub STORE
{
    if ( $_[3] )
    {
        $_[0]{ $_[1] } = $_[2];
    }
    else
    {
        if ( exists $_[0]{ $_[1] } )
        {

            $_[0]{ $_[1] } = $_[2] if exists $_[0]{ $_[1] };
        }
        else
        {
            my $line = ( caller( 0 ) )[2];
            my $sub = ( caller( 1 ) )[3] || "main";
            __HANDEL_ERROR__( $_[1], $_[2] );
        }
    }
}

sub FORCE_STORE
{
    my $class = $_[0];
    my $key   = $_[1];
    my $val   = $_[2];
    if ( exists( $class->{ $key } ) )
    {
        if ( ( ref( $val ) ) =~ /HASH/i )
        {
            tie( my %all, 'Tie::Hash::ImmutableKeys', $class->{ $key } );
            my $obj = tied( %all );
            foreach my $k ( keys %$val )
            {
                if ( ( ref( $val->{ $k } ) ) =~ /HASH/i )
                {
                    tie my %c, 'Tie::Hash::ImmutableKeys', $val->{ $k };
                    $obj->FORCE_STORE( $k, \%c );
                }
                else
                {
                    $obj->STORE( $k, $val->{ $k }, 1 );
                }
            }
            $class->STORE( $key, \%all, 1 );
        }
        else
        {
            $class->SUPER::STORE( $key, $val );
        }
    }
    else
    {
        my %all;
        foreach my $k ( keys %$val )
        {
            if ( ( ref( $val->{ $k } ) ) =~ /HASH/i )
            {
                tie my %c, 'Tie::Hash::ImmutableKeys', $val->{ $k };
                $all{ $k } = \%c;
            }
            else
            {
                $all{ $k } = $val->{ $k };
            }
        }
        my %tmp;
        tie( %tmp, 'Tie::Hash::ImmutableKeys', \%all );
        $class->SUPER::STORE( $key, \%tmp );
    }
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Tie::Hash::ImmutableKeys - Perl module to create a HASH where keys are immutable but not the leaf data.
It is possible to modify the key by FORCE_STORE or FORCE_DELETE.
It is working on all the tree key created (keys and subkeys are immutable).

=head1 SYNOPSIS

  use Tie::Hash::ImmutableKeys;
  use Data::Dumper;


  my $z = { aze => 100, tyuiop => 333, qsdfg => 987 };
  my $f = { A   => 0,   Z      => 1,   E     => 0, L => $z };
  my $a = { a   => 0,   z      => 1,   e     => 1, r => 1, AA => $f };

  my $list = {
      S => $a,
      F => $f,
      P => "leaf"
  };

  ## Tie the hash with a list of key and values
  tie( my %a, 'Tie::Hash::ImmutableKeys', $list );
  
  ## Try to modify a value . If the key is missing this command fail
  my $ar = "z" ;
  if ( defined( $a{ S }->{ $ar } = 1111 ) )
  {
      print "The key is present and data are updated " . Dumper( \%a );

  }else
  {
      print "The key is NOT present and data are NOT updated " . Dumper( \%a );
  }
  
  
  ## Get the object from the tied variable
  my $obj = tied( %a );
  
  
  ## force the store over a KEY (or create a new key)
  $obj->FORCE_STORE( 'S', { l => 5656565 } );
  
  print "NEW KEY" . Dumper( \%a );
  
  
  ## Now it is possible to use the normal tied hash to modify the data
  $a{ S }->{ AA }{ L }{ aze } = "dfsdf";
  print "NEW KEY" . Dumper( \%a );


  ## could not delete normal key
  delete $a{ S }->{ AA }{ L }{ aze };
  print "NEW KEY" . Dumper( \%a );

  ## must use the object call to force the delete
  $obj->FORCE_DELETE( { 'S' => { AA => { L => 'aze' } } } );
  print "NEW KEY after FORCE_DELETE" . Dumper( \%a );
  
  ## force the module to exit with an error
  tied(%a)->error('exit');


=head1 DESCRIPTION

Tie::Hash::ImmutableKeys - Perl module to create a HASH where keys are immutable but not the leaf data.
It is possible to modify the key by FORCE_STORE or FORCE_DELETE.
It is working on all the tree key created (keys and subkeys are immutable).

  TIEHASH classname, LIST
 	The method invoked by the command "tie %hash, classname". Associates a new hash instance with the specified class. "LIST" would
        represent the structure of the initial hash created.
 
  FORCE_STORE this, key, value
      Store datum value into key for the tied hash this. This call create or averwrite the key(s) if needed
      
  FORCE_DELETE this, key
      Delete the key key from the tied hash this.
  
  There is an exportable function "error" to allow a differrnt way to complain if we try to modify/delete a locked key
  
  use Tie::Hash::ImmutableKeys qw( error );
  
  	my %a;
	tie( %a, 'Tie::Hash::ImmutableKeys', $list );
	tied(%a)->error('exit');
	
  The posible parameter for the error are:
  	croak	this is the default behaviour, the module die if we try to modify a locked key and print some info about the error.
	carp	the module warn if we try to modify a locked key and print some info about the error.
	exit    the module simple exit with a return value of 0
	
   any other value fallback to croak.
   
=head1 SEE ALSO

fields, Hash::Util, Class::PseudoHash

=head1 AUTHOR

Fabrice Dulaunoy <fabrice[at]dulaunoy[dot]com>

07 june 2007

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
Under the GNU GPL2

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public 
License as published by the Free Software Foundation; either version 2 of the License, 
or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; 
if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

B<Tie::Hash::ImmutableKeys> Copyright (C) 2007 DULAUNOY Fabrice. B<Tie::Hash::ImmutableKeys> comes with ABSOLUTELY NO WARRANTY; 
for details See: L<http://www.gnu.org/licenses/gpl.html> 
This is free software, and you are welcome to redistribute it under certain conditions;


=cut
