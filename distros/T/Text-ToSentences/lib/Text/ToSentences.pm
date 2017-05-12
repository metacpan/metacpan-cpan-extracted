package Text::ToSentences;

use 5.008008;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Text::ToSentences ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'test' => [ qw(
    convert
    _isNotSentenceStart
    _correctSpacesAndFormat
    _isAcronym
    _isSentenceEnd
    _isBlockOpening
    _removeBlockDelimiters
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'test'} } );
# our @EXPORT_OK = ( );

# our @EXPORT = qw(
# 	convert
#     _isNotSentenceStart
#     _correctDotsAndSpaces
# );

our $VERSION = '0.91';

our %blockDelimiters = ("(" => ")",
                        "[" => "]");

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.



1;
__END__

=head1 NAME

Text::ToSentences - Perl extension for converting pieces of text into individual sentences.

=head1 SYNOPSIS

  use Text::ToSentences;
  @sentences = @{Text::ToSentences::convert($text)};

=head1 DESCRIPTION

Extract sentences from a given piece of text. It is aware of acronyms and parenthesis (including some mistakes as not closing or not opening ones)


=head2 EXPORT

convert

=head1 AUTHOR

Alberto Montero, E<lt>alberto.montero.asenjo@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Alberto Montero

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

=item convert

Split the given piece of text in sentences.

=cut 
sub convert($) {
    my $text = shift;
    chomp($text);
    $text = _correctSpacesAndFormat($text);
    my $textForProcessing = _putSpacesAroundBlockDelimiters($text);

    my @sentencesToReturn;

    my @initialWords = split /\s+/, $textForProcessing;
    my @words;
    foreach my $initialWord (@initialWords) {
        my @possibleWords = split(/\./, $initialWord);
        if ((@possibleWords <= 1) || 
            (@possibleWords == 2 && $possibleWords[-1] eq "") ||
            (_isAcronym($initialWord))) {
            push(@words, $initialWord);
        } else {
            my @wordsToAdd = map { "$_." } @possibleWords;
            chop($wordsToAdd[-1]) unless $initialWord =~ /\.$/;
            push(@words, @wordsToAdd);
        }
    }

    my $currentSentece;
    my @pendingSentences;
    while (@words) {
        my $currentWord = shift @words;
        if (_isBlockOpening($currentWord)) {
            my @blockWords = @{_getWordsUpToBlockClosing(\@words, 
                                                         $currentWord)};
            push(@pendingSentences, @{convert(join(" ", @blockWords))});
        } else {
            $currentSentece .= " ".$currentWord if $currentWord;
        }
        my $nextWord = @words ? $words[0] : "";

        if (_isSentenceEnd($currentWord)){# || _isSentenceStart($nextWord)) {
            push(@sentencesToReturn, 
                 _correctSpacesAndFormat(_removeBlockDelimiters($currentSentece)));
            push(@sentencesToReturn, @pendingSentences);
            $currentSentece = "";
            @pendingSentences = ();
        }
    }

    push(@sentencesToReturn,  
         _correctSpacesAndFormat(_removeBlockDelimiters($currentSentece)))
        if $currentSentece;

    return \@sentencesToReturn;
}

sub _isBlockOpening($) {
    my $text = shift;

    my $result = 0;
    $result ||= $text eq $_ foreach (keys %blockDelimiters);

    return $result;
}

sub _getWordsUpToBlockClosing {
    my $words = shift;
    my $blockStart = shift;

    my $blockEnd = $blockDelimiters{$blockStart};

    my $nExpectedBlockEnds = 1; 

    my @wordsUpToBlockClosing;
    while (@{$words}) {
        my $currentWord = shift @{$words};
        push(@wordsUpToBlockClosing, $currentWord);
        if ($currentWord eq $blockStart) {
            $nExpectedBlockEnds++;
        } elsif ($currentWord eq $blockEnd) {
            if ($nExpectedBlockEnds == 1) {
                pop @wordsUpToBlockClosing;
                last;
            } else {
                $nExpectedBlockEnds--;
            }
        }
    }
    return \@wordsUpToBlockClosing;
}

=item _putSpacesAroundBlockDelimiters

Put spaces around parenthesis and similar characters

=cut 
sub _putSpacesAroundBlockDelimiters($) {
    my $text = shift;
    $text =~ s/\s*\(\s*/ ( /g;
    $text =~ s/\s*\)\s*/ ) /g;
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;
    return $text;
}

sub _removeBlockDelimiters($) {
    my $sentence = shift;
    foreach (%blockDelimiters) {
        my $re = "\\$_";
        $sentence =~ s/$re//g;
    }
    return $sentence;
}

=item _correctDotsAndSpaces

Correct duplicated spaces and those incorrectly situated around dots

=cut 
sub _correctSpacesAndFormat($) {
    my $sentence = shift;
    $sentence =~ s/\s+/ /g;
    $sentence =~ s/\s+\.\s*/. /g;
    $sentence =~ s/\s+\,\s*/, /g;
    $sentence =~ s/\. ([A-Z]{2,})(\.| )/.$1./g;
    $sentence =~ s/\s*\(\s*/ (/g;
    $sentence =~ s/\s*\)\s*/) /g;
    $sentence =~ s/^\s*//;
    $sentence =~ s/\s*$//;
    if ($sentence =~ /^([a-z])/) {
        my $firstChar = uc($1);
        $sentence =~ s/^([a-z])/$firstChar/;
    }
    $sentence .= "." unless $sentence =~ /\.$/;
    return $sentence;
}

=item _isNotSentenceStart

Return true if the specified word is not a sentence start, according to usual tipographical rules (uppercase, lowercase, acronyms, ...)

=cut 
sub _isNotSentenceStart($) {
    my $word = shift;
    return ($word =~ /^\s*([A-Z]{2,}|[a-z]+)\b/);
}

sub _isSentenceStart($) {
    return !_isNotSentenceStart(@_);
}

=item _isAcronym

Return true if the specified word is an acronym.

=cut 
sub _isAcronym($) {
    my $word = shift;
    my $result = 1;

    $result &&= ($word =~ /^\s*([A-Z]+\.)+([A-Z]+\.?)?$/);

    return $result;
}

=item _isSentenceEnd

Return true if the specified word is a sentence end, according to tipographical rules.

=cut 
sub _isSentenceEnd($) {
    my $word = shift;
    my $lastChar = chop($word);
    return ($lastChar eq '!') || ($lastChar eq '?') || ($lastChar eq '.' && !_isAcronym("$word."));
}
