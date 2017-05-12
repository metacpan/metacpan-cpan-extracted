package WWW::Shorten::0rz;

use strict;
use warnings;
use Carp        ();
use Mojo::DOM58 ();
use Try::Tiny qw(try catch);
use WWW::Mechanize ();

use base qw( WWW::Shorten::generic Exporter );
our @EXPORT = qw( makeashorterlink makealongerlink );

our $_error_message = '';
our $VERSION        = '0.074';
$VERSION = eval $VERSION;

sub makeashorterlink {
    my $url = shift or Carp::croak("No URL passed to makeashorterlink");
    $_error_message = '';
    return try {
        my $mech = WWW::Mechanize->new;
        $mech->add_header('Accept' => 'text/html');
        $mech->get('http://0rz.tw/create');
        $mech->submit_form(
            form_id => 'redirect-form',
            fields  => {url => $url,},
        );
        return undef unless $mech->response->is_success;
        my $dom = Mojo::DOM58->new($mech->response->decoded_content);
        return $dom->find('div#doneurl > a')->last->attr('href');
    }
    catch {
        $_error_message = $_;
        return undef;
    };
}

sub makealongerlink {
    my $url = shift or Carp::croak('No URL passed to makealongerlink');
    $_error_message = '';
    my $ua = __PACKAGE__->ua();
    $url = "http://0rz.tw/$url" unless $url =~ m!^http://!i;
    my $resp = $ua->get($url);
    unless ($resp->is_redirect) {
        my $content = $resp->content;
        if ($content =~ /Error/) {
            if ($content =~ /<html/) {
                $_error_message = 'Error is a html page';
            }
            elsif (length($content) > 100) {
                $_error_message = substr($content, 0, 100);
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
    my $long = $resp->header('Location');
    return $long;
}

1;

__END__

=head1 NAME

WWW::Shorten::0rz - Shorten URLs using L<http://0rz.tw/>

=head1 SYNOPSIS

  use strict;
  use warnings;

  use WWW::Shorten::0rz;
  # use WWW::Shorten '0rz';  # or, this way

  my $short_url = makeashorterlink('http://www.foo.com/some/long/url');
  my $long_url  = makealongerlink($short_url);

=head1 DESCRIPTION

A Perl interface to the web site L<http://0rz.tw>.  The service simply maintains
a database of long URLs, each of which has a unique identifier.

=head1 FUNCTIONS

=head2 makeashorterlink

The function C<makeashorterlink> will call the L<http://0rz.tw> web site passing
it your long URL and will return the shorter version.

=head2 makealongerlink

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument either the full URL or just the identifier.

If anything goes wrong, then either function will return C<undef>.

=head1 AUTHOR

Kang-min Liu <F<gugod@gugod.org>>

=head1 CONTRIBUTORS

=over

=item *

Chase Whitener <F<capoeirab@cpan.org>>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2004-2009 by Kang-min Liu <F<gugod@gugod.org>>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
