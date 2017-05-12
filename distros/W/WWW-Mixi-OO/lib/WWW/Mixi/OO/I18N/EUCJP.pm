# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: EUCJP.pm 89 2005-02-04 04:23:12Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/I18N/EUCJP.pm $
package WWW::Mixi::OO::I18N::EUCJP;
use strict;
use warnings;
use POSIX;
use Carp;
use base qw(WWW::Mixi::OO::I18N);

sub convert_from_http_content {
    my ($this, $charset, $str) = @_;

    die "this module not implementated charset convertion yet!"
	unless $charset =~ /euc-jp/i;
    return $str;
}

sub convert_to_http_content {
    my ($this, $charset, $str) = @_;

    die "this module not implementated charset convertion yet!"
	unless $charset =~ /euc-jp/i;
    return $str;
}

sub convert_login_time {
    my ($this, $timestr) = @_;
    return undef unless defined $timestr;
    my $time = 0;
    my $add_time = sub { $time += $1; '' };
    $timestr =~ s/(\d+)日/&$add_time/eg;$time *= 24;
    $timestr =~ s/(\d+)時間/&$add_time/eg;$time *= 60;
    $timestr =~ s/(\d+)分/&$add_time/eg;$time *= 60;
    $timestr =~ s/^(\d+)$/&$add_time/eg;
    if ($timestr) {
	croak "Couldn't parse login timestr. junk: $timestr, parsed: $time";
    }
    $timestr = strftime('%Y/%m/%d %H:%M', localtime(time() - $time));
    return wantarray ? ($timestr, $time) : $timestr;
}

sub convert_time {
    my ($this, $timestr) = @_;
    return undef unless defined $timestr;
    $timestr =~ s|(\d+)年(\d+)月(\d+)日|$1/$2/$3|g;
    $timestr =~ s|(\d+)月(\d+)日|$1/$2|g;
    return $timestr;
}

1;
