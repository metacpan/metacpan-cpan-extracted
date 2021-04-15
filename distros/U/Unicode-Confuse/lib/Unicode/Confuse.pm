package Unicode::Confuse;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/confusable canonical/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.03';
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
    if ($c =~ $re) {
	return $data->{confusables}{$c};
    }
}

1;
