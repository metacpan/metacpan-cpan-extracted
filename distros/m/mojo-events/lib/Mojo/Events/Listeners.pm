package Mojo::Events::Listeners;
use Mojo::Base -base;

use Mojo::Loader qw(find_modules load_class);
use Mojo::Server;

has app => sub { Mojo::Server->new->build_app('Mojo::HelloWorld') }, weak => 1;
has registered => sub { [] };
has namespaces => sub { [] };

=head2 new

Initialize listeners

=cut

sub new {
    my $self = shift->SUPER::new(@_);

    my @namespaces = @{ $self->namespaces };
    push(@namespaces, 'Mojo::Events::Listeners');

    for my $namespace (@namespaces) {
        for my $module (find_modules($namespace)) {
            my $loaded = _listener($module, 1);

            if (!$loaded) {
                warn "Could not load $module";
                
                next;
            }

            # Initialize listener
            my $listener = $loaded->new(app => $self->app);
            
            push(@{ $self->registered }, $listener);
        }
    }

    return $self;
}

=head2 register

Append new listener

=cut

sub register {
    my ($self, $listener) = @_;

    if (!$listener->isa('Mojo::Events::Listener')) {
        warn "Invalid listener";
    }

    push(@{ $self->registered }, $listener);
}

=head2 _listener

Load listener

=cut

sub _listener {
    my ($module, $fatal) = @_;

    return $module->isa('Mojo::Events::Listener') ? $module : undef
        unless my $e = load_class $module;
    $fatal && ref $e ? die $e : return undef;
}

1;
