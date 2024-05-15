package e;

=head1 LOGO

                __                __             __
   __  ______  / /__  ____ ______/ /_  ___  ____/ /
  / / / / __ \/ / _ \/ __ `/ ___/ __ \/ _ \/ __  /
 / /_/ / / / / /  __/ /_/ (__  ) / / /  __/ /_/ /
 \__,_/_/ /_/_/\___/\__,_/____/_/ /_/\___/\__,_/

=cut

use 5.006;
use strict;
use warnings;

=head1 NAME

e - Unleash the power of e!

=cut

our $VERSION = '1.05';

=head1 SYNOPSIS

Convert a data structure to json:

    perl -Me -e 'say j { a => [ 1..3] }'

Convert a data structure to yaml:

    perl -Me -e 'say yml { a => [ 1..3] }'

Pretty print a data structure:

    perl -Me -e 'p { a => [ 1..3] }'

Data dump a data structure:

    perl -Me -e 'd { a => [ 1..3] }'

Devel::Peek dump a data structure:

    perl -Me -e 'dd { a => [ 1..3] }'

Add a trace marker:

    perl -Me -e 'sub f1 { trace } sub f2 { f1 } f2'

Watch a reference for changes:

    perl -Me -e 'my $v = {}; sub f1 { watch( $v ) } sub f2 { f1; $v->{a} = 1 } f2'

    perl -Me -e '
        package A {
            use e;
            my %h = ( aaa => 111 );

            watch(\%h);

            sub f1 {
                $h{b} = 1;
            }

            sub f2 {
                f1();
                delete $h{aaa};
            }
        }

        A::f2();
    '

Launch the Runtime::Debugger:

    perl -Me -e 'repl'

Invoke the Tiny::Prof:

    perl -Me -e 'prof'

=head1 SUBROUTINES

=head2 monkey_patch

insert subroutines into the symbol table.

Extracted from Mojo::Util for performance.

Can be updated once this issue is resolved:
L<https://github.com/mojolicious/mojo/pull/2173>

=cut

sub monkey_patch {
    my ( $class, %patch ) = @_;

    require Sub::Util;    # Can omit set_subname, but it makes traces nicer.
    no strict 'refs';

    for ( keys %patch ) {
        *{"${class}::$_"} =
          Sub::Util::set_subname( "${class}::$_", $patch{$_} );
    }
}

=head2 import

Inserts commands into caller's namespace.

=cut

sub import {
    monkey_patch(
        ~~ caller(),

        ######################################
        #          Investigation
        ######################################

        # Debugging.
        repl => sub {
            require Runtime::Debugger;
            Runtime::Debugger->VERSION( '0.20' )
              ;    # Since not using "use MODULE VERSION".
            Runtime::Debugger::repl(
                levels_up => 1,
                @_,
            );
        },

        # Tracing.
        trace => sub {    # Stack or var trace.
            require Data::Trace;
            Data::Trace->VERSION( '0.19' )
              ;           # Since not using "use MODULE VERSION".
            Data::Trace::Trace( @_ );
        },

        # Alias for trace.
        watch => sub {    # Stack or var trace.
            require Data::Trace;
            Data::Trace->VERSION( '0.19' )
              ;           # Since not using "use MODULE VERSION".
            Data::Trace::Trace( @_ );
        },


        # Benchmark/timing.
        n => sub (&@) {
            require Benchmark;
            Benchmark->import( ':hireswallclock' );
            print STDERR "\n";
            print STDERR Benchmark::timestr(
                Benchmark::timeit( $_[1] // 1, $_[0] ) );
            print STDERR "\n";
        },

        # Profiling.
        prof => sub {
            require Tiny::Prof;
            Tiny::Prof->run(
                Name => 'Test',
                @_,
            );
        },

        ######################################
        #         Format Conversions
        ######################################

        # Json.
        j => sub {
            require Mojo::JSON;
            Mojo::JSON::j( @_ );
        },

        # XML/HTML.
        x => sub {
            require Mojo::DOM;
            Mojo::DOM->new( @_ );
        },

        # YAML.
        yml => sub {
            my ( $thing ) = @_;
            require YAML::XS;
            ref $thing
              ? YAML::XS::Dump( $thing )
              : YAML::XS::Load( $thing );
        },

        ######################################
        #          Enhanced Types
        ######################################

        # String Object.
        b => sub {
            require Mojo::ByteStream;
            Mojo::ByteStream::b( @_ );
        },

        # Array Object.
        c => sub {
            require Mojo::Collection;
            Mojo::Collection::c( @_ );
        },

        ######################################
        #         Files Convenience
        ######################################

        # File Object.
        f => sub {
            require Mojo::File;
            Mojo::File::path( @_ );
        },

        ######################################
        #             Output
        ######################################

        # Print.
        say => sub {
            print @_ ? @_ : $_;
            print "\n";
        },

        # Pretty Print.
        p => sub {
            require Data::Printer;
            Data::Printer->import( use_prototypes => 0 );
            p( @_ );
        },
        np => sub {
            require Data::Printer;
            Data::Printer->import( use_prototypes => 0 );
            np( @_ );
        },

        # Dumper.
        d => sub {
            require Mojo::Util;
            print Mojo::Util::dumper( @_ );
        },

        # Dump C stuctures.
        dd => sub {
            require Devel::Peek;
            Devel::Peek::Dump( @_ );
        },

        ######################################
        #           Web Related
        ######################################

        # GET request.
        g => sub {
            require Mojo::UserAgent;
            my $UA = Mojo::UserAgent->new;
            $UA->max_redirects( 10 ) unless defined $ENV{MOJO_MAX_REDIRECTS};
            $UA->proxy->detect       unless defined $ENV{MOJO_PROXY};
            $UA->get( @_ )->result;
        },

        # URL.
        l => sub {
            require Mojo::URL;
            Mojo::URL->new( @_ );
        },

        ######################################
        #         Package Building
        ######################################

        monkey_patch => \&monkey_patch,

    );
}

=head1 AUTHOR

Tim Potapov, C<< <tim.potapov[AT]gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/poti1/e/issues>.

=head1 SUPPORT

You can find documentation for this module
with the perldoc command.

    perldoc e

You can also look for information at:

L<https://metacpan.org/pod/e>

L<https://github.com/poti1/e>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Tim Potapov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

"\x{1f42a}\x{1f977}"
