# $Id: Name.pm 7370 2012-04-09 01:17:33Z chris $

=head1 NAME

WebService::IMDB::Name

=cut

package WebService::IMDB::Name;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(WebService::IMDB::Base);

use Carp;
our @CARP_NOT = qw(WebService::IMDB);

use HTTP::Request::Common;

use URI;

use WebService::IMDB::Birth;
use WebService::IMDB::Death;
use WebService::IMDB::News;
use WebService::IMDB::KnownFor;
use WebService::IMDB::Trivium;
use WebService::IMDB::WhereNow;

__PACKAGE__->mk_accessors(qw(
    __birth
    __death
    __image
    __known_for
    __news
    __photos
    __trivia
    __where_now
));

use constant {
    PAGE_MAINDETAILS => 1,
    PAGE_NEWS => 2,
    PAGE_PHOTOS => 3,
    PAGE_QUOTES => 4,
    PAGE_TRIVIA => 5,

    PAGE_LAST => 5,
};


=head1 METHODS

=head2 nconst

=head2 aka

=head2 bio

=head2 birth

=head2 death

=head2 image

=head2 known_for

=head2 name

=head2 news

=head2 photos

=head2 quotes

=head2 real_name

=head2 trivia

=head2 where_now

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
	$uri->path(sprintf("/name/%s/maindetails", $self->_id()));
    } elsif ($page == PAGE_NEWS) {
	$uri->path(sprintf("/name/%s/news", $self->_id()));
    } elsif ($page == PAGE_PHOTOS) {
	$uri->path("/name/photos");
	$uri->query_form('nconst' => $self->_id());
    } elsif ($page == PAGE_QUOTES) {
	$uri->path("/name/quotes");
	$uri->query_form('nconst' => $self->_id());
    } elsif ($page == PAGE_TRIVIA) {
	$uri->path("/name/trivia");
	$uri->query_form('nconst' => $self->_id());
    }

    return $uri->as_string();
}


sub nconst {
    my $self = shift;
    return $self->_content(PAGE_MAINDETAILS)->{'nconst'};
}

sub aka {
    my $self = shift;
    if (exists $self->_content(PAGE_MAINDETAILS)->{'aka'}) {
	return $self->_content(PAGE_MAINDETAILS)->{'aka'};
    } else {
	return [];
    }
}

sub bio {
    my $self = shift;
    if (exists $self->_content(PAGE_MAINDETAILS)->{'bio'}) {
	return $self->_content(PAGE_MAINDETAILS)->{'bio'};
    } else {
	return undef;
    }
}

sub birth {
    my $self = shift;
    return $self->_birth();
}

sub death {
    my $self = shift;
    return $self->_death();
}

sub image {
    my $self = shift;
    return $self->_image();
}

sub known_for {
    my $self = shift;
    return $self->_known_for()
}

sub name {
    my $self = shift;
    return $self->_content(PAGE_MAINDETAILS)->{'name'};
}

sub news {
    my $self = shift;
    return $self->_news();
}

sub photos {
    my $self = shift;
    return $self->_photos();
}

sub quotes {
    my $self = shift;
    if (exists $self->_content(PAGE_QUOTES)->{'quotes'}) { # TODO: Think about how to handle this best.
	return [ @{$self->_content(PAGE_QUOTES)->{'quotes'}} ];
    } else {
	return [];
    }
}

sub real_name {
    my $self = shift;
    if (exists $self->_content(PAGE_MAINDETAILS)->{'real_name'}) {
	return $self->_content(PAGE_MAINDETAILS)->{'real_name'};
    } else {
	return undef;
    }
}

sub trivia {
    my $self = shift;
    return $self->_trivia();
}

sub where_now {
    my $self = shift;
    return $self->_where_now();
}


################################
#
# Caching accessors
#
################################

sub _flush {
    my $self = shift;

    $self->SUPER::_flush();

    $self->__birth(undef);
    $self->__death(undef);
    $self->__image(undef);
    $self->__known_for(undef);
    $self->__news(undef);
    $self->__photos(undef);
    $self->__trivia(undef);
    $self->__where_now(undef);
}

sub _birth {
    my $self = shift;

    if (!defined $self->__birth()) { $self->__birth([$self->_get_birth()]); } # Wrap in array, because we need to cache undef too
    return $self->__birth()->[0];
}

sub _death {
    my $self = shift;

    if (!defined $self->__death()) { $self->__death([$self->_get_death()]); } # Wrap in array, because we need to cache undef too
    return $self->__death()->[0];
}

sub _image {
    my $self = shift;

    if (!defined $self->__image()) { $self->__image([$self->_get_image()]); } # Wrap in array, because we need to cache undef too
    return $self->__image()->[0];
}

sub _known_for {
    my $self = shift;

    if (!defined $self->__known_for()) { $self->__known_for($self->_get_known_for()); }
    return $self->__known_for();
}

sub _news {
    my $self = shift;

    if (!defined $self->__news()) { $self->__news($self->_get_news()); }
    return $self->__news();
}

sub _photos {
    my $self = shift;

    if (!defined $self->__photos()) { $self->__photos($self->_get_photos()); }
    return $self->__photos();
}

sub _trivia {
    my $self = shift;

    if (!defined $self->__trivia()) { $self->__trivia($self->_get_trivia()); }
    return $self->__trivia();
}

sub _where_now {
    my $self = shift;

    if (!defined $self->__where_now()) { $self->__where_now($self->_get_where_now()); }
    return $self->__where_now();
}


################################
#
# Parsing methods
#
################################

sub _get_id {
    my $self = shift;

    my $nconst;

    if (exists $self->_q()->{'nconst'}) {
	$nconst = $self->_q()->{'nconst'}
    } elsif (exists $self->_q()->{'imdbid'}) {
	my $imdbid = $self->_q()->{'imdbid'};
	my ($id) = $imdbid =~ m/^(?:nm)?(\d+)$/ or die "Failed to parse '$imdbid'";
	$nconst = sprintf("nm%07d", $id);
    } else {
	croak "No valid search criteria";
    }

    # See comments in WebService::IMDB::Title::_get_id()

    my $uri = URI->new();
    $uri->scheme("http");
    $uri->host($self->_domain());
    $uri->path(sprintf("/name/%s/maindetails", $nconst));

    my $content = $self->_ws()->_response_decoded_json(GET $uri->as_string());

    if ($content->{'nconst'} ne $nconst) {
	die "nconst failed round trip"
    }

    return $nconst;

}

sub _get_birth {
    my $self = shift;

    if (exists $self->_content(PAGE_MAINDETAILS)->{'birth'}) {
	return WebService::IMDB::Birth->_new($self->_ws(), $self->_content(PAGE_MAINDETAILS)->{'birth'});
    } else {
	return undef;
    }

}

sub _get_death {
    my $self = shift;

    if (exists $self->_content(PAGE_MAINDETAILS)->{'death'}) {
	return WebService::IMDB::Death->_new($self->_ws(), $self->_content(PAGE_MAINDETAILS)->{'death'});
    } else {
	return undef;
    }

}

sub _get_image {
    my $self = shift;

    if (exists $self->_content(PAGE_MAINDETAILS)->{'image'}) {
	return WebService::IMDB::Image->_new($self->_ws(), $self->_content(PAGE_MAINDETAILS)->{'image'});
    } else {
	return undef;
    }

}

sub _get_known_for {
    my $self = shift;

    return [map { WebService::IMDB::KnownFor->_new($self->_ws(), $_) } @{$self->_content(PAGE_MAINDETAILS)->{'known_for'}}];

}

sub _get_news {
    my $self = shift;

    return WebService::IMDB::News->_new($self->_ws(), $self->_content(PAGE_NEWS));

}

sub _get_photos {
    my $self = shift;

    return [map { WebService::IMDB::Photo->_new($self->_ws(), $_) } @{$self->_content(PAGE_PHOTOS)->{'photos'}}];

}

sub _get_trivia {
    my $self = shift;

    return [map { WebService::IMDB::Trivium->_new($self->_ws(), $_) } @{$self->_content(PAGE_TRIVIA)->{'trivia'}}];

}

sub _get_where_now {
    my $self = shift;

    return [map { WebService::IMDB::WhereNow->_new($self->_ws(), $_) } @{$self->_content(PAGE_TRIVIA)->{'where_now'}}];

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

    delete $d->{PAGE_MAINDETAILS()}->{'nconst'};
    delete $d->{PAGE_MAINDETAILS()}->{'aka'};
    delete $d->{PAGE_MAINDETAILS()}->{'bio'};
    delete $d->{PAGE_MAINDETAILS()}->{'birth'};
    delete $d->{PAGE_MAINDETAILS()}->{'death'};
    delete $d->{PAGE_MAINDETAILS()}->{'image'};
    delete $d->{PAGE_MAINDETAILS()}->{'known_for'};
    delete $d->{PAGE_MAINDETAILS()}->{'name'};
    $d->{PAGE_NEWS()} = {};
    delete $d->{PAGE_PHOTOS()}->{'photos'};
    delete $d->{PAGE_QUOTES()}->{'quotes'};
    delete $d->{PAGE_MAINDETAILS()}->{'real_name'};
    delete $d->{PAGE_TRIVIA()}->{'trivia'};
    delete $d->{PAGE_TRIVIA()}->{'where_now'};

    # TODO: Check that these really aren't required
    delete $d->{PAGE_MAINDETAILS()}->{'has'};

    # TODO: Check that there's nothing in these that doesn't occur in the dedicated pages
    delete $d->{PAGE_MAINDETAILS()}->{'news'};
    delete $d->{PAGE_MAINDETAILS()}->{'photos'};

    delete $d->{PAGE_PHOTOS()}->{'name'};
    delete $d->{PAGE_PHOTOS()}->{'nconst'};

    delete $d->{PAGE_QUOTES()}->{'name'};
    delete $d->{PAGE_QUOTES()}->{'nconst'};

    delete $d->{PAGE_TRIVIA()}->{'name'};
    delete $d->{PAGE_TRIVIA()}->{'nconst'};

    return $d;
}

1;
