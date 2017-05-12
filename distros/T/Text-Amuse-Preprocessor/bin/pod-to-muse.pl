#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use Pod::Simple::Wiki;
use Pod::Usage;
use Getopt::Long;

=head1 NAME

pod-to-muse.pl - convert POD documentation to muse

=head1 DESCRIPTION

Convert the POD found in a module, script or pod file to muse, using
L<Pod::Simple::Wiki>.

=head1 SYNOPSIS

 pod-to-muse.pl /path/to/lib/Module.pm [ output.muse ]

or

 cat /path/to/lib/Module.pm | pod-to-muse.pl > out.muse

If an argument is provided, parse that file, otherwise use the STDIN.

If a second argument is provided, use that as output, otherwise use
the STDOUT.

=head1 SEE ALSO

L<Text::Amuse::Preprocessor>

=cut

my ($help);

GetOptions(help => \$help) or die;

if ($help) {
    pod2usage();
    exit;
}

my $parser = Pod::Simple::Wiki->new('muse');


my ($in, $out, $title);
if ( defined $ARGV[0] ) {
    # open in raw mode
    open ($in, '<', $ARGV[0]) or die "Couldn't open $ARGV[0]: $!\n";
    $title = fileparse($ARGV[0], qr{\.(pl|pm|pod)}i);
}
else {
    $in = *STDIN;
    $title = '<STDIN>';
}

# but encode the output layer
if ( defined $ARGV[1] ) {
    open ($out, ">:encoding(UTF-8)", $ARGV[1]) or die "Couldn't open $ARGV[1]: $!\n";
}
else {
    binmode STDOUT, "encoding(UTF-8)";
    $out = *STDOUT;
}
print $out "#title $title\n\n";

$parser->output_fh($out);
$parser->parse_file($in);


