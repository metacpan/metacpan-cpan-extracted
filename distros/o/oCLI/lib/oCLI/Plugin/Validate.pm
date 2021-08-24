package oCLI::Plugin::Validate;
use Moo;
use Storable qw( dclone );
use Scalar::Util qw( looks_like_number );

# Enable code references in dclone so that our validation code
# refs don't result in "Can't store CODE items at"
# https://metacpan.org/pod/release/AMS/Storable-2.21/Storable.pm#CODE-REFERENCES
$Storable::Deparse = 1;
$Storable::Eval    = 1;

has tests => (
    is => 'ro',
    default => sub {
        return +{
            def     => sub { defined $_[2] ? $_[2] : $_[3] },
            defined => sub { defined $_[2] or die "Error: --$_[1] was expected.\n"; $_[2] },
            num     => sub { looks_like_number($_[2] or die "Error: --$_[1] expects a number.\n"); $_[2] },
            gte     => sub { $_[2] >= $_[3] or die "Error: --$_[1] must be a number greater than or equal to $_[3].\n"; $_[2] },
            lte     => sub { $_[2] <= $_[3] or die "Error: --$_[1] must be a number less than or equal to $_[3].\n"; $_[2] },
            min     => sub { length($_[2]) >= $_[3] or die "Error: --$_[1] must be a string longer than $_[3] characters.\n"; $_[2] },
            max     => sub { length($_[2]) <= $_[3] or die "Error: --$_[1] must be a string shorter than $_[3] characters.\n"; $_[2] },
        };
    }
);

sub after_context { }

# This function is run before the code reference is called.
#
# Self is the object of this code.
# c is the context object, it can be modified before running the code
# d is the command structure that we're running
sub before_code {
    my ( $self, $c, $d ) = @_;

    if ( ( not $d->{validate} ) or ( ref($d->{validate}) ne 'ARRAY' ) ) {
        $c->trace("No validation structure to check, skipping");
        return;
    }

    my $validate = dclone( $d->{validate} );

    while ( defined( my $token = shift @{$validate} ) ) {
        $c->trace("Checking $token");
        
        my $meta = shift @{$validate};

        foreach my $test ( @{$meta->[0]} ) {
            my ( $ref, $value );


            if ( looks_like_number($token) ) {
                $ref   = \$c->req->args->[$token];
                $value =  $c->req->args->[$token];
            } else {
                $ref   = \$c->req->settings->{$token};
                $value =  $c->req->settings->{$token};
            }

            if ( ref($test) eq 'CODE' ) {
                $c->trace("Running validation code block.");
                $$ref = $test->($c, $token, $value);
                next;
            }

            if ( index($test, '=') != -1 ) {
                my ( $function, $arg ) = split(/=/, $test, 2);
                $c->trace("Running validation function $function with user-supplied value $arg.");

                die "Error: unknown function $function called in validation."
                    unless defined $self->tests->{$function};
                $$ref = $self->tests->{$function}->($c, $token, $value, $arg );
                next;
            }

            # Last case, a bare function name.
            die "Error: unknown function $test called in validation."
                unless defined $self->tests->{$test};

            $$ref = $self->tests->{$test}->($c, $token, $value);
        }

    }
}

sub after_code {

}

1;
