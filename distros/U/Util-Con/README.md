# NAME

Util::Con - Small everyday helpers: directory listing, shell commands, JSON files, number formatting, and data-structure shapes

# Synopsis

    use Util::Con;

    my @scripts = dir(dir => '.', regex => '\.pl$', recursive => 1);
    my $branch  = execute('git rev-parse --abbrev-ref HEAD', 'stdout');
    my $text    = file2string('notes.txt');
    print format_commas(1234567.891), "\n";   # 1,234,567.89

    my $data = json_file_to_ref('results.json');
    ref_to_json_file($data, 'copy.json');

    st $data;    # print the shape of $data, not its values
    p  $data;    # Data::Printer's p(), loaded on first use

# Description

`Util::Con` is a collection of the functions I reach for in nearly every script: listing a directory with file tests and a regex, running a shell command and keeping its output, slurping a file, reading and writing JSON, putting commas in a number, and seeing the *shape* of a large data structure without scrolling through every value in it.

Loading it is meant to be cheap.  Everything that is not needed to compile the caller is loaded the first time a function needs it, so a script that only calls `format_commas` does not pay for `JSON::MaybeXS`, `Capture::Tiny` or `Data::Printer`.

## What `use Util::Con` does

Besides exporting the ten functions below, `use Util::Con` does three things to the file and package that loads it:

* It turns on `autodie ':default'` in that file, from the `use` line onward, so a bare `open` or `close` that fails dies with a message rather than returning false.
* It gives that package `p` and `np` from `Data::Printer` (`DDP`).  They are stubs until first called, so `DDP` is loaded only by a script that prints something.  A `p` or `np` the package already has, such as one from an earlier `use DDP`, is left alone.
* It loads `Devel::Confess`, which is process-wide: every `die` and `warn` in the program carries a stack trace.

`use Util::Con ();` imports nothing and skips the first two; `Devel::Confess` is still loaded.  `use Util::Con 'format_commas';` imports only the names given, and still does all three.

# Functions

All functions are exported by default.

## dir

    my @files = dir(dir => '/data', regex => '\.csv$');
    my @tree  = dir(dir => '/data', regex => '\.csv$', recursive => 1, cpu => 8);
    dir(dir => '/data', recursive => 1, on_match => sub { say $_[0] });

Returns the paths under `dir` whose base name matches `regex` and that pass every file test in `tests`.  The paths are `dir` joined to the entry with `/`; with the default `dir => '.'`, the leading `./` is left off.  `.` and `..` are never returned.

It takes these named arguments:

* `dir` (default `.`): The directory to list.  Trailing slashes are removed, but `/` stays `/`.
* `regex` (default `.`): A pattern the base name must match, given as a string or a `qr//`.  An invalid pattern dies, naming it.
* `tests` (default `f`): One or more of perl's file tests, as letters: `rwxoRWXOezsfdlpSbcugkTB`.  Every one must pass.  `'d'` lists directories; `''` applies no test at all.
* `recursive` (default `0`): `1` descends into subdirectories, through `File::Find`, without following symbolic links.
* `cpu` (default `1`): For a recursive listing, the number of worker processes (through `Parallel::ForkManager`).  Ignored when `recursive` is `0`.
* `on_match` (no default): A code reference called with each path as it is found; `dir` then returns an empty list, so a very large tree is never held in memory.

The file tests share one `stat` per path, so asking for four of them costs no more than asking for one.  `-l` is checked first, with `lstat`.

With `cpu` greater than 1, `dir` walks the tree breadth-first until one level holds four directories per worker, then shares those directories out.  The results are the same as a serial walk, in a different order.  `on_match` still runs in the calling process, so it can change the caller's variables, but it is called once a worker's whole batch arrives rather than as each file is found.

An unknown argument, a letter that is not a file test, a `cpu` that is not a positive integer, and a directory that cannot be opened all die.

## execute

    my $exit   = execute('make test');                  # 0, or dies
    my $out    = execute('git log -1 --format=%H', 'stdout');
    my $err    = execute('perl -c script.pl', 'stderr');
    my $all    = execute('ls /nonexistent', 'all', 0);  # does not die
    # $all = { exit => 512, stdout => '', stderr => "ls: cannot access ..." }

Runs `$cmd` through the shell with `system`, capturing its standard output and standard error with `Capture::Tiny`.  The second argument says what to return:

* `exit` (the default): the wait status, `$?` -- 0 for success, 256 for `exit 1`
* `stdout`: standard output, chomped
* `stderr`: standard error, chomped
* `all`: a hash reference with `exit`, `stdout` and `stderr`

The third argument, `$die`, is 1 by default: a command that exits non-zero prints its exit status, standard output and standard error to `STDERR` and dies.  Pass 0 to have the status returned instead.

The command's standard input is the null device (`/dev/null`, or `nul` on Windows).  A command that would prompt -- `rm` on a write-protected file, `cp -i` -- reads end-of-file and declines rather than waiting, unseen, for an answer.  The caller's `STDIN` is restored afterwards.

## file2string

    my $text = file2string('notes.txt');

Returns the whole of a file as one string, read without any decoding layer.  A file that cannot be opened dies, naming it.

## format_commas

    format_commas(1234567.891);         # '1,234,567.89'
    format_commas(1234567, '%.0u');     # '1,234,567'
    format_commas(999999.999);          # '1,000,000.00'
    format_commas(-0.5);                # '-0.50'
    format_commas(1e20);                # '100,000,000,000,000,000,000.00'

Puts a comma between each group of three digits of the integer part and appends the hundredths, rounded half up.  The second argument is the `sprintf` format the hundredths are printed with, `'.%02d'` by default; `'%.0u'` prints nothing, for a whole number.  Rounding that carries into the integer part does so (`0.999` is `1.00`), a negative number keeps its sign, a number that rounds to zero has none, and a large number is grouped as digits rather than printed in exponent form.

## json_file_to_ref

    my $ref = json_file_to_ref('results.json');

Reads a JSON file and returns the decoded data, through `JSON::MaybeXS`.  Python's `json` module and NumPy write `NaN`, `Infinity` and `-Infinity` as bare words, which are not JSON; where one of those stands as a value it is read as `null`, so it becomes `undef`.  The same words inside a string are left alone.  A file that does not exist, or is empty, dies.

## ref_to_json_file

    ref_to_json_file($data, 'results.json');   # prints "Wrote results.json"

Writes a data structure to a file as JSON, through `JSON::MaybeXS`, prints `Wrote` and the file name, and returns the file name.  The file name must be a plain string; a reference dies.

## random_key, random_value

    my $key   = random_key(\%hash);
    my $value = random_value(\%hash);

Return one key, or one value, of a hash -- whichever pair perl's hash iterator yields first, which is quick no matter how big the hash is.  This is *any* key, not a randomly chosen one: the same hash returns the same pair each time.  It is useful for looking at one record of a hash of records.  An empty hash returns `undef`.

Both reset the hash's iterator, so do not call them on a hash in the middle of an `each` loop.

## structure

    my $text = structure($ref, output => 'string');
    structure(\%config, max_depth => 2, as => 'config');

Prints the *shape* of a data structure rather than its values: `p` shows every element of a 50,000-element array of records, while `structure` merges them into one and shows the record once.

    my @people = (
        { name => 'Ann', age => 31, langs => ['perl', 'R'] },
        { name => 'Bo',  age => 28, langs => [], email => undef },
    );
    st @people;

prints

    ARRAY[2]
        [*]: HASH{4} (from 2 instances)
            age: number
            email?: null
            langs: ARRAY[0-2] (from 2 instances)
                [*]: string
            name: string

A key that only some of the merged hashes have is marked `?`.  Values in the same place that are of different kinds are shown as a `UNION` of each kind.  Arrays show the range of their lengths.  Blessed references show their class.  A reference back to a containing structure is shown as `(cycle)` rather than followed.

It takes these options after the reference:

* `output` (default `stdout`): `stdout` or `stderr` to print there; `string` to print nothing.  The text is returned in every case.
* `color` (default `auto`): `1` or `0`.  `auto` colours the output when it goes to a terminal, or when `CLICOLOR_FORCE` is set, unless `NO_COLOR` is set.
* `max_depth` (default `0`): How many levels to descend before printing `(...)`; `0` is no limit.
* `hash_max` (default `32`): A hash with more keys than this is taken to be a lookup table, and its values are merged into one entry, `<*>`, rather than listed by key.  `0` lists every key.
* `as` (no default): A line to print above the structure.

## st

    st %hash;
    st @array;
    st $ref, max_depth => 2;

`structure`, called the way `p` is called: the argument is a variable, not a reference to one, and the options follow it.  As with `p`, it must be a variable -- `st(\%h)` and `st(func())` do not compile; call `structure` for those.

# Installation

    cpanm Util::Con

or, from a copy of the repository:

    perl Makefile.PL
    make
    make test
    make install

# Compatibility

`Util::Con` runs on perl 5.10.1 and later, and is tested there.  `execute` hands its command to the shell, so the command has to be written for the shell of the system it runs on.  On Windows, the paths `dir` returns are joined with `/`, which perl accepts there; recursive listings with `cpu` rely on `Parallel::ForkManager`'s emulated `fork`.

# Author

David E. Condon <dec986@gmail.com>

# License

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# Thanks

A lot of this work used Claude AI, which was paid for by the University of Idaho's IMCI
