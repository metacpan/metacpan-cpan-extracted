package XAO::DO::Web::Unicode;
use strict;
use Encode;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Action');

sub display_check_cgi ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    my $name=$args->{'name'} || 'ucode';
    my $value=$self->cgi->param($name) || '';

    $self->textout(Encode::is_utf8($value) ? 'unicode' : 'data');
}

sub display_force_byte_output ($@) {
    my $self=shift;
    $self->siteconfig->force_byte_output(1);
}

1;
