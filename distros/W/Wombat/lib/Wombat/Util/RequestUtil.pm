# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Util::RequestUtil;

use strict;
use warnings;

use Servlet::Http::Cookie ();
use Servlet::Http::HttpServlet ();
use URI::Escape ();
use Wombat::Globals ();

sub decodeURI {
    my $class = shift;
    my $uri = shift;

    $uri = $$uri if ref $uri;

    my $sessionID;
    my ($pre, $post) = split(Wombat::Globals::SESSION_PARAMETER_NAME, $uri);
    if (defined $post) {
        $pre =~ s/[;&]$//;
        $post =~ s/^=([^;&]+)[;&]?//;
        $sessionID = $1;

        my $uri;
        if ($post) {
            $uri = ($pre =~ /\?$/) ?
                join('', $pre, $post) :
                    join('&', $pre, $post);
        } else {
            $pre =~ s/\?$//;
            $uri = $pre;
        }
    }

    return $sessionID ?
        __PACKAGE__->unescapeURIPart($sessionID) :
            undef;
}

sub makeSessionCookie {
    my $class = shift;
    my $request = shift;

    my $application = $request->getApplication();
    return undef unless $application && $application->isSessionCookie();

    my $cookie;
    my $session = $request->getSession();
    if ($session && $session->isNew()) {
        my $name = Wombat::Globals::SESSION_COOKIE_NAME;
        my $value = $session->getId();
        $cookie = Servlet::Http::Cookie->new($name, $value);

        my $contextPath = $application->getPath() if $application;
        $contextPath ||= '/';
        $cookie->setPath($contextPath);
        $cookie->setMaxAge(-1);
        $cookie->setSecure($request->isSecure());

        # send cookie to the subdomain to which this host belongs
        my $domain = $request->getServerName();
        $domain =~ s|^[^.]+\.|.|;
        $cookie->setDomain($domain);
    }

    return $cookie;
}

sub parseCharacterEncoding {
    my $class = shift;
    my $hdr = shift;

    return '' unless $hdr;

    my $encoding;
    my ($primary, @attrs) = split /;\s*/, $hdr;
    for my $attr (@attrs) {
        my ($name, $value) = split /=/, $attr;
        next unless lc $name eq 'charset';

        $encoding = $value;
        last;
    }

    return $encoding;
}

sub parseContentType {
    my $class = shift;
    my $hdr = shift;

    return '' unless $hdr;

    my $encoding;
    my ($primary) = split /;\s*/, $hdr;

    return $primary;
}

sub parseCookies {
    my $class = shift;
    my $hdr = shift || '';

    my @list;
    for my $chunk (split /;\s*/, $hdr) {
        my ($key, $val) = split /=/, $chunk;

        $key = __PACKAGE__->unescapeURIPart($key);
        $val = __PACKAGE__->unescapeURIPart($val);

        my $cookie;
        eval {
            $cookie = Servlet::Http::Cookie->new($key, $val);
        };
        push @list, $cookie if $cookie;
    }

    return wantarray ? @list : \@list;
}

sub parseLocales {
    my $class = shift;
    my $hdr = shift || '';

    my $locales = {};
    for my $chunk (split /,\s*/, $hdr) {
        my ($entry, $quality) = split /;q=/, $chunk;
        next if $quality && $quality eq '*'; # XXX
        $quality ||= '0.0';

        $locales->{$quality} ||= [];
        push @{ $locales->{$quality} }, $entry;
    }

    my @list;
    for my $quality (sort { $b <=> $a } keys %$locales) {
        for my $locale (@{ $locales->{$quality} }) {
            push @list, $locale;
        }
    }

    return wantarray ? @list : \@list;
}

sub parseParameters {
    my $class = shift;
    my $str = shift;

    my @uriwords;
    if ($str) {
        for my $chunk (split /[;&]/, $str) {
            my ($key, $val) = split /=/, $chunk;

            if (defined $key && defined $val) {
                $key = __PACKAGE__->unescapeURIPart($key);
                $val = __PACKAGE__->unescapeURIPart($val);

                push @uriwords, [$key, $val];
            } else {
                # malformed parameter, skip
            }
        }
    }

    return wantarray ? @uriwords : \@uriwords;
}

sub unescapeURIPart {
    my $class = shift;
    my $str = shift;

    if ($str) {
        $str =~ tr/+/ /;
        $str = URI::Escape::uri_unescape($str);
    }

    return $str;
}

1;
__END__
