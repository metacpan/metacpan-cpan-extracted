# $Id: Stub.pm 7373 2012-04-09 18:00:33Z chris $

package WebService::Flixster::Actor::Stub;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(WebService::Flixster::Actor);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Actor);

use WebService::Flixster::Actor;

__PACKAGE__->mk_accessors(qw(
    _stub_id
    _stub_character
    _stub_name
    _stub_photo
));


sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    my $self = $class->SUPER::_new($ws, {'id' => $data->{'id'}}, '_defer_fetch' => 1);
    bless $self, $class;

    $self->_stub_id($data->{'id'});
    if (exists $data->{'character'}) { $self->_stub_character($data->{'character'}); }
    if (exists $data->{'name'}) { $self->_stub_name($data->{'name'}); }
    if (exists $data->{'photo'}) { $self->_stub_photo($data->{'photo'}); }

    if (0) { $self->_check_unparsed($data); }

    return $self;
}

sub obj {
    my $self = shift;
    return WebService::Flixster::Actor->_new($self->_ws(), {'id' => $self->id()});
}

sub id {
    my $self = shift;
    return $self->_stub_id();
}

sub character {
    my $self = shift;
    my $nosuper = shift;

    if (defined $self->_stub_character()) {
	return $self->_stub_character();
    } elsif ($nosuper) {
	return undef;
    } else {
	return $self->SUPER::character();
    }
}

sub name {
    my $self = shift;
    my $nosuper = shift;

    if (defined $self->_stub_name()) {
	return $self->_stub_name();
    } elsif ($nosuper) {
	return undef;
    } else {
	return $self->SUPER::name();
    }
}

sub photo {
    my $self = shift;
    my $nosuper = shift;

    if (defined $self->_stub_photo()) {
	return $self->_stub_photo();
    } elsif ($nosuper) {
	return undef;
    } else {
	return $self->SUPER::photo();
    }
}


sub _check_unparsed {
    use Storable qw(dclone);

    my $self = shift;
    my $d = dclone(shift);

    delete $d->{'id'};
    delete $d->{'character'};
    delete $d->{'name'};
    delete $d->{'photo'};

    if (scalar keys %$d != 0) {
	die "Remaining keys: " . join(", ", keys %$d);
    }
}

1;
