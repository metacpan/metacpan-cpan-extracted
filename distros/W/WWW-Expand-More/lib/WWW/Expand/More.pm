package WWW::Expand::More;
use strict;
use warnings;

use Furl;

our $VERSION = '0.02';

sub _default_ua {
    my $args = shift;

    Furl->new(
        timeout => $args->{timeout} || 5,
        agent   => $args->{agent}   || __PACKAGE__."/$VERSION",
    );
}

our %CACHE = ();

sub expand {
    my ($class, $url, $opt) = @_;

    return $CACHE{$url} if exists $CACHE{$url};

    my @urls;

    $class->_expand($url, \@urls);

    if ($opt->{cache}) {
        $CACHE{$url} = $urls[-1];
    }

    return $urls[-1];
}

sub expand_all {
    my ($class, $url, $opt) = @_;

    return $CACHE{$url} if exists $CACHE{$url};

    my @urls;

    $class->_expand($url, \@urls);

    if ($opt->{cache}) {
        $CACHE{$url} = [@urls];
    }

    return @urls;
}

sub _expand {
    my ($class, $url, $urls, $opt) = @_;

    $opt->{ua} ||= _default_ua();

    push @{$urls}, $url;

    my $res = $opt->{ua}->request(
        method        => 'HEAD',
        url           => $url,
        max_redirects => 0,
        headers       => [ Connection => 'close' ],
    );

    if (my $next_url = $res->headers->header('location')) {
        return $class->_expand($next_url, $urls, $opt);
    }
}

1;

__END__

=head1 NAME

WWW::Expand::More - The expander for a shortened URL


=head1 SYNOPSIS

    use WWW::Expand::More;

    my $expanded_url  = WWW::Expand::More->expand('http://example.com/foo');

    my @expanded_urls = WWW::Expand::More->expand_all('http://example.com/foo');

    # options
    print WWW::Expand::More->expand('http://example.com/foo' => {
        timeout => 1,
        agent   => 'YourUA/1.0',
    });


=head1 DESCRIPTION

WWW::Expand::More is the expander for a shortened URL.


=head1 METHODS

=head2 expand($url:Str, $opt:HashRef)

=head2 expand_all($url:Str, $opt:HashRef)

=head3 $opt: HashRef

=head4 ua

The User Agent Object that needs to have compatiblity with an interface of L<Furl>.

=head4 timeout => $sec

=head4 agent => $agent_name

=head4 cache => boolean

If you set true value on C<cache> option, then the expanded URL will cache.


=head1 CLI COMMAND

=head2 expand_url

The cli command L<expand_url> has been included in this module's distribution.

    $ expand_url http://bit.ly/1BPj30x
    https://www.google.com/search?q=Perl

You can use it in your terminal easily. See more detail L<expand_url>.

=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/WWW-Expand-More"><img src="https://secure.travis-ci.org/bayashi/WWW-Expand-More.png"/></a> <a href="https://coveralls.io/r/bayashi/WWW-Expand-More"><img src="https://coveralls.io/repos/bayashi/WWW-Expand-More/badge.png?branch=master"/></a>

=end html

WWW::Expand::More is hosted on github: L<http://github.com/bayashi/WWW-Expand-More>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Furl>

L<WWW::Expand>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
