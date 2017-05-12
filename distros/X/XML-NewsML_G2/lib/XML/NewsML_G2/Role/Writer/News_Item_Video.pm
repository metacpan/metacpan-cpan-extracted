package XML::NewsML_G2::Role::Writer::News_Item_Video;

use Moose::Role;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::Writer';

around '_build_g2_catalog_schemes' => sub {
    my ( $orig, $self, @args ) = @_;
    my $result = $self->$orig(@args);
    $result->{rnd} = undef;
    return $result;
};


after '_create_remote_content' => sub {
    my ($self, $root, $video) = @_;

    foreach (qw/size width height duration videoframerate videoavgbitrate audiosamplerate/) {
        $root->setAttribute( $_, $video->$_ ) if defined $video->$_;
    }

    my $audiochannels = $self->scheme_manager->build_qcode('adc', $video->audiochannels);
    $root->setAttribute('audiochannels', $audiochannels) if $audiochannels;
};

sub _create_icon {
    my ($self, $root) = @_;

    for my $icon (@{$self->news_item->icon}) {
        my $rendition = $self->scheme_manager->build_qcode('rnd', $icon->rendition);
        my $icon_element = $self->create_element(
            'icon',
            rendition => $rendition,
        );

        foreach (qw/href width height/) {
            next unless $icon->$_;
            $icon_element->setAttribute($_, $icon->$_);
        }
        $root->appendChild($icon_element);
    }
    return;
}

1;
__END__

=head1 NAME

XML::NewsML_G2::Role::Writer::News_Item_Video - Role for writing news items of type 'video'

=head1 DESCRIPTION

This module serves as a role for all NewsML-G2 writer classes and get automatically applied when the according news item type is written

=head1 AUTHOR

Stefan Hrdlicka  C<< <stefan.hrdlicka@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
