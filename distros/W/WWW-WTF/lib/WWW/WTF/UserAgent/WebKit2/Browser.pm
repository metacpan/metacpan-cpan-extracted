package WWW::WTF::UserAgent::WebKit2::Browser;

use common::sense;

use Moose;

extends 'WWW::WebKit2';

has 'callbacks' => (
    is      => 'ro',
    isa     => 'HashRef[CodeRef]',
    lazy    => 1,
    default => sub { {} },
);

sub init_webkit {
    my ($self) = @_;

    $self->SUPER::init_webkit;

    foreach my $callback (keys %{ $self->callbacks }) {

        $self->view->signal_connect($callback => sub {
            my ($view, $resource, $request) = @_;

            $self->callbacks->{$callback}->($view, $resource, $request);
        });
    }
}

__PACKAGE__->meta->make_immutable;

1;
