package Tie::Array::CustomStorage ;

use warnings ;
use Carp;
use strict;

use vars qw($VERSION) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/;

use base qw/Tie::Array/;

# if not init or tie_array or init parameter is given, behaves exactly
# as a standard array

sub TIEARRAY 
  {
    my $type = shift ;
    my %args = @_ ;

    my @data = () ;
    my $autovivify = 1 ;

    my $self =  { data => \@data }  ;

    my $load = sub 
      {
	my $file = $_[0].'.pm';
	$file =~ s!::!/!g;
	require $file unless defined *{$_[0].'::'} ;
      };

    if (defined $args{autovivify})
      {
	$autovivify = delete $args{autovivify} ;
      }

    # applied to array containing the storage
    if (defined $args{tie_array}) 
      {
	my $p = delete $args{tie_array} ;
	my ($class, @args) = ref $p ? @$p : ($p) ;
	$load->($class) ;
	$self->{tie_array_obj} = tie @data, $class, @args ;
      }

    my $init_obj = delete $args{init_object} ;

    # applied to storage
    if (defined $args{class_storage}) 
      {
	my $p = delete $args{class_storage} ;
	my ($class, @args) = ref $p ? @$p : ($p) ;
	$load->($class) ;

	$self->{init} = $autovivify ? 
	  sub 
	    { 
	      my $idx = shift ;
	      my $obj = shift || $class -> new (@args) ;
	      $init_obj->($obj,$idx) if defined $init_obj ;

	      $self->{data}[$idx] = $obj ;
	    } : sub {} ;

	$self->{class_storage} = $class ;
      }
    elsif (defined $args{tie_storage}) 
      {
	my $p = delete $args{tie_storage} ;
	my ($class, @args) = ref $p ? @$p : ($p) ;
	$load->($class) ;
	$self->{init} = sub 
	  { 
	    #print "storage init with tie_storage\n";
	    my $ref = $self->get_storage_ref($_[0]) ;
	    my $obj = tie $$ref, $class, @args ;
	    $init_obj->($obj,$_[0]) if defined $init_obj ;
	  } ;
      } 
    elsif (defined $args{init_storage}) 
      {
	my ($init_method, @args) = @{delete $args{init_storage}} ;
	$self->{init} = sub 
	  { 
	    #print "storage init with init\n";
	    my $ref = $self->get_storage_ref($_[0]) ;
	    $init_method->($ref, @args) 
	  } ;
      }
    else 
      {
	$self->{init} = sub {} ; 
      }

    croak __PACKAGE__,": Unexpected TIEARRAY argument: ",
      join(' ',keys %args) if %args ;

    bless $self, $type  ;
  }

# this one is tricky, all direct method calls to this class must be
# forwarded to the tied object hidden behind the @data array
sub AUTOLOAD 
  {
    our $AUTOLOAD ;
    my $self=shift ;
    my $obj = $self->{tie_array_obj} ;

    if (defined $obj) 
      {
	my ($pack,$method) = ($AUTOLOAD =~ /(.*)::(\w+)/) ;
	$obj->$method(@_) ;
      }
    else 
      {
	croak "Undefined subroutine $AUTOLOAD called";
      }
  }

sub FETCH
  {
    my ($self,$idx) = @_ ;

    #print "TieArray: fetch idx $idx\n";
    $self->{init}->($idx) unless defined $self->{data}[$idx] ;

    return $self->{data}[$idx] ;
  }

# Implementation note: The tie must be applied to the variable which
# is actually stored. For a standard array this variable is
# $self->{$name}[$key]. For a tied array, the actual variable is hidden
# within the tied array. The code will find the actual location if the
# tied array inherits from StdArray or if the tied array follows the
# example of the camel book (e.g. $self->{DATA} or $self->{data}). If
# all fails, the user's tied array must provide a get_data_ref method
# that give a ref to the actual location of the variable to be tied.

sub get_storage_ref
  {
    my ($self,$idx) = @_ ;
    my $h_obj = $self->get_user_tied_array_object ;

    return \$self->{data}[$idx] unless defined $h_obj;

    # print "get_scalar_ref called for $h_obj,$idx\n";
    return $h_obj->isa('Tie::StdArray') ? \$h_obj->[$idx] :
      defined $h_obj->{DATA} ? \$h_obj->{DATA}[$idx] :
	defined $h_obj->{data} ? \$h_obj->{data}[$idx] :
	  $h_obj->can('get_data_ref') ? $h_obj->get_data_ref($idx):
	    die ref($h_obj)," must provide a get_data_ref method" ;
  }

sub get_user_tied_array_object
  {
    my $self = shift ;
    return  tied @{$self->{data}} ;
  }

sub get_tied_storage_object
  {
    my ($self,$idx) = @_ ;
    $self->{init}->($idx) unless defined $self->{data}[$idx] ;
    #print "TieArray: get_storage on idx $idx\n";
    my $r = $self->get_storage_ref($idx) ;
    tied ($$r) ;
  }

sub STORE
  { 
    my ($self,$idx, $data) = @_ ;

    #print "TieArray: store idx $idx, data ", defined $data ? $data : 'UNDEF', " (", join('~', @{$self->{data}}),")\n";

    my @args;
    if (defined $self->{class_storage} and defined $data)
      {
	if (ref($data) eq $self->{class_storage})
	  {
	    # provided object will be run through init process
	    $self->{init}->($idx,$data) ;
	    return $self->{data}[$idx] ;
	  }
	else
	  {
	    croak ref($self),": wrong object assigned to index '$idx'. ",
	      "Expected '$self->{class_storage}', got '",ref($data),"'" ;
	  }
      }

    $self->{init}->($idx,$data) unless defined $self->{data}[$idx] ;

    return $self->{data}[$idx] = $data ;
  }


sub STORESIZE 
  {
    my ($self,$size) = @_ ;

    my $old = scalar @{$self->{data}} ;

    return if $old == $size ;

    if ($size < $old) {
      #print "Reducing array from $old to $size elements\n";
      $#{$self->{data}} = $size -1 ;
      return ;
    }

    #print "Growing array from $old to $size elements\n";

    for (my $i = $old; $i<$size; $i++) {
      $self->{init}->($i);
    }

  }

sub FETCHSIZE { scalar @{$_[0]->{data}} }


sub EXISTS    { exists $_[0]->{data}[$_[1]] ;}
sub DELETE    { delete $_[0]->{data}[$_[1]] ;}

sub DESTROY {}

1;

__END__

=head1 NAME

Tie::Array::CustomStorage - Tie array and value storage 

=head1 SYNOPSIS

  tie @array , 'Tie::Array::CustomStorage',
   [ 
     tie_array => 'My_Tie_Array', | 
     tie_array => [ 'My_Tie_Array' , @my_args ],
   ] ,

   [
     init_storage => \&my_sub, | 
     init_storage => [ \&my_sub, @my_args ], | 
     tie_storage => 'MyTieScalar' , |
     tie_storage => [ 'MyTieScalar', @my_args], |
     class_storage => 'MyClass' , |
     class_storage => [ 'MyClass' , @my_args ], 
   ]
   [ autovivify => [ 0 | 1 ] , ]
   [ init_object => sub{ my ($obj,$idx) = @_ ; ... } , ]


=head1 DESCRIPTION

This module provides a kind of a proxy tied array. By default (without
any constructor parameter), this class provides a regular array.

With a C<tie_array> parameter (and a tied array class provided by the
user), this class provides a regular tied array (as usual). All
C<STORE> and C<FETCH> call are delegated to the user tied array class.

With a C<tie_storage> parameter (and a tied scalar class), all value
of the array are tied to the tied scalar class passed by the user.
This way, you can get a array of tied scalars.

With a C<class_storage> parameter (and a class name), you get a
strongly typed array where value can only be instance of the class
passed with the C<class_storage> parameter. This object can be
autovivified or not depending on the value of <autovivify> parameter.

With a C<init_storage> parameter (and a sub ref), you get a regular
array where all value are initialized with the passed sub.

By combining C<tie_array> parameter with one of the C<*_storage>
parameter, you can get a tied array of tied scalars, or a tied array of
objects or a tied array with auto-initialized values.


=head1 What's going on here ?

When the user calls C<< tie @array ,
'Tie::Array::CustomStorage' >>, a tied array is created,
let's call it a I<proxy array>.

To let the user define its own array behavior, the proxy array contains
a array that will be tied by the user class when the proxy array is
created with a C<tie_array> parameters. Let's call it the I<user array>.

The values of the user array will contain the data that the user care
about. These scalar values are contained in the I<storage> of the user
array.

This storage of the user array can also be specialized by using the
C<tie_storage> parameter or the C<class_storage> parameter or the
C<init_storage> parameter.

=head1 CONSTRUCTOR

Parameters are:

=over

=item tie_array => "Tie::MyArray"

The class to tie the user array.

=item tie_storage => "Tie::MyScalar"

The class to tie to the scalars contained in the user array.

=item class_storage => "My::Class"

All scalar contained in the values of the user array will be instances
of C<class_storage>

=item autovivify [ 0 | 1 ]

When fetched, the value of the user array will be automatically
initialized with and instance of C<class_storage>. (this parameter can
only be used with C<class_storage>). Default is 1.

=item init_object => sub { ... }

After a new object is created, this sub ref will be called with
C<(object, index)>. Can be used only with C<class_storage>.

=item init_storage => sub { ... }

When fetched, the value of the user array will be automatically
initialized by calling this subroutine and storing its return value
into the user array.

The sub ref will be called with one parameter: the index of the
fetched item.

I.e., calling C<$array{foo}> will perform:

 $array{foo} = $init_storage->('foo') ;

=back

=head1 Requirement regarding C<tie_array> class

Automatic tying of the scalar contained by the array means the the
tying must be done on the actual scalar storage. For a standard array
this variable is C<$self->{$name}{$key}>. For a tied array, this scalar
storage is actually contained in a class provided by the user
through the C<tie_array> parameter.

The user class passed through the C<tie_array> parameter must satisfy
one of the following conditions:

=over

=item *

Inherit from L<Tie::StdArray>

=item *

Store its data in C<< $self->{DATA} >> or C<< $self->{data} >>

=item *

Provide a C<get_data_ref> method that will return a ref of the array
containing the data.

=back

=head1 EXAMPLES

  # create a array where value are initialized with a sub and arguments
  tie @array, 'Tie::Array::CustomStorage',
    init => [ \&my_sub, @my_args ] ;

  # create a regular tied array. This is equivalent to
  # tie @array, 'My_Tie_Array';
  tie @array, 'Tie::Array::CustomStorage',
    tie_array => 'My_Tie_Array' ;

  # create a regular tied array. This is equivalent to
  # tie @array, 'My_Tie_Array', foo => 'bar' ;
  tie @array, 'Tie::Array::CustomStorage',
    tie_array => [ 'My_Tie_Array', foo => 'bar' ]  ;

  # create a array where values are tied scalars
  tie @array, 'Tie::Array::CustomStorage',
    tie_storage => [ 'MyTieScalar', @my_args] ;

  # create a array where values are autovivified objects
  tie @array, 'Tie::Array::CustomStorage',
    class_storage => [ 'MyClass' , @my_args ] ;

  # create a array where values are objects (must be assigned)
  tie @array, 'Tie::Array::CustomStorage',
    class_storage => 'MyClass', autovivify => 0 ;

=head1 COPYRIGHT

Copyright (c) 2004 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<Tie::Array>,
