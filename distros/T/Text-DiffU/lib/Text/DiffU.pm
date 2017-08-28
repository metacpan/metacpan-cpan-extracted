package Text::DiffU;

our $DATE = '2017-08-19'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our %colors = (
    seq_header_line  => "\e[1m",
    hunk_header_line => "\e[36m",
    delete_line      => "\e[31m",
    insert_line      => "\e[32m",
    reset            => "\e[0m",
);

$SPEC{diff_u} = {
    v => 1.1,
    summary => 'Diff two sequences and print unified-style output',
    args => {
        seq1 => {
            schema => 'array*',
            req => 1,
            pos => 0,
        },
        seq2 => {
            schema => 'array*',
            req => 1,
            pos => 0,
        },
        seq1_name => {
            schema => 'str*',
            default => '(seq1)',
        },
        seq2_name => {
            schema => 'str*',
            default => '(seq2)',
        },
        ctx => {
            schema => 'nonnegint*',
            default => 3,
        },
        hook_format_seq_header => {
            schema => 'code*',
            description => <<'_',

Hook will be called with these arguments:

    ($seq1_name, $seq2_name)

_
        },
        hook_format_hunk_header => {
            schema => 'code*',
            description => <<'_',

Hook will be called with these arguments:

    ($line1_start, $line2_start, $num_lines1, $num_lines2)

The default hook will print this:

    @@ -<line1_start>,<num_lines1> +<line2_start>,<num_lines2> @@

_
        },
        hook_format_same_items => {
            schema => 'code*',
            description => <<'_',

Hook will be called with these arguments:

    (\@items)

The default hook will print this (i.e. items as lines where each line is
prefixed by a single space):

     line1
     line2
     ...

_
        },
        hook_format_diff_items => {
            schema => 'code*',
            description => <<'_',

Hook will be called with these arguments:

    (\@items1, \@items2)

The default hook will print this, i.e. items1 as lines where each line is
prefixed by a `-` (minus) sign, followed by items2 as lines where each line is
prefixed by a `+` (plus) sign:

     -line1_from_items1
     -line2_from_items1
     ...
     +line1_from_items2
     +line2_from_items2
     ...

_
        },
        use_color => {
            summary => 'Whether the default hooks should print '.
                'ANSI color escape sequences',
            schema => 'bool*',
            description => <<'_',

The default is to use setting from `COLOR` environment variable, or check if
program is run interactively.

_
        },
    },
    result_naked => 1,
    links => [
        {
            url => 'pm:Text::Diff',
            description => <<'_',

Generally <pm:Text::Diff> should be your go-to module if you want to produce
diff ouput. The `diff_u` routine specifically produces unified-style output with
hooks to be able to customize the output.

_
        },
    ],
};
sub diff_u {
    require Algorithm::Diff;

    my %args = @_;

    $args{handle}     //= \*STDOUT;
    $args{seq1_name}  //= '(seq1)';
    $args{seq2_name}  //= '(seq2)';
    $args{ctx}        //= 3;
    $args{use_color}  //= $ENV{COLOR} // (-t STDOUT);

    local %colors = (map {$_=>""} keys %colors) unless $args{use_color};

    $args{hook_format_seq_header} //= sub {
        my ($seq1_name, $seq2_name) = @_;
        join(
            "",
            "$colors{seq_header_line}--- $seq1_name$colors{reset}\n",
            "$colors{seq_header_line}+++ $seq2_name$colors{reset}\n",
        );
    };

    $args{hook_format_hunk_header} //= sub {
        my ($line1_start, $line2_start, $num_lines1, $num_lines2) = @_;
            "$colors{hunk_header_line}\@\@ -$line1_start,$num_lines1".
            " +$line2_start,$num_lines2 \@\@$colors{reset}\n";
    };

    $args{hook_format_same_items} //= sub {
        my ($items) = @_;
        join("", map { " $_\n" } @$items);
    };

    $args{hook_format_diff_items} //= sub {
        my ($items1, $items2) = @_;
        join(
            "",
            (map {"$colors{delete_line}-$_$colors{reset}\n"} @$items1),
            (map {"$colors{insert_line}+$_$colors{reset}\n"} @$items2),
        );
    };

    my $res = "";
    my $seq_header_printed;

    my $code_add_uni_hunk = sub {
        my ($line1_start, $line2_start, $num_lines1, $num_lines2, $has_diff, $hunk_text) = @_;
        return unless $has_diff;
        $res .= $args{hook_format_seq_header}->(
            $args{seq1_name}, $args{seq2_name}) unless $seq_header_printed++;
        $res .= $args{hook_format_hunk_header}->(
            $line1_start, $line2_start, $num_lines1, $num_lines2);
        $res .= $hunk_text;
    };

    # to display unified-style hunks, we basically need to print unified-style
    # hunks. each uni-hunk contains one or more diff-hunks delimited by at most
    # $ctx lines from neighboring same-hunks as context.

    my $diff = Algorithm::Diff->new($args{seq1}, $args{seq2});
    $diff->Base(1);
    my @uni_hunk; # (line1_start, line2_start, num_lines1, num_lines2, has_diff?, hunk_text)

  HUNK:
    while ($diff->Next) {
        my ($min1, $max1, $min2, $max2) = $diff->Get(qw/Min1 Max1 Min2 Max2/);
        if ($diff->Same) {
            if (@uni_hunk) {
                if ($max1-$min1+1 > 2*$args{ctx}) {
                    # break the uni hunk because there are more than 2*ctx of
                    # same lines
                    $uni_hunk[5] .= $args{hook_format_same_items}->(
                        [@{$args{seq1}}[$min1-1 .. $min1+$args{ctx}-1-1]]);
                    $uni_hunk[2] += $args{ctx};
                    $uni_hunk[3] += $args{ctx};
                    $code_add_uni_hunk->(@uni_hunk);

                    @uni_hunk = ($max1-$args{ctx}+1, $max2-$args{ctx}+1, 0, 0, 0, "");
                    $uni_hunk[5] .= $args{hook_format_same_items}->(
                        [@{$args{seq1}}[$max1-$args{ctx} .. $max1-1]]);
                    $uni_hunk[2] += $args{ctx};
                    $uni_hunk[3] += $args{ctx};
                } else {
                    # grow the uni hunk
                    my $max = $max1;
                    my $is_last_hunk;
                    if ($diff->Next) {
                        $diff->Prev;
                    } else {
                        $max = $min1+$args{ctx}-1 if $max > $min1+$args{ctx}-1;
                        $is_last_hunk++;
                    }
                    $uni_hunk[5] .= $args{hook_format_same_items}->(
                        [@{$args{seq1}}[$min1-1 .. $max-1]]);
                    $uni_hunk[2] += ($max-$min1+1);
                    $uni_hunk[3] += ($max-$min1+1);
                    last HUNK if $is_last_hunk;
                }
            } else {
                my $line1_start = $max1-$args{ctx}+1; $line1_start = 1 if $line1_start < 1;
                my $line2_start = $max2-$args{ctx}+1; $line2_start = 1 if $line2_start < 1;
                @uni_hunk = ($line1_start, $line2_start, 0, 0, 0, "");
                $uni_hunk[5] .= $args{hook_format_same_items}->(
                    [@{$args{seq1}}[$line1_start-1 .. $max1-1]]);
                $uni_hunk[2] += ($max1-$line1_start+1);
                $uni_hunk[3] += ($max1-$line1_start+1);
            }
        } else {
            unless (@uni_hunk) {
                @uni_hunk = ($min1, $min2, 0, 0, 0, "");
            }
            $uni_hunk[4]++;
            $uni_hunk[5] .= $args{hook_format_diff_items}->(
                [@{$args{seq1}}[$min1-1 .. $max1-1]],
                [@{$args{seq2}}[$min2-1 .. $max2-1]],
            );
            $uni_hunk[2] += ($max1-$min1+1);
            $uni_hunk[3] += ($max2-$min2+1);
        }
    } # while $diff->Next
    $code_add_uni_hunk->(@uni_hunk);

    $res;
}

1;
# ABSTRACT: Diff two sequences and print unified-style output

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::DiffU - Diff two sequences and print unified-style output

=head1 VERSION

This document describes version 0.001 of Text::DiffU (from Perl distribution Text-DiffU), released on 2017-08-19.

=head1 FUNCTIONS


=head2 diff_u

Usage:

 diff_u(%args) -> any

Diff two sequences and print unified-style output.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<ctx> => I<nonnegint> (default: 3)

=item * B<hook_format_diff_items> => I<code>

Hook will be called with these arguments:

 (\@items1, \@items2)

The default hook will print this, i.e. items1 as lines where each line is
prefixed by a C<-> (minus) sign, followed by items2 as lines where each line is
prefixed by a C<+> (plus) sign:

  -line1_from_items1
  -line2_from_items1
  ...
  +line1_from_items2
  +line2_from_items2
  ...

=item * B<hook_format_hunk_header> => I<code>

Hook will be called with these arguments:

 ($line1_start, $line2_start, $num_lines1, $num_lines2)

The default hook will print this:

 @@ -<line1_start>,<num_lines1> +<line2_start>,<num_lines2> @@

=item * B<hook_format_same_items> => I<code>

Hook will be called with these arguments:

 (\@items)

The default hook will print this (i.e. items as lines where each line is
prefixed by a single space):

  line1
  line2
  ...

=item * B<hook_format_seq_header> => I<code>

Hook will be called with these arguments:

 ($seq1_name, $seq2_name)

=item * B<seq1>* => I<array>

=item * B<seq1_name> => I<str> (default: "(seq1)")

=item * B<seq2>* => I<array>

=item * B<seq2_name> => I<str> (default: "(seq2)")

=item * B<use_color> => I<bool>

Whether the default hooks should print ANSI color escape sequences.

The default is to use setting from C<COLOR> environment variable, or check if
program is run interactively.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Text-DiffU>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Text-DiffU>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text-DiffU>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO


L<Text::Diff>. Generally L<Text::Diff> should be your go-to module if you want to produce
diff ouput. The C<diff_u> routine specifically produces unified-style output with
hooks to be able to customize the output.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
