package Test2::Tools::DOM::Check;

use v5.20;
use warnings;
use experimental 'signatures';

use Test2::Util ();
use Mojo::DOM58;

our $VERSION = '0.100';

use parent 'Test2::Compare::Base';

sub name { '<DOM>' }

sub verify ( $self, %params ) { !!$params{exists} }

sub init ( $self ) { $self->{calls} = [] }

sub add_call ( $self, $call, $check, $name, $context, @ ) {
    $name
        ||= ref $call eq 'ARRAY' ? $call->[0]
          : ref $call eq 'CODE'  ? '\&CODE'
          : $call;

    push @{ $self->{calls} } => [ $call, $check, $name, $context || 'scalar' ];
}

sub deltas ( $self, %params ) {
    my @deltas;
    my ( $got, $convert, $seen ) = @params{qw( got convert seen )};

    $self->{dom} = ref $got eq 'Mojo::DOM58' ? $got : Mojo::DOM58->new($got);

    if ( $self->{dom}->type eq 'root' ) {
        # Keep root in scope.
        # See https://github.com/mojolicious/mojo/issues/1924
        $self->{root} = $self->{dom};

        # For usability's sake, if we received the root of the DOM, we move
        # to its first child (if one exists). In the contexts where this
        # module will be used, this will in most cases be what people expect.
        if ( my $top = $self->{dom}->children->first ) {
            $self->{dom} = $top;
        }
    }

    my $dom = $self->{dom};

    for (@{ $self->{calls} // [] }) {
        my ( $method, $check, $name, $context ) = @$_;

        my @args;
        ( $method, @args ) = @$method if ref $method eq 'ARRAY';

        $check = $convert->($check);

        $method = ref $method eq 'CODE'
            ? $method
            : $dom->can($name);

        Carp::croak "Cannot call '$name' on an object of type " . ref $dom
            unless $method;


        my $value;
        my ( $ok, $err ) = Test2::Util::try {
            $value = $context eq 'list' ? [ $dom->$method(@args) ] :
                     $context eq 'hash' ? { $dom->$method(@args) } :
                                            $dom->$method(@args);
        };

        if ($ok) {
            my %args = (
                id      => [ METHOD => $name ],
                seen    => $seen,
                convert => $convert,
                got     => $value,
                exists  => defined $method,
            );

            # Support HTML/XML logic for element attributes
            if ( @args && $name eq 'attr' ) {
                my $exists = exists $dom->attr->{ $args[0] };
                $args{got}    = $exists if $check->name =~ /^(?:TRUE|FALSE)$/;
                $args{exists} = $exists if $check->name =~ /EXIST/;
            }
            # If the element is not found, it does not exist
            elsif ( $name eq 'at' ) {
                $args{exists} = defined $value if $check->name =~ /EXIST/;
            }

            push @deltas => $check->run(%args);
        }
        else {
            push @deltas => $check->delta_class->new(
                id        => [ METHOD => $name ],
                check     => $check,
                exception => $err,
                got       => undef,
                verified  => undef,
            );
        }
    }

    return @deltas;
}

sub stringify_got { 1 }

1;
