use v5.10.1;
use strict;
use warnings;

package WWW::ArsenalFC::TicketInformation;
{
  $WWW::ArsenalFC::TicketInformation::VERSION = '1.123160';
}

# ABSTRACT: Get Arsenal FC ticket information for forthcoming matches

use WWW::ArsenalFC::TicketInformation::Match;
use WWW::ArsenalFC::TicketInformation::Match::Availability;
use WWW::ArsenalFC::TicketInformation::Category;

use LWP::Simple              ();
use HTML::TreeBuilder::XPath ();

# the URL on Arsenal.com
use constant URL => 'http://www.arsenal.com/membership/buy-tickets';

use Object::Tiny qw{
  categories
  matches
};

sub fetch {
    my ($self) = @_;

    $self->_fetch_categories();
    $self->_fetch_matches();
}

sub _fetch_categories {
    my ($self) = @_;

    my $tree = $self->_get_tree();
    my @categories;

    # get the categories table
    my $rows = $tree->findnodes('//table[@summary="Match categories"]//tr');

    my %categories_hash = ();
    for ( my $i = 1 ; $i < $rows->size() ; $i++ ) {
        my $row = $rows->[$i];

        my $category = WWW::ArsenalFC::TicketInformation::Category->new(
            date_string => $row->findvalue('td[1]'),
            opposition  => $row->findvalue('td[2]'),
            category    => $row->findvalue('td[3]'),
        );

        push @categories, $category;

        # used to assign the category to a match later
        my $category_key =
          sprintf( "%s:%s", $category->opposition, $category->date );
        $categories_hash{$category_key} = $category->category;
    }

    $self->{categories}      = \@categories;
    $self->{categories_hash} = \%categories_hash;
}

sub _fetch_matches {
    my ($self) = @_;

    my $tree = $self->_get_tree();
    my @matches;

    # get the table and loop over every 3 rows, as these
    # contain the matches
    # the second and third rows contain data on who can purchase tickets, if
    # its not yet sold out or on the exchange.
    my $rows = $tree->findnodes('//table[@id="member-tickets"]/tr');
    for ( my $i = 0 ; $i < $rows->size() ; $i += 3 ) {
        my %match = ();
        my $row   = $rows->[$i];

        $match{fixture}     = _trimWhitespace( $row->findvalue('td[2]/p[1]') );
        $match{competition} = _trimWhitespace( $row->findvalue('td[2]/p[2]') );
        $match{datetime_string} =
          _trimWhitespace( $row->findvalue('td[2]/p[3]') );
        $match{hospitality} = $row->exists(
            'td[3]//a[@href="http://www.arsenal.com/hospitality/events"]');

        $match{is_soldout}   = $row->exists('td[6]//span[@class="soldout"]');
        $match{can_exchange} = 0;

        if ( !$match{is_soldout} ) {

          AVAILABILITY:
            for ( my $j = $i ; $j < $i + 3 ; $j++ ) {
                my $availability_row = $rows->[$j];

                my @membership_nodes;
                if ( $j == $i ) {
                    @membership_nodes =
                      $availability_row->findnodes('td[5]/img[@title]');
                }
                else {
                    @membership_nodes =
                      $availability_row->findnodes('td[1]/img[@title]');
                }

                last AVAILABILITY unless @membership_nodes;

                my ( $availability_forsale, $availability_date );
                if ( $j == $i ) {
                    ( $availability_forsale, $availability_date ) =
                      _parse_availability(
                        $availability_row->findvalue('td[6]/p') );
                }
                else {
                    ( $availability_forsale, $availability_date ) =
                      _parse_availability(
                        $availability_row->findvalue('td[2]/p') );
                }

                my @memberships_for_availability;
                for my $membership_node (@membership_nodes) {
                    my $membership = $membership_node->attr('title');
                    given ($membership) {
                        when (/Exchange/) {
                            $match{can_exchange} = 1;
                            last AVAILABILITY;
                        }
                        when (/General Sale/) {
                            push( @memberships_for_availability,
                                WWW::ArsenalFC::TicketInformation::Match::Availability
                                  ->GENERAL_SALE );
                        }
                        when (/Red Members/) {
                            push( @memberships_for_availability,
                                WWW::ArsenalFC::TicketInformation::Match::Availability
                                  ->RED );
                        }
                        when (/Silver Members/) {
                            push( @memberships_for_availability,
                                WWW::ArsenalFC::TicketInformation::Match::Availability
                                  ->SILVER );
                        }
                        when (/Platinum \/ Gold Members/) {
                            push( @memberships_for_availability,
                                WWW::ArsenalFC::TicketInformation::Match::Availability
                                  ->PLATINUM_GOLD );
                        }
                        when (/Travel Club/) {
                            push( @memberships_for_availability,
                                WWW::ArsenalFC::TicketInformation::Match::Availability
                                  ->TRAVEL_CLUB );
                        }
                    }    # given ($membership)
                    $match{availability} //= [];

                }
                if ($availability_forsale) {

                    push @{ $match{availability} },
                      WWW::ArsenalFC::TicketInformation::Match::Availability
                      ->new(
                        memberships => \@memberships_for_availability,
                        type =>
                          WWW::ArsenalFC::TicketInformation::Match::Availability
                          ->FOR_SALE,
                      );
                }
                elsif ($availability_date) {
                    push @{ $match{availability} },
                      WWW::ArsenalFC::TicketInformation::Match::Availability
                      ->new(
                        memberships => \@memberships_for_availability,
                        type =>
                          WWW::ArsenalFC::TicketInformation::Match::Availability
                          ->SCHEDULED,
                        date => $availability_date
                      );
                }
            }    # for my $membership_node (@membership_nodes)
        }

        my $match = WWW::ArsenalFC::TicketInformation::Match->new(%match);

        # add the category if we can
        my $category_key = sprintf( "%s:%s", $match->opposition, $match->date );
        if ( my $category = $self->{categories_hash}->{$category_key} ) {
            $match->{category} = $category;
        }

        push @matches, $match;
    }

    $self->{matches} = \@matches;
}

# populates an HTML::TreeBuilder::XPath tree, unless we already have one
sub _get_tree {
    my ($self) = @_;

    if ( !$self->{tree} ) {
        $self->{tree} =
          HTML::TreeBuilder::XPath->new_from_content( LWP::Simple::get(URL) );
    }

    return $self->{tree};
}

sub _parse_availability {
    my ($availability) = @_;

    given ($availability) {
        when (/Buy Now/) {
            return 1;
        }
        when (/(\d\d-\d\d-\d\d\d\d)/) {
            return ( undef, $1 );
        }
    }
}

# trims whitespace from a string
sub _trimWhitespace {
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

1;


__END__
=pod

=head1 NAME

WWW::ArsenalFC::TicketInformation - Get Arsenal FC ticket information for forthcoming matches

=head1 VERSION

version 1.123160

=head1 SYNOPSIS

  my $ticket_information = WWW::ArsenalFC::TicketInformation->new();
  $ticket_information->fetch();

  for my $match (@{$ticket_info->matches}){
    # WWW::ArsenalFC::TicketInformation::Match objects
  }
  
  for my $category (@{$ticket_info->categories}){
    # WWW::ArsenalFC::TicketInformation::Category objects
  }

=head1 DESCRIPTION

This is a module to get and parse the Arsenal ticket information for forthcoming matches (from http://www.arsenal.com/membership/buy-tickets).

Hint: Try L<aliased> to save some typing when using this module.

=head1 ATTRIBUTES

=head2 matches

An array reference of L<WWW::ArsenalFC::TicketInformation::Match> objects.

=head2 categories

An array reference of L<WWW::ArsenalFC::TicketInformation::Category> objects.

=head1 METHODS

=head2 fetch()

Fetches and parses the Arsenal ticket information. Populates C<matches> and C<categories>.

=head1 EXAMPLES

An example of using this module to send out emails when tickets become available is available at https://gist.github.com/3728775.

=head1 SEE ALSO

=over 4

=item *

L<WWW::ArsenalFC::TicketInformation::Match>

=item *

L<WWW::ArsenalFC::TicketInformation::Category>

=back

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

