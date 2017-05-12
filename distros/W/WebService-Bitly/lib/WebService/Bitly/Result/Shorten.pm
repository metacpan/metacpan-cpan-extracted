package WebService::Bitly::Result::Shorten;

use warnings;
use strict;
use Carp;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_shorten) = @_;
    my $self = $class->SUPER::new($result_shorten);
}

sub short_url {
    return shift->data->{url};
}

sub is_new_hash {
    return shift->data->{new_hash};
}

sub hash {
    return shift->data->{hash};
}

sub global_hash {
    return shift->data->{global_hash};
}

sub long_url {
    return shift->data->{long_url};
}

1;
