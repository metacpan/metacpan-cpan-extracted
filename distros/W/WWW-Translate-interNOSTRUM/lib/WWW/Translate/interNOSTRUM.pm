package WWW::Translate::interNOSTRUM;

use strict;
use warnings;
use Carp qw(carp);
use WWW::Mechanize;
use Encode;


our $VERSION = '0.13';


my %lang_pairs = (
                    'ca-es' => 'Catalan -> Spanish',   # default
                    'es-ca' => 'Spanish -> Catalan',
                    'es-va' => 'Spanish -> Catalan with Valencian forms',
                 );

my %output =     (
                    plain_text => 'txtf',  # default
                    marked_text => 'txt',
                 );

my %defaults =   (
                    lang_pair => 'ca-es',
                    output => 'plain_text',
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
    
    $this{agent} = WWW::Mechanize->new();
    $this{agent}->env_proxy();
    $this{url} = 'http://www.internostrum.com/welcome.php'; 
    
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

    my $mech = $self->{agent};
    
    $mech->get($self->{url});
    unless ($mech->success) {
        carp $mech->response->status_line;
        return undef;
    }
    
    $mech->field("quadretext", $string);
    
    if ($self->{lang_pair} eq 'es-va') {
        $self->{lang_pair} = 'es-ca';
        $mech->tick('valen', 1);
    }
    $mech->select("direccio", $self->{lang_pair});  
    $mech->select("tipus", $output{$self->{output}});
    
    $mech->click();
    
    my $response = $mech->content();
            
    my $translated;
    if ($response =~
        /spelling\.<\/div>\s*<p class="textonormal">(.+?)<\/p>/s) { 
            $translated = $1;
    } else {
        carp "Didn't receive a translation from the interNostrum server.\n" .
             "Please check the length of the source text.\n";
        return '';
    }
            
    # remove double spaces
    $translated =~ s/(?<=\S)\s{2}(?=\S)/ /g;
    
    # store unknown words
    if ($self->{store_unknown} && $self->{output} eq 'marked_text') {
        
        if ($translated =~ /(?:^|\W)\*/) {
        
            my $source_lang = substr($self->{lang_pair}, 0, 2);
            my $utf8 = decode('iso-8859-1', $translated);
            
            while ($utf8 =~ /(?:^|\W)\*(\w+?)\b/g) {
                my $detected = encode('iso-8859-1', $1);
                $self->{unknown}->{$source_lang}->{$detected}++;
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
        if ($lang_code =~ /^(?:es|ca)$/) {
            return $self->{unknown}->{$lang_code};
        } else {
            carp "Invalid language code\n";
        }
    } else {
        carp "I'm not configured to store unknown words\n";
    }
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

1;

__END__


=head1 NAME

WWW::Translate::interNOSTRUM - Catalan < > Spanish machine translation [ OBSOLETE - Use WWW::Translate::Apertium instead ]


=head1 VERSION

Version 0.13 February 18, 2014


=head1 SYNOPSIS

    use WWW::Translate::interNOSTRUM;
    
    my $engine = WWW::Translate::interNOSTRUM->new();
    
    my $translated_string = $engine->translate($string);
    
    # default language pair is Catalan -> Spanish
    # change to Spanish -> Catalan:
    $engine->from_into('es-ca');
    
    # check current language pair:
    my $current_langpair = $engine->from_into();
    
    # default output format is 'plain_text'
    # change to 'marked_text':
    $engine->output_format('marked_text');
    
    # check current output format:
    my $current_format = $engine->output_format();
    
    # configure a new interNOSTRUM object to store unknown words:
    my $engine = WWW::Translate::interNOSTRUM->new(
                                                    output => 'marked_text',
                                                    store_unknown => 1,
                                                  );
    
    # get unknown words for source language = Spanish:
    my $es_unknown_href = $engine->get_unknown('es');

=head1 DESCRIPTION

[ OBSOLETE MODULE: interNOSTRUM will cease to be available on 31.05.2014, but interNOSTRUM 
technologies continue and expand in the free/open-source platform Apertium (accessible 
through WWW::Translate::Apertium). ] 


interNOSTRUM is a Catalan < > Spanish machine translation engine developed by
the Department of Software and Computing Systems of the University of Alicante
in Spain. This module provides an OO interface to the interNOSTRUM online
translation engine.

interNOSTRUM provides approximate translations of Catalan into Spanish and
Spanish into Catalan. It generates both the central variant of Oriental
Catalan (the standard variant used in Catalonia) and Valencian forms,
which follow the recommendations published in
L<http://www.ua.es/spv/assessorament/criteris.pdf>.
For more information on the Catalan variants, see the References
below.


=head1 CONSTRUCTOR

=head2 new()

Creates and returns a new WWW::Translate::interNOSTRUM object.

    my $engine = WWW::Translate::interNOSTRUM->new();

WWW::Translate::interNOSTRUM recognizes the following parameters:

=over 4

=item * C<< lang_pair >>

The valid values of this parameter are:

=over 8

=item * C<< ca-es >>

Standard Catalan or Valencian into Spanish (default value).

=item * C<< es-ca >>

Spanish into Standard Catalan.

=item * C<< es-va >>

Spanish into Valencian.

=back


=item * C<< output >>

The valid values of this parameter are:

=over 8

=item * C<< plain_text >>

Returns the translation as plain text (default value).

=item * C<< marked_text >>

Returns the translation with the unknown words marked with an asterisk.

=back

=item * C<< store_unknown >>

Off by default. If set to a true value, it configures the engine object to store
in a hash the unknown words and their frequencies during the session.
You will be able to access this hash later through the get_unknown method.
If you change the engine language pair in the same session, it will also
create a separate word list for the new source language.

B<IMPORTANT>: If you activate this setting, then you must also set the 
B<output> parameter to I<marked_text>. Otherwise, the get_unknown method will
return an empty hash.

=back


The default parameter values can be overridden when creating a new
interNOSTRUM engine object:

    my %options = (
                    lang_pair => 'es-ca',
                    output => 'marked_text',
                    store_unknown => 1,
                  );

    my $engine = WWW::Translate::interNOSTRUM->new(%options);

=head1 METHODS

=head2 $engine->translate($string)

Returns the translation of $string generated by interNOSTRUM.
$string must be a string of ANSI text, and can contain up to 16,384 characters.
If the source text isn't encoded as Latin-1, you must convert it to that encoding
before sending it to the machine translation engine. For this task you can use
the Encode module or the PerlIO layer, if you are reading the text from a file.

In case the server is down, it will show a warning and return C<undef>.


=head2 $engine->from_into($lang_pair)

Changes the engine language pair to $lang_pair.
When called with no argument, it returns the value of the current engine
language pair.

=head2 $engine->output_format($format)

Changes the engine output format to $format.
When called with no argument, it returns the value of the current engine
output format.

=head2 $engine->get_unknown($lang_code)

If the engine was configured to store unknown words, it returns a reference to
a hash containing the unknown words (keys) detected during the current machine
translation session for the specified source language, along with their
frequencies (values).

The valid values of $lang_code are:

=over 8

=item * C<< ca >>

Source language is Catalan or Valencian.

=item * C<< es >>

Source language is Spanish.

=back

=head1 DEPENDENCIES

WWW::Mechanize 1.20 or higher.

=head1 SEE ALSO

WWW::Translate::Apertium

=head1 REFERENCES

interNOSTRUM website:

L<http://www.internostrum.com/welcome.php>

Department of Software and Computing Systems (University of Alicante):

L<http://www.dlsi.ua.es/index.cgi?id=eng>

For more information on Catalan and its variants, see:

L<http://en.wikipedia.org/wiki/Catalan_language>


=head1 ACKNOWLEDGEMENTS

Many thanks to Mikel Forcada Zubizarreta, coordinator of the interNOSTRUM
project, who kindly answered my questions during the development of this module.


=head1 AUTHOR

Enrique Nell, C<< <blas.gordon at gmail.com> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-www-translate-internostrum at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Translate-interNOSTRUM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Translate::interNOSTRUM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Translate-interNOSTRUM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Translate-interNOSTRUM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Translate-interNOSTRUM>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Translate-interNOSTRUM/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2006-2014 Enrique Nell.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut



