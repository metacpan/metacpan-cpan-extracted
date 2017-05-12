package WWW::2ch::Plugin::Base;
use strict;
our $VERSION = '0.06';

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw( conf config ) );

use POSIX;

sub new {
    my $class = shift;
    my $conf = shift;

    my $self = bless {}, $class;
    $conf = { $conf } unless ref($conf) eq 'HASH';
    $self->conf($conf);
    
    $self;
}

sub encoding { 'shiftjis' }

sub gen_conf {
    my $self = shift;
    my $conf = shift;

    my $url = $conf->{url};
    my ($host, $bbs, $key);
    if ($url =~ m|^http://([\w\d]+)\.2ch\.net/test/read.cgi/([^/]+)/(\d+)/|i) {
	($host, $bbs, $key) = ($1, $2, $3);
    } elsif ($url =~ m|^http://([\w\d]+)\.2ch\.net/([^/]+)/|i) {
	($host, $bbs) = ($1, $2);
    } else {
	die 'url format error.';
    }

    $self->config(+{
	host => $host,
	domain => "$host.2ch.net",
	bbs => $bbs,
	key => $key,
	setting => "http://$host.2ch.net/$bbs/SETTING.TXT",
	subject => "http://$host.2ch.net/$bbs/subject.txt",
	dat => "http://$host.2ch.net/$bbs/dat/$key.dat",
	local_path => "$host.2ch.net/$bbs/",
    });
    $self->config;
}

sub daturl {
    my ($self, $key) = @_;
    'http://' . $self->config->{domain} . '/' . $self->config->{bbs} . "/dat/$key.dat";
}

sub permalink {
    my ($self, $key, $resid) = @_;
    if ($key) {
	if ($resid) {
	    return 'http://' . $self->config->{domain} . '/test/read.cgi/' . $self->config->{bbs} . "/$key/$resid";
	} else {
	    return 'http://' . $self->config->{domain} . '/test/read.cgi/' . $self->config->{bbs} . "/$key/";
	}
    } else {
	return 'http://' . $self->config->{domain} . '/' . $self->config->{bbs} . '/';
    }
}

sub get_dat {
    my ($self, $c) = @_;

    my ($res, $data);
    my $cache = $c->get_cache;
    if ($cache->{data}) {
	$res = $c->c->ua->diff_request($c->url, time => $cache->{time}, size => (length($cache->{data}) - 1));
	$data = $res->content;
	if ($res->code eq '206') {
	    if ($data =~ s/^\n//) {
		$data = $cache->{data} . $data;
		$c->set_cache($data, $res);
	    } else {
		$cache = undef;
	    }
	} elsif ($res->code eq '304') {
	    $data = $cache->{data};
	} elsif ($res->code eq '416') {
	    $cache = undef;
	}
    }
    unless ($cache->{data}) {
	$res = $c->c->ua->diff_request($c->url);
	return unless $res->is_success;
	my $data = $data = $res->content;
	$c->set_cache($data, $res);
    }
    $data;
}

sub parse_setting {
    my ($self, $data) = @_;

    my $config;
    my @list = split(/\n/, $data);
    shift @list;
    foreach (@list) {
	my ($a, $b) = split(/=/, $_);
	$config->{$a} = $b;
    }

    $config->{title} = $config->{BBS_TITLE};
    $config->{noname} = $config->{BBS_NONAME_NAME};
    $config->{image} = $config->{BBS_TITLE_PICTURE};

    $config;
}

sub parse_subject {
    my ($self, $data) = @_;

    my @subject;
    foreach (split(/\n/, $data)) {
	/^(\d+).dat<>(.+?) \((\d+)\)$/;
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
    my $i = 0;
    foreach (split(/\n/, $data)) {
	if (/^(.*?)<>(.*?)<>(.*?)<>(.*?)<>.*?$/) {
	    $i++;
	    my $res ={
		name => $1,
		mail => $2,
		date => $3,
		body => $4,
		resid => $i,
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
	id => '',
	be => '',
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
    if ($data =~ / ID:([^ ]+) ?/) {
	$ret->{id} = $1;
    }
    if ($data =~ / BE:([^\- ]+)[\- ]?/) {
	$ret->{be} = $1;
    }
    $ret;
}

1;
__END__

=head1 NAME

WWW::2ch::Plugin::Base - Peculiar processing to 2ch

=head1 DESCRIPTION

It takes charge of peculiar processing to 2ch. 
it is likely to become basic processing of other sites. 

=head1 SEE ALSO

L<WWW::2ch>, L<http://2ch.net/>

=head1 AUTHOR

Kazuhiro Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
