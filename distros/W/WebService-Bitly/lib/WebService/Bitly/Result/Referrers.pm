package WebService::Bitly::Result::Referrers;

use warnings;
use strict;
use Carp;

use base qw(WebService::Bitly::Result);

use WebService::Bitly::Util;

sub new {
    my ($class, $result_referrers) = @_;
    my $self = $class->SUPER::new($result_referrers);

    $self->{referrers}
        = WebService::Bitly::Util->make_entries($self->data->{referrers});

    return $self;
}

sub referrers {
    my $referrers = shift->{referrers};
    return wantarray ? @$referrers : $referrers;
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
