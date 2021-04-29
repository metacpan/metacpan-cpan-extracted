package Unicode::Confuse;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/
    canonical
    confusable
    similar
/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.05';
use Unicode::Confuse::Regex;

my $re = $Unicode::Confuse::Regex::re;

use JSON::Parse 'read_json';

my $jfile = __FILE__;
$jfile =~ s!\.pm$!/confusables.json!;
our $data = read_json ($jfile);

sub confusable
{
    my ($c) = @_;
    return $c =~ $re;
}

sub canonical
{
    my ($c) = @_;
    my $r;
    if ($c =~ $re) {
	$r = $data->{confusables}{$c};
	if (! defined $r) {
	    # $r is already the canonical form
	    $r = $c;
	}
    }
    return $r;
}

sub similar
{
    my ($c) = @_;
    my $d = canonical ($c);
    if (! $d) {
	return ();
    }
    my @similar;
    # The reverse data does not include the canonical form in its
    # list.
    push @similar, $d;
    my $r = $data->{reverse}{$d};
    push @similar, @$r;
    return @similar;
}

1;
