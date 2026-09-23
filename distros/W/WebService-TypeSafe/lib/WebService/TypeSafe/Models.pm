package WebService::TypeSafe::Models;

use strict;
use warnings;
use WebService::TypeSafe::Response ();

sub new { my ($class, $client) = @_; return bless { client => $client }, $class }
sub list {
    my ($self, %args) = @_;
    my $data = $self->{client}->_request('GET', '/v1/models', undef, %args);
    my @models = map { WebService::TypeSafe::Object->new($_) } @{ $data->{models} || [] };
    return WebService::TypeSafe::Object->new({ %$data, models => \@models });
}

1;
