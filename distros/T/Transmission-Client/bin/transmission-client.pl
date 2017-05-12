#!/usr/bin/perl
# Copyright 2009-2010, Jan Henning Thorsen <jhthorsen@cpan.org>
#    and contributors
#
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

=head1 NAME

transmission-client.pl - Alternative to transmission-remote

=head1 SYNOPSIS

 transmission-client.pl list;
 transmission-client.pl session;
 transmission-client.pl session $key $value;
 transmission-client.pl stats;

=head1 DESCRIPTION

This is an example application for L<Transmission::Client>

=cut

use strict;
use warnings;
use lib qw(lib);
use Transmission::Client;

my $action = shift @ARGV or _help();

my $tc = Transmission::Client->new;

if($action eq 'list') {
    printf "%3s %-34s %4s %4s %5s %5s\n", 'id', 'name', 'lcrs', 'sdrs', 'rate', 'eta';
    print "-" x 79, "\n";
    for my $torrent ($tc->read_torrents) {
        printf "%3i %-34s %4s %4s %5s %5s\n",
            $torrent->id,
            substr($torrent->name, 0, 34),
            _peers($torrent->leechers),
            _peers($torrent->seeders),
            _rate($torrent->rate_download),
            _eta($torrent->eta),
            ;
    }
}
elsif($action eq 'session') {
    if(my $set = shift @ARGV) {
        $tc->session->$set(shift @ARGV);
        $tc->session->${ \"clear_$set" };
        printf "%s: %s\n", $set, $tc->session->$set;
        print $tc->error;
    }
    else {
        my $res = $tc->session->read_all;
        for my $key (sort keys %$res) {
            printf "%-30s %s\n", $key, $res->{$key};
        }
    }
}
elsif($action eq 'stats') {
    my $res = $tc->session->stats->read_all;
    for my $key (sort keys %$res) {
        printf "%-30s %s\n", $key, $res->{$key};
    }
}
else {
    _help();
}

print "\n";

#==============================================================================
sub _peers {
    my $n = shift;

    if($n < 0) {
        return 'na';
    }
    elsif($n < 9999) {
        return $n;
    }
    else {
        return '++';
    }
}
sub _rate {
    my $kbps = shift;

    if($kbps < 0) {
        return '0';
    }
    elsif($kbps < 1000) {
        return $kbps;
    }
    elsif($kbps < 1e6) {
        return int($kbps / 1e3) . 'k';
    }
    elsif($kbps < 1e6) {
        return int($kbps / 1e6) . 'M';
    }
    else {
        return '++';
    }
}

sub _eta {
    my $sec = shift;

    if($sec < 0) {
        return 'inf';
    }
    elsif($sec < 60) {
        return $sec . "s";
    }
    elsif($sec < 3600) {
        return int($sec / 6) / 10 . "m";
    }
    elsif($sec < 86400) {
        return int($sec / 360) / 10 . "h";
    }
    else {
        return '>1d';
    }
}

sub _help {
    exec perldoc => -tT => $0;
}

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Transmission::Client>

=head1 AUTHOR

Jan Henning Thorsen

=cut

exit;
