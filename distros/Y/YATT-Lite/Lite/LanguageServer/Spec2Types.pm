#!/usr/bin/env perl
package YATT::Lite::LanguageServer::Spec2Types;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use File::AddInc;
use MOP4Import::Base::CLI_JSON -as_base
  , [fields =>
     [with_field_docs => doc => "generate field document too"],
     [with_field_typeinfos => doc => "generate field typeinfo too"],
   ]
  , [output_format => pairlist => sub {
    my ($self, $outFH, @args) = @_;
    require Data::Dumper;
    foreach my $list (@args) {
      my @list = @$list;
      while (my ($k, $v) = splice @list, 0, 2) {
        # Data::Dumper always quotes numbers but it is not ideal for JSON.
        my $vd = join("", _toy_dump_numeric_as_is($v, 0));
        print $outFH do {
          defined $k ? MOP4Import::Util::terse_dump($k) : "undef()";
        }, " => $vd";
      }
    }
  }];

use YATT::Lite::LanguageServer::SpecParser qw/Interface Decl Annotated/
  , [as => 'SpecParser'];

# % parser=./Lite/LanguageServer/SpecParser.pm
# % ./Lite/LanguageServer/Spec2Types.pm --output=indented make_spec_from  "$(
# $parser extract_codeblock typescript $specFn|
# $parser cli_xargs_json extract_statement_list|
# grep -v 'interface ParameterInformation'|
# $parser cli_xargs_json --slurp tokenize_statement_list|
# $parser --flatten=0 cli_xargs_json --slurp parse_statement_list
# )" Message
# 'Message'
# [
#   [
#     'fields',
#     'jsonrpc'
#   ]
# ]

use MOP4Import::Types
  CollectedItem => [
    [fields => qw/kind name spec items parent subtypes dependency/]
  ];

sub make_typedefs_from {
  (my MY $self, my ($specDictOrArrayOrFile, @names)) = @_;
  my $specDict = $self->specdict_from($specDictOrArrayOrFile);
  my $collectedDict = $self->collect_spec_from($specDict, @names);
  my %seen;
  my @result = map {
    my CollectedItem $item = $_;
    if ($seen{$item->{name}}++) {
      ()
    } else {
      $self->typedefs_of_collected_item($item, \%seen);
    }
  } $self->reorder_collected_items($collectedDict);
  wantarray ? @result : \@result;
}

sub reorder_collected_items {
  (my MY $self, my ($collectedDict)) = @_;
  my (@result, %seen, $lastKeys);
  $lastKeys = keys %$collectedDict;
  while (keys %$collectedDict) {
    my @ready = sort(grep {
      my CollectedItem $item = $collectedDict->{$_};
      not $item->{parent}
        or $seen{$item->{parent}};
    } keys %$collectedDict);
    push @result, map {
      delete $collectedDict->{$seen{$_} = $_};
    } @ready;
    if ($lastKeys == keys %$collectedDict) {
      die "Can't reorder types. Possibly circular deps? "
        . MOP4Import::Util::terse_dump([remains => sort keys %$collectedDict]
                                       , [ok => @result]);
    }
    $lastKeys = keys %$collectedDict;
  }
  @result;
}

sub collect_spec_from {
  (my MY $self, my ($specDictOrArrayOrFile, @names)) = @_;
  my $specDict = $self->specdict_from($specDictOrArrayOrFile);
  my $collectedDict = {};
  foreach my $name (@names) {
    $self->spec_dependency_of($name, $specDict, $collectedDict);
  }
  $collectedDict;
}

sub spec_dependency_of {
  (my MY $self, my ($declOrName, $specDictOrArrayOrFile, $collectedDict, $opts)) = @_;
  $collectedDict //= {};
  my $specDict = $self->specdict_from($specDictOrArrayOrFile);
  my Decl $decl = ref $declOrName ? $declOrName : $specDict->{$declOrName};
  unless (defined $decl) {
    Carp::croak "No such type: ". MOP4Import::Util::terse_dump($declOrName);
  }
  my $sub = $self->can("spec_dependency_of__$decl->{kind}") or do {
    print STDERR "Skipped: not yet supported in spec_dependency_of($decl->{name}): $decl->{kind}"
      . MOP4Import::Util::terse_dump($decl), "\n" unless $self->{quiet};
    return;
  };
  my CollectedItem $item = $collectedDict->{$decl->{name}}
    //= $sub->($self, $decl, $specDict, $collectedDict, $opts);

  wantarray ? ($item, $collectedDict) : $item;
}

sub unwrap_annotation {
  (my Annotated $rec) = @_;
  if (not ref $rec) {
    $rec;
  } elsif (ref $rec eq 'ARRAY') {
    [map {unwrap_annotation($_)} @$rec];
  } elsif (ref $rec eq 'HASH') {
    my $body = $rec->{body};
    if (not ref $body) {
      $body;
    } else {
      [map {unwrap_annotation($_)} @$body];
    }
  }
}

*spec_dependency_of__class = *spec_dependency_of__interface; *spec_dependency_of__class = *spec_dependency_of__interface;

sub spec_dependency_of__interface {
  (my MY $self, my Interface $decl, my ($specDictOrArrayOrFile, $collectedDict, $opts)) = @_;
  $collectedDict //= {};
  my $specDict = $self->specdict_from($specDictOrArrayOrFile);

  # Origin of dependency references
  my CollectedItem $from = $self->intern_collected_item_in($collectedDict, $decl);
  if (my $nm = $decl->{extends}) {
    $from->{parent} = $nm;
    my Decl $superSpec = $specDict->{$nm}
      or Carp::croak "Unknown base type for $decl->{name}: $nm";
    my CollectedItem $superItem
      = $self->spec_dependency_of($superSpec, $specDict, $collectedDict, $opts);
    push @{$superItem->{subtypes}}, $from;
  }
  foreach my Annotated $slot (@{$decl->{body}}) {
    next if ref $slot eq 'HASH' and $slot->{deprecated};
    my $slotDesc = ref $slot eq 'HASH' ? $slot->{body} : $slot;
    unless (ref $slotDesc) {
      die "Invalid slotDesc: $slotDesc";
    }
    my ($slotName, @typeUnion) = @$slotDesc;
    $slotName =~ s/\?\z//;
    my @fieldOpts;
    if ($self->{with_field_docs} and ref $slot eq 'HASH') {
      push @fieldOpts, doc => $slot->{comment};
    }
    if ($self->{with_field_typeinfos}) {
      my @tu = map { unwrap_annotation($_) } @typeUnion;
      push @fieldOpts, typeinfo => (@tu == 1 ? $tu[0] : \@tu);
    }
    push @{$from->{items}}, @fieldOpts ? [$slotName, @fieldOpts] : $slotName;
    foreach my $typeExprItem (@typeUnion) {
      my $typeExprString = do {
        if (not ref $typeExprItem) {
          $typeExprItem;
        } elsif (ref $typeExprItem eq 'ARRAY' and @$typeExprItem == 2 and $typeExprItem->[-1] eq '[]') {
          $typeExprItem->[0];
        } else {
          warn "Skipped: not yet implemented type item: "
            .MOP4Import::Util::terse_dump($typeExprItem);
          next;
        }
      };
      $typeExprString =~ /[A-Z]/
        or next;
      my Decl $typeSpec = $specDict->{$typeExprString}
        or next;
      $from->{dependency}{$typeExprString}
        //= $self->spec_dependency_of($typeSpec, $specDict, $collectedDict, $opts);
    }
  }
  $from;
}

sub unwrap_comment_decl {
  (my MY $self, my Decl $decl) = @_;
  if (not defined $decl->{kind}
      and exists $decl->{comment} and exists $decl->{body}) {
    $decl->{body}
  } else {
    $decl;
  }
}

sub spec_dependency_of__namespace {
  (my MY $self, my Decl $decl, my ($specDictOrArrayOrFile, $collectedDict, $opts)) = @_;
  $collectedDict //= {};
  my $specDict = $self->specdict_from($specDictOrArrayOrFile);

  my CollectedItem $from = $self->intern_collected_item_in($collectedDict, $decl);

  foreach my Decl $slot (map {$self->unwrap_comment_decl($_)} @{$decl->{body}}) {
    next unless ($slot->{kind} // '') eq 'const';
    my ($typeExprString, $value) = do {
      if (ref $slot->{body}) {
        @{$slot->{body}};
      } else {
        (undef,$slot->{body});
      }
    };

    push @{$from->{items}}, [$slot->{name}, $value];

    if (defined $typeExprString) {
      $typeExprString =~ /[A-Z]/
        or next;
      my Decl $typeSpec = $specDict->{$typeExprString}
        or next;

      $from->{dependency}{$typeExprString}
        //= $self->spec_dependency_of($typeSpec, $specDict, $collectedDict, $opts);
    }
  }

  $from;
}

sub intern_collected_item_in {
  (my MY $self, my $collectedDict, my Decl $decl, my $opts) = @_;
  $collectedDict->{$decl->{name}} //= do {
    my CollectedItem $item = {};
    $item->{kind} = $decl->{kind};
    $item->{name} = $decl->{name};
    if ($opts->{spec}) {
      $item->{spec} = $decl;
    }
    $item;
  };
}

sub extract_spec_from {
  (my MY $self, my ($specDictOrArrayOrFile, @names)) = @_;
  my $specDict = $self->specdict_from($specDictOrArrayOrFile);
  map {
    $specDict->{$_}
  } @names;
}

sub specdict_from {
  (my MY $self, my ($specDictOrArrayOrFile)) = @_;
  if (not ref $specDictOrArrayOrFile) {
    my @decls = do {
      if ($specDictOrArrayOrFile =~ /\.md\z/) {
        $self->SpecParser->new->parse_files($specDictOrArrayOrFile)
      } else {
        # $self->cli_read_file__json($specDictOrArrayOrFile);
        $self->cli_slurp_xargs_json($specDictOrArrayOrFile);
      }
    };
    $self->gather_by_name(@decls);
  } elsif (ref $specDictOrArrayOrFile eq 'ARRAY') {
    $self->gather_by_name(
      @$specDictOrArrayOrFile
    );
  } elsif (ref $specDictOrArrayOrFile eq 'HASH') {
    $specDictOrArrayOrFile;
  } else {
    Carp::croak "Unsupported specDict: "
      . MOP4Import::Util::terse_dump($specDictOrArrayOrFile);
  }
}

#========================================

sub typedefs_of_collected_item {
  (my MY $self, my CollectedItem $item, my $seen) = @_;
  $seen->{$item->{name}}++;

  my $sub = $self->can("typedefs_of_collected_item_of__$item->{kind}") or do {
    warn "Skipped: not yet implemented to generate typedefs of $item->{kind} for $item->{name};";
    return;
  };

  $sub->($self, $item, $seen);
}

*typedefs_of_collected_item_of__class = *typedefs_of_collected_item_of__interface; *typedefs_of_collected_item_of__class = *typedefs_of_collected_item_of__interface;

sub typedefs_of_collected_item_of__interface {
  (my MY $self, my CollectedItem $item, my $seen) = @_;
  # Type is not used currently.

  # If item has no fields, no need to generate field specs.
  return unless $item->{items};

  my @defs = ([fields => @{$item->{items}}]);
  if ($item->{subtypes}) {
    push @defs, [subtypes => map {
      $self->typedefs_of_collected_item($_, $seen)
    } @{$item->{subtypes}}]
  }
  ($item->{name}, \@defs);
}

sub typedefs_of_collected_item_of__namespace {
  (my MY $self, my CollectedItem $item, my $seen) = @_;

  return unless $item->{items};

  (undef, [map {
    my ($name, $value) = @$_;
    [constant => "$item->{name}__$name" => $value];
  } @{$item->{items}}]);
}

#========================================

sub gather_by_name {
  (my MY $self, my @decls) = @_;
  my %dict;
  foreach my Interface $if (@decls) {
    next unless ref $if eq 'HASH';
    $dict{$if->{name}} = $if;
  }
  \%dict;
}

sub _toy_dump_numeric_as_is {
  my ($obj, $depth) = @_;
  my $indent = "  " x $depth;
  if (not defined $obj) {
    ($indent."undef(),\n");
  } elsif (not ref $obj) {
    if ($obj =~ /^[-+]?\d+\z/) {
      ($indent."$obj,\n");
    } else {
      $obj =~ s/\'/\\'/g;
      ($indent."'$obj',\n");
    }
  } elsif (ref $obj eq 'ARRAY') {
    $indent."[\n".join("", map {
      _toy_dump_numeric_as_is($_, $depth+1);
    } @$obj).$indent."],\n";
  } else {
    Carp::croak "Not supported type: ". ref $obj;
  }
}

MY->run(\@ARGV) unless caller;

1;
