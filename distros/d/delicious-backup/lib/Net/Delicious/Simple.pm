package Net::Delicious::Simple;
use strict;
use warnings;

use Config::Auto;
use Date::Parse;
use Net::Delicious;

=head1 NAME

Net::Delicious::Simple - Net::Delicious for backups

=head1 VERSION

version 0.013

=cut

our $VERSION = '0.013';

=head1 SYNOPSIS

  use Net::Delicious::Simple;
  my $del = Net::Delicious->new(user => 'plki', pswd => 'secret');

  print "$_->{href}\n" for $del->all_posts;

=head1 DESCRIPTION

If you want to do anything interesting with del.icio.us automation, you
probably want L<Net::Delicious>.  It's good.  This module is not.  It's just
here to return all of your tags or posts as a basic Perl data structure.  This
makes it very easy to store that structure using existing dumpers.  In fact, it
only exists to power C<delbackup>, which dumps to YAML or Netscape::Bookmarks.

=head1 METHODS

=head2 new

The constructor gets passed the same things as you'd pass to Net::Delicious.
Basically, you need to pass C<user> and C<pswd> arguments, giving your login
credentials.

=cut

sub new {
	my ($class, $config) = @_;

	return unless my $del = Net::Delicious->new({
    %$config,
    updates => File::Temp::tempdir(CLEANUP => 1),
  });

	bless { del => $del } => $class;
}

=head2 tags

This returns all of your tags, in a list.

=cut

sub tags { my @tags = map { $_->tag } (shift)->{del}->tags }

=head2 all_posts

This returns all of your posts, in a list.  Every post is hash with the
following keys: description, extended, href, tags, and datetime.

Tags is an arrayref, and datetime is in seconds-sicne-epoch, GMT.

=cut

sub all_posts {
  my ($self) = @_;

  my @all_posts = $self->{del}->all_posts;

	my @posts = map {{
		description => $_->description,
		extended    => $_->extended,
		href        => $_->href,
		tags        => [ split /\s+/, $_->tags ],
		datetime    => str2time($_->time)
	}} @all_posts;
}

=head1 SEE ALSO

L<Net::Delicious>

=head1 AUTHOR

Ricardo SIGNES <C<rjbs@cpan.org>>

=head2 COPYRIGHT

(C) 2004, Ricardo SIGNES.  This library is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
