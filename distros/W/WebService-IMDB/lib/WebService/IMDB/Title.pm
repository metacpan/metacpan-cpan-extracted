# $Id: Title.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Title

=cut

package WebService::IMDB::Title;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(WebService::IMDB::Base);

use Carp;
our @CARP_NOT = qw(WebService::IMDB);

use HTTP::Request::Common;

use URI;

use WebService::IMDB::Certificate;
use WebService::IMDB::Credit;
use WebService::IMDB::CreditList;
use WebService::IMDB::Date;
use WebService::IMDB::Goof;
use WebService::IMDB::Image;
use WebService::IMDB::News;
use WebService::IMDB::ParentalGuideItem;
use WebService::IMDB::Photo;
use WebService::IMDB::Plot;
use WebService::IMDB::Quote;
use WebService::IMDB::Review;
use WebService::IMDB::Runtime;
use WebService::IMDB::Season;
use WebService::IMDB::Title::Stub;
use WebService::IMDB::Trailer;
use WebService::IMDB::Trivium;
use WebService::IMDB::UserComment;

__PACKAGE__->mk_accessors(qw(
    __cast_summary
    __certificate
    __creators
    __credits
    __directors_summary
    __goofs
    __image
    __news
    __parental_guide
    __photos
    __plots
    __quote
    __quotes
    __release_date
    __reviews
    __runtime
    __seasons
    __series
    __trailer
    __trivia
    __user_comment
    __user_comments
    __writers_summary
));

use constant {
    PAGE_MAINDETAILS => 1,
    PAGE_EXTERNAL_REVIEWS => 2,
    PAGE_EPISODES => 3,
    PAGE_FULLCREDITS => 4,
    PAGE_GOOFS => 5,
    PAGE_NEWS => 6,
    PAGE_PARENTALGUIDE => 7,
    PAGE_PHOTOS => 8,
    PAGE_PLOT => 9,
    PAGE_QUOTES => 10,
    PAGE_SYNOPSIS => 11,
    PAGE_TRIVIA => 12,
    PAGE_USERCOMMENTS => 13,

    PAGE_LAST => 13,
};

# Also:
# 'more_cast',
# 'more_writers',
# 'more_plot',


=head1 METHODS

=head2 tconst

=head2 cast_summary

=head2 certificate

=head2 creators

=head2 credits

=head2 directors_summary

=head2 genres

=head2 goof

=head2 goofs

=head2 image

=head2 news

=head2 num_votes

=head2 outline_plot

=head2 parental_guide

=head2 photos

=head2 plots

=head2 production_status

=head2 quote

=head2 quotes

=head2 rating

=head2 release_date

=head2 reviews

=head2 runtime

=head2 seasons

=head2 series

=head2 synopsis

=head2 tagline

=head2 title

=head2 trailer

=head2 trivia

=head2 trivium

=head2 type

=head2 user_comment

=head2 user_comments

=head2 writers_summary

=head2 year

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
    if ($page == PAGE_MAINDETAILS) {
	$uri->path(sprintf("/title/%s/maindetails", $self->_id()));
    } elsif ($page == PAGE_EXTERNAL_REVIEWS) {
	$uri->path("/title/external_reviews");
	$uri->query_form('tconst' => $self->_id());
    } elsif ($page == PAGE_EPISODES) {
	$uri->path("/title/episodes");
	$uri->query_form('tconst' => $self->_id());
    } elsif ($page == PAGE_FULLCREDITS) {
	$uri->path("/title/fullcredits");
	$uri->query_form('tconst' => $self->_id());
    } elsif ($page == PAGE_GOOFS) {
	$uri->path("/title/goofs");
	$uri->query_form('tconst' => $self->_id());
    } elsif ($page == PAGE_NEWS) {
	$uri->path(sprintf("/title/%s/news", $self->_id()));
    } elsif ($page == PAGE_PARENTALGUIDE) {
	$uri->path("/title/parentalguide");
	$uri->query_form('tconst' => $self->_id());
    } elsif ($page == PAGE_PHOTOS) {
	$uri->path("/title/photos");
	$uri->query_form('tconst' => $self->_id());
    } elsif ($page == PAGE_PLOT) {
	$uri->path("/title/plot");
	$uri->query_form('tconst' => $self->_id());
    } elsif ($page == PAGE_QUOTES) {
	$uri->path("/title/quotes");
	$uri->query_form('tconst' => $self->_id());
    } elsif ($page == PAGE_SYNOPSIS) {
	$uri->path("/title/synopsis");
	$uri->query_form('tconst' => $self->_id());
    } elsif ($page == PAGE_TRIVIA) {
	$uri->path("/title/trivia");
	$uri->query_form('tconst' => $self->_id());
    } elsif ($page == PAGE_USERCOMMENTS) {
	$uri->path("/title/usercomments");
	$uri->query_form('tconst' => $self->_id(), "limit" => 20); # TODO: Should perhaps be higher?
    }

    return $uri->as_string();
}


sub tconst {
    my $self = shift;
    return $self->_content(PAGE_MAINDETAILS)->{'tconst'};
}

sub cast_summary {
    my $self = shift;
    return $self->_cast_summary();
}

sub certificate {
    my $self = shift;
    return $self->_certificate();
}

sub creators {
    my $self = shift;
    return $self->_creators()
}

sub credits {
    my $self = shift;
    return $self->_credits()
}

sub directors_summary {
    my $self = shift;
    return $self->_directors_summary();
}

sub genres {
    my $self = shift;
    if (exists $self->_content(PAGE_MAINDETAILS)->{'genres'}) { # TODO: Think about how to handle this correctly.
	return [ @{$self->_content(PAGE_MAINDETAILS)->{'genres'}} ];
    } else {
	return [];
    }
}

sub goof {
    my $self = shift;
    if (exists $self->_content(PAGE_MAINDETAILS)->{'goof'}) {
	return $self->_content(PAGE_MAINDETAILS)->{'goof'};
    } else {
	return undef;
    }
}

sub goofs {
    my $self = shift;
    return $self->_goofs();
}

sub image {
    my $self = shift;
    return $self->_image();
}

sub news {
    my $self = shift;
    return $self->_news();
}

sub num_votes {
    my $self = shift;
    if (exists $self->_content(PAGE_MAINDETAILS)->{'num_votes'}) {
	return $self->_content(PAGE_MAINDETAILS)->{'num_votes'};
    } else {
	return undef;
    }
}

sub outline_plot {
    my $self = shift;
    if (exists $self->_content(PAGE_MAINDETAILS)->{'plot'} && exists $self->_content(PAGE_MAINDETAILS)->{'plot'}->{'outline'}) {
	return $self->_content(PAGE_MAINDETAILS)->{'plot'}->{'outline'};
    } else {
	return undef;
    }
}

sub parental_guide {
    my $self = shift;
    return $self->_parental_guide();
}

sub photos {
    my $self = shift;
    return $self->_photos();
}

sub plots {
    my $self = shift;
    return $self->_plots();
}

sub production_status {
    my $self = shift;
    if (exists $self->_content(PAGE_MAINDETAILS)->{'production_status'}) {
	return $self->_content(PAGE_MAINDETAILS)->{'production_status'};
    } else {
	return undef;
    }
}

sub quote {
    my $self = shift;
    return $self->_quote();
}

sub quotes {
    my $self = shift;
    return $self->_quotes();
}

sub rating {
    my $self = shift;
    if (exists $self->_content(PAGE_MAINDETAILS)->{'rating'}) {
	return $self->_content(PAGE_MAINDETAILS)->{'rating'};
    } else {
	return undef;
    }
}

sub release_date {
    my $self = shift;
    return $self->_release_date();
}

sub reviews { # Should be "external_reviews"?
    my $self = shift;
    return $self->_reviews();
}

sub runtime {
    my $self = shift;
    return $self->_runtime();
}

sub seasons {
    my $self = shift;
    return $self->_seasons();
}

sub series {
    my $self = shift;
    return $self->_series();
}

sub synopsis {
    my $self = shift;

    # We can't rely on $self->_content(PAGE_MAINDETAILS)->{'has'}; it doesn't always have synopsis present, even for titles that do 
    # return a synopsis in $self->_content(PAGE_SYNOPSIS) (e.g. tt0036342).  For titles that don't have a synopsis, $self->_content(PAGE_SYNOPSIS) 
    # can either return a hash without a 'text' key, or returns a 404 status (e.g. http://app.imdb.com/title/synopsis?tconst=tt0035015)
    # hence we test for both these cases.
    my $content;
    eval {
	$content = $self->_content(PAGE_SYNOPSIS);
    };

    if ($@ =~ m/404/) {
	$@ = "";
	return undef;
    } elsif ($@) {
	die $@;
    } elsif (exists $content->{'text'}) {
	return $content->{'text'};
    } else {
	return undef;
    }

}

sub tagline {
    my $self = shift;
    if (exists $self->_content(PAGE_MAINDETAILS)->{'tagline'}) {
	return $self->_content(PAGE_MAINDETAILS)->{'tagline'};
    } else {
	return undef;
    }
}

sub title {
    my $self = shift;
    return $self->_content(PAGE_MAINDETAILS)->{'title'};
}

sub trailer {
    my $self = shift;
    return $self->_trailer();
}

sub trivia {
    my $self = shift;
    return $self->_trivia();
}

sub trivium {
    my $self = shift;
    if (exists $self->_content(PAGE_MAINDETAILS)->{'trivium'}) {
	return $self->_content(PAGE_MAINDETAILS)->{'trivium'};
    } else {
	return undef;
    }
}

sub type {
    my $self = shift;
    return $self->_content(PAGE_MAINDETAILS)->{'type'};
}

sub user_comment {
    my $self = shift;
    return $self->_user_comment();
}

sub user_comments {
    my $self = shift;
    return $self->_user_comments();
}

sub writers_summary {
    my $self = shift;
    return $self->_writers_summary();
}

sub year {
    my $self = shift;
    return $self->_content(PAGE_MAINDETAILS)->{'year'};
}


# Temporary aliases for soem IMDB::Film methods

sub plot {
    my $self = shift;
    return $self->outline_plot();
}

sub full_plot {
    my $self = shift;
    if (scalar @{$self->plots()}) {
	return $self->plots()->[0]->text();
    } else {
	return undef;
    }
}




sub language {
    return undef;
}

sub company {
    return undef;
}

sub directors {
    return undef;
}

sub cast {
    return undef;
}

sub certifications {
    return undef;
}

sub duration {
    return undef;
}

sub episodeof {
    my $self = shift;
    if (defined $self->series()) {
	return [{'id' => substr($self->series()->tconst(), 2)}];
    } else {
	return undef;
    }
}

################################
#
# Caching accessors
#
################################

sub _flush {
    my $self = shift;

    $self->SUPER::_flush();

    $self->__cast_summary(undef);
    $self->__certificate(undef);
    $self->__creators(undef);
    $self->__credits(undef);
    $self->__directors_summary(undef);
    $self->__goofs(undef);
    $self->__image(undef);
    $self->__news(undef);
    $self->__parental_guide(undef);
    $self->__photos(undef);
    $self->__plots(undef);
    $self->__quote(undef);
    $self->__quotes(undef);
    $self->__release_date(undef);
    $self->__reviews(undef);
    $self->__runtime(undef);
    $self->__seasons(undef);
    $self->__series(undef);
    $self->__trailer(undef);
    $self->__trivia(undef);
    $self->__user_comment(undef);
    $self->__user_comments(undef);
    $self->__writers_summary(undef);
}

sub _cast_summary {
    my $self = shift;

    if (!defined $self->__cast_summary()) { $self->__cast_summary($self->_get_cast_summary()); }
    return $self->__cast_summary();
}

sub _certificate {
    my $self = shift;

    if (!defined $self->__certificate()) { $self->__certificate([$self->_get_certificate()]); } # Wrap in array, because we need to cache undef too
    return $self->__certificate()->[0];
}

sub _creators {
    my $self = shift;

    if (!defined $self->__creators()) { $self->__creators($self->_get_creators()); }
    return $self->__creators();
}

sub _credits {
    my $self = shift;

    if (!defined $self->__credits()) { $self->__credits($self->_get_credits()); }
    return $self->__credits();
}

sub _directors_summary {
    my $self = shift;

    if (!defined $self->__directors_summary()) { $self->__directors_summary($self->_get_directors_summary()); }
    return $self->__directors_summary();
}

sub _goofs {
    my $self = shift;

    if (!defined $self->__goofs()) { $self->__goofs($self->_get_goofs()); }
    return $self->__goofs();
}

sub _image {
    my $self = shift;

    if (!defined $self->__image()) { $self->__image([$self->_get_image()]); } # Wrap in array, because we need to cache undef too
    return $self->__image()->[0];
}

sub _news {
    my $self = shift;

    if (!defined $self->__news()) { $self->__news($self->_get_news()); }
    return $self->__news();
}

sub _parental_guide {
    my $self = shift;

    if (!defined $self->__parental_guide()) { $self->__parental_guide($self->_get_parental_guide()); }
    return $self->__parental_guide();
}

sub _photos {
    my $self = shift;

    if (!defined $self->__photos()) { $self->__photos($self->_get_photos()); }
    return $self->__photos();
}

sub _plots {
    my $self = shift;

    if (!defined $self->__plots()) { $self->__plots($self->_get_plots()); }
    return $self->__plots();
}

sub _quote {
    my $self = shift;

    if (!defined $self->__quote()) { $self->__quote([$self->_get_quote()]); } # Wrap in array, because we need to cache undef too
    return $self->__quote()->[0];
}

sub _quotes {
    my $self = shift;

    if (!defined $self->__quotes()) { $self->__quotes($self->_get_quotes()); }
    return $self->__quotes();
}

sub _release_date {
    my $self = shift;

    if (!defined $self->__release_date()) { $self->__release_date([$self->_get_release_date()]); } # Wrap in array, because we need to cache undef too
    return $self->__release_date()->[0];
}

sub _reviews {
    my $self = shift;

    if (!defined $self->__reviews()) { $self->__reviews($self->_get_reviews()); }
    return $self->__reviews();
}

sub _runtime {
    my $self = shift;

    if (!defined $self->__runtime()) { $self->__runtime([$self->_get_runtime()]); } # Wrap in array, because we need to cache undef too
    return $self->__runtime()->[0];
}

sub _seasons {
    my $self = shift;

    if (!defined $self->__seasons()) { $self->__seasons($self->_get_seasons()); }
    return $self->__seasons();
}

sub _series {
    my $self = shift;

    if (!defined $self->__series()) { $self->__series([$self->_get_series()]); } # Wrap in array, because we need to cache undef too
    return $self->__series()->[0];
}

sub _trailer {
    my $self = shift;

    if (!defined $self->__trailer()) { $self->__trailer([$self->_get_trailer()]); } # Wrap in array, because we need to cache undef too
    return $self->__trailer()->[0];
}

sub _trivia {
    my $self = shift;

    if (!defined $self->__trivia()) { $self->__trivia($self->_get_trivia()); }
    return $self->__trivia();
}

sub _user_comment {
    my $self = shift;

    if (!defined $self->__user_comment()) { $self->__user_comment([$self->_get_user_comment()]); } # Wrap in array, because we need to cache undef too
    return $self->__user_comment()->[0];
}

sub _user_comments {
    my $self = shift;

    if (!defined $self->__user_comments()) { $self->__user_comments($self->_get_user_comments()); }
    return $self->__user_comments();
}

sub _writers_summary {
    my $self = shift;

    if (!defined $self->__writers_summary()) { $self->__writers_summary($self->_get_writers_summary()); }
    return $self->__writers_summary();
}


################################
#
# Parsing methods
#
################################

sub _get_id {
    my $self = shift;

    my $tconst;

    if (exists $self->_q()->{'tconst'}) {
	$tconst = $self->_q()->{'tconst'}
    } elsif (exists $self->_q()->{'imdbid'}) {
	my $imdbid = $self->_q()->{'imdbid'};
	my ($id) = $imdbid =~ m/^(?:tt)?(\d+)$/ or die "Failed to parse '$imdbid'";
	$tconst = sprintf("tt%07d", $id);
    } else {
	croak "No valid search criteria";
    }

    # The constructor calls _get_id to validate the supplied id too, such that a
    # successful return from the constructor is indicative that the id is valid, and
    # that the resource exists.  We do that by trying to use the supplied id to
    # fetch the resource.

    my $uri = URI->new();
    $uri->scheme("http");
    $uri->host($self->_domain());
    $uri->path(sprintf("/title/%s/maindetails", $tconst));

    my $content = $self->_ws()->_response_decoded_json(GET $uri->as_string());

    if ($content->{'tconst'} ne $tconst) {
	die "tconst failed round trip"
    }

    return $tconst;
}

sub _get_cast_summary {
    my $self = shift;

    return [map {WebService::IMDB::Credit->_new($self->_ws(), $_)} @{$self->_content(PAGE_MAINDETAILS)->{'cast_summary'}}];

}

sub _get_certificate {
    my $self = shift;

    if (exists $self->_content(PAGE_MAINDETAILS)->{'certificate'}) {
	return WebService::IMDB::Certificate->_new($self->_ws(), $self->_content(PAGE_MAINDETAILS)->{'certificate'});
    } else {
	return undef;
    }

}

sub _get_creators {
    my $self = shift;

    if (exists $self->_content(PAGE_MAINDETAILS)->{'creators'}) {
	return [map {WebService::IMDB::Credit->_new($self->_ws(), $_)} @{$self->_content(PAGE_MAINDETAILS)->{'creators'}}];
    } else {
	return [];
    }

}

sub _get_credits {
    my $self = shift;

    return [map {WebService::IMDB::CreditList->_new($self->_ws(), $_)} @{$self->_content(PAGE_FULLCREDITS)->{'credits'}}];

}

sub _get_directors_summary {
    my $self = shift;

    return [map {WebService::IMDB::Credit->_new($self->_ws(), $_)} @{$self->_content(PAGE_MAINDETAILS)->{'directors_summary'}}];

}

sub _get_goofs {
    my $self = shift;

    return [
	(map {WebService::IMDB::Goof->_new($self->_ws(), $_, 1)} @{$self->_content(PAGE_GOOFS)->{'spoilt'}}),
	(map {WebService::IMDB::Goof->_new($self->_ws(), $_, '')} @{$self->_content(PAGE_GOOFS)->{'unspoilt'}}),
	];

}

sub _get_image {
    my $self = shift;

    if (exists $self->_content(PAGE_MAINDETAILS)->{'image'}) {
	return WebService::IMDB::Image->_new($self->_ws(), $self->_content(PAGE_MAINDETAILS)->{'image'});
    } else {
	return undef;
    }

}

sub _get_news {
    my $self = shift;

    # Handle 500 errors, e.g. for:
    # http://app.imdb.com/title/tt0095705/news
    # http://app.imdb.com/title/tt0213847/news
    # TODO: Is 'has' any more use in avoiding the problem here?
    my $content;
    eval {
	$content = $self->_content(PAGE_NEWS);
    };

    if ($@ =~ m/500/) {
	$@ = "";
	return undef;
    } elsif ($@) {
	die $@;
    } else {
	return WebService::IMDB::News->_new($self->_ws(), $content);
    }

}

sub _get_parental_guide {
    my $self = shift;

    return [map { WebService::IMDB::ParentalGuideItem->_new($self->_ws(), $_) } @{$self->_content(PAGE_PARENTALGUIDE)->{'parental_guide'}}];

}

sub _get_photos {
    my $self = shift;

    return [map { WebService::IMDB::Photo->_new($self->_ws(), $_) } @{$self->_content(PAGE_PHOTOS)->{'photos'}}];

}

sub _get_plots {
    my $self = shift;

    return [map {WebService::IMDB::Plot->_new($self->_ws(), $_)} @{$self->_content(PAGE_PLOT)->{'plots'}}];

}

sub _get_quote {
    my $self = shift;
    if (exists  $self->_content(PAGE_MAINDETAILS)->{'quote'}) {
	return WebService::IMDB::Quote->_new($self->_ws(), $self->_content(PAGE_MAINDETAILS)->{'quote'});
    } else {
	return undef;
    }
}

sub _get_quotes {
    my $self = shift;

    return [map {WebService::IMDB::Quote->_new($self->_ws(), $_)} @{$self->_content(PAGE_QUOTES)->{'quotes'}}];

}

sub _get_release_date {
    my $self = shift;

    if (exists $self->_content(PAGE_MAINDETAILS)->{'release_date'}) {
	return WebService::IMDB::Date->_new($self->_ws(), $self->_content(PAGE_MAINDETAILS)->{'release_date'});
    } else {
	return undef;
    }

}

sub _get_reviews {
    my $self = shift;

    return [map {WebService::IMDB::Review->_new($self->_ws(), $_)} @{$self->_content(PAGE_EXTERNAL_REVIEWS)->{'reviews'}}];

}

sub _get_runtime {
    my $self = shift;

    if (exists $self->_content(PAGE_MAINDETAILS)->{'runtime'}) {
	return WebService::IMDB::Runtime->_new($self->_ws(), $self->_content(PAGE_MAINDETAILS)->{'runtime'});
    } else {
	return undef;
    }

}

sub _get_seasons {
    my $self = shift;

    if (exists $self->_content(PAGE_EPISODES)->{'seasons'}) {
	return [map {WebService::IMDB::Season->_new($self->_ws(), $_)} @{$self->_content(PAGE_EPISODES)->{'seasons'}}];
    } else {
	return [];
    }

}

sub _get_series {
    my $self = shift;

    if (exists $self->_content(PAGE_MAINDETAILS)->{'series'}) {
	return WebService::IMDB::Title::Stub->_new($self->_ws(), $self->_content(PAGE_MAINDETAILS)->{'series'});
    } else {
	return undef;
    }

}

sub _get_trailer {
    my $self = shift;

    if (exists $self->_content(PAGE_MAINDETAILS)->{'trailer'}) {
	return WebService::IMDB::Trailer->_new($self->_ws(), $self->_content(PAGE_MAINDETAILS)->{'trailer'});
    } else {
	return undef;
    }

}

sub _get_trivia {
    my $self = shift;

    return [
	(map { WebService::IMDB::Trivium->_new($self->_ws(), $_, 1) } @{$self->_content(PAGE_TRIVIA)->{'spoilt'}}),
	(map { WebService::IMDB::Trivium->_new($self->_ws(), $_, '') } @{$self->_content(PAGE_TRIVIA)->{'unspoilt'}}),
	];

}

sub _get_user_comment {
    my $self = shift;

    if (exists $self->_content(PAGE_MAINDETAILS)->{'user_comment'}) {
	return WebService::IMDB::UserComment->_new($self->_ws(), $self->_content(PAGE_MAINDETAILS)->{'user_comment'});
    } else {
	return undef;
    }

}

sub _get_user_comments {
    my $self = shift;

    return [map {WebService::IMDB::UserComment->_new($self->_ws(), $_)} @{$self->_content(PAGE_USERCOMMENTS)->{'user_comments'}}];

}

sub _get_writers_summary {
    my $self = shift;

    return [map {WebService::IMDB::Credit->_new($self->_ws(), $_)} @{$self->_content(PAGE_MAINDETAILS)->{'writers_summary'}}];

}



################################
#
# Debug / dev code
#
################################

sub _unparsed {
    my $self = shift;

    use Storable qw(dclone);
    my $d = { map {$_ => dclone(eval { $self->_content($_) } || {} )} (1..PAGE_LAST) }; # See comments in synopsis(), _get_news() for why we need eval.

    delete $d->{PAGE_MAINDETAILS()}->{'tconst'};
    delete $d->{PAGE_MAINDETAILS()}->{'cast_summary'};
    delete $d->{PAGE_MAINDETAILS()}->{'certificate'};
    delete $d->{PAGE_MAINDETAILS()}->{'creators'};
    delete $d->{PAGE_FULLCREDITS()}->{'credits'};
    delete $d->{PAGE_MAINDETAILS()}->{'directors_summary'};
    delete $d->{PAGE_MAINDETAILS()}->{'genres'};
    delete $d->{PAGE_MAINDETAILS()}->{'image'};
    delete $d->{PAGE_MAINDETAILS()}->{'goof'};
    delete $d->{PAGE_GOOFS()}->{'spoilt'};
    delete $d->{PAGE_GOOFS()}->{'unspoilt'};
    delete $d->{PAGE_MAINDETAILS()}->{'title'};
    $d->{PAGE_NEWS()} = {};
    delete $d->{PAGE_MAINDETAILS()}->{'num_votes'};
    delete $d->{PAGE_MAINDETAILS()}->{'plot'}->{'outline'};
    delete $d->{PAGE_PARENTALGUIDE()}->{'parental_guide'};
    delete $d->{PAGE_PHOTOS()}->{'photos'};
    delete $d->{PAGE_PLOT()}->{'plots'};
    delete $d->{PAGE_MAINDETAILS()}->{'production_status'};
    delete $d->{PAGE_MAINDETAILS()}->{'quote'};
    delete $d->{PAGE_QUOTES()}->{'quotes'};
    delete $d->{PAGE_MAINDETAILS()}->{'rating'};
    delete $d->{PAGE_MAINDETAILS()}->{'release_date'};
    delete $d->{PAGE_EXTERNAL_REVIEWS()}->{'reviews'};
    delete $d->{PAGE_MAINDETAILS()}->{'runtime'};
    delete $d->{PAGE_EPISODES()}->{'seasons'};
    delete $d->{PAGE_MAINDETAILS()}->{'series'};
    delete $d->{PAGE_SYNOPSIS()}->{'text'};
    delete $d->{PAGE_MAINDETAILS()}->{'tagline'};
    delete $d->{PAGE_MAINDETAILS()}->{'title'};
    delete $d->{PAGE_MAINDETAILS()}->{'trailer'};
    delete $d->{PAGE_TRIVIA()}->{'spoilt'};
    delete $d->{PAGE_TRIVIA()}->{'unspoilt'};
    delete $d->{PAGE_MAINDETAILS()}->{'trivium'};
    delete $d->{PAGE_MAINDETAILS()}->{'type'};
    delete $d->{PAGE_MAINDETAILS()}->{'user_comment'};
    delete $d->{PAGE_USERCOMMENTS()}->{'user_comments'};
    delete $d->{PAGE_MAINDETAILS()}->{'writers_summary'};
    delete $d->{PAGE_MAINDETAILS()}->{'year'};

    # TODO: Check that these really aren't required
    delete $d->{PAGE_MAINDETAILS()}->{'can_rate'}; # What is this?
    delete $d->{PAGE_MAINDETAILS()}->{'has'};
    delete $d->{PAGE_MAINDETAILS()}->{'plot'}; # Should only have ->{'more'} remaining

    delete $d->{PAGE_USERCOMMENTS()}->{'limit'};
    delete $d->{PAGE_USERCOMMENTS()}->{'total'};


    # TODO: Check that there's nothing in these that doesn't occur in the dedicated pages
    delete $d->{PAGE_MAINDETAILS()}->{'news'};
    delete $d->{PAGE_MAINDETAILS()}->{'photos'};
    delete $d->{PAGE_MAINDETAILS()}->{'seasons'};

    delete $d->{PAGE_EXTERNAL_REVIEWS()}->{'tconst'};
    delete $d->{PAGE_EXTERNAL_REVIEWS()}->{'title'};
    delete $d->{PAGE_EXTERNAL_REVIEWS()}->{'type'};
    delete $d->{PAGE_EXTERNAL_REVIEWS()}->{'year'};

    delete $d->{PAGE_EPISODES()}->{'tconst'};
    delete $d->{PAGE_EPISODES()}->{'title'};
    delete $d->{PAGE_EPISODES()}->{'type'};
    delete $d->{PAGE_EPISODES()}->{'year'};

    delete $d->{PAGE_FULLCREDITS()}->{'tconst'};
    delete $d->{PAGE_FULLCREDITS()}->{'title'};
    delete $d->{PAGE_FULLCREDITS()}->{'type'};
    delete $d->{PAGE_FULLCREDITS()}->{'year'};

    delete $d->{PAGE_GOOFS()}->{'tconst'};
    delete $d->{PAGE_GOOFS()}->{'title'};
    delete $d->{PAGE_GOOFS()}->{'type'};
    delete $d->{PAGE_GOOFS()}->{'year'};

    delete $d->{PAGE_PHOTOS()}->{'tconst'};
    delete $d->{PAGE_PHOTOS()}->{'title'};
    delete $d->{PAGE_PHOTOS()}->{'type'};
    delete $d->{PAGE_PHOTOS()}->{'year'};

    delete $d->{PAGE_PLOT()}->{'tconst'};
    delete $d->{PAGE_PLOT()}->{'title'};
    delete $d->{PAGE_PLOT()}->{'type'};
    delete $d->{PAGE_PLOT()}->{'year'};

    delete $d->{PAGE_QUOTES()}->{'tconst'};
    delete $d->{PAGE_QUOTES()}->{'title'};
    delete $d->{PAGE_QUOTES()}->{'type'};
    delete $d->{PAGE_QUOTES()}->{'year'};

    delete $d->{PAGE_SYNOPSIS()}->{'tconst'};
    delete $d->{PAGE_SYNOPSIS()}->{'title'};
    delete $d->{PAGE_SYNOPSIS()}->{'type'};
    delete $d->{PAGE_SYNOPSIS()}->{'year'};

    delete $d->{PAGE_TRIVIA()}->{'tconst'};
    delete $d->{PAGE_TRIVIA()}->{'title'};
    delete $d->{PAGE_TRIVIA()}->{'type'};
    delete $d->{PAGE_TRIVIA()}->{'year'};

    delete $d->{PAGE_USERCOMMENTS()}->{'tconst'};
    delete $d->{PAGE_USERCOMMENTS()}->{'title'};
    delete $d->{PAGE_USERCOMMENTS()}->{'type'};
    delete $d->{PAGE_USERCOMMENTS()}->{'year'};

    return $d;
}

1;
