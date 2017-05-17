package Yandex::Dictionary;

use strict;
use warnings;
use utf8;

use HTML::Entities qw{encode_entities};
use HTTP::Tiny;
use JSON;
use POSIX qw{:locale_h};
use URI::Escape qw{uri_escape_utf8};

my
$VERSION = '0.02';

my %valid_lang = map { $_ => 1 } qw{
   be-be be-ru bg-ru cs-en cs-ru da-en da-ru de-de de-en 
   de-ru de-tr el-en el-ru en-cs en-da en-de en-el en-en 
   en-es en-et en-fi en-fr en-it en-lt en-lv en-nl en-no 
   en-pt en-ru en-sk en-sv en-tr en-uk es-en es-es es-ru 
   et-en et-ru fi-en fi-fi fi-ru fr-en fr-fr fr-ru hu-hu 
   hu-ru it-en it-it it-ru lt-en lt-lt lt-ru lv-en lv-ru 
   mhr-ru mrj-ru nl-en nl-ru no-en no-ru pl-ru pt-en pt-ru 
   ru-be ru-bg ru-cs ru-da ru-de ru-el ru-en ru-es ru-et 
   ru-fi ru-fr ru-hu ru-it ru-lt ru-lv ru-mhr ru-mrj ru-nl 
   ru-no ru-pl ru-pt ru-ru ru-sk ru-sv ru-tr ru-tt ru-uk 
   sk-en sk-ru sv-en sv-ru tr-de tr-en tr-ru tt-ru uk-en 
   uk-ru uk-uk
};

my %valid_default_ui = map { $_ => 1 } qw{ en ru tr };

my %valid_format = map { $_ => 1 } qw{ json xml };

my $default_format = 'json';

my $james_axl_result = sub
{
    my $self = shift;
    die "You must set API key\n" if (not defined $self->{ _key_ });
    die "You must set Text\n" if (not defined $self->{ _text_ });
    my $query = '/lookup?';
    my $post = 'key='.$self->{ _key_ }.'&text='.$self->{ _text_ }.'&lang='.$self->{_lang_}.'&ui='.$self->{_ui_};
    my $response = $self->{_http_}->get($self->{_base_} . '.json' . $query . $post);
    die "Invalid API key.\n" if ($response->{status} eq '401');
    die "Blocked API key.\n" if ($response->{status} eq '402');
    die "Exceeded the daily limit on the number of requests.\n" if ($response->{status} eq '403');
    die "The text size exceeds the maximum.\n" if ($response->{status} eq '413');
    die "The specified translation direction is not supported.\n" if ($response->{status} eq '501');
    die "Failed to get list of supported languages! (response code $response->{status})\n" unless ($response->{success});
    if (defined wantarray && length $response->{content}) {
        my $json_respond = JSON->new->utf8->decode($response->{content});
	return $json_respond->{def};
    }
};

#
## Set the default UI to Russian if the locale is Russian;
## Set the default UI to Turkish if the locale is Turkish;
## otherwise, set it to English.
##
#
(my $default_ui = setlocale(LC_CTYPE) || 'en') =~ s/_.*$//;
$default_ui = 'en' if (!exists $valid_default_ui{$default_ui});

sub new
{
    my $class = shift;
    my $self = {
	    _key_       =>    shift,
	    _text_      =>    shift,
	    _lang_      =>    shift,
	    _ui_        =>    shift || $default_ui, 
	    _format_    =>    shift || $default_format,
	    _base_      =>    'https://dictionary.yandex.net/api/v1/dicservice' ,
	    _http_      =>    HTTP::Tiny->new,
    };

    $self->{_text_} = uri_escape_utf8($self->{_text_}) if (defined $self->{_text_});
    return bless $self, $class;
}

sub set_key
{
    my ($self,$key) = @_;
    $self->{_key_} = $key if (defined $key);
}

sub set_text
{
    my ($self,$test) = @_;
    $self->{_text_} = $test if (defined $test);
}

sub set_lang
{
    my ($self,$lang) = @_;
    $self->{_lang_} = $lang if (defined $lang && exists $valid_lang{$lang});
}

sub set_format
{
    my ($self,$format) = @_;
    $self->{_format_} = (defined $format && exists $valid_format{$format}) ? $format : $default_format;
}

sub set_ui
{
    my ($self,$ui) = @_;
    $self->{_ui_} = (defined $ui && exists $valid_default_ui{$ui}) ? $ui : $default_ui;
}

sub set_default_ui
{
    my ($self,$this_default_ui) = @_;
    $default_ui = $this_default_ui if (defined $this_default_ui && exists $valid_default_ui{$this_default_ui});
}

sub get_langs_list
{
    my $self = shift;
    die "You must set API key\n" if (not defined $self->{ _key_ });
    my $query = '/getLangs?';
    my $post = 'key='.$self->{_key_}.'&ui='.$self->{_ui_};
    $self->{_format_} = (defined $self->{_format_} && exists $valid_format{$self->{_format_}}) ? $self->{_format_} :$default_format;
    my $format =  ($self->{_format_} eq 'xml') ? '' : '.json';
    my $response = $self->{_http_}->get($self->{_base_} . $format . $query . $post);

    die "Invalid API key\n" if ($response->{status} eq '401');
    die "Blocked API key\n" if ($response->{status} eq '402');
    die "Failed to get list of supported languages! (response code $response->{status})\n" unless ($response->{success});

    if (length $response->{content}) {
        return $response->{content};
    }
}

sub james_axl_langs_list
{
    my $self = shift;
    die "You must set API key\n" if (not defined $self->{ _key_ });
    die "You must set Text\n" if (not defined $self->{ _text_ });
    my $query = '/getLangs?';
    my $post = 'key='.$self->{_key_}.'&ui='.$self->{_ui_};
    my $response = $self->{_http_}->get($self->{_base_} .'.json' . $query . $post);
    die "Invalid API key\n" if ($response->{status} eq '401');
    die "Blocked API key\n" if ($response->{status} eq '402');
    die "Failed to get list of supported languages! (response code $response->{status})\n" unless ($response->{success});
    if (defined wantarray && length $response->{content}) {
        my $json_respond = JSON->new->utf8->decode($response->{content});
	return (wantarray) ? @{ $json_respond } : scalar(@{ $json_respond });
    }
}

sub get_result
{
    my $self = shift;
    die "You must set API key\n" if (not defined $self->{ _key_ });
    die "You must set Text\n" if (not defined $self->{ _text_ });
    my $query = '/lookup?';
    my $post = 'key='.$self->{ _key_ }.'&text='.$self->{ _text_ }.'&lang='.$self->{_lang_}.'&ui='.$self->{_ui_};
    $self->{_format_} = $default_format if (defined $self->{_format_} && !exists $valid_format{$self->{_format_}});
    my $format =  ($self->{_format_} eq 'xml') ? '' : '.json';
    my $response = $self->{_http_}->get($self->{_base_} . $format . $query . $post);
    die "Invalid API key.\n" if ($response->{status} eq '401');
    die "Blocked API key.\n" if ($response->{status} eq '402');
    die "Exceeded the daily limit on the number of requests.\n" if ($response->{status} eq '403');
    die "The text size exceeds the maximum.\n" if ($response->{status} eq '413');
    die "The specified translation direction is not supported.\n" if ($response->{status} eq '501');
    die "Failed to get list of supported languages! (response code $response->{status})\n" unless ($response->{success});
    if (length $response->{content}) {
        return $response->{content};
    }
}

sub get_input_text_pos_ts
{
    my $self = shift;
    my $respond  = $self->$james_axl_result();
    my $index = undef;
    my $result = [];
    for ($index = 0; $index < scalar @{$respond} ; $index+=1){
	push @{$result}, {
		          'text' => ${$respond}[$index]->{text},
	                  'pos'  => ${$respond}[$index]->{pos},
			  'ts'  => ${$respond}[$index]->{ts}
	                 };
    }

    return (wantarray) ? @{ $result } : scalar(@{ $result });
}

# In English does not have 'gen'
sub get_result_tr_pos_gen
{
    my $self = shift;
    my $respond  = $self->$james_axl_result();
    my ($x,$y,$result) = (undef, undef, []);

    for ($x = 0; $x < scalar @{$respond} ; $x+=1){
        for ($y = 0; $y < scalar @{$respond->[$x]->{tr}} ; $y+=1) {	    
		push @{$result}, {
		              'text' => ${$respond}[$x]->{tr}[$y]->{text},
			      'pos'  => ${$respond}[$x]->{tr}[$y]->{pos},
			      'gen'  => ${$respond}[$x]->{tr}[$y]->{gen}
			     };
        }
    }

    return (wantarray) ? @{ $result } : scalar(@{ $result });
}

sub get_result_mean
{
    my $self = shift;
    my $respond  = $self->$james_axl_result();
    my ($x,$y,$z,$result) = (undef, undef, undef ,[]);
    for ($x = 0; $x < scalar @{$respond} ; $x+=1){
	for ($y = 0; $y < scalar @{$respond->[$x]->{tr}} ; $y+=1) {	
	    if (defined ${$respond}[$x]->{tr}[$y]->{mean}[0]->{text}){
                for ($z = 0; $z < scalar @{$respond->[$x]->{tr}->[$y]->{mean}} ; $z+=1) {
                    push @{$result}, ${$respond}[$x]->{tr}[$y]->{mean}[$z]->{text};
                }
            }
	}
    }

    return (wantarray) ? @{ $result } : scalar(@{ $result });
}

sub get_result_syn
{
    my $self = shift;
    my $respond  = $self->$james_axl_result();
    my ($x,$y,$z,$result) = (undef, undef, undef ,[]);
    for ($x = 0; $x < scalar @{$respond} ; $x+=1){
        for ($y = 0; $y < scalar @{$respond->[$x]->{tr}} ; $y+=1) {
            if (defined ${$respond}[$x]->{tr}[$y]->{syn}[0]->{text}){
                for ($z = 0; $z < scalar @{$respond->[$x]->{tr}->[$y]->{syn}} ; $z+=1) {
                    push @{$result}, {
			    'text' => ${$respond}[$x]->{tr}[$y]->{syn}[$z]->{text},
			    'pos'  => ${$respond}[$x]->{tr}[$y]->{syn}[$z]->{pos},
			    'gen'  => ${$respond}[$x]->{tr}[$y]->{syn}[$z]->{gen}
		    }
                }
            }
        }
    }

    return (wantarray) ? @{ $result } : scalar(@{ $result });
}

sub get_result_eg
{
    my $self = shift;
    my $respond  = $self->$james_axl_result();
    my ($x,$y,$z,$result) = (undef, undef, undef ,[]);
    for ($x = 0; $x < scalar @{$respond} ; $x+=1){
        for ($y = 0; $y < scalar @{$respond->[$x]->{tr}} ; $y+=1) {
            if (defined ${$respond}[$x]->{tr}[$y]->{ex}[0]->{text}){
	        for ($z = 0; $z < scalar @{$respond->[$x]->{tr}->[$y]->{ex}} ; $z+=1) {
		    push @{$result}, {
		        'text' => ${$respond}[$x]->{tr}[$y]->{ex}[$z]->{text},
			'tr' => ${$respond}[$x]->{tr}[$y]->{ex}[$z]->{tr}[0]->{text}
		    }
		}
	    }
        }
    }

    return (wantarray) ? @{ $result } : scalar(@{ $result });
}

1;
__END__

=encoding utf-8

=head1 NAME

Yandex::Dictionary - a simple API for Yandex.Dictionary

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Yandex::Dictionary;
  use Data::Dumper; 
  use utf8;

  my $dic = Yandex::Dictionary->new;
  $dic->set_key('yandex_key');
  $dic->set_text('time');

  $dic->set_lang('en-ru');
  my @result = $dic->get_result();

  print Dumper \@result ,"\n";

=head1 DESCRIPTION

The API is used for getting detailed dictionary entries from the static 
Yandex.Dictionary. Unlike conventional translation dictionaries, it is 
compiled automatically using the technologies at the root of the Yandex 
machine translation system. Yandex.Dictionary entries include the word’s 
part of speech, and translations are grouped with examples. For English words, 
the transcription is provided. The service supports a total of 17 language pairs.

Note also that the “Yandex Terms of Use of API Yandex.Dictionary Service”
at https://yandex.com/legal/dictionary_api/ must be observed.

=head1 METHODS

=head2 new

    $tr = Yandex::Dictionary->new(@attributes);

This constructor returns a new C<Yandex::Dictionary> object. Optional attributes
include:

=over 4

=item *

_key_ - An API key that you can get from the Yandex website
after registering, string format.

=item *

_text_ - Input Text, string format.

=item *

_lang_ - pair lang eg: en-ru from english tu russian, string format.

=item *

_ui_ - The user interface language, string format.

=item *

_format_ - The returned text format, either C<json> (default) or C<xml>.

=back


=head2 set_key

    $dic->set_key('yandex_key');

This method is used to pass a Yandex API key (string), instead of passing it
in L</new>. A C<Yandex::Dictionary> object can be instantiated
without any attributes.

=head2 set_text

    $tr->set_text('input_text');

This method is used to pass a text(string).

=head2 set_lang

    $dic->set_lang('en-ru');

This method is used to pass a pair lang (string).
For example, english would be given as C<en> and russian would be given as C<ru>.

=head2 set_ui

    $dic->set_ui('fr');

This method is used to set the user interface language (string).
For example, French would be given as C<fr>.

=head2 set_default_ui

    $dic->set_default_ui('ru');

This method is used to set the default user interface language (string).
Either C<ru> (Russian) or C<en> (English) or C<tr> (Turkish)  can be given.

=head2 set_format

    $dic->set_format('json');

This method is used to set the format of the output (string).
Either C<json> or C<xml> can be given.

=head2 get_result

    my $output = $dic->get_result();
    print $output , "\n";

This method is used to get the output result. If L</set_format> is 'json'
It returns json result that you can parse by yourself, if L</set_format> is 'xml'
It returns xml result that you can parse by yourself, check examples/result.json.

=head2 get_langs_list

    my $output = $dic->get_langs_list();
    print $output , "\n";

This method is used to get the list of supported translation directions.
It returns json result that you can parse by yourself, if L</set_format> is 'xml'
it returns xml result that you can parse by yourself.


=head2 james_axl_langs_list

    print join(',', $dic->james_axl_langs_list()), "\n";
    print scalar($dic->james_axl_langs_list()), "\n";

This method is used to get the list of supported translation directions.
In array context, it returns an array of these directions; in scalar context,
it returns the count of them.


=head2 get_input_text_pos_ts

    my @result = $dic->get_input_text_pos_ts();
    print Dumper \@result;

This method is used to get the input text that you enter,
pos (Part of speech) and ts.

=head2 get_result_tr_pos_gen

    my @result = $dic->get_result_tr_pos_gen();
    print Dumper \@result;

This method is used to get the text translate, pos and gen(genre).

=head2 get_result_mean

    my @result = $dic->get_result_mean()
    print Dumper \@result;

This method is used to get the list of meaning of the input text.

=head2 get_result_syn

    my @result = $dic->get_result_syn;
    print Dumper \@result;

This method is used to get the list of synonyms.

=head2 get_result_eg

    my @result = $dic->get_result_eg;
    print Dumper \@result;

This method is used to get the list of examples with translate.


=head1 SEE ALSO

For more information, please visit L<Yandex|https://tech.yandex.com/dictionary/>.

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

