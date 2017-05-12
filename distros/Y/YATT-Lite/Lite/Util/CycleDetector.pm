# -*- coding: utf-8 -*-

# This package is used to implement modified version of following algorithm:
#
#   http://en.wikipedia.org/wiki/Topological_sorting#CITEREFCormenLeisersonRivestStein2001
#
#   Cormen, Thomas H.; Leiserson, Charles E.; Rivest, Ronald L.;
#   Stein, Clifford (2001),
#   "Section 22.4: Topological sort", Introduction to Algorithms (2nd ed.),
#   MIT Press and McGraw-Hill, pp. 549–552, ISBN 0-262-03293-7.
#

package YATT::Lite::Util::CycleDetector;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;

use Exporter qw/import/;
our @EXPORT_OK = qw/Visits/;

sub Visits () {__PACKAGE__}
use YATT::Lite::MFields qw/nodes time/;

use YATT::Lite::Types
  ([Node => fields => [qw/fname discovered finished color parent/]]);
use YATT::Lite::Util::Enum
  (NTYPE_ => [qw/WHITE GRAY BLACK/]
   , EDGE_ => [qw/TREE BACK FORW CROSS/]);

sub start {
  my ($pack, $fname) = @_;
  my Visits $vis = bless {}, $pack;
  $vis->{time} = 0;
  $vis->ensure_make_node($fname);
  $vis->visit_node($fname);
  $vis;
}

sub fname2id {
  (my Visits $vis, my $fname) = @_;
  my ($dev, $inode) = stat($fname);
  if (grep {$_ eq ''} $dev, $inode) {
    $fname; # Workaround
  } else {
    join "_", $dev, $inode;
  }
}

sub has_node {
  (my Visits $vis, my $fname) = @_;
  $vis->{nodes}{$vis->fname2id($fname)};
}

sub ensure_make_node {
  (my Visits $vis, my @path) = @_;
  foreach my $fname (@path) {
    next if $vis->{nodes}{$vis->fname2id($fname)};
    $vis->make_node($fname);
  }
  @path;
}

sub make_node {
  (my Visits $vis, my ($fname)) = @_;
  $vis->{nodes}{$vis->fname2id($fname)} = my Node $node = {};
  $node->{fname} = $fname;
  $node->{color} = NTYPE_WHITE;
  $node;
}

sub visit_node {
  (my Visits $vis, my ($fname, $parent)) = @_;
  my Node $node = $vis->{nodes}{$vis->fname2id($fname)}
    or croak "No such path in visits! $fname";
  $node->{color} = NTYPE_GRAY;
  $node->{discovered} = ++$vis->{time};
  $node->{parent} = $vis->{nodes}{$vis->fname2id($parent)} if $parent;
  $node;
}

sub finish_node {
  (my Visits $vis, my $fname) = @_;
  my Node $node = $vis->{nodes}{$vis->fname2id($fname)}
    or croak "No such path in visits! $fname";
  $node->{color} = NTYPE_BLACK;
  $node->{finished} = ++$vis->{time};
  $node;
}

sub check_cycle {
  (my Visits $vis, my ($to, $from)) = @_;
  my Node $dest = $vis->{nodes}{$vis->fname2id($to)}
    or croak "No such path in visits! $to";
  if ($dest->{color} == NTYPE_WHITE) {
    # tree edge
    $vis->visit_node($to);
  } elsif ($dest->{color} == NTYPE_GRAY) {
    # back edge!
    return [$to, $vis->list_cycle($dest)]
  } else {
    # forward or cross
  }
  return;
}

sub list_cycle {
  (my Visits $vis, my Node $node) = @_;
  my @path;
  while ($node and $node->{parent}) {
    $node = $node->{parent};
    push @path, $node->{fname};
  }
  @path;
}

1;
