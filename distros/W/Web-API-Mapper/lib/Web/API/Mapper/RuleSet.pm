package Web::API::Mapper::RuleSet;
use warnings;
use strict;
use Any::Moose;
use Path::Dispatcher;

has disp => ( 
    is => 'rw' , 
    default => sub { 
        return Path::Dispatcher->new;
    } );

has rules => ( is => 'rw', isa => 'ArrayRef' , default => sub { [  ] } );

has fallback => ( is => 'rw' , isa => 'CodeRef' , default => sub {  sub {  } } );

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    if ( ! ref $_[0] && ref $_[1] eq 'ARRAY') {
        my $base = shift @_;
        my $handlers = shift @_;
        my @rules;
        while (my($path, $code) = splice @$handlers, 0, 2) {
            $path = $base . $path;
            $path = qr@^/$@    if $path eq '/';
            $path = qr/^$path/ unless ref $path eq 'RegExp';
            push @rules, { path => $path, code => $code };
        }
        $class->$orig( base => $base , rules => \@rules, @_);
    } else {
        $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;
    $self->{_hits} = 0;
    $self->load();
}

sub mount {
    my ($self,$base,$routes) = @_;
    while (my($path, $code) = splice @$routes, 0, 2) {
        $path = $base . $path;
        $path = qr@^/$@    if $path eq '/';
        $path = qr/^$path/ unless ref $path eq 'RegExp';
        push @{ $self->rules } , { path => $path, code => $code };
        $self->add_rule( $path , $code );
    }
}

sub add_rule {  
    my ($self,$path,$code) = @_;
    $self->disp->add_rule( Path::Dispatcher::Rule::Regex->new( regex => $path , block => $code ));
    return $self;
}

sub load {
    my $self = shift;
    $self->add_rule( $_->{path} , $_->{code} ) for @{ $self->rules };
    return $self;
}

sub dispatch {
    my ($self,$path,$args) = @_;
    # $self->{_hits}++;
#     my $base = $self->base;
#     $path =~ s{^/$base/}{} if $base;
    my $dispatch = $self->disp->dispatch( $path );
    return $dispatch->run( $args ) if $dispatch->has_matches;
    return $self->fallback->( $args ) if $self->fallback;
    return;
}


1;
