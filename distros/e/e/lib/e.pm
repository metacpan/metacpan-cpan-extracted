package e;

=encoding utf8

=head1 LOGO

                       ⢀⣀⡤ ⢀⣤⣿⡗ ⣀⣀⣀
           ⢀⣤⣤⣤⣄⡀    ⣠⡶⠿⠛⣹⡾⠛⢁⡼⠟⢛⠉⠉⠉⣉⣣⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⡄
       ⢉⠻⣯⣉⡛⠒⠻⡷⢮⡙⠳⣤⡐⣾⠟⣀⣴⠋⠁⣀⡴⠋ ⣠⡟ ⠐⠚⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⢩⠛
       ⠘⣧ ⠹⣿⡳⡀⠙⢦⡈⠳⠈⢱⡟ ⠋⣼⣿⣿⢿⠁⠰⣶⠏⢐⡆⢠  ⣠⣖⣢⠤⠶⠶⠂ ⡽⢃  ⣀
        ⠈⢗⣲⠞⠓⠛⢦⡌⡿  ⡾⠃  ⣿⣿⡾   ⣿ ⣼⣠⠏⢀⡾⣿⠟⣂⣠⡤⠤⠴⠶⠛⠛⠛⢋⡿
    ⢀⡴⡲⠹⠍⠁ ⠐⢶⡂⠈⣓⠱⣆⡼⠃  ⢰⣿⡟⢳ ⢀⣾⢇⡜⠋⠁⣰⣯⠾⠷⠚⠉ ⢀⣴⠎    ⢸⡇
    ⠘⠙⠳⠤⣕ ⠳⣄ ⠉⠓⢴⣱⣿⡅⣀⣤⠾⣟⣯⣤⣶⡶⢿⣿⣯⠆ ⢈⣽⠃⣀⣀⣠⣴⣾⣯⠄     ⣴⠇
       ⢀⣹⣶⡀⢈⣷⣶⣤⣼⣿⡿⢗⡋⣩⣶⡟⣛⣿⣿⣷⣾⣛⣉⣀⡤⠾⠛⠒⠋⠉⠛⣿⡿⠋     ⢠⡏
      ⠙⠛⣲⡶⣤⣤⣿⡿⠋⠁⠻⠿⠛⠛⠙⠛⠛⠋⠉⠹⠿⠿⢿⣿⣏⣠⡖⣀⢀⣠⠤⢀⣈⣳⣄     ⢨⣶⣦⡤⣄⣀
       ⠉⢁⣴⣋⣸⠟       ⣰⣶⠴⠒      ⠈⠛⠻⢿⣿⣿⡛⠋⠉⠙⣿   ⣠⡶⣫⣭⠶⣭⡀
      ⢀⣴⠟⠉⢡⡏⡼   ⢠⡞  ⠉            ⢸⣿⡿⢿⡒⠒⠲⠿⠶⠶⠶⠟⠋⠁⣀⣀⣀⠉⠳⣄
     ⠲⣿⠷⠃⢀⣾⠷⠿⠦⢤⣤⡟   ⢀⣀⣤⣶⣯⣥⣤⣤⡞⠁   ⠈⣼⣿⣷⣝⡳⠤⣤⣀⣀   ⠉  ⠙⠻⢦⣈⢳⡄
    ⢀⡼⢋⣤⠴⠋⠁   ⣴⠿⠿⢶⣶⣿⣿⠟⠛⢻⣿⣿⠟⠁      ⠈⠻⣿⡍⠛⠷⣦⣄⡀⠳⢤⡀      ⠙⠧⣄
   ⣠⣿⠟⠉    ⣀⣀⡀ ⣤⣤⣼⣿⣿⣷⣂⣴⣿⡿⠋      ⠰⡆ ⢻⣿⣿⣶⣄⡈⠻⣝ ⠈⠙⠲⣤⣀⡀  ⠑⢦⣌⡙⠒
  ⢰⡟⠁     ⠛⢩⠶⠖⠛⣀⡏⠉⠙⠿⣿⣿⡟⠉         ⣷  ⣿⣿⣧⡙⢷⣄⡈⠂     ⠉⠉⠙⢷⡄⠈⠛⢦
 ⣠⡿⠛⢶⣦⣤⣤⣴⣶ ⠈⡿⠟⠛⠉⠁⢀⣀⣀ ⠉⠙⠛⠒⠂       ⡿ ⣽⣿⠘⢻⣷⡀⠈⠉⠉         ⠹⣆  ⠁
 ⡏  ⢸⣿⡿⠉⠙⠋ ⠈      ⠈⠉⣉⠅ ⠓⠲⢤⣄⡀    ⣼⠃ ⢿⣿  ⣿⠇⢠⡀       ⠠⣄⣄ ⢹⡆
 ⣷⡀  ⡿       ⣀⠔   ⣠⣞⣁⣀⣠⣤⣤⣷⣌⠙⢦⡀⢀⡾⠃  ⢸⣿⡆⣻⠇  ⢹⣄       ⢹⡌⢳⣜⡟
 ⢻⣧⣠⣸⡇          ⣠⡾⠟⠛⠉⣥⡾⢿⣿⣿⣿⣆ ⠙⠃    ⣿⢏⣿⡿⡀   ⠻⣷⢤⡀    ⢸⡇ ⢿⡇
  ⠉⢻⢿⣿⣶⣤⣤⣀⣀⣀⣀⣤⣴⡿⠋⠁⣠⡴⠟⢁⣴⣿⣿⣿⣿⣿⡆     ⣼⡟⣼⣿⣷⢻⡜⣆  ⠘⢷⡙  ⣠⣤⡿ ⠈⠛⠁
   ⠘⠦⢿⣍⠉⠉⠉⠙⢿⠩⢻⣿⣾⠞⠛⠁  ⣾⠏⠈⢻⣿⣿⣿⣿⡀⡀   ⢻⣰⠟⠁⠘⢦⡻⣿⡆  ⢸⣷  ⣿⡟⠁
      ⠙⠋⠛⠳⣶⣶⠷⢾⣿⣿    ⢀⣿   ⢻⣿⣿⣿⡧   ⢀⣴⠋    ⠁⠈⢳  ⣸⠙⣦⢰⡟
          ⠘⣿⣄⢼⣿⣿⣇⠒⢢⣿⣼⣧⡀ ⢤⡀⣿⣿⣿⡧  ⢀⣾⠃  ⢀⢠⡆  ⡞⢀⡴⣃⣸⡟⠳⣇
           ⠹⡽⣾⣿⠹⣿⣆⣾⢯⣿⣿ ⡞ ⠻⣿⣿⣿⠁ ⢠⣿⢏  ⡀ ⡟  ⢀⣴⣿⠃⢁⡼⠁ ⠈
             ⠈⠛ ⢻⣿⣧⢸⢟⠶⢾⡇  ⣸⡿⠁ ⢠⣾⡟⢼  ⣷ ⡇ ⣰⠋⠙⠁
                ⠈⣿⣻⣾⣦⣇⢸⣇⣀⣶⡿⠁⣀⣀⣾⢿⡇⢸  ⣟⡦⣧⣶⠏ unleashed
                 ⠸⢿⡍⠛⠻⠿⠿⠿⠋⣠⡾⢋⣾⣏⣸⣷⡸⣇⢰⠟⠛⠻⡄  v1.25
                   ⢻⡄   ⠐⠚⠋⣠⡾⣧⣿⠁⠙⢳⣽⡟
                   ⠈⠳⢦⣤⣤⣀⣤⡶⠛ ⠈⢿⡆  ⢿⡇
                         ⠈    ⠈⠓  ⠈

=head1 NAME

e - beast mode unleashed

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '1.25';

=head1 SYNOPSIS

Add a trace marker:

    $ perl -Me -e 'sub f1 { trace } sub f2 { f1 } f2'

Watch a reference for changes:

    $ perl -Me -e 'my $v = {}; sub f1 { watch( $v ) } sub f2 { f1; $v->{a} = 1 } f2'

    $ perl -Me -e '
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

Benchmark two snippets of code:

    $ perl -Me -e 'n { slow => sub{ ... }, fast => sub{ ... }}, 10000'

Launch the Runtime::Debugger:

    $ perl -Me -e 'repl'

Invoke the Tiny::Prof:

    $ perl -Me -e 'prof'

Convert a data structure to json:

    $ perl -Me -e 'say j { a => [ 1..3] }'

Convert a data structure to yaml:

    $ perl -Me -e 'say yml { a => [ 1..3] }'

Pretty print a data structure:

    $ perl -Me -e 'p { a => [ 1..3] }'

Data dump a data structure:

    $ perl -Me -e 'd { a => [ 1..3] }'

Devel::Peek dump a data structure:

    $ perl -Me -e 'dd { a => [ 1..3] }'

Print data as a table:

    $ perl -Me -e 'table( [qw(key value)], [qw(red 111)], [qw(blue 222)] )'
    +------+-------+
    | key  | value |
    +------+-------+
    | red  | 111   |
    | blue | 222   |
    +------+-------+

Encode/decode UTF-8:

    $ perl -Me -e 'printf "%#X\n", ord for split //, enc "\x{5D0}"'
    0XD7
    0X90

    $ perl -C -Me -e 'say dec "\xD7\x90"'
    $ perl -Me -e 'utf8; say dec "\xD7\x90"'
    א

=cut

=head1 DESCRIPTION

This module imports many features that make
one-liners and script debugging much faster.

It has been optimized for performance to not
import all features right away:
thereby making its startup cost quite low.

=cut

=head1 SUBROUTINES

=cut

=head2 Investigation

=head3 repl

Add a breakpoint to code.

Basically inserts a Read Evaluate Print Loop.

Enable to analyze code in the process.

    CODE ...

    # Breakpoint
    repl

    CODE ...

Simple debugger on the command line:

    $ perl -Me -e 'repl'

=head3 trace

Show a stack trace.

    trace( $depth=1 )

=head3 watch

Watch a reference for changes.

    watch( $ref, OPTIONS )

OPTIONS:

    -clone => 0,               # Will not watch cloned objects.

    -methods => "fetch",       # Monitor just this method.
    -methods => [ "fetch" ],   # Same.

    -levels  => NUM,           # How many scope levels to show.
    NUM,                       # Same.

    -raw => 1,                 # Include internal calls.
    -NUM,                      # Same.

    -message => STR,           # Message to display.
    STR,                       # Same.

=head3 prof

Profile the code from this point on.

    my $obj = prof;
    ...
    # $obj goes out of scope and builds results.

=head3 n

Benchmark and compare different pieces of code.

    Time single block of code.
    n sub{ ... };
    n sub{ ... }, 100000;

    # Compare blocks of code.
    n {
        slow => sub{ ... },
        fast => sub{ ... },
    };
    n {
        slow => sub{ ... },
        fast => sub{ ... },
    }, 10000;

=cut

=head2 Format Conversions

=head3 j

JSON Parser.

    my $bytes = j([1, 2, 3]);
    my $bytes = j({foo => 'bar'});
    my $value = j($bytes);

Encode Perl data structure or decode JSON with L<Mojo::JSON/"j">.

Convert Perl object to JSON string:

    $ perl -Me -e 'say j { a => [1..3]}'

Convert JSON string to Perl object:

    $ perl -Me -e 'p j q({"a":[1,2,3]})'

=head3 x

XML parser.

    my $dom = x('<div>Hello!</div>');

Turn HTML/XML input into L<Mojo::DOM> object.

    $ perl -Me -e 'say x("<div>hey</dev>")->at("div")->text'

=head3 yml

YAML parser.

Convert Perl object to YAML string:

    $ perl -Me -e 'say yml { a => [1..3]}'

Convert YAML string to Perl object:

    $ perl -Me -e 'p yml "---\na:\n- 1\n- 2\n- 3"'

=head3 enc

Encode UTF-8 code point to a byte stream:

    $ perl -Me -e 'printf "%#X\n", ord for split //, enc "\x{5D0}"'
    0XD7
    0X90

=head3 dec

Decode a byte steam to UTF-8 code point:

    $ perl -C -Me -e 'say dec "\xD7\x90"'
    א

=head3 utf8

Set STDOUT and STDERR as UTF-8 encoded.

=cut

=head2 Enhanced Types

=head3 b

Work with strings.

    my $stream = b('lalala');

Turn string into a L<Mojo::ByteStream> object.

    $ perl -Me -e 'b(g("mojolicious.org")->body)->html_unescape->say'

=head3 c

Work with arrays.

    my $collection = c(1, 2, 3);

Turn list into a L<Mojo::Collection> object.

=cut

=head2 Files Convenience

=head3 f

Work with files.

    my $path = f('/home/sri/foo.txt');

Turn string into a L<Mojo::File> object.

    $ perl -Me -e 'say r j f("hello.json")->slurp'

=cut

=head2 Output

=head3 say

Print with newline.

    $ perl -Me -e 'say 123'
    $ perl -Me -e 'say for 1..3'

Always sends output to the terminal even
when STDOUT and/or STDERR are redirected:

    $ perl -Me -e '
        close *STDOUT;
        close *STDERR;
        say 111;
        print "999\n";
        say 222;
    '
    111
    222

=head3 p

Pretty data printer.

    $ perl -Me -e 'p [1..3]'

=head3 np

Return pretty printer data.

    $ perl -Me -e 'my $v = np [1..3]; say "got: $v"'

Can be used with C<say> to output to the terminal
(incase STDOUT/STDERR are redirected):

    $ perl -Me -e '
        close *STDOUT;
        close *STDERR;
        say np [ 1.. 3 ];
    '

=head3 d

Data dumper.

    $ perl -Me -e 'd [1..3]'

=head3 dd

Internal data dumper.

    $ perl -Me -e 'dd [1..3]'

=head3 dye

Color a string.

    $ perl -Me -e 'say dye 123, "RED"'

=head3 table

Print data as a table:

    $ perl -Me -e 'table( [qw(key value)], [qw(red 111)], [qw(blue 222)] )'
    +------+-------+
    | key  | value |
    +------+-------+
    | red  | 111   |
    | blue | 222   |
    +------+-------+

Context sensitive!

    - Void   - output table.
    - List   - return individual lines.
    - Scalar - return entire table as a string.

=cut

=head2 Web Related

=head3 g

    my $res = g('example.com');
    my $res = g('http://example.com' => {Accept => '*/*'} => 'Hi!');
    my $res = g('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
    my $res = g('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});

Perform C<GET> request with L<Mojo::UserAgent/"get"> and return resulting L<Mojo::Message::Response> object.

    $ perl -Me -e 'say g("mojolicious.org")->dom("h1")->map("text")->join("\n")'

=head3 l

Work with URLs.

    my $url = l('https://mojolicious.org');

Turn a string into a L<Mojo::URL> object.

    $ perl -Me -e 'say l("/perldoc")->to_abs(l("https://mojolicious.org"))'

=cut

=head2 Package Tools

=head3 monkey_patch

Insert subroutines into the symbol table.

Extracted from Mojo::Util for performance.

Import methods into another function
(as done this module):

    $ perl -e 'package A; use e; sub import { my $c = caller(); monkey_patch $c, new => sub { say "Im new" } } package main; A->import; new()'
    Im new

Import methods into the same package
(probably not so useful):

    $ perl -e 'package A; use e; sub import { my $c = caller(); monkey_patch $c, new => sub { say "Im new" } } A->import; A->new()'
    Im new

Perhaps can be updated based on the outcome
of this issue:
L<https://github.com/mojolicious/mojo/pull/2173>

=head3 pod

Work with perl pod.

=head3 import

[Internal] Imports the DSL into another package.

Can be used in a sub class to import this class
plus its own commands like this:

    package e2;
    use parent qw( e );

    sub import {
        my ( $class ) = @_;
        my $class = caller;
        $class->SUPER::import( $caller );
        $class->can("monkey_patch")->(
            $caller,
            my_command_1 => sub {},
            my_command_2 => sub {},
            my_command_3 => sub {},
        );
    }

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
    my ( $class, $caller ) = @_;
    my %imported;
    $caller //= caller;

    monkey_patch(
        $caller,

        ######################################
        #          Investigation
        ######################################

        # Debugging.
        repl => sub {
            if ( !$imported{$caller}{"Runtime::Debugger"}++ ) {
                require Runtime::Debugger;
            }
            Runtime::Debugger::repl(
                levels_up => 1,
                @_,
            );
        },

        # Tracing.
        trace => sub {
            if ( !$imported{$caller}{"Data::Trace"}++ ) {
                require Data::Trace;
            }
            Data::Trace::Trace( @_ );
        },

        # Alias for trace.
        watch => sub {
            if ( !$imported{$caller}{"Data::Trace"}++ ) {
                require Data::Trace;
            }
            Data::Trace::Trace( @_ );
        },

        # Profiling.
        prof => sub {
            if ( !$imported{$caller}{"Tiny::Prof"}++ ) {
                require Tiny::Prof;
            }
            Tiny::Prof->run(
                name => 'Test',
                @_,
            );
        },

        # Benchmark/timing.
        n => sub {
            if ( !$imported{$caller}{"Benchmark"}++ ) {
                require Benchmark;
                Benchmark->import( ':hireswallclock' );
            }

            my ( $arg, $times ) = @_;
            my $subs =
                ( ref $arg eq "CODE" )
              ? { "test" => $arg }
              : $arg;
            $times //= 1;

            Benchmark::cmpthese( $times, $subs );
        },

        ######################################
        #         Format Conversions
        ######################################

        # Json.
        j => sub {
            if ( !$imported{$caller}{"Mojo::JSON"}++ ) {
                require Mojo::JSON;
            }
            Mojo::JSON::j( @_ );
        },

        # XML/HTML.
        x => sub {
            if ( !$imported{$caller}{"Mojo::DOM"}++ ) {
                require Mojo::DOM;
            }
            Mojo::DOM->new( @_ );
        },

        # YAML.
        yml => sub {
            if ( !$imported{$caller}{"YAML::XS"}++ ) {
                require YAML::XS;
            }
            my ( $thing ) = @_;
            ref $thing
              ? YAML::XS::Dump( $thing )
              : YAML::XS::Load( $thing );
        },

        # UTF-8 conversions.
        enc => sub {
            if ( !$imported{$caller}{"Encode"}++ ) {
                require Encode;
            }
            my ( $ucp ) = @_;
            Encode::encode( "UTF-8", $ucp,
                Encode::WARN_ON_ERR() | Encode::LEAVE_SRC() );
        },
        dec => sub {
            if ( !$imported{$caller}{"Encode"}++ ) {
                require Encode;
            }
            my ( $ubs ) = @_;
            Encode::decode( "UTF-8", $ubs,
                Encode::WARN_ON_ERR() | Encode::LEAVE_SRC() );
        },

        # Set UTF-8 for STDOUT and STDERR.
        utf8 => sub {
            my @fh = @_ ? @_ : ( *STDOUT, *STDERR );
            binmode $_, "encoding(UTF-8)" for @fh;
        },

        ######################################
        #          Enhanced Types
        ######################################

        # String Object.
        b => sub {
            if ( !$imported{$caller}{"Mojo::ByteStream"}++ ) {
                require Mojo::ByteStream;
            }
            Mojo::ByteStream::b( @_ );
        },

        # Array Object.
        c => sub {
            if ( !$imported{$caller}{"Mojo::Collection"}++ ) {
                require Mojo::Collection;
            }
            Mojo::Collection::c( @_ );
        },

        ######################################
        #         Files Convenience
        ######################################

        # File Object.
        f => sub {
            if ( !$imported{$caller}{"Mojo::File"}++ ) {
                require Mojo::File;
            }
            Mojo::File::path( @_ );
        },

        ######################################
        #             Output
        ######################################

        # Print.
        say => sub {
            my @args = @_ ? @_ : ( $_ );

            # Send to terminal.
            # Needs to be explicitly closed to avoid
            # issues with next say() if still closed:
            #   "say() on closed filehandle STDOUT"
            if ( !-t STDOUT ) {
                open my $tty, ">", "/dev/tty" or die $!;
                caller->can( "utf8" )->( $tty );    # Method now in caller.
                CORE::say $tty @args;
                close $tty;
            }

            # Send to output incase something expects it there.
            caller->can( "utf8" );
            CORE::say @args;
        },

        # Pretty Print.
        p => sub {
            if ( !$imported{$caller}{"Data::Printer"}++ ) {
                require Data::Printer;
                Data::Printer->import(
                    use_prototypes => 0,
                    show_dualvar   => "off",
                    hash_separator => " => ",
                    end_separator  => 1,
                    show_refcount  => 1,
                );
            }
            p( @_ );
        },
        np => sub {
            if ( !$imported{$caller}{"Data::Printer"}++ ) {
                require Data::Printer;
                Data::Printer->import(
                    use_prototypes => 0,
                    show_dualvar   => "off",
                    hash_separator => " => ",
                    end_separator  => 1,
                    show_refcount  => 1,
                );
            }
            np( @_ );
        },

        # Dumper.
        d => sub {
            if ( !$imported{$caller}{"Mojo::Util"}++ ) {
                require Mojo::Util;
            }
            print Mojo::Util::dumper( @_ );
        },

        # Dump C stuctures.
        dd => sub {
            if ( !$imported{$caller}{"Devel::Peek"}++ ) {
                require Devel::Peek;
            }
            Devel::Peek::Dump( @_ );
        },

        # Color.
        dye => sub {
            if ( !$imported{$caller}{"Term::ANSIColor"}++ ) {
                require Term::ANSIColor;
            }
            Term::ANSIColor::colored( @_ );
        },

        # Table.
        table => sub {
            if ( !$imported{$caller}{"Term::Table"}++ ) {
                require Term::Table;
            }

            my ( $header, @rows ) = @_;
            my @lines = Term::Table->new(
                header   => $header,
                rows     => \@rows,
                sanitize => 0,          # To not show \n
            )->render;

            return @lines if wantarray;
            return join "\n", @lines if defined wantarray;

            print "$_\n" for @lines;
        },

        ######################################
        #           Web Related
        ######################################

        # GET request.
        g => sub {
            if ( !$imported{$caller}{"Mojo::UserAgent"}++ ) {
                require Mojo::UserAgent;
            }
            my $UA = Mojo::UserAgent->new;
            $UA->max_redirects( 10 ) unless defined $ENV{MOJO_MAX_REDIRECTS};
            $UA->proxy->detect       unless defined $ENV{MOJO_PROXY};
            $UA->get( @_ )->result;
        },

        # URL.
        l => sub {
            if ( !$imported{$caller}{"Mojo::URL"}++ ) {
                require Mojo::URL;
            }
            Mojo::URL->new( @_ );
        },

        ######################################
        #         Package Tools
        ######################################

        monkey_patch => \&monkey_patch,

        pod => sub {
            if ( !$imported{$caller}{"App::Pod"}++ ) {
                require App::Pod;
                App::Pod->import;
            }

            local @ARGV = @_;
            App::Pod->run;
        },

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

Logo was generated using: L<https://emojicombos.com/dot-art-editor>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Tim Potapov.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)

=cut

"\x{1f42a}\x{1f977}"
