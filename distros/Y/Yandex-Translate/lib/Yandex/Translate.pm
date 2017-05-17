package Yandex::Translate;

use strict;
use warnings;
use utf8;

use HTML::Entities qw{encode_entities};
use HTTP::Tiny;
use JSON;
use POSIX qw{:locale_h};
use URI::Escape qw{uri_escape_utf8};

#
# The “my” keyword is on a separate line so that the VERSION_FROM attribute
# of ExtUtils::MakeMaker->WriteMakefile() will accurately detect $VERSION.
#
my
$VERSION = '1.002';

#
# See https://tech.yandex.ru/translate/doc/dg/concepts/api-overview-docpage/
# for the supported language codes.
#
my %valid_lang = map { $_ => 1 } qw{
    az sq am en ar hy af eu ba be bn my bg bs cy hu vi ht gl nl
    mrj el ka gu da he yi id ga it is es kk kn ca ky zh ko xh km
    lo la lv lt lb mg ms
    ml mt mk mi mr mhr mn de ne no pa pap fa pl pt ro ru ceb sr si
    sk sl sw su tg th tl ta tt te tr udm uz uk ur fi fr hi hr cs
    sv gd et eo jv ja
};

my %valid_format = map { $_ => 1 } qw { plain html };

my %valid_options = map { $_ => 1 } qw { 1 };

my %valid_default_ui = map { $_ => 1 } qw{ en ru tr };

#
# Set the default UI to Russian if the locale is Russian;
# Set the default UI to Turkish if the locale is Turkish;
# otherwise, set it to English.
#
(my $default_ui = setlocale(LC_CTYPE) || 'en') =~ s/_.*$//;
$default_ui = 'en' if (!exists $valid_default_ui{$default_ui});

sub new
{
    my $class = shift;
    my $self = {
        _key_        => shift,
        _text_       => shift,
        _from_lang_  => shift,
        _to_lang_    => shift,
        _ui_         => shift || $default_ui,
        _hint_       => shift,
        _format_     => shift,
        _options_    => shift,
        _base_       => 'https://translate.yandex.net/api/v1.5/tr.json',
        _post_       => undef,
	_http_       => HTTP::Tiny->new
    };

    $self->{_text_} = uri_escape_utf8($self->{_text_}) if (defined $self->{_text_});

    return bless $self, $class;
}

sub set_key
{
    my ( $self, $key ) = @_;
    $self->{_key_} = $key if (defined $key);
}

sub set_ui
{
    my ( $self, $ui ) = @_;
    $self->{_ui_} = (defined $ui && exists $valid_lang{$ui}) ? $ui : $default_ui;
}

sub set_default_ui
{
    my ( $self, $this_default_ui ) = @_;
    $default_ui = $this_default_ui if (defined $this_default_ui && exists $valid_default_ui{$this_default_ui});
}

#
# Get a list of supported translation directions.
#
sub get_langs_list
{
    my $self = shift;
    
    my $query = '/getLangs?';
    $self->{_post_} = 'key='.$self->{_key_}.'&ui='.$self->{_ui_};
    my $response = $self->{_http_}->get($self->{_base_} . $query  . $self->{_post_});

    die "Invalid API key\n" if ($response->{status} eq '401');
    die "Blocked API key\n" if ($response->{status} eq '402');
    die "Failed to get list of supported languages! (response code $response->{status})\n" unless ($response->{success});

    if (defined wantarray && length $response->{content}) {
        my $json_respond = JSON->new->utf8->decode($response->{content});
        return (wantarray) ? @{ $json_respond->{dirs} } : scalar(@{ $json_respond->{dirs} });
    }
}

sub set_text
{
    my ( $self, $text ) = @_;
    $self->{_text_} = uri_escape_utf8($text) if (defined $text);
}

sub set_hint
{
    my ( $self, $hint ) = @_;
    my @valid_hint_lang;
    if (defined $hint && ref($hint) eq 'ARRAY') {
        for (@{ $hint }) {
           push @valid_hint_lang, $_ if (exists $valid_lang{$_});
        }
    }
    $self->{_hint_} = (@valid_hint_lang) ? [ @valid_hint_lang ] : undef;
}

sub detect_lang
{
    my $self = shift;

    my $query = '/detect?';
    $self->{_post_} = 'key='.$self->{_key_}.'&text='.$self->{_text_};
    $self->{_post_} .= '&hint='.join(',', @{ $self->{_hint_} }) if (defined $self->{_hint_});
    my $response = $self->{_http_}->get($self->{_base_} . $query  . $self->{_post_});

    die "Invalid API key\n" if ($response->{status} eq '401');
    die "Blocked API key\n" if ($response->{status} eq '402');
    die "Exceeded the daily limit on the amount of translated text\n" if ($response->{status} eq '404');
    die "Failed to detect the language! (response code $response->{status})\n" unless ($response->{success});

    if (defined wantarray && length $response->{content}) {
        my $json_respond = JSON->new->utf8->decode($response->{content});
        return (wantarray) ? ($json_respond->{lang}) : $json_respond->{lang};
    }
}

sub set_from_lang
{
    my ( $self, $from_lang ) = @_;
    $self->{_from_lang_} = $from_lang if (!defined $from_lang || exists $valid_lang{$from_lang});
}

sub set_to_lang
{
    my ( $self, $to_lang ) = @_;
    $self->{_to_lang_} = $to_lang if (defined $to_lang && exists $valid_lang{$to_lang});
}

sub set_format
{
    my ( $self, $format ) = @_;
    $self->{_format_} = $format if (!defined $format || exists $valid_format{$format});
}

sub set_options
{
    my ( $self, $options ) = @_;
    $self->{_options_} = $options if (!defined $options || exists $valid_options{$options});
}

sub translate
{
    my $self = shift;

    my $query = '/translate?';
    my $lang = (defined $self->{_from_lang_}) ? $self->{_from_lang_}.'-'.$self->{_to_lang_} : $self->{_to_lang_};
    $self->{_post_} = 'key='.$self->{_key_}.'&text='.$self->{_text_}.'&lang='.$lang;
    $self->{_post_} .= '&format='.$self->{_format_} if (defined $self->{_format_});
    $self->{_post_} .= '&options='.$self->{_options_} if (defined $self->{_options_});
    my $response = $self->{_http_}->get($self->{_base_} . $query  . $self->{_post_});

    die "Invalid API key\n" if ($response->{status} eq '401');
    die "Blocked API key\n" if ($response->{status} eq '402');
    die "Exceeded the daily limit on the amount of translated text\n" if ($response->{status} eq '404');
    die "Exceeded the maximum text size\n" if ($response->{status} eq '413');
    die "The text cannot be translated\n" if ($response->{status} eq '422');
    die "The specified translation direction is not supported\n" if ($response->{status} eq '501');
    die "Failed to translate text! (response code $response->{status})\n" unless ($response->{success});

    if (defined wantarray && length $response->{content}) {
        my $json_respond = JSON->new->utf8->decode($response->{content});
        if (defined $self->{_options_}) {
            return ($json_respond->{detected}->{lang}, $json_respond->{text}[0]);
        }
        else {
            return (wantarray) ? ($json_respond->{text}[0]) : $json_respond->{text}[0];
        }
    }
}

#
# See §2.7 of Пользовательское соглашение сервиса «API Яндекс.Переводчик»
# at https://yandex.ru/legal/translate_api/
#
# See §2.7 of Terms of Use of API Yandex.Translate Service
# at https://yandex.com/legal/translate_api/
#

sub get_yandex_technology_reference
{
    my ( $self, $attribute ) = @_;
    if (defined wantarray) {
        my %yandex_attribute;
        if (defined $attribute && ref($attribute) eq 'HASH') {
            while (my ( $key, $value ) = each %{ $attribute }) {
                $yandex_attribute{$key} = $key.'="'.encode_entities($value).'"' if (lc $key ne 'href');
            }
        }

        #
        # Sort %yandex_attribute so that the same $yandex_attributes value
        # will consistently be produced for a given $attribute hash.
        #
        my $yandex_attributes = (%yandex_attribute) ? ' '.join(' ', map { $yandex_attribute{$_} } sort { $a cmp $b } keys %yandex_attribute) : '';

        my %yandex_url = (
            ru => 'http://translate.yandex.ru/',
            en => 'http://translate.yandex.com/',
	    tr => 'http://translate.yandex.com.tr/',
        );
        my %yandex_text = (
            ru => 'Переведено сервисом Яндекс.Переводчик',
            en => 'Powered by Yandex.Translate',
	    tr => 'Tarafından desteklenmektedir Yandex.Çeviri',
        );
        my $yandex_url = (exists $yandex_url{$self->{_ui_}}) ? $yandex_url{$self->{_ui_}} : $yandex_url{$default_ui};
        my $yandex_text = (exists $yandex_text{$self->{_ui_}}) ? $yandex_text{$self->{_ui_}} : $yandex_text{$default_ui};
        my $yandex_element = '<a'.$yandex_attributes.' href="'.$yandex_url.'">'.$yandex_text.'</a>';
        return (wantarray) ? ($yandex_element) : $yandex_element;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Yandex::Translate - a simple API for Yandex.Translate

=head1 VERSION

version 1.002

=head1 SYNOPSIS

    use utf8; #It is require
    use Yandex::Translate;

    my $tr = Yandex::Translate->new;

    # Set the Yandex API key that you can get from https://tech.yandex.com/
    $tr->set_key('yandex_key');

    # Set the text that you want to translate
    $tr->set_text('In the name of God');

    # Set the source language
    $tr->set_from_lang('en');

    # Set the destination language
    $tr->set_to_lang('ru');

    # Get the result
    print $tr->translate();

=head1 DESCRIPTION

Yandex.Translate (previously Yandex.Translation) is a web service
provided by Yandex, intended for the translation of text or web pages
into another language.

The service uses a self-learning statistical machine translation,
developed by Yandex. The system constructs the dictionary of
correspondences based on the analysis of millions of translated texts.

=head1 METHODS

=head2 new

    $tr = Yandex::Translate->new(@attributes);

This constructor returns a new C<Yandex::Translate> object. Optional attributes
include:

=over 4

=item *

_key_ - An API key that you can get from the Yandex website
after registering, string format.

=item *

_text_ - The text that you want to translate, string format.

=item *

_from_lang_ - The source language, string format.

=item *

_to_lang_ - The destination language, string format.

=item *

_ui_ - The user interface language, string format.

=item *

_hint_ - A list of comma-separated languages for detecting the text language,
array reference format.

=item *

_format_ - The returned text format, either C<plain> (default) or C<html>.

=item *

_options_ - C<1> if the response should include the automatically detected language of the text to be translated.

=back

=head2 set_key

    $tr->set_key('yandex_key');

This method is used to pass a Yandex API key (string), instead of passing it
in L</new>. A C<Yandex::Translate> object can be instantiated
without any attributes.

=head2 set_text

    $tr->set_text('text_to_translate');

This method is used to pass a text to translate (string).

=head2 set_from_lang

    $tr->set_from_lang('zh');

This method is used to pass a source language (string).
For example, Chinese would be given as C<zh>.

=head2 set_to_lang

    $tr->set_to_lang('ar');

This method is used to pass a destination language (string).
For example, Arabic would be given as C<ar>.

=head2 set_ui

    $tr->set_ui('fr');

This method is used to set the user interface language (string).
For example, French would be given as C<fr>.

=head2 set_default_ui

    $tr->set_default_ui('ru');

This method is used to set the default user interface language (string).
Either C<ru> (Russian) or C<en> (English) or C<tr> (Turkish)  can be given.

=head2 set_hint

    $tr->set_hint([qw{es pt}]);

This method is used to set the list of likely languages for detecting
the text language (array reference). For example, Spanish and Portuguese
would be given as C<[qw{es pt}]>.

=head2 set_format

    $tr->set_format('html');

This method is used to set the format of the text to be translated
(string). Either C<plain> or C<html> can be given.

=head2 set_options

    $tr->set_options('1');

This method is used to set options for the translated text language response
(string). The only option currently supported is C<1> (to also return
the automatically detected language of the text to be translated).

=head2 translate

    print $tr->translate(), "\n";

This method is used to get the translated text. If L</set_options> has been
previously called, it returns an array of two elements, with the first element
containing the detected language of the original text (string) and the second
element containing the translated text (string); otherwise, only the
translated text is returned.

=head2 detect_lang

    print $tr->detect_lang(), "\n";

This method is used to detect the language of the text. It returns a string.

=head2 get_langs_list

    print join(',', $tr->get_langs_list()), "\n";

    print scalar($tr->get_langs_list()), "\n";

This method is used to get the list of supported translation directions.
In array context, it returns an array of these directions; in scalar context,
it returns the count of them.

=head2 get_yandex_technology_reference

    print $tr->get_yandex_technology_reference(), "\n";

    print $tr->get_yandex_technology_reference({ id => 'yandex' }), "\n";

This method is used to get the HTML C<E<lt>aE<gt>> element that
the L<Yandex Terms of Use of API Yandex.Translate Service|https://yandex.com/legal/translate_api/>
requires to be displayed either directly above or directly below
the translated text. An optional hash reference of attributes and values
for the returned element can be passed in.

=head1 SEE ALSO

For more information, please visit L<Yandex|https://translate.yandex.com/developers>.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests on my email.

L<https://fossil.falseking.site/ticket>

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://fossil.falseking.site/dir?ci=tip&type=tree>

=head1 AUTHORS

=over 4

=item *

James Axl C<E<lt>axlrose112@gmail.comE<gt>>

=item *

Christian Carey

=back

=head1 COPYLEFT AND LICENSE

This software is copyleft E<copy> 2017 by James Axl.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

