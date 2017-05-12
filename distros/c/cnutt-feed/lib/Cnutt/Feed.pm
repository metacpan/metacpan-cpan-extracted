package Cnutt::Feed;

use strict;
use warnings;

use Pod::Usage;
use Getopt::Long;

use Cnutt::Feed::Actions::List;
use Cnutt::Feed::Actions::Get;
use Cnutt::Feed::Actions::Fetch;

=encoding utf8

=head1 NAME

Cnutt::Feed - A rss/atom reader which delivers entries to your mailboxes

=head1 VERSION

Version 1.1

=cut

our $VERSION = '1.1';

=head1 DESCRIPTION

See cnutt-feed manual.

=head1 METHODS

=head2 new

=cut

sub new {
	my $class = shift;
	my %options = @_;
	my $self = \%options;
	bless $self;
	return $self;
}

=head2 ls

List the feeds from an url.

=cut

sub ls {
	my $options = shift;
    my $url = shift;

    Cnutt::Feed::Actions::List::ls($options, $url);
}

=head2 get

Take an url and a mailbox on the command line and download the feed to
the mailbox.

=cut

sub get {
	my $options = shift;
    my $url = shift;
    my $mb = shift;

    Cnutt::Feed::Actions::Get::get($options, $url, $mb);
}

=head2 fetch

Take a feed name and fetch it according the config file data.

=cut

sub fetch {
	my $options = shift;
    my @names = @_;

    Cnutt::Feed::Actions::Fetch::fetch($options, @names);
}

=head1 AUTHOR

Olivier Schwander, C<< <olivier.schwander at ens-lyon.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cnutt-feed at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=cnutt-feed>. I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

A darcs repository is available here :

L<http://chadok.info/darcs/cnutt/cnutt-feed>

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=cnutt-feed>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/cnutt-feed>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/cnutt-feed>

=item * Search CPAN

L<http://search.cpan.org/dist/cnutt-feed>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007-2008 Olivier Schwander, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

