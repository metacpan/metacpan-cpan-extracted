#!/usr/bin/env perl
use strict;
use warnings;
use Wx;
use Wx::Perl::DataWalker;
use YAML::XS;
use Getopt::Long qw(GetOptions);

sub usage {
  my $msg = shift;
  warn("$msg\n\n") if defined $msg;

  warn <<HERE;
Usage: $0 --eval '{foo => "bar", baz => []}'
       $0 --yaml YAMLFILE
HERE
  exit(1);
}

my $eval;
my $yamlfile;
GetOptions(
  'h|help' => \&usage,
  'e|eval=s' => \$eval,
  'y|yaml=s' => \$yamlfile,
);

if (1!=grep {defined $_} ($eval, $yamlfile)) {
  usage("You need to supply exactly one of the --eval or --yaml options");
}

my $data;
if (defined $eval) {
  $data = eval "$eval";
  if ($@) {
    usage("Could not eval your expression: $@");
  }
}
elsif (defined $yamlfile) {
  usage("Could not find YAML input file '$yamlfile'") unless -f $yamlfile;
  $data = YAML::XS::LoadFile($yamlfile)
}
else {
  die "Should not happen";
}

package MyApp;
our @ISA = qw(Wx::App);

sub OnInit {
    my $self = shift;

    my $frame = Wx::Perl::DataWalker->new(
      {data => $data},
      undef, -1,
      "dataWalker",
    );
    $self->SetTopWindow($frame);
    $frame->Show(1);
    $frame->SetSize(500,500);

    return 1;
}


package main;
my $app = MyApp->new();
$app->MainLoop();

