package WWW::ORCID;

use strict;
use warnings;

our $VERSION = 0.0401;

use Class::Load qw(try_load_class);
use Carp;
use namespace::clean;

my $DEFAULT_VERSION = '2.0';

sub new {
    my $self    = shift;
    my $opts    = ref $_[0] ? {%{$_[0]}} : {@_};
    my $version = $opts->{version} ||= $DEFAULT_VERSION;
    $version =~ s/\./_/g;
    $version .= '_public' if $opts->{public};
    my $class = "WWW::ORCID::API::v${version}";
    try_load_class($class) or croak("Could not load $class: $!");
    $class->new($opts);
}

1;

__END__

=pod

=head1 NAME

WWW::ORCID - A client for the ORCID 2.0 API

=head1 SYNOPSIS

    my $client = WWW::ORCID->new(client_id => "XXX", client_secret => "XXX");

    my $client = WWW::ORCID->new(client_id => "XXX", client_secret => "XXX", sandbox => 1);

    my $client = WWW::ORCID->new(client_id => "XXX", client_secret => "XXX", public => 1);

=head1 DESCRIPTION

A client for the ORCID 2.x API.

=head1 STATUS

The client is mostly complete. The 2.0 member API is implemented except C<notification-permission>. The 2.0
public API is implemented except C<identifiers> and C<status>. The 2.1 member
API has not yet been implemented.

=head1 CREATING A NEW INSTANCE

The C<new> method returns a new L<2.0 API client|WWW::ORCID::API::v2_0>.

Arguments to new:

=head2 C<client_id>

Your ORCID client id (required).

=head2 C<client_secret>

Your ORCID client secret (required).

=head2 C<version>

The only possible value at the moment is C<"2.0"> which will load L<WWW::ORCID::API::v2_0> or L<WWW::ORCID::API::v2_0_public>.

=head2 C<sandbox>

The client will use the API sandbox if set to C<1>.

=head2 C<public>

The client will use the L<ORCID public API|https://pub.sandbox.orcid.org/v2.0>
if set to C<1>. Default is the
L<ORCID member API|https://pub.sandbox.orcid.org/v2.0>.

=head2 C<transport>

Specify the HTTP client to use. Possible values are L<LWP> or L<HTTP::Tiny>.
Default is L<LWP>.

=head1 METHODS

Please refer to the API clients L<WWW::ORCID::API::v2_0> and L<WWW::ORCID::API::v2_0_public> for method documentation.

=head1 SEE ALSO

L<https://api.orcid.org/v2.0/#/Member_API_v2.0>

=head1 AUTHOR

Patrick Hochstenbach C<< <patrick.hochstenbach at ugent.be> >>

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

Simeon Warner C<< <simeon.warner at cornell.edu> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
