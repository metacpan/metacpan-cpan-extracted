package Tie::Hash::Sorted;
require 5.005_03;
use strict;
use Carp;
use vars '$VERSION';
use UNIVERSAL 'isa';

use constant FIRST_KEY     => -1;
use constant STORED_HASH   =>  0;
use constant ITERATOR      =>  1;
use constant SORTED_KEYS   =>  2;
use constant SORT_ROUTINE  =>  3;
use constant STORE_ROUTINE =>  4;
use constant CHANGED       =>  5;
use constant OPTIMIZATION  =>  6;

$VERSION = '0.10';

BEGIN { *NEXTKEY = \&_FetchKey };

sub TIEHASH {
    my $class = shift;
    croak "Incorrect number of parameters" if @_ % 2;
    my $self = bless [], $class;
    $self->_Build(@_);
    return $self;
}

sub FETCH {
    my($self, $key) = @_;
    return $self->[STORED_HASH]{$key};
}

sub STORE {
    my ($self, $key, $value) = @_;
    $self->[STORE_ROUTINE]{$self->[OPTIMIZATION]}->($self, $key, $value);
    return;
}

sub EXISTS {
    my($self, $key) = @_;
    return exists $self->[STORED_HASH]{$key};
}

sub DELETE {
    my($self, $key) = @_;
    if (exists $self->[STORED_HASH]{$key}) {
        $self->[CHANGED] = 1;
        return delete $self->[STORED_HASH]{$key};
    }    
    return undef;
}

sub FIRSTKEY {
    my $self = shift;
    $self->_ReOrder if $self->[OPTIMIZATION] eq 'none' || $self->[CHANGED];
    $self->[ITERATOR] = FIRST_KEY;
    return $self->_FetchKey;
}

sub CLEAR {
    my $self = shift;
    %{$self->[STORED_HASH]} = ();
    @{$self->[SORTED_KEYS]} = ();
    $self->[CHANGED] = 1;
    return;
}

sub DESTROY {
    return;
}

sub Sort_Routine {
    my ($self, $sort) = @_;
    croak "Not a code ref" if ! isa($sort, 'CODE');
    $self->[SORT_ROUTINE] = $sort;
    $self->[CHANGED] = 1;
    return;
}

sub Optimization {
    my ($self, $type) = @_;
    $type ||= 'default';
    croak "Invalid optimization type"
        if $type !~ /^(?:default|none|keys|values)$/;
    $self->[OPTIMIZATION] = $type;
    $self->[CHANGED] = 1;
}

sub Resort {
    my $self = shift;
    $self->[CHANGED] = 1;
    return;
}

sub Count {
    my $self = shift;
    return scalar keys %{$self->[STORED_HASH]};
}

sub _Build {
    my ($self, %opt) = @_;
    my $sort = $opt{Sort_Routine} || sub {
        my $hash = shift;
        [ sort {$a cmp $b || $a <=> $b} keys %$hash ];
    };

    $self->Sort_Routine($sort);
    $self->Optimization($opt{Optimization});

    my $hash = $opt{Hash} || {};
    croak "$hash is not a hash ref" if ! isa($hash, 'HASH');
    @{$self->[STORED_HASH]}{keys %$hash} = values %$hash;

    $self->[STORE_ROUTINE] = {
        'default' => \&_Store_NoOpt,
        'none'    => \&_Store_NoOpt,
        'keys'    => \&_Store_KeyOpt,
        'values'  => \&_Store_ValueOpt
    };
    return;
}

sub _ReOrder {
    my $self = shift;
    $self->[SORTED_KEYS] = $self->[SORT_ROUTINE]->($self->[STORED_HASH]);
    $self->[CHANGED] = 0;
    return;
}

sub _FetchKey {
    my ($self, $lastkey) = @_;
    $self->[ITERATOR]++;
    return $self->[SORTED_KEYS][$self->[ITERATOR]];
}

sub _Store_KeyOpt {
    my($self, $key, $value) = @_;
    $self->[CHANGED] = 1 if ! exists $self->[STORED_HASH]{$key};
    $self->[STORED_HASH]{$key} = $value;
    return;
}

sub _Store_ValueOpt {
    my($self, $key, $value) = @_;
    $self->[CHANGED] = 1 if $value ne $self->[STORED_HASH]{$key};
    $self->[STORED_HASH]{$key} = $value;
    return;
}

sub _Store_NoOpt {
    my($self, $key, $value) = @_;
    $self->[STORED_HASH]{$key} = $value;
    $self->[CHANGED] = 1;
    return;
}

1;
__END__
=head1 NAME

Tie::Hash::Sorted - Presents hashes in sorted order

=head1 VERSION

Version 0.07 released on 11 Sept 2003

=head1 SYNOPSIS

 use Tie::Hash::Sorted;

 my %ages = (
     'John'   => 33,
     'Jacob'  => 29,
     'Jingle' => 15,
     'Heimer' => 48,
     'Smitz'  => 12,
 );

 my $sort_by_numeric_value = sub {
     my $hash = shift;
     [ sort {$hash->{$b} <=> $hash->{$a}} keys %$hash ];
 };

 tie my %sorted_ages, 'Tie::Hash::Sorted',
     'Hash'         => \ %ages,
     'Sort_Routine' => $sort_by_numeric_value;

 for my $name ( keys %sorted_ages ) {
     print "$name is $sorted_ages{$name} years old.\n";
 }

 ### OUTPUT ###
 Heimer is 48 ears old.
 John is 33 ears old.
 Jacob is 29 ears old.
 Jingle is 15 ears old.
 Smitz is 12 ears old.

=head1 DESCRIPTION

This module presents hashes in sorted order.

=head1 SYNTAX

In order to C<tie()> your hash to C<Tie::Hash::Sorted>:

 tie HASH, 'Tie::Hash::Sorted', [OPTIONS => VALUE];

or

 HASHREF = tie HASH, 'Tie::Hash::Sorted', [OPTIONS => VALUE];

=head1 OPTIONS

=over 4

=item Hash

If you do not want to start with an empty hash, you can specify a hash
reference

=item Sort_Routine

If you do not want to use the default sort routine, you can specify a code
reference. The sub is very flexible with the following two requirements. It
must accept a hash reference as its only argument and it must return an array
reference.

The funtion is passed a reference to an unsorted hash and is expected to
return the correct order for the hash's keys.

 sub {
     my $unsorted_hash = shift;
     return [ sort keys %$unsorted_hash ];
 }

=back

=head2 Optimization

There are four different kinds of optimization.

=over 4

=item default

By default, the hash will remain sorted until a re-sort is required. Changes
will set a flag to re-sort the hash the next time it is iterated over.

=item none

This will cause the hash to be re-sorted once every time you iterate over the
hash. Use it if the sort routine depends on something that can't be detected
in the tied hash. Perhaps you have a hash of hashes (HoH) sorted by the
number of second level keys.

Even if you fall into this category, you may be able to use the default
optimization. You can use L<"Resort"> after any change you know the tied
hash can't detect.

=item keys

This optimization works the same as the default except it will not set the
flag for re-sorting if the only change detected is to an already existing
value.

=item values

This optimization works the same as the default except it will not set the
flag for re-sorting if the new value is the same as the old value.

=back

=head1 METHODS

=head2 Sort_Routine

You can change the sort routine at any time. The change will take affect when
you iterate over the hash.

 tie my %sorted_hash, 'Tie::Hash::Sorted', 'Hash' => \%hash;
 my $sort = sub {
     my $hash = shift;
     return [ sort { $a cmp $b || $a <=> $b } keys %$hash ];
 };
 tied( %sorted_hash ) -> Sort_Routine( $sort );

=head2 Optimization

You can change the optimization promise at any time.

 tie my %sorted_hash, 'Tie::Hash::Sorted', 'Hash' => \%hash;
 my $sort = sub {
     my $hash = shift;
     return [ sort { $a cmp $b || $a <=> $b } keys %$hash ];
 };
 tied( %sorted_hash ) -> Optimization( 'keys' );

=head2 Resort

This method sets the flags for re-sorting the next time you iterate over the
hash. It would typically only be used in with Optimization => 'none'. Call
this method after changes that you don't expect Tie::Hash::Sorted to be able
to notice.

 my @months = qw(January March April June August December);
 my (%data, %order);

 @data{@months} = (33, 29, 15, 48, 23, 87);
 @order{@months} = (1, 3, 4, 6, 8, 12);

 my $sort = sub {
     my $hash = shift;    
     return [ sort {$order{$a} <=> $order{$b}} keys %$hash ];
 };

 tie my %sorted_data, 'Tie::Hash::Sorted', 
     'Hash'         => \%data,
     'Sort_Routine' => $sort,
     'Optimization' => 'none';

 for my $month ( keys %sorted_data ) {
     print "$month had $sorted_data{$month} million sales.\n";
 }
 # More code that iterates over the hash
 # Since there are no changes, you get the benefits of no re-sorting

 @order{@months} = (12, 8, 6, 4, 3, 1);

 # Tie::Hash::Sorted doesn't know that %order just changed so we'll force
 # the issue.
 tied( %sorted_data ) -> Resort;

 for my $month ( keys %sorted_data ) {
     print "$month had $sorted_data{$month} million sales.\n";
 }

=head2 Count

Current versions of perl (so far, 5.8.1 and below) implement
C<scalar keys %tied_hash> poorly. Use the Count method instead to get the
number of elements in the hash.

 my %data = ( a=>1, b=>2, c=>3, d=>4 );
 tie my %sorted_data, 'Tie::Hash::Sorted', 'Hash' => \%data;
 print tied( %sorted_data ) -> Count, "\n";

=head1 AUTHORS

Joshua Gatcomb, <Limbic_Region_2000@Yahoo.com>

Joshua Jore, <jjore@cpan.org>

Currently maintained by Joshua Gatcomb, <Limbic_Region_2000@Yahoo.com>

=head1 ACKNOWLEDGEMENTS

This module was inspired by Tie::SortHash.

Various people from PerlMonks (L<http://www.perlmonks.org>) provided
invaluable input.

=head1 BUGS

None known.  Bug reports, fixes, and feedback are desired.

=head1 CAVEATS

As of this release, tied hashes always return 0 in scalar context and false
in boolean context. You might want to consider using L<"Count"> as an
alternative.

=head1 COPYRIGHT

 Copyright (c) 2003 Joshua Gatcomb. All rights reserved.
 This program is free software; you can redistribute it
 and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>(1), L<perltie>

README for a comparison to Tie::IxHash and Tie::SortHash

=cut
