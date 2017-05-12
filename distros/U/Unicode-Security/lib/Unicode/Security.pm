package Unicode::Security;

use 5.008;
use strict;
use warnings;
use Exporter qw(import);

use Unicode::Security::Confusables;
use Unicode::Normalize qw(NFD);
use Unicode::UCD qw(charinfo charscript);

our $VERSION = '0.08';
$VERSION = eval $VERSION;

our @EXPORT_OK = qw(
    skeleton confusable soss restriction_level mixed_script
    mixed_number mixed_num
    whole_script_confusable mixed_script_confusable
    ws_confusable ms_confusable
);

our (%MA, %WS);

use constant {
    UNRESTRICTED           => 0,
    ASCII_ONLY             => 1,
    SINGLE_SCRIPT          => 2,
    HIGHLY_RESTRICTIVE     => 3,
    MODERATELY_RESTRICTIVE => 4,
    MINIMALLY_RESTRICTIVE  => 5,
};

my %recommended_script = map { $_ => \1 } qw(
    Common Inherited Arabic Armenian Bengali Bopomofo Cyrillic Devanagari
    Ethiopic Georgian Greek Gujarati Gurmukhi Han Hangul Hebrew Hiragana
    Kannada Katakana Khmer Lao Latin Malayalam Myanmar Oriya Sinhala Tamil
    Telugu Thaana Thai Tibetan
);

my %aspirational_script = map { $_ => \1 } qw(
    Canadian_Aboriginal Miao Mongolian Tifinagh Yi
);

my %highly_restrictive = map { $_ => \1 } (
    '', 'Hiragana', 'Katakana', 'Hiragana, Katakana', 'Bopomofo', 'Hangul',
);


sub skeleton {
    my $str = NFD shift;
    my $m = $str =~ s{(.)}{ my $c = $MA{$1}; defined $c ? $c : $1 }eg;
    return $m ? NFD $str : $str;
}


sub confusable {
    return skeleton($_[0]) eq skeleton($_[1]);
}


# Algorithm described here:
#   http://www.unicode.org/reports/tr39/#Whole_Script_Confusables
sub whole_script_confusable {
    my ($target, $str) = @_;

    # Canonicalize the script name to match the format used in %WS.
    $target = ucfirst lc $target;

    my %soss = soss(NFD $str);
    delete @soss{qw(Common Inherited)};

    my $count = keys %soss or return '';
    return if 1 < $count;
    my ($source) = keys %soss;

    my $chars = $WS{$source}{$target};
    do { return 1 if $chars->{$_} } for keys %{ $soss{$source} };
}
*ws_confusable = *ws_confusable = \&whole_script_confusable;


# Algorithm described here:
#   http://www.unicode.org/reports/tr39/#Mixed_Script_Confusables
sub mixed_script_confusable {
    my %soss = soss(NFD $_[0]);
    delete @soss{qw(Common Inherited)};

    my @soss = keys %soss;
    for my $source (@soss) {
        my $sum = 0;
        for my $target (@soss) {
            next if $target eq $source;

            my $nok = 0;
            my $chars = $WS{$target}{$source};
            for my $char (keys %{ $soss{$target} }) {
                $nok = 1, last unless $chars->{$char};
            }
            last if $nok;
            $sum++;
        }

        return 1 if 1 == @soss - $sum;
    }

    return '';
}
*ms_confusable = *ms_confusable = \&mixed_script_confusable;


sub soss {
    my %soss;
    for my $char (split //, $_[0]) {
        my $script = charscript(ord($char));
        $script = 'Unknown' unless defined $script;
        $soss{$script}{$char} = \1;
    }
    return %soss;
}


sub mixed_script {
    my %soss = soss($_[0]);
    delete @soss{qw(Common Inherited)};
    return 1 < keys %soss;
}


sub mixed_number {
    my %z;
    for my $char (split //, $_[0]) {
        my $info = charinfo(ord $char) or next;

        my $num = $info->{decimal};
        next unless length $num;

        $z{ ord($char) - $num } = \1;
    }

    return 1 < keys %z;
}
*mixed_num = *mixed_num = \&mixed_number;


# Algorithm described here:
#   http://www.unicode.org/reports/tr39/#Restriction_Level_Detection
sub restriction_level {
    my ($str, $non_id_regex) = @_;

    $non_id_regex = qr/\P{ID_Continue}/ unless defined $non_id_regex;

    return UNRESTRICTED if $str =~ /$non_id_regex/;
    return ASCII_ONLY   if $str !~ /\P{ASCII}/;

    my %soss = soss($str);
    delete @soss{qw(Common Inherited)};
    return SINGLE_SCRIPT if 1 == keys %soss;

    delete $soss{Latin};
    my %copy = %soss;
    delete $copy{Han};
    my $soss = join ', ', sort keys %copy;
    return HIGHLY_RESTRICTIVE if $highly_restrictive{$soss};

    if (1 == keys %soss) {
        my ($script) = keys %soss;
        return MODERATELY_RESTRICTIVE
            if ($recommended_script{$script} or $aspirational_script{$script})
                and not ($soss{Cyrillic} or $soss{Greek});

    }

    return MINIMALLY_RESTRICTIVE;
}


1;

__END__

=head1 NAME

Unicode::Security - Unicode security mechanisms

=head1 SYNOPSIS

    use Unicode::Security qw(
        confusable restriction_level whole_script_confusable
        mixed_script_confusable mixed_script mixed_number
    );

    $truth = confusable($string1, $string2);
    $truth = whole_script_confusable($script, $string);
    $truth = mixed_script_confusable($string);
    $truth = mixed_script($string);
    $truth = mixed_number($string);
    $level = restriction_level($string);

=head1 DESCRIPTION

Implements the Unicode security mechanisms as described in the Unicode
Technical Standard #39.

=head1 FUNCTIONS

=head2 confusable

    $truth = confusable($string1,  $string2)

Returns true if the two strings are visually confusable.

=head2 whole_script_confusable

=head2 ws_confusable

    $truth = whole_script_confusable($script, $string)

Returns true if the string is whole-script confusable within the given script.
Returns undef if the string contains multiple scripts.

=head2 mixed_script_confusable

=head2 ms_confusable

    $truth = mixed_script_confusable($string)

Returns true if the string is mixed-script confusable.

=head2 skeleton

    $skel = skeleton($string)

The skeleton transform is used internally by the confusable algorithm. The
result is not intended for display, storage or transmission. It should be
thought of as an intermediate processing form, similar to a hashcode. The
characters in the skeleton are not guaranteed to be identifier characters.

=head2 restriction_level

    $level = restriction_level($string [, $non_id_regex])

Returns the restriction level (0-5) of the string. The default Identifier
Profile matches against B<\P{ID_Continue}>. If you want to use a different
Identifier Profile, you can pass in an optional regular expression to test for
non-identifier characters.

=head2 soss

    %soss = soss($string)

The set of Unicode character script names for a given string. Used internally
by the restriction level algorithm.

=head2 mixed_script

    $truth = mixed_script($string)

Returns true if the string contains mixed scripts.

=head2 mixed_number

=head2 mixed_num

    $truth = mixed_number($string)

Returns true if the string is composed of characters from different decimal
number systems.

=head1 SEE ALSO

L<http://www.unicode.org/reports/tr39/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Unicode-Security>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Unicode::Security

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/unicode-security>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Unicode-Security>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Unicode-Security>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Unicode-Security>

=item * Search CPAN

L<http://search.cpan.org/dist/Unicode-Security/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
