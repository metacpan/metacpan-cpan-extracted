#!/usr/bin/perl

use strict;
use Text::Distill qw(DetectBookFormat TextToGems GemsValidate ExtractSingleZipFile);
use Getopt::Long;
use LWP::UserAgent;
use JSON::XS;
use Data::Dumper;

binmode STDOUT, ":utf8";

my %OPT;
GetOptions(
	'help' => \$OPT{'help'},
	'full-info' => \$OPT{'fullinfo'},
) || help();

help() if $OPT{'help'};

my $FilePath = $ARGV[0] || die "please define FILEPATH as first argument (look ./plagiarism_check.pl --help)";
my $Url = $ARGV[1] || "http://partnersdnld.litres.ru/copyright_check_by_gems/";

die "file '$FilePath' not exists" unless -f $FilePath;

my $FileType = DetectBookFormat($FilePath);
die "can't detect file '$FileType'" unless $FileType;

if ($FileType =~ /^(.+?)\.zip$/) {
	$FileType = $1;
	$FilePath = ExtractSingleZipFile($FilePath,$FileType);
}

my $Text = $Text::Distill::Extractors->{$FileType}($FilePath);
my $Gems = TextToGems($Text);

my $Result = GemsValidate($Gems, $Url);

if ($OPT{'fullinfo'}) {
	print JSON::XS->new->pretty(1)->encode($Result);
} else {
	print $Result->{'verdict'}."\n";
}

sub help {
  print <<_END

plagiarism_check.pl - checks your ebook againts known texts

Script uses check_by_gems API (https://goo.gl/xmFMdr). You can
select any "check service" provider with CHECKURL (see below),
by default text checked with LitRes copyright-check service:
http://partnersdnld.litres.ru/copyright_check_by_gems/

USAGE
> plagiarism_check.pl FILEPATH [CHECKURL] [--full-info --help]


EXAMPLE
> plagiarism_check.pl /home/file.epub --full-info


PARAMS
    FILEPATH    path to file for check

    CHECKURL    url of validating API to check file with. By default:
	http://partnersdnld.litres.ru/copyright_check_by_gems/

    --full-info  show full info of checked

    --help      show this information

OUTPUT
    Ebook statuses explained:
    - protected: there are copyright on this book. Or it is
	forbidden for distribution by some other reason (law f.e.)

    - free: ebook content owner distributes it for free (but
	content may still be protected from certan use)

    - public_domain: this it public domain, no restrictions
	for use at all

    - unknown: service have has no info on this text


See more information at http://search.cpan.org/perldoc?Text::Distill

_END
;
exit;
}
