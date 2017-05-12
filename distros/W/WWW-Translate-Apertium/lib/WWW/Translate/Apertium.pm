package WWW::Translate::Apertium;

use strict;
use warnings;
use Carp qw(carp);
use LWP::UserAgent;
use URI::Escape;
use HTML::Entities;
use Encode;
use utf8;


our $VERSION = '0.16';


my %lang_pairs = (
                    'es-ca'          => 'Spanish -> Catalan', # Default
                    'ca-es'          => 'Catalan -> Spanish',
                    'es-gl'          => 'Spanish -> Galician',
                    'gl-es'          => 'Galician -> Spanish',
                    'es-pt'          => 'Spanish -> Portuguese',
                    'pt-es'          => 'Portuguese -> Spanish',
                    'ca-pt'          => 'Catalan -> Portuguese',
                    'pt-ca'          => 'Portuguese -> Catalan',
                    'gl-pt'          => 'Galician -> Portuguese',
                    'pt-gl'          => 'Portuguese -> Galician',
                    'es-pt_BR'       => 'Spanish -> Brazilian Portuguese',
                    'oc-ca'          => 'Occitan -> Catalan',
                    'ca-oc'          => 'Catalan -> Occitan',
                    'oc-es'          => 'Occitan -> Spanish',
                    'es-oc'          => 'Spanish -> Occitan',
                    'oc_aran-ca'     => 'Aranese -> Catalan',
                    'ca-oc_aran'     => 'Catalan -> Aranese',
                    'en-ca'          => 'English -> Catalan',
                    'ca-en'          => 'Catalan -> English',
                    'fr-ca'          => 'French -> Catalan',
                    'ca-fr'          => 'Catalan -> French',
                    'fr-es'          => 'French -> Spanish',
                    'es-fr'          => 'Spanish -> French',
                    'ca-eo'          => 'Catalan -> Esperanto',
                    'es-eo'          => 'Spanish -> Esperanto',
                    'en-eo'          => 'English -> Esperanto',
                    'eo-en'          => 'Esperanto -> English',
                    'ro-es'          => 'Romanian -> Spanish',
                    'es-en'          => 'Spanish -> English',
                    'en-es'          => 'English -> Spanish',
                    'cy-en'          => 'Welsh -> English',
                    'eu-es'          => 'Basque -> Spanish',
                    'en-gl'          => 'English -> Galician',
                    'gl-en'          => 'Galician -> English',
                    'br-fr'          => 'Breton -> French',
                    'nb-nn'          => 'Norwegian Bokmål -> Norwegian Nynorsk',
                    'nn-nb'          => 'Norwegian Nynorsk -> Norwegian Bokmål',
                    'sv-da'          => 'Swedish-Danish',
                    'es-ast'         => 'Spanish-Asturian',
                    'is-en'          => 'Icelandic-English',
                    'bg-mk'          => 'Bulgarian-Macedonian',
                    'mk-bg'          => 'Macedonian-Bulgarian',
                 );

my %output =     (
                    plain_text  => 'txtf',  # default
                    marked_text => 'txt',
                 );

my %defaults =   (
                    lang_pair     => 'ca-es',
                    output        => 'plain_text',
                    store_unknown => 0,
                 );


sub new {
    my $class = shift;
    
    # validate overrides
    my %overrides = @_;
    foreach (keys %overrides) {
        # check key; warn if illegal
        carp "Unknown parameter: $_\n" unless exists $defaults{$_};
        
        # check value; warn and delete if illegal
        if ($_ eq 'output' && !exists $output{$overrides{output}}) {
            carp _message('output', $overrides{output});
            delete $overrides{output};
        }
        if ($_ eq 'lang_pair' && !exists $lang_pairs{$overrides{lang_pair}}) {
            carp _message('lang_pair', $overrides{lang_pair});
            delete $overrides{lang_pair};
        }
    }
    
    # replace defaults with overrides
    my %args = (%defaults, %overrides);
    
    # remove invalid parameters
    my @fields = keys %defaults;
    my %this;
    @this{@fields} = @args{@fields};
    
    if ($this{store_unknown}) {
        $this{unknown} = ();
    }
    
    
    $this{agent} = LWP::UserAgent->new( agent => 'apertium2perl' );
    $this{agent}->env_proxy();
    $this{url} = 'http://xixona.dlsi.ua.es/webservice/ws.php';
    
    
    return bless(\%this, $class);
}


sub translate {
    my $self = shift;
    
    my $string;
    if (@_ > 0) {
        $string = shift;
    } else {
        carp "Nothing to translate\n";
        return '';
    }
    
    return '' if ($string eq '');
    
    $string = _fix_source($string);
    $string = uri_escape_utf8($string);

    my $browser = $self->{agent};
    
    
    my $source_lang = substr($self->{lang_pair}, 0, 2);
    my $target_lang = substr($self->{lang_pair}, 3, 2);
    
    my $url = "$self->{url}?mode=$self->{lang_pair}&format=txt&text=$string";
    
    if ($self->{output} eq 'marked_text') {
        $url .= "&mark=1";
    } else {
        $url .= "&mark=0";
    }
    
    my $response = $browser->get($url);
    
    
    unless ($response->is_success) {
        carp $response->status_line;
        return undef;
    }
    
    
    if (!defined $response) {
        carp "Didn't receive a translation from the Apertium server.\n" .
             "Please check the length of the source text.\n";
        return '';
    }
    
    my $translated = _fix_translated($response->{'_content'});
    
    $translated = decode_utf8($translated);
    $translated = decode_entities($translated);
    
    if ($self->{output} eq 'marked_text') {
        
        if ($self->{store_unknown}) {
            
            # store unknown words
            if ($translated =~ /(?:^|\W)\*/) {
                
                while ($translated =~ /(?:^|\W)\*(\w+?)\b/g) {
                    $self->{unknown}->{$source_lang}->{$1}++;
                }
            }
        }
    }
    
    return $translated;
}

sub from_into {
    my $self = shift;
    
    
    if (@_) {
        my $pair = shift;
        if (!exists $lang_pairs{$pair}) {
            carp _message('lang_pair', $pair);
            $self->{lang_pair} = $defaults{'lang_pair'};
        } else {
            $self->{lang_pair} = $pair;
        }
    } else {
        return $self->{lang_pair};
    }
}

sub output_format {
    my $self = shift;
    
    if (@_) {
        my $format = shift;
        $self->{output} = $format if exists $output{$format};
    } else {
        return $self->{output};
    }
}

sub get_unknown {
    my $self = shift;
    
    if (@_ && $self->{store_unknown}) {
        my $lang_code = shift;
        if ($lang_code =~ /^(?:br|ca|cy|en|eo|es|eu|fr|gl|is|nb|nn|oc|oc_aran|pt|ro|sv|bg|mk)$/) {
            return $self->{unknown}->{$lang_code};
        } else {
            carp "Invalid language code\n";
        }
    } else {
        carp "I'm not configured to store unknown words\n";
    }
}

sub get_pairs {
    my $self = shift;
    
    return %lang_pairs;
}

sub _message {
    my ($key, $value) = @_;
    
    my $string = "Invalid value for parameter $key, $value.\n" .
                 "Will use the default value instead.\n";
                 
    return $string;
}

sub _fix_source {
    my ($string) = @_;
    
    # fix geminated l; replace . by chr(183) = hex B7
    $string =~ s/l\.l/l\xB7l/g;
    
    return $string;
}

sub _fix_translated {
    my ($string) = @_;
    
    # remove double spaces
    $string =~ s/(?<=\S)\s{2}(?=\S)/ /g;
    
    return $string;
}


1;

__END__

=encoding utf8

=head1 NAME

WWW::Translate::Apertium - Open source machine translation


=head1 VERSION

Version 0.16 September 6, 2010


=head1 SYNOPSIS

    use WWW::Translate::Apertium;
    
    my $engine = WWW::Translate::Apertium->new();
    
    my $translated_string = $engine->translate($string);
    
    # default language pair is Catalan -> Spanish
    # change to Spanish -> Galician:
    $engine->from_into('es-gl');
    
    # check current language pair:
    my $current_langpair = $engine->from_into();
    
    # get available language pairs:
    my %pairs = $engine->get_pairs();
    
    # default output format is 'plain_text'
    # change to 'marked_text':
    $engine->output_format('marked_text');
    
    # check current output format:
    my $current_format = $engine->output_format();
    
    # configure a new Apertium object to store unknown words:
    my $engine = WWW::Translate::Apertium->new(
                                                output => 'marked_text',
                                                store_unknown => 1,
                                              );
    
    # get unknown words for source language = Aranese
    my $es_unknown_href = $engine->get_unknown('oc_aran');

=head1 DESCRIPTION

Apertium is an open source shallow-transfer machine translation engine designed
to translate between related languages (and less related languages). It is being
developed by the Department of Software and Computing Systems at the University
of Alicante. The linguistic data is being developed by research teams from the
University of Alicante, the University of Vigo and the Pompeu Fabra University.
For more details, see L<http://www.apertium.org/>.

WWW::Translate::Apertium provides an object oriented interface to the Apertium
online machine translation web service, based on Apertium 3.0.



Currently, Apertium supports the following language pairs:

- Bidirectional

=over 4

=item * Aranese < > Catalan

=item * Bulgarian < > Macedonian

=item * Catalan < > English

=item * Catalan < > French

=item * Catalan < > Occitan

=item * Catalan < > Portuguese

=item * Catalan < > Spanish

=item * French < > Spanish

=item * English < > Galician

=item * English < > Spanish

=item * English < > Esperanto

=item * Galician < > Portuguese

=item * Galician < > Spanish

=item * Norwegian Bokmål < > Norwegian Nynorsk

=item * Occitan < > Spanish

=item * Portuguese < > Spanish


=back


- Single Direction

=over 4

=item * Basque    >   Spanish

=item * Breton    >   French

=item * Catalan   >   Esperanto

=item * Icelandic >   English

=item * Romanian  >   Spanish

=item * Spanish   >   Asturian

=item * Spanish   >   Brazilian Portuguese

=item * Spanish   >   Catalan (Valencian)

=item * Spanish   >   Esperanto

=item * Swedish   >   Danish

=item * Welsh     >   English

=back



=head1 CONSTRUCTOR

=head2 new()

Creates and returns a new WWW::Translate::Apertium object.

    my $engine = WWW::Translate::Apertium->new();

WWW::Translate::Apertium recognizes the following parameters:

=over 4

=item * C<< lang_pair >>

You can find below the valid values of this parameter, classified by source language:

B<Aranese> into:

=over 8

=item * B<Catalan> -- C<< oc_aran-ca >>

=back

B<Basque> into:

=over 8

=item * B<Spanish> -- C<< eu-es >>

=back

B<Breton> into:

=over 8

=item * B<French> --C<< br-fr >>

=back

B<Bulgarian> into:

=over 8

=item * B<Macedonian> --C<< bg-mk >>

=back

B<Catalan> into:

=over 8

=item * B<Aranese> -- C<< ca-oc_aran >>

=item * B<English> -- C<< ca-en >>

=item * B<Esperanto> -- C<< ca-eo >>

=item * B<French> -- C<< ca-fr >>

=item * B<Occitan> -- C<< ca-oc >>

=item * B<Spanish> -- C<< ca-es >>

=back

B<English> into:

=over 8

=item * B<Catalan> -- C<< en-ca >>

=item * B<Esperanto> -- C<< en-eo >>

=item * B<Galician> -- C<< en-gl >>

=item * B<Spanish> -- C<< en-es >>

=back

B<Esperanto> into:

=over 8

=item * B<English> -- C<< eo-en >>

=back

B<French> into:

=over 8

=item * B<Catalan> -- C<< fr-ca >>

=item * B<Spanish> -- C<< fr-es >>

=back

B<Galician> into:

=over 8

=item * B<English> -- C<< gl-en >>

=item * B<Spanish> -- C<< gl-es >>

=back

B<Icelandic> into:

=over 8

=item * B<English> -- C<< is-en >>

=back

B<Macedonian> into:

=over 8

=item * B<Bulgarian> --C<< mk-bg >>

=back

B<Norwegian Bokmål> into:

=over 8

=item * B<Norwegian Nynorsk> -- C<< nb-nn >>

=back

B<Norwegian Nynorsk> into:

=over 8

=item * B<Norwegian Bokmål> -- C<< nn-nb >>

=back

B<Occitan> into:

=over 8

=item * B<Catalan> -- C<< oc-ca >>

=item * B<Spanish> -- C<< oc-es >>

=back

B<Portuguese> into:

=over 8

=item * B<Catalan> -- C<< pt-ca >>

=item * B<Galician> -- C<< pt-gl >>

=item * B<Spanish> -- C<< pt-es >>

=back

B<Romanian> into:

=over 8

=item * B<Spanish> -- C<< ro-es >>

=back

B<Spanish> into:

=over 8

=item * B<Asturian> -- C<< es-ast >>

=item * B<Brazilian Portuguese> -- C<< es-pt_BR >>

=item * B<Catalan> -- C<< es-ca >>

=item * B<English> -- C<< es-en >>

=item * B<Esperanto> -- C<< es-eo >>

=item * B<French> -- C<< es-fr >>

=item * B<Galician> -- C<< es-gl >>

=item * B<Portuguese> -- C<< es-pt >>

=back

B<Swedish> into:

=over 8

=item * B<Danish> -- C<< sv-da >>

=back

B<Welsh> into:

=over 8

=item * B<English> -- C<< cy-en >>

=back

These language pairs are stable versions. Other language pairs are currently
under development.

=item * C<< output >>

The valid values of this parameter are:

=over 8

=item * C<< plain_text >>

Returns the translation as plain text (default value).

=item * C<< marked_text >>

Returns the translation with the unknown words marked with an asterisk.

B<Warning>: This feature is always on in the current version of the Catalan < > French
language pair due to a bug in the stable package for these languages. It will be
fixed in the next release.

=back

=item * C<< store_unknown >>

Off by default. If set to a true value, it configures the engine object to store
in a hash the unknown words and their frequencies during the session.
You will be able to access this hash later through the B<get_unknown> method.
If you change the engine language pair in the same session, it will also
create a separate word list for the new source language.

B<IMPORTANT>: If you activate this setting, then you must also set the 
B<output> parameter to I<marked_text>. Otherwise, the B<get_unknown> method will
return an empty hash.

=back


The default parameter values can be overridden when creating a new
Apertium engine object:

    my %options = (
                    lang_pair => 'es-ca',
                    output => 'marked_text',
                    store_unknown => 1,
                  );

    my $engine = WWW::Translate::Apertium->new(%options);

=head1 METHODS

=head2 $engine->translate($string)

Returns the translation of $string generated by Apertium, encoded as UTF-8.
In case the server is down, the C<translate> method will show a warning and
return C<undef>.

The input $string must be an UTF-8 encoded string (for this task you can use
the Encode module or the PerlIO layer, if you are reading the text from a file).

If you are going to translate a string literal included in the code and then
display the result in the output window of the code editor, then you should add
the following statement to your code in order to avoid a "Wide character in
print" warning:

    binmode(STDOUT, ':utf8');


=head2 $engine->from_into($lang_pair)

Changes the engine language pair to $lang_pair.
When called with no argument, it returns the value of the current engine
language pair.

=head2 $engine->get_pairs()

Returns a hash containing the available language pairs.
The hash keys are the language codes, and the values are the corresponding
language names.

=head2 $engine->output_format($format)

Changes the engine output format to $format.
When called with no argument, it returns the value of the current engine
output format.

=head2 $engine->get_unknown($lang_code)

If the engine was configured to store unknown words, it returns a reference to
a hash containing the unknown words (keys) detected during the current machine
translation session for the specified source language, along with their
frequencies (values).

The valid values of $lang_code for the source language are (in alphabetical order):

=over 8

=item * C<< bg >>  --  Bulgarian

=item * C<< br >>  --  Breton

=item * C<< ca >>  --  Catalan

=item * C<< cy >>  --  Welsh

=item * C<< en >>  --  English

=item * C<< eo >>  --  Esperanto

=item * C<< es >>  --  Spanish

=item * C<< eu >>  --  Basque

=item * C<< fr >>  --  French

=item * C<< gl >>  --  Galician

=item * C<< is >>  --  Icelandic

=item * C<< mk >>  --  Macedonian

=item * C<< nb >>  --  Norwegian Bokmål

=item * C<< nn >>  --  Norwegian Nynorsk

=item * C<< oc >>  --  Occitan

=item * C<< oc_aran >>  --  Aranese

=item * C<< pt >>  --  Portuguese

=item * C<< ro >>  --  Romanian

=item * C<< sv >>  --  Swedish

=back

=head1 DEPENDENCIES

LWP::UserAgent

URI::Escape

HTML::Entities

=head1 SEE ALSO

WWW::Translate::interNOSTRUM

=head1 REFERENCES

Apertium project website:

L<http://www.apertium.org/>

If you want to get I<the real thing>, you can download the Apertium code and
build it on your local machine. You will find detailed setup instructions in
the Apertium wiki:

L<http://wiki.apertium.org/wiki/Installation>

=head1 ACKNOWLEDGEMENTS

Many thanks to Mikel Forcada Zubizarreta, coordinator of the Transducens
research team of the Department of Software and Computing Systems at the
University of Alicante, who kindly answered my questions during the development
of this module, and to Xavier Noria, João Albuquerque, and Kevin Brubeck Unhammer
for useful suggestions.
The author is also grateful to Francis Tyers, a member of the Apertium team
who provided essential feedback for the latest versions of this module.


=head1 AUTHOR

Enrique Nell, C<< <blas.gordon at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-www-translate-apertium at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Translate-Apertium>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Translate::Apertium


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Translate-Apertium>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Translate-Apertium>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Translate-Apertium>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Translate-Apertium/>

=back


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2010 by Enrique Nell, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut



