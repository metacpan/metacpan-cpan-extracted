package WWW::Dict::Zdic;

use warnings;
use strict;
use v5.8.0;
our $VERSION = '0.0.4';

use base 'WWW::Dict';

use WWW::Mechanize;
use Encode;
use URI::Escape;
use HTML::TagParser;
use HTML::Entities;
use Class::Field qw'field const';

# Module implementation here

field ua => -init => 'WWW::Mechanize->new()';
const dict_url => 'http://www.zdic.net';
field word => '';

sub define {
    my $self = shift;
    my $word = shift;
    $self->word($word);
    $word = URI::Escape::uri_escape_utf8($word);
    $word =~ s/%/Zdic/g;
    my $url = $self->dict_url . "/zd/zi/${word}.htm";
    $self->ua->get($url);
    $self->parse_content( $self->ua->content() );
}

sub parse_content {
    my $self = shift;
    my $html = HTML::TagParser->new;
    $html->parse(shift);
    my @def;
    for my $elem ( $html->getElementsByTagName("div") ) {
        my $attr = $elem->attributes;
        next unless ( 'tab-page' eq ( $attr->{class} || '' ) );
        my $innerText = $elem->innerText;
        if (! Encode::is_utf8($innerText)) {
            $innerText = Encode::decode('utf8', $innerText);
            $innerText = decode_entities( $innerText );
        }
        my @d = grep { !/tabPane|^\s*$/ }
          map {
            s/--.*?Zdic.net.*?--//g;
            s/\t//g;
            $_;
          }
          split( /\r?\n/, $innerText );
        push @def,
          {
            category   => $d[0],
            definition => join( "\n", @d[ 1 .. $#d ] )
          };
    }
    return \@def;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

WWW::Dict::Zdic - Zdic Chinese Dictionary interface


=head1 VERSION

This document describes WWW::Dict::Zdic version 0.0.4

=head1 SYNOPSIS

    use WWW::Dict::Zdic;
    my $dic = WWW::Dict::Zdic->new();
    my $def = $dic->define("劉");
    print YAML::Dump($def);

=head1 DESCRIPTION

This module provides simple interface to zdic.net Chinese character
dictionary website.

=head1 INTERFACE

=over 4

=item new()

Object contrsuctor. Nothing special, no argument is needed here.

=item define( $character )

Return an arrayref of hashref. Each hashref presents a definition of
the given Chinese $character. Currently valid keys for that hashref
are 'category' and 'definition'. 'category' refers to different
sources of defintions on zdic.net web-site. Usually there are more
then two of them.

=item parse_content( $string )

Internally used function, to parse HTML from word definition page.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-www-dict-zdic@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Kang-min Liu  C<< <gugod@gugod.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Kang-min Liu C<< <gugod@gugod.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
