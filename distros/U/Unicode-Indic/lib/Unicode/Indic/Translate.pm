package Unicode::Indic::Translate;
use strict;
our $VERSION = 0.01;

sub new{
  my $proto = shift;
  my $class = ref($proto)||$proto;
  my $self = {
    @_
  };
  bless $self, $class;
}


sub translate{
  my $self = shift;
  my $fromlang = $self->{FromLang};
  my $tolang   = $self->{ToLang};
  my $infile   = $self->{InFile};
  my $outfile  = $self->{OutFile};
  $tolang = "Unicode::Indic::$tolang";
  $fromlang = "Unicode::Indic::$fromlang";
  open(INPUT,"<$infile");
  open(OUTPUT,">$outfile");
  binmode(INPUT,":utf8") unless $fromlang eq 'Unicode::Indic::Phonetic';
  binmode(OUTPUT,":utf8") unless $tolang eq 'Unicode::Indic::Phonetic';
  my @input = <INPUT>;
  my $buf = "@input";
  eval "use $tolang";
  my $out = $tolang->new();
  if ($fromlang ne 'Unicode::Indic::Phonetic'){
    eval "use $fromlang;";
    print "from lang is $fromlang\n";
    my $in = $fromlang->new();
    $buf = $in->romanise($buf);
  }
  print "tolang is $tolang \n";
  $buf = $out->translate($buf) unless $tolang eq 'Unicode::Indic::Phonetic';
  print OUTPUT "$buf\n";
}

1;

