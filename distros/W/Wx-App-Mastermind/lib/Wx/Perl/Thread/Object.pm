package Wx::Perl::Thread::Object;

use strict;
use warnings;

use Thread::Queue::Any::Monitored;

my $SELF;

sub create {
    my( $class, @args ) = @_;
    my( $q, $t ) = Thread::Queue::Any::Monitored->new
      ( { monitor => sub { my( $meth, @args ) = @_; $SELF->$meth( @args ) },
          pre     => sub { $SELF = shift->new( @_ ) },
          }, $class, @args );

    # Oops, avoid the proxy being cloned
    my $self = bless {}, 'Wx::Perl::Thread::Object::Proxy';

    $self->{q} = $q;
    $self->{t} = $t;
    $self->{class} = $class;

    return $self;
}

package Wx::Perl::Thread::Object::Proxy;

use strict;
use warnings;

sub isa { $_[0]->{class}->isa( $_[1] ) }
sub can { $_[0]->{class}->can( $_[1] ) }

our $AUTOLOAD;

sub AUTOLOAD {
    my $name = $AUTOLOAD;
    $name =~ s/^.*:://;

    return if $name eq 'DESTROY';
    die $AUTOLOAD if Thread::Queue::Any::Monitored->self;
    die $AUTOLOAD if $name eq 'new';

    my $self = shift;

    $self->{q}->enqueue( $name, @_ );
}

sub wpto_terminate { $_[0]->{q}->enqueue( undef ) }
sub wpto_join      { $_[0]->{t}->join }

1;
