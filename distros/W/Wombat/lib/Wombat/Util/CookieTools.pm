# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Util::CookieTools;

use strict;
use warnings;

use HTTP::Date ();

sub getCookieHeaderName {
    my $class = shift;
    my $cookie = shift;

    return $cookie->getVersion() == 1 ? 'Set-Cookie2' : 'Set-Cookie';
}

sub getCookieHeaderValue {
    my $class = shift;
    my $cookie = shift;

    my @words;
    push @words, join '=', $cookie->getName(), $cookie->getValue();

    my $version = $cookie->getVersion();

    my $path = $cookie->getPath();
    push @words, join '=', 'path', maybeQuote($path, $version) if $path;

    my $domain = $cookie->getDomain();
    push @words, join '=', 'domain', maybeQuote($domain, $version) if $domain;

    push @words, 'secure' if $cookie->getSecure();

    my $maxage = $cookie->getMaxAge();
    if ($maxage >= 0) {
        if ($version == 0) {
            push @words, join '=', 'expires', HTTP::Date::time2isoz($maxage);
        } else {
            push @words, join '=', 'max-age', $maxage;
        }
    } elsif ($version == 1) {
        push @words, 'discard';
    }

    if ($version == 1) {
        push @words, join '=', 'version', $version;

        my $comment = $cookie->getComment();
        push @words, join '=', 'comment', maybeQuote($version, $comment) if
            $comment;
    }

    return join '; ', @words;
}

sub maybeQuote {
    my $str = shift or
        return '';

    # don't quote values for version 0
    my $ver = shift or
        return $str;

    # don't quote HTTP/1.1 tokens as defined in RFC 2068
    return $str =~ /(["()<>@,;:\/[]?={} \t]|\x20-\x7f)/ ?
        qq("$str") :
            $str;
}

1;
__END__
