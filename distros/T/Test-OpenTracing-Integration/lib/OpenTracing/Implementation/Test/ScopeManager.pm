package OpenTracing::Implementation::Test::ScopeManager;

our $VERSION = 'v0.102.0';

use Moo;
use OpenTracing::Implementation::Test::Scope;

with 'OpenTracing::Role::ScopeManager';

has '+active_scope' => (
    clearer => 'final_scope',
);

sub build_scope {
    my ($self, %options) = @_;
    my $span                 = $options{span};
    my $finish_span_on_close = $options{finish_span_on_close};

    my $current_scope = $self->get_active_scope;
    my $restore_scope =
      $current_scope
      ? sub { $self->set_active_scope($current_scope) }
      : sub { $self->final_scope() };

    my $scope = OpenTracing::Implementation::Test::Scope->new(
        span                 => $span,
        finish_span_on_close => $finish_span_on_close,
        on_close             => $restore_scope,
    );

    return $scope
}

1;



=head1 NAME

OpenTracing::Implementation::Test::ScopeManager - OpenTracing Test for ScopeManager



=head1 AUTHOR

Szymon Nieznanski <snieznanski@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'Test::OpenTracing::Integration'
is Copyright (C) 2019 .. 2020, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.


=cut
