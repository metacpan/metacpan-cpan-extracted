package Text::Clevery::Modifier;
use strict;
use warnings;

use parent qw(Text::Xslate::Bridge);

use List::Util qw(min);

use Text::Xslate::Util qw(
    p
    mark_raw
    html_escape
    uri_escape
);

use Text::Clevery::Util qw(
    safe_join
    safe_cat
    true false
);

require Text::Clevery;
our $EngineClass = 'Text::Clevery';

my %modifier = map { $_ => __PACKAGE__->can($_) || die $_ } qw(
    capitalize
    cat
    count_characters
    count_paragraphs
    count_sentences
    count_words
    date_format
    default
    escape
    indent
    lower
    nl2br
    regex_replace
    replace
    spacify
    string_format
    strip
    strip_tags
    truncate
    upper
    wordwrap
);
__PACKAGE__->bridge(function => \%modifier);

sub capitalize {
    my($str, $number_as_word) = @_;
    my $word = $number_as_word
        ? qr/\b ([[:alpha:]]\w*) \b/xms
        : qr/\b ([[:alpha:]]+)   \b/xms;

    $str =~ s/$word/ ucfirst($1) /xmseg;
    return $str;
}

sub cat {
    return safe_cat(@_);
}

sub count_characters {
    my($str, $count_whitespaces) = @_;
    if(!$count_whitespaces) {
        $str =~ s/\s+//g;
    }
    return length($str);
}

sub count_paragraphs {
    my($str) = @_;
    return scalar $str =~ s/([\r\n]+)/$1/xmsg;
}

sub count_sentences {
    my($str) = @_;
    return scalar $str =~ s/(\S \.) (?!\w)/$1/xmsg;
}

sub count_words {
    my($str) = @_;
    return scalar $str =~ s/(\S+)/$1/xmsg;
}

sub date_format {
    my($time, $format, $default) = @_;
    require Time::Piece;
    return $time
        ? Time::Piece->new($time)->strftime($format)
        : $default;
}

sub default {
    my($value, $default) = @_;
    return defined($value) && length($value)
        ? $value
        : $default;
}

# See smarty3/libs/plugins/modifier.escape.php

sub escape {
    my($str, $format, $encoding) = @_;
    $format   ||= 'html';
    $encoding ||= 'ISO-8859-1';

    if($format eq 'html') {
        return html_escape($str);
    }
    elsif($format eq 'htmlall') {
        require HTML::Entities;
        $str = HTML::Entities::encode($str);
    }
    elsif($format =~ /\A ur [il] ( pathinfo )? \z/xms) {
        $str = uri_escape($str);
        if($1) { # ur[il]pathinfo
            $str =~ s{%2F}{/}g;
        }
    }
    elsif($format eq 'quotes') {
        # escapes single quotes and back slashes
        $str =~ s{ ( [\\'] ) }{\\$1}xmsg; # '
    }
    elsif($format eq 'hex') {
        use bytes;
        $str =~ s{ (.) }{ '%' . unpack('H*', $1) }xmsge;
    }
    elsif($format eq 'hexentity') {
        $str =~ s{ (.) }{ '&#x' . unpack('H*', $1) . ';' }xmsge;
    }
    elsif($format eq 'decentity') {
        $str =~ s{ (.) }{ '&#' . ord($1) . ';' }xmsge;
    }
    elsif($format eq 'javascript') {
        my %map = (
            q{\\}  => q{\\\\},
            q{'}   => q{\\'},
            q{"}   => q{\\"},
            qq{\r} => q{\r},
            qq{\n} => q{\n},
            q{</}  => q{<\/},
        );
        my $pat = join '|', map { quotemeta } keys %map;
        $str =~ s/($pat)/$map{$1}/xmsge;
    }
    elsif($format eq 'mail') {
        $str =~ s/\@/ [AT] /g;
        $str =~ s/\./ [DOT] /g;
    }
    elsif($format eq 'nonstd') {
        use bytes;
        $str =~ s/([^\x00-\x7d])/'&#' . ord($1) . ';'/xmsge;
        $str = mark_raw($str);
    }
    else {
        warnings::warnif(misc => "Unknown escape format '$format' used");
    }
    return mark_raw($str);
}

sub indent {
    my($str, $count, $padding) = @_;
    $count   = 4   if not defined $count;
    $padding = ' ' if not defined $padding;

    $padding x= $count;
    $str =~ s/^/$padding/xmsg;
    return $str;
}

sub lower {
    my($str) = @_;
    return lc($str);
}

sub nl2br {
    my($str) = @_;
    return safe_join mark_raw("<br />"),
        split /\n/, $str, -1;
}

sub regex_replace {
    my($str, $pattern, $replace) = @_;
    $str =~ s/$pattern/$replace/msg;
    return $str;
}

sub replace {
    my($str, $pattern, $replace) = @_;
    $str =~ s/\Q$pattern\E/$replace/msg;
    return $str;
}

sub spacify {
    my($str, $padding) = @_;
    $padding = ' ' if not defined $padding;
    return safe_join $padding, split //, $str;
}

sub string_format {
    my($str, $format) = @_;
    return sprintf $format, $str;
}

sub strip {
    my($str, $space) = @_;
    $space = ' ' if not defined $space;
    $str =~ s/\s+/$space/g;
    return $str;
}

sub strip_tags {
    my($str, $replace_with_space) = @_;
    $replace_with_space = 1 if not defined $replace_with_space;
    my $replace = $replace_with_space ? ' ' : '';
    $str =~ s{ < [^>]* > }{$replace}xmsg;
    return $str;
}

sub truncate {
    my($str, $length, $etc, $break_words, $middle) = @_;
    $length = 80    if not defined $length;
    $etc    = '...' if not defined $etc;

    if(length($str) <= $length) {
        return $str;
    }

    $length -= min($length, length($etc));

    if (!$middle) {
        if(!$break_words) {
            $str = substr($str, 0, $length + 1);
            $str =~ s/ \s+? (\S+)? \z//xmsg;
        }
        return substr($str, 0, $length) . $etc;
    } else {
        return substr($str, 0, $length / 2) . $etc . substr($str, - $length / 2);
    }
}

sub upper {
    my($str) = @_;
    return uc($str);
}

sub wordwrap {
    my($str, $length, $break, $cut) = @_;
    $length = 80   if not defined $length;
    $break  = "\n" if not defined $break;

    if(!$cut) {
        my @lines;
        my $line = '';
        foreach my $word(split /(\s+)/, $str) {
            if(length($line) + length($word) > $length
                    && $word =~ /\S/) {
                $line =~ s/ \s+ \z//xms; # chomp the last spaces
                push @lines, $line;
                $line = $word;
            }
            else {
                $line .= $word;
            }
        }

        if(length($line) > 0) {
            $line =~ s/ \s+ \z//xms; # chomp the last spaces
            push @lines, $line;
        }

        return safe_join($break, @lines);
    }
    else { # force wrapping mode
        $length--; # What's it???
        $str =~ s/(.{$length})/$1$break/xmsg;
    }

    return $str;
}

1;
__END__

=head1 NAME

Text::Clevery::Modifier - Smarty compatible expression modifiers

=head1 MODIFIER

=head2 capitalize

=head2 cat

=head2 count_characters

=head2 count_paragraphs

=head2 count_sentences

=head2 count_words

=head2 date_format

=head2 default

=head2 escape

=head2 indent

=head2 lower

=head2 nl2br

=head2 regex_replace

=head2 replace

=head2 spacify

=head2 string_format

=head2 strip

=head2 strip_tags

=head2 truncate

=head2 upper

=head2 wordwrap

=head1 SEE ALSO

L<Text::Clevery>

=cut

