package Text::Amuse::Compile::Indexer;

use strict;
use warnings;
use Moo;
use Types::Standard qw/Str ArrayRef Object CodeRef/;
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
has logger => (is => 'ro', isa => CodeRef, required => 1);

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

    my @paragraphs = split(/\n\n/, $full_body);

    # build a huge regexp with the matches
    my %labels;
    my @matches;
    for (my $i = 0; $i < @{$self->specifications}; $i++) {
        my $spec = $self->specifications->[$i];
      MATCH:
        foreach my $match (@{$spec->matches}) {
            my $str = $match->{match};
            if (my $exists = $labels{$str}) {
                $self->logger->("$str already has a label $exists->{label} " . $exists->{spec}->index_name . "\n");
                next MATCH;
            }
            $labels{$str} = {
                             label => $match->{label},
                             matches => 0,
                             spec => $spec,
                             spec_index => $i,
                            };
            my @pieces;
            if ($match->{match} =~ m/\A\w/) {
                push @pieces, "\\b";
            }
            push @pieces, quotemeta($match->{match});
            if ($match->{match} =~ m/\w\z/) {
                push @pieces, "\\b";
            }
            push @matches, join('', @pieces);
        }
    }
    my $re_string = join('|', @matches);
    my $re = qr{$re_string};
    # print "Regex is $re\n";
    my @out;

    my $add_index = sub {
        my ($match) = @_;
        die "Cannot find belonging specification for $match. Bug?" unless $labels{$match};
        my $index_name = $labels{$match}{spec}->index_name;
        my $label = $labels{$match}{label};
        $labels{$match}{matches}++;
        return "\\index[$index_name]{$label}";
    };

  LINE:
    foreach my $p (@paragraphs) {
        # we index the inline comments as well, so we can index
        # what we want, where we want.
        if ($p =~ m/^%/) {
            my @prepend;
            while ($p =~ m/($re)/g) {
                push @prepend, $add_index->($1);
            }
            if (@prepend) {
                $p = join("\n", @prepend) . "\n" . $p;
            }
        }
        elsif ($p =~ m/^\\(part|chapter|section|subsection|subsubsection)/) {
            my @append;
            while ($p =~ m/($re)/g) {
                push @append, $add_index->($1);
            }
            if (@append) {
                $p .= join("\n", @append);
            }

        }
        else {
            $p =~ s/($re)/$add_index->($1) . $1/ge;
        }
        push @out, $p;
    }
    # collect the stats
    my %stats;
    foreach my $regex (keys %labels) {
        my $stat = $labels{$regex};
        $stats{$stat->{spec_index}} ||= 0;
        if ($stat->{matches} > 0) {
            $stats{$stat->{spec_index}} += $stat->{matches};
        }
        else {
            $self->logger->("No matches found for $regex\n");
        }
    }
    foreach my $k (keys %stats) {
        $self->specifications->[$k]->total_found($stats{$k});
    }
    return join("\n\n", @out);
}

1;
