#!/usr/bin/perl

use Getopt::Std;
use Text::TypingEffort qw(effort);

$Getopt::Std::STANDARD_HELP_VERSION = 1;

my %opts;            # command-line options go here
getopts('l:c:', \%opts);

push @ARGV, '-' unless @ARGV;

my $effort = {};  # our accumulator
foreach (@ARGV) {
    $effort = effort(
        file    => $_ eq '-' ? \*STDIN : $_,
        layout  => $opts{l},
        initial => $effort,
        caps    => $opts{c},
    );
}

my $chars   = $effort->{characters};
my $presses = $effort->{presses};
my $dist    = $effort->{distance};
my $joules  = $effort->{energy};

print "$chars characters\n";
print "$presses presses\n";
print "$dist mm\n";
print "\n";
printf "%.1f mm/press\n",     $dist/$presses  if $presses;
printf "%.1f mm/char\n",      $dist/$chars    if $chars  ;
printf "%.2f presses/char\n", $presses/$chars if $chars  ;
printf "%.3f Joules total\n", $joules                    ;


sub HELP_MESSAGE {
    my ($fh) = @_;

    print $fh <<USAGE;
Usage: $0 [-l layout] [filename [filename [...]]]

'filename' should be the name of a file to analyze.  You may also
use the special filename '-' to indicate standard input.  If no
filenames are specified, standard input is used.

Options:
  -l layout   specify the desired keyboard layout where 'layout' is
              one of: qwerty, dvorak, aset, xpert
  -c number   specify the number of capital letters that must be in
              a row before Caps Lock will be used

USAGE
}

sub VERSION_MESSAGE {
    my ($fh) = @_;

    my $rev = sprintf("%d", q$Revision$ =~ /(\d+)/);
    my $date = sprintf("%s", q$Date$ =~ /\( (.*?) \)/x);

    print $fh <<MSG;
$0 revision $rev
   using Text::TypingEffort version $Text::TypingEffort::VERSION
   last modified $date

MSG
}

__END__

=head1 NAME

effort - command-line interface to Text::TypingEffort

=head1 SYNOPSIS

 effort -l dvorak -c6 journal/*.txt

calculates the effort required to type all the .txt files in the directory
journal/ using the Dvorak keyboard layout and assuming that the Caps Lock
key was only used when 6 or more capitals were typed in a row.

=head1 DESCRIPTION

A simple command-line interface to the L<Text::TypingEffort> module.  Run
C<effort --help> for full usage instructions.

=head1 SEE ALSO

L<Text::TypingEffort>

=head1 AUTHOR

Michael Hendricks <michael@palmcluster.org>

=head1 COPYRIGHT

Copyright 2005-2009 Michael Hendricks. All rights reserved.

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

