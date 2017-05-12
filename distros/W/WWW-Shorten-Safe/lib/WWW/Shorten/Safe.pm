# $Id: Safe.pm 106 2009-05-27 21:06:26Z jsobrier $
# $Author: jsobrier $
# $Date: 2009-05-27 02:36:26 +0530 (Wed, 27 My 2009) $
# Author: <a href=mailto:jsobrier@safe.mn>Julien Sobrier</a>
################################################################################################################################
package WWW::Shorten::Safe;

use warnings;
use strict;
use Carp;

use base qw( WWW::Shorten::generic Exporter );

use XML::Simple;

require Exporter;

our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(new version);

my @ISA = qw(Exporter);

use vars qw( @ISA @EXPORT );


=head1 NAME

WWW::Shorten::Safe - Interface to shortening URLs using http://safe.mn/, http://clic.gs/, http://go2.gs/ or http://cliks.fr/.

=head1 VERSION

1.22

=cut

our $VERSION = '1.22';

# ------------------------------------------------------------


=head1 SYNOPSIS

WWW::Shorten::Safe provides an easy interface for shortening URLs using L<http://safe.mn/>, L<http://clic.gs/>, L<http://go2.gs/> or L<http://cliks.fr/>.


    use WWW::Shorten::Safe;

    my $url = "http://www.example.com/";

    my $short = makeashorterlink($url);
    my $long = makealongerlink($short); # "http://www.example.com/"

or

    use WWW::Shorten::Safe;

    my $url = "http://www.example.com";
    my $safe = WWW::Shorten::Safe->new();

    $safe->shorten(URL => $url);
    print "shortened URL is $safe->{safeurl}\n";

    $safe->expand(URL => $safe->{safeurl});
    print "expanded/original URL is $safe->{longurl}\n";

    my $info = $safe->info(URL => $safe->{safeurl});
    print "number of clicks: ", $info->{clicks}, "\n";


=head1 FUNCTIONS

=head2 new

Create a new safe.mn object.

    my $safe = WWW::Shorten::Safe->new();


=head3 Arguments

=head4 source

Optional. User-Agent value.

    my $safe = WWW::Shorten::Safe->new(source => 'MyLibrary');

default: perlteknatussafe


=head4 domain

Optional. Domain of the short URL. Choose between safe.mn, clic.gs, go2.gs or cliks.fr.

    my $safe = WWW::Shorten::Safe->new(domain => 'clic.gs');


default: safe.mn

=cut
sub new {
    my ($class, %args) = @_;
    $args{source} ||= "perlteknatussafe";
    $args{domain} ||= 'safe.mn';

# 	print $args{domain}, "\n";

    my $safe = {
        browser => LWP::UserAgent->new(agent => $args{source}),
        domain  => $args{domain},
    };

    bless $safe, $class;
#     return $class;
}


=head2 makeashorterlink(url[, domain])

The function C<makeashorterlink> will call the safe.mn API site passing it
your long URL and will return the shorter safe.mn version.

=head3 Arguments

=head4 url

B<Required>. Long URL to shorten

    my $short = makeashorterlink("http://www.example.com/"); # http://safe.mn/25

=head4 domain

Optional. Domain of the short URL. Choose between safe.mn, clic.gs, go2.gs or cliks.fr.

    my $short = makeashorterlink("http://www.example.com/", "clic.gs"); # http://clic.gs/25

safe.mn by default

=cut
sub makeashorterlink #($;%)
{
    my $url = shift or croak('No URL passed to makeashorterlink');
    my $domain = shift || 'safe.mn';

    my $ua = __PACKAGE__->ua();


    my $safe;
    my $safeurl = "http://$domain/api/?format=text&url=$url";
    $safe->{response} = $ua->get($safeurl);
    $safe->{safeurl} = $safe->{response}->{_content};
    $safe->{safeurl} =~ s/\s//mg;
    return unless $safe->{response}->is_success;
    return $safe->{safeurl};
}

=head2 makealongerlink(url)

The function C<makealongerlink> does the reverse. C<makealongerlink>
will accept as an argument the full safe.mn/clic.gs/go2.gs/cliks.fr URL.

If anything goes wrong, then the function will return C<undef>.

=head3 Arguments

=head4 url

B<Required>. Short URL to shorten

    my $long = makealongerlink("http://clic.gs/25"); # "http://www.example.com/"

=cut
sub makealongerlink #($,%)
{
    my $url = shift or croak('No shortened safe.mn URL passed to makealongerlink');

    my $ua = __PACKAGE__->ua();

    my $safe;

    my $safeurl = URI->new("http://safe.mn/api/?format=text&short_url=$url");

    $safe->{response} = $ua->get($safeurl);
    $safe->{longurl} = $safe->{response}->{_content};
    $safe->{longurl} =~ s/\s//mg;

    return undef unless $safe->{response}->is_success;
    return $safe->{longurl};
}

=head2 shorten

Shorten a URL using http://safe.mn/, http://clic.gs/, http://go2.gs/ or http://cliks.fr/.
Calling the shorten method will return the shortened URL but will also store it in safe.mn object until the next call is made.

    my $url = "http://www.example.com/";
    my $shortstuff = $safe->shorten(URL => $url);

    print "safeurl is " . $safe->{safeurl} . "\n";
or
    print "safeurl is $shortstuff\n";


=head3 Arguments

=head4 URL

B<Required>. Long URL to shorten

    my $short = $safe->shorten(URL => "http://www.example.com/"); # http://safe.mn/25

=head4  DOMAIN

Optional. Domain of the short URL. Choose between safe.mn, clic.gs, go2.gs or cliks.fr.

    my $short = $safe->shorten(URL => "http://www.example.com/", DOMAIN => "clic.gs"); # http://clic.gs/25

safe.mn by default

=cut
sub shorten {
    my ($self, %args)   = @_;
    my $url             = $args{URL}    || croak("URL is required.\n");
    my $domain          = $args{DOMAIN} || $self->{domain}	|| 'safe.mn';

    my $api  = "http://$domain/api/?format=text&url=$url";
# 	print $api, "\n";

    $self->{response} = $self->{browser}->get($api);
    return undef unless $self->{response}->is_success;;

    $self->{safeurl} = $self->{response}->{_content};
    $self->{safeurl} =~ s/\s//mg;

    return $self->{safeurl};
}


=head2 expand

Expands a shortened safe.mn URL to the original long URL.

=head3 Arguments

=head4 URL

B<Required>. Long URL to shorten

    my $long = $safe->expand(URL => "http://safe.mn/25"); # http://www.example.com/

=cut
sub expand {
    my ($self, %args)   = @_;
    my $url             = $args{URL}    || croak("URL is required.\n");


    my $api   = "http://safe.mn/api/?format=text&short_url=$url";
    $self->{response} = $self->{browser}->get($api);

    return undef unless $self->{response}->is_success;
    $self->{longurl} = $self->{response}->content;
    $self->{longurl} =~ s/\s//mg;

    return $self->{longurl};
}

=head2 info

Get information bout a short link.

=head3 Arguments

=head4 URL

B<Required>. Short URL to track

    my $info = $safe->info(URL => "http://safe.mn/25");
    print "number of clicks: ", $info->{clicks}, "\n";

See http://safe.mn/api-doc/protocol#track-response for the list of fields returned: clicks, referers, countries, filetype, etc.

=cut
sub info {
    my ($self, %args)   = @_;
    my $url             = $args{URL}    || croak "URL is required.\n";


    my $api   = "http://safe.mn/api/info?format=xml&url=$url";
    $self->{response} = $self->{browser}->get($api);

    return { } unless $self->{response}->is_success;

    my $xml = XMLin($self->{response}->content, ForceArray => [qw/referers countries/]);
    return $xml;
}



=head2 version

Gets the module version number

=cut
sub version {
    my ($self, $version)     = @_;

    warn "Version $version is later then $WWW::Shorten::Safe::VERSION. It may not be supported" if (defined ($version) && ($version > $WWW::Shorten::Safe::VERSION));
    return $WWW::Shorten::Safe::VERSION;
}#version

sub ua {
    my ($self)  = @_;

    return LWP::UserAgent->new();
}


=head1 AUTHOR

Julien Sobrier, C<< <jsobrier at safe.mn> >>

=head1 BUGS

Please report any bugs or feature requests to C<jsobrier at safe.mn>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Shorten::Safe


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Shorten-Safe>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Shorten-Safe>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Shorten-Safe>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Shorten-Safe/>

=back


=head1 ACKNOWLEDGMENTS

=over

=item Dave Cross for WWW::Shorten.
.

=back

=head1 COPYRIGHT & LICENSE

=over

=item Copyright (c) 2009 Julien Sobrier, All Rights Reserved L<http://safe.mn/>.


=back

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 SEE ALSO

L<perl>, L<WWW::Shorten>, L<http://safe.mn/tools/#api>.

=cut

1; # End of WWW::Shorten::Safe
