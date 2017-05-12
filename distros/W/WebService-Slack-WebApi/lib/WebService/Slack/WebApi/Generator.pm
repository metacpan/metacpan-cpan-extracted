package WebService::Slack::WebApi::Generator;
use strict;
use warnings;
use utf8;
use feature qw/state/;

sub import {
    my ($class, %rules) = @_;
    my $caller = caller;

    while (my ($method_name, $rule) = each %rules) {
        (my $path = $method_name) =~ s/_([a-z])/\u$1/g;
        my $method = sprintf '%s::%s', $caller, $method_name;

        no strict 'refs';
        *$method = sub {
            state $v = Data::Validator->new(%$rule)->with('Method', 'AllowExtra');
            my ($self, $args, %extra) = $v->validate(@_);
            return $self->request($path, {%$args, %extra});
        };
    }
}

1;

