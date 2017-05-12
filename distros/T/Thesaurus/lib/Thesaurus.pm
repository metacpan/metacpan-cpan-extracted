package Thesaurus;

use strict;

use vars qw[$VERSION];

$VERSION = '0.23';

use Params::Validate qw( validate_with BOOLEAN );

sub new
{
    my $class = shift;
    my %p = validate_with( params => \@_,
                           spec => { ignore_case => { type => BOOLEAN, default => 0 },
                                   },
                           allow_extra => 1,
                         );

    my $self = bless { params => { ignore_case => delete $p{ignore_case},
                                 }
                     }, $class;

    $self->_init(%p);

    return bless $self, $class;
}

sub _init
{
    my $self = shift;

    $self->{data} = {};
}

sub add
{
    my $self = shift;

    foreach my $list (@_)
    {
        $self->_add_list($list);
    }
}

sub _add_list
{
    my $self = shift;
    my $list = shift;

    my %items = $self->_hash_from_list($list);

    while ( my ($k, $v) = each %items )
    {
        $self->{data}{$k} = $v;
    }
}

sub _hash_from_list
{
    my $self = shift;
    my $list = shift;

    # if we have any of these already, we need to create new lists for
    # them
    my @new =
        map { $self->find($_) } $self->_normalize_list($list);

    # return a unique list
    my @unique = keys %{ { map { $_ => 1 } @new, @$list } };

    # a hash of keys to values
    return map { ( $self->{params}{ignore_case} ? lc $_ : $_ ) => \@unique } @unique;
}

sub find
{
    my $self = shift;

    my $lists = $self->_find(@_);

    if (@_ > 1)
    {
        return unless %$lists;
        return %$lists;
    }
    else
    {
        return unless exists $lists->{ $_[0] };
        return @{ $lists->{ $_[0] } };
    }
}

sub _find
{
    my $self = shift;

    my %lists;
    foreach my $key (@_)
    {
        my $search_key = $self->{params}{ignore_case} ? lc $key : $key;

        # ignore duplicates
        next if exists $lists{$key};

        # Anonymize to keep people away from our lists!
        $lists{$key} =
            exists $self->{data}{$search_key} ? [ @{ $self->{data}{$search_key} } ] : [];
    }

    return \%lists;
}

sub delete
{
    my $self = shift;

    foreach my $item ( $self->_normalize_list(\@_) )
    {
        next unless exists $self->{data}{$item};

        foreach my $key ( @{ $self->{data}{$item} } )
        {
            delete $self->{data}{$key};
        }
    }
}

sub all
{
    my $self = shift;

    my (%done, @data);
    foreach my $key ( keys %{ $self->{data} } )
    {
        next if exists $done{$key};

        @done{ @{ $self->{data}{$key} } } = ();

        push @data, $self->{data}{$key};
    }

    return @data
}

sub _normalize_list
{
    my $self = shift;
    my $list = shift;

    return map { lc } @$list if $self->{params}{ignore_case};
    return @$list;
}

1;

__END__

=head1 NAME

Thesaurus - Maintains lists of associated items

=head1 SYNOPSIS

 use Thesaurus;

 my $th = Thesaurus->new( -files => [ 'file1', 'file2' ],
                          -ignore_case => 1 );

 @words = $th->find('vegan');

 %words = $th->find( 'Faye' );

 foreach $word ( @{ $words{Faye} } )
 {
     #something ...
 }

 $th->add_file( 'file1', 'file2' );

 $th->add( [ 'tofu', 'mock duck' ] );

 $th->delete( 'meat', 'vivisection' );

=head1 DESCRIPTION

Thesaurus is a module that allows you to create lists of related
things.  It was created in order to facilitate searches of a database
of Chinese names in Anglicized form.  Because there are various
schemes to create phonetic representations of Chinese words, the
following can all represent the same Chinese character:

 Woo
 Wu
 Ng

Thesaurus can be used for anything that fits into a scalar by using
the C<new> method with no parameters and then calling the C<add>
method to add data.

Thesaurus also acts as the parent class to several child classes which
implement various forms of persistence for the data structure.  This
module can be used on its own to instantiate an object that lives for
the life of its scope.

=head1 METHODS

=over 4

=item * new( %params )

The C<new> method returns a Thesaurus object.  It takes the following
parameters:

=over 8

=item * ignore_case => $boolean

If this parameter is true, then the object will be case insensitive.
It is _always_ case-preservative for its data.

=back

=item * find( @items )

 @words = $th->find( 'Big Hat' );
 %words = $th->find( 'Big Hat', 'Faye Wong' );

The C<find> method returns either a list or a hash, depending on
context.  Given a single word to find, it returns the list of words
that it is associated with, including the word that was given.  If no
matches  are found then it returns an empty list.

If it is given multiple words, it returns a hash.  The keys of the has
are the words given, and the keys are list references containing the
associated words.  If no words were found then the key has a value of
0.  If none of the words match then an empty list is returned.

=item * add( \@list1, \@list2 )

The C<add> method takes a list of list references.  Each of these
references should contain a set of associated scalars.  Like the
C<add_files()> method, if an entry in a list matches an entry already
in the object, then it is appended to the existing list, otherwise a
new association is created.

=item * delete( @items )

The C<delete> method takes a list of items to delete.  All the
associations for the given items will be removed.

=item * all

Returns a list of array references.  Each one of these list references
contains one set of associations.  Each association list is returned
once, not once per item it contains.

=back

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 COPYRIGHT

Copyright (c) 1999-2003 David Rolsky. All rights reserved. This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=head1 SEE ALSO

Thesaurus::CSV, Thesaurus::BerkeleyDB

=cut
