# $Id: Stub.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Name::Stub

=head1 DESCRIPTION

For details, see L<WebService::IMDB::Title::Stub>.

=cut

package WebService::IMDB::Name::Stub;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(WebService::IMDB::Name);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Title);

use WebService::IMDB::Name;

__PACKAGE__->mk_accessors(qw(
    _stub_nconst
    _stub_char
    _stub_image
    _stub_name
));


=head1 METHODS

=head2 obj

=head2 nconst

=head2 char

=head2 image

=head2 name

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    my $self = $class->SUPER::_new($ws, {'nconst' => $data->{'nconst'}}, '_defer_fetch' => 1);
    bless $self, $class;

    $self->_stub_nconst($data->{'nconst'});
    if (exists $data->{'char'}) { $self->_stub_char($data->{'char'}); }
    if (exists $data->{'image'}) { $self->_stub_image(WebService::IMDB::Image->_new($ws, $data->{'image'})); }
    if (exists $data->{'name'}) { $self->_stub_name($data->{'name'}); }

    if (0) { $self->_check_unparsed($data); }

    return $self;
}

sub obj {
    my $self = shift;
    return WebService::IMDB::Name->_new($self->_ws(), {'nconst' => $self->nconst()});
}


sub nconst {
    my $self = shift;
    return $self->_stub_nconst();
}

sub char {
    my $self = shift;
    my $nosuper = shift;

    if (defined $self->_stub_char()) {
	return $self->_stub_char();
    } elsif ($nosuper) {
	return undef;
    } else {
	return $self->SUPER::char();
    }
}

sub image {
    my $self = shift;
    my $nosuper = shift;

    if (defined $self->_stub_image()) {
	return $self->_stub_image();
    } elsif ($nosuper) {
	return undef;
    } else {
	return $self->SUPER::image();
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


sub _check_unparsed {
    use Storable qw(dclone);

    my $self = shift;
    my $d = dclone(shift);

    delete $d->{'nconst'};
    delete $d->{'image'};
    delete $d->{'name'};

    if (scalar keys %$d != 0) {
	die "Remaining keys: " . join(", ", keys %$d);
    }
}

1;
