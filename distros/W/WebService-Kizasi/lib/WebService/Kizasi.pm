package WebService::Kizasi;

use version; our $VERSION = qv('0.02');

use warnings;
use strict;
use Carp;
use LWP::UserAgent;
use URI::Escape;
use WebService::Kizasi::Parser;

my $C10E_WORD_URL =
  "http://kizasi.jp/kizapi.py?span=SPAN&kw_expr=WORD&type=coll";
my $KWIC_URL    = "http://kizasi.jp/kizapi.py?kw_expr=WORD&type=kwic";
my $RANKING_URL = "http://kizasi.jp/kizapi.py?span=SPAN&type=rank";

sub new {
    my $class = shift;
    my $ua    = new LWP::UserAgent;
    $ua->env_proxy;
    $ua->agent( join '/', __PACKAGE__, $VERSION );
    bless { ua => $ua }, $class;
}

sub _get_and_parse {
    my ( $self, $uri, $keyword, $period ) = @_;
    my ($res);

    $keyword = uri_escape($keyword) if ($keyword);
    $uri =~ s/SPAN/$period/  if ($period);
    $uri =~ s/WORD/$keyword/ if ($keyword);

    $res = $self->{ua}->get($uri);
    WebService::Kizasi::Parser->parse($res);
}

sub _c10e_word {
    my ( $self, $keyword, $period ) = @_;
    _get_and_parse( $self, $C10E_WORD_URL, $keyword, $period );
}

sub c10e_word_1d {
    my ( $self, $keyword ) = @_;
    $self->_c10e_word( $keyword, '24' );
}

sub c10e_word_1w {
    my ( $self, $keyword ) = @_;
    $self->_c10e_word( $keyword, '1w' );
}

sub c10e_word_1m {
    my ( $self, $keyword ) = @_;
    $self->_c10e_word( $keyword, '1m' );
}

sub keyword_in_context {
    my ( $self, $keyword ) = @_;
    _get_and_parse( $self, $KWIC_URL, $keyword, '' );
}

sub _ranking {
    my ( $self, $period ) = @_;
    _get_and_parse( $self, $RANKING_URL, '', $period );
}

sub ranking_1d {
    my $self = shift;
    $self->_ranking('24');
}

sub ranking_1w {
    my $self = shift;
    $self->_ranking('1w');
}

sub ranking_1m {
    my $self = shift;
    $self->_ranking('1m');
}

1;

=head1 NAME

WebService::Kizasi - A Perl Interface for the Kizasi Web Services


=head1 VERSION

This document describes WebService::Kizasi version 0.0.1


=head1 SYNOPSIS

    use WebService::Kizasi;

    use Encode qw(_utf8_off);

    my $kizapi = WebService::Kizasi->new();
    my @result;

    $result[0] = $kizapi->c10e_word_1d('CPAN');
    $result[1] = $kizapi->c10e_word_1w('CPAN');
    $result[2] = $kizapi->c10e_word_1m('CPAN');
    $result[3] = $kizapi->keyword_in_context('CPAN');
    $result[4] = $kizapi->ranking_1d;
    $result[5] = $kizapi->ranking_1w;
    $result[6] = $kizapi->ranking_1m;

    for my $result (@result) {
        my $utf8off = $result->items->[0]->title;
        _utf8_off ($utf8off);
        print $utf8off,"\n";
        print $result->items->[0]->pubDate,"\n";
        print $result->items->[0]->link,"\n";
        print $result->items->[0]->guid,"\n";
        $utf8off = $result->items->[0]->description;
        _utf8_off($utf8off);
        print $utf8off,"\n";
    }

=head1 DESCRIPTION

Kizasi.jp is the sight which discovers the "sign of change"
(Kizasi) from blogs, and the WebService::Kizasi is a Perl
interface to the Kizasi WebService API (Kizapi). For details,
see http://blog.kizasi.jp/kizasi/66.

=head1 INTERFACE

=head2 new

Returns an instace of this module.

=head2 c10e_word_1d($keyword)

Returns WebService::Kizasi::Items, designates the
cooccurrence (C10E) words from the keyword in 1 day.
Keyword must be encoded as UTF-8, and the number of
C10E words are less than 60.

=head2 c10e_word_1w($keyword)

Returns WebService::Kizasi::Items, designates the
cooccurrence (C10E) words from the keyword in 1 week.
Keyword must be encoded as UTF-8, and the number of
C10E words are less than 60.

=head2 c10e_word_1m($keyword)

Returns WebService::Kizasi::Items, designates the
cooccurrence (C10E) words from the keyword in 1 month.
Keyword must be encoded as UTF-8, and the number of
C10E words are less than 60.

=head2 keyword_in_context($keyword)

Returns WebService::Kizasi::Items, designates the
sentenses which include the keyword. Keyword must be
encoded as UTF-8, and the number of sentenses are
less than 30.

=head2 ranking_1d

Returns WebService::Kizasi::Items, designates the
ranking of the topics in 1 day.

=head2 ranking_1w

Returns WebService::Kizasi::Items, designates the
ranking of the topics in 1 week.

=head2 ranking_1m

Returns WebService::Kizasi::Items, designates the
ranking of the topics in 1 month.

=head1 DIAGNOSTICS

See WebService::Kizasi::Items->status and their status_message.

=head1 CONFIGURATION AND ENVIRONMENT

WebService::Kizasi requires no configuration files, but load
proxy settings from *_proxy environment variables. See LWP::UserAgent
for more details.

=head1 DEPENDENCIES

Class::Accessor::Fast,
XML::RSS::LibXML,
version,
LWP::UserAgent,
URI::Escape,
Test::Base.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-WebService-Kizasi@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

L<WebService::Kizasi::Item>

=head1 AUTHOR

DAIBA, Keiichi  C<< keiichi@tokyo.pm.org >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, DAIBA, Keiichi C<< keiichi@tokyo.pm.org >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See C<perldoc perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE ''AS IS'' WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
