# $Id: Actor.pm 7375 2012-04-10 11:49:08Z chris $

=head1 NAME

WebService::Flixster::Actor

=cut

package WebService::Flixster::Actor;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(WebService::Flixster::Base);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Base WebService::Flixster::Movie);

use HTTP::Request::Common;

use URI;

use WebService::Flixster::Movie::Stub;

__PACKAGE__->mk_accessors(qw(
    __dob
    __movies
));


use constant {
    PAGE_MAIN => 1,
    PAGE_PHOTOS => 2,

    PAGE_LAST => 2,
};


=head1 METHODS

=head2 id

=head2 dob

=head2 movies

=head2 name

=head2 pob

=cut

################################
#
# Primary properties
#
################################

sub _url {
    my $self = shift;
    my $page = shift;

    my $uri = URI->new();
    $uri->scheme("http");
    $uri->host($self->_domain());
    if ($page == PAGE_MAIN) {
	$uri->path(sprintf("/iphone/api/v1/actors/%d.json", $self->_id()));
    } elsif ($page == PAGE_PHOTOS) {
	$uri->path("/iphone/api/v1/photos.json");
	$uri->query_form('actor' => $self->_id(), 'limit' => 100, 'offset' => 0); # TODO: Suitable limit (and use offset?)
    }

    return $uri->as_string();
}


sub id {
    my $self = shift;
    return $self->_content(PAGE_MAIN)->{'id'};
}

sub dob {
    my $self = shift;
    return $self->_dob();
}

sub movies {
    my $self = shift;
    return $self->_movies();
}

sub name {
    my $self = shift;
    return $self->_content(PAGE_MAIN)->{'name'};
}

sub pob {
    my $self = shift;
    return $self->_content(PAGE_MAIN)->{'pob'};
}


################################
#
# Caching accessors
#
################################

sub _flush {
    my $self = shift;

    $self->SUPER::_flush();

    $self->__dob(undef);
    $self->__movies(undef);
}

sub _dob {
    my $self = shift;

    if (!defined $self->__dob()) {
	$self->__dob($self->_get_dob());
    }
    return $self->__dob();
}

sub _movies {
    my $self = shift;

    if (!defined $self->__movies()) {
	$self->__movies($self->_get_movies());
    }
    return $self->__movies();
}


################################
#
# Parsing methods
#
################################

sub _get_id {
    my $self = shift;

    # See comment in WebService::Flixster::Movie::_get_id()

    if (exists $self->_q()->{'id'}) {
	my $id = $self->_q()->{'id'};

	my $uri = URI->new();
	$uri->scheme("http");
	$uri->host($self->_domain());
	$uri->path(sprintf("/iphone/api/v1/actors/%d.json", $id));

 	my $content = $self->_ws()->_response_decoded_content(GET $uri->as_string());

 	if ($content =~ m/^\s*$/) {
 	    croak "Resource not found";
 	}

	my $json = $self->_ws()->_response_decoded_json(GET $uri->as_string());

	if ($json->{'id'} ne $id) {
	    die "id failed round trip"
	}

	return $id;

    } elsif (exists $self->_q()->{'imdbid'}) {
	my $imdbid = $self->_q()->{'imdbid'};
	my ($id) = $imdbid =~ m/^(?:nm)?(\d+)$/ or die "Failed to parse '$imdbid'";
	die "TODO: " . sprintf("nm%07d", $id);
    } else {
	croak "No valid search criteria";
    }

}

sub _get_dob {
    my $self = shift;

    return WebService::Flixster::Date->_new($self->_ws(), $self->_content(PAGE_MAIN)->{'dob'});

}

sub _get_movies {
    my $self = shift;

    return [ map { WebService::Flixster::Movie::Stub->_new($self->_ws(), $_) } @{$self->_content(PAGE_MAIN)->{'movies'}} ];

}


################################
#
# Debug / dev code
#
################################

sub _unparsed {
    my $self = shift;

    use Storable qw(dclone);
    my $d = { map {$_ => dclone($self->_content($_))} (1..PAGE_LAST) };

    delete $d->{PAGE_MAIN()}->{'dob'};
    delete $d->{PAGE_MAIN()}->{'movies'};
    delete $d->{PAGE_MAIN()}->{'name'};
    delete $d->{PAGE_MAIN()}->{'pob'};

    return $d;
}

1;
