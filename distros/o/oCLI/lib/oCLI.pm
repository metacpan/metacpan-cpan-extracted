# ABSTRACT: Opinionated Command Line Interface
package oCLI;
use Moo;
use Import::Into;
use Package::Stash;
use oCLI::Context;
use oCLI::Request;
use oCLI::Plugin;
use Module::Runtime qw( use_module );
use Try::Tiny;

has root => (
    is => 'ro'
);

has render_root => (
    is => 'ro',
    lazy => 1,
    default => sub { shift->root },
);

sub import {
    my ( $class, @plugins ) = @_;

    my $target = caller;
    Package::Stash->new($target)->add_symbol( '%stash', { class => $target, plugins => [ @plugins ] } );
    Moo->import::into($target);
}

sub run {
    my ( $self, @in ) = @_;


    my $req = oCLI::Request->new_from_command_line( @in );

    my $c = oCLI::Context->new( req => $req, root => $self->root );
    
    # Load Plugins
    my $info  = (Package::Stash->new($self->root)->get_symbol('%stash'));
    foreach my $plugin ( @{$info->{plugins}} ) {
        $c->trace( "Loading plugin $plugin" );
        $c->plugin->add( use_module( $plugin )->new );
    }
    
    $c->plugin->hook_after_context( $c );

    use Data::Dumper;
    $c->trace("Entering oCLI::Dispatch::dispatch");
    $c->trace("Processing The Following Request:" );
    $c->trace( $c->req->command_class );
    $c->trace( $c->req->command_name );
    $c->trace(Dumper($c->req) );

    # Load Command Class.
    my $controller = try {
        if ( $c->req->command_class ) {
            $c->trace("Trying to load module: " .  $self->root . '::Command::' . $c->req->command_class );
            use_module( $self->root . '::Command::' . $c->req->command_class )->new();
        } else {
            $c->trace("Trying to load module: " . $self->root );
            use_module( $self->root )->new();
        }
    } catch {
        $c->trace("Failed to load module in oCLI::Dispatch::dispatch");
        die "Error: Failed to load command class: $_\n";
    };

    # Load Code
    my $stash = (Package::Stash->new(ref($controller))->get_symbol('%stash'));
    my $command  = $stash->{command}->{$c->req->command_name};


    $c->plugin->hook_before_code( $c, $command );

    $c->trace( "Request after hooks ran:" );
    $c->trace(Dumper($c->req) );

    $command->{code}->( $self, $c );

    $c->plugin->hook_after_code($c);

    $self->render($c)
        unless $c->req->overrides->{quiet};

    return $c;
}

sub render {
    my ( $self, $c ) = @_;

    # Load View Class.
    $c->stash->{view} ||= 'Text';
    my $view = try {
        use_module( $self->render_root . '::View::' . $c->stash->{view} )->new;
    } catch {
        die "Error: Failed to render command class: $_\n";
    };

    $view->render($c);
}

sub config {

}

sub model {
    my ( $class, $name, $data ) = @_;

    my $stash = (Package::Stash->new($class)->get_symbol('%stash'));

    $stash->{model}->{$name} = { 
        name => $name,
        %{$data},
    };

    return;
}

1;

=encoding UTF-8

=head1 NAME

oCLI - Opinionated Command Line Interface

=head1 DESCRIPTION

This is an early version of an Command Line Interface framework.  It needs more documenting.


