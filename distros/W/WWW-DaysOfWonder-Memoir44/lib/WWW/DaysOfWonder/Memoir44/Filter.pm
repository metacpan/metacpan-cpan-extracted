#
# This file is part of WWW-DaysOfWonder-Memoir44
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package WWW::DaysOfWonder::Memoir44::Filter;
# ABSTRACT: filter object
$WWW::DaysOfWonder::Memoir44::Filter::VERSION = '3.000';
use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

with 'MooseX::Getopt::GLD';


use WWW::DaysOfWonder::Memoir44::Types;


# -- public attributes


has ids => (
    rw, auto_deref,
    isa           => 'ArrayRef[Int]',
    predicate     => 'has_ids',
    traits        => [ qw{ Getopt } ],
    cmd_aliases   => [ qw{ i } ],
);

has name => (
    rw,
    isa           => 'Str',
    predicate     => 'has_name',
    traits        => [ qw{ Getopt } ],
    cmd_aliases   => [ qw{ n } ],
);

has operation => (
    rw,
    isa           => 'Str',
    predicate     => 'has_operation',
    traits        => [ qw{ Getopt } ],
    cmd_aliases   => [ qw{ o } ],
);

has front => (
    rw,
    isa           => 'Str',
    predicate     => 'has_front',
    traits        => [ qw{ Getopt } ],
    cmd_aliases   => [ qw{ w } ],
);

has format => (
    rw,
    isa           => 'Format',
    predicate     => 'has_format',
    traits        => [ qw{ Getopt } ],
    cmd_aliases   => [ qw{ fmt f } ],
);

has board => (
    rw,
    isa           => 'Board',
    predicate     => 'has_board',
    traits        => [ qw{ Getopt } ],
    cmd_aliases   => [ qw{ b } ],
);



has tp   => ( rw, isa=>'Bool' );
has ef   => ( rw, isa=>'Bool' );
has mt   => ( rw, isa=>'Bool' );
has pt   => ( rw, isa=>'Bool' );
has ap   => ( rw, isa=>'Bool' );
has bm   => ( rw, isa=>'Bool' );
has cb   => ( rw, isa=>'Bool' );



has languages => (
    rw, auto_deref,
    isa           => 'ArrayRef[Str]',
    predicate     => 'has_languages',
    traits        => [ qw{ Getopt } ],
    cmd_aliases   => [ qw{ lang l } ],
);

has rating => (
    rw, coerce,
    isa           => 'Int_0_3',
    predicate     => 'has_rating',
    traits        => [ qw{ Getopt } ],
    cmd_aliases   => [ qw{ rate r } ],
);


# -- public methods


sub as_grep_clause {
    my $self = shift;
    my @clauses;

    # ** filtering on scenario information
    # - ids
    if ( $self->has_ids ) {
        my $clause = join( '||', map { "\$_->id == $_" } $self->ids );
        push @clauses, "($clause)";
    }

    # - name
    push @clauses, '$_->name =~ qr{' . $self->name . '}i'
        if $self->has_name;

    # - operation
    push @clauses, '$_->operation =~ qr{' . $self->operation . '}i'
        if $self->has_operation;

    # - front
    push @clauses, '$_->front =~ qr{' . $self->front . '}i'
        if $self->has_front;

    # - format
    push @clauses, '$_->format eq q{' . $self->format . '}'
        if $self->has_format;

    # - board
    push @clauses, '$_->board eq q{' . $self->board . '}'
        if $self->has_board;

    # ** filtering on extensions
    foreach my $expansion ( qw{ tp ef pt mt ap } ) {
        next unless defined $self->$expansion;
        my $clause = '$_->need_';
        $clause    = "!$clause" unless $self->$expansion;
        push @clauses, $clause . $expansion;
    }

    # ** filtering on meta-information
    # - languages
    if ( $self->has_languages ) {
        my $clause  = 'join(",",$_->languages) =~ /\Q';
        $clause .= join "\\E|\\Q", $self->languages;
        $clause .= '\E/';
        push @clauses, $clause;
    }

    # - rating
    push @clauses, '$_->rating >= ' . $self->rating
        if $self->has_rating;

    my $grep = "sub { " . join(" && ", (1,@clauses)) . " }";
    return eval $grep;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::DaysOfWonder::Memoir44::Filter - filter object

=head1 VERSION

version 3.000

=head1 DESCRIPTION

This module represents a filter that can be applied to the list of
scenarios.

=head1 ATTRIBUTES

=head2 ids

Scenario id (if multiple entries, only one of them need to match).
Alias: C<i>.

=head2 name

Scenario name. Alias: C<n>.

=head2 operation

Scenario operation. Alias: C<o>.

=head2 format

Scenario format. Aliases: C<fmt> or C<f>.

=head2 board

Scenario board. Alias: C<b>.

=head2 my $bool = $scenario->tp;

Whether terrain pack extension is required.

=head2 my $bool = $scenario->ef;

Whether eastern front extension is required.

=head2 my $bool = $scenario->mt;

Whether mediterranean theater extension is required.

=head2 my $bool = $scenario->pt;

Whether pacific theater extension is required.

=head2 my $bool = $scenario->ap;

Whether air pack extension is required.

=head2 my $bool = $scenario->bm;

Whether battle maps extension is required.

=head2 my $bool = $scenario->cb;

Whether campaign book extension is required.

=head2 languages

Languages accepted for a scenario (if multiple entries, only one of them
need to match). Aliases: C<lang> or C<l>.

=head2 rating

Minimum scenario rating (integer between 0 and 3). Aliases: C<rate> or
C<r>.

=head1 METHODS

=head2 as_grep_clause

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
