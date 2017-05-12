#############################################################################
#Changes.pm
#Last Change: 2009-02-18
#Copyright (c) 2008 Marc-Seabstian "Maluku" Lucksch
#Version 0.1
####################
#Changes.pm is published under the terms of the MIT license, which
#basically means "Do with it whatever you want". For more information, see the 
#license.txt file that should be enclosed with plasma distributions. A copy of 
#the license is (at the time of this writing) also available at
#http://www.opensource.org/licenses/mit-license.php .
#############################################################################

package Tie::Proxy::Changes;
use strict;
use warnings;
use Carp qw/croak/;
require Scalar::Util;
use overload 
             '""'=> \&_getbool, 
             'bool'=>\&_getbool, 
             '%{}'=>\&_gethash,
             '@{}'=>\&_getarray,
             '${}'=>\&_getscalar,
             'nomethod'=>\&_getbool;

our $VERSION = 0.2;


#For thread safety

my %REGISTRY;

# Define the data store fields
# We have to make this an inside-out-object so it can be used by deref in any
# call, without killing overload.

my %caller_of;
my %index_of;
my %data_of;
my %tiearray_of;
my %tiehash_of;
my %tiescalar_of;

# Helper method for inside-out objecst:

sub _id {
    return Scalar::Util::refaddr($_[0]);
}

# Create a new Tie::Proxy::Changes with optional data.
sub new {
	my $class=shift;
    my $self=bless \do{ my $anon; },$class;
    
    # Safe it into the registry for thread stuff:
    
    my $id=_id($self);
    Scalar::Util::weaken($REGISTRY{$id}=$self);
    
    $caller_of{$id}=shift;

    my $index=shift;
    $index_of{$id}=$index if defined $index;
    #my $self=[$calling_obj,$index]; 
    
    # Get the current state of the value, if it is there.
    my $data=shift;
    $data_of{$id}=$data if $data;

	return $self;
}

# Access this object as a hashref.
sub _gethash {
	my $self=shift;
	my $id=_id($self);

    # Return the stored access if it is already there.
	return $tiehash_of{$id} if $tiehash_of{$id};

    # Check the existing data or create it (if not there)
    croak "Can't use an ".ref $data_of{$id}." as a hash" 
        if exists $data_of{$id} 
            and Scalar::Util::reftype($data_of{$id}) ne "HASH";
	$data_of{$id}={} unless $data_of{$id};
    
    # Tie myself as a hash.
    my %h=();
	tie %h,ref $self,$self;
	my $x=\%h;

    # Store the tied object for faster access.
	$tiehash_of{$id}=$x;

	return $x;
}

# Access this object as an arrayref.
sub _getarray {
	my $self=shift;
	my $id=_id($self);

    # Return the stored access if it is already there.
	return $tiearray_of{$id} if $tiearray_of{$id};
    
    # Check the existing data or create it (if not there)
    croak "Can't use ".ref $data_of{$id}." as an array" 
        if exists $data_of{$id} 
            and Scalar::Util::reftype($data_of{$id}) ne "ARRAY";
	$data_of{$id}=[] unless $data_of{$id};

    # Tie myself as an array.
	my @a=();
	tie @a,ref $self,$self;
	my $x=\@a;

    # Store the tied object for faster access.
	$tiearray_of{$id}=$x;

	return $x;
}

# Access this as a scalar ref.

sub _getscalar {
	my $self=shift;
	my $id=_id($self);

    # Return the stored access if it is already there.
	return $tiescalar_of{$id} if $tiescalar_of{$id};
    
    # Check the existing data or create it (if not there)
    croak "Can't use ".ref $data_of{$id}." as a scalarref" 
        if exists $data_of{$id} 
            and Scalar::Util::reftype($data_of{$id}) ne "REF"
            and Scalar::Util::reftype($data_of{$id}) ne "SCALAR"
        ;
	$data_of{$id}=\do {my $d;} unless exists $data_of{$id};

    # Tie myself as an array.
	my $s;
	tie $s,ref $self,$self;
	my $x=\$s;

    # Store the tied object for faster access.
	$tiescalar_of{$id}=$x;

	return $x;
}

# Test for the boolean value
sub _getbool {
    my $self=shift;
	my $id=_id($self);

    # Test for data, return the size of array or hash data.
    if ($data_of{$id}) {
        if (Scalar::Util::reftype($data_of{$id})) {
            if (Scalar::Util::reftype($data_of{$id}) eq "HASH") {
                return scalar %{$data_of{$id}};
            }
            elsif (Scalar::Util::reftype($data_of{$id}) eq "ARRAY") {
                return scalar @{$data_of{$id}};
            }
            elsif (Scalar::Util::reftype($data_of{$id}) eq "REF") {
                return ${$data_of{$id}};
            }
            elsif (Scalar::Util::reftype($data_of{$id}) eq "SCALAR") {
                return ${$data_of{$id}};
            }
        }
        # Return other data, if it's not an array or a hash
        return $data_of{$id};
    }

    # Empty object is always false (Happens during autovivify)
	return 0;
}

# Helper to set the right params for STORE
#
sub _upper {
    my $id=shift;
    die "upper has to be called as a list" unless wantarray;
    if (exists $index_of{$id}) {
        return ($index_of{$id},$data_of{$id});
    }
    return $data_of{$id};
}

# To understand this, reading of perltie is required.

sub TIEHASH { 
	my $class=shift;
	return shift;
}
sub TIEARRAY { 
	my $class=shift;
	return shift;
}

sub TIESCALAR { 
	my $class=shift;
	return shift;
}

sub STORE { 
	my $self=shift;
	my $id=_id($self);
	my $key=shift;
	my $value=shift;
	
    # Choose the right operating method, since STORE can be called on both
    # arrays and hashes
    if (Scalar::Util::reftype($data_of{$id}) eq "HASH") {
		$data_of{$id}->{$key}=$value;
	}
	elsif (Scalar::Util::reftype($data_of{$id}) eq "ARRAY") {
		$data_of{$id}->[$key]=$value;
	}
    else {
        ${$data_of{$id}}=$key;
    }
    # Content has changed, call STORE of the emitting object/tie.
	
    $caller_of{$id}->STORE(_upper($id));
    return;
}
sub FETCH { 
	my $self=shift;
	my $id=_id($self);
	my $key=shift;

    # Choose the right operationg method, FETCH is also implemented for both
    # arrays and hashes.
    # This also creates a new ChangeProxy, so it can track the changes of the
    # data of this object as well. The STORE calls are stacking till they
    # reach the emitting object.
	if (Scalar::Util::reftype($data_of{$id}) eq "HASH") {
		return __PACKAGE__->new($self,$key,$data_of{$id}->{$key}) 
            if $data_of{$id}->{$key};
	}
	elsif (Scalar::Util::reftype($data_of{$id}) eq "ARRAY") {
		return __PACKAGE__->new($self,$key,$data_of{$id}->[$key]) 
            if $data_of{$id}->[$key];
	}
    else {
        return __PACKAGE__->new($self,$key,${$data_of{$id}}) 
    }

    # Also return an empty ChangeProxy on unknown keys or indices, so
    # autovivify calls are tracked as well. The object will play empty/undef
    # in bool context, so it works for both testing and autovivification,
    # since there is no way to distinguish them from the FETCH call. 
    return __PACKAGE__->new($self,$key); 
}

# This implements the rest of the tie interface, nothing new here, they just
# call STORE on every change to proxy them as well.

sub FIRSTKEY { 
	my $self=shift;
	my $id=_id($self);
	my $a = scalar keys %{$data_of{$id}}; each %{$data_of{$id}} 
}
sub NEXTKEY  { 
	my $self=shift;
	my $id=_id($self);
	each %{$data_of{$id}}
}
sub EXISTS   { 
	my $self=shift;
	my $id=_id($self);
	my $key=shift;
	if (Scalar::Util::reftype($data_of{$id}) eq "HASH") {
		return exists $data_of{$id}->{$key};
	}
	else {
		return exists $data_of{$id}->{$key};
	}
}
sub DELETE   { 
	my $self=shift;
	my $id=_id($self);
	my $key=shift;
	if (Scalar::Util::reftype($data_of{$id}) eq "HASH") {
		delete $data_of{$id}->{$key};
	}
	else {
		delete $data_of{$id}->{$key};
	}
	$caller_of{$id}->STORE(_upper($id));
}
sub CLEAR    { 
	my $self=shift;
	my $id=_id($self);
	if (Scalar::Util::reftype($data_of{$id}) eq "HASH") {
		%{$data_of{$id}}=();
	}
	else {
		@{$data_of{$id}}=()
	}
	$caller_of{$id}->STORE(_upper($id)); 
}
sub SCALAR { 
	my $self=shift;
	my $id=_id($self);
	if (Scalar::Util::reftype($data_of{$id}) eq "HASH") {
		return scalar %{$data_of{$id}};
	}
	else {
		return scalar @{$data_of{$id}};
	}
}

sub FETCHSIZE { 
	my $self=shift;
	my $id=_id($self);
	scalar @{$data_of{$id}}; 
}
sub STORESIZE { 
	my $self=shift;
	my $id=_id($self);
	$#{$data_of{$id}} = $_[0]-1;
	$caller_of{$id}->STORE(_upper($id)); 
}
sub POP       { 
	my $self=shift;
	my $id=_id($self);
	my $e=pop(@{$data_of{$id}});
	$caller_of{$id}->STORE(_upper($id)); 
	return $e;
}
sub PUSH      { 
	my $self=shift;
	my $id=_id($self);
	push(@{$data_of{$id}},@_);
	$caller_of{$id}->STORE(_upper($id)); 
	return;
}
sub SHIFT     { 
	my $self=shift;
	my $id=_id($self);
	my $e=shift(@{$data_of{$id}});
	$caller_of{$id}->STORE(_upper($id)); 
	return $e;
}
sub UNSHIFT   { 
	my $self=shift;
	my $id=_id($self);
	unshift(@{$data_of{$id}},@_);
	$caller_of{$id}->STORE(_upper($id)); 
	return; }

sub SPLICE {
	my $self=shift;
	my $id=_id($self);
	my $sz  = scalar @{$data_of{$id}};
	my $off = @_ ? shift : 0;
	$off   += $sz if $off < 0;
	my $len = @_ ? shift : $sz-$off;
	my @rem=splice(@{$data_of{$id}},$off,$len,@_);
	$caller_of{$id}->STORE(_upper($id)); 
	return @rem;
}

# Idea from http://www.perlmonks.org/?node_id=483162
# Method to clone on ithreads
sub CLONE {
    for my $old_reference ( keys %REGISTRY ) {
        my $object = $REGISTRY{ $old_reference };
        my $new_reference = Scalar::Util::refaddr($object);

        $caller_of{$new_reference}=$caller_of{$old_reference};
        delete $caller_of{$old_reference};
        $index_of{$new_reference}=$index_of{$old_reference};
        delete $index_of{$old_reference};
        $data_of{$new_reference}=$data_of{$old_reference};
        delete $data_of{$old_reference};
        $tiearray_of{$new_reference}=$tiearray_of{$old_reference};
        delete $tiearray_of{$old_reference};
        $tiehash_of{$new_reference}=$tiehash_of{$old_reference};
        delete $tiehash_of{$old_reference};
        $tiescalar_of{$new_reference}=$tiescalar_of{$old_reference};
        delete $tiescalar_of{$old_reference};

        Scalar::Util::weaken( 
            $REGISTRY{ $new_reference } = $REGISTRY{ $old_reference } 
            );
        delete $REGISTRY{ $old_reference };
        
    }
}

# DESTROY, needed for inside-out objects:
sub DESTROY {
    my $self=shift;
	my $id=_id($self);

    delete $REGISTRY{$id};
    delete $caller_of{$id};
    delete $index_of{$id};
    delete $data_of{$id};
    delete $tiearray_of{$id};
    delete $tiehash_of{$id};
    delete $tiescalar_of{$id};
}

sub UNTIE {
    my $self=shift;
	my $id=_id($self);

    delete $tiearray_of{$id};
    delete $tiehash_of{$id};
    delete $tiescalar_of{$id};
}

#Retrieve the internal stuff, for debug and maybe hacks :)
sub _data {
    my $self=shift;
	my $id=_id($self);
    return {
        object=>$caller_of{$id},
        key=>$index_of{$id},
        data=>$data_of{$id},
        tied_array=>$tiearray_of{$id},
        tied_hash=>$tiehash_of{$id},
        tied_scalar=>$tiescalar_of{$id},
    };
}
    

1;

__END__

=head1 NAME

Tie::Proxy::Changes - Track changes in your tied objects

=head1 SYNOPSIS

In any tied class:

    use Tie::Proxy::Changes;
    use Tie::Hash;
    
    our @ISA=qw/Tie::StdHash/;
   
    sub FETCH {
        my $self=shift;
        my $key=shift;
        if (exists $self->{$key}) {
            return Tie::Proxy::Changes->new($self,$key,$self->{$key});
        }
        else {
            return Tie::Proxy::Changes->new($self,$key);
        }
    }

=head1 DESCRIPTION

Sometimes a tied object needs to keep track of all changes happening to its
data. This includes substructures with multi-level data. Returning a
C<Tie::Proxy::Changes> object instead of the raw data will result in a STORE 
call whenever the data is changed.

Here is a small example to illustrate to problem.

    package main;
    tie %data 'TiedObject';
    $data{FOO}={}; #Calls STORE(FOO,{})
    $data{FOO}->{Bar}=1; #calls just FETCH.

But when TiedObject is changed, it does this:

    package TiedObject;
    #...
    sub FETCH {
        my $self=shift;
        my $key=shift;
        #... $data=something.
        # return $data # Not anymore.
        return Tie::Proxy::Changes->new($self,$key,$data);
    }
    package main;
    tie %data 'TiedObject';
    $data{FOO}={}; #Calls STORE(FOO,{})
    $data{FOO}->{Bar}=1; #calls FETCH and then STORE(FOO,{Bar=>1}).


=head1 AUTOVIVIFICATION

This module can also (or exclusivly) be used to make autovivification work.
Some tied datastructures convert all mulit-level data they get into tied 
objects.

When perl gets an C<undef> from a FETCH call, it calls STORE with an empty
reference to an array or a hash and then changes that hash. Some tied objects
however can not keep this reference, because they save it in a different way.

The solution is to have FETCH return an empty C<Tie::Proxy::Changes> object, 
and if the object is changed, STORE of the tied object will be called with the
given key

    my $self=shift;
    my $key=shift;
    ...
    #return undef; # Not anymore
    return Tie::Proxy::Changes->new($self,$key);

If the object is just tested for existance of substructures, no STORE is
called.

=head1 METHODS

=head2 new (OBJECT, KEY, [DATA]) 

Creates a new C<Tie::Proxy::Changes>, on every change of its content
C<OBJECT>->STORE(C<KEY>,C<MODIFIED DATA>) is called.

For TIESCALAR objects, KEY has to be set to undef.

=head1 INTERNAL METHODS

=head2 SCALAR

Returns the size of the data.

See L<perltie> (Somehow Pod::Coverage annoys me about this method).

=head1 BUGS

If you find any bugs, please drop me a mail.

=head1 SEE ALSO

L<perltie>

=head1 LICENSE

C<Tie::Proxy::Changes> is published under the terms of the MIT license, which 
basically means "Do with it whatever you want". For more information, see the 
LICENSE file that should be enclosed with this distribution. A copy of the
license is (at the time of this writing) also available at
L<http://www.opensource.org/licenses/mit-license.php>.

=head1 AUTHOR

Marc "Maluku" Sebastian Lucksch

perl@marc-s.de

=cut


