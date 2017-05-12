package WWW::2ch::Subject;
use strict;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw( c url title noname image) );

use HTTP::Date;

use WWW::2ch::Dat;

sub new {
    my $class = shift;
    my $c = shift;
    my $url = shift;

    my $self = bless {
	c => $c,
	url => $url,
	threads => [],
	thread_by_key => {},
    }, $class;

    $self->title($c->setting->{title});
    $self->noname($c->setting->{noname});
    $self->image($c->setting->{image});

    $self;
}

sub load {
    my ($self) = @_;

    $self->{threads} = [];
    $self->{thread_by_key} = {};
    return 0 unless $self->c && $self->url;

    my $cache = $self->c->cache->get($self->file);
    my $time = $cache->{time} || 0;
    my $res = $self->c->ua->diff_request($self->url, time => $time);

    my $data;
    if (!$res->is_success) {
	return 0 unless $res->code eq '304';
	$data = $cache->{data};
    } elsif ($res->content eq $cache->{data}) {
	$data = $cache->{data};
    } else {
	my $lasttime =  HTTP::Date::str2time($res->header('Last-Modified'));
	$self->c->cache->set($self->file, {
	    data => $res->content,
	    time => $lasttime,
	    fetch_time => time,
	    url => $self->url,
	    title => $self->title,
	    noname => $self->noname,
	    image => $self->image,
	});
	$data = $res->content;
    }
    my $subject = $self->c->worker->parse_subject($data);
    foreach (@{ $subject }) {
	$_->{url} = $self->url;
	$_->{bbstitle} = $self->title;
	$_->{noname} = $self->noname;
	$_->{image} = $self->image;
	$self->add_thread( WWW::2ch::Dat->new($self->c, $_) );
    }
    return 1;
}

sub add_thread {
    my($self, $dat) = @_;
    push @{ $self->{threads} }, $dat;
    $self->{thread_by_key}->{$dat->key} = $dat;
}

sub threads {
    my $self = shift;
    wantarray ? @{ $self->{threads} } : $self->{threads};
}

sub thread {
    my ($self, $key) = @_;
    $self->{thread_by_key}->{$key};
}

sub file {
    my ($self) = @_;
    $self->c->conf->{local_path} . 'subject.txt';
}

sub permalink {
    my ($self) = @_;
    $self->c->worker->permalink;
}

1;
__END__

=head1 NAME

WWW::2ch::Subject - article list of BBS is treated. 


=head1 Method

=over 4

=item title

bbs name

=item threads

return L<WWW::2ch::Dat> list

=item thread

A corresponding L<WWW::2ch::Dat> to key is returned. 

=item permalink


=back

=head1 SEE ALSO

L<WWW::2ch::Dat>

=head1 AUTHOR

Kazuhiro Osawa

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
