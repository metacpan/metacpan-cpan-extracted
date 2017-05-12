use strict;
use warnings;

package WWW::ArsenalFC::TicketInformation::Category;
{
  $WWW::ArsenalFC::TicketInformation::Category::VERSION = '1.123160';
}

use WWW::ArsenalFC::TicketInformation::Util ':all';

# ABSTRACT: Represents categories for upcoming Premier League fixtures.

use Object::Tiny qw{
  category
  date_string
  opposition
};

sub date {
    my ($self) = @_;

    if ( $self->date_string =~ /\w+\W+(\w+)\D(\d+)/ ) {
        my $year  = '2012';                # FIXME
        my $month = month_to_number($1);
        my $day   = $2;
        $day = "0$day" if $day =~ /^\d$/;
        return "$year-$month-$day";
    }
}

1;



=pod

=head1 NAME

WWW::ArsenalFC::TicketInformation::Category - Represents categories for upcoming Premier League fixtures.

=head1 VERSION

version 1.123160

=head1 ATTRIBUTES

=head2 category

The category of the match (A, B or C).

=head2 date_string

The date as it appears on the website.

=head2 opposition

The opposition.

=head1 METHODS

=head2 date

The date as YYYY-MM-DD.

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

