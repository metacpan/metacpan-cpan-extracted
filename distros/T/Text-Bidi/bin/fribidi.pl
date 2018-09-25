#!perl

# PODNAME: fribidi.pl
# ABSTRACT: Convert logical text to visual, via the unicode bidi algorithm

use 5.10.0;
use warnings;
use integer;
use strict;

use open ':encoding(utf8)';
use open ':std';

use Text::Bidi 2.07 qw(log2vis get_bidi_type_name fribidi_version);
use Text::Bidi::Constants;
#use Carp::Always;

use Getopt::Long qw(:config gnu_getopt auto_help auto_version);
our $VERSION = "2.07\nlibfribidi " . fribidi_version;
our $width = $ENV{'COLUMNS'} // 80;
our %Opts = ('width=i' => \$width);
GetOptions(\%Opts, qw(break:s rtl! ltr! levels! hex! dir! ltov! types! verbose! width=i));

$Opts{'break'} = ' ' if defined($Opts{'break'}) and ($Opts{'break'} eq '');
if ($Opts{'verbose'}) {
    $Opts{$_} = 1 foreach (qw(levels dir ltov types hex));
}


# read paragraphs (and make perlcritic happy with 'local')
local $/ = '';
my $flags;
$flags = { break => $Opts{'break'} } if defined $Opts{'break'};
my $dir = $Opts{'rtl'} ? $Text::Bidi::Par::RTL 
                       : $Opts{'ltr'} ? $Text::Bidi::Par::LTR : undef;
while (<>) {
    chomp;
    s/ *\n */ /g;
    my ($p, $visual) = log2vis($_, $width, $dir, $flags);
    say $visual;
    say '';
    say STDERR "Base dir: " . get_bidi_type_name($p->dir) if $Opts{'dir'};
    say STDERR "Hex: " . join(' ', map { sprintf("%x", ord($_)) } split '');
    say STDERR "Types: " . join(' ', $p->type_names) if $Opts{'types'};
    say STDERR "Levels: " . join(' ', @{$p->levels}) if $Opts{'levels'};
}

# start of POD

__END__

=pod

=head1 NAME

fribidi.pl - Convert logical text to visual, via the unicode bidi algorithm

=head1 VERSION

version 2.15

=head1 SYNOPSIS

    # display bidi text given in logical order in foo.txt
    fribidi.pl foo.txt
    # same, but force Right-To-Left paragraph direction
    fribidi.pl --rtl foo.txt
    # same, but break lines on spaces
    fribidi.pl --rtl --break -- foo.txt

=head1 DESCRIPTION

This script is similar to the fribidi(1) program provided with libfribidi, 
and performs a subset of its functions. The main point is to test 
L<Text::Bidi> and provide a usage example.

=head1 OPTIONS

=over

=item --(no)ltr

Force all paragraph directions to be Left-To-Right. The default is to deduce 
the paragraph direction via the bidi algorithm.

=item --(no)rtl

Force all paragraph directions to be Right-To-Left. The default is to deduce 
the paragraph direction via the bidi algorithm.

=item --width=I<n>

Set the width of the output lines to I<n>. The default is to use the terminal 
width, or C<80> if that cannot be deduced.

=item --break[=I<s>]

Break the line at the string I<s>. If this is given, the width functions as 
an upper bound for the line length, and the line might be shorter. The 
default value for I<s> is C<' '>, but note that anything following the option 
will be interpreted as the argument, unless it is of the form C<--...>.

=item --levels

Also output the embedding levels of the characters. Mostly for debugging.

=item --help,-?

Give a short usage message and exit with status 1

=item --version

Print a line with the program name and exit with status 0

=back

=head1 ARGUMENTS

Any argument is interpreted as a file name, and the content of all the files, 
as well as the standard input are concatenated together.

=head1 SEE ALSO

L<Text::Bidi>, L<Text::Bidi::Paragraph>, fribidi(1)

=head1 AUTHOR

Moshe Kamensky <kamensky@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Moshe Kamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
