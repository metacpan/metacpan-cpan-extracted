package XML::NewsML_G2::News_Message;

use Moose;
use namespace::autoclean;

# header elements
has 'sent',
    isa     => 'DateTime',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_sent';

has 'destination',
    isa     => 'ArrayRef[XML::NewsML_G2::Destination]',
    is      => 'ro',
    default => sub { [] },
    traits  => ['Array'],
    handles => { add_destination => 'push' };

#news/package items
has 'items',
    isa     => 'ArrayRef[XML::NewsML_G2::AnyItem]',
    is      => 'rw',
    default => sub { [] },
    traits  => ['Array'],
    handles => { add_item => 'push' };

sub _build_sent {
    return DateTime->now( time_zone => 'local' );
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::News_Message - a container that can hold multiple News
or Package Items

=for test_synopsis
    my (%text_params, %pic_params);

=head1 SYNOPSIS

    my $nm = XML::NewsML_G2::News_Message->new();
    my $ni_text = XML::NewsML_G2::News_Item_Text->new(%text_params);
    my $ni_picture = XML::NewsML_G2::News_Item_Picture->new(%pic_params);
    $nm->add_item($ni_text);
    $nm->add_item($ni_picture);

=head1 ATTRIBUTES

=over 4

=item sent

Timestemp generated automatically

=item destination

Intended target for news message

=item items

A collection of news and/or package items

=back

=head1 AUTHOR

Stefan Hrdlicka  C<< <stefan.hrdlicka@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
