#!/usr/bin/env perl
package YATT::Lite::Inspector;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use File::AddInc;
use MOP4Import::Base::CLI_JSON -as_base
  , [fields =>
       qw/_SITE _app_root _file_line_cache/,
     [dir => doc => "starting directory to search app.psgi upward"],
     [emit_absolute_path => doc => "emit absolute path instead of \$app_root-relative"],
     [site_class => doc => "class name for SiteApp (to load app.psgi)", default => "YATT::Lite::WebMVC0::SiteApp"],
     [ignore_symlink => doc => "ignore symlinked templates"],
     [detail => doc => "show argument details"],
     [line_base => default => 1],
     # qw/debug/,
   ];

use JSON::MaybeXS;

use MOP4Import::Util qw/lexpand symtab terse_dump/;

use MOP4Import::Types
  Zipper => [[fields => qw/array index path defs/]]
  , SymbolInfo => [[fields => qw/kind name filename range refpos/]
                   , [subtypes =>
                      , VarInfo => [[fields => qw/type detail/]]
                    ]
                 ]
  , EntityInfo => [[fields => qw/name entns file line/]]
  , LintResult => [[fields => qw/type is_success
                                 info
                                 message
                                 file diagnostics/]]
  ;

use parent qw/File::Spec/;

#----------------------------------------

use URI::file;
use Text::Glob;
use Plack::Util;
use File::Basename;
use File::stat;

use Try::Tiny;

use YATT::Lite;
use YATT::Lite::Factory;
use YATT::Lite::LRXML;
use YATT::Lite::Core qw/Part Widget Template/;
use YATT::Lite::CGen::Perl;

use YATT::Lite::LRXML::AltTree qw/column_of_source_pos AltNode/;

use YATT::Lite::Walker qw/walk walk_vfs_folders/;

use YATT::Lite::LanguageServer::Protocol
  qw/Position Range MarkupContent
     Location
     Diagnostic
     TextDocumentContentChangeEvent
     DocumentSymbol
    /
  , qr/^DiagnosticSeverity__/
  , qr/^SymbolKind__/
  ;

#========================================

sub after_configure_default {
  (my MY $self) = @_;
  $self->SUPER::after_configure_default;

  $self->{_SITE} = do {
    my $class = Plack::Util::load_class($self->{site_class});
    $class->load_factory_offline(dir => $self->{dir})
      or die "Can't find YATT app script!\n";
  };

  $self->{_app_root} = $self->{_SITE}->cget('app_root');
}


#========================================

sub cmd_ctags_symbols {
  (my MY $self, my @args) = @_;
  $self->configure($self->parse_opts(\@args));
  my ($dir) = @args;

  my $cwdOrFileList = $self->list_target_dirs($dir);

  walk(
    factory => $self->{_SITE},
    from => $cwdOrFileList,
    ignore_symlink => $self->{ignore_symlink},
    widget => sub {
      my ($args) = @_;
      my Part $widget = $args->{part};
      my Template $tmpl = $widget->{cf_folder};
      my $path = $tmpl->{cf_path};
      $self->emit_ctags($args->{kind}, $args->{name}, $path, $widget->{cf_startln});
    },
    item => sub {
      my ($args) = @_;
      my $path = $args->{tree}->cget('path');
      my ($kind, $name) = do {
        if (-l $path) {
          (symlink => readlink($path))
        } else {
          (file => $self->clean_path($path));
        }
      };
      $self->emit_ctags($kind => $name, $path, 1);
    },
  );
}

sub clean_path {
  (my MY $self, my $path) = @_;
  if (not $self->{emit_absolute_path}) {
    $path =~ s,^$self->{_app_root}/*,,;
  }
  $path;
}

#
# Same format with "ctags -x --_xformat=%{input}:%n:1:%K!%N" (I hope).
#
sub emit_ctags {
  (my MY $self, my ($kind, $name, $fileName, $lineNo, $colNo)) = @_;
  # XXX: symbolKind mapping.
  printf "%s:%d:%d:%s!%s\n", $self->clean_path($fileName)
    , $lineNo, $colNo // 1, $kind, $name;
}

#========================================

sub load_string_into_file {
  (my MY $self, my ($fileName, $text)) = @_;
  my ($baseName, $dir) = File::Basename::fileparse($fileName);

  my $yatt = $self->{_SITE}->load_yatt($dir);
  my $core = $yatt->open_trans;

  my $tmpl = $core->find_file($baseName);

  my LintResult $result;

  try {
    $core->get_parser->load_string_into($tmpl, $text, all => 1);
  } catch {
    $result //= +{};
    if (not ref $_) {
      $self->strerror2lintresult($tmpl, $_, $result //= {});
    } elsif (UNIVERSAL::isa($_, 'YATT::Lite::Error')) {
      $self->yatterror2lintresult($_, $result);
    } else {
      $result->{message} = $_;
    }
  };

  $result;
}

sub apply_changes {
  (my MY $self, my ($fileName, @changes)) = @_;

  my ($baseName, $dir) = File::Basename::fileparse($fileName);

  my $yatt = $self->{_SITE}->load_yatt($dir);
  my $core = $yatt->open_trans;

  my Template $tmpl = $core->find_file($baseName);

  my $lines = [defined $tmpl->{cf_string} && $tmpl->{cf_string} ne ""
               ? (split /\n/, $tmpl->{cf_string}, -1) : ("")];

  foreach my TextDocumentContentChangeEvent $change (@changes) {
    $lines = $self->apply_change_to_lines($lines, $change);
  }

  $tmpl->{cf_mtime} = time;
  my $changed = join("\n", @$lines);

  my LintResult $result;

  try {
    $core->get_parser->load_string_into($tmpl, $changed, all => 1);
  } catch {
    $tmpl->{cf_string} = $changed;
    $result //= +{};
    if (not ref $_) {
      $self->strerror2lintresult($tmpl, $_, $result //= {});
    } elsif (UNIVERSAL::isa($_, 'YATT::Lite::Error')) {
      $self->yatterror2lintresult($_, $result);
    } else {
      $result->{message} = $_;
      $result->{info}{from} = ["line: ", __LINE__];
    }
  };

  if (not $result) {
    my LintResult $res = $self->lint($fileName);
    $result = $res unless $res->{is_success};
  }

  ($changed, $result);
}

# Z-chtholly(pts/0)% ./Lite/Inspector.pm apply_change_to_lines '["fooooo","bar","baz"]' '{"text":"xx","range":{"start":{"line":0,"character":1},"end":{"line":0,"character":2}}}'
# [["fxxoooo","bar","baz"]]
# Z-chtholly(pts/0)% ./Lite/Inspector.pm apply_change_to_lines '["fooooo","bar","baz"]' '{"text":"xx","range":{"start":{"line":0,"character":1},"end":{"line":0,"character":1}}}'
# [["fxxooooo","bar","baz"]]
# Z-chtholly(pts/0)% ./Lite/Inspector.pm apply_change_to_lines '["fooooo","bar","baz"]' '{"text":"xx","range":{"start":{"line":0,"character":1},"end":{"line":0,"character":100}}}'
# [["fxx","bar","baz"]]
# Z-chtholly(pts/0)% ./Lite/Inspector.pm apply_change_to_lines '["fooooo","bar","baz"]' '{"text":"xx","range":{"start":{"line":0,"character":1},"end":{"line":1,"character":1}}}'
# [["fxxar","baz"]]

sub apply_change_to_lines {
  (my MY $self, my $lines, my TextDocumentContentChangeEvent $change) = @_;
  my Range $from = $change->{range};
  my Position $start = $from->{start};
  my Position $end = $from->{end};
  my @pre = @{$lines}[0 .. $start->{line}-1];
  my @post = @{$lines}[$end->{line}+1 .. $#$lines];
  if ($start->{line} == $end->{line}) {
    my $edited = $lines->[$start->{line}];
    try {
      substr($edited
             , $start->{character}, $end->{character} - $start->{character}
             , $change->{text});
    } catch {
      Carp::croak "failed to apply changes: "
        . terse_dump([original => $edited
                      , start => $start->{character}
                      , len => $end->{character} - $start->{character}
                      , changed => $change->{text}]). ": $_";
    };
    [@pre, $edited, @post];
  } else {
    my ($pre_edit, $post_edit);
    try {
      $pre_edit = substr($lines->[$start->{line}], 0, $start->{character});
      $post_edit = substr($lines->[$end->{line}], $end->{character});
    } catch {
      Carp::croak "failed to apply multiline changes: "
        . terse_dump([pre => [original => $lines->[$start->{line}]
                              , start => $start->{character}]
                      , post => [original => $lines->[$end->{line}]
                                 , end => $end->{character}]
                      , changed => $change->{text}]). ": $_";
    };
    [@pre, $pre_edit.$change->{text}.$post_edit, @post];
  }
}

sub lint : method {
  (my MY $self, my $fileName) = @_;

  my ($baseName, $dir) = File::Basename::fileparse($fileName);

  my LintResult $result;
  my $mtime;
  my $tmpl;

  try {

    if (-r $fileName) {
      $mtime = stat($fileName)->mtime;
    }

    $self->{_SITE}->cf_let([
      error_handler => sub {
        (my $type, my YATT::Lite::Error $err) = @_;
        $result->{type} = $type;
        $self->yatterror2lintresult($err, $result);
        die $result;
      }
     ], sub {
      my $yatt = $self->{_SITE}->load_yatt($dir);
      # $yatt->fconfigure_encoding(\*STDOUT, \*STDERR);
      # get_trans is not ok.
      my $core = $yatt->open_trans;
      $tmpl = $core->find_file($baseName);
      $tmpl->refresh($core);
      my $pkg = $core->find_product(perl => $tmpl);

      $result->{is_success} = JSON()->true;
      $result->{info}{mtime} = [$mtime, $tmpl->{cf_mtime}];

    });
  } catch {

    unless ($result) {
      my $backtrace;
      if (not ref $_) {
        $self->strerror2lintresult($tmpl, $_, $result //= {});
      } elsif (UNIVERSAL::isa($_, 'YATT::Lite::Error')) {
        $self->yatterror2lintresult($_, $result //= +{});
        $backtrace = $_->{cf_backtrace};
      } else {
        $result->{message} = $_;
        $result->{info}{from} = ["line: ", __LINE__];
      }

      $result->{info}{mtime} = [$mtime, $tmpl->{cf_mtime}] if defined $mtime;
      $result->{info}{backtrace} = $self->backtrace2list($backtrace) if $backtrace;
    }
  };

  $result;
}

sub yatterror2lintresult {
  (my MY $self, my YATT::Lite::Error $err, my LintResult $result) = @_;
  use YATT::Lite::Util::AllowRedundantSprintf;
  $result->{info}{from} = 'yatterror2lintresult';
  $result->{file} = $err->{cf_tmpl_file};
  $result->{diagnostics} = my Diagnostic $diag = {};
  $diag->{severity} = DiagnosticSeverity__Error;
  $diag->{message} = $err->{cf_reason} // do {
    my $str;
    try {
      $str = sprintf($err->{cf_format}, @{$err->{cf_args}});
    } catch {
      $str = terse_dump([$_, $err->{cf_format}, @{$err->{cf_args}}]);
    };
    $str;
  };
  $diag->{range} = $self->make_line_range($err->{cf_tmpl_line} - 1);
  $result;
}

sub strerror2lintresult {
  (my MY $self, my Template $tmpl, my $errStr, my LintResult $result) = @_;
  $result->{info}{from} = 'strerror2lintresult';
  $result->{file} = $tmpl->{cf_path};
  $result->{diagnostics} = my Diagnostic $diag = {};
  $diag->{severity} = DiagnosticSeverity__Error;
  $errStr =~ s/\n.*\z//s;
  $diag->{message} = $errStr;
  if ($errStr =~ / line (\d+)[,\.]/) {
    $diag->{range} = $self->make_line_range($1+0);
  }
  $result;
}

sub backtrace2list {
  (my MY $self, my $trace) = @_;
  my @list;
  while (my $frame = $trace->next_frame) {
    push @list, +{
      map {$_ => $frame->$_()}
      qw(
          package filename line subroutine
        )
    };
  }
  \@list;
}

sub make_line_range {
  (my MY $self, my $lineno) = @_;
  my Range $range = {};
  $range->{start} = $self->make_line_position($lineno);
  $range->{end} = $self->make_line_position($lineno+1);
  $range
}

#========================================

sub alttree {
  (my MY $self, my ($tmpl, $tree)) = @_;
  [YATT::Lite::LRXML::AltTree->new(
    string => $tmpl->cget('string'),
    with_source => 0,
  )
   ->convert_tree($tree)];
}

sub lookup_symbol_definition {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;

  unless (defined $sym->{kind}) {
    Carp::croak "kind in SymbolInfo is empty! "
      . terse_dump($sym);
  }

  my $sub = $self->can("lookup_symbol_definition_of__$sym->{kind}")
    or return;

  $sub->($self, $sym, $cursor);
}

sub lookup_symbol_definition_of__ELEMENT {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;

  my Position $pos = $sym->{refpos};

  my AltNode $node = $cursor->{array}[$cursor->{index}];
  # assert($node);

  my $wname = join(":", lexpand($node->{path}));

  # XXX: yatt:if, yatt:foreach, ... macro
  # XXX: calllable_vars like <yatt:body/>

  my Part $widget = $self->lookup_widget_from(
    $node->{path}, $sym->{filename}, $pos->{line}
  ) or return;

  my Location $loc = +{};

  $loc->{uri} = $self->filename2uri($self->part_filename($widget));
  $loc->{range} = $self->part_decl_range($widget);

  $loc;
}

sub lookup_symbol_definition_of__var {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;

  my Location $loc = +{};
  if (my VarInfo $var = $self->locate_entity_var($sym, $cursor)) {
    $loc->{uri} = $self->filename2uri($var->{filename});
    $loc->{range} = $var->{range};
    return $loc;
  }

  if (my EntityInfo $entFunc = $self->locate_entity_function($sym, $cursor)) {
    $loc->{uri} = $self->filename2uri($entFunc->{file});
    $loc->{range} = $self->make_line_range($entFunc->{line});
    return $loc;
  }
}

sub lookup_symbol_definition_of__call {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;

  my Location $loc = +{};
  if (my VarInfo $var = $self->locate_entity_var($sym, $cursor)) {
    $loc->{uri} = $self->filename2uri($var->{filename});
    $loc->{range} = $var->{range};
    return $loc;
  }

  if (my EntityInfo $entFunc = $self->locate_entity_function($sym, $cursor)) {
    $loc->{uri} = $self->filename2uri($entFunc->{file});
    $loc->{range} = $self->make_line_range($entFunc->{line});
    return $loc;
  }
}

sub filename2uri {
  (my MY $self, my $fn) = @_;
  URI::file->new_abs($fn)->as_string;
}

sub part_filename {
  (my MY $self, my Part $part) = @_;
  my Template $tmpl = $part->{cf_folder};
  $tmpl->{cf_path};
}

sub describe_symbol {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;

  unless (defined $sym->{kind}) {
    Carp::croak "kind in SymbolInfo is empty! "
      . terse_dump($sym);
  }

  my $resolver = $self->can("describe_symbol_of_$sym->{kind}")
    or return;
  $resolver->($self, $sym, $cursor);
}

sub describe_symbol_of_ELEMENT {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;

  my AltNode $node = $cursor->{array}[$cursor->{index}];
  # assert($node);

  my Position $pos = $self->range_start($sym->{range});

  my $wname = join(":", lexpand($node->{path}));

  # XXX: builtin macros like yatt:if, yatt:foreach, ...
  # XXX: calllable_vars like <yatt:body/>

  my Part $widget = $self->lookup_widget_from(
    $node->{path}, $sym->{filename}, $pos->{line}
  ) or return;

  my MarkupContent $md = +{};
  $md->{kind} = 'markdown';
  $md->{value} = $self->widget_signature_md($widget, 1);
  $md;
}

sub describe_symbol_of_call {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;

  if (my VarInfo $var = $self->locate_entity_var($sym, $cursor, 'code')) {
    return $self->describe_entity_var($sym, $var);
  }

  if (my $entFunc = $self->locate_entity_function($sym, $cursor)) {
    return $self->describe_entity_function($sym, $entFunc);
  }
}

sub describe_symbol_of_var {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;

  if (my VarInfo $var = $self->locate_entity_var($sym, $cursor)) {
    return $self->describe_entity_var($sym, $var);
  }

  if (my $entFunc = $self->locate_entity_function($sym, $cursor)) {
    return $self->describe_entity_function($sym, $entFunc);
  }
}

sub describe_entity_var {
  (my MY $self, my SymbolInfo $sym, my VarInfo $var) = @_;

  my MarkupContent $md = +{};

  $md->{kind} = 'markdown';
  my $text = "$var->{kind} $var->{name}";
  $text .= ": $var->{type}";
  $text .= "=$var->{detail}" if $var->{detail};
  $md->{value} = $self->md_quote_code_as(yatt => $text);

  return $md;
}

sub describe_entity_function {
  (my MY $self, my SymbolInfo $sym, my EntityInfo $entFunc) = @_;
  my MarkupContent $md = +{};
  $md->{kind} = 'markdown';
  my $text = "function $sym->{name}";
  $md->{value} = $self->md_quote_code_as(yatt => $text);
  return $md;
}

sub locate_entity_var {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor, my $ofType) = @_;
  for (my Zipper $c = $cursor; $c; $c = $c->{path}) {
    if (my $defs = $c->{defs}) {
      if (my VarInfo $var = $defs->{$sym->{name}}) {
        next if defined $ofType and $var->{type} ne $ofType;
        return $var;
      }
    }
  }
}

sub locate_entity_function {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;

  my ($tmpl, $core) = $self->find_template($sym->{filename});

  $self->find_entity_from($tmpl->cget('entns'), $sym->{name});
}

sub md_quote_code_as {
  (my MY $self, my ($langId, $text)) = @_;
   my $pre = q{```}.$langId."\n";
   $text =~ s/\n*\z/\n/;
   $pre.$text.q{```}."\n";
}

sub widget_signature_md {
  (my MY $self, my Widget $widget, my $detail) = @_;
  my $wname = "yatt:$widget->{cf_name}";
  my $args = join("", map {
    my $var = $widget->{arg_dict}{$_};
    " ".join("=", $_, q{"}.$var->spec_string.q{"}).($detail ? "\n" : "");
  } @{$widget->{arg_order}});
  if ($detail) {
    $self->md_quote_code_as(yatt => "($widget->{cf_kind}) <$wname$args/>");
  } else {
    $args;
  }
}

sub list_parts_in {
  (my MY $self, my $fileName) = @_;
  my ($tmpl, $core) = $self->find_template($fileName);
  my @result;
  foreach my Part $part ($tmpl->list_parts) {
    push @result, my DocumentSymbol $sym = {};
    $sym->{name} = "$part->{cf_kind} $part->{cf_name}";
    $sym->{kind} = $part->isa(Widget) ? SymbolKind__Constructor
      : SymbolKind__Method;
    $sym->{detail} = $self->widget_signature_md($part);
    $sym->{range} = $self->part_decl_range($part);
    $sym->{selectionRange} = $self->part_decl_range($part);
  }
  @result;
}

sub lookup_widget_from {
  (my MY $self, my ($wpath, $fileName, $line)) = @_;

  (my Part $part, my Template $tmpl, my $core)
    = $self->find_part_of_file_line($fileName, $line)
    or return;

  $core->build_cgen_of('perl')
    ->with_template($tmpl, lookup_widget => lexpand($wpath));
}

sub locate_symbol_at_file_position {
  (my MY $self, my ($fileName, $line, $column)) = @_;
  $line //= 0;
  $column //= 0;

  my Zipper $cursor = $self->locate_node_at_file_position(
    $fileName, $line, $column
  ) or return;

  my AltNode $node = $cursor->{array}[$cursor->{index}]
    or return;

  my SymbolInfo $info = {};
  $info->{kind} = $node->{kind};
  $info->{name} = join(":", lexpand($node->{path}));
  $info->{range} = $node->{symbol_range};
  $info->{filename} = $fileName;
  $info->{refpos} = my Position $pos = +{};
  $pos->{line} = $line;
  $pos->{character} = $column;

  wantarray ? ($info, $cursor) : $info;
}

sub locate_node_at_file_position {
  (my MY $self, my ($fileName, $line, $column)) = @_;
  $line //= 0;
  $column //= 0;

  my $treeSpec = $self->dump_tokens_at_file_position($fileName, $line, $column)
    or return;

  my Position $pos;
  $pos->{line} = $line;
  $pos->{character} = $column;

  (my ($kind, $path, $range, $tree), my Part $part) = @$treeSpec;
  unless ($self->is_in_range($range, $pos)) {
    Carp::croak "BUG: Not in range! range=".terse_dump($range)." line=$line col=$column";
  }

  # <!yatt:action>, <!yatt:entity>...
  return if $kind eq 'body_string';

  my Zipper $cursor = $self->locate_node($tree, $pos);

  $self->augment_defs($cursor, $part);
}

sub augment_defs {
  (my MY $self, my Zipper $cursor, my Part $part) = @_;
  my $zipperList = $self->flatten_zipper_top2bottom($cursor);
  my Zipper $outermost = $zipperList->[0];
  $outermost->{defs}{$_}
    //= $self->make_document_symbol_from_argument($part->{arg_dict}{$_})
    for keys %{$part->{arg_dict}};
  $self->augment_defs_1($zipperList, 0);
  $cursor;
}

sub make_document_symbol_from_argument {
  (my MY $self, my $arg) = @_;
  my VarInfo $var = {};
  $var->{name} = $arg->varname;
  $var->{kind} = '(argument)';
  $var->{type} = join(":", lexpand($arg->type));
  if (my $spec = $arg->spec_string) {
    $var->{detail} = qq{"$spec"};
  }
  $var->{range} = $self->make_line_position($arg->lineno);
  $var;
}

sub flatten_zipper_top2bottom {
  (my MY $self, my Zipper $cursor) = @_;
  my @zipper;
  my Zipper $c = $cursor;
  do {
    unshift @zipper, $c;
    $c = $c->{path};
  } while $c;
  wantarray ? @zipper : \@zipper;
}

sub augment_defs_1 {
  (my MY $self, my $zipperList, my $depth) = @_;

  my Zipper $zipper = $zipperList->[$depth];

  my @nodes = @{$zipper->{array}}[0..$zipper->{index}];
  foreach my AltNode $node (@nodes) {
    unless (defined $node->{kind}) {
      next;
    }
    my $method = join("_", augment_defs_1_ =>
                      , $node->{kind}, lexpand($node->{path}));
    my $sub = $self->can($method)
      or next;
    $sub->($self, $zipper, $node, $node == $nodes[-1]);
  }
}

sub augment_defs_1__ELEMENT_yatt_my {
  (my MY $self, my Zipper $cursor, my AltNode $node, my $isCurrent) = @_;
  foreach my AltNode $subNode (@{$node->{subtree}}) {
    next unless defined $subNode->{kind};
    next unless $subNode->{kind} eq "ATT_TEXT";
    my ($name, @type) = lexpand($subNode->{path});
    $cursor->{defs}{$name} = my VarInfo $var = +{};
    $var->{kind} = 'my';
    $var->{name} = $name;
    $var->{type} = @type ? join(":", @type) : 'text';
    $var->{range} = $subNode->{symbol_range};
  }
}

sub node_path_of_zipper {
  (my MY $self, my Zipper $cursor) = @_;
  my @trail;
  my Zipper $cur = $cursor;
  while ($cur) {
    push @trail, do {
      if (my AltNode $node = $cur->{array}[$cur->{index}]) {
        $self->minimize_altnode($node);
      } else {
        [map {$self->minimize_altnode($_)} @{$cur->{array}}];
      }
    };
    $cur = $cur->{path};
  }

  @trail;
}

sub minimize_altnode {
  (my MY $self, my AltNode $node) = @_;
  my AltNode $min = {};
  $min->{kind} = $node->{kind};
  $min->{path} = $node->{path};
  $min->{tree_range} = $node->{tree_range};
  $min;
}

sub locate_node {
  (my MY $self, my $tree, my Position $pos, my Zipper $parent) = @_;

  my Zipper $current = +{};
  $current->{path} = $parent;
  $current->{array} = $tree;
  my $ix = $current->{index} = $self->lsearch_node_pos($pos, $tree);

  if (my AltNode $node = $tree->[$ix]) {

    if ($node->{symbol_range}
        and $self->is_in_range($node->{symbol_range}, $pos)) {
      return $current;
    }

    if ($node->{subtree}
        and $self->is_in_range($node->{tree_range}, $pos)) {
      return $self->locate_node($node->{subtree}, $pos, $current);
    } else {
      # No yatt elements are under the position.
      splice @$tree, $ix, 0, undef;

      return $current;
    }
  }

  $current;
}

sub lsearch_node_pos {
  (my MY $self, my Position $pos, my $tree) = @_;
  my $i = 0;
  foreach my AltNode $node (@$tree) {
    unless (defined $node->{tree_range}) {
      Carp::confess "BUG: tree_range is empty. i=$i, tree="
        . terse_dump($tree);
    }
    if ($self->compare_position($self->range_end($node->{tree_range}), $pos) > 0) {
      return $i;
    }
  } continue {
    $i++;
  }
  # Point outside of the tree.
  return scalar @$tree;
}

sub range_start { (my MY $self, my Range $range) = @_; $range->{start}; }
sub range_end { (my MY $self, my Range $range) = @_; $range->{end}; }

sub is_in_range {
  (my MY $self, my Range $range, my Position $pos) = @_;
  $self->compare_position($range->{start}, $pos) <= 0
    && $self->compare_position($range->{end}, $pos) >= 0;
}

sub compare_position {
  (my MY $self, my Position $leftPos, my Position $rightPos) = @_;
  $leftPos->{line} <=> $rightPos->{line}
    || $leftPos->{character} <=> $rightPos->{character};
}

sub dump_part_decllist {
  (my MY $self, my ($fileName, $line)) = @_;
  $line //= 0;

  (my Part $part, my Template $tmpl, my $core)
    = $self->find_part_of_file_line($fileName, $line)
    or return;

  $part->{decllist}
}

sub dump_part_tree {
  (my MY $self, my ($fileName, $line)) = @_;
  $line //= 0;

  (my Part $part, my Template $tmpl, my $core)
    = $self->find_part_of_file_line($fileName, $line)
    or return;

  unless (UNIVERSAL::isa($part, 'YATT::Lite::Core::Widget')) {
    Carp::croak "part $part->{cf_kind} $part->{cf_name} is not a widget";
  }

  $core->ensure_parsed($part);
  my Widget $widget = $part;
  $widget->{tree}
}

sub dump_tokens_at_file_position {
  (my MY $self, my ($fileName, $line, $column)) = @_;
  $line //= 0;

  (my Part $part, my Template $tmpl, my $core)
    = $self->find_part_of_file_line($fileName, $line)
    or return;

  return unless defined $tmpl->{cf_nlines};

  unless ($line <= $tmpl->{cf_nlines} - 1) {
    # warn?
    return;
  }

  # my $yatt = $self->find_yatt_for_template($fileName);
  $core->ensure_parsed($part);

  $part->{cf_endln} //= $tmpl->{cf_nlines}; # XXX:

  my $declkind = [$part->{cf_namespace}, $part->{cf_kind}];

  if ($line < $part->{cf_bodyln} - 1) {
    # At declaration
    [decllist => $declkind
     , $self->part_decl_range($part)
     , $self->alttree($tmpl, $part->{decllist})
     , $part
   ];
  } elsif (UNIVERSAL::isa($part, 'YATT::Lite::Core::Widget')) {
    # At body of widget, page, args...
    my Widget $widget = $part;
    [body => $declkind
     , $self->part_body_range($part)
     , $self->alttree($tmpl, $widget->{tree})
     , $part
   ];
  } else {
    # At body of action, entity, ...
    # XXX: TODO extract tokens for host language.
    [body_string => $declkind
     , $self->part_body_range($part)
     , $part->{toks}
     , $part
   ];
  }
}

sub part_decl_range {
  (my MY $self, my Part $part) = @_;
  my Range $range;
  $range->{start} = $self->make_line_position($part->{cf_startln} - 1);
  $range->{end} = $self->make_line_position($part->{cf_bodyln} - 1);
  $range;
}

sub make_line_position {
  (my MY $self, my ($line, $character)) = @_;
  my Position $p = {};
  $p->{character} = $character // 0;
  $p->{line} = $line;
  $p;
}

sub part_body_range {
  (my MY $self, my Part $part) = @_;
  my Range $range;
  $range->{start} = $self->make_line_position($part->{cf_bodyln} - 1);
  my Template $tmpl = $part->{cf_folder};
  my $hasLastNL = $tmpl->{cf_string} =~ /\n\z/ ? 1 : 0;
  $range->{end} = $self->make_line_position($part->{cf_endln}
                                            - ($hasLastNL ? 1 : 0));
  $range;
}

sub find_part_of_file_line {
  (my MY $self, my ($fileName, $line)) = @_;
  $line //= 0;
  my ($tmpl, $core) = $self->find_template($fileName);
  my Part $prev;
  foreach my Part $part ($tmpl->list_parts) {
    last if $line < $part->{cf_startln} - 1;
    $prev = $part;
  }

  wantarray ? ($prev, $tmpl, $core) : $prev;
}

sub find_template {
  (my MY $self, my $fileName) = @_;
  my ($fn, $dir) = File::Basename::fileparse($fileName);
  my $yatt = $self->find_yatt_for_template($fileName);
  my $core = $yatt->open_trans;
  my $tmpl = $core->find_file($fn);
  # XXX: force refresh?
  wantarray ? ($tmpl, $core) : $tmpl;
}

sub find_yatt_for_template {
  (my MY $self, my $fileName) = @_;
  my ($fn, $dir) = File::Basename::fileparse($fileName);
  $self->{_SITE}->load_yatt($dir);
}

#========================================

sub cmd_show_file_line {
  (my MY $self, my @desc) = @_;
  $self->cli_output($self->show_file_line(@desc));
  ();
}
sub show_file_line {
  (my MY $self, my @desc) = @_;
  my ($file, $line) = do {
    if (@desc == 1 and ref $desc[0] eq 'HASH') {
      @{$desc[0]}{'file', 'line'}
    } else {
      @desc;
    }
  };

  my $lines = $self->{_file_line_cache}{$file} //= do {
    open my $fh, "<:utf8", $file or Carp::croak "Can't open $file: $!";
    chomp(my @lines = <$fh>);
    \@lines;
  };

  unless (defined $line) {
    Carp::croak "line is undef!";
  }

  [@desc, $lines->[$line - $self->{line_base}]];
}

sub find_entity_from {
  (my MY $self, my ($fromFile, $entityName)) = @_;

  my ($tmpl, $core) = $self->find_template($fromFile);

  my $entns = $tmpl->cget('entns');
  $entns->can("entity_$entityName")
    or return;

  +{@{$self->describe_entns_entity($entns, $entityName)}};
}

*cmd_list_entity = *cmd_list_entities;*cmd_list_entity = *cmd_list_entities;

sub cmd_list_entities {
  (my MY $self, my @args) = @_;
  $self->configure($self->parse_opts(\@args));
  my $nameRe = do {
    if (my $nameGlob = shift @args) {
      Text::Glob::glob_to_regex($nameGlob);
    } else {
      undef;
    }
  };

  my %opts = @args == 1 ? %{$args[0]} : @args;

  my $searchFrom = delete $opts{from};
  if (%opts) {
    Carp::croak "Unknown options: ". join(", ", sort keys %opts);
  }

  my $cwdOrFileList = $self->list_target_dirs($searchFrom);

  my $emit_entities_in_entns; $emit_entities_in_entns = sub {
    my ($entns, $path) = @_;
    my $symtab = symtab($entns);
    my @methods = do {
      if ($nameRe) {
        sort grep {
          my $entry = $symtab->{$_};
          if (ref \$entry eq 'GLOB'
              and *{$entry}{CODE}
              and (my $meth = $_) =~ s/^entity_//) {
            $meth =~ $nameRe;
          }
        } keys %$symtab;
      } else {
        sort grep {/^entity_/ and *{$symtab->{$_}}{CODE}} keys %$symtab;
      }
    };
    foreach my $meth (@methods) {
      (my $entityName = $meth) =~ s/^entity_//;

      my @result = @{$self->describe_entns_entity($entns, $entityName, path => $path)};
      $self->cli_output(
        $self->{detail} ? [+{@result}] : \@result
      );
    }
  };

  my %seen;
  my @superNS;
  walk_vfs_folders(
    factory => $self->{_SITE},
    from => $cwdOrFileList,
    ignore_symlink => $self->{ignore_symlink},
    dir => sub {
      my ($dir, $yatt) = @_;
      my $entns = $yatt->EntNS;
      return if $seen{$entns};
      push @superNS, grep {not $seen{$_}++} $dir->get_linear_isa_of_entns;
    },
    file => sub {
      my ($tmpl, $yatt) = @_;
      my $entns = $tmpl->cget('entns');
      foreach my $part ($tmpl->list_parts(YATT::Lite::Core->Entity)) {
        my @result = (name => $part->cget('name'), file => $tmpl->cget('path')
                        , line => $part->cget('startln'), entns => $entns);
        $self->cli_output(
          $self->{detail} ? +{@result} : \@result
        );
      }
      push @superNS, grep {not $seen{$_}++} $tmpl->get_linear_isa_of_entns;
    },
  );

  foreach my $superNS (@superNS) {
    my $path = YATT::Lite::Util::try_invoke($superNS, 'filename');
    $emit_entities_in_entns->($superNS, $path);
  }
}

sub describe_entns_entity {
  (my MY $self, my ($entns, $entityName, %opts)) = @_;

  require Sub::Identify;

  my $entSub = $entns->can("entity_$entityName");

  my ($file, $line) = Sub::Identify::get_code_location($entSub);

  [name => $entityName, entns => $entns
   , file => $file // $opts{path}, line => $line];
}

sub cmd_list_vfs_folders {
  (my MY $self, my @args) = @_;
  $self->configure($self->parse_opts(\@args));
  my $widgetNameGlob = shift @args;

  my %opts = @args == 1 ? %{$args[0]} : @args;

  my $searchFrom = delete $opts{from};
  if (%opts) {
    Carp::croak "Unknown options: ". join(", ", sort keys %opts);
  }

  my $cwdOrFileList = $self->list_target_dirs($searchFrom);

  walk_vfs_folders(
    factory => $self->{_SITE},
    from => $cwdOrFileList,
    ignore_symlink => $self->{ignore_symlink},
    dir => sub {
      my ($dir, $yatt) = @_;
      # print join("\t", dir => $yatt->cget('dir'), $yatt->EntNS), "\n";
      my @result = (kind => 'dir', path => $dir->cget('path'),
                    entns => $dir->cget('entns'));
      $self->cli_output(\@result);
    },
    file => sub {
      my ($tmpl, $yatt) = @_;
      my @result = (kind => 'dir', path => $tmpl->cget('path'),
                    entns => $tmpl->cget('entns'));
      $self->cli_output(\@result);
    },
  );
}


#========================================

sub cmd_list_widgets {
  (my MY $self, my @args) = @_;
  $self->configure($self->parse_opts(\@args));
  my $widgetNameGlob = shift @args;
  my %opts = @args == 1 ? %{$args[0]} : @args;
  $opts{kind} = ['widget', 'page'];
  $self->cmd_list_parts($widgetNameGlob, \%opts);
}

sub cmd_list_actions {
  (my MY $self, my @args) = @_;
  $self->configure($self->parse_opts(\@args));
  my $widgetNameGlob = shift @args;
  my %opts = @args == 1 ? %{$args[0]} : @args;
  $opts{kind} = ['action'];
  $self->cmd_list_parts($widgetNameGlob, \%opts);
}

sub cmd_list_parts {
  (my MY $self, my @args) = @_;
  $self->configure($self->parse_opts(\@args));
  my $widgetNameGlob = shift @args;
  my %opts = @args == 1 ? %{$args[0]} : @args;
  my $searchFrom = delete $opts{from};
  my $onlyKind = delete $opts{kind};
  if (%opts) {
    Carp::croak "Unknown options: ". join(", ", sort keys %opts);
  }

  my $cwdOrFileList = $self->list_target_dirs($searchFrom);

  walk(
    factory => $self->{_SITE},
    from => $cwdOrFileList,
    ignore_symlink => $self->{ignore_symlink},
    ($widgetNameGlob ? (
      (name_match => Text::Glob::glob_to_regex($widgetNameGlob))
    ) : ()),
    widget => sub {
      my ($found) = @_;
      my Part $widget = delete $found->{part};
      if ($onlyKind and not grep {$found->{kind} eq $_} lexpand($onlyKind)) {
        # XXX: 
        return;
      }
      my Template $tmpl = $widget->{cf_folder};
      my $path = $tmpl->{cf_path};
      my $args = $self->{detail}
        ? [$self->list_part_args_internal($widget)]
        : $widget->{arg_order};
      my @result = ((map {$_ => $found->{$_}} sort keys %$found)
                      , args => $args, path => $self->clean_path($path));
      # Emit as an array for readability in normal mode.
      my $result = $self->{detail} ? +{@result} : \@result;
      $self->cli_output($result);
    },
    item => sub {
      my ($args) = @_;
      # print "# ", $args->{tree}->cget('path'), "\n";
    },
  );

  # $yatt->get_trans->list_items
  # $yatt->get_trans->find_file('index')
  # $yatt->get_trans->find_file('index')->list_parts
}

sub list_part_args_internal {
  (my MY $self, my Part $part, my $nameRe) = @_;
  my @result;
  my @fields = YATT::Lite::VarTypes->list_field_names;
  foreach my $argName ($part->{arg_order} ? @{$part->{arg_order}} : ()) {
    next if $nameRe and not $argName =~ $nameRe;
    my $argObj = $part->{arg_dict}{$argName};
    push @result, my $spec = {};
    foreach my $i (0 .. $#fields) {
      my $val = $argObj->[$i];
      $spec->{$fields[$i]} = $val;
    }
  }
  @result;
}

#========================================

sub is_in_template_dir {
  (my MY $self, my $path) = @_;
  foreach my $dir (lexpand($self->{_SITE}->{tmpldirs})) {
    if (length $dir <= length $path
        and substr($dir, 0, length $path) eq $path) {
      return 1;
    }
  }
  return 0;
}

sub list_target_dirs {
  (my MY $self, my $dirSpec) = @_;

  if ($dirSpec) {
    $self->rel2abs($dirSpec)
  } else {
    my $cwd = Cwd::getcwd;
    if ($self->is_in_template_dir($cwd)) {
      $cwd;
    } else {
      $self->{_SITE}->cget('doc_root') // do {
        if (my $dir = $self->{_SITE}->cget('per_role_docroot')) {
          [glob("$dir/[a-z]*")];
        } else {
          Carp::croak "doc_root is empty!"
        }
      }
    }
  }
}

#========================================

MY->run(\@ARGV) unless caller;

1;
