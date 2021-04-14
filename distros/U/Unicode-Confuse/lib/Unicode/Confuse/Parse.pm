package Unicode::Confuse::Parse;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/parse_confusables/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
use warnings;
use strict;
use utf8;
use Carp;
use File::Slurper 'read_text';

our $VERSION = '0.02';

# A code point
my $cp = qr!([0-9A-F]{4,5})\s+!;
# A set of code points
my $ba = qr!($cp+);!;
# A line
my $cl = qr!(?<before>$ba)\s*(?<after>$ba)!;

# Convert hex code points to equivalent strings.

sub cp2s
{
    my ($c) = @_;
    $c =~ s!;$!!;
    $c =~ s!$cp!chr (hex ($1))!ge;
    return $c;
}

sub parse_confusables
{
    my ($file, $v) = @_;
    my $text = read_text ($file);

    msg ($v, "Removing comments");

    $text =~ s!#.*$!!gm;

    # I don't know what MA is but it doesn't do any work, every entry
    # is MA.

    msg ($v, "Removing MA.*\$");

    $text =~ s!\s*MA.*$!!gm;

    msg ($v, "Removing blank lines");

    $text =~ s!^\s*\n!!gm;

    # At this stage there should be nothing except entries.

    my %con;

    while ($text =~ /$cl/g) {
	my $before = cp2s ($+{before});
	my $after = cp2s ($+{after});
	$con{$before} = $after;
    }
    return \%con;
}

sub msg
{
    my ($verbose, $text) = @_;
    if (! $verbose) {
	return;
    }
    my (undef, $file, $line) = caller ();
    $file =~ s!.*/!!;
    print "$file:$line: ";
    print $text;
    print ".\n";
}

1;
