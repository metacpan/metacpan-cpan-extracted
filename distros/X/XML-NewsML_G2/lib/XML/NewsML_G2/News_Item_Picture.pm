package XML::NewsML_G2::News_Item_Picture;

use Moose;
use namespace::autoclean;

extends 'XML::NewsML_G2::News_Item';

has '+nature', default => 'picture';
has '+remotes', isa => 'HashRef[XML::NewsML_G2::Picture]';

has 'photographer', isa => 'Str', is => 'rw';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::News_Item_Picture - a picture news item

=for test_synopsis
    my ($provider, $service, $genre1, $genre2);

=head1 SYNOPSIS

    my $ni = XML::NewsML_G2::News_Item_Picture->new
        (guid => "tag:example.com,2013:service:date:number",
         title => "Story title",
         slugline => "the/slugline",
         language => 'de',
         provider => $provider,
         service => $service,
         photographer => 'Homer Simpson'
        );

    my $pic = XML::NewsML_G2::Picture->new
        (mimetype => 'image/jpg',
         rendition => 'highRes',
         width => 1600,
         height => 1024
        );

    my $thumb = XML::NewsML_G2::Picture->new
        (mimetype => 'image/jpg',
         rendition => 'thumb',
         width => 48,
         height => 32
        );
    $ni->add_remote('file://tmp/files/123.jpg', $pic);
    $ni->add_remote('file://tmp/files/123.thumb.jpg', $thumb);

=head1 ATTRIBUTES

=over 4

=item photographer

A photographer string

=back

=head1 AUTHOR

Christian Eder  C<< <christian.eder@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
