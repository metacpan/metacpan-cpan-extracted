# $Id: Stub.pm 7373 2012-04-09 18:00:33Z chris $

package WebService::Flixster::Movie::Stub;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(WebService::Flixster::Movie);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Actor);

use WebService::Flixster::Movie;

__PACKAGE__->mk_accessors(qw(
    _stub_id
    _stub_title
));


sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    my $self = $class->SUPER::_new($ws, {'id' => $data->{'id'}}, '_defer_fetch' => 1);
    bless $self, $class;

    $self->_stub_id($data->{'id'});
    if (exists $data->{'title'}) { $self->_stub_title($data->{'title'}); }

    if (0) { $self->_check_unparsed($data); }

    return $self;
}

sub obj {
    my $self = shift;
    return WebService::Flixster::Movie->_new($self->_ws(), {'id' => $self->id()});
}

sub id {
    my $self = shift;
    return $self->_stub_id();
}

sub title {
    my $self = shift;
    my $nosuper = shift;

    if (defined $self->_stub_title()) {
	return $self->_stub_title();
    } elsif ($nosuper) {
	return undef;
    } else {
	return $self->SUPER::title();
    }
}

sub _check_unparsed {
    use Storable qw(dclone);

    my $self = shift;
    my $d = dclone(shift);

    delete $d->{'id'};
    delete $d->{'title'};

    if (scalar keys %$d != 0) {
	die "Remaining keys: " . join(", ", keys %$d);
    }
}

1;
