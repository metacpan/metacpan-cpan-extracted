# $Id: Stub.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Title::Stub

=head1 DESCRIPTION

WebService::IMDB::Title::Stub is to store any data supplied alongside
a reference to a title, preventing additional API requests.  WebService::IMDB::Title::Stub
isa WebService::IMDB::Title, and can be treated as such.  Any of the methods specific to
WebService::IMDB::Title::Stub can be called with a single true argument, preventing
recursion to WebService::IMDB::Title if the data isn't immediately available.

=cut

package WebService::IMDB::Title::Stub;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(WebService::IMDB::Title);

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Name);

use WebService::IMDB::Title;

__PACKAGE__->mk_accessors(qw(
    _stub_tconst
    _stub_image
    _stub_release_date
    _stub_title
    _stub_type
    _stub_year
));


=head1 METHODS

=head2 obj

Return a conventional WebService::IMDB::Title object.

=head2 tconst

=head2 release_date

=head2 title

=head2 type

=head2 year

=cut

sub _new {
    my $class = shift;
    my $ws = shift;
    my $data = shift;

    my $self = $class->SUPER::_new($ws, {'tconst' => $data->{'tconst'}}, '_defer_fetch' => 1);
    bless $self, $class;

    $self->_stub_tconst($data->{'tconst'});
    if (exists $data->{'image'}) { $self->_stub_image(WebService::IMDB::Image->_new($ws, $data->{'image'})); }
    if (exists $data->{'release_date'}) { $self->_stub_release_date(WebService::IMDB::Date->_new($ws, $data->{'release_date'})); }
    if (exists $data->{'title'}) { $self->_stub_title($data->{'title'}); } # TODO: This should perhaps be treated as non-optional
    if (exists $data->{'type'}) { $self->_stub_type($data->{'type'}); }
    if (exists $data->{'year'}) { $self->_stub_year($data->{'year'}); }

    if (0) { $self->_check_unparsed($data); }

    return $self;
}

sub obj {
    my $self = shift;
    return WebService::IMDB::Title->_new($self->_ws(), {'tconst' => $self->tconst()});
}

sub tconst {
    my $self = shift;
    return $self->_stub_tconst();
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

sub release_date {
    my $self = shift;
    my $nosuper = shift;

    if (defined $self->_stub_release_date()) {
	return $self->_stub_release_date();
    } elsif ($nosuper) {
	return undef;
    } else {
	return $self->SUPER::release_date();
    }
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

sub type {
    my $self = shift;
    my $nosuper = shift;

    if (defined $self->_stub_type()) {
	return $self->_stub_type();
    } elsif ($nosuper) {
	return undef;
    } else {
	return $self->SUPER::type();
    }
}

sub year {
    my $self = shift;
    my $nosuper = shift;

    if (defined $self->_stub_year()) {
	return $self->_stub_year();
    } elsif ($nosuper) {
	return undef;
    } else {
	return $self->SUPER::year();
    }
}


sub _check_unparsed {
    use Storable qw(dclone);

    my $self = shift;
    my $d = dclone(shift);

    delete $d->{'tconst'};
    delete $d->{'image'};
    delete $d->{'title'};
    delete $d->{'type'};
    delete $d->{'year'};

    if (scalar keys %$d != 0) {
	die "Remaining keys: " . join(", ", keys %$d);
    }
}

1;
