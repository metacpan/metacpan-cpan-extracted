package WWW::Offliberty;

use 5.008009;
use strict;
use warnings;
use parent qw/Exporter/;
our $VERSION = '1.000008';
our @EXPORT_OK = qw/off/;

our $OFF_URL = 'http://offliberty.com/off04.php';

use HTML::TreeBuilder;
use HTTP::Tiny;

our $http = HTTP::Tiny->new(agent => "WWW-Offliberty/$VERSION ", default_headers => {Referer => 'http://offliberty.com/'});

sub off{
	my ($url, @params) = @_;
	my $ret = $http->post_form($OFF_URL, {track => $url, @params});
	die $ret->{reason} unless $ret->{success}; ## no critic (RequireCarping)
	my $root = HTML::TreeBuilder->new_from_content($ret->{content});
	map { $_->attr('href') } $root->look_down(qw/_tag a class download/);
}

1;
__END__

=head1 NAME

WWW::Offliberty - interface to offliberty.com download service

=head1 SYNOPSIS

  use WWW::Offliberty qw/off/;
  my @links = off 'http://youtube.com/watch?v=something', video_file => 1;

=head1 DESCRIPTION

WWW::Offliberty is a simple interface to the offliberty.com download service.

The module exports (on request) a single function, B<off>(I<url>,
[I<parameter> => value, ...]). It takes a URL and an optional list of
parameters (key/value pairs). It returns a list of download links. An
empty list is returned if the Offliberty service returns no URLs (for
example if Offliberty encounters an error or the URL is invalid). Dies
if unable to contact Offliberty (for example if there is no internet
connection or a firewall blocks the connection).

The supported services and parameters are undocumented. From empirical
testing, when requesting a YouTube URL the service will return an
audio-only URL when called with no parameters, and two URLs
(audio-only and audio/video) when called with the parameter
B<video_file> set to B<1>. In contrast, Vimeo URLs with no parameters
return both audio-only and audio/video variants.

Note: The URL of the service sometimes changes, which breaks this
module. If you notice this, please report a bug on RT. While the bug
is being fixed, you can override the URL locally by doing:

  $WWW::Offliberty:OFF_URL = 'http://offliberty.com/correct_url.php';

before calling off.

=head1 SEE ALSO

L<http://offliberty.com>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2018 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
