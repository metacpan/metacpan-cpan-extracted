#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long qw(:config no_ignore_case pass_through);
use Pod::Usage;
use Text::LTSV::Liner;

GetOptions(
    'k|key=s'    => \my @_keys,
    'no-color|C' => \my $no_color,
    'no-key|K'   => \my $no_key,
    'h|help'     => \my $help,
    'man'        => \my $man,
);

pod2usage(1)             if $help;
pod2usage(-verbose => 2) if $man;

$no_color = 1 if $no_key;
my @keys = map { split ',' } @_keys;

my %args = (
    'no-color' => $no_color,
    'no-key'   => $no_key,
);

if ( scalar(@keys) ) {
    $args{key} = \@keys;
}

my $liner = Text::LTSV::Liner->new(%args);

while (<>) {
    $liner->run($_);
}

__END__

=head1 NAME

ltsvl.pl - Line filter of LTSV text

=head1 SYNOPSIS

    $ cat /path/to/yourtext.ltsv | ltsvl.pl [Options]

    Options:
      --key|-k         keys to output
      --no-color|C     don't colorize output
      --no-key|K       output only values and don't colorize output
      --help|-h        brief help message
      --man            full documentaion

=head1 OPTIONS

=over 4

=item B<--key|-k>

Keys which you want to output.

=item B<--no-color|-C>

Don't colorize output.

=item B<--no-key|-K>

Don't output labels, but only values.
If you specify this option, you won't get colorized output (like --no-color).

=item B<--man>

Prints the manual page and exit

=back

=head1 DESCRIPTION

Labeled Tab-separated Values (LTSV) format is a variant of Tab-separated
Values (TSV). (cf: L<http://ltsv.org/>)
This script simply filters text whose format is LTSV by specified keys.

=head1 AUTHORS

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=head1 LICENSE

Copyright (C) 2013 YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  That means either (a) the GNU General Public
License or (b) the Artistic License.

=head1 SEE ALSO

L<Text::LTSV::Liner>

=cut

