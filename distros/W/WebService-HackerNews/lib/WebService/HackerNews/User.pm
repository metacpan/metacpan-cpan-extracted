package WebService::HackerNews::User;
$WebService::HackerNews::User::VERSION = '0.05';
use Moo;

has id        => (is => 'ro');
has delay     => (is => 'ro');
has created   => (is => 'ro');
has karma     => (is => 'ro');
has about     => (is => 'ro');
has submitted => (is => 'ro');

1;

=head1 NAME

WebService::HackerNews::User - a data object representing a HackerNews registered user

=head1 SYNOPSIS

 use WebService::HackerNews::User;
 my $item = WebService::HackerNews::Item->new(
                id    => 'frodo',
                karma => 1234,
                # more attributes
            );

=head1 DESCRIPTION

This module is a class for data objects returned by the C<user()> method
of L<WebService::HackerNews>.

The objects have the following attributes, which are named after
properties listed in the
L<Item documentation|https://github.com/HackerNews/API#users>:

=over 4

=item * B<id>        - The user's unique username. Case-sensitive. Required.

=item * B<delay>     - Delay in minutes between a comment's creation and its visibility to other users.

=item * B<created>   - Creation date of the user, in Unix Time.

=item * B<karma>     - The user's karma.

=item * B<about>     - The user's optional self-description. HTML.

=item * B<submitted> - List of the user's stories, polls and comments.

=back

=head1 SEE ALSO

L<WebService::HackerNews>

=head1 REPOSITORY

L<https://github.com/neilbowers/WebService-HackerNews>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

