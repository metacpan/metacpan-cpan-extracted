package XML::NewsML_G2::News_Item_Audio;

use Moose;
use namespace::autoclean;

extends 'XML::NewsML_G2::News_Item';

has '+nature',  default => 'audio';
has '+remotes', isa     => 'HashRef[XML::NewsML_G2::Audio]';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::News_Item_Audio - a audio news item (story)

=for test_synopsis
    my ($provider, $service, $genre1, $genre2);

=head1 SYNOPSIS

    my $ni = XML::NewsML_G2::News_Item_Audio->new
        (guid => "tag:example.com,2013:service:date:number",
         title => "Story title",
         slugline => "the/slugline",
         language => 'de',
         provider => $provider,
         service => $service,
        );

    $ni->add_genre($genre1, $genre2);
    $ni->add_source('APA');
    my $audio = XML::NewsML_G2::Audio->new(
        size => '23013531', duration => 30, audiochannels => 'stereo',
        mimetype => 'audio/mpeg'
    );

    $ni->add_remote('file:///tmp/files/123.mp3', $audio);


=head1 AUTHOR

Mario Paumann  C<< <mario.paumann@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
