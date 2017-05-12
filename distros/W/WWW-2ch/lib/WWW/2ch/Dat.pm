package WWW::2ch::Dat;
use strict;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw( c subject key title resnum dat ) );

use WWW::2ch::Res;

sub new {
    my $class = shift;
    my $c = shift;
    my $subject = shift;

    my $self = bless {
	c => $c,
	reslist => [],
	res_by_num => {},
	subject => $subject,
    }, $class;

    $self->set_subjects;
    $self;
}

sub set_subjects {
    my ($self) = @_;
    $self->key($self->subject->{key});
    $self->title($self->subject->{title});
    $self->resnum($self->subject->{resnum});
}

sub get_cache {
    my ($self) = @_;

    my $cache = $self->c->cache->get($self->file);
    return unless $cache->{data};
    $self->subject($cache->{subject});
    $self->set_subjects;
    $self->dat($cache->{data});
    $cache;
}

sub set_cache {
    my ($self, $data, $res) = @_;
    $self->c->cache->set($self->file, {
	subject => $self->subject,
	data => $data,
	time => HTTP::Date::str2time($res->header('Last-Modified')),
	fetch_time => time,
    });
}

sub load {
    my ($self) = @_;

    $self->{reslist} = [];
    $self->{res_by_num} ={};
    return 0 unless $self->c && $self->key;
    $self->dat($self->c->worker->get_dat($self));
    $self->parse;
}

sub parse {
    my ($self, $dat) = @_;

    return 0 unless $self->dat;
    my $dat = $self->c->worker->parse_dat($self->dat);
    my $i = 1;
    foreach (@{ $dat }) {
	$_->{num} = $i++;
	$_->{key} = $self->key;
	$_->{resid} = $_->{num} if $_->{resid} eq '';
	$self->add_res( WWW::2ch::Res->new($self->c, $_) );
    }
    $i;
}

sub add_res {
    my($self, $dat) = @_;
    push(@{ $self->{reslist} }, $dat);
    $self->{res_by_num}->{$dat->num} = $dat;
}

sub reslist {
    my $self = shift;
    wantarray ? @{ $self->{reslist} } : $self->{reslist};
}

sub res {
    my ($self, $num) = @_;
    $self->{res_by_num}->{$num};
}

sub url {
    my ($self) = @_;
    $self->c->worker->daturl($self->key);
}

sub file {
    my ($self) = @_;
    $self->c->conf->{local_path} . $self->key . '.dat';
}

sub permalink {
    my ($self) = @_;
    $self->c->worker->permalink($self->key);
}

1;
__END__

=head1 NAME

WWW::2ch::Dat - remark list of BBS is treated. 


=head1 Method

=over 4

=item title

article name

=item resnum

number of remarks

=item reslist

return L<WWW::2ch::Res> list

=item res

A corresponding L<WWW::2ch::Res> to res number is returned. 

=item dat

returns it with raw article data.

=item permalink


=back

=head1 SEE ALSO

L<WWW::2ch::Res>

=head1 AUTHOR

Kazuhiro Osawa

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
