package XML::NewsML_G2::News_Item_Video;

use Moose;
use namespace::autoclean;

extends 'XML::NewsML_G2::News_Item';

has '+nature',  default => 'video';
has '+remotes', isa     => 'HashRef[XML::NewsML_G2::Video]';
has 'icon',
    isa     => 'ArrayRef[XML::NewsML_G2::Icon]',
    is      => 'rw',
    default => sub { [] },
    traits  => ['Array'],
    handles => { add_icon => 'push', has_icon => 'count' };

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::News_Item_Video - a video news item (story)

=for test_synopsis
    my ($provider, $service, $genre1, $genre2);

=head1 SYNOPSIS

    my $ni = XML::NewsML_G2::News_Item_Video->new
        (guid => "tag:example.com,2013:service:date:number",
         title => "Story title",
         slugline => "the/slugline",
         language => 'de',
         provider => $provider,
         service => $service,
        );

    $ni->add_genre($genre1, $genre2);
    $ni->add_source('APA');
    my $hd = XML::NewsML_G2::Video->new(
        width => 1920, height => 1080,
        size => '23013531', duration => 30, audiochannels => 'stereo'
    );

    $ni->add_remote('file:///tmp/files/123.hd.mp4', $hd);


=head1 AUTHOR

Stefan Hrdlicka  C<< <stefan.hrdlicka@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
