#!/usr/bin/perl
use warnings;
use strict;
use utf8;
use Encode qw(is_utf8 _utf8_off _utf8_on from_to);
use File::Spec::Functions qw(rel2abs);
use Test::More qw(no_plan);
use Log::Log4perl qw(:easy);
use File::Temp qw(tempfile);
use Data::Hexdumper;
use XML::Simple;

my $data_dir = "data";
$data_dir = "t/$data_dir" unless -d $data_dir;

#Log::Log4perl->easy_init($DEBUG);

my($fh, $outfile) = tempfile(CLEANUP => 1);

use XML::RSS::FromHTML::Simple;

#my $ua = LWP::UserAgent->new(parse_head => 0);

my $f = XML::RSS::FromHTML::Simple->new({
    url => "file://" . rel2abs("$data_dir/utf8.html"),
    base_url  => "http://microsoft.com",
    rss_file  => $outfile,
    #encoding => 'utf8',
    # ua => $ua,
});

{ $SIG{__WARN__} = sub {};
  $f->make_rss();
}

ok(-s $outfile, "RSS file created");

  # Read XML file back in
$XML::Simple::PREFERRED_PARSER = "XML::Parser";
my $data = XMLin($outfile);

binmode STDERR, ":utf8";
binmode STDOUT, ":utf8";

my $got = $data->{item}->{title};
_utf8_on($got);
ok(is_utf8($got), "got string is utf8");

my $exp = "Hüsker Dü";
ok(is_utf8($exp), "exp string is utf8");

my $exp_dump;
my $got_dump;

{
    my $exp2 = $exp;
    my $got2 = $got;
    _utf8_off($exp2);
    _utf8_off($got2);
    $exp_dump = hexdump(data => $exp2);
    $got_dump = hexdump(data => $got2);
}

is($got, $exp, "Title with umlaut");
DEBUG "got_dump=$got_dump exp_dump=$exp_dump";
is($got_dump, $exp_dump, "Dump with umlaut");
