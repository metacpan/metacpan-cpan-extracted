package WWW::2ch::Plugin::Jbbs;
use strict;
our $VERSION = '0.03';

use base qw( WWW::2ch::Plugin::Base );

use POSIX;

sub encoding { 'euc-jp' }

sub gen_conf {
    my $self = shift;
    my $conf = shift;

    my $url = $conf->{url};
    my ($host, $bbs, $key);
    if ($url =~ m|^http://jbbs\.livedoor\.jp/bbs/read.cgi/([^/]+)/([^/]+)/(\d+)/|i) {
	($host, $bbs, $key) = ($1, $2, $3);
    } elsif ($url =~ m|^http://jbbs\.livedoor\.jp/([^/]+)/([^/]+)/|i) {
	($host, $bbs) = ($1, $2);
    } else {
	die 'url format error.';
    }
    $self->config(+{
	host => $host,
	domain => 'jbbs.livedoor.jp',
	bbs => $bbs,
	key => $key,
	setting => "http://jbbs.livedoor.jp/$host/$bbs/",
	subject => "http://jbbs.livedoor.jp/$host/$bbs/subject.txt",
	dat => "http://jbbs.livedoor.jp/bbs/rawmode.cgi/$host/$bbs/$key/",
	local_path => "jbbs.livedoor.jp/$host/$bbs/",
    });
    $self->config;
}

sub daturl {
    my ($self, $key) = @_;
    'http://' . $self->config->{domain} . '/bbs/rawmode.cgi/' . $self->config->{host} . '/' . $self->config->{bbs} . "/$key/";
}

sub permalink {
    my ($self, $key, $resid) = @_;
    if ($key) {
	if ($resid) {
	    return 'http://' . $self->config->{domain} . '/bbs/read.cgi/' . $self->config->{host} . '/' . $self->config->{bbs} . "/$key/$resid";
	} else {
	    return 'http://' . $self->config->{domain} . '/bbs/read.cgi/' . $self->config->{host} . '/' . $self->config->{bbs} . "/$key/";
	}
    } else {
	return $self->config->{setting};
    }
}

sub get_dat {
    my ($self, $c) = @_;

    my $res = $c->c->ua->diff_request($c->url);
    return unless $res->is_success;
    my $data = $res->content;
    $c->set_cache($data, $res);
    $data;
}

sub parse_setting {
    my ($self, $data) = @_;

    my $config;
    $data =~ m|<title>(.*?)</title>|;
    $config->{title} = $1;
    $config;
}

sub parse_subject {
    my ($self, $data) = @_;

    my @subject;
    foreach (split(/\n/, $data)) {
	/^(\d+).cgi,(.+?)\((\d+)\)$/;
	push(@subject, +{
	    key => $1,
	    title => $2,
	    resnum => $3,
	});
    }
    return \@subject;
}

sub parse_dat {
    my ($self, $data) = @_;

    my @dat;
    foreach (split(/\n/, $data)) {
	if (/^(.*?)<>(.*?)<>(.*?)<>(.*?)<>(.*?)<>(.*?)<>(.*?)$/i) {
	    my $res ={
		resid  => $1,
		name   => $2,
		mail   => $3,
		date   => $4,
		body   => $5,
		id     => $7,
	    };
	    my $date = $self->parse_date($res->{date});
	    $res->{$_} = $date->{$_} foreach (keys %{ $date });
	    push(@dat, $res);
	}
    }
    return \@dat;
}

sub parse_date {
    my ($self, $data) = @_;

    my $ret = {
	time => time,
    };
    my ($y, $m, $d, $h, $i, $s) = (0, 0, 0, 0, 0, 0);
    if ($data =~ m|(\d+)/(\d+)/(\d+)|) {
	($y, $m, $d) = ($1, $2, $3);
	if ($data =~ m| (\d+):(\d+):(\d+)|) {
	    ($h, $i, $s) = ($1, $2, $3);
	} elsif ($data =~ m| (\d+):(\d+)|) {
	    ($h, $i, $s) = ($1, $2, 0);
	}
	$y += 2000 if $y < 10;
	$y -= 1900;
	$m--;
	$ret->{time} = mktime($s, $i, $h, $d, $m, $y);
    }
    $ret;
}

1;

=head1 NAME

WWW::2ch::Plugin::Jbbs - Peculiar processing to jbbs

=head1 DESCRIPTION

It takes charge of peculiar processing to jbbs.

=head1 SEE ALSO

L<WWW::2ch>, L<WWW::2ch::Plugin::Base>, L<http://jbbs.livedoor.jp/>

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
