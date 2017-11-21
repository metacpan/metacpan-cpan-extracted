package WebService::Slack::WebApi::Dialog;
use strict;
use warnings;
use utf8;
use 5.10.0;

use parent 'WebService::Slack::WebApi::Base';

use JSON::XS;

sub open {
  state $rule = Data::Validator->new(
    dialog     => { isa => 'HashRef', optional => 0 },
    trigger_id => { isa => 'Str',     optional => 0, },
  )->with('Method', 'AllowExtra');
  my ($self, $args, %extra) = $rule->validate(@_);

  $args->{dialog} = encode_json $args->{dialog};
  return $self->request('open', { %$args, %extra });
}

1;
