# $Id: Base.pm 7370 2012-04-09 01:17:33Z chris $

package WebService::IMDB::Base;

use strict;
use warnings;

our $VERSION = '0.05';

use base qw(Class::Accessor);

use Cache::FileCache;

use Carp;
our @CARP_NOT = qw(WebService::IMDB WebService::IMDB::Title WebService::IMDB::Name);

use HTTP::Request::Common;

__PACKAGE__->mk_accessors(qw(
    _ws
    _q

    __id

    __content
));


sub _new {
    my $class = shift;
    my $ws = shift;
    my $q = shift or die;
    my %opts = @_;

    my $self = {};

    bless $self, $class;

    $self->_ws($ws);

    $self->_q($q);

    if (!$opts{'_defer_fetch'}) {
	$self->_id();
    }

    return $self;

}

################################
#
# Primary properties
#
################################

sub type {
    my $self = shift;
    if ($self->isa("WebService::IMDB::Title")) {
	return "Title";
    } elsif ($self->isa("WebService::IMDB::Name")) {
	return "Name";
    } else {
	die "Unknown type";
    }
}


sub _domain {
    my $self = shift;
    return $self->_ws()->_domain();
}

sub _url {
    die "Not implemented";
}

sub _request {
    my $self = shift;
    my $page = shift;
    return GET $self->_url($page);
}


################################
#
# Caching accessors
#
################################

sub _flush {
    my $self = shift;

    $self->__id(undef);
    $self->__content(undef);
}

sub _id {
    my $self = shift;

    if (!defined $self->__id) {
	$self->__id($self->_get_id());
    }
    return $self->__id();
}

sub _content {
    my $self = shift;
    my $page = shift;

    if (!defined $self->__content()) { $self->__content({}); }

    my $content = $self->__content()->{$page};

    if (! defined $content) {

	$content = $self->_ws()->_response_decoded_json($self->_request($page));

	$self->__content()->{$page} = $content;
    }

    return $content;

}


################################
#
# Parsing methods
#
################################



1;
