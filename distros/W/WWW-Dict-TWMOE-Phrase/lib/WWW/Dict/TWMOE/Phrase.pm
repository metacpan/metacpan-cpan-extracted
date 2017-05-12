package WWW::Dict::TWMOE::Phrase;

use warnings;
use strict;
use v5.8.0;

use base 'WWW::Dict';

use HTML::TagParser;
use HTML::TableExtract;

use WWW::Mechanize;
use Encode;
use Class::Field qw'field const';

=head1 NAME

WWW::Dict::TWMOE::Phrase - TWMOE Chinese Phrase Dictionary interface.

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

const dict_url => 'http://140.111.34.46/dict/';

field ua => -init => 'WWW::Mechanize->new()';
field word => '';

=head1 SYNOPSIS

    use WWW::Dict::TWMOE::Phrase;
    use encoding 'utf8';
    my $dict = WWW::Dict::TWMOE::Phrase->new();
    my $definition = $dict->define("凡");

=head1 METHODS

=head2 define ($word)

define() method look up the definition of $word from twmoe dict
server. The return value is an array of definitions, each definition
is a hash with 6 possible keys: "phrase", "zuin_form_1",
"zuin_form_2", "synonym", "antonym", "definition". The values to these
keys are directly copied from web server, except for "phrase", which
represent the actually phrase of this definition.

=cut

sub define {
    my $self = shift;
    my $word = shift;
    my $def = [];
    my $ua = $self->ua;

    $self->word($word);
    $word = '^' . Encode::encode("big5",$word) . '$';

    $ua->get($self->dict_url);
    $ua->submit_form( form_number => 1,
                      fields => {
                                 QueryScope => "Name",
                                 QueryCommand => "find",
                                 GraphicWord => "yes",
                                 QueryString => $word
                                }
                    );
    my $content = $ua->content();
    my $doc = HTML::TagParser->new( $ua->content() );
    foreach my $elem ($doc->getElementsByTagName("a")) {
        my $attr = $elem->attributes;
        next unless ( $attr->{href} =~ /^GetContent.cgi/ );
        $ua->get($attr->{href});
        push @$def, $self->parse_content( Encode::decode('big5',$ua->content ));
        $ua->back();
    }
    return $def;
}

=head2 parse_content ($content)

Parse the definition web page, with URI started with "GetContent.cgi".
The returned is a hash representing the word definition table no the
web page. This is intend to be used internally. You don't call this
function.

=cut

sub parse_content {
    use encoding 'utf8';

    my $self = shift;
    my $content = shift;
    my $def = {};
    my $te = HTML::TableExtract->new( keep_html => 0 );
    $te->parse( $content );
    for my $row ( $te->rows ) {
        # The parsed result of HTML::TableExtract lost utf8 flag.
        for(@$row) { Encode::_utf8_on($_||='') }
        if ( $row->[0] =~ />(.*)</ ) {
            $row->[0] = $1;
        }
        $row->[0] = $self->inflect($row->[0]);
        if ( $row->[0] =~ /【(.+)】/ ) {
            $def->{phrase} = $1;
        } else {
            $def->{$row->[0]} = $row->[1];
        }
    }
    return $def;
}

=head2 inflect ($key)

This is where the table field names converted to a proper ASCII name,
for it is easier to coding with. This is intend to be used internally.
You don't call this function.

=cut

sub inflect {
    use encoding 'utf8';

    my $self = shift;
    my $key  = shift;

    return {
            "注音一式" => 'zuin_form_1',
            "注音二式" => 'zuin_form_2',
            "相似詞" => 'synonym',
            "相反詞" => 'antonym',
            "解釋" => 'definition'
           }->{$key} || $key;
}

=head1 AUTHOR

Kang-min Liu, C<< <gugod at gugod.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-dict-twmoe-phrase at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Dict-TWMOE-Phrase>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Dict::TWMOE::Phrase

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Dict-TWMOE-Phrase>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Dict-TWMOE-Phrase>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Dict-TWMOE-Phrase>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Dict-TWMOE-Phrase>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006,2007 Kang-min Liu, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WWW::Dict::TWMOE::Phrase
