use strict;
use warnings;
use utf8;

package Ukigumo::Client::Executor::Prove;
use Mouse;
use Ukigumo::Constants;

sub run {
    my ($self, $c) = @_;
    return $c->tee("prove")==0 ? STATUS_SUCCESS : STATUS_FAIL;
}

1;
__END__

=head1 NAME

Ukigumo::Client::Executor::Prove - runs prove command

=head1 DESCRIPTION

This executor runs prove command.

