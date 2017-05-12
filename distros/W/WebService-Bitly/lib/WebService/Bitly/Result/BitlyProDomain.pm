package WebService::Bitly::Result::BitlyProDomain;

use warnings;
use strict;
use Carp;

use base qw(WebService::Bitly::Result);

sub new {
    my ($class, $result_bitly_pro_domain) = @_;
    my $self = $class->SUPER::new($result_bitly_pro_domain);
}

sub is_pro_domain {
    return shift->data->{bitly_pro_domain};
}

sub domain {
    return shift->data->{domain};
}

1;
