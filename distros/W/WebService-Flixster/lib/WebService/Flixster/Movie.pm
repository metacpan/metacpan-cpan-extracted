# $Id: Movie.pm 7375 2012-04-10 11:49:08Z chris $

=head1 NAME

WebService::Flixster::Movie

=cut

package WebService::Flixster::Movie;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(WebService::Flixster::Base);

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Base WebService::Flixster::Actor);

use HTTP::Request::Common;

use URI;

use WebService::Flixster::Actor::Stub;
use WebService::Flixster::Currency;
use WebService::Flixster::Date;
use WebService::Flixster::Director;
use WebService::Flixster::Photo;
use WebService::Flixster::Poster;
use WebService::Flixster::Reviews;
use WebService::Flixster::RunningTime;
use WebService::Flixster::Trailer;
use WebService::Flixster::URL;

__PACKAGE__->mk_accessors(qw(
    __actors
    __boxOffice
    __directors
    __photos
    __poster
    __products
    __releaseDates
    __reviews
    __runningTime
    __trailer
    __urls
));

use constant {
    PAGE_MAIN => 1,
    PAGE_PHOTOS => 2,
    PAGE_REVIEWS => 3,

    PAGE_LAST => 3,
};


=head1 METHODS

=head2 id

=head2 actors

=head2 boxOffice

=head2 dvdReleaseDate

=head2 directors

=head2 mpaa

=head2 photos

=head2 playing

=head2 poster

=head2 products

=head2 reviews

=head2 runningTime

=head2 status

=head2 synopsis

=head2 tags

=head2 theaterReleaseDate

=head2 thumbnail

=head2 title

=head2 trailer

=head2 url

=head2 urls

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
	$uri->path(sprintf("/iphone/api/v1/movies/%d.json", $self->_id()));
	$uri->query_form('limit' => 13, 'offset' => 0); # TODO: Suitable limit (and use offset?)
    } elsif ($page == PAGE_PHOTOS) {
	$uri->path("/iphone/api/v1/photos.json");
	$uri->query_form('movie' => $self->_id(), 'limit' => 100, 'offset' => 0); # TODO: Suitable limit (iPhone uses 100) (and use offset?)
    } elsif ($page == PAGE_REVIEWS) {
	$uri->path(sprintf("/iphone/api/v1/movies/%d/reviews.json", $self->_id()));
	$uri->query_form('type' => 'critics', 'limit' => 100, 'offset' => 0); # TODO: Type other than critics? TODO: Suitable limit (iPhone uses 20) (and use offset?)
    }

    return $uri->as_string();
}


sub id {
    my $self = shift;
    return $self->_content(PAGE_MAIN)->{'id'};
}

sub actors {
    my $self = shift;
    return $self->_actors();
}


sub boxOffice {
    my $self = shift;
    return $self->_boxOffice()
}

sub dvdReleaseDate {
    my $self = shift;
    return $self->_releaseDates()->{'dvd'};
}

sub directors {
    my $self = shift;
    return $self->_directors();
}

sub mpaa {
    my $self = shift;
    return $self->_content(PAGE_MAIN)->{'mpaa'};
}

sub photos {
    my $self = shift;
    return $self->_photos();
}

sub playing {
    my $self = shift;
    return !!$self->_content(PAGE_MAIN)->{'playing'};
}

sub poster {
    my $self = shift;
    return $self->_poster();
}

sub products {
    my $self = shift;
    return $self->_products();
}

sub reviews {
    my $self = shift;
    return $self->_reviews();
}

sub runningTime {
    my $self = shift;
    return $self->_runningTime();
}

sub status {
    my $self = shift;
    return $self->_content(PAGE_MAIN)->{'status'};
}

sub synopsis {
    my $self = shift;
    return $self->_content(PAGE_MAIN)->{'synopsis'};
}

sub tags {
    my $self = shift;
    return [ @{$self->_content(PAGE_MAIN)->{'tags'}} ];
}

sub theaterReleaseDate {
    my $self = shift;
    return $self->_releaseDates()->{'theater'};
}

sub thumbnail {
    my $self = shift;
    return $self->_content(PAGE_MAIN)->{'thumbnail'};
}

sub title {
    my $self = shift;
    return $self->_content(PAGE_MAIN)->{'title'};
}

sub trailer {
    my $self = shift;
    return $self->_trailer();
}

sub url {
    my $self = shift;
    return $self->_content(PAGE_MAIN)->{'url'};
}

sub urls {
    my $self = shift;
    return $self->_urls();
}


################################
#
# Caching accessors
#
################################

sub _flush {
    my $self = shift;

    $self->SUPER::_flush();

    $self->__actors(undef);
    $self->__boxOffice(undef);
    $self->__directors(undef);
    $self->__photos(undef);
    $self->__poster(undef);
    $self->__products(undef);
    $self->__releaseDates(undef);
    $self->__reviews(undef);
    $self->__runningTime(undef);
    $self->__trailer(undef);
    $self->__urls(undef);
}

sub _actors {
    my $self = shift;

    if (!defined $self->__actors()) {
	$self->__actors($self->_get_actors());
    }
    return $self->__actors();
}

sub _boxOffice {
    my $self = shift;

    if (!defined $self->__boxOffice()) {
	$self->__boxOffice($self->_get_boxOffice())
    }
    return $self->__boxOffice();
}

sub _directors {
    my $self = shift;

    if (!defined $self->__directors()) {
	$self->__directors($self->_get_directors());
    }
    return $self->__directors();
}

sub _photos {
    my $self = shift;

    if (!defined $self->__photos()) {
	$self->__photos($self->_get_photos());
    }
    return $self->__photos();
}

sub _poster {
    my $self = shift;

    if (!defined $self->__poster()) {
	$self->__poster($self->_get_poster());
    }
    return $self->__poster();
}

sub _products {
    my $self = shift;

    if (!defined $self->__products()) {
	$self->__products($self->_get_products());
    }
    return $self->__products();
}

sub _releaseDates {
    my $self = shift;

    if (!defined $self->__releaseDates()) {
	$self->__releaseDates($self->_get_releaseDates());
    }
    return $self->__releaseDates();
}

sub _reviews {
    my $self = shift;

    if (!defined $self->__reviews()) {
	$self->__reviews($self->_get_reviews());
    }
    return $self->__reviews();
}

sub _runningTime {
    my $self = shift;

    if (!defined $self->__runningTime()) {
	$self->__runningTime($self->_get_runningTime());
    }
    return $self->__runningTime();
}

sub _trailer {
    my $self = shift;

    if (!defined $self->__trailer()) {
	$self->__trailer($self->_get_trailer());
    }
    return $self->__trailer();
}

sub _urls {
    my $self = shift;

    if (!defined $self->__urls()) {
	$self->__urls($self->_get_urls());
    }
    return $self->__urls();
}


################################
#
# Parsing methods
#
################################

sub _get_id {
    my $self = shift;

    # The constructor calls _get_id to validate the supplied id too, such that a
    # successful return from the constructor is indicative that the id is valid, and
    # that the resource exists.  We do that by trying to use the supplied id to
    # fetch the resource.

    if (exists $self->_q()->{'id'}) {
	my $id = $self->_q()->{'id'};

	my $uri = URI->new();
	$uri->scheme("http");
	$uri->host($self->_domain());
	$uri->path(sprintf("/iphone/api/v1/movies/%d.json", $id));

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
	my ($imdbcode) = $imdbid =~ m/^(?:tt)?(\d+)$/ or die "Failed to parse '$imdbid'";

	my $uri = URI->new();
	$uri->scheme("http");
	$uri->host("www.rottentomatoes.com");
	$uri->path("/alias");
	$uri->query_form('type' => "imdbid", 's' => sprintf("%07d", $imdbcode));

	my $request = GET $uri->as_string();
	my $response = $self->_ws()->_response($request, {'200' => 1, '404' => 1});

	if($response->code() eq "200") {
	    my $id;
	    if ( !(
		      (($id) = $response->decoded_content() =~ m/movieid=(\d+)/) || # in URL
		      (($id) = $response->decoded_content() =~ m/movieid\s*=\s*"(\d+)"/) || # tag attribute
		      (($id) = $response->decoded_content() =~ m/'?movieId'?\s*:\s*(\d+)/) # javascript
		 ) ) {

		die "Failed to extract movie id";

	    }

	    # Some imdbids resolve to a flixster id with no associated data.  Detect these.
	    my $uri = URI->new();
	    $uri->scheme("http");
	    $uri->host($self->_domain());
	    $uri->path(sprintf("/iphone/api/v1/movies/%d.json", $id));

	    my $content = $self->_ws()->_response_decoded_content(GET $uri->as_string());

	    if ($content =~ m/^\s*$/) {
		croak "Resource not found";
	    }

	    return $id;

	} elsif ($response->code eq "404") {
	    croak "Resource not found";
	} else {
	    croak "URL (", $request->uri(), ") Request Failed - Code: ", $response->code(), " Error: ", $response->message(), "\n";
	}

    } else {
	croak "No valid search criteria";
    }

}

sub _get_actors {
    my $self = shift;

    return [ map { WebService::Flixster::Actor::Stub->_new($self->_ws(), $_) } @{$self->_content(PAGE_MAIN)->{'actors'}} ];

}

sub _get_boxOffice {
    my $self = shift;

    return WebService::Flixster::Currency->_new($self->_ws(), $self->_content(PAGE_MAIN)->{'boxOffice'}, $self->_content(PAGE_MAIN)->{'boxOfficeCurrencySymbol'});

}

sub _get_directors {
    my $self = shift;

    return [ map { WebService::Flixster::Director->_new($self->_ws(), $_) } @{$self->_content(PAGE_MAIN)->{'directors'}} ];

}

sub _get_photos {
    my $self = shift;

    return [ map { WebService::Flixster::Photo->_new($self->_ws(), $_) } @{$self->_content(PAGE_MAIN)->{'photos'}} ];

}

sub _get_poster {
    my $self = shift;

    return WebService::Flixster::Poster->_new($self->_ws(), $self->_content(PAGE_MAIN)->{'poster'});

}

sub _get_products {
    my $self = shift;

    return [ map { WebService::Flixster::URL->_new($self->_ws(), $_) } @{$self->_content(PAGE_MAIN)->{'products'}} ];;

}

sub _get_releaseDates {
    my $self = shift;

    return {
	'dvd'        => WebService::Flixster::Date->_new($self->_ws(), $self->_content(PAGE_MAIN)->{'dvdReleaseDate'}),
	'theater' => WebService::Flixster::Date->_new($self->_ws(), $self->_content(PAGE_MAIN)->{'theaterReleaseDate'}),
    };

}

sub _get_reviews {
    my $self = shift;

    return WebService::Flixster::Reviews->_new($self->_ws(), $self->_content(PAGE_MAIN)->{'reviews'}, $self->_content(PAGE_REVIEWS)->{'reviews'});

}

sub _get_runningTime {
    my $self = shift;

    return WebService::Flixster::RunningTime->_new($self->_ws(), $self->_content(PAGE_MAIN)->{'runningTime'});

}

sub _get_trailer {
    my $self = shift;

    return WebService::Flixster::Trailer->_new($self->_ws(), $self->_content(PAGE_MAIN)->{'trailer'});

}

sub _get_urls {
    my $self = shift;

    return [ map { WebService::Flixster::URL->_new($self->_ws(), $_) } @{$self->_content(PAGE_MAIN)->{'urls'}} ];

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

    delete $d->{PAGE_MAIN()}->{'id'};
    delete $d->{PAGE_MAIN()}->{'actors'};
    delete $d->{PAGE_MAIN()}->{'boxOffice'};
    delete $d->{PAGE_MAIN()}->{'boxOfficeCurrencySymbol'};
    delete $d->{PAGE_MAIN()}->{'directors'};
    delete $d->{PAGE_MAIN()}->{'dvdReleaseDate'};
    delete $d->{PAGE_MAIN()}->{'mpaa'};
    delete $d->{PAGE_MAIN()}->{'photos'};
    delete $d->{PAGE_MAIN()}->{'playing'};
    delete $d->{PAGE_MAIN()}->{'poster'};
    delete $d->{PAGE_MAIN()}->{'products'};
    delete $d->{PAGE_MAIN()}->{'reviews'};
    delete $d->{PAGE_MAIN()}->{'runningTime'};
    delete $d->{PAGE_MAIN()}->{'status'};
    delete $d->{PAGE_MAIN()}->{'synopsis'};
    delete $d->{PAGE_MAIN()}->{'tags'};
    delete $d->{PAGE_MAIN()}->{'theaterReleaseDate'};
    delete $d->{PAGE_MAIN()}->{'thumbnail'};
    delete $d->{PAGE_MAIN()}->{'title'};
    delete $d->{PAGE_MAIN()}->{'trailer'};
    delete $d->{PAGE_MAIN()}->{'url'};
    delete $d->{PAGE_MAIN()}->{'urls'};
    delete $d->{PAGE_REVIEWS()}->{'reviews'};

    # TODO: Check that these really aren't required
    delete $d->{PAGE_MAIN()}->{'photoCount'};

    return $d;
}

1;
