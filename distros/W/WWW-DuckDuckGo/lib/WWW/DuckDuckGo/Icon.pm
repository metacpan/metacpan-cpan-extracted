package WWW::DuckDuckGo::Icon;
BEGIN {
  $WWW::DuckDuckGo::Icon::AUTHORITY = 'cpan:DDG';
}
{
  $WWW::DuckDuckGo::Icon::VERSION = '0.016';
}
# ABSTRACT: A DuckDuckGo Icon definition

use Moo;
use URI;

sub by {
	my ( $class, $icon_result ) = @_;
	my %params;
	$params{url} = URI->new($icon_result->{URL}) if $icon_result->{URL};
	$params{height} = $icon_result->{Height} if $icon_result->{Height};
	$params{width} = $icon_result->{Width} if $icon_result->{Width};
	__PACKAGE__->new(%params);
}

has url => (
	is => 'ro',
	predicate => 'has_url',
);

has width => (
	is => 'ro',
	predicate => 'has_width',
);

has height => (
	is => 'ro',
	predicate => 'has_height',
);

1;

__END__

=pod

=head1 NAME

WWW::DuckDuckGo::Icon - A DuckDuckGo Icon definition

=head1 VERSION

version 0.016

=head1 SYNOPSIS

  use WWW::DuckDuckGo;

  my $zci = WWW::DuckDuckGo->new->zci('duck duck go');
  
  for (@{$zci->results}) {
    print "Result URL: ".$_->first_url->as_string."\n" if $_->has_first_url;
    print "Result Icon: ".$_->icon->url->as_string."\n" if $_->has_icon and $_->icon->has_url;
  }

=head1 DESCRIPTION

This package reflects the result of a zeroclickinfo API request.

=head1 METHODS

=head2 has_url

=head2 url

Gives back a URI::http

=head2 has_width

=head2 width

=head2 has_height

=head2 height

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
