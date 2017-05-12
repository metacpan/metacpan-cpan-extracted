package Tie::Hash::Stack;

#=============================================================================
#
# $Id: Stack.pm,v 0.9 2001/06/30 12:13:46 mneylon Exp $
# $Revision: 0.9 $
# $Author: mneylon $
# $Date: 2001/06/30 12:13:46 $
# $Log: Stack.pm,v $
# Revision 0.9  2001/06/30 12:13:46  mneylon
#
# Initial Release (based on www.perlmonks.org code with some additional
# changes)
#
#
#=============================================================================

use strict;
use Carp;

use Exporter   ();
use vars       qw($VERSION @ISA @EXPORT %EXPORT_TAGS);

$VERSION     = "0.100";
@ISA         = qw(Exporter);
@EXPORT      = qw(push_hash pop_hash shift_hash unshift_hash
		  reverse_hash merge_hash flatten_hash get_depth);
%EXPORT_TAGS = ( );

sub TIEHASH {
    my $self = shift;
    my $newhash = shift || {};
    croak "Argument must be a hashref in Tie::Hash::Stack constructor"
      unless UNIVERSAL::isa( $newhash, 'HASH' );
    my $hash_array = [ $newhash ];         # Create array, with one blank hash
    return bless $hash_array, $self;
}

sub FETCH {
    my $self = shift;
    my $key = shift;

    foreach ( @$self ) {
	# $_ is a hashref!
	return $_->{ $key } if ( exists $_->{ $key } );
    }
    return undef;
}

sub STORE {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    
    $self->[0]->{ $key } = $value;
}

sub DELETE {
    my $self = shift;
    my $key = shift;
    my $return = $self->FETCH( $key );
    foreach ( @$self ) {
	delete $_->{ $key } if ( exists $_->{ $key } );
    }
    return $return;
}


sub CLEAR {
    my $self = shift;
    @$self = ( { } );
}

sub EXISTS {
    my $self = shift;
    my $key = shift;
    foreach ( @$self ) {
	return 1 if exists $_->{ $key };
    }
    return undef;
}

sub FIRSTKEY {
    my $self = shift;
    my %hash;
    foreach ( @$self ) {
	foreach my $key ( keys %$_ ) { 
	    $hash{ $key } = 1;
	}
    }
    my @keys = sort keys %hash;
    return $keys[ 0 ];
}

sub NEXTKEY {
    my $self = shift;
    my $lastkey = shift;
    my %hash;
    foreach ( @$self ) {
	foreach my $key ( keys %$_ ) { 
	    $hash{ $key } = 1;
	}
    }
    my @keys = sort keys %hash;
    my $i = 0;
    $i++ while ( ( $lastkey ne $keys[ $i ] ) 
		&& ( $i < @keys - 1 ) ) ;
    if ( $i == @keys - 1 ) {
	return ();
    } else {
	return $keys[ $i+1 ];
    }
}

sub DESTROY {
}

sub merge_hash (\%) {
    my $href = shift;
    my $obj = tied %$href;
    croak "must be a Tie::Hash::Stack tied hash"
      unless $obj and $obj->isa('Tie::Hash::Stack');
    my %hash;
    foreach ( reverse @$obj ) {
	foreach my $key ( keys %$_ ) { 
	    $hash{ $key } = $_->{ $key };
	}
    }
    return %hash;
}

sub flatten_hash(\%) {
    my $href = shift;
    my $obj = tied %$href;
    croak "must be a Tie::Hash::Stack tied hash"
      unless $obj and $obj->isa('Tie::Hash::Stack');
    my %hash = merge_hash %$href;
    @$obj = ( \%hash );
}


sub push_hash (\%;\%) {
    my $href = shift;
    my $obj = tied %$href;
    my $addhash = shift || {};
    croak "First argument must be a Tie::Hash::Stack tied hash in push_hash"
      unless $obj and $obj->isa('Tie::Hash::Stack');
    croak "Second argument must be a hashref in push_hash"
      unless UNIVERSAL::isa( $addhash, 'HASH' );
    unshift @$obj, $addhash;
}

sub pop_hash (\%) {
    my $href = shift;
    my $obj = tied %$href;
    croak "First argument must be a Tie::Hash::Stack tied hash in pop_hash"
      unless $obj and $obj->isa('Tie::Hash::Stack');
    shift @$obj;
    @$obj = ( { } ) if !@$obj;
}

sub unshift_hash (\%;\%) {
    my $href = shift;
    my $obj = tied %$href;
    my $addhash = shift || {};
    croak "First argument must be a Tie::Hash::Stack tied hash in unshift_hash"
      unless $obj and $obj->isa('Tie::Hash::Stack');
    croak "Second argument must be a hashref in unshift_hash"
      unless UNIVERSAL::isa( $addhash, 'HASH' );
    push @$obj, $addhash;
}

sub shift_hash (\%) {
    my $href = shift;
    my $obj = tied %$href;
    croak "First argument must be a Tie::Hash::Stack tied hash in shift_hash"
      unless $obj and $obj->isa('Tie::Hash::Stack');
    pop @$obj;
    @$obj = ( { } ) if !@$obj;
}

sub reverse_hash (\%) {
    my $href = shift;
    my $obj = tied %$href;
    croak "First argument must be a Tie::Hash::Stack tied hash in shift_hash"
      unless $obj and $obj->isa('Tie::Hash::Stack');
    @$obj = reverse @$obj;
}

sub get_depth (\%) {
    my $href = shift;
    my $obj = tied %$href;
    croak "First argument must be a Tie::Hash::Stack tied hash in shift_hash"
      unless $obj and $obj->isa('Tie::Hash::Stack');
    return @$obj - 1;
}

42;

__END__

=head1 NAME

Tie::Hash::Stack - Maintains an array of hashes like a stack.

=head1 SYNOPSIS

    use Tie::Hash::Stack qw(pop_hash push_hash merge_hash);

    my %hash;
    tie( %hash, "Tie::Hash::Stack" );   # Ties the hash

    $hash{ 1 } = "one";
    $hash{ 2 } = "two";
    $hash{ 3 } = "three";

    push_hash %hash;               # Pushes a new hash on the stack

    $hash{ 2 } = "II";             # $hash{ 2 } now 'II'
    $hash{ 4 } = "IV";

    push_hash %hash;

    $hash{ 3 } = "9/3";            # $hash{ 3 } now '9/3'
    $hash{ 5 } = "10/2";

    pop_hash %hash;                # $hash{ 3 } now 'three';

    delete $hash{ 2 };             # $hash{ 2 } now undef'ed;

    my %merged = merge_hash %hash; # ( 1=>one, 3=>three, 4=>IV )

=head1 DESCRIPTION

C<Tie::Hash::Stack> allows one to tie a hash to a data structure that
is composed of an ordered (FILO) sequence of hashes; hash values are
always set on the newest hash of the stack, and are retrieved from
the hash that contains the requested that is newest on the stack.
The stack can be manipulated to add or remove these hashes.  This
type of structure is good when one is collecting data in stages with
the possibility of having to "back up" to previous stages.

In cases where the same key is in two or more hashes on the stack,
the value from the most recent hash containing that key will be
returned.

When C<tie>'d, the new hash will already have one hash on the stack,
so that it can be used without any extra code. Optionally, a hash
reference may be passed which will be used as the initial hash within
the array.

Besides the standard hash functions, there are several functions that can
be accessed through the tie'd hash variable.

=over

=item C<push_hash>

Pushes an empty hash onto the hash; any further hash assignments will
be placed into this hash until it is removed, or a new hash pushed
onto the stack.  A optional second argument may be a reference to a
hash which will be pushed onto the stack instead of an empty one.

=item C<pop_hash>

Removes the last hash on the stack after deleting the values from it.
If all hashes are removed, the stack is reset with an empty hash.

=item C<shift_hash>, C<unshift_hash>

Complimentary functions of C<pop_hash> and C<push_hash>; removes the
hash at the front of the stack, or adds a new hash to the front of
the stack. C<unshift_hash> also takes a similar optional second
argument as with C<push_hash>.

=item C<merge_hash>

Merges all the hashes into one and returns this new (untied) hash;
duplicated keys are treated as described above.  The hash stack is 
left untouched.

=item C<flatten_hash>

This is similar to C<merge_hash>, but in this case, the merged hash
is then set as the only hash on the stack for this object, all other
data being thrown away.  No return value is returned in this case.

=item C<reverse_hash>

Flips the order of the hashes around.

=item C<get_depth>

Returns the number of hashes currently on the stack.

=back

=head1 HISTORY

    $Date: 2001/06/30 12:13:46 $

    $Log: Stack.pm,v $
    Revision 0.9  2001/06/30 12:13:46  mneylon

    Initial Release (based on www.perlmonks.org code with some additional
    changes)


=head1 AUTHOR

This package was written by Michael K. Neylon

=head1 COPYRIGHT

Copyright 2001 by Michael K. Neylon

=head1 LICENSE

This program is Copyright 2001 by Michael K. Neylon.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut

