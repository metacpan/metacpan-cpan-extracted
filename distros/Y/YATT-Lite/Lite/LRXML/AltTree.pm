#!/usr/bin/env perl
package YATT::Lite::LRXML::AltTree;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use File::AddInc;
use MOP4Import::Base::CLI_JSON -as_base
  , [fields =>
     [string => doc => "source template string"],
     [with_source => default => 1, doc => "include source for intermediate nodes"],
     [with_text => doc => "include all text node"],
     [with_range => default => 1, doc => "include range for LSP"],
   ];

use YATT::Lite::LanguageServer::Protocol qw/Position Range/;

use MOP4Import::Types
  AltNode => [[fields => qw/
                             kind path source
                             symbol_range tree_range
                             subtree
                             value
                           /]];

use YATT::Lite::Constants
  qw/NODE_TYPE
     NODE_BEGIN NODE_END NODE_LNO
     NODE_SYM_END
     NODE_PATH NODE_BODY NODE_VALUE
     NODE_ATTLIST NODE_AELEM_HEAD NODE_AELEM_FOOT
     TYPE_ELEMENT TYPE_LCMSG
     TYPE_ATT_TEXT
     TYPE_ATT_NESTED
     TYPE_COMMENT
     TYPE_ENTITY

     node_unwrap_attlist
    /;
# XXX: Adding *TYPE_ / @TYPE_ to @YATT::Lite::Constants::EXPORT_OK didn't work
# Why?
*TYPES = *YATT::Lite::Constants::TYPE_;*TYPES = *YATT::Lite::Constants::TYPE_;
our @TYPES;

use YATT::Lite::LRXML::FormatEntpath qw/format_entpath/;

use YATT::Lite::XHF::Dumper qw/dump_xhf/;
sub cli_write_fh_as_xhf {
  (my MY $self, my ($outFH, @args)) = @_;
  foreach my $list (@args) {
    print $outFH $self->dump_xhf($list), "\n";
  }
}

sub convert_tree {
  (my MY $self, my ($tree, $with_text)) = @_;
  map {
    if (not ref $_) {
      ($with_text || $self->{with_text}) ? $_ : ();
    } elsif (not ref $_->[NODE_TYPE] and my $sub = $self->can("convert_node__$TYPES[$_->[NODE_TYPE]]")) {
      $sub->($self, $_, $with_text);
    } elsif (not ref $_->[NODE_TYPE]) {
      my AltNode $altnode = +{};
      $altnode->{kind} = $TYPES[$_->[NODE_TYPE]];
      $altnode->{path} = $self->convert_path_of($_);

      $self->fill_source_range_of($altnode, $_);

      if ($_->[NODE_TYPE] == TYPE_ELEMENT || $_->[NODE_TYPE] == TYPE_ATT_NESTED) {
        my @origSubTree;
        if (my $attlist = $self->node_unwrap_attlist($_->[NODE_ATTLIST])) {
          push @origSubTree, $attlist;
        }
        if (my $subtree = $_->[NODE_AELEM_HEAD]) {
          push @origSubTree, $subtree;
        }
        if (defined $_->[NODE_BODY] and ref $_->[NODE_BODY] eq 'ARRAY') {
          push @origSubTree, $self->node_body_slot($_);
        }
        if (my $subtree = $_->[NODE_AELEM_FOOT]) {
          push @origSubTree, $subtree;
        }
        $altnode->{subtree} = [map {
          $self->convert_tree($_, $with_text);
        } @origSubTree];
      } else {
        if ($_->[NODE_TYPE] == TYPE_COMMENT) {
          $altnode->{value} = $_->[NODE_ATTLIST];
        } elsif ($_->[NODE_TYPE] == TYPE_ENTITY) {
          $altnode->{value} = [@{$_}[NODE_BODY .. $#$_]];
        } else {
          if ($_->[NODE_TYPE] == TYPE_ATT_TEXT) {
            $altnode->{symbol_range}
              = $self->make_range($_->[NODE_BEGIN]
                                  , ($_->[NODE_BEGIN] + length($_->[NODE_PATH]))
                                  , $_->[NODE_LNO])
              if defined $_->[NODE_BEGIN] and defined $_->[NODE_PATH];
          }
          if (defined $_->[NODE_BODY] and ref $_->[NODE_BODY] eq 'ARRAY') {
            $altnode->{subtree} = [$self->convert_tree(
              $self->node_body_slot($_), $with_text
            )];
          } else {
            $altnode->{value} = $_->[NODE_BODY];
          }
        }
      }
      $altnode;
    } else {
      # XXX: Is this ok?
      print STDERR "# really?: ".YATT::Lite::Util::terse_dump($tree), "\n";
      ...;
      # $self->convert_tree($_);
    }
  } @$tree;
}

sub fill_source_range_of {
  (my MY $self, my AltNode $altnode, my $orig) = @_;
  if (defined $orig->[NODE_BEGIN] and defined $orig->[NODE_END]
      and $orig->[NODE_BEGIN] < length($self->{string})
      and $orig->[NODE_END] <= length($self->{string})) {
    my $source = substr($self->{string}, $orig->[NODE_BEGIN]
                        , $orig->[NODE_END] - $orig->[NODE_BEGIN]);
    if ($self->{with_source}) {
      $altnode->{source} = $source;
    }
    if ($self->{with_range}) {
      $altnode->{tree_range} = $self->make_range(
        $orig->[NODE_BEGIN],
        $orig->[NODE_END],
        $orig->[NODE_LNO],
        ($source =~ tr|\n||)
      );
      if ($orig->[NODE_SYM_END]) {
        $altnode->{symbol_range} = $self->make_range(
          $orig->[NODE_BEGIN],
          $orig->[NODE_SYM_END] - 1,
          $orig->[NODE_LNO],
        );
      }
    }
  }
}

sub convert_node__ENTITY {
  (my MY $self, my ($node, $with_text)) = @_;
  my AltNode $entpathNode = {};
  $entpathNode->{kind} = 'entpath';
  $self->fill_source_range_of($entpathNode, $node);
  my $pos = $node->[NODE_BEGIN] + length($node->[NODE_PATH]) + 1;
  $entpathNode->{subtree} = [$self->convert_node_entpath(
    $with_text, $pos, $node->[NODE_LNO],
    @{$node}[NODE_BODY .. $#$node],
  )];
  $entpathNode;
}

sub convert_node_entpath {
  (my MY $self, my ($with_text, $pos, $line, @pathItems)) = @_;
  my (@subtree);
  foreach my $item (@pathItems) {
    my ($kind, @args) = @$item;
    if (my $sub = $self->can("convert_node_entpath__$kind")) {
      if (my AltNode $subtree = $sub->($self, $with_text, $pos, $line, $item)) {
        push @subtree, $subtree;
        $pos += length $subtree->{source};
      } else {
        $pos += length format_entpath($item);
      }
    } else {
      my $begin = $pos;
      my $str = format_entpath($item);
      my AltNode $entNode;
      push @subtree, $entNode = {};
      $entNode->{kind} = $kind;
      $entNode->{source} = $str;
      if (@args) {
        $self->convert_entpath_args($entNode, $with_text, $pos, $line, @args);
      }
      my $end = $pos += length $str;
      if ($self->{with_range}) {
        $entNode->{tree_range} = $self->make_range($begin, $end, $line);
      }
    }
  }
  @subtree;
}

sub convert_node_entpath__text {
  (my MY $self, my ($with_text, $pos, $line, $item)) = @_;
  return unless $with_text;
  ...;
}

sub convert_node_entpath__call {
  (my MY $self, my ($with_text, $pos, $line, $item)) = @_;
  my ($kind, $funcName, @args) = @$item;
  my $begin = $pos;
  my AltNode $entNode = {};
  $entNode->{kind} = $kind;
  $entNode->{path} = $funcName;
  $pos += length(":$funcName(");
  if ($self->{with_range}) {
    $entNode->{symbol_range}
      = $self->make_range($begin, $pos, $line);
  }
  $entNode->{source} = my $str = format_entpath($item);
  if (@args) {
    $self->convert_entpath_args($entNode, $with_text, $pos, $line, @args);
  }
  my $end = $begin + length $str;
  if ($self->{with_range}) {
    $entNode->{tree_range} = $self->make_range($begin, $end, $line);
  }
  $entNode;
}

*convert_node_entpath__invoke = *convert_node_entpath__call;
*convert_node_entpath__invoke = *convert_node_entpath__call;
*convert_node_entpath__prop = *convert_node_entpath__call;
*convert_node_entpath__prop = *convert_node_entpath__call;

sub convert_node_entpath__var {
  (my MY $self, my ($with_text, $pos, $line, $item)) = @_;
  my ($kind, $varName) = @$item;
  my $begin = $pos;
  my AltNode $entNode = {};
  $entNode->{kind} = $kind;
  $entNode->{path} = $varName;
  $entNode->{source} = my $str = format_entpath($item);
  $pos += length($str);
  my $end = $begin + length $str;
  if ($self->{with_range}) {
    $entNode->{symbol_range}
      = $entNode->{tree_range} = $self->make_range($begin, $end, $line);
  }
  $entNode;
}

sub convert_entpath_args {
  (my MY $self, my AltNode $entNode, my ($with_text, $pos, $line, @args)) = @_;
  foreach my $arg (@args) {
    if (not ref $arg) {
      $pos += length $arg;
    } else {
      if (ref $arg eq 'ARRAY' and ref $arg->[0] eq 'ARRAY') {
        # pipeline
        push @{$entNode->{subtree}}
          , $self->convert_node_entpath($with_text, $pos, $line, @$arg);
      } elsif (ref $arg eq 'ARRAY') {
        # single item
        push @{$entNode->{subtree}}
          , $self->convert_node_entpath($with_text, $pos, $line, $arg);
      } else {
        die "Really?";
      }
      $pos += length format_entpath(YATT::Lite::Constants::lxnest($arg));
    }
  } continue {
    $pos += length(",");
  }
}

sub make_range {
  (my MY $self, my ($begin, $end, $lineno, $nlines)) = @_;
  my Range $range = +{};
  $range->{start} = do {
    my Position $p;
    $p->{character} = $self->column_of_source_pos($self->{string}, $begin)-1;
    $p->{line} = $lineno - 1;
    $p;
  };
  $range->{end} = do {
    my Position $p;
    $p->{character} = $self->column_of_source_pos($self->{string}, $end-1, 1);
    $p->{line} = $lineno - 1 + ($nlines // 0);
    $p;
  };
  $range;
}

sub column_of_source_pos {
  my $pos = $_[2];
  if ($_[3] and substr($_[1], $pos, 1) eq "\n") {
    $pos--;
  }
  if ((my $found = rindex($_[1], "\n", $pos)) >= 0) {
    $pos - $found;
  } else {
    $pos;
  }
}

sub node_body_slot {
  my ($self, $node) = @_;
  if ($node->[NODE_TYPE] == TYPE_ELEMENT) {
    return $node->[NODE_BODY] ? $node->[NODE_BODY][NODE_VALUE] : undef;
  } elsif ($node->[NODE_TYPE] == TYPE_LCMSG) {
    return $node->[NODE_BODY] ? $node->[NODE_BODY][0] : undef;
  } else {
    return $node->[NODE_VALUE];
  }
}

sub convert_path_of {
  my ($self, $node) = @_;
  my $path = $node->[NODE_PATH];
  if ($path and ref $path and @$path and ref $path->[0]) {
    [$self->convert_tree($path, 1)]; # with_text
  } else {
    $path;
  }
}

sub list_types {
  @TYPES;
}

MY->run(\@ARGV) unless caller;
1;
