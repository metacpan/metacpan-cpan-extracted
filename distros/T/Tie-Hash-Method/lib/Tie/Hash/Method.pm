package Tie::Hash::Method;
use strict;
use warnings;
use base 'Exporter';

=head1 NAME

Tie::Hash::Method - Tied hash with specific methods overriden by callbacks

=head1 VERSION

Version 0.02

=cut

our $VERSION= '0.02';
$VERSION= eval $VERSION;    # just in case we have a dev release
our @EXPORT_OK= qw(tie_hash_method HASH METHOD PRIVATE);

use constant HASH => 0;
use constant METHOD => 1;
use constant PRIVATE => 2;
use Data::Dumper;

# not overridable obviously.
sub TIEHASH {
    my $class= shift;
    my %opts= @_;
    #die Dumper 
    bless [
            {}, #HASH
            +{ map { $_ => $opts{$_} } grep {$_ eq uc($_) } keys %opts }, #METHOD
            +{ map { $_ => $opts{$_} } grep {$_ ne uc($_) } keys %opts }, #PRIVATE
           ], $class;
}

sub FETCH {
    if ( my $cb= $_[0][METHOD]->{FETCH} ) {
        return $cb->(@_);
    } else {
        return $_[0][HASH]->{ $_[1] };
    }
}

sub STORE {
    if ( my $cb= $_[0][METHOD]->{STORE} ) {
        return $cb->(@_);
    } else {
        return $_[0][HASH]->{ $_[1] }= $_[2];
    }
}

sub EXISTS {
    if ( my $cb= $_[0][METHOD]->{EXISTS} ) {
        return $cb->(@_);
    } else {
        exists $_[0][HASH]->{ $_[1] };
    }
}

sub DELETE {
    if ( my $cb= $_[0][METHOD]->{DELETE} ) {
        return $cb->(@_);
    } else {
        delete $_[0][HASH]->{ $_[1] };
    }
}


sub FIRSTKEY {
    if ( my $cb= $_[0][METHOD]->{FIRSTKEY} ) {
        return $cb->(@_);
    } else {
        # reset iterator
        my $val= scalar keys %{ $_[0][HASH] };
        return each %{ $_[0][HASH] };
    }
}

sub NEXTKEY {
    if ( my $cb= $_[0][METHOD]->{NEXTKEY} ) {
        return $cb->(@_);
    } else {
        return each %{ $_[0][HASH] };
    }
}


sub CLEAR {
    if ( my $cb= $_[0][METHOD]->{CLEAR} ) {
        return $cb->(@_);
    } else {
        return %{ $_[0][HASH] }= ();
    }
}

sub SCALAR {
    if ( my $cb= $_[0][METHOD]->{SCALAR} ) {
        return $cb->(@_);
    } else {
        return scalar %{ $_[0][HASH] };
    }
}

sub methods {
    return grep { $_ ne 'hash' } keys %{ $_[0][METHOD] };
}

sub method_hash : lvalue { $_[0][METHOD] }

sub base_hash : lvalue { $_[0][HASH] }
sub h         : lvalue { $_[0][HASH] }
sub private_hash : lvalue { $_[0][PRIVATE] }
sub p            : lvalue { $_[0][PRIVATE] }

sub hash_overload {
    tie my %hash, __PACKAGE__, @_;
    return \%hash;
}

1;    #make require happy

__END__

=head1 SYNOPSIS

    tie my %hash, 'Tie::Hash::Method',
        FETCH => sub {
            exists $_[0]->base_hash->{$_[1]} ? $_[0]->base_hash->{$_[1]} : $_[1]
        };

=head1 DESCRIPTION

Tie::Hash::Method provides a way to create a tied hash with specific
overriden behaviour without having to create a new class to do it. A tied
hash with no methods overriden is functionally equivalent to a normal hash.

Each method in a standard tie can be overriden by providing a callback
to the tie call. So for instance if you wanted a tied hash that changed
'foo' into 'bar' on store you could say:

    tie my %hash, 'Tie::Hash::Method',
        STORE => sub {
            (my $v=pop)=~s/foo/bar/g if defined $_[2];
            return $_[0]->base_hash->{$_[1]}=$v;
        };

The callback is called with exactly the same arguments as the tie itself, in
particular the tied object is always passed as the first argument. 

The tied object is itself an array, which contains a second hash in the 
HASH slot (index 0) which is used to perform the default operations. 

The callbacks available are in a hash keyed by name in the METHOD slot of
the array (index 1). 

If your code needs to store extra data in the object it should be stored 
in the PRIVATE slot of the object (index 2). No future release of this module
will ever use or alter anything in that slot.

The arguments passed to the tie constructor will be seperated by the case of 
their keys. The ones with all capitals will be stored in the METHOD hash, and
the rest will be stored in the PRIVATE hash.

=head2 CALLBACKS

=over 4

=item STORE this, key, value

Store datum I<value> into I<key> for the tied hash I<this>.

=item FETCH this, key

Retrieve the datum in I<key> for the tied hash I<this>.

=item FIRSTKEY this

Return the first key in the hash.

=item NEXTKEY this, lastkey

Return the next key in the hash.

=item EXISTS this, key

Verify that I<key> exists with the tied hash I<this>.

=item DELETE this, key

Delete the key I<key> from the tied hash I<this>.

=item CLEAR this

Clear all values from the tied hash I<this>.

=item SCALAR this

Returns what evaluating the hash in scalar context yields.

=back

=head2 Methods

=over 4

=item base_hash

return or sets the underlying hash for this tie.

    $_[0]->base_hash->{$key}= $value;

=item h

alias for base_hash.

    $_[0]->h->{$key}= $value;

=item private_hash

Return or sets the hash of private data associated with this tie. This
value will never be touched by any code in this class or its subclasses. 
It is purely object specific.

    $_[0]->p->{'something'}= 'cake!';

=item p 

alias for private_hash

=item method_hash

return or sets the hash of methods that are overriden for this tie. Exactly
why you would want to use this is a little beyond my imagination, but for those
who can think of a reason here is a nice way to do it. :-)

=item methods

Returns a list of methods that are overriden for this tie. Why this would be useful
escapes me, but here it is anyway for Completeness sake, whoever she is, but people
are always coding for her so I might as well too.

=back

=head2 Exportable Subs

The following subs are exportable on request:

=over 4

=item hash_overload(PAIRS)

Returns a reference to a hash tied with the specified
callbacks overriden. Just a short cut.

=item HASH

Constant subroutine equivalent to 0

=item METHOD

Constant subroutine equivalent to 1

=item PRIVATE

Constant subroutine equivalent to 2

=back


=head1 AUTHOR

Yves Orton, C<< <yves at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tie-hash-method at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Hash-Method>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::Hash::Method


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Hash-Method>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tie-Hash-Method>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tie-Hash-Method>

=item * Search CPAN

L<http://search.cpan.org/dist/Tie-Hash-Method>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Yves Orton, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

