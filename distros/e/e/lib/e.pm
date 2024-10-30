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
                 ⠸⢿⡍⠛⠻⠿⠿⠿⠋⣠⡾⢋⣾⣏⣸⣷⡸⣇⢰⠟⠛⠻⡄  v1.32
                   ⢻⡄   ⠐⠚⠋⣠⡾⣧⣿⠁⠙⢳⣽⡟
                   ⠈⠳⢦⣤⣤⣀⣤⡶⠛ ⠈⢿⡆  ⢿⡇
                         ⠈    ⠈⠓  ⠈

=head1 NAME

e - beast mode unleashed

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '1.32';

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

Create a breakpoint in code:

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

And much, much more ...

=cut

=head1 DESCRIPTION

This module imports many features that make
one-liners and script debugging much faster.

It has been optimized for performance to not
import all features right away:
thereby making its startup cost quite low.

=head2 How to Import

This module will overwrite existing methods
of the same name (which triggers a warning)!

Should this happen and it is not desired,
simply import this module first.

Should you prefer the methods in this module,
import this module last (if needed, at the end
of the file).

=cut

=head1 SUBROUTINES

=cut

=head2 Investigation

=head3 repl

Add a breakpoint using L<Runtime::Debugger>.

Basically inserts a Read Evaluate Print Loop.

Version 0 was basically:

    while ( 1 ) {
        my $input = <STDIN>;
        last if $input eq 'q';
        eval "$input";
    }

(Much more powerful since then).

Enable to analyze code in the process.

    CODE ...

    # Breakpoint
    use e;
    repl

    CODE ...

Simple debugger on the command line:

    $ perl -Me -e 'repl'

=head3 trace

Show a stack trace.

    trace( OPTIONS )

OPTIONS:

    -levels  => NUM,           # How many scope levels to show.
    NUM,                       # Same.

    -raw => 1,                 # Include internal calls.
    -NUM,                      # Same.

    -message => STR,           # Message to display.
    STR,                       # Same.

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

    $ perl -Me -e '$v = 333; n { concat => sub { 111 . $v }, interp => sub { "111$v" }, list => sub { 111,$v } }, 100000000'

              Rate interp concat   list
    interp  55248619/s     --    -6%   -62%
    concat  58479532/s     6%     --   -60%
    list   144927536/s   162%   148%     --

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

Force HTML semantics:

    $ perl -Me -e 'say x->xml(0)->parse("<Tag>Name</Tag>")'
    <tag>Name</tag>

Force XML semantics (case sensitive tags and more):

    $ perl -Me -e 'say x->xml(1)->parse("<Tag>Name</Tag>")'
    <Tag>Name</Tag>

=head3 yml

YAML parser.

Convert Perl object to YAML string:

    $ perl -Me -e 'say yml { a => [1..3]}'

Convert YAML string to Perl object:

    $ perl -Me -e 'p yml "---\na:\n- 1\n- 2\n- 3"'

=head3 clone

Storable's deep clone.

    $ perl -Me -e '
        my $arr1   = [ 1..3 ];
        my $arr2   = clone $arr1;
        $arr2->[0] = 111;

        say $arr1;
        p $arr1;

        say "";
        say $arr2;
        p $arr2;
    '

    # Output:
    ARRAY(0x5d0b8a408518)
    [
        [0] 1,
        [1] 2,
        [2] 3,
    ]

    ARRAY(0x5d0b8a42d9e0)
    [
        [0] 111,
        [1] 2,
        [2] 3,
    ]

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

If given a filehandle, will set the encoding
for it to UTF-8.

    utf8($fh);

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

=head3 set

Work with sets.

    my $set = set(2,4,6,4);

Turn list into a L<Set::Scalar> object.

    $ perl -Me -e 'say set(2,4,6,2)'
    (2 4 6)

Get elements:

    $ perl -Me -e 'say for sort(set(2,4,6,2)->elements)'
    $ perl -Me -e 'say for sort(set(2,4,6,2)->@*)'
    2
    4
    6

Check for existence of an element:

    $ perl -Me -e 'say set(2,4,6,2)->has(7)'
    $ perl -Me -e 'say set(2,4,6,2)->has(4)'
    1

Intersection:

    $ perl -Me -e 'say set(2,4,6,2) * set(3,4,5,6)'
    (4 6)

Create a new universe:

    # Universe 1:
    # ...
    Set::Scalar::Universe->new->enter;
    # Universe 2:
    # ...

Operations:

    set                         value

    $a                          (a b c d e _ _ _ _)
    $b                          (_ _ c d e f g _ _)
    $c                          (_ _ _ _ e f g h i)

    union:        $a + $b       (a b c d e f g _ _)
    union:        $a + $b + $c  (a b c d e f g h i)
    intersection: $a * $b       (_ _ c d e _ _ _ _)
    intersection: $a * $b * $c  (_ _ _ _ e _ _ _ _)
    difference:   $a - $b       (a b _ _ _ _ _ _ _)
    difference:   $a - $b - $c  (a b _ _ _ _ _ _ _)
    unique:       $a % $b       (a b _ _ _ f g _ _)
    symm_diff:    $a / $b       (a b _ _ _ f g _ _)
    complement:   -$a           (_ _ c d e f g h i)

=cut

=head2 Files Convenience

=head3 f

Work with files.

    my $path = f('/home/sri/foo.txt');

Turn string into a L<Mojo::File> object.

    $ perl -Me -e 'say r j f("hello.json")->slurp'

=cut

=head2 List Support

=head3 max

Get the biggest number in a list.

    $ perl -Me -e 'say max 2,4,1,3'
    4

=head3 min

Get the smallest number in a list.

    $ perl -Me -e 'say max 2,4,1,3'
    1

=head3 sum

Adds a list of numbers.

    $ perl -Me -e 'say sum 1..10'
    55

=head3 uniq

Get the unique values in a list.

    $ perl -Me -e 'say for uniq 2,4,4,6'
    2
    4
    6

=cut

=head2 Output

=head3 say

Obnoxious print with a newline.

    $ perl -Me -e 'say 123'
    $ perl -Me -e 'say for 1..3'

Always sends output to the terminal even
when STDOUT and/or STDERR are redirected:

    $ perl -Me -e '
        say "Shown before";
        close *STDOUT;
        close *STDERR;
        say "Shown with no stdout/err";
        print "Print not seen\n";
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

=head3 post

    my $res = post('example.com');
    my $res = post('http://example.com' => {Accept => '*/*'} => 'Hi!');
    my $res = post('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
    my $res = post('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});

Perform C<POST> request with L<Mojo::UserAgent/"get"> and return resulting L<Mojo::Message::Response> object.

    $ perl -Me -e 'say post("mojolicious.org")->dom("h1")->map("text")->join("\n")'

=head3 l

Work with URLs.

    my $url = l('https://mojolicious.org');

Turn a string into a L<Mojo::URL> object.

    $ perl -Me -e 'say l("/perldoc")->to_abs(l("https://mojolicious.org"))'

=cut

=head2 Asynchronous

This sector includes commands to run asynchronous
(or pseudo-async) operations.

It is not entirely clear which method to always use.

C<runf> limits to number of action or 20 (whichever is smaller).

C<runt> and C<runio> have no such limits.

Typically using threads (with C<runt>) seems to be fastest.

Some statistics using different run commands:

    $ gitb status -d
           s/iter   runt  runio   runf series
    runt     1.74     --   -35%   -59%   -74%
    runio    1.12    55%     --   -36%   -59%
    runf    0.716   142%    56%     --   -36%
    series  0.456   281%   146%    57%     --

    $ gitb branch -d
              Rate   runt   runf series  runio
    runt   0.592/s     --   -71%   -81%   -83%
    runf    2.02/s   240%     --   -34%   -42%
    series  3.05/s   415%    51%     --   -12%
    runio   3.47/s   486%    72%    14%     --

    $ gitb pull -d
           s/iter  runio series   runt   runf
    runio    4.27     --    -7%   -21%   -33%
    series   3.97     8%     --   -15%   -28%
    runt     3.38    26%    17%     --   -15%
    runf     2.87    49%    38%    18%     --

=head3 runf

Run tasks in parallel using L<Parallel::ForkManager>.

Returns the results.

    $ perl -Me -e '
        p {
            runf
            map {
                my $n = $_;
                sub{ $n => $n**2 };
            } 1..5
        }
    '
    {
        1 => 1,
        2 => 4,
        3 => 9,
        4 => 16,
        5 => 25,
    }

Takes much overhead to start up!

Will use up to 20 processes.

=head3 runio

Run tasks in parallel using L<Mojo::IOLoop>.

Returns the results.

    $ perl -Me -e '
        p {
            runio
            map {
                my $n = $_;
                sub{ $n => $n**2 };
            } 1..5
        }
    '
    {
        1 => 1,
        2 => 4,
        3 => 9,
        4 => 16,
        5 => 25,
    }

This is apparently better to use for IO related tasks.

=head3 runt

Run tasks in parallel using L<threads>.

Returns the results.

    $ perl -Me -e '
        p {
            runt
            map {
                my $n = $_;
                sub{ $n => $n**2 };
            } 1..5
        }
    '
    {
        1 => 1,
        2 => 4,
        3 => 9,
        4 => 16,
        5 => 25,
    }

This is the fastest run* command usually.

=cut

=head2 Package Tools

=head3 monkey_patch

Insert subroutines into the symbol table.

Extracted from Mojo::Util for performance.

Imports method(s) into another package
(as done in this module):

Take a look at the import method for an example.

=head3 pod

Work with perl pod.

=head3 import

Imports a DSL into another package.

Can be used in a sub class to import this class
plus its own commands like this:

    package e2;
    use parent qw( e );

    sub import {
        shift->SUPER::import(
            scalar caller,
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
    my ( $class, $caller, %extra ) = @_;
    my %imported;    # Require only once a package.
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

        # Storable's deep clone.
        clone => sub {
            if ( !$imported{$caller}{"Storable"}++ ) {
                require Storable;
            }
            Storable::dclone( $_[0] );
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

        # Array Object.
        set => sub {
            if ( !$imported{$caller}{"Set::Scalar"}++ ) {
                require Set::Scalar;
            }
            Set::Scalar->new( @_ );
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
        #            List Support
        ######################################

        max => sub {
            if ( !$imported{$caller}{"List::Util"}++ ) {
                require List::Util;
            }

            List::Util::max( @_ );
        },

        min => sub {
            if ( !$imported{$caller}{"List::Util"}++ ) {
                require List::Util;
            }

            List::Util::min( @_ );
        },

        sum => sub {
            if ( !$imported{$caller}{"List::Util"}++ ) {
                require List::Util;
            }

            List::Util::sum( @_ );
        },

        uniq => sub {
            if ( !$imported{$caller}{"List::Util"}++ ) {
                require List::Util;
            }

            # Since uniq is missing in some recent versions.
            if ( List::Util->can( "uniq" ) ) {
                List::Util::uniq( @_ );
            }
            else {
                my %h;
                grep { !$h{$_}++ } @_;
            }
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
                if ( open my $tty, ">", "/dev/tty" ) {
                    caller->can( "utf8" )->( $tty );    # Method now in caller.
                    my $prefix =
                      caller->can( "dye" )->( "no-stdout: ", "CYAN" );
                    CORE::say( $tty $prefix, @args );
                    close $tty;
                }
            }

            # Send to output incase something expects it there.
            caller->can( "utf8" )->();
            CORE::say( @args );

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
                sanitize => 0,         # To not show \n
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
            my $ua = Mojo::UserAgent->new;
            $ua->max_redirects( 10 ) unless defined $ENV{MOJO_MAX_REDIRECTS};
            $ua->proxy->detect       unless defined $ENV{MOJO_PROXY};
            $ua->get( @_ )->result;
        },

        # POST Request.
        post => sub {
            if ( !$imported{$caller}{"Mojo::UserAgent"}++ ) {
                require Mojo::UserAgent;
            }
            my $ua = Mojo::UserAgent->new;
            $ua->max_redirects( 10 ) unless defined $ENV{MOJO_MAX_REDIRECTS};
            $ua->proxy->detect       unless defined $ENV{MOJO_PROXY};
            $ua->post( @_ )->result;
        },

        # URL.
        l => sub {
            if ( !$imported{$caller}{"Mojo::URL"}++ ) {
                require Mojo::URL;
            }
            Mojo::URL->new( @_ );
        },

        ######################################
        #           Asynchronous
        ######################################

        runio => sub {
            if ( !$imported{$caller}{"Mojo::IOLoop"}++ ) {
                require Mojo::IOLoop;
            }

            my $ioloop = Mojo::IOLoop->new;
            my @res;

            for my $cb ( @_ ) {
                $ioloop->timer( 0 => sub { push @res, $cb->() } );
            }

            $ioloop->start;

            @res;
        },

        runf => sub {
            if ( !$imported{$caller}{"Parallel::ForkManager"}++ ) {
                require Parallel::ForkManager;
            }

            my $MAX_PROCESSES = 20;
            my $processes     = ( @_ > $MAX_PROCESSES ) ? $MAX_PROCESSES : @_;
            my $pm            = Parallel::ForkManager->new( $processes );
            my @res;

            $pm->run_on_finish(
                sub {
                    push @res, @{ $_[-1] };
                }
            );
            for my $cb ( @_ ) {
                $pm->start and next;
                $pm->finish( 0, [ $cb->() ] );
            }
            $pm->wait_all_children;

            @res;
        },

        runt => sub {
            if ( !$imported{$caller}{"Config"}++ ) {
                require Config;
            }

            if ( !$Config::Config{useithreads} ) {
                die "Threading not supported!\n";
            }

            if ( !$imported{$caller}{"threads"}++ ) {
                require threads;
            }

            map { $_->join }
            map { threads->create( $_ ) } @_;
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

        ######################################
        #           Extra Methods
        ######################################

        # Make it easier to subclass.
        %extra,

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
