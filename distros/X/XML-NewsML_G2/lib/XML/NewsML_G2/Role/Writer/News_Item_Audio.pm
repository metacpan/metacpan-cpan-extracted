package XML::NewsML_G2::Role::Writer::News_Item_Audio;

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
    my ($self, $root, $audio) = @_;

    for (qw/size duration audiosamplerate/) {
        $root->setAttribute( $_, $audio->$_ ) if defined $audio->$_;
    }

    my $audiochannels = $self->scheme_manager->build_qcode('adc', $audio->audiochannels);
    $root->setAttribute('audiochannels', $audiochannels) if $audiochannels;
    return;
};

1;
__END__

=head1 NAME

XML::NewsML_G2::Role::Writer::News_Item_Audio - Role for writing news items of type 'audio'

=head1 DESCRIPTION

This module serves as a role for all NewsML-G2 writer classes and get automatically applied when the according news item type is written

=head1 AUTHOR

Mario Paumann  C<< <mario.paumann@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
