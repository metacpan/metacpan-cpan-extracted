package WWW::Ohloh::API::Projects;

use strict;
use warnings;

use Carp;
use Object::InsideOut;
use XML::LibXML;
use Readonly;
use List::MoreUtils qw/ none any /;

use overload '<>' => \&next;

our $VERSION = '0.3.2';

my @all_read : Field : Default(0);
my @cache_of : Field;
my @total_entries_of : Field : Default(-1);
my @ohloh_of : Field : Arg(ohloh);
my @page_of : Field : Default(0);
my @query_of : Field : Arg(query);
my @sort_order_of : Field : Arg(sort) :
  Type(\&WWW::Ohloh::API::Projects::is_allowed_sort);
my @max_entries_of : Field : Arg(max) : Get(max);

Readonly our @ALLOWED_SORTING => map { $_, $_ . '_reverse' }
  qw/ created_at description id name stack_count updated_at /;

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub is_allowed_sort {
    my $s = shift;
    return any { $s eq $_ } @ALLOWED_SORTING;
}

sub _init : Init {
    my $self = shift;

    $cache_of[$$self] = [];    # initialize to empty array

    if ( my $s = $sort_order_of[$$self] ) {
        if ( none { $s eq $_ } @ALLOWED_SORTING ) {
            croak "sorting order given: $s, must be one of the following: "
              . join ', ' => @ALLOWED_SORTING;
        }
    }
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub next {
    my $self = shift;
    my $nbr_requested = shift || 1;

    while ( @{ $cache_of[$$self] } < $nbr_requested
        and not $all_read[$$self] ) {
        $self->_gather_more;
    }

    my @bunch = splice @{ $cache_of[$$self] }, 0, $nbr_requested;

    if (@bunch) {
        return wantarray ? @bunch : $bunch[0];
    }

    # we've nothing else to return

    $page_of[$$self]  = 0;
    $all_read[$$self] = 0;

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _gather_more {
    my $self = shift;

    my ( $url, $xml ) = $ohloh_of[$$self]->_query_server(
        'projects.xml',
        {   ( query => $query_of[$$self] ) x !!$query_of[$$self],
            ( sort => $sort_order_of[$$self] ) x !!$sort_order_of[$$self],
            page => ++$page_of[$$self] } );

    my @new_batch =
      map {
        WWW::Ohloh::API::Project->new(
            ohloh => $ohloh_of[$$self],
            xml   => $_,
          )
      } $xml->findnodes('project');

    # get total projects + where we are

    $total_entries_of[$$self] =
      $xml->findvalue('/response/items_available/text()');

    my $first_item = $xml->findvalue('/response/first_item_position/text()');

    $all_read[$$self] = 1 unless $total_entries_of[$$self];

    if ( $first_item + @new_batch - 1 >= $total_entries_of[$$self] ) {
        $all_read[$$self] = 1;
    }

    if ( my $max = $self->max ) {
        if ( $first_item + @new_batch - 1 >= $max ) {
            @new_batch = splice @new_batch, 0, $max - $first_item;
            $all_read[$$self] = 1;
        }
    }

    push @{ $cache_of[$$self] }, @new_batch;

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub all {
    my $self = shift;

    unless ( $self->max ) {
        croak "call to all only permitted if 'max' set in get_projects()";
    }

    $self->_gather_more until ( $all_read[$$self] );

    my @bunch = @{ $cache_of[$$self] };
    $cache_of[$$self] = [];

    $page_of[$$self]  = 0;
    $all_read[$$self] = 0;

    return @bunch;
}

'end of WWW::Ohloh::API::Projects';
__END__

=head1 NAME

WWW::Ohloh::API::Projects - a set of Ohloh projects

=head1 SYNOPSIS

    use WWW::Ohloh::API;

    my $ohloh = WWW::Ohloh::API->new( api_key => $my_api_key );
    my $projects = $ohloh->get_projects( query => 'Ohloh', max => 100 );

    while ( my $p = $projects->next ) {
        print $p->name;
    }

=head1 DESCRIPTION

W::O::A::Projects returns the results of an Ohloh project query.
To be properly populated, it must be created via
the C<get_projects> method of a L<WWW::Ohloh::API> object.

The results of a query are not all captured at the call of
<get_projects>, but are retrieved from Ohloh as required, usually
by batches of 25 items.  

=head1 METHODS 

=head2 next( [ $n ] )

Return the next project of the set or, if I<$n> is given,
the I<$n> following projects (or all remaining projects if they
are less than I<$n>). When all projects have been returned, C<next()>
returns C<undef> once, and then restarts from the beginning.

Examples:

    # typical iterator
    while( my $project = $projects->next ) {
        print $project->name;
    }

    # read projects 10 at a time
    while( my @p = $project->next( 10 ) ) {
        # do something with them...
    }

=head2 all

Return all the remaining projects of the set. A call
to C<all()> immediatly reset the set. I.e., a subsequent call
to C<next()> would return the first project of the set, not I<undef>.

As a precaution against
memory meltdown, calls to C<all()> are not permited unless the parameter
I<max> of C<get_projects> has been set.

Example:

    my $projects = $ohloh->get_projects( sort => 'stack_count', max => 100 );
    # get the first project special
    $top = $projects->next;
    # get the rest
    @most_stacked = $projects->all;

=head1 OVERLOADING

=head2 Iteration

If called on a W:O:A:Projects object, the iteration operator (<>) acts
as a call to '$projects->next'.

E.g.,

    while( my $p = <$projects> ) { 
        ### do stuff with $p
    }

=head1 SEE ALSO

=over

=item * 

L<WWW::Ohloh::API>, 
L<WWW::Ohloh::API::Project>,
L<WWW::Ohloh::API::Analysis>, 
L<WWW::Ohloh::API::Account>.


=item *

Ohloh API reference: http://www.ohloh.net/api/getting_started

=item * 

Ohloh Account API reference: http://www.ohloh.net/api/reference/project

=back

=head1 VERSION

This document describes WWW::Ohloh::API version 0.3.2

=head1 BUGS AND LIMITATIONS

WWW::Ohloh::API is very extremely alpha quality. It'll improve,
but till then: I<Caveat emptor>.

Please report any bugs or feature requests to
C<bug-www-ohloh-api@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Yanick Champoux  C<< <yanick@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Yanick Champoux C<< <yanick@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.



