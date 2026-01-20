package main;

use 5.018;

use utf8;
use strict;
use warnings;

use Test::More;
use Venus::Test;
use Venus;
use Venus::Os;
use Venus::Path;

my $test = test(__FILE__);
my $fsds = qr/[:\\\/\.]+/;

no warnings 'once';

$Venus::Os::TYPES{$^O} = 'linux';

=encoding

utf8

=cut

=name

Venus::Os

=cut

$test->for('name');

=tagline

OS Class

=cut

$test->for('tagline');

=abstract

OS Class for Perl 5

=cut

$test->for('abstract');

=includes

method: call
method: find
method: is_bsd
method: is_cyg
method: is_dos
method: is_lin
method: is_mac
method: is_non
method: is_sun
method: is_vms
method: is_win
method: name
method: new
method: paths
method: quote
method: read
method: syscall
method: type
method: where
method: which
method: write

=cut

$test->for('includes');

=synopsis

  package main;

  use Venus::Os;

  my $os = Venus::Os->new;

  # bless({...}, 'Venus::Os')

  # my $name = $os->name;

  # "linux"

=cut

$test->for('synopsis', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $result->name, 'linux';

  $result
});

=description

This package provides methods for determining the current operating system, as
well as finding and executing files.

=cut

$test->for('description');

=inherits

Venus::Kind::Utility

=cut

$test->for('inherits');

=method call

The call method attempts to find the path to the program specified via
L</which> and dispatches to L<Venus::Path/mkcall> and returns the result. Any
exception throw is supressed and will return undefined if encountered.

=signature call

  call(string $name, string @args) (any)

=metadata call

{
  since => '2.80',
}

=cut

=example-1 call

  # given: synopsis

  package main;

  my $app = $os->is_win ? 'perl.exe' : 'perl';

  my $call = $os->call($app, '-V:osname');

  # "osname='linux';"

=cut

$test->for('example', 1, 'call', sub {
  $Venus::Os::TYPES{$^O} = $^O;
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "osname='$^O';";

  $result
});

=example-2 call

  # given: synopsis

  package main;

  my $app = $os->is_win ? 'perl.exe' : 'perl';

  my @call = $os->call($app, '-V:osname');

  # ("osname='linux';", 0)

=cut

$test->for('example', 2, 'call', sub {
  $Venus::Os::TYPES{$^O} = $^O;
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ["osname='$^O';", 0];

  @result
});

=example-3 call

  # given: synopsis

  package main;

  my $call = $os->call('nowhere');

  # undef

=cut

$test->for('example', 3, 'call', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=example-4 call

  # given: synopsis

  package main;

  my @call = $os->call($^X, '-V:osname');

  # ("osname='linux';", 0)

=cut

$test->for('example', 4, 'call', sub {
  $Venus::Os::TYPES{$^O} = $^O;
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ["osname='$^O';", 0];

  @result
});

=example-5 call

  # given: synopsis

  package main;

  my @call = $os->call($^X, 't/data/sun');

  # ("", 1)

=cut

$test->for('example', 5, 'call', sub {
  $Venus::Os::TYPES{$^O} = $^O;
  my ($tryable) = @_;
  my @result = $tryable->result;
  is_deeply [@result], ["", 1];

  @result
});

=method find

The find method searches the paths provided for a file matching the name
provided and returns all the files found as an arrayref. Returns a list in list
context.

=signature find

  find(string $name, string @paths) (arrayref)

=metadata find

{
  since => '2.80',
}

=cut

=example-1 find

  # given: synopsis

  package main;

  my $find = $os->find('cmd', 't/path/user/bin');

  # ["t/path/user/bin/cmd"]

=cut

$test->for('example', 1, 'find', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0], qr/t${fsds}path${fsds}user${fsds}bin${fsds}cmd$/;

  $result
});

=example-2 find

  # given: synopsis

  package main;

  my $find = $os->find('cmd', 't/path/user/bin', 't/path/usr/bin');

  # ["t/path/user/bin/cmd", "t/path/usr/bin/cmd"]

=cut

$test->for('example', 2, 'find', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0], qr/t${fsds}path${fsds}user${fsds}bin${fsds}cmd$/;
  like $result->[1], qr/t${fsds}path${fsds}usr${fsds}bin${fsds}cmd$/;

  $result
});

=example-3 find

  # given: synopsis

  package main;

  my $find = $os->find('zzz', 't/path/user/bin', 't/path/usr/bin');

  # []

=cut

$test->for('example', 3, 'find', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  ok !@{$result};

  $result
});

=method is_bsd

The is_bsd method returns true if the OS is either C<"freebsd"> or
C<"openbsd">, and otherwise returns false.

=signature is_bsd

  is_bsd() (boolean)

=metadata is_bsd

{
  since => '2.80',
}

=cut

=example-1 is_bsd

  # given: synopsis

  package main;

  # on linux

  my $is_bsd = $os->is_bsd;

  # false

=cut

$test->for('example', 1, 'is_bsd', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 is_bsd

  # given: synopsis

  package main;

  # on freebsd

  my $is_bsd = $os->is_bsd;

  # true

=cut

$test->for('example', 2, 'is_bsd', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'freebsd';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-3 is_bsd

  # given: synopsis

  package main;

  # on openbsd

  my $is_bsd = $os->is_bsd;

  # true

=cut

$test->for('example', 2, 'is_bsd', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'openbsd';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method is_cyg

The is_cyg method returns true if the OS is either C<"cygwin"> or C<"msys">,
and otherwise returns false.

=signature is_cyg

  is_cyg() (boolean)

=metadata is_cyg

{
  since => '2.80',
}

=cut

=example-1 is_cyg

  # given: synopsis

  package main;

  # on linux

  my $is_cyg = $os->is_cyg;

  # false

=cut

$test->for('example', 1, 'is_cyg', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 is_cyg

  # given: synopsis

  package main;

  # on cygwin

  my $is_cyg = $os->is_cyg;

  # true

=cut

$test->for('example', 2, 'is_cyg', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'cygwin';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-3 is_cyg

  # given: synopsis

  package main;

  # on msys

  my $is_cyg = $os->is_cyg;

  # true

=cut

$test->for('example', 3, 'is_cyg', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'msys';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method is_dos

The is_dos method returns true if the OS is either C<"mswin32"> or C<"dos"> or
C<"os2">, and otherwise returns false.

=signature is_dos

  is_dos() (boolean)

=metadata is_dos

{
  since => '2.80',
}

=cut

=example-1 is_dos

  # given: synopsis

  package main;

  # on linux

  my $is_dos = $os->is_dos;

  # false

=cut

$test->for('example', 1, 'is_dos', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 is_dos

  # given: synopsis

  package main;

  # on mswin32

  my $is_dos = $os->is_dos;

  # true

=cut

$test->for('example', 2, 'is_dos', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'mswin32';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-3 is_dos

  # given: synopsis

  package main;

  # on dos

  my $is_dos = $os->is_dos;

  # true

=cut

$test->for('example', 3, 'is_dos', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'dos';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-4 is_dos

  # given: synopsis

  package main;

  # on os2

  my $is_dos = $os->is_dos;

  # true

=cut

$test->for('example', 4, 'is_dos', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'os2';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method is_lin

The is_lin method returns true if the OS is C<"linux">, and otherwise returns
false.

=signature is_lin

  is_lin() (boolean)

=metadata is_lin

{
  since => '2.80',
}

=cut

=example-1 is_lin

  # given: synopsis

  package main;

  # on linux

  my $is_lin = $os->is_lin;

  # true

=cut

$test->for('example', 1, 'is_lin', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-2 is_lin

  # given: synopsis

  package main;

  # on macos

  my $is_lin = $os->is_lin;

  # false

=cut

$test->for('example', 2, 'is_lin', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'macos';
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-3 is_lin

  # given: synopsis

  package main;

  # on mswin32

  my $is_lin = $os->is_lin;

  # false

=cut

$test->for('example', 3, 'is_lin', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'mswin32';
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=method is_mac

The is_mac method returns true if the OS is either C<"macos"> or C<"darwin">,
and otherwise returns false.

=signature is_mac

  is_mac() (boolean)

=metadata is_mac

{
  since => '2.80',
}

=cut

=example-1 is_mac

  # given: synopsis

  package main;

  # on linux

  my $is_mac = $os->is_mac;

  # false

=cut

$test->for('example', 1, 'is_mac', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 is_mac

  # given: synopsis

  package main;

  # on macos

  my $is_mac = $os->is_mac;

  # true

=cut

$test->for('example', 2, 'is_mac', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'macos';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-3 is_mac

  # given: synopsis

  package main;

  # on darwin

  my $is_mac = $os->is_mac;

  # true

=cut

$test->for('example', 3, 'is_mac', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'darwin';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method is_non

The is_non method returns true if the OS is not recognized, and if recognized
returns false.

=signature is_non

  is_non() (boolean)

=metadata is_non

{
  since => '2.80',
}

=cut

=example-1 is_non

  # given: synopsis

  package main;

  # on linux

  my $is_non = $os->is_non;

  # false

=cut

$test->for('example', 1, 'is_non', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 is_non

  # given: synopsis

  package main;

  # on aix

  my $is_non = $os->is_non;

  # true

=cut

$test->for('example', 2, 'is_non', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'aix';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method is_sun

The is_sun method returns true if the OS is either C<"solaris"> or C<"sunos">,
and otherwise returns false.

=signature is_sun

  is_sun() (boolean)

=metadata is_sun

{
  since => '2.80',
}

=cut

=example-1 is_sun

  # given: synopsis

  package main;

  # on linux

  my $is_sun = $os->is_sun;

  # false

=cut

$test->for('example', 1, 'is_sun', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 is_sun

  # given: synopsis

  package main;

  # on solaris

  my $is_sun = $os->is_sun;

  # true

=cut

$test->for('example', 2, 'is_sun', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'solaris';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-3 is_sun

  # given: synopsis

  package main;

  # on sunos

  my $is_sun = $os->is_sun;

  # true

=cut

$test->for('example', 3, 'is_sun', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'sunos';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method is_vms

The is_vms method returns true if the OS is C<"vms">, and otherwise returns
false.

=signature is_vms

  is_vms() (boolean)

=metadata is_vms

{
  since => '2.80',
}

=cut

=example-1 is_vms

  # given: synopsis

  package main;

  # on linux

  my $is_vms = $os->is_vms;

  # false

=cut

$test->for('example', 1, 'is_vms', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 is_vms

  # given: synopsis

  package main;

  # on vms

  my $is_vms = $os->is_vms;

  # true

=cut

$test->for('example', 2, 'is_vms', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'vms';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method is_win

The is_win method returns true if the OS is either C<"mswin32"> or C<"dos"> or
C<"os2">, and otherwise returns false.

=signature is_win

  is_win() (boolean)

=metadata is_win

{
  since => '2.80',
}

=cut

=example-1 is_win

  # given: synopsis

  package main;

  # on linux

  my $is_win = $os->is_win;

  # false

=cut

$test->for('example', 1, 'is_win', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 0;

  !$result
});

=example-2 is_win

  # given: synopsis

  package main;

  # on mswin32

  my $is_win = $os->is_win;

  # true

=cut

$test->for('example', 2, 'is_win', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'mswin32';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-3 is_win

  # given: synopsis

  package main;

  # on dos

  my $is_win = $os->is_win;

  # true

=cut

$test->for('example', 3, 'is_win', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'dos';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=example-4 is_win

  # given: synopsis

  package main;

  # on os2

  my $is_win = $os->is_win;

  # true

=cut

$test->for('example', 4, 'is_win', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'os2';
  my $result = $tryable->result;
  is $result, 1;

  $result
});

=method name

The name method returns the OS name.

=signature name

  name() (string)

=metadata name

{
  since => '2.80',
}

=cut

=example-1 name

  # given: synopsis

  package main;

  # on linux

  my $name = $os->name;

  # "linux"

  # same as $^O

=cut

$test->for('example', 1, 'name', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "linux";

  $result
});

$Venus::Os::TYPES{$^O} = $^O;
$ENV{PATH} = join((Venus::Os->is_win ? ';' : ':'),
  map Venus::Path->new($_)->absolute, qw(
    t/path/user/local/bin
    t/path/user/bin
    t/path/usr/bin
    t/path/usr/local/bin
    t/path/usr/local/sbin
    t/path/usr/sbin
  ));

=method new

The new method constructs an instance of the package.

=signature new

  new(any @args) (Venus::Os)

=metadata new

{
  since => '4.15',
}

=cut

=example-1 new

  package main;

  use Venus::Os;

  my $new = Venus::Os->new;

  # bless(..., "Venus::Os")

=cut

$test->for('example', 1, 'new', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');

  $result
});

=method paths

The paths method returns the paths specified by the C<"PATH"> environment
variable as an arrayref of unique paths. Returns a list in list context.

=signature paths

  paths() (arrayref)

=metadata paths

{
  since => '2.80',
}

=cut

=example-1 paths

  # given: synopsis

  package main;

  my $paths = $os->paths;

  # [
  #   "/root/local/bin",
  #   "/root/bin",
  #   "/usr/local/sbin",
  #   "/usr/local/bin",
  #   "/usr/sbin:/usr/bin",
  # ]

=cut

$test->for('example', 1, 'paths', sub {
  $Venus::Os::TYPES{$^O} = $^O;
  my ($tryable) = @_;
  my $result = $tryable->result;
  my $is_win = Venus::Os->is_win;
  my $paths = [($is_win ? '.' : ()), split(($is_win ? ';' : ':'), $ENV{PATH})];
  is_deeply $result, $paths;

  $result
});

=method quote

The quote method accepts a string and returns the OS-specific quoted version of
the string.

=signature quote

  quote(string $data) (string)

=metadata quote

{
  since => '2.91',
}

=cut

=example-1 quote

  # given: synopsis

  package main;

  # on linux

  my $quote = $os->quote("hello \"world\"");

  # "'hello \"world\"'"

=cut

$test->for('example', 1, 'quote', sub {
  my ($tryable) = @_;
  $Venus::Os::TYPES{$^O} = 'linux';
  my $result = $tryable->result;
  is $result, "'hello \"world\"'";

  $result
});

=example-2 quote

  # given: synopsis

  package main;

  # on linux

  my $quote = $os->quote('hello \'world\'');

  # "'hello '\\''world'\\'''"

=cut

$test->for('example', 2, 'quote', sub {
  my ($tryable) = @_;
  $Venus::Os::TYPES{$^O} = 'linux';
  my $result = $tryable->result;
  is $result, "'hello '\\''world'\\'''";

  $result
});

=example-3 quote

  # given: synopsis

  package main;

  # on mswin32

  my $quote = $os->quote("hello \"world\"");

  # "\"hello \\"world\\"\""

=cut

$test->for('example', 3, 'quote', sub {
  my ($tryable) = @_;
  $Venus::Os::TYPES{$^O} = 'mswin32';
  my $result = $tryable->result;
  is $result, '"hello \\"world\\""';

  $result
});

=example-4 quote

  # given: synopsis

  package main;

  # on mswin32

  my $quote = $os->quote('hello "world"');

  # '"hello \"world\""'

=cut

$test->for('example', 4, 'quote', sub {
  my ($tryable) = @_;
  $Venus::Os::TYPES{$^O} = 'mswin32';
  my $result = $tryable->result;
  is $result, '"hello \"world\""';

  $result
});

=method read

The read method reads from a file, filehandle, or STDIN, and returns the data.
To read from STDIN provide the string C<"STDIN">. The method defaults to reading from STDIN.

=signature read

  read(any $from) (string)

=metadata read

{
  since => '4.15',
}

=cut

=example-1 read

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read;

  # from STDIN

  # "..."

=cut

$test->for('example', 1, 'read', sub {
  my ($tryable) = @_;
  my $input = '...';
  open my $fake_stdin, '<', \$input;
  local *STDIN = $fake_stdin;
  my $result = $tryable->result;
  is $result, '...';

  $result
});

=example-2 read

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('STDIN');

  # from STDIN

  # "..."

=cut

$test->for('example', 2, 'read', sub {
  my ($tryable) = @_;
  my $input = '...';
  open my $fake_stdin, '<', \$input;
  local *STDIN = $fake_stdin;
  my $result = $tryable->result;
  is $result, '...';

  $result
});

=example-3 read

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('t/data/texts/iso-8859-1.txt');

  # from file

  # "Hello, world! This is ISO-8859-1."

=cut

$test->for('example', 3, 'read', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Hello, world! This is ISO-8859-1.';

  $result
});

=example-4 read

  # given: synopsis

  package main;

  # on linux

  open my $fh, '<', 't/data/texts/iso-8859-1.txt';

  my $read = $os->read($fh);

  # from filehandle

  # "Hello, world! This is ISO-8859-1."

=cut

$test->for('example', 4, 'read', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Hello, world! This is ISO-8859-1.';

  $result
});

=example-5 read

  # given: synopsis

  package main;

  # on linux

  use IO::File;

  my $fh = IO::File->new('t/data/texts/iso-8859-1.txt', 'r');

  my $read = $os->read($fh);

  # from filehandle

  # "Hello, world! This is ISO-8859-1."

=cut

$test->for('example', 5, 'read', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Hello, world! This is ISO-8859-1.';

  $result
});

=example-6 read

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('t/data/texts/utf-16be.txt');

  # from UTF-16BE encoded file

  # "Hello, world! こんにちは世界！"

=cut

$test->for('example', 6, 'read', sub {
    require Encode;
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Hello, world! こんにちは世界！';

  $result
});

=example-7 read

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('t/data/texts/utf-16le.txt');

  # from UTF-16LE encoded file

  # "Hello, world! こんにちは世界！"

=cut

$test->for('example', 7, 'read', sub {
    require Encode;
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Hello, world! こんにちは世界！';

  $result
});

=example-8 read

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('t/data/texts/utf-32be.txt');

  # from UTF-32BE encoded file

  # "Hello, world! こんにちは世界！"

=cut

$test->for('example', 8, 'read', sub {
    require Encode;
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Hello, world! こんにちは世界！';

  $result
});

=example-9 read

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('t/data/texts/utf-32le.txt');

  # from UTF-32LE encoded file

  # "Hello, world! こんにちは世界！"

=cut

$test->for('example', 9, 'read', sub {
    require Encode;
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Hello, world! こんにちは世界！';

  $result
});

=example-10 read

  # given: synopsis

  package main;

  # on linux

  my $read = $os->read('t/data/texts/utf-8.txt');

  # from UTF-8 encoded file

  # "Hello, world! こんにちは世界！"

=cut

$test->for('example', 10, 'read', sub {
    require Encode;
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, 'Hello, world! こんにちは世界！';

  $result
});

=method syscall

The syscall method executes the command and arguments provided, via
L<perlfunc/system>, and returns the invocant.

=signature syscall

  syscall(any @data) (Venus::Os)

=metadata syscall

{
  since => '4.15',
}

=cut

=example-1 syscall

  package main;

  use Venus::Os;

  my $os = Venus::Os->new;

  $os->syscall($^X, '--help');

  # bless(..., "Venus::Os")

=cut

$test->for('example', 1, 'syscall', sub {
  my ($tryable) = @_;
  require Venus::Space;
  my $patched = Venus::Space->new('Venus::Os')->patch('_system', sub{0});
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  $patched->unpatch;

  $result
});

=example-2 syscall

  package main;

  use Venus::Os;

  my $os = Venus::Os->new;

  $os->syscall('.help');

  # Exception! (isa Venus::Os::Error) (see error_on_system_call)

=cut

$test->for('example', 2, 'syscall', sub {
  plan skip_all => 'skip Os#syscall on win32' if $^O =~ /win32/i;
  my ($tryable) = @_;
  require Venus::Space;
  my $patched = Venus::Space->new('Venus::Os')->patch('_system', sub{1});
  ok my $result = $tryable->error(\my $error)->safe('result');
  ok $error->isa('Venus::Os::Error');
  ok $error->isa('Venus::Error');
  $patched->unpatch;

  $result
});

=method type

The type method returns a string representing the "test" method, which
identifies the OS, that would return true if called, based on the name of the
OS.

=signature type

  type() (string)

=metadata type

{
  since => '2.80',
}

=cut

=example-1 type

  # given: synopsis

  package main;

  # on linux

  my $type = $os->type;

  # "is_lin"

=cut

$test->for('example', 1, 'type', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  is $result, "is_lin";

  $result
});

=example-2 type

  # given: synopsis

  package main;

  # on macos

  my $type = $os->type;

  # "is_mac"

=cut

$test->for('example', 2, 'type', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'macos';
  my $result = $tryable->result;
  is $result, "is_mac";

  $result
});

=example-3 type

  # given: synopsis

  package main;

  # on mswin32

  my $type = $os->type;

  # "is_win"

=cut

$test->for('example', 3, 'type', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'mswin32';
  my $result = $tryable->result;
  is $result, "is_win";

  $result
});

=example-4 type

  # given: synopsis

  package main;

  # on openbsd

  my $type = $os->type;

  # "is_bsd"

=cut

$test->for('example', 4, 'type', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'openbsd';
  my $result = $tryable->result;
  is $result, "is_bsd";

  $result
});

=example-5 type

  # given: synopsis

  package main;

  # on cygwin

  my $type = $os->type;

  # "is_cyg"

=cut

$test->for('example', 5, 'type', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'cygwin';
  my $result = $tryable->result;
  is $result, "is_cyg";

  $result
});

=example-6 type

  # given: synopsis

  package main;

  # on dos

  my $type = $os->type;

  # "is_win"

=cut

$test->for('example', 6, 'type', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'dos';
  my $result = $tryable->result;
  is $result, "is_win";

  $result
});

=example-7 type

  # given: synopsis

  package main;

  # on solaris

  my $type = $os->type;

  # "is_sun"

=cut

$test->for('example', 7, 'type', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'solaris';
  my $result = $tryable->result;
  is $result, "is_sun";

  $result
});

=example-8 type

  # given: synopsis

  package main;

  # on vms

  my $type = $os->type;

  # "is_vms"

=cut

$test->for('example', 8, 'type', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  local %Venus::Os::TYPES; $Venus::Os::TYPES{$^O} = 'vms';
  my $result = $tryable->result;
  is $result, "is_vms";

  $result
});

=method where

The where method searches the paths defined by the C<PATH> environment variable
for a file matching the name provided and returns all the files found as an
arrayref. Returns a list in list context. This method doesn't check (or care)
if the files found are actually executable.

=signature where

  where(string $file) (arrayref)

=metadata where

{
  since => '2.80',
}

=cut

=example-1 where

  # given: synopsis

  package main;

  my $where = $os->where('cmd');

  # [
  #   "t/path/user/local/bin/cmd",
  #   "t/path/user/bin/cmd",
  #   "t/path/usr/bin/cmd",
  #   "t/path/usr/local/bin/cmd",
  #   "t/path/usr/local/sbin/cmd",
  #   "t/path/usr/sbin/cmd"
  # ]

=cut

$test->for('example', 1, 'where', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0], qr/t${fsds}path${fsds}user${fsds}local${fsds}bin${fsds}cmd$/;
  like $result->[1], qr/t${fsds}path${fsds}user${fsds}bin${fsds}cmd$/;
  like $result->[2], qr/t${fsds}path${fsds}usr${fsds}bin${fsds}cmd$/;
  like $result->[3], qr/t${fsds}path${fsds}usr${fsds}local${fsds}bin${fsds}cmd$/;
  like $result->[4], qr/t${fsds}path${fsds}usr${fsds}local${fsds}sbin${fsds}cmd$/;
  like $result->[5], qr/t${fsds}path${fsds}usr${fsds}sbin${fsds}cmd$/;

  $result
});

=example-2 where

  # given: synopsis

  package main;

  my $where = $os->where('app1');

  # [
  #   "t/path/user/local/bin/app1",
  #   "t/path/usr/bin/app1",
  #   "t/path/usr/sbin/app1"
  # ]

=cut

$test->for('example', 2, 'where', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0], qr/t${fsds}path${fsds}user${fsds}local${fsds}bin${fsds}app1$/;
  like $result->[1], qr/t${fsds}path${fsds}usr${fsds}bin${fsds}app1$/;
  like $result->[2], qr/t${fsds}path${fsds}usr${fsds}sbin${fsds}app1$/;

  $result
});

=example-3 where

  # given: synopsis

  package main;

  my $where = $os->where('app2');

  # [
  #   "t/path/user/local/bin/app2",
  #   "t/path/usr/bin/app2",
  # ]

=cut

$test->for('example', 3, 'where', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0], qr/t${fsds}path${fsds}user${fsds}local${fsds}bin${fsds}app2$/;
  like $result->[1], qr/t${fsds}path${fsds}usr${fsds}bin${fsds}app2$/;

  $result
});

=example-4 where

  # given: synopsis

  package main;

  my $where = $os->where('app3');

  # [
  #   "t/path/user/bin/app3",
  #   "t/path/usr/sbin/app3"
  # ]

=cut

$test->for('example', 4, 'where', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0], qr/t${fsds}path${fsds}user${fsds}bin${fsds}app3$/;
  like $result->[1], qr/t${fsds}path${fsds}usr${fsds}sbin${fsds}app3$/;

  $result
});

=example-5 where

  # given: synopsis

  package main;

  my $where = $os->where('app4');

  # [
  #   "t/path/user/local/bin/app4",
  #   "t/path/usr/local/bin/app4",
  #   "t/path/usr/local/sbin/app4",
  # ]

=cut

$test->for('example', 5, 'where', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok ref $result eq 'ARRAY';
  like $result->[0], qr/t${fsds}path${fsds}user${fsds}local${fsds}bin${fsds}app4$/;
  like $result->[1], qr/t${fsds}path${fsds}usr${fsds}local${fsds}bin${fsds}app4$/;
  like $result->[2], qr/t${fsds}path${fsds}usr${fsds}local${fsds}sbin${fsds}app4$/;

  $result
});

=example-6 where

  # given: synopsis

  package main;

  my $where = $os->where('app5');

  # []

=cut

$test->for('example', 6, 'where', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  is_deeply $result, [];

  $result
});

=method which

The which method returns the first match from the result of calling the
L</where> method with the arguments provided.

=signature which

  which(string $file) (string)

=metadata which

{
  since => '2.80',
}

=cut

=example-1 which

  # given: synopsis

  package main;

  my $which = $os->which('cmd');

  # "t/path/user/local/bin/cmd",

=cut

$test->for('example', 1, 'which', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result =~ m{t${fsds}path${fsds}user${fsds}local${fsds}bin${fsds}cmd$};

  $result
});

=example-2 which

  # given: synopsis

  package main;

  my $which = $os->which('app1');

  # "t/path/user/local/bin/app1"

=cut

$test->for('example', 2, 'which', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result =~ m{t${fsds}path${fsds}user${fsds}local${fsds}bin${fsds}app1$};

  $result
});

=example-3 which

  # given: synopsis

  package main;

  my $which = $os->which('app2');

  # "t/path/user/local/bin/app2"

=cut

$test->for('example', 3, 'which', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result =~ m{t${fsds}path${fsds}user${fsds}local${fsds}bin${fsds}app2$};

  $result
});

=example-4 which

  # given: synopsis

  package main;

  my $which = $os->which('app3');

  # "t/path/user/bin/app3"

=cut

$test->for('example', 4, 'which', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result =~ m{t${fsds}path${fsds}user${fsds}bin${fsds}app3$};

  $result
});

=example-5 which

  # given: synopsis

  package main;

  my $which = $os->which('app4');

  # "t/path/user/local/bin/app4"

=cut

$test->for('example', 5, 'which', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result =~ m{t${fsds}path${fsds}user${fsds}local${fsds}bin${fsds}app4$};

  $result
});

=example-6 which

  # given: synopsis

  package main;

  my $which = $os->which('app5');

  # undef

=cut

$test->for('example', 6, 'which', sub {
  $Venus::Os::TYPES{$^O} = 'linux';
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok !defined $result;

  !$result
});

=method write

The write method writes to a file, filehandle, STDOUT, or STDERR, and returns
the invocant. To write to STDOUT provide the string C<"STDOUT">. To write to
STDERR provide the string C<"STDERR">. The method defaults to writing to
STDOUT.

=signature write

  write(any $into, string $data, string $encoding) (Venus::Os)

=metadata write

{
  since => '4.15',
}

=cut

=example-1 write

  # given: synopsis

  package main;

  # on linux

  my $write = $os->write;

  # to STDOUT

  # ''

  # bless(..., "Venus::Os")

=cut

$test->for('example', 1, 'write', sub {
  my ($tryable) = @_;
  my $output;
  open my $fake_stdout, '>', \$output;
  local *STDOUT = $fake_stdout;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $output, undef;

  $result
});

=example-2 write

  # given: synopsis

  package main;

  # on linux

  my $write = $os->write(undef, '');

  # to STDOUT

  # ''

  # bless(..., "Venus::Os")

=cut

$test->for('example', 2, 'write', sub {
  my ($tryable) = @_;
  my $output;
  open my $fake_stdout, '>', \$output;
  local *STDOUT = $fake_stdout;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $output, undef;

  $result
});

=example-3 write

  # given: synopsis

  package main;

  # on linux

  my $write = $os->write('STDOUT');

  # to STDOUT

  # ''

  # bless(..., "Venus::Os")

=cut

$test->for('example', 3, 'write', sub {
  my ($tryable) = @_;
  my $output;
  open my $fake_stdout, '>', \$output;
  local *STDOUT = $fake_stdout;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $output, undef;

  $result
});

=example-4 write

  # given: synopsis

  package main;

  # on linux

  my $write = $os->write('STDOUT', '...');

  # to STDOUT

  # '...'

  # bless(..., "Venus::Os")

=cut

$test->for('example', 4, 'write', sub {
  my ($tryable) = @_;
  my $output;
  open my $fake_stdout, '>', \$output;
  local *STDOUT = $fake_stdout;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $output, '...';

  $result
});

=example-5 write

  # given: synopsis

  package main;

  # on linux

  my $write = $os->write('STDERR');

  # to STDERR

  # ''

  # bless(..., "Venus::Os")

=cut

$test->for('example', 5, 'write', sub {
  my ($tryable) = @_;
  my $output;
  open my $fake_stderr, '>', \$output;
  local *STDERR = $fake_stderr;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $output, undef;

  $result
});

=example-6 write

  # given: synopsis

  package main;

  # on linux

  my $write = $os->write('STDERR', '...');

  # to STDERR

  # '...'

  # bless(..., "Venus::Os")

=cut

$test->for('example', 6, 'write', sub {
  my ($tryable) = @_;
  my $output;
  open my $fake_stderr, '>', \$output;
  local *STDERR = $fake_stderr;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $output, '...';

  $result
});

=example-7 write

  # given: synopsis

  package main;

  # on linux

  my $file = 't/data/texts/iso-8859-1.txt';

  my $write = $os->write($file, 'Hello, world! This is ISO-8859-1.');

  # to file

  # "Hello, world! This is ISO-8859-1."

  # bless(..., "Venus::Os")

=cut

$test->for('example', 7, 'write', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $result->read('t/data/texts/iso-8859-1.txt'),
    'Hello, world! This is ISO-8859-1.';

  $result
});

=example-8 write

  # given: synopsis

  package main;

  # on linux

  open my $fh, '<', 't/data/texts/iso-8859-1.txt';

  my $write = $os->write($fh, 'Hello, world! This is ISO-8859-1.');

  # to file

  # "Hello, world! This is ISO-8859-1."

  # bless(..., "Venus::Os")

=cut

$test->for('example', 8, 'write', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $result->read('t/data/texts/iso-8859-1.txt'), 'Hello, world! This is ISO-8859-1.';

  $result
});

=example-9 write

  # given: synopsis

  package main;

  # on linux

  use IO::File;

  my $fh = IO::File->new('t/data/texts/iso-8859-1.txt', 'w');

  my $write = $os->write($fh, 'Hello, world! This is ISO-8859-1.');

  # to ISO-8859-1 encoded file

  # "Hello, world! This is ISO-8859-1."

  # bless(..., "Venus::Os")

=cut

$test->for('example', 9, 'write', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $result->read('t/data/texts/iso-8859-1.txt'), 'Hello, world! This is ISO-8859-1.';

  $result
});

=example-10 write

  # given: synopsis

  package main;

  # on linux

  my $file = 't/data/texts/utf-16be.txt';

  my $write = $os->write($file, 'Hello, world! こんにちは世界！', 'UTF-16BE');

  # to UTF-16BE encoded file

  # "Hello, world! こんにちは世界！"

  # bless(..., "Venus::Os")

=cut

$test->for('example', 10, 'write', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $result->read('t/data/texts/utf-16be.txt'),
    'Hello, world! こんにちは世界！';

  $result
});

=example-11 write

  # given: synopsis

  package main;

  # on linux

  my $file = 't/data/texts/utf-16le.txt';

  my $write = $os->write($file, 'Hello, world! こんにちは世界！', 'UTF-16LE');

  # to UTF-16LE encoded file

  # "Hello, world! こんにちは世界！"

  # bless(..., "Venus::Os")

=cut

$test->for('example', 11, 'write', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $result->read('t/data/texts/utf-16le.txt'),
    'Hello, world! こんにちは世界！';

  $result
});

=example-12 write

  # given: synopsis

  package main;

  # on linux

  my $file = 't/data/texts/utf-32be.txt';

  my $write = $os->write($file, 'Hello, world! こんにちは世界！', 'UTF-32BE');

  # to UTF-32BE encoded file

  # "Hello, world! こんにちは世界！"

  # bless(..., "Venus::Os")

=cut

$test->for('example', 12, 'write', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $result->read('t/data/texts/utf-32be.txt'),
    'Hello, world! こんにちは世界！';

  $result
});

=example-13 write

  # given: synopsis

  package main;

  # on linux

  my $file = 't/data/texts/utf-32le.txt';

  my $write = $os->write($file, 'Hello, world! こんにちは世界！', 'UTF-32LE');

  # to UTF-32LE encoded file

  # "Hello, world! こんにちは世界！"

  # bless(..., "Venus::Os")

=cut

$test->for('example', 13, 'write', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $result->read('t/data/texts/utf-32le.txt'),
    'Hello, world! こんにちは世界！';

  $result
});

=example-14 write

  # given: synopsis

  package main;

  # on linux

  my $file = 't/data/texts/utf-8.txt';

  my $write = $os->write($file, 'Hello, world! こんにちは世界！', 'UTF-8');

  # to UTF-8 encoded file

  # "Hello, world! こんにちは世界！"

  # bless(..., "Venus::Os")

=cut

$test->for('example', 14, 'write', sub {
  my ($tryable) = @_;
  my $result = $tryable->result;
  ok $result->isa('Venus::Os');
  is $result->read('t/data/texts/utf-8.txt'),
    'Hello, world! こんにちは世界！';

  $result
});

=raise read Venus::Os::Error on.read.open.file

  # given: synopsis;

  $os->read('/path/to/nowhere');

  # Error! (on.read.open.file)

=cut

$test->for('raise', 'read', 'Venus::Os::Error', 'on.read.open.file', sub {
  my ($tryable) = @_;

  $test->is_error(my $error = $tryable->error->result);

  $error
});

=raise write Venus::Os::Error on.write.open.file

  # given: synopsis;

  $os->write('/path/to/nowhere/file.txt', 'content');

  # Error! (on.write.open.file)

=cut

$test->for('raise', 'write', 'Venus::Os::Error', 'on.write.open.file', sub {
  my ($tryable) = @_;

  $test->is_error(my $error = $tryable->error->result);

  $error
});

=partials

t/Venus.t: present: authors
t/Venus.t: present: license

=cut

$test->for('partials');

# END

$test->render('lib/Venus/Os.pod') if $ENV{VENUS_RENDER};

ok 1 and done_testing;
