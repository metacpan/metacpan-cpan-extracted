package WebService::HackerNews::Item;
$WebService::HackerNews::Item::VERSION = '0.05';
use Moo;

has id      => (is => 'ro');
has deleted => (is => 'ro');
has type    => (is => 'ro');
has by      => (is => 'ro');
has time    => (is => 'ro');
has text    => (is => 'ro');
has dead    => (is => 'ro');
has parent  => (is => 'ro');
has kids    => (is => 'ro');
has url     => (is => 'ro');
has score   => (is => 'ro');
has title   => (is => 'ro');
has parts   => (is => 'ro');

1;

=head1 NAME

WebService::HackerNews::Item - a HackerNews story, job, comment, poll or pollopt

=head1 SYNOPSIS

 use WebService::HackerNews::Item;
 my $item = WebService::HackerNews::Item->new(
                id   => 123,
                type => 'story',
                # more attributes
            );

=head1 DESCRIPTION

This module is a class for data objects returned by the C<item()> method
of L<WebService::HackerNews>.

The objects have the following attributes, which are named after
properties listed in the
L<Item documentation|https://github.com/HackerNews/API#items>:

=over 4

=item * B<id> - The item's unique id. Required.

=item * B<deleted> - true if the item is deleted.

=item * B<type> - The type of item. One of "job", "story", "comment", "poll", or "pollopt".

=item * B<by> - The username of the item's author.

=item * B<time> - Creation date of the item, in Unix Time.

=item * B<text> - The comment, Ask HN, or poll text. HTML.

=item * B<dead> - true if the item is dead.

=item * B<parent> - The item's parent. For comments, either another comment or the relevant story. For pollopts, the relevant poll.

=item * B<kids>  - The ids of the item's comments, in ranked display order.

=item * B<url>   - The URL of the story.

=item * B<score> - The story's score, or the votes for a pollopt.

=item * B<title> - The title of the story or poll.

=item * B<parts> - A list of related pollopts, in display order.

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

