package e;

=head1 LOGO

                  ___====-_  _-====___
            _--~~~#####// '  ` \\#####~~~--_
          -~##########// (    ) \\##########~-_
        -############//  |\^^/|  \\############-
      _~############//   (O||O)   \\############~_
     ~#############((     \\//     ))#############~
    -###############\\    (oo)    //###############-
   -#################\\  / `' \  //#################-
  -###################\\/  ()  \//###################-
 _#/|##########/\######(  (())  )######/\##########|\#_
 |/ |#/\#/\#/\/  \#/\##|  \()/  |##/\#/  \/\#/\#/\#| \|
 `  |/  V  V  `   V  )||  |()|  ||(  V   '  V /\  \|  '
    `   `  `      `  / |  |()|  | \  '      '<||>  '
                    (  |  |()|  |  )\        /|/
                   __\ |__|()|__| /__\______/|/
                  (vvv(vvvv)(vvvv)vvv)______|/
                  __                __             __
     __  ______  / /__  ____ ______/ /_  ___  ____/ /
    / / / / __ \/ / _ \/ __ `/ ___/ __ \/ _ \/ __  /
   / /_/ / / / / /  __/ /_/ (__  ) / / /  __/ /_/ /
   \__,_/_/ /_/_/\___/\__,_/____/_/ /_/\___/\__,_/
  
=head1 NAME

e - beastmode unleashed

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '1.14';

=head1 SYNOPSIS

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

=cut

=head1 DESCRIPTION

This module imports many features that make
one-liners and script debugging much faster.

It has been optimized for performance to not
import all features right away:
thereby making its startup cost quite low.

=cut

=head1 SUBROUTINES

=head2 monkey_patch

Insert subroutines into the symbol table.

Extracted from Mojo::Util for performance.

Perhaps can be updated based on the outcome
of this issue:
L<https://github.com/mojolicious/mojo/pull/2173>

=head2 import

=head2 repl

Add a breakpoint to code.

Basically inserts a Read Evaluate Print Loop.

Enable to analyze code in the process.

=head2 trace

Show a stack trace.

 trace( $depth=1 )

=head2 watch

Watch a reference for changes.

 watch( $ref, $depth=3 )

=head2 prof

Profile the code from this point on.

 my $obj = prof;
 ...
 # $obj goes out of scope and builds results.

=head2 j

JSON Parser.

=head2 x

XML parser.

=head2 yml

YAML parser.

=head2 b

Work with strings.

=head2 c

Work with arrays.

=head2 f

Work with files.

=head2 say

Print with newline.

=head2 p

Pretty data printer.

=head2 np

Return pretty printer data.

=head2 d

Data dumper.

=head2 dd

Internal data dumper.

=head2 dye

Color a string.

    say dye( "HEY", "RED" );

=head2 g

Perform a get request.

=head2 l

Work with URLs.

=head2 pod

Work with perl pod.

=cut

sub monkey_patch {
    my ( $class, %patch ) = @_;

    # Can be omitted, but it makes traces much
    # nicer since it adds names to subs.
    require Sub::Util;

    no strict 'refs';

    for ( keys %patch ) {
        *{"${class}::$_"} =
          Sub::Util::set_subname( "${class}::$_", $patch{$_} );
    }
}

sub import {
    monkey_patch(
        ~~ caller(),

        ######################################
        #          Investigation
        ######################################

        # Debugging.
        repl => sub {
            require Runtime::Debugger;
            Runtime::Debugger::repl(
                levels_up => 1,
                @_,
            );
        },

        # Tracing.
        trace => sub {
            require Data::Trace;
            Data::Trace::Trace( @_ );
        },

        # Alias for trace.
        watch => sub {
            require Data::Trace;
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
            Data::Printer->import(
                use_prototypes => 0,
                show_dualvar   => "off",
                hash_separator => " => ",
                end_separator  => 1,
                show_refcount  => 1,
            );
            p( @_ );
        },
        np => sub {
            require Data::Printer;
            Data::Printer->import(
                use_prototypes => 0,
                show_dualvar   => "off",
                hash_separator => " => ",
                end_separator  => 1,
                show_refcount  => 1,
            );
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

        # Color.
        dye => sub {
            require Term::ANSIColor;
            Term::ANSIColor::colored( @_ );
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
        #              Pod
        ######################################

        pod => sub {
            require App::Pod;
            App::Pod->import;

            local @ARGV = @_;
            App::Pod->run;
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
