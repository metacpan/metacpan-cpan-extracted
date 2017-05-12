package Webservice::InterMine::Model;

=head1 NAME

Webservice::InterMine::Model - A version of an InterMine Model that is aware that it comes from a web service

=head1 DESCRIPTION

This model provides lazy fetching support from its originating web service.

=cut

use parent qw(InterMine::Model);

use Scalar::Util qw/weaken/;

sub set_service {
    my $self = shift;
    my $service = shift;
    $self->{service} = $service;
    weaken($self->{service});
    return $self->{service};
}

sub lazy_fetch {
    my $self = shift;
    my ($cd, $fd, $obj) = @_;
    my $extra_views = ($fd->isa("InterMine::Model::Reference")) ? $fd->name . ".*" : $fd->name;
    my $q = $self->{service}
                 ->resultset($cd)
                 ->select("id", $extra_views)
                 ->where(id => $obj->id);
    $q->outerjoin($fd->name) if ($fd->isa("InterMine::Model::Reference"));
    my $r = $q->first(as => 'objects');
    my $reader = "get" . ucfirst($fd->name);
    my $ref = $r->$reader;
    return $ref;
}

1;

