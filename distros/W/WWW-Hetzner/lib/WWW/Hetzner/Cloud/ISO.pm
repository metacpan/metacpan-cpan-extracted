package WWW::Hetzner::Cloud::ISO;
# ABSTRACT: Hetzner Cloud ISO object

our $VERSION = '0.101';

use Moo;
use namespace::clean;


has _client => (
    is       => 'ro',
    required => 1,
    weak_ref => 1,
    init_arg => 'client',
);

has id => ( is => 'ro' );


has name => ( is => 'ro' );


has description => ( is => 'ro' );


has type => ( is => 'ro' );


has architecture => ( is => 'ro' );


has deprecation => ( is => 'ro' );


has deprecated => ( is => 'ro' );


sub data {
    my ($self) = @_;
    return {
        id           => $self->id,
        name         => $self->name,
        description  => $self->description,
        type         => $self->type,
        architecture => $self->architecture,
        deprecation  => $self->deprecation,
        deprecated   => $self->deprecated,
    };
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::Hetzner::Cloud::ISO - Hetzner Cloud ISO object

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    my $iso = $cloud->isos->get_by_name('netboot.xyz.iso');

    print $iso->name, "\n";         # netboot.xyz.iso
    print $iso->description, "\n";  # netboot.xyz
    print $iso->type, "\n";         # public
    print $iso->architecture, "\n"; # x86

    $cloud->servers->attach_iso($server_id, $iso->name);

=head1 DESCRIPTION

This class represents a Hetzner Cloud ISO image. Objects are returned by
L<WWW::Hetzner::Cloud::API::ISOs> methods.

ISOs are read-only resources.

=head2 id

ISO ID.

=head2 name

ISO name, e.g. "netboot.xyz.iso". This is what
L<WWW::Hetzner::Cloud::API::Servers/attach_iso> expects.

=head2 description

Human-readable description.

=head2 type

ISO type: public or private.

=head2 architecture

CPU architecture the ISO can be attached to: x86 or arm. undef for ISOs
that are not bound to an architecture.

=head2 deprecation

Deprecation hashref with C<announced> and C<unavailable_after> timestamps,
undef unless the ISO is deprecated.

=head2 deprecated

Legacy deprecation timestamp. Superseded by C<deprecation> in the current
API; kept for responses that still carry it.

=head2 data

    my $hashref = $iso->data;

Returns all ISO data as a hashref (for JSON serialization).

=head1 SEE ALSO

=over 4

=item * L<WWW::Hetzner::Cloud::API::ISOs> - ISOs API

=item * L<WWW::Hetzner::Cloud> - Main Cloud API client

=item * L<WWW::Hetzner::Cloud::API::Servers> - Servers API (attach_iso, detach_iso)

=item * L<WWW::Hetzner> - Main umbrella module

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-www-hetzner/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
