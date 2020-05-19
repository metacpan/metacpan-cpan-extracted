package Text::Amuse::Compile::Indexer;

use strict;
use warnings;
use Moo;
use Types::Standard qw/Str ArrayRef Object/;
use Data::Dumper;
use Text::Amuse::Compile::Indexer::Specification;
use Text::Amuse::Functions qw/muse_format_line/;


=encoding utf8

=head1 NAME

Text::Amuse::Compile::Indexer - Class for LaTeX indexes

=head1 SYNOPSIS

Everything here is pretty much private and used by L<Text::Amuse::Compile::File>

=head1 ACCESSORS AND METHODS

=over 4

=item latex_body

The body provided to the constructor

=item index_specs

The raw indexes

=item specifications

Lazy built, the L<Text::Amuse::Compile::Indexer::Specification>
objects

=item language_code

The language ISO code. To be passed to C<muse_format_line>

=item indexed_tex_body

Method meant to be called from the L<Text::Amuse::Compile::File>
object.

=item interpolate_indexes

Main method to get the job done.

=back

=cut


has latex_body => (is => 'ro', required => 1, isa => Str);
has index_specs => (is => 'ro', required => 1, isa => ArrayRef[Str]);
has specifications => (is => 'lazy', isa => ArrayRef[Object]);
has language_code => (is => 'ro');

sub _build_specifications {
    my $self = shift;
    my @specs;
    my $lang = $self->language_code;
    my $escape = sub {
        return muse_format_line(ltx => $_[0], $lang);
    };
    foreach my $str (@{$self->index_specs}) {
        my ($first, @lines) = grep { length($_) } split(/\n+/, $str);
        if ($first =~ m/^INDEX ([a-z]+): (.+)/) {
            my ($name, $label) = ($1, $2);
            my @patterns;
            # remove the comments and the white space
            foreach my $str (@lines) {
                $str =~ s/\A\s*//g;
                $str =~ s/\s*\z//g;
                push @patterns, $escape->($str) if $str;
            }
            push @specs, Text::Amuse::Compile::Indexer::Specification->new(
                                                                           index_name => $escape->($name),
                                                                           index_label => $escape->($label),
                                                                           patterns => \@patterns,
                                                                          );
        }
        else {
            die "Invalid index specification $first, expecting INDEX <name>: <label>";
        }
    }
    return \@specs;
}

sub indexed_tex_body {
    my $self = shift;
    if (@{$self->index_specs}) {
        return $self->interpolate_indexes;
    }
    else {
        return $self->latex_body;
    }
}

sub interpolate_indexes {
    my $self = shift;
    my $full_body = $self->latex_body;
    # remove the indexes
    $full_body =~ s/\\begin\{comment\}
                    \s*
                    INDEX\x{20}+[a-z]+:
                    .*?
                    \\end\{comment\}//gsx;

    my @lines = split(/\n/, $full_body);
    my @outlines;
  LINE:
    foreach my $l (@lines) {
        # we index the inline comments as well, so we can index
        # what we want, where we want.
        my $is_comment = $l =~ m/^%/;
        my @prepend;
        my @out;
        my @words = Text::Amuse::Compile::Indexer::Specification::explode_line($l);
        my $last_word = $#words;
        my $i = 0;
        # print Dumper(\@words);
        # print "Last is $last_word\n";

      WORD:
        while ($i <= $last_word) {
          SPEC:
            foreach my $spec (@{$self->specifications}) {
                my $index_name = $spec->index_name;
              MATCH:
                foreach my $m (@{ $spec->matches }) {
                    # print Dumper([$i, \@words, $m]);
                    my @search = @{$m->{tokens}};
                    my $add_to_index = $#search;
                    next MATCH unless @search;
                    my $last_i = $i + $add_to_index;
                    if ($last_word >= $last_i) {
                        if (join('', @search) eq
                            join('', @words[$i..$last_i])) {
                            $spec->total_found($spec->total_found + 1);
                            # print join("", @search) . " at " . join("", @words[$i..$last_i]) . "\n";
                            my $index_str = "\\index[$index_name]{$m->{label}}";
                            if ($is_comment) {
                                push @prepend, $index_str;
                            }
                            else {
                                push @out, $index_str;
                            }
                            push @out, @words[ $i .. $last_i];
                            # advance
                            $i = $last_i + 1;
                            next WORD;
                        }
                    }
                }
            }
            push @out, $words[$i];
            $i++;
        }
        if (@prepend) {
            push @prepend, "\n";
        }
        push @outlines, join('', @prepend, @out);
    }
    return join("\n", @outlines);
}

1;
