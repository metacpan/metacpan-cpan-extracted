package XML::NewsML_G2::News_Item_Text;

use Moose;
use namespace::autoclean;

extends 'XML::NewsML_G2::News_Item';

has '+nature', default => 'text';

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::News_Item_Text - a text news item (story)

=for test_synopsis
    my ($provider, $service, $genre1, $genre2);

=head1 SYNOPSIS

    my $ni = XML::NewsML_G2::News_Item_Text->new
        (guid => "tag:example.com,2013:service:date:number",
         title => "Story title",
         slugline => "the/slugline",
         language => 'de',
         provider => $provider,
         service => $service,
        );

    $ni->add_genre($genre1, $genre2);
    $ni->add_source('APA');
    $ni->add_paragraph('blah blah blah');

=head1 ATTRIBUTES

For a list of attributes, please see L<XML::NewsML_G2::News_Item>.

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.
