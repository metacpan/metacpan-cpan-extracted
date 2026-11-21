package Test2::Aggregate::Helper;

use strict;
use warnings;

use Carp;
use Path::Tiny;

=head1 NAME

Test2::Aggregate::Helper - Common functions for Test2::Aggregate helper scripts

=head1 SYNOPSIS

See L<agg> and L<aggit> helper scripts.

=cut

our $VERSION = '1.00';

=head1 FUNCTIONS

=head2 setup_options(\%opt)

Normalizes command-line options used by the helper scripts. This sets defaults,
validates paths and regexes, prepares include/exclude patterns, and falls back to
C<prove> when L<Test2::Harness> is unavailable. An C<exclude_list> is resolved
to canonical paths (relative entries against C<root> or the current directory).

=head2 is_excluded(\%opt, $test)

Returns true if C<$test> (a path to an existing test file) is one of the
entries of the C<exclude_list> processed by C<setup_options>.

=head2 canonical_path($path)

Returns the absolute path with symlinks and C<..> resolved where possible.

=head2 create_command(\%opt, $file, $args_only)

Builds the C<prove> or C<yath> command used to run the generated aggregate test
file. C<include> may be a single path or an array ref of paths. When
C<$args_only> is true, only the arguments are returned.

=head2 generate_code(\%opt, @paths)

Generates a standalone aggregate test file from normalized helper options and
the supplied test files, directories, or list files.

=cut

sub setup_options {
    my $opt = shift;

    unless ($opt->{prove}) {
        eval "use Test2::Harness";
        $opt->{prove} = 1 if $@;
    }
    $opt->{test_bundle} ||= $opt->{prove} ? 'Test::More' : 'Test2::V0';
    $opt->{stats_output}  = $opt->{pass_output} if $opt->{pass_output};
    $opt->{out} =~ s/\.t$// if $opt->{out};
    delete $opt->{event_timeout} if $opt->{prove};
    $opt->{exclude_pattern} = _create_exclude_pattern($opt)
        if $opt->{exclude_regex};
    $opt->{include_pattern} = _create_include_pattern($opt)
        if $opt->{include_regex};

    if ($opt->{root}) {
        $opt->{absolute} = undef;
        croak "Specified --root does not exist" unless -d $opt->{root};
        $opt->{root} = "" . path($opt->{root})->absolute;
        foreach (@ARGV) {
            my $path = path($_)->is_absolute ? path($_) : path($opt->{root}, $_);
            croak "$path doesn't exist" unless -e $path;
        }
    } elsif (!$opt->{absolute}) {
        $opt->{root} = "./";
        $opt->{relative_root} = 1;
    }

    $opt->{exclude_paths} = _read_exclude_list($opt) if $opt->{exclude_list};
}

sub is_excluded {
    my $opt  = shift;
    my $test = shift;

    return 0 unless $opt->{exclude_paths};
    return $opt->{exclude_paths}->{canonical_path($test)} ? 1 : 0;
}

sub canonical_path {
    my $path = path(shift)->absolute;
    my $real = eval { $path->realpath };
    return "" . ($real || $path);
}

sub create_command {
    my $opt       = shift;
    my $file      = shift;
    my $args_only = shift;

    my $cmd  = $opt->{prove} ? 'prove' : 'yath';
    my @inc  = ref $opt->{include} ? @{$opt->{include}}
        : defined $opt->{include} ? $opt->{include} : ();
    my @args = ($file);
    unshift @args, '-v'                            if $opt->{verbose};
    unshift @args, map { "-I$_" } grep { length } @inc;
    unshift @args, '--et', $opt->{event_timeout}
        if !$opt->{prove} && defined $opt->{event_timeout};
    unshift @args, 'test' unless $opt->{prove} || $args_only;

    return @args if $args_only;
    return $cmd, @args;
}

sub generate_code {
    my $opt  = { %{shift()} };
    $opt->{root} ||= "" . path('.')->absolute if $opt->{lists} && $opt->{absolute};
    my $code = _test_bundle_use($opt->{test_bundle})
        . "\nuse Test2::Aggregate;\n\nTest2::Aggregate::run_tests(\n";
    for (qw/test_warnings reverse shuffle sort dry_run bail_on_fail relative_root absolute/) {
        $code .= "\t$_ => 1,\n" if $opt->{$_};
    }
    for (qw/stats_output root _progress_file/) {
        next unless $opt->{$_};
        my $value = $opt->{$_};
        if ($_ eq 'root' && $opt->{lists} && $opt->{relative_root}) {
            $value = path($value)->absolute->relative($opt->{file}->parent->absolute);
        }
        $code .= "\t$_ => " . _quote_perl_string($value) . ",\n";
    }
    $code .= "\texclude => " . _quote_perl_string($opt->{exclude_pattern}) . ",\n"
        if $opt->{exclude_pattern};
    $code .= "\tinclude => " . _quote_perl_string($opt->{include_pattern}) . ",\n"
        if $opt->{include_pattern};
    $code .= "\tpass_only => 1,\n" if $opt->{pass_output};
    $code .= $opt->{lists} ? "\tlists" : "\tdirs";
    $code .= " => [\n\t\t";
    $code .= join(",\n\t\t", map {_quote_perl_string($_)} _absolute_paths($opt, @_));
    $code .= "\n\t]\n);\n\ndone_testing();\n";
    return $code;
}

sub _test_bundle_use {
    my @modules = split /,/, shift;
    my $str     = '';
    $str .= "use $_;\n" for @modules;
    return $str;
}

sub _absolute_paths {
    my $opt    = shift;
    my $t_file = $opt->{file}->parent->absolute;
    my @norm;
    foreach my $input (@_) {
        my $path = $input;
        unless (substr($path, 0, 1) eq '/') {
            if ($opt->{relative_root}) {
                my $abs = path($opt->{root}, $path)->absolute;
                # List entries also use root, so retain the input root for lists.
                my $base = $opt->{lists} ? path($opt->{root})->absolute : $t_file;
                $path = $abs->relative($base);
            } elsif ($opt->{absolute}) {
                $path = path($opt->{root} || '.', $path)->absolute;
            }
        }
        push @norm, $path;
    }

    return @norm;
}

sub _create_exclude_pattern {
    my ($opt) = @_;

    eval { qr/$opt->{exclude_regex}/ };
    croak "Invalid --exclude_regex '$opt->{exclude_regex}': $@" if $@;

    return "(?:$opt->{exclude_regex})";
}

# Exclude list entries are resolved against --root (or the current directory)
# to canonical paths, so they match regardless of where the generated runner
# lives (e.g. a temp directory) and of how the discovered path is spelled.
sub _read_exclude_list {
    my ($opt) = @_;

    croak "Specified --exclude_list does not exist" unless -e $opt->{exclude_list};
    my $base = path($opt->{root} || '.')->absolute;
    my %paths;
    foreach my $line (split /\r?\n/, path($opt->{exclude_list})->slurp_utf8) {
        next if $line =~ /^\s*(?:#|$)/;
        $line =~ s/^\s+|\s+$//g;
        next unless length $line;

        my $test = path($line)->is_absolute ? path($line) : path($base, $line);
        $paths{canonical_path($test)} = 1;
    }

    return \%paths;
}

sub _create_include_pattern {
    my ($opt) = @_;

    eval { qr/$opt->{include_regex}/ };
    croak "Invalid --include_regex '$opt->{include_regex}': $@" if $@;

    return "(?:$opt->{include_regex})";
}

sub _quote_perl_string {
    my ($value) = @_;
    $value = "$value";
    $value =~ s/\\/\\\\/g;
    $value =~ s/'/\\'/g;
    return "'$value'";
}

1;
