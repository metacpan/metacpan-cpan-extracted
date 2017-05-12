# $Id: Base.pm 7373 2012-04-09 18:00:33Z chris $

package WebService::Flixster::Base;

use strict;
use warnings;

our $VERSION = '0.02';

use base qw(Class::Accessor);

use Cache::FileCache;

use Carp;
our @CARP_NOT = qw(WebService::Flixster WebService::Flixster::Title);

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
    my $q = shift;
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
    if ($self->isa("WebService::Flixster::Movie")) {
	return "Movie";
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

    $self->__ids(undef);
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
