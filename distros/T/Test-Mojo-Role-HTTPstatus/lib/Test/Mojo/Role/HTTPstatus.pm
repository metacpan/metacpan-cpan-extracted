package Test::Mojo::Role::HTTPstatus;

use strict;
use warnings;
use 5.016; # inherited from Mojolicious

use Mojo::Util qw(encode);

use Role::Tiny;

# Yuck, semver. I give in, the stupid cult that doesn't understand
# what the *number* bit of *version number* means has won.
our $VERSION='1.0.0';

sub status_like {
    my ($self, $status, $desc) = @_;
    $desc = _desc($desc, $self->tx->res->code . " like $status");
    return $self->test('like', $self->tx->res->code, $status, $desc);
}

sub status_unlike {
    my ($self, $status, $desc) = @_;
    $desc = _desc($desc, $self->tx->res->code . " unlike $status");
    return $self->test('unlike', $self->tx->res->code, $status, $desc);
}

# copied from Test::Mojo. If no $desc is provided to status_(un)like
# then use the default that those methods define
sub _desc { encode 'UTF-8', shift || shift }

sub status_is_client_error {
    $_[0]->status_like(qr/^4\d\d$/a, $_[0]->tx->res->code.' is client error');
}

sub status_is_empty {
    $_[0]->status_like(qr/^(1\d\d|[23]04)$/a, $_[0]->tx->res->code.' is empty');
}

sub status_is_error {
    $_[0]->status_like(qr/^[45]\d\d$/a, $_[0]->tx->res->code.' is error');
}

sub status_is_info {
    $_[0]->status_like(qr/^1\d\d$/a, $_[0]->tx->res->code.' is info');
}

sub status_is_redirect {
    $_[0]->status_like(qr/^3\d\d$/a, $_[0]->tx->res->code.' is redirect');
}

sub status_is_server_error {
    $_[0]->status_like(qr/^5\d\d$/a, $_[0]->tx->res->code.' is server error');
}

sub status_is_success {
    $_[0]->status_like(qr/^2\d\d$/a, $_[0]->tx->res->code.' is success');
}

=encoding utf8

=head1 NAME

Test::Mojo::Role::HTTPstatus

=head1 DESCRIPTION

Role to add some extra methods to Test::Mojo for testing routes' HTTP status codes

=head1 SYNOPSIS

  use Test::More;
  use Test::Mojo::WithRoles qw(HTTPstatus);

  my $t = Test::Mojo::WithRoles->new('MyApp');

  $t->get_ok('/success')->status_like(qr/^2/);
  $t->get_ok('/failure')->status_is_error();

  done_testing();

=head1 METHODS

C<status_like> does most of the work behind the scenes. For completeness, its
opposite C<status_unlike> is also provided.

=over

=item status_like

  $t = $t->status_like(qr/^4/);
  $t = $t->status_like(qr/^4/, 'some kind of error');

Pass if the status matches a given regex.

=item status_unlike

  $t = $t->status_unlike(qr/^3/);
  $t = $t->status_unlike(qr/^3/, 'not any kind of redirect');

Pass if the status does B<not> match the given regex.

=back

The various C<status_is_*> methods match the C<is_*> methods in
L<Mojo::Message::Response>.

=over

=item status_is_client_error

Matches a C<4xx> status code.

=item status_is_empty

Matches a C<1xx>, C<204>, or C<304> status code.

=item status_is_error

Matches a C<4xx> or C<5xx> status code.

=item status_is_info

Matches a C<1xx> status code.

=item status_is_redirect

Matches a C<3xx> status code.

=item status_is_server_error

Matches a C<5xx> status code.

=item status_is_success

Matches a C<2xx> status code.

=back

=head1 BUGS

None known, plenty lurking no doubt. Please report any bugs that you find on
Github:

L<https://github.com/DrHyde/perl-modules-Test-Mojo-Role-HTTPstatus/issues>

or even better, raise a pull request that fixes it. The best pull requests
include at least two commits, the first being a test that fails, and then in the
following commits a code change that makes that test pass, and documentation. I
realise that it is difficult to work in that manner, but C<git rebase -i> will
let you edit history to pretend that's what you did.

=head1 SEE ALSO

L<Test::Mojo>

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2020 David Cantrell E<lt>david@cantrell.org.ukE<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
