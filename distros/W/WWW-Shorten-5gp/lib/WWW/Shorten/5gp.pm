package WWW::Shorten::5gp;

use strict;
use warnings;

use Carp qw();
use JSON::MaybeXS qw(decode_json);
use URI ();

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );
our $VERSION = '1.030';
$VERSION = eval $VERSION;

my $service = 'http://5.gp/api/';

sub makeashorterlink {
    my $url = shift or Carp::croak('No URL passed to makeashorterlink');
    my $ua = __PACKAGE__->ua();
    my $uri = URI->new('http://5.gp/api/short');
    $uri->query_form(longurl => $url);
    my $res = $ua->get($uri);

    return undef unless $res && $res->is_success;
    my $content = decode_json($res->decoded_content);
    return undef unless $content && $content->{url};
    return $content->{url};
}

sub makealongerlink {
    my $url = shift or Carp::croak('No 5.gp key / URL passed to makealongerlink');
    my $ua = __PACKAGE__->ua();

    $url = "http://5.gp/$url" unless $url =~ m!^http://!i;
    my $uri = URI->new('http://5.gp/api/long');
    $uri->query_form(shorturl => $url);

    my $res = $ua->get($uri);
    return undef unless $res && $res->is_success;
    my $content = decode_json($res->decoded_content);
    return undef unless $content && $content->{$url}->{target_url};
    return $content->{$url}->{target_url};
}

1;

__END__

=head1 NAME

WWW::Shorten::5gp - Shorten URLs using L<http://5.gp>

=head1 SYNOPSIS

    use strict;
    use warnings;

    use WWW::Shorten::5gp;
    # use WWW::Shorten '5gp';  # or, this way

    my $short_url = makeashorterlink('http://www.foo.com/some/long/url');
    my $long_url  = makealongerlink($short_url);

=head1 DESCRIPTION

A Perl interface to the web site L<http://5.gp>. The service simply maintains
a database of long URLs, each of which has a unique identifier.

=head1 FUNCTIONS

=head2 makeashorterlink

The function C<makeashorterlink> will call the L<http://5gp> web site passing
it your long URL and will return the shorter version.

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full URL or just the identifier.

If anything goes wrong, then either function will return C<undef>.

=head1 AUTHOR

Michiel Beijen <F<michielb@cpan.org>>

=head1 CONTRIBUTORS

=over

=item *

Chase Whitener <F<capoeirab@cpan.org>>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2015 by Michiel Beijen <F<michielb@cpan.org>>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
