package HTML::HTPL::Orig;

use strict;

sub eof {
    my $self = shift;
    return undef if ($self->{'buffer'});
    return 1 if $self->{'dead'};
    ($self->{'buffer'} = $self->justfetch) ? undef : 1;
}

sub fetch {
    my $self = shift;
    return undef if $self->{'dead'};
    my $ret = $self->{'buffer'};
    if ($ret) {
        delete $self->{'buffer'};
        return $ret;
    }
    $self->justfetch;
}

sub justfetch {
    my $self = shift;
    my $ret = $self->realfetch;
    $self->{'dead'} = 1 unless ($ret);
    $ret;
}

1;
