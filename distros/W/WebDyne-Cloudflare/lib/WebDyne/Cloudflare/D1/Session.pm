package WebDyne::Cloudflare::D1::Session;

use 5.020;
use strict;
use warnings;
use Future::AsyncAwait;
use WebDyne::Cloudflare::D1;

our @ISA=qw(WebDyne::Cloudflare::D1);
our $VERSION='0.001';

sub new {
    die "Create D1 sessions with with_session()\n";
}


async sub get_bookmark {
    my ($self)=@_;
    die "D1 get_bookmark takes no arguments\n" unless (@_==1);
    return await $self->execute(operation => 'get_bookmark');
}

1;
