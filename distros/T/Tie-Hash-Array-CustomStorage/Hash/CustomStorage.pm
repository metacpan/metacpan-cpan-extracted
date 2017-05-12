package Tie::Hash::CustomStorage ;

use warnings ;
use Carp;
use strict;

use vars qw($VERSION) ;
$VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/;

use base qw/Tie::Hash/;

# if not init or tie_hash or init parameter is given, behaves exactly
# as a standard hash

sub TIEHASH 
  {
    my $type = shift ;
    my %args = @_ ;

    my %data = () ;
    my $autovivify = 1 ;

    my $self =  { data => \%data }  ;

    #print "Creating Tie::Hash with '",join("','", %args),"'\n";

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

    # applied to hash containing the storage
    if (defined $args{tie_hash}) 
      {
	my $p = delete $args{tie_hash} ;
	my ($class, @args) = ref $p ? @$p : ($p) ;
	$load->($class) ;
	$self->{tie_hash_obj} = tie %data, $class, @args ;
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

	      $self->{data}{$idx} = $obj ;
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

    croak __PACKAGE__,": Unexpected TIEHASH argument: ",
      join(' ',keys %args) if %args ;

    bless $self, $type  ;
  }

# this one is tricky, all direct method calls to this class must be
# forwarded to the tied object hidden behind the %data hash
sub AUTOLOAD 
  {
    our $AUTOLOAD ;
    my $self=shift ;
    my $obj = $self->{tie_hash_obj} ;

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

    #print "TieHash: fetch idx $idx\n";
    $self->{init}->($idx) unless defined $self->{data}{$idx} ;

    return $self->{data}{$idx} ;
  }

# Implementation note: The tie must be applied to the variable which
# is actually stored. For a standard hash this variable is
# $self->{$name}{$key}. For a tied hash, the actual variable is hidden
# within the tied hash. The code will find the actual location if the
# tied hash inherits from StdHash or if the tied hash follows the
# example of the camel book (e.g. $self->{DATA} or $self->{data}). If
# all fails, the user's tied hash must provide a get_data_ref method
# that give a ref to the actual location of the variable to be tied.

sub get_storage_ref
  {
    my ($self,$idx) = @_ ;
    my $h_obj = $self->get_user_tied_hash_object ;

    return \$self->{data}{$idx} unless defined $h_obj;

    # print "get_scalar_ref called for $h_obj,$idx\n";
    return $h_obj->isa('Tie::StdHash') ? \$h_obj->{$idx} :
      defined $h_obj->{DATA} ? \$h_obj->{DATA}{$idx} :
	defined $h_obj->{data} ? \$h_obj->{data}{$idx} :
	  $h_obj->can('get_data_ref') ? $h_obj->get_data_ref($idx):
	    die ref($h_obj)," must provide a get_data_ref method" ;
  }

sub get_user_tied_hash_object
  {
    my $self = shift ;
    return  tied %{$self->{data}} ;
  }

sub get_tied_storage_object
  {
    my ($self,$idx) = @_ ;
    $self->{init}->($idx) unless defined $self->{data}{$idx} ;
    #print "TieHash: get_storage on idx $idx\n";
    my $r = $self->get_storage_ref($idx) ;
    tied ($$r) ;
  }

sub STORE
  { 
    my ($self,$idx, $data) = @_ ;

    #print "TieHash: store idx $idx, data ", defined $data ? $data : 'UNDEF', " (", join('~',keys %{$self->{data}}),")\n";

    my @args;
    if (defined $self->{class_storage} and defined $data)
      {
	if (ref($data) eq $self->{class_storage})
	  {
	    # provided object will be run through init process
	    $self->{init}->($idx,$data) ;
	    return $self->{data}{$idx} ;
	  }
	else
	  {
	    croak ref($self),": wrong object assigned to index '$idx'. ",
	      "Expected '$self->{class_storage}', got '",ref($data),"'" ;
	  }
      }

    $self->{init}->($idx,$data) unless defined $self->{data}{$idx} ;

    return $self->{data}{$idx} = $data ;
  }

sub FIRSTKEY { my $a = scalar keys %{$_[0]->{data}}; each %{$_[0]->{data}} }
sub NEXTKEY  { each %{$_[0]->{data}} }


sub STORESIZE 
  {
    my ($self,$size) = @_ ;

    for (my $i = $#{$_[0]->{data}}; $i<$size; $i++) 
      {
	$self->{init}->($i);
      }
  }

sub EXISTS    { exists $_[0]->{data}{$_[1]} }
sub DELETE    { delete $_[0]->{data}{$_[1]} }
sub CLEAR    { %{$_[0]->{data}} = () }
sub SCALAR   { scalar %{$_[0]->{data}} }

sub DESTROY {}

1;

__END__

=head1 NAME

Tie::Hash::CustomStorage - Tie hash and value storage 

=head1 SYNOPSIS

  tie %hash , 'Tie::Hash::CustomStorage',
   [ 
     tie_hash => 'My_Tie_Hash', | 
     tie_hash => [ 'My_Tie_Hash' , @my_args ],
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

This module provides a kind of a proxy tied hash. By default (without
any constructor parameter), this class provides a regular hash.

With a C<tie_hash> parameter (and a tied hash class provided by the
user), this class provides a regular tied hash (as usual). All
C<STORE> and C<FETCH> call are delegated to the user tied hash class.

With a C<tie_storage> parameter (and a tied scalar class), all value
of the hash are tied to the tied scalar class passed by the user.
This way, you can get a hash of tied scalars.

With a C<class_storage> parameter (and a class name), you get a
strongly typed hash where value can only be instance of the class
passed with the C<class_storage> parameter. This object can be
autovivified or not depending on the value of <autovivify> parameter.

With a C<init_storage> parameter (and a sub ref), you get a regular
hash where all value are initialized with the passed sub.

By combining C<tie_hash> parameter with one of the C<*_storage>
parameter, you can get a tied hash of tied scalars, or a tied hash of
objects or a tied hash with auto-initialized values.


=head1 What's going on here ?

When the user calls C<< tie %hash ,
'Tie::Hash::CustomStorage' >>, a tied hash is created,
let's call it a I<proxy hash>.

To let the user define its own hash behavior, the proxy hash contains
a hash that will be tied by the user class when the proxy hash is
created with a C<tie_hash> parameters. Let's call it the I<user hash>.

The values of the user hash will contain the data that the user care
about. These scalar values are contained in the I<storage> of the user
hash.

This storage of the user hash can also be specialized by using the
C<tie_storage> parameter or the C<class_storage> parameter or the
C<init_storage> parameter.

=head1 CONSTRUCTOR

Parameters are:

=over

=item tie_hash => "Tie::MyHash"

The class to tie the user hash.

=item tie_storage => "Tie::MyScalar"

The class to tie to the scalars contained in the user hash.

=item class_storage => "My::Class"

All scalar contained in the values of the user hash will be instances
of C<class_storage>

=item autovivify [ 0 | 1 ]

When fetched, the value of the user hash will be automatically
initialized with and instance of C<class_storage>. (this parameter can
only be used with C<class_storage>). Default is 1.

=item init_object => sub { ... }

After a new object is created, this sub ref will be called with
C<(object, index)>. Can be used only with C<class_storage>.

=item init_storage => sub { ... }

When fetched, the value of the user hash will be automatically
initialized by calling this subroutine and storing its return value
into the user hash. In other word, the hash can never return an
undefined value (unless the sub you provides returns an undef value,
but I don't why you'd do that...)

The sub ref will be called with one parameter: the index of the
fetched item.

I.e., calling C<$hash{foo}> will perform:

 $hash{foo} = $init_storage->('foo') ;

=back

=head1 Requirement regarding C<tie_hash> class

Automatic tying of the scalar contained by the hash means the the
tying must be done on the actual scalar storage. For a standard hash
this variable is C<$self->{$name}{$key}>. For a tied hash, this scalar
storage is actually contained in a class provided by the user
through the C<tie_hash> parameter.

The user class passed through the C<tie_hash> parameter must satisfy
one of the following conditions:

=over

=item *

Inherit from L<Tie::StdHash>

=item *

Store its data in C<< $self->{DATA} >> or C<< $self->{data} >>

=item *

Provide a C<get_data_ref> method that will return a ref of the hash
containing the data.

=back

=head1 EXAMPLES

  # create a hash where value are initialized with a sub and arguments
  tie %hash, 'Tie::Hash::CustomStorage',
    init => [ \&my_sub, @my_args ] ;

  # create a regular tied hash. This is equivalent to
  # tie %hash, 'My_Tie_Hash';
  tie %hash, 'Tie::Hash::CustomStorage',
    tie_hash => 'My_Tie_Hash' ;

  # create a regular tied hash. This is equivalent to
  # tie %hash, 'My_Tie_Hash', foo => 'bar' ;
  tie %hash, 'Tie::Hash::CustomStorage',
    tie_hash => [ 'My_Tie_Hash', foo => 'bar' ]  ;

  # create a hash where values are tied scalars
  tie %hash, 'Tie::Hash::CustomStorage',
    tie_storage => [ 'MyTieScalar', @my_args] ;

  # create a hash where values are autovivified objects
  tie %hash, 'Tie::Hash::CustomStorage',
    class_storage => [ 'MyClass' , @my_args ] ;

  # create a hash where values are objects (must be assigned)
  tie %hash, 'Tie::Hash::CustomStorage',
    class_storage => 'MyClass', autovivify => 0 ;

=head1 COPYRIGHT

Copyright (c) 2004 Dominique Dumont. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<Tie::Hash>,
