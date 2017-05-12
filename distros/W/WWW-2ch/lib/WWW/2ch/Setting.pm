package WWW::2ch::Setting;
use strict;

use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw( c url config title noname image) );


sub new {
    my $class = shift;
    my $c = shift;
    my $url = shift;

    my $self = bless {c => $c, url => $url}, $class;

    $self;
}

sub load {
    my $self = shift;

    return 0 unless $self->c && $self->url;
    my $res = $self->c->ua->get($self->url);
    return 0 unless $res->is_success;

    my $config = $self->c->worker->parse_setting($res->content);
    $self->config($config);
    $self->title($config->{title});
    $self->noname($config->{noname});
    $self->image($config->{image});
    
    return 1;
}

1;
