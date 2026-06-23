package WWW::Gitea::Attachment;

# ABSTRACT: Gitea attachment / asset entity

use Moo;
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has data => (
    is       => 'rw',
    required => 1,
);


sub id                   { $_[0]->data->{id} }
sub name                 { $_[0]->data->{name} }
sub size                 { $_[0]->data->{size} }
sub download_count       { $_[0]->data->{download_count} }
sub uuid                 { $_[0]->data->{uuid} }
sub browser_download_url { $_[0]->data->{browser_download_url} }
sub created_at           { $_[0]->data->{created_at} }



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Gitea::Attachment - Gitea attachment / asset entity

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    my $assets = $gitea->releases->assets('getty', 'p5-www-gitea', 5);

    for my $a (@$assets) {
        print $a->name, " (", $a->size, " bytes) -> ",
              $a->browser_download_url, "\n";
    }

=head1 DESCRIPTION

Lightweight wrapper around the JSON returned for a Gitea attachment (also
called an "asset"). Attachments are returned by the release-asset and
issue/comment-attachment endpoints. The raw decoded data is always available
via L</data>; mutation runs through the controllers
(L<WWW::Gitea::API::Releases>, L<WWW::Gitea::API::Issues>).

=head2 data

Raw decoded JSON for the attachment.

=head2 id

Numeric attachment ID.

=head2 name

Display name of the attachment.

=head2 size

Size of the attachment in bytes.

=head2 download_count

Number of times the attachment has been downloaded.

=head2 uuid

The attachment's UUID.

=head2 browser_download_url

Direct download URL for the attachment.

=head2 created_at

ISO-8601 creation timestamp.

=head1 SEE ALSO

=over 4

=item * L<WWW::Gitea>

=item * L<WWW::Gitea::API::Releases>

=item * L<WWW::Gitea::API::Issues>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://codeberg.org/getty/p5-www-gitea/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
