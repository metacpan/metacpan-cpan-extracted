
=encoding utf8

=head1 NAME

WWW::Shorten::SapoPuny - Perl interface to xsl.pt

=head1 SYNOPSIS

  use WWW::Shorten::SapoPuny;
  use WWW::Shorten 'SapoPuny';

  $short_url = makeashorterlink($long_url);

  $long_url  = makealongerlink($short_url);

=head1 DESCRIPTION

A Perl interface to the web site xsl.pt.  SapoPuny simply maintains
a database of long URLs, each of which has a unique identifier.

=cut

package WWW::Shorten::SapoPuny;
$WWW::Shorten::SapoPuny::VERSION = '0.04';
use 5.006;
use strict;
use warnings;

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT         = qw( makeashorterlink makealongerlink );
our $_error_message = '';

use Carp;

=head1 Functions

=head2 makeashorterlink

The function C<makeashorterlink> will call the SapoPuny web site passing
it your long URL and will return the shorter SapoPuny version.

=cut

#javascript:void(location.href='http://xsl.pt/punify?url='+encodeURIComponent(location.href))

sub makeashorterlink {
    my $url = shift or croak 'No URL passed to makeashorterlink';
    $_error_message = '';
    my $ua      = __PACKAGE__->ua();
    my $tinyurl = 'http://xsl.pt/punify?url=';
    print STDERR $tinyurl . $url;
    my $resp = $ua->get( $tinyurl . $url );

    unless ( $resp->is_success ) {
        $_error_message = $resp->status_line;
        return undef;
    }

    my $content = $resp->content;
    if ( $content !~ /id="ascii"/ ) {
        if ( $content =~ /<html/ ) {
            $_error_message = 'Error is a html page';
        }
        elsif ( length($content) > 100 ) {
            $_error_message = substr( $content, 0, 100 );
        }
        else {
            $_error_message = $content;
        }
        return undef;
    }
    if ( $resp->content =~ m!(http://[a-z0-9]+\.[a-z0-9]+\.xsl\.pt)!x ) {
        return $1;
    }
    return;
}

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an B<ONLY> the full SapoPuny URL.

If anything goes wrong, then either function will return C<undef>.

=cut

sub makealongerlink {
    my $tinyurl_url = shift
      or croak 'No SapoPuny key / URL passed to makealongerlink';
    $_error_message = '';
    my $ua = __PACKAGE__->ua();

    return undef unless $tinyurl_url =~ m!http://[a-z0-9]+\.[a-z0-9]+\.xsl\.pt!;

    my $resp = $ua->get($tinyurl_url);

    unless ( $resp->is_redirect ) {
        my $content = $resp->content;
        if ( $content =~ /Error/ ) {
            if ( $content =~ /<html/ ) {
                $_error_message = 'Error is a html page';
            }
            elsif ( length($content) > 100 ) {
                $_error_message = substr( $content, 0, 100 );
            }
            else {
                $_error_message = $content;
            }
        }
        else {
            $_error_message = 'Unknown error';
        }

        return undef;
    }
    my $url = $resp->header('Location');
    return $url;

}

1;

__END__

=head2 EXPORT

makeashorterlink, makealongerlink

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Alberto Simões, all rights reserved.

This module is free software and is published under the same terms as Perl itself.

=head1 AUTHOR

Alberto Simões C<< <ambs@cpan.org> >>

=head1 SEE ALSO

L<WWW::Shorten>, L<perl>, L<http://xsl.pt/>

=cut
