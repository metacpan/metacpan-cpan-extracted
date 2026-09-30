package Test::JSON::Diff;

use warnings;
use v5.42;
use Test2::API qw( context_do );
use File::Which qw( which );
use Path::Tiny qw( tempdir );
use IPC::Open3 qw( open3 );
use Carp qw( croak );
use Exporter qw( import );

our @EXPORT_OK = qw( json_eq_or_diff );

# ABSTRACT: Check two large JSON strings for structural equality
our $VERSION = '0.02'; # VERSION


my %default_options = (
    context   => 3,
    max_lines => 50,
);

my $jq_filter = 'if length == 1 then .[0] else error("input must contain exactly one JSON value") end';

sub json_eq_or_diff ($actual, $expected, @rest) {

    my %options = %default_options;
    if(@rest && ref $rest[-1] eq 'HASH') {
        my $user = pop @rest;
        if(my @bad = sort grep { !exists $default_options{$_} } keys %$user) {
            croak "json_eq_or_diff: unknown option(s): @{[ join ', ', @bad ]}";
        }
        %options = (%options, %$user);
    }
    croak "usage: json_eq_or_diff \$actual_json, \$expected_json [, \$test_name] [, \\%options]"
        if @rest > 1;
    croak "json_eq_or_diff: context must be a non-negative integer"
        unless defined $options{context} && $options{context} =~ /^[0-9]+\z/;
    croak "json_eq_or_diff: max_lines must be a positive integer"
        unless defined $options{max_lines} && $options{max_lines} =~ /^[0-9]+\z/ && $options{max_lines} > 0;

    my $test_name = $rest[0] // "json is the same";

    my $jq   = which('jq')   // croak "json_eq_or_diff: unable to find jq";
    my $diff = which('diff') // croak "json_eq_or_diff: unable to find diff";

    my $dir = tempdir;

    my @diag;
    my %canon;
    foreach my $which (qw( actual expected )) {
        my $raw = $dir->child("$which.json");
        $raw->spew_raw($which eq 'actual' ? $actual : $expected);
        $canon{$which} = $dir->child("$which.canon.json");
        my $err = $dir->child("$which.err");
        my $status = _run_to_files([$jq, '-S', '-s', $jq_filter], $raw, $canon{$which}, $err);
        if($status != 0) {
            push @diag, "$which is not valid JSON:", $err->lines_raw({ chomp => 1 });
        }
    }

    unless(@diag) {
        @diag = _diff($diff, $options{context}, $options{max_lines}, $canon{expected}, $canon{actual}, $dir->child('diff.err'));
    }

    my $ok = !@diag;

    context_do {
        my $ctx = shift;
        $ctx->ok($ok, $test_name, @diag ? [join "\n", @diag] : ());
    };

    return $ok;
}

# run $cmd with stdin, stdout and stderr connected directly to files,
# so that the (possibly large) data never passes through Perl.
sub _run_to_files ($cmd, $in_path, $out_path, $err_path) {
    my $in  = $in_path->openr_raw;
    my $out = $out_path->openw_raw;
    my $err = $err_path->openw_raw;
    my $pid = open3('<&' . fileno($in), '>&' . fileno($out), '>&' . fileno($err), @$cmd);
    waitpid $pid, 0;
    return $?;
}

# returns an empty list if the files are the same, otherwise up to
# $max_lines lines of unified diff, followed by '...' if clipped.
sub _diff ($diff, $context, $max_lines, $expected, $actual, $err_path) {
    # reading $diff's output is line based below, so make sure that's true
    # regardless of what the caller has done to $/ -- in particular, if $/
    # is set to undef (slurp mode), reading an already-at-EOF pipe returns
    # an empty string once instead of undef immediately, which is read as a
    # single (phantom) line of diff output, producing a false failure.
    local $/ = "\n";

    my $err = $err_path->openw_raw;
    my $pid = open3(my $stdin, my $stdout, '>&' . fileno($err),
        $diff, "-U$context", '--label', 'expected', '--label', 'actual', $expected, $actual);
    close $stdin;

    my @lines;
    my $clipped = 0;
    while(defined(my $line = <$stdout>)) {
        if(@lines >= $max_lines) {
            $clipped = 1;
            last;
        }
        chomp $line;
        push @lines, $line;
    }

    if($clipped) {
        push @lines, '...';
        kill 'TERM', $pid;
    }
    close $stdout;
    waitpid $pid, 0;

    unless($clipped) {
        my $status = $? >> 8;
        die join "\n", "diff failed with exit $status:", $err_path->lines_raw({ chomp => 1 })
            if $? == -1 || $? & 127 || $status > 1;
    }

    return @lines;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::JSON::Diff - Check two large JSON strings for structural equality

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Test2::V0;
 use Test::JSON::Diff qw( json_eq_or_diff );

 json_eq_or_diff '{"a":1,"b":[1,2]}', '{ "b" : [1,2], "a" : 1 }';
 json_eq_or_diff $actual_json, $expected_json, 'response body';
 json_eq_or_diff $actual_json, $expected_json, { max_lines => 100 };
 json_eq_or_diff $actual_json, $expected_json, 'response body', { context => 5 };

 done_testing;

=head1 DESCRIPTION

This module provides a L<Test2> compatible test for comparing two JSON
documents for structural equality.  It is intended for large documents,
so the JSON is never decoded into Perl.  Instead each document is
canonicalized with C<jq> and, only if they differ, the canonical forms
are compared with C<diff>.  The failure diagnostic is a unified diff of
the pretty-printed JSON.

Two documents are considered the same if they differ only in:

=over 4

=item object key order

C<{"a":"b","c":"d"}> is the same as C<{"c":"d","a":"b"}>.

=item whitespace outside of strings

C<{"a":"b"}> is the same as C<{ "a" : "b" }>.

=back

Any other difference is a failure, including:

=over 4

=item array order

C<[1,2]> is not the same as C<[2,1]>.

=item types

C<[1]> is not the same as C<["1"]>, and C<[true]> is not the same as C<[1]>.

=item number literals

C<[1]> is not the same as C<[1.0]>.  Number literals are compared as
written, which also means that large integers are compared exactly.

=back

=head1 FUNCTIONS

=head2 json_eq_or_diff

 json_eq_or_diff $actual_json, $expected_json;
 json_eq_or_diff $actual_json, $expected_json, $test_name;
 json_eq_or_diff $actual_json, $expected_json, \%options;
 json_eq_or_diff $actual_json, $expected_json, $test_name, \%options;

Passes if C<$actual_json> and C<$expected_json> are structurally the
same JSON.  Both must be strings of raw, undecoded, UTF-8 encoded JSON
containing exactly one JSON value.  If either is not valid JSON, the
test fails and the diagnostic contains the error reported by C<jq>.

If the documents differ, the diagnostic is a unified diff of the
pretty-printed, key sorted JSON, with the expected document as the
original (C<->) and the actual document as the new (C<+>).

C<$test_name> defaults to C<json is the same>.

Options:

=over 4

=item context

The number of lines of context around each change in the diff.
Defaults to C<3>.

=item max_lines

The maximum number of lines of diff output to include in the
diagnostic.  If the diff is longer, the remaining lines are replaced
with C<...>.  Defaults to C<50>.

=back

This function will die if an unrecognized option is passed, or if
either C<jq> or C<diff> cannot be found in the C<PATH>.

=head1 CAVEATS

Strings containing wide characters are not currently supported; the
JSON must be passed as UTF-8 encoded bytes.

This module requires C<jq> 1.7 or later, since older versions do not
preserve number literals.  This is checked when the distribution is
installed, but not at runtime.

=head1 SEE ALSO

=over 4

=item L<Test::Differences>

=item L<https://jqlang.org>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
