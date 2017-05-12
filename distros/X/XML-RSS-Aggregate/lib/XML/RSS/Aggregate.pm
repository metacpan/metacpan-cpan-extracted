# $File: //member/autrijus/XML-RSS-Aggregate/lib/XML/RSS/Aggregate.pm $ $Author: autrijus $
# $Revision: #4 $ $Change: 2924 $ $DateTime: 2002/12/25 15:04:33 $

package XML::RSS::Aggregate;
$XML::RSS::Aggregate::VERSION = '0.02';

use strict;
use XML::RSS;
use base 'XML::RSS';

use Date::Parse;
use LWP::Simple 'get';
use HTML::Entities 'encode_entities';

=head1 NAME

XML::RSS::Aggregate - RSS Aggregator

=head1 SYNOPSIS

    my $rss = XML::RSS::Aggregate->new(
        # parameters for XML::RSS->channel()
        title   => 'Aggregated Examples',
        link    => 'http://blog.elixus.org/',

        # parameters for XML::RSS::Aggregate->aggregate()
        sources => [ qw(
            http://one.example.com/index.rdf
            http://another.example.com/index.rdf
            http://etc.example.com/index.rdf
        ) ],
        sort_by => sub {
            $_[0]->{dc}{subject}    # default to sort by dc:date
        },
        uniq_by => sub {
            $_[0]->{title}          # default to uniq by link
        }
    );

    $rss->aggregate( sources => [ ... ] );  # more items
    $rss->save("all.rdf");

=head1 DESCRIPTION

This module implements a subclass of B<XML::RSS>, adding a single
C<aggregate> method that fetches other RSS feeds and add to the object
itself.  It handles the proper ordering and duplication removal for
aggregated links.

Also, the constructor C<new> is modified to take arguments to pass
implicitly to C<channel> and C<aggregate> methods.

All the base methods are still applicable to this module; please see
L<XML::RSS> for details.

=head1 METHODS

=over 4

=item aggregate (sources=>\@url, sort_by=>\&func, uniq_by=>\&func)

This method fetches all RSS feeds listed in C<@url> and pass their
items to the object's C<add_item>.

The optional C<sort_by> argument specifies the function to use for
ordering RSS items; it defaults to sort them by their C<{dc}{date}>
attribute (converted to absolute timestamps), with ties broken by
their C<{link}> attribute.

The optional C<uniq_by> argument specifies the function to use for
removing duplicate RSS items; it defaults to remove items that has
the same C<{link}> value.

=back

=cut

sub new {
    my ($class, %args) = @_;

    my $version = delete($args{version}) || '1.0';
    my $self    = $class->SUPER::new( version => $version );

    my $sources = delete($args{sources});
    my $sort_by = delete($args{sort_by});

    $self->channel(%args) if %args;
    $self->aggregate(
        sources => $sources,
        sort_by => $sort_by,
    ) if $sources;

    return $self;
}

sub aggregate {
    my ($self, %args) = @_;

    my $sources = $args{sources} or return;
    my $sort_by = $args{sort_by} || sub {
        my $date = $_[0]->{dc}{date};
        $date =~ s/:(\d\d)$/$1/ if $date;
        sprintf("%20s", str2time($date)).$_[0]->{link}
    };
    my $uniq_by = $args{uniq_by} || sub {
        $_[0]->{link}
    };

    my $old_items = $self->{items} || [];
    $self->{items} = [];

    my %saw;
    $self->add_item(%{$_->[0]}) for
        sort { $b->[1] cmp $a->[1] }
        grep { $_->[1] }
        map  { [ $_ => scalar($sort_by->($_)) ] }
        grep { !$saw{$uniq_by->($_)}++ } @{$old_items},
        map  { encode_entities($_, '&<>') for grep {!ref($_)} values %{$_}; $_ }
        map  { encode_entities($_, '&<>') for grep {!ref($_)} values %{$_->{dc}}; $_ }
        map  { encode_entities($_, '&<>') for grep {!ref($_)} values %{$_->{syn}}; $_ }
        map  { encode_entities($_, '&<>') for grep {!ref($_)} @{$_->{taxo}}; $_ }
        map  { eval { (my $rss = XML::RSS->new)->parse(get($_)); @{$rss->{items}} } }
        grep { /^\w+:/ } @{$sources};

    return $self;
}

1;

=head1 SEE ALSO

L<XML::RSS>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2002 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut

__END__
# Local variables:
# c-indentation-style: bsd
# c-basic-offset: 4
# indent-tabs-mode: nil
# End:
# vim: expandtab shiftwidth=4:
