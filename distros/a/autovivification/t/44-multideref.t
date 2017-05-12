#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner tests => 4 * 4 * (8 ** 3) * 2;

my $depth = 3;

my $magic_val = 123;

my @prefixes = (
 sub { $_[0]                },
 sub { "$_[0] = $magic_val" },
 sub { "exists $_[0]"       },
 sub { "delete $_[0]"       },
);

my  (@vlex, %vlex, $vrlex);
our (@vgbl, %vgbl, $vrgbl);

my @heads = (
 '$vlex',    # lexical array/hash
 '$vgbl',    # global array/hash
 '$vrlex->', # lexical array/hash reference
 '$vrgbl->', # global array/hash reference
);

my  $lex;
our $gbl;

my @derefs = (
 '[0]',      # array const (aelemfast)
 '[$lex]',   # array lexical
 '[$gbl]',   # array global
 '[$lex+1]', # array complex
 '{foo}',    # hash const
 '{$lex}',   # hash lexical
 '{$gbl}',   # hash global
 '{"x$lex"}' # hash complex
);

sub reset_vars {
 (@vlex, %vlex, $vrlex) = ();
 (@vgbl, %vgbl, $vrgbl) = ();
 $lex = 1;
 $gbl = 2;
}

{
 package autovivification::TestIterator;

 sub new {
  my $class = shift;

  my (@lists, @max);
  for my $arg (@_) {
   next unless defined $arg;
   my $type = ref $arg;
   my $list;
   if ($type eq 'ARRAY') {
    $list = $arg;
   } elsif ($type eq '') {
    $list = [ 1 .. $arg ];
   } else {
    die "Invalid argument of type $type";
   }
   my $max = @$list;
   die "Empty list" unless $max;
   push @lists, $list;
   push @max,   $max;
  }

  my $len = @_;
  bless {
   len   => $len,
   max   => \@max,
   lists => \@lists,
   idx   => [ (0) x $len ],
  }, $class;
 }

 sub next {
  my $self = shift;

  my ($len, $max, $idx) = @$self{qw<len max idx>};

  my $i;
  ++$idx->[0];
  for ($i = 0; $i < $len; ++$i) {
   if ($idx->[$i] == $max->[$i]) {
    $idx->[$i] = 0;
    ++$idx->[$i + 1] unless $i == $len - 1;
   } else {
    last;
   }
  }

  return $i < $len;
 }

 sub items {
  my $self = shift;

  my ($len, $lists, $idx) = @$self{qw<len lists idx>};

  return map $lists->[$_]->[$idx->[$_]], 0 .. ($len - 1);
 }
}

my $iterator = autovivification::TestIterator->new(
 \@prefixes, \@heads, (\@derefs) x $depth,
);
do {
 my ($prefix, @elems) = $iterator->items;
 my $code = $prefix->(join '', @elems);
 my $exp  = ($code =~ /^\s*exists/) ? !1
                                    : (($code =~ /=\s*$magic_val/) ? $magic_val
                                                                   : undef);
 reset_vars();
 my ($res, $err) = do {
  local $SIG{__WARN__} = sub { die @_ };
  local $@;
  my $r = eval <<" CODE";
  no autovivification;
  $code
 CODE
  ($r, $@)
 };
 is $err, '',   "$code: no exception";
 is $res, $exp, "$code: value";
} while ($iterator->next);
