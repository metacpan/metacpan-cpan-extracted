package WebService::Bitly::Result::Countries;

use warnings;
use strict;
use Carp;

use base qw(WebService::Bitly::Result);

use WebService::Bitly::Util;

sub new {
    my ($class, $result_countries) = @_;
    my $self = $class->SUPER::new($result_countries);

    $self->{countries}
        = WebService::Bitly::Util->make_entries($self->data->{countries});

    return $self;
}

sub countries {
    my $countries = shift->{countries};
    return wantarray ? @$countries : $countries;
}

sub created_by {
    return shift->data->{created_by};
}

sub global_hash {
    return shift->data->{global_hash};
}

sub short_url {
    return shift->data->{short_url};
}

sub user_hash {
    return shift->data->{user_hash};
}

1;
