use v5.36;

package Text::Redact::Secrets;

use Carp       qw(croak);
use Exporter   qw(import);
use List::Util qw(all any);
use POSIX      qw(log2);

use Text::Redact::Secrets::Rules::Dist;
use Text::Redact::Secrets::Rules::Gitleaks;

our $VERSION = 'v1.0.2';

our @EXPORT_OK = qw(find redact);

my $REDACTED = '*REDACTED*';

# A line holding this is passed over, as gitleaks passes it over.
my $ALLOW = 'gitleaks:allow';

# Return a copy of the string with each secret found replaced by
# *REDACTED*. Secrets that overlap, found by two rules, are replaced once.
sub redact ($string) {
    _check_string($string, 'redact');
    return _redact($string, _rules());
}


# Return a copy of the string with each secret the compiled rules find
# replaced by *REDACTED*.
sub _redact ($string, $compiled) {
    my $redacted = $string;
    my @spans;
    for my $found (_scan($string, $compiled)) {
        my($start, $end)
            = ($found->{offset}, $found->{offset} + length $found->{secret});
        next if $start == $end;
        if (@spans && $start < $spans[-1][1]) {
            $spans[-1][1] = $end if $end > $spans[-1][1];
        }
        else {
            push @spans, [$start, $end];
        }
    }
    for my $span (reverse @spans) {
        substr $redacted, $span->[0], $span->[1] - $span->[0], $REDACTED;
    }
    return $redacted;
}


# Return each secret found in the string, in the order it appears, as a
# hash of its rule's id, the secret and its offset.
sub find ($string) {
    _check_string($string, 'search');
    return map {
        +{rule => $_->{rule}, secret => $_->{secret}, offset => $_->{offset}}
    } _scan($string, _rules());
}


# Croak, at the caller's line, unless what's given is a string.
sub _check_string ($string, $verb) {
    croak "Expected a string to $verb" if !defined $string || ref $string;
    return;
}


# Return gitleaks' rules, then the module's own, and gitleaks' global
# allowlists, compiled the first time they're wanted.
sub _rules () {
    state $rules = _compile(
        [
            @{ Text::Redact::Secrets::Rules::Gitleaks::rules() },
            @{ Text::Redact::Secrets::Rules::Dist::rules() },
        ],
        Text::Redact::Secrets::Rules::Gitleaks::global_allowlists(),
    );
    return $rules;
}


# Return rules and global allowlists, as
# Text::Redact::Secrets::Rules::Gitleaks gives them, compiled for _scan:
# each regex with /a, keywords and stopwords lowercased, as gitleaks does
# when it loads them.
sub _compile ($rules, $globals) {
    my @compiled = map {
        +{
            id           => $_->{id},
            regex        => _regex($_->{regex}),
            entropy      => $_->{entropy}      // 0,
            secret_group => $_->{secret_group} // 0,
            keywords     => _keywords($_->{keywords}),
            allowlists   => [map { _compile_allowlist($_) } @{ $_->{allowlists} // [] }],
        }
    } @$rules;
    return {
        rules      => \@compiled,
        allowlists => [map { _compile_allowlist($_) } @$globals],
        _compile_keywords(map { @{ $_->{keywords} // [] } } @compiled),
    };
}


# Return a rule's keywords, lowercased, as gitleaks does when it loads
# them, or nothing if it has none, as a rule with none runs on every
# text.
sub _keywords ($keywords) {
    return undef unless $keywords && @$keywords;    ## no critic (Subroutines::ProhibitExplicitReturnUndef)
    return [map { lc } @$keywords];
}


# Return the regex that finds the keywords in a text, and the keywords
# each found stands for, as D4 says: one regex of every keyword, tried
# at every place in the text. Two keywords found at one place are a
# shorter and a longer, the shorter a prefix of the longer, and the
# regex, trying the longest first, finds only the longer, so each
# keyword stands for its prefixes too. So the keywords found are those
# in the text, as gitleaks finds them, overlapping ones too.
sub _compile_keywords (@keywords) {
    my %unique  = map  { $_ => 1 } @keywords;
    my @longest = sort { length $b <=> length $a } sort keys %unique;
    my %prefixes;
    for my $keyword (@longest) {
        $prefixes{$keyword}
            = [grep { $_ ne $keyword && index($keyword, $_) == 0 } @longest];
    }
    return (keywords => undef) unless @longest;
    my $any = join '|', map { quotemeta } @longest;
    return (keywords => qr( (?= ($any) ) )x, prefixes => \%prefixes);
}


# Return an allowlist compiled for _allowed: its regexes, and its
# stopwords, lowercased, as one regex that finds any of them, which Perl
# makes into one fast search, where looking for each in turn would cost
# as much as a rule.
sub _compile_allowlist ($allowlist) {
    my @stopwords = map { lc } @{ $allowlist->{stopwords} // [] };
    my $any       = join '|', map { quotemeta } @stopwords;
    return {
        and       => ($allowlist->{condition} // 'OR') eq 'AND',
        target    => $allowlist->{regex_target} // 'secret',
        regexes   => [map { _regex($_) } @{ $allowlist->{regexes} // [] }],
        stopwords => @stopwords ? qr( $any )x : undef,
    };
}


# Return one of gitleaks' regexes compiled as D3 says: with /a, as it's
# written. A literal { that isn't a quantifier is read by Perl as by Go's
# RE2, but Perl warns of it, so the warning is kept quiet.
sub _regex ($source) {
    no warnings qw(regexp);    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    return qr($source)a;       ## no critic (RegularExpressions::RequireExtendedFormatting)
}


# Return the secrets the compiled rules find in the text, as gitleaks'
# detector finds them in a string: each rule whose keywords are in the
# text, or that has none, run over it, and the findings of a generic rule
# that a specific rule's finding on the same line contains dropped. Each
# is a hash of the rule's id, the secret and its offset, in the order the
# secrets appear, then the rules' order.
sub _scan ($text, $compiled) {
    my %present;
    if (my $keywords = $compiled->{keywords}) {
        my $lower = lc $text;
        while ($lower =~ m( $keywords )xg) {
            $present{$_} = 1 for $1, @{ $compiled->{prefixes}{$1} };
        }
    }

    my @found;
    for my $rule (@{ $compiled->{rules} }) {
        next if $rule->{keywords} && !any { $present{$_} } @{ $rule->{keywords} };
        push @found, _scan_rule($text, $rule, $compiled->{allowlists});
    }
    # By offset, and those at the same offset in the rules' order.
    my %at;
    push @{ $at{$_->{offset}} }, $_ for _drop_generic(@found);
    return map { @{ $at{$_} } } sort { $a <=> $b } keys %at;
}


# Return the findings of one rule, as gitleaks' detectRule makes them.
sub _scan_rule ($text, $rule, $globals) {
    my $regex = $rule->{regex};
    my(@found, $newlines);
    while ($text =~ m( $regex )xg) {
        my $start = $-[0];
        my $match = substr $text, $start, $+[0] - $start;

        # gitleaks trims newlines from the match, and its line is found
        # from where the match starts, to where the match trimmed only of
        # its trailing newlines would end.
        my($leading) = $match =~ m( \A (\n*) )x;
        $match =~ s( \A \n+ | \n+ \z )()xg;
        $newlines //= _newlines($text);
        my $line = _line($text, $start, $start + length $match, $newlines);
        next if index($line, $ALLOW) >= 0;

        my($secret, $offset) = _secret($match, $rule) or next;
        $offset += $start + length $leading;
        next if $rule->{entropy} && _entropy($secret) <= $rule->{entropy};

        my %finding = (secret => $secret, match => $match, line => $line);
        next if any { _allowed($_, \%finding) } @$globals, @{ $rule->{allowlists} };

        push @found, {
            rule   => $rule->{id},
            secret => $secret,
            offset => $offset,
            line   => _line_number($newlines, $start),
        };
    }
    return @found;
}


# Return the secret in a match, and where it starts in the match, as D8
# says: gitleaks runs the rule's regex again, on the match alone, and
# takes the group the rule names, or else the first group that isn't
# empty, or else the whole match. Return nothing if the rule names a
# group its regex doesn't have, as gitleaks passes the match over.
sub _secret ($match, $rule) {
    my $regex   = $rule->{regex};
    my $matched = $match =~ m( $regex )x;
    return ($match, 0) if !$matched || $#+ < 1;
    my $groups = $#+;
    my $group  = $rule->{secret_group};
    if ($group) {
        return if $group > $groups;
        return
            defined $-[$group]
            ? (substr($match, $-[$group], $+[$group] - $-[$group]), $-[$group])
            : ('', 0);
    }
    for my $i (1 .. $groups) {
        next if !defined $-[$i] || $+[$i] == $-[$i];
        return substr($match, $-[$i], $+[$i] - $-[$i]), $-[$i];
    }
    return ($match, 0);
}


# Return where each newline in a text is.
sub _newlines ($text) {
    my @newlines;
    push @newlines, $-[0] while $text =~ m( \n )xg;
    return \@newlines;
}


# Return how many newlines come before an offset, so the line it's on,
# counting from 0.
sub _line_number ($newlines, $offset) {
    my($low, $high) = (0, scalar @$newlines);
    while ($low < $high) {
        my $middle = int(($low + $high) / 2);
        if   ($newlines->[$middle] < $offset) { $low  = $middle + 1 }
        else                                  { $high = $middle }
    }
    return $low;
}


# Return the line gitleaks checks a match's allowlists and
# gitleaks:allow against, as its location() finds it: from the newline
# before the match, or the start of the text, to the newline after it.
# A match after the last newline gets the text from its start.
# The newlines are where _newlines found them.
sub _line ($text, $start, $end, $found = _newlines($text)) {
    my $newlines = @$found ? $found : [length $text];

    # The newline after the match's start, if there is one.
    my $after = _line_number($newlines, $start + 1);
    my($from, $to);
    if ($after < @$newlines) {
        ($from, $to) = ($after ? $newlines->[$after - 1] : 0, $newlines->[$after]);

        # The newline at or after the match's end, if it ends after the
        # text's start.
        my $ends = _line_number($newlines, $end);
        $to = $newlines->[$ends] if $ends < @$newlines && $end > 0;
    }
    else {
        my($rest) = substr($text, $end) =~ m( \A ([^\r\n]*) )x;
        ($from, $to) = (0, $end + length $rest);
    }
    $to = $end if $end > $to;
    return substr $text, $from, $to - $from;
}


# Return the Shannon entropy of a string, in bits, over its characters,
# as gitleaks reckons it (D5).
sub _entropy ($string) {
    my $length = length $string or return 0;
    my %count;
    $count{substr $string, $_, 1}++ for 0 .. $length - 1;
    my $entropy = 0;
    for my $count (values %count) {
        my $frequency = $count / $length;
        $entropy -= $frequency * log2($frequency);
    }
    return $entropy;
}


# Return true if an allowlist passes over a finding, as gitleaks'
# checkFindingAllowed decides: its regexes are matched against what its
# target says, and its stopwords looked for in the secret, lowercased;
# under AND, both must, where it has them, and under OR, either.
sub _allowed ($allowlist, $finding) {
    my $target = $finding->{$allowlist->{target}};
    my $regex  = $target ne '' && any { $target =~ $_ } @{ $allowlist->{regexes} };
    my $secret = lc $finding->{secret};
    my $stop
        = $secret ne ''
        && $allowlist->{stopwords}
        && $secret =~ $allowlist->{stopwords};
    return $regex || $stop unless $allowlist->{and};

    # Under AND, each that it has, as gitleaks' allTrue.
    my @checks;
    push @checks, $regex if @{ $allowlist->{regexes} };
    push @checks, $stop  if $allowlist->{stopwords};
    return all { $_ } @checks;
}


# Return the findings but those of a generic rule that a specific rule's
# finding, starting on the same line, contains, as gitleaks' filter drops
# them. The specific rules' findings are looked up by their line, so that
# each generic finding is checked against only those on its own line.
sub _drop_generic (@found) {
    my %specific;
    for my $finding (@found) {
        push @{ $specific{$finding->{line}} }, $finding unless _generic($finding);
    }
    my @kept;
    for my $finding (@found) {
        next
            if _generic($finding)
            && any { index($_->{secret}, $finding->{secret}) >= 0 }
            @{ $specific{$finding->{line}} // [] };
        push @kept, $finding;
    }
    return @kept;
}


# Return true if a finding is by a generic rule.
sub _generic ($finding) {
    return index(lc $finding->{rule}, 'generic') >= 0;
}


1;

__END__

=encoding utf8

=for stopwords gitleaks gitleaks' allowlist allowlists regexes LICENSE-gitleaks

=head1 NAME

Text::Redact::Secrets - find secrets in text by gitleaks' rules, and redact them

=head1 SYNOPSIS

    use Text::Redact::Secrets qw(find redact);

    # The text with each secret in it replaced by *REDACTED*.
    print {$log} redact($text);

    # Each secret in the text, with the rule that found it.
    for my $found (find($text)) {
        say "$found->{rule} at $found->{offset}";
    }

=head1 DESCRIPTION

Text that might hold a secret, such as a dump written to a log, should
be safe to write. Text::Redact::Secrets finds the secrets in a string
by gitleaks' rules: a maintained set of regexes, keywords, entropies
and allowlists, carried over from gitleaks with their meaning
unchanged. C<redact> puts
C<*REDACTED*> in place of each, and C<find> reports each, with the rule
that found it.

gitleaks' rules are in L<Text::Redact::Secrets::Rules::Gitleaks>, which
names the gitleaks tag and commit they came from. gitleaks is
L<https://github.com/gitleaks/gitleaks>, copyright (c) 2019 Zachary
Rice, under the MIT licence.

Beside gitleaks' rules are some of the module's own, for secrets
gitleaks has no rule for, such as a password in a URL, in
L<Text::Redact::Secrets::Rules::Dist>, which says what each finds.

Nothing is exported unless asked for.

=head1 FUNCTIONS

=head2 redact

    my $safe = redact($text);

Returns a copy of C<$text> with each secret found in it replaced by
C<*REDACTED*>. C<$text> itself is left as it was. Where two rules find
secrets that overlap, the text they cover between them is replaced
once.

=head2 find

    my @found = find($text);

Returns each secret found in C<$text>, in the order it appears, as a
hash reference:

=over

=item C<rule>

The id of the rule that found it: one of gitleaks', such as
C<aws-access-token>, or one of the module's own, such as
C<url-userinfo-password>.

=item C<secret>

The secret, as the rule picks it out of what it matched.

=item C<offset>

Where the secret starts in C<$text>, counting from 0.

=back

Returns an empty list if there are none.

Two rules can find secrets that overlap, and each is reported.

=head1 WHAT IT WON'T FIND

It finds what its rules describe, and nothing else, so redacted text
can still hold a secret. Most rules find a kind of secret by its
shape, such as an AWS access key id or a private key. The rest, most of
all C<generic-api-key>, find a value given to a name such as
C<password> or C<api_key>, but only one long enough and random enough:
a short or ordinary password, or one with a word in it, isn't found.

gitleaks' command line also decodes base64, hex and percent-encoded
text, and looks for secrets in what it decodes. This module looks only
at the text as it is, so it doesn't find a secret that's been encoded.
Nor does it use gitleaks' rules that look at a file's name, as it
sees only text.

It takes time in step with the text for nearly every rule: about
8 milliseconds for a dump of a few hundred rows, on a laptop. A few rules take longer
on a long run of letters and digits with no space in it, tens of
thousands of characters, such as a long hex string, if the text also
holds the rule's keyword: up to about a fifth of a second for
40,000 characters, on a laptop.

=head1 KEEPING THE RULES CURRENT

gitleaks' rules come from one of its releases, which
L<Text::Redact::Secrets::Rules::Gitleaks> names. To see which:

    perl -MText::Redact::Secrets::Rules::Gitleaks \
        -E 'say Text::Redact::Secrets::Rules::Gitleaks::gitleaks_tag()'

The rules can't be updated where the module is installed. Each set is
carried over from a gitleaks release by the distribution's maintainer,
tested, and released as a new version of the module, so that what's
installed is always a set that was tested together. A version that
brings new rules moves the middle number, as from v1.0.0 to v1.1.0; a
fix moves the last; and a change to what C<redact> or C<find> take or
return moves the first. To have the newest rules, install the module
again, which brings the newest version:

    cpanm Text::Redact::Secrets

=head1 DIAGNOSTICS

=over

=item Expected a string to redact

C<redact> was given C<undef> or a reference.

=item Expected a string to search

C<find> was given C<undef> or a reference.

=back

=head1 SEE ALSO

L<gitleaks|https://github.com/gitleaks/gitleaks>, whose rules these
are, and L<Text::Redact::Secrets::Rules::Dist>, the module's own.

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself, except for
gitleaks' rules, in L<Text::Redact::Secrets::Rules::Gitleaks>, which
are under gitleaks' MIT licence, in F<LICENSE-gitleaks>.

=cut
