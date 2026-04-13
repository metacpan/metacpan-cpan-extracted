#!/usr/bin/false
# ABSTRACT: Lightweight user detail sub-object returned by various Bugzilla API responses
# PODNAME: WebService::Bugzilla::UserDetail

package WebService::Bugzilla::UserDetail 0.001;
use strictures 2;
use Moo;
use namespace::clean;

has email     => (is => 'ro');
has id        => (is => 'ro');
has name      => (is => 'ro');
has nick      => (is => 'ro');
has real_name => (is => 'ro');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::Bugzilla::UserDetail - Lightweight user detail sub-object returned by various Bugzilla API responses

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    my $activity = $bz->flag_activity->get;
    for my $flag (@{$activity}) {
        say 'Set by: ', $flag->setter->name;
        if ($flag->requestee) {
            say 'Requested from: ', $flag->requestee->name;
        }
    }

=head1 DESCRIPTION

Lightweight data container for user information embedded in various API
responses.  Simpler than L<WebService::Bugzilla::User> and typically used
for display purposes.

Instances are created internally by service classes when parsing API
responses that include user data (comments, bug history, flag activity,
etc.).

=head1 ATTRIBUTES

All attributes are read-only.

=over 4

=item C<email>

The user's email address.

=item C<id>

Numeric user ID.

=item C<name>

Display name (usually the login name).

=item C<nick>

Nickname, if set.

=item C<real_name>

The user's full real name.

=back

=head1 SEE ALSO

L<WebService::Bugzilla::User> - full user objects with more attributes and methods

L<WebService::Bugzilla::Comment> - comments (which include creator details)

L<WebService::Bugzilla::FlagActivity> - flag activity (which includes setter/requestee details)

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
