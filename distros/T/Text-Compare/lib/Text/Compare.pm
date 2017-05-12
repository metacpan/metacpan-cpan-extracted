########################################################################
#  
#    Text::Compare
#
#    Copyright 2005, Marcus Thiesen (marcus@thiesen.org)  All rights reserved.
#              2007, Serguei Trouchelle (stro@railways.dp.ua)
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of either:
#
#    a) the GNU General Public License as published by the Free Software
#    Foundation; either version 1, or (at your option) any later
#       version, or
#
#    b) the "Artistic License" which comes with Perl.
#
#    On Debian GNU/Linux systems, the complete text of the GNU General
#    Public License can be found in `/usr/share/common-licenses/GPL' and
#    the Artistic Licence in `/usr/share/common-licenses/Artistic'.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
#
########################################################################

# 2007/06/22 stro v1.02
#                 Fixed bug 15329 (https://rt.cpan.org/Ticket/Display.html?id=15329)
#                 Fixed bug 21587 (https://rt.cpan.org/Ticket/Display.html?id=21587)
#                 Fixed bug 21588 (https://rt.cpan.org/Ticket/Display.html?id=21588)
#

# 2007/06/23 stro v1.03
#                 Fixed POD
#                 License added to meta.yml

package Text::Compare;

=pod

=head1 NAME

Text::Compare - Language sensitive text comparison

=head1 SYNOPSIS

    use Text::Compare;
    # the instant way:
    my $tc = new Text::Compare( memoize => 1, strip_html => 0 );

    my $sim = $tc->similarity($text_a, $text_b);
    #$sim will be between 0 and 1

    # second way (cache lists):
    my $tc2 = new Text::Compare( strip_html => 1 );

    # make a language sensitive word hash:
    my %wordhash = $tc2->get_words($some_text);

    $tc2->first_list(\%wordhash);

    foreach my $list (@wordlists) {
       #list is a hashref
       $tc2->second_list($list);

       print $tc2->similarity();
    }

    # third way (cache texts) 
    my $tc3 = new Text::Compare();

    $tc3->first($some_text);
    $tc3->second($some_other_text);

    print $tc3->similarity;
     


=head1 DESCRIPTION

Text::Compare is an attempt to write a high speed text compare tool
based on Vector comparision which uses language dependend stopwords.
Text::Compare uses Lingua::Identify to find the language of the
given texts, then uses Lingua::StopWords to get the stopwords for the
given language and finally uses Linuga::Stem to find word stems. 

=cut 

use strict;
use warnings;

use Lingua::Identify qw(:language_identification :language_manipulation);
use Lingua::StopWords;
use Lingua::Stem;

use Sparse::Vector;

use Carp;

our $VERSION = '1.03';

=head1 METHODS

=over

=item new( memoize => <boolean>, strip_html => <boolean> )

Creates a new Text::Compare object. Per default, Text::Compare
usese memoize to cache some of the calls. See L<Memoize> for 
details. If you don't want that to happen, initialize it with memoize
=> 0. Furthermore, Text::Compare uses HTML::Strip to stip off the HTML
found in the text. If you are sure that you don't have any HTML in
your data or simply want to use it, deactivate it with strip_html =>
0.

=cut 

sub new {
    my $class = shift;
    my @args = @_;

    my $self = {
	'word_count' =>  0,
	'word_index' => {},
	'word_list'  => [],
	'list'       => [],
	'cache'      => {},
	'memoize'    =>  0,
	'strip_html' =>  1,
	'first'      => {},
	'second'     => {},

	@args,

    };
    $self = bless $self, $class;

    deactivate_all_languages();
    activate_language('da');
    activate_language('de');
    activate_language('en');
    activate_language('fr');
    activate_language('it');
    activate_language('no');
    activate_language('pt');
    activate_language('sv');

    if ($self->{'memoize'}) {
	require Memoize;
	import  Memoize;
	memoize('get_words');
	memoize('langof');
	memoize('Lingua::Stem::stem');
    }

    if ($self->{'strip_html'}) {
	require HTML::Strip;
    }

    return $self;
}

=item similarity($text_a, $text_b) 

Compares both texts and returns a similarity value between 0 and
1. Text::Compare does all this language magic, therefore two texts
which address the same topic but are in different languages might get
relatively high values. 

=cut

sub similarity {
    my $self = shift;
    my $first = shift;
    my $second = shift;

    $self->first($first) if defined $first;
    $self->second($second) if defined $second;

    $self->make_word_list();
    my $v1 = $self->make_vector( shift @{$self->{'list'}} );
    my $v2 = $self->make_vector( shift @{$self->{'list'}} );

    return $self->cosine( $v1, $v2 );
}

=item first

=cut

sub first {
    my $self = shift;
    my $first = shift;

    $self->first_list($self->get_words($first));
}

=item first_list

=cut

sub first_list {
    my $self = shift;
    my $list = shift;

    $self->{'first'} = $list if ($list);
    return $self->{'first'};
}

=item second

=cut

sub second {
    my $self = shift;
    my $second = shift;

    $self->second_list($self->get_words($second));
}

=item second_list

=cut

sub second_list {
    my $self = shift;
    my $list = shift;

    $self->{'second'} = $list if ($list);
    return $self->{'second'};
}

=item cosine

=cut

sub cosine {
    my $self = shift;

    my ( $vec1, $vec2 ) = @_;

    $vec1->normalize;
    $vec2->normalize;
    return $vec1->dot( $vec2 );    # inner product
}

=item make_vector

=cut

sub make_vector {
    my $self = shift;
    my $href = shift;
    my %words = %$href;
    my $vector = new Sparse::Vector;

    while (my ($w,$value) = each %words ) {
	next unless defined $self->{'word_index'}->{$w};
	$vector->set($self->{'word_index'}->{$w}, $value);
    }

    return $vector;
}

=item make_word_list

=cut

sub make_word_list {
    my $self = shift;
    my %all_words;

    $self->{'list'} = [];

    my %words1 = %{$self->{'first'}};
    push @{$self->{'list'}}, \%words1;
    %all_words = %words1;

    my %words2 = %{$self->{'second'}};

    push @{$self->{'list'}}, \%words2;
    foreach my $k ( keys %words2 ) {
	$all_words{$k} += $words2{$k};
    }

    # create a lookup hash of word to position
    my %lookup;
    my @sorted_words = sort keys %all_words;
    @lookup{@sorted_words} = (1..$#sorted_words );
    
    $self->{'word_index'} = \%lookup;
    $self->{'word_list'}  = \@sorted_words;
    $self->{'word_count'} = scalar @sorted_words;
}

=item get_words

=cut

sub get_words {
    my $self = shift;
    my $text = shift || carp "Need Text as an argument to get_words\n";

    if ($self->{'strip_html'}) {
	my $hs = HTML::Strip->new();
	$text = $hs->parse($text);
	$hs->eof;
    }

    my $lang = langof( $text );

    my $stopwords = Lingua::StopWords::getStopWords(lc($lang ? $lang : 'en'));
    my $stemmer = Lingua::Stem->new(-locale => uc($lang ? $lang : 'en'));

    return { map { $_ => 1 }
	   grep { ! exists $$stopwords{$_} }
           map { $stemmer->stem( $_ )->[0] }
           map { lc $_ }
           map { /([a-zA-Z\-']+)/ } 
           split /\s+/s, $text };
}

1;

=back

=head1 LANGUAGES 

Text::Compare uses the set of languages which is common to
Lingua::Identify, Lingua::Stem and Lingua::StopWords, namely:

=over 4

=item da

=item de

=item en

=item fr

=item it

=item no

=item pt

=item sv

=back 

=head1 AUTHORS

Marcus Thiesen, C<< <marcus@thiesen.org> >>

Serguei Trouchelle C<< <stro@railways.dp.ua> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-text-compare@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-Compare>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The actual code is heavilly based on Search::VectorSpace by 
Maciej Ceglowski.

=head1 COPYRIGHT

Copyright 2005 Marcus Thiesen, All Rights Reserved.

Copyright 2007 Serguei Trouchelle

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

