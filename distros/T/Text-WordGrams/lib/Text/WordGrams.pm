package Text::WordGrams;

use warnings;
use strict;
use DB_File;
use File::Temp;
use Fcntl;

use base 'Exporter';

use Lingua::PT::PLNbase;

=encoding UTF-8

=head1 NAME

Text::WordGrams - Calculates statistics on word ngrams.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';
our @EXPORT = ("word_grams", "word_grams_from_files");

=head1 SYNOPSIS

    use Text::WordGrams;

    my $data = word_grams( $text );

    my $data = word_grams_from_files( $file1, $file2 );

=head1 FUNCTIONS

=head2 word_grams

Returns a reference to an hash table with word ngrams counts for a
specified string. Options are passed as a hash reference as first
argument if needed.

Options include:

=over 4

=item ignore_case

Set this option to ignore text case;

=item size

Set this option to the n-gram size you want. Notice that the value
should be greater or equal to two. Also, keep in mind that the bigger
size you ask for, the larger the hash will become.

=item tokenize

This option is activated by default. Give a zero value if your
document is already tokenized. In this case your text will be slitted
by space characters.

=back

=cut

sub word_grams {
    my $conf = {};
    $conf = shift if (ref($_[0]) eq "HASH");
    $conf->{size} = 2 unless $conf->{size} && $conf->{size} >= 1;

    my $text = shift;
    $text = lc($text) if $conf->{ignore_case};

    my @atoms;
    if (!exists($conf->{tokenize}) || $conf->{tokenize} == 1) {
        @atoms = atomiza($text);
    }
    else {
        $text =~ s/\n/ /g;
        @atoms = split /\s+/, $text;
    }

    my %data;
    my $fh = File::Temp->new();
    my $fname = $fh->filename;
    $DB_HASH->{cachesize} = 10000;
    tie %data, 'DB_File', $fname, 0666, O_CREAT, $DB_HASH;

    my $previous;
    my $next;
    while ($previous = shift @atoms) {
        $next = _get($conf->{size}-1, \@atoms);
        if (length($next)) {
            $data{"$previous $next"}++;
        } else {
            $data{$previous}++;
        }
    }
    return \%data
}

sub _get {
    my ($n, $atoms) = @_;
    if ($n && $n <= $#$atoms + 1) {
        return join(" ", @{$atoms}[0..$n-1])
    } else {
        return ""
    }
}

=head2 word_grams_from_files

Supports the same options of C<word_grams> function, but receives a
list of file names instead of a string.

=cut

sub word_grams_from_files {
    my $conf = {};
    $conf = shift if (ref($_[0]) eq "HASH");
    my $data;

    for my $file (@_) {
        next unless -f $file;

        local $/ = "\n\n";

        open F, $file or die "Can't open file: $file\n";

        binmode F, ":utf8" if exists($conf->{utf8}) && $conf->{utf8};

        while(<F>) {
            my $o = word_grams($conf, $_);
            for my $w (keys %$o) {
                $data->{$w}+=$o->{$w}
            }
        }
        close F;
    }

    return $data;
}

=head1 AUTHOR

Alberto Simões, C<< <ambs@cpan.org> >>

=head1 BUGS

Current method is very, very slow. if you find any faster method,
please let me know. I think the bottle neck is in the tokenisation
part.

Please report any bugs or feature requests to
C<bug-text-wordgrams@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-WordGrams>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005-2009 Alberto Simões, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; # End of Text::WordGrams
