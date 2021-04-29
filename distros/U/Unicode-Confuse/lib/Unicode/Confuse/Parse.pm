package Unicode::Confuse::Parse;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/
    metadata
    parse_confusables
/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
use warnings;
use strict;
use utf8;
use Carp;
use File::Slurper 'read_text';

our $VERSION = '0.05';

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

# Extract the date and version information from the confusables
# file. The return value is a hash reference which is then directly
# converted to JSON.

sub metadata
{
    my ($file) = @_;
    if (! -f $file) {
	die "No $file";
    }
    my %md;
    my $text = read_text ($file);
    while ($text =~ /^# (.*)$/gm) {
	my $data = $1;
	if ($data =~ /(Date|Version): (.*)/) {
	    my $what = lc $1;
	    $md{$what} = $2;
	    next;
	}
	if ($data =~ /©/) {
	    $md{copyright} = $data;
	    next;
	}
	if ($data =~ /terms of use/i) {
	    $data =~ s!(https?://.*\.html)!L<$1>!;
	    $md{terms} = $data;
	    next;
	}
	if ($data =~ /Unicode Security Mechanisms/) {
	    $md{title} = $data;
	    next;
	}
	if ($data eq 'confusables.txt' ||
	    $data =~ /trademark|documentation|total/) {
	    next;
	}
	warn "Unparsed metadata line '$data' in $file.\n";
    }
    return \%md;
}

1;
