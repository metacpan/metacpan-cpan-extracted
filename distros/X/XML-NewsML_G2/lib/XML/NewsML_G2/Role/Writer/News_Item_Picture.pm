package XML::NewsML_G2::Role::Writer::News_Item_Picture;

use Moose::Role;
use namespace::autoclean;

with 'XML::NewsML_G2::Role::Writer';

around '_build_g2_catalog_schemes' => sub {
    my ( $orig, $self, @args ) = @_;
    my $result = $self->$orig(@args);
    $result->{rnd} = undef;
    $result->{colsp} = undef;
    return $result;
};

before '_create_authors' => sub {
    my ($self, $root) = @_;

    if ($self->news_item->photographer) {
        my $c = $self->_create_creator($self->news_item->photographer);
        $root->appendChild($c);
        $self->scheme_manager->add_qcode($c, 'crol', 'photographer');
    }
    return;
};

after '_create_remote_content' => sub {
    my ($self, $root, $picture) = @_;

    foreach (qw/size width height orientation/) {
        $root->setAttribute( $_, $picture->$_ ) if defined $picture->$_;
    }

    my $rendition =
        $self->scheme_manager->build_qcode('rnd', $picture->rendition);
    $root->setAttribute('rendition', $rendition) if $rendition;

    my $colsp =
        $self->scheme_manager->build_qcode('colsp', $picture->colorspace);
    $root->setAttribute('colourspace', $colsp) if $colsp;

    if (my $altId=$picture->altId) {
        $root->appendChild($self->create_element('altId', _text => $altId));
    }

};

1;
__END__

=head1 NAME

XML::NewsML_G2::Role::Writer::News_Item_Picture - Role for writing news items of type 'picture'

=head1 DESCRIPTION

This module serves as a role for all NewsML-G2 writer classes and get automatically applied when the according news item type is written

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
