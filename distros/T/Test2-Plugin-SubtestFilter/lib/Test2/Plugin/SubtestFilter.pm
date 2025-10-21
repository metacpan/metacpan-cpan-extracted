package Test2::Plugin::SubtestFilter;
use 5.016;
use strict;
use warnings;
use Encode qw(decode_utf8);
use Test2::API qw(context);
use B::Deparse ();
use List::Util qw(any);

our $VERSION = "0.02";

our $SEPARATOR = ' ';

use constant DEBUG => $ENV{SUBTEST_FILTER_DEBUG} ? 1 : 0;

sub import {
    my $class = shift;
    my $caller = caller;

    # Get original subtest function from caller's namespace
    # If it doesn't exist, do nothing
    my $orig = $caller->can('subtest') or return;

    # Override subtest in caller's namespace
    no strict 'refs';
    no warnings 'redefine';
    *{"${caller}::subtest"} = _create_filtered_subtest($orig, $caller);
}

# Get subtest filter regex from environment variable
sub _get_subtest_filter_regex {

    unless ( $ENV{SUBTEST_FILTER} ) {
        return undef;
    }

    my $subtest_filter = $ENV{SUBTEST_FILTER};

    # Decode UTF-8 if necessary
    if ($subtest_filter =~ /[\x80-\xFF]/) {
        $subtest_filter = decode_utf8($subtest_filter);
    }

    my $regexp = eval { qr/$subtest_filter/ };
    die "SUBTEST_FILTER ($regexp) is not a valid regexp: $@" if $@;

    return $regexp;
}

# Create a filtered subtest wrapper
sub _create_filtered_subtest {
    my ($original_subtest, $target_caller) = @_;

    my $deparse = B::Deparse->new('-p');

    return sub {
        my $filter = _get_subtest_filter_regex();

        # If no filter is set, run the original subtest
        unless ($filter) {
            goto &$original_subtest;
        }

        my $name = shift;
        my $params = ref($_[0]) eq 'HASH' ? shift(@_) : {};
        my $code = shift;
        my @args = @_;

        my $ctx = context();
        my $hub = $ctx->hub;

        $hub->set_meta(subtest_name => $name);
        my @stacked_subtest_names = map { $_->get_meta('subtest_name') } $ctx->stack->all;
        my $current_subtest_fullname = join $SEPARATOR, @stacked_subtest_names;

        # If a parent subtest matches, run all children
        if ($current_subtest_fullname =~ $filter) {
            my $pass = $original_subtest->($name, $params, $code, @args);
            $ctx->release;
            return $pass;
        }

        # Dry-run the subtest to check for matching child subtests
        my $obj    = B::svref_2object(\$code);
        my $source = $deparse->coderef2text($code);
        my @child_subtest_names = $source =~ /subtest\(['"](.+?)['"]/g;

        if (@child_subtest_names) {
            my @child_subtest_fullnames = map {
                my $decoded = $_;
                # Convert B::Deparse's \x{XXXX} format to actual characters
                $decoded =~ s/\\x\{([0-9a-fA-F]+)\}/chr(hex($1))/ge;
                join $SEPARATOR, $current_subtest_fullname, $decoded;
            } @child_subtest_names;
            if (any { $_ =~ $filter } @child_subtest_fullnames) {
                my $pass = $original_subtest->($name, $params, $code, @args);
                $ctx->release;
                return $pass;
            }
        }

        # No match found, skip the subtest
        if (DEBUG) {
            $ctx->skip($name);
        }
        $ctx->release;
        return 1;
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Test2::Plugin::SubtestFilter - Filter subtests by name

=head1 SYNOPSIS

    # t/test.t
    use Test2::V0;
    use Test2::Plugin::SubtestFilter;

    subtest 'foo' => sub {
        ok 1;
        subtest 'bar' => sub { ok 1 };
    };

    subtest 'baz' => sub {
        ok 1;
    };

    done_testing;

Then run with filtering:

    # Run only 'foo' subtest and all its children
    $ SUBTEST_FILTER=foo prove -lv t/test.t

    # Run nested 'bar' subtest (and its parent 'foo')
    $ SUBTEST_FILTER=bar prove -lv t/test.t

    # Use regex patterns
    $ SUBTEST_FILTER='ba' prove -lv t/test.t  # Matches 'bar' and 'baz'

    # Run all tests (no filtering)
    $ prove -lv t/test.t

=head1 DESCRIPTION

Test2::Plugin::SubtestFilter is a Test2 plugin that allows you to selectively run
specific subtests based on environment variables. This is useful when you want to
run only a subset of your tests during development or debugging.

=head1 FILTERING BEHAVIOR

The plugin matches subtest names using partial matching (substring or regex pattern).
For nested subtests, the full name is constructed by joining parent and child names
with spaces.

=head2 How Matching Works

=over 4

=item * B<Simple match>

    subtest 'foo' => sub { ... };
    # SUBTEST_FILTER=foo matches 'foo'
    # SUBTEST_FILTER=fo  matches 'foo' (partial match)

=item * B<Nested subtest match>

    subtest 'parent' => sub {
        subtest 'child' => sub { ... };
    };
    # Full name is: 'parent child'
    # SUBTEST_FILTER=child         matches 'parent child'
    # SUBTEST_FILTER='parent child' matches 'parent child'

=item * B<When parent matches>

When a parent subtest matches the filter, ALL its children are executed.

    SUBTEST_FILTER=parent prove -lv t/test.t
    # Executes 'parent' and all nested subtests inside it

=item * B<When child matches>

When a nested child matches the filter, its parent is executed but only the
matching children run. Non-matching siblings are skipped.

    SUBTEST_FILTER=child prove -lv t/test.t
    # Executes 'parent' (to reach 'child') but skips other children

=item * B<No match>

Subtests that don't match the filter are skipped.

=item * B<No filter set>

When C<SUBTEST_FILTER> is not set, all tests run normally.

=back

=head1 ENVIRONMENT VARIABLES

=over 4

=item * C<SUBTEST_FILTER>

Regular expression pattern for partial matching against subtest names.
Supports both substring matching and full regex patterns.

    SUBTEST_FILTER=foo      # Matches 'foo', 'foobar', 'my foo test', etc.
    SUBTEST_FILTER='foo.*'  # Matches 'foo', 'foobar', 'foo_test', etc.
    SUBTEST_FILTER='foo|bar' # Matches 'foo' or 'bar'

=back

=head1 CAVEATS

=over 4

=item * This plugin must be loaded AFTER Test2::V0 or Test2::Tools::Subtest,
as it needs to override the C<subtest> function that they export.

=item * The plugin modifies the C<subtest> function in the caller's namespace,
which may interact unexpectedly with other code that also modifies C<subtest>.

=back

=head1 SEE ALSO

=over 4

=item * L<Test2::V0> - Recommended Test2 bundle

=item * L<Test2::Tools::Subtest> - Core subtest functionality

=item * L<Test2::API> - Test2 API for intercepting events

=back

=head1 LICENSE

Copyright (C) kobaken.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kobaken E<lt>kentafly88@gmail.comE<gt>

=cut

