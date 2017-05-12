package WWW::DuckDuckGo::Link;
BEGIN {
  $WWW::DuckDuckGo::Link::AUTHORITY = 'cpan:DDG';
}
{
  $WWW::DuckDuckGo::Link::VERSION = '0.016';
}
# ABSTRACT: A DuckDuckGo Link definition

use Moo;
use WWW::DuckDuckGo::Icon;
use URI;

sub by {
	my ( $class, $link_result ) = @_;
	my %params;
	$params{result} = $link_result->{Result} if $link_result->{Result};
	$params{first_url} = URI->new($link_result->{FirstURL}) if $link_result->{FirstURL};
	$params{icon} = $class->_icon_class->by($link_result->{Icon}) if ref $link_result->{Icon} eq 'HASH' and %{$link_result->{Icon}};
	$params{text} = $link_result->{Text} if $link_result->{Text};
	__PACKAGE__->new(%params);
}

sub _icon_class { 'WWW::DuckDuckGo::Icon' }

has result => (
	is => 'ro',
	predicate => 'has_result',
);

has first_url => (
	is => 'ro',
	predicate => 'has_first_url',
);

has icon => (
	is => 'ro',
	predicate => 'has_icon',
);

has text => (
	is => 'ro',
	predicate => 'has_text',
);

1;

__END__

=pod

=head1 NAME

WWW::DuckDuckGo::Link - A DuckDuckGo Link definition

=head1 VERSION

version 0.016

=head1 SYNOPSIS

  use WWW::DuckDuckGo;

  my $zci = WWW::DuckDuckGo->new->zci('duck duck go');
  
  for (@{$zci->related_topics}) {
    print "Related Topic URL: ".$_->first_url."\n" if $_->has_first_url;
  }

=head1 DESCRIPTION

This package reflects the result of a zeroclickinfo API request.

=head1 METHODS

=head2 has_result

=head2 result

=head2 has_first_url

=head2 first_url

Gives back a URI::http

=head2 has_icon

=head2 icon

Gives back an L<WWW::DuckDuckGo::Icon> object.

=head2 has_text

=head2 text

=encoding utf8

=head1 METHODS

=head1 SUPPORT

IRC

  Join #duckduckgo on irc.freenode.net. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-www-duckduckgo
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-www-duckduckgo/issues

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=item *

Michael Smith <crazedpsyc@duckduckgo.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by L<DuckDuckGo, Inc.|https://duckduckgo.com/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
