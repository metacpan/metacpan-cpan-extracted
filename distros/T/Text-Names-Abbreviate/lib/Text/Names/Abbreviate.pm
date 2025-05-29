package Text::Names::Abbreviate;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(abbreviate);
our $VERSION   = '0.01';

=head1 NAME

Text::Names::Abbreviate - Create abbreviated name formats from full names

=head1 SYNOPSIS

  use Text::Names::Abbreviate qw(abbreviate);

  say abbreviate("John Quincy Adams");         # "J. Q. Adams"
  say abbreviate("Adams, John Quincy");        # "J. Q. Adams"
  say abbreviate("George R R Martin", format => 'initials'); # "G.R.R.M."

=head1 DESCRIPTION

This module provides simple abbreviation logic for full personal names,
with multiple formatting options and styles.

=head1 OPTIONS

=over

=item format

One of: default, initials, compact, shortlast

=item style

One of: first_last, last_first

=item separator

Customize the spacing/punctuation for initials (default: ". ")

=back

=cut

sub abbreviate {
    my ($name, %opts) = @_;

    my $format = $opts{format} // 'default';   # default, initials, compact, shortlast
    my $style  = $opts{style}  // 'first_last'; # first_last or last_first
    my $sep    = defined $opts{separator} ? $opts{separator} : '. ';

    # Normalize commas (e.g., "Adams, John Q." -> ("Adams", "John Q."))
    my ($last, $rest);
    if ($name =~ /,/) {
        ($last, $rest) = map { s/^\s+|\s+$//gr } split(/\s*,\s*/, $name, 2);
        $name = "$rest $last";
    }

    my @parts = split /\s+/, $name;
    return '' unless @parts;

    my $last_name = pop @parts;
    my @initials  = map { substr($_, 0, 1) } @parts;

    if ($format eq 'compact') {
        return join('', @initials, substr($last_name, 0, 1));
    }
    elsif ($format eq 'initials') {
        return join('.', @initials, substr($last_name, 0, 1)) . '.';
    }
    elsif ($format eq 'shortlast') {
        return join(' ', map { "$_." } @initials) . " $last_name";
    }
    else { # default: "J. Q. Adams"
        my $joined = join(' ', map { "$_." } @initials);
        return $style eq 'last_first'
            ? "$last_name, $joined"
            : "$joined $last_name";
    }
}

1;

__END__
