#!/usr/bin/env perl
package YATT::Lite::Inspector;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use File::AddInc;
use MOP4Import::Base::CLI_JSON -as_base
  , [fields =>
       qw/_SITE _app_root _file_line_cache/,
     [dir => doc => "starting directory to search app.psgi upward"],
     [search_boundary => doc => "never search app.psgi above this directory (the language server sets it to the workspace root)"],
     [emit_absolute_path => doc => "emit absolute path instead of \$app_root-relative"],
     [site_class => doc => "class name for SiteApp (to load app.psgi)", default => "YATT::Lite::WebMVC0::SiteApp"],
     [ignore_symlink => doc => "ignore symlinked templates"],
     [detail => doc => "show argument details"],
     [line_base => default => 1],
     [debug_changes_dir => doc => "(LSP debugging only)"
      , default => "var/debug_yatt_ls"],
     # qw/debug/,
   ];

use JSON::MaybeXS;

use MOP4Import::Util qw/lexpand symtab terse_dump globref isa_array/;

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

use File::Path qw(make_path);
use File::Slurp qw(write_file);
use Time::HiRes ();

use Try::Tiny;

use YATT::Lite;
use YATT::Lite::Factory; sub Factory () {'YATT::Lite::Factory'}
use YATT::Lite::LRXML;
use YATT::Lite::Core qw/Part Widget Template/;
use YATT::Lite::CGen::Perl;
use YATT::Lite::VFS qw/Folder/;

use MOP4Import::Types
  ArgSpec => [
    [fields => 
      YATT::Lite::VarTypes->list_field_names,
      'is_required',
    ]
  ];

use YATT::Lite::LRXML::AltTree qw/column_of_source_pos AltNode/;

use YATT::Lite::Walker qw/walk walk_vfs_folders/;

use YATT::Lite::LanguageServer::Protocol
  qw/Position Range MarkupContent
     Location
     Diagnostic
     TextDocumentContentChangeEvent
     DocumentSymbol
     CompletionItem
    /
  , qr/^DiagnosticSeverity__/
  , qr/^SymbolKind__/
  , qr/^InsertTextFormat__/
  ;

#========================================

sub after_configure_default {
  (my MY $self) = @_;
  $self->SUPER::after_configure_default;

  $self->{_SITE} = do {
    # Site->load caches per factory script, so multiple Inspectors can
    # coexist in one process. Bare template dirs (no app.psgi) get a
    # default site instead of dying. GH-269
    my $class = Plack::Util::load_class($self->{site_class});
    $class->load_or_default(dir => $self->{dir}
			    , class => $self->{site_class}
                            , (defined $self->{search_boundary}
                               ? (stop_at => $self->{search_boundary}) : ()));
  };

  $self->{_app_root} = $self->{_SITE}->cget('app_root');

  $self->debug_log("Initialized");
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
      my Template $tmpl = $widget->{folder};
      my $path = $tmpl->{path};
      $self->emit_ctags($args->{kind}, $args->{name}, $path, $widget->{startln});
    },
    item => sub {
      my ($args) = @_;
      my $path = $args->{_tree}->cget('path');
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

  my $lines = [defined $tmpl->{string} && $tmpl->{string} ne ""
               ? (split /\n/, $tmpl->{string}, -1) : ("")];

  foreach my TextDocumentContentChangeEvent $change (@changes) {
    $lines = $self->apply_change_to_lines($lines, $change);
  }

  $tmpl->{mtime} = time;
  my $changed = join("\n", @$lines);

  if ($self->debug_changes_dir_exists) {
    my $destFn = $self->debug_changes_write_file($fileName, $changed);
    print STDERR "# Wrote: $destFn\n";
  }

  my LintResult $result;

  try {
    $core->get_parser->load_string_into($tmpl, $changed, all => 1);
  } catch {
    $tmpl->{string} = $changed;
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

sub head_as_json_array {
  my MY $self = shift;
  my $limit = 10;
  if ($_[0] =~ /^-(\d+)/) {
    $limit = $1; shift;
  }
  use open qw(:std :locale);
  local @ARGV = @_;
  my @result;
  while (<>) {
    chomp;
    push @result, $_;
    last if --$limit <= 0;
  }
  \@result;
}

sub debug_changes_dir_exists {
  (my MY $self) = @_;
  defined $self->{dir}
    &&
  -e "$self->{dir}/DEBUG_YATT_LANGSERVER"
    &&
  -d "$self->{dir}/$self->{debug_changes_dir}";
}

sub debug_changes_write_file {
  (my MY $self, my ($fileName, $changed)) = @_;

  my $debugDir = "$self->{dir}/$self->{debug_changes_dir}";

  substr($fileName, 0, length $self->{dir}) = "";

  my $destFn = "$debugDir/$fileName." . Time::HiRes::time;
  my $destDir = File::Basename::dirname($destFn);
  unless (-d $destDir) {
    make_path($destDir);
  }
  write_file($destFn, +{binmode => ':utf8'}, $changed);
}

# Z-chtholly(pts/0)% ./Lite/Inspector.pm apply_change_to_lines '["fooooo","bar","baz"]' '{"text":"xx","range":{"start":{"line":0,"character":1},"end":{"line":0,"character":2}}}'
# [["fxxoooo","bar","baz"]]
# Z-chtholly(pts/0)% ./Lite/Inspector.pm apply_change_to_lines '["fooooo","bar","baz"]' '{"text":"xx","range":{"start":{"line":0,"character":1},"end":{"line":0,"character":1}}}'
# [["fxxooooo","bar","baz"]]
# Z-chtholly(pts/0)% ./Lite/Inspector.pm apply_change_to_lines '["fooooo","bar","baz"]' '{"text":"xx","range":{"start":{"line":0,"character":1},"end":{"line":0,"character":100}}}'
# [["fxx","bar","baz"]]
# Z-chtholly(pts/0)% ./Lite/Inspector.pm apply_change_to_lines '["fooooo","bar","baz"]' '{"text":"xx","range":{"start":{"line":0,"character":1},"end":{"line":1,"character":1}}}'
# [["fxxar","baz"]]

sub cmd_apply_all_change_to_lines {
  (my MY $self, my $linesOrFileName, my $changeList) = @_;

  my $lines = do {
    if (ref $linesOrFileName) {
      $linesOrFileName
    } else {
      [split /\r?\n/, YATT::Lite::Util::read_file($linesOrFileName)]
    }
  };

  my $result = $self->apply_all_change_to_lines($lines, $changeList);
  print $_, "\n" for @$result;
}

sub apply_all_change_to_lines {
  (my MY $self, my $lines, my $changeList) = @_;
  foreach my TextDocumentContentChangeEvent $change (@$changeList) {
    $lines = $self->apply_change_to_lines($lines, $change);
  }
  $lines;
}

sub apply_change_to_lines {
  (my MY $self, my $lines, my TextDocumentContentChangeEvent $change) = @_;
  my Range $from = $change->{range};
  unless ($from) {
    # Full document sync: the whole text replaces the document. GH-275
    my $text = $change->{text} // '';
    return [$text ne '' ? split(/\n/, $text, -1) : ('')];
  }
  my Position $start = $from->{start};
  my Position $end = $from->{end};
  my @pre = @{$lines}[0 .. $start->{line}-1];
  my @post = @{$lines}[$end->{line}+1 .. $#$lines];
  if ($start->{line} == $end->{line}) {
    my @edited = $lines->[$start->{line}];
    try {
      substr($edited[0]
             , $start->{character}, $end->{character} - $start->{character}
             , $change->{text});
      @edited = split /\n/, $edited[0], -1 if $edited[0] ne '';
    } catch {
      Carp::croak "failed to apply changes: "
        . terse_dump([original => $lines->[$start->{line}]
                      , start => $start->{character}
                      , len => $end->{character} - $start->{character}
                      , changed => $change->{text}]). ": $_";
    };
    [@pre, @edited, @post];
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
    my $edited = $pre_edit.$change->{text}.$post_edit;
    my @edited = $edited ne '' ? split(/\n/, $edited, -1) : $edited;
    [@pre, @edited, @post];
  }
}

sub append_file {
  (my MY $self, my ($fileName, $text)) = @_;

  my Range $ending = $self->file_ending_range($fileName);

  $self->apply_changes($fileName, +{
    range => $ending, rangeLength => 0, text => $text
  });
}

sub file_ending_range {
  (my MY $self, my ($fileNameOrTemplate)) = @_;

  my Template $tmpl = do {
    if (ref $fileNameOrTemplate) {
      unless ($fileNameOrTemplate->isa(Template)) {
        Carp::croak "Invalid argument type: ". ref($fileNameOrTemplate)
      }
      $fileNameOrTemplate
    } else {
      $self->find_template($fileNameOrTemplate);
    }
  };

  my ($lineNo, $colNo) = do {
    my $lines = [defined $tmpl->{string} && $tmpl->{string} ne ""
                 ? (split /\n/, $tmpl->{string}, -1) : ("")];

    my $lastLine = $lines->[-1];

    ($#$lines, length($lastLine));
  };

  my Position $start = +{};
  $start->{line} = $lineNo; $start->{character} = $colNo;
  my Position $end = +{};
  $end->{line} = $lineNo; $end->{character} = $colNo;
  my Range $range = +{};
  $range->{start} = $start; $range->{end} = $end;
  $range;
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
      $result->{info}{mtime} = [$mtime, $tmpl->{mtime}];

    });
  } catch {

    unless ($result) {
      my $backtrace;
      if (not ref $_) {
        $self->strerror2lintresult($tmpl, $_, $result //= {});
      } elsif (UNIVERSAL::isa($_, 'YATT::Lite::Error')) {
        $self->yatterror2lintresult($_, $result //= +{});
        $backtrace = $_->{backtrace};
      } else {
        $result->{message} = $_;
        $result->{info}{from} = ["line: ", __LINE__];
      }

      $result->{info}{mtime} = [$mtime, $tmpl->{mtime}] if defined $mtime;
      $result->{info}{backtrace} = $self->backtrace2list($backtrace) if $backtrace;
    }
  };

  $result;
}

sub yatterror2lintresult {
  (my MY $self, my YATT::Lite::Error $err, my LintResult $result) = @_;
  use YATT::Lite::Util::AllowRedundantSprintf;
  $result->{info}{from} = 'yatterror2lintresult';
  $result->{file} = $err->{tmpl_file};
  $result->{diagnostics} = my Diagnostic $diag = {};
  $diag->{severity} = DiagnosticSeverity__Error;
  $diag->{message} = $err->{reason} // do {
    my $str;
    try {
      $str = sprintf($err->{format}, @{$err->{args}});
    } catch {
      $str = terse_dump([$_, $err->{format}, @{$err->{args}}]);
    };
    $str;
  };
  $diag->{range} = $self->make_line_range($err->{tmpl_line} - 1);
  $result;
}

sub strerror2lintresult {
  (my MY $self, my Template $tmpl, my $errStr, my LintResult $result) = @_;
  $result->{info}{from} = 'strerror2lintresult';
  $result->{file} = $tmpl->{path};
  $result->{diagnostics} = my Diagnostic $diag = {};
  $diag->{severity} = DiagnosticSeverity__Error;
  # Keep the whole message (perl may report several errors at once);
  # the range comes from the first reported line. GH-269
  $errStr =~ s/\n+\z//;
  $diag->{message} = $errStr;
  if ($errStr =~ / line (\d+)[,\.]/) {
    # make_line_range takes a 0-based line (cf. yatterror2lintresult).
    $diag->{range} = $self->make_line_range($1 - 1);
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

# $lineno is 0-based (LSP). Callers holding 1-based lines (Part startln,
# Sub::Identify) must subtract 1.
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
  my $converter = YATT::Lite::LRXML::AltTree->new(
    string => $tmpl->cget('string'),
    with_source => 0,
  );
  [$converter->convert_tree($tree)];
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

  return unless $cursor;
  my AltNode $node = $cursor->{array}[$cursor->{index}]
    or return;

  # A callable variable in scope (<yatt:body/>, <yatt:cb/> for cb=[code],
  # <yatt:my f:code=...>) shadows a widget of the same name, as in
  # CGen::Perl::gen_call. GH-280
  if (my VarInfo $var = $self->locate_callable_var_of_element($node, $cursor)) {
    my Location $loc = +{};
    $loc->{uri} = $self->filename2uri($var->{filename} // $sym->{filename});
    $loc->{range} = $var->{range};
    return $loc;
  }

  # Macro elements (yatt:if, yatt:foreach, ...) have no definition.

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
    # args and <yatt:my> vars are always defined in the file of the cursor.
    $loc->{uri} = $self->filename2uri($var->{filename} // $sym->{filename});
    $loc->{range} = $var->{range};
    return $loc;
  }

  if (my EntityInfo $entFunc = $self->locate_entity_function($sym, $cursor)) {
    $loc->{uri} = $self->filename2uri($entFunc->{file});
    # {line} is 1-based (Part startln / Sub::Identify). GH-275
    $loc->{range} = $self->make_line_range($entFunc->{line} - 1);
    return $loc;
  }
}

sub lookup_symbol_definition_of__call {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;

  my Location $loc = +{};
  if (my VarInfo $var = $self->locate_entity_var($sym, $cursor)) {
    # args and <yatt:my> vars are always defined in the file of the cursor.
    $loc->{uri} = $self->filename2uri($var->{filename} // $sym->{filename});
    $loc->{range} = $var->{range};
    return $loc;
  }

  if (my EntityInfo $entFunc = $self->locate_entity_function($sym, $cursor)) {
    $loc->{uri} = $self->filename2uri($entFunc->{file});
    # {line} is 1-based (Part startln / Sub::Identify). GH-275
    $loc->{range} = $self->make_line_range($entFunc->{line} - 1);
    return $loc;
  }
}

#========================================
# Attributes at a widget call site. GH-277
# (see CGen::Perl::gen_putargs and passThruVar)
#
#   <yatt:foo x/>          passes the variable x in scope to formal arg x
#                          (a flag when there is no such variable)
#   <yatt:foo a=y/>        passes the variable y in scope to formal arg a
#   <yatt:foo b="..."/>    b is a formal arg; entities in the value are
#                          resolved through the entpath subtree as before
#   <:yatt:d>...</:yatt:d> d is a formal arg
#

sub lookup_symbol_definition_of__ATTRIBUTE {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;
  my AltNode $node = $cursor->{array}[$cursor->{index}];
  my ($name) = lexpand($node->{path});
  return unless defined $name and not ref $name;
  $self->variable_location($sym, $cursor, $name)
    // $self->formal_arg_location($sym, $cursor, $name);
}

sub lookup_symbol_definition_of__ATT_BARENAME {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;
  my AltNode $node = $cursor->{array}[$cursor->{index}];
  if ($node->{value_range}
      and $self->is_in_range($node->{value_range}, $sym->{refpos})) {
    return $self->variable_location($sym, $cursor, $node->{value});
  }
  my ($name) = lexpand($node->{path});
  return unless defined $name and not ref $name;
  $self->formal_arg_location($sym, $cursor, $name);
}

sub lookup_symbol_definition_of__ATT_TEXT {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;
  my AltNode $node = $cursor->{array}[$cursor->{index}];
  my ($name) = lexpand($node->{path});
  return unless defined $name and not ref $name;
  $self->formal_arg_location($sym, $cursor, $name);
}

sub lookup_symbol_definition_of__ATT_NESTED {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;
  my AltNode $node = $cursor->{array}[$cursor->{index}];
  # Only attribute elements (<:yatt:d>) have a symbol_range.
  return unless $node->{symbol_range};
  my @path = lexpand($node->{path});
  return unless @path and not grep {ref $_} @path;
  $self->formal_arg_location($sym, $cursor, $path[-1]);
}

# The ELEMENT node which owns the attribute at $cursor, if any.
sub parent_element_of_cursor {
  (my MY $self, my Zipper $cursor) = @_;
  my Zipper $parent = $cursor->{path} or return;
  my AltNode $elem = $parent->{array}[$parent->{index}] or return;
  return unless defined $elem->{kind} and $elem->{kind} eq 'ELEMENT';
  $elem;
}

# ($widget, $var, $range) of the formal argument $argName of the widget
# called by the element which owns the attribute at $cursor, or ().
sub locate_formal_arg {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor, my $argName) = @_;
  my AltNode $elem = $self->parent_element_of_cursor($cursor) or return;
  my Position $pos = $sym->{refpos};
  my Part $widget = $self->lookup_widget_from(
    $elem->{path}, $sym->{filename}, $pos->{line}
  ) or return;
  return unless UNIVERSAL::isa($widget, 'YATT::Lite::Core::Widget');
  my $arg = $widget->{_arg_dict}{$argName} or return;
  my $range = $self->arg_range_map_of_part($widget)->{$argName}
    // $self->make_line_range(($arg->lineno // 1) - 1);
  ($widget, $arg, $range);
}

sub formal_arg_location {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor, my $argName) = @_;
  my ($widget, $arg, $range) = $self->locate_formal_arg($sym, $cursor, $argName)
    or return;
  my Location $loc = +{};
  $loc->{uri} = $self->filename2uri($self->part_filename($widget));
  $loc->{range} = $range;
  $loc;
}

# Location of the variable $name visible at $cursor (args, <yatt:my>).
sub variable_location {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor, my $name) = @_;
  my SymbolInfo $varSym = +{%$sym};
  $varSym->{name} = $name;
  my VarInfo $var = $self->locate_entity_var($varSym, $cursor) or return;
  my Location $loc = +{};
  $loc->{uri} = $self->filename2uri($var->{filename} // $sym->{filename});
  $loc->{range} = $var->{range};
  $loc;
}

sub describe_symbol_of_ATTRIBUTE {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;
  my AltNode $node = $cursor->{array}[$cursor->{index}];
  my ($name) = lexpand($node->{path});
  return unless defined $name and not ref $name;
  $self->describe_variable($sym, $cursor, $name)
    // $self->describe_formal_arg($sym, $cursor, $name);
}

sub describe_symbol_of_ATT_BARENAME {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;
  my AltNode $node = $cursor->{array}[$cursor->{index}];
  if ($node->{value_range}
      and $self->is_in_range($node->{value_range}, $sym->{refpos})) {
    return $self->describe_variable($sym, $cursor, $node->{value});
  }
  my ($name) = lexpand($node->{path});
  return unless defined $name and not ref $name;
  $self->describe_formal_arg($sym, $cursor, $name);
}

sub describe_symbol_of_ATT_TEXT {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;
  my AltNode $node = $cursor->{array}[$cursor->{index}];
  my ($name) = lexpand($node->{path});
  return unless defined $name and not ref $name;
  $self->describe_formal_arg($sym, $cursor, $name);
}

sub describe_symbol_of_ATT_NESTED {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;
  my AltNode $node = $cursor->{array}[$cursor->{index}];
  return unless $node->{symbol_range};
  my @path = lexpand($node->{path});
  return unless @path and not grep {ref $_} @path;
  $self->describe_formal_arg($sym, $cursor, $path[-1]);
}

sub describe_variable {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor, my $name) = @_;
  my SymbolInfo $varSym = +{%$sym};
  $varSym->{name} = $name;
  my VarInfo $var = $self->locate_entity_var($varSym, $cursor) or return;
  $self->describe_entity_var($varSym, $var);
}

sub describe_formal_arg {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor, my $argName) = @_;
  my ($widget, $arg) = $self->locate_formal_arg($sym, $cursor, $argName)
    or return;
  my MarkupContent $md = +{};
  $md->{kind} = 'markdown';
  $md->{value} = $self->md_quote_code_as(
    yatt => "argument $argName of <" . $widget->callsite_name . ">: "
    . $arg->spec_string
  );
  $md;
}

sub filename2uri {
  (my MY $self, my $fn) = @_;
  URI::file->new_abs($fn)->as_string;
}

sub part_filename {
  (my MY $self, my Part $part) = @_;
  my Template $tmpl = $part->{folder};
  $tmpl->{path};
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

  return unless $cursor;
  my AltNode $node = $cursor->{array}[$cursor->{index}]
    or return;

  my Position $pos = $self->range_start($sym->{range});

  my $wname = join(":", lexpand($node->{path}));

  # Callable variable first, as in gen_call. GH-280
  if (my VarInfo $var = $self->locate_callable_var_of_element($node, $cursor)) {
    return $self->describe_entity_var($sym, $var);
  }

  # Builtin macros like yatt:if, yatt:foreach, ... GH-280
  if ($self->macro_method_of_element($node, $sym->{filename}, $pos->{line})) {
    my MarkupContent $md = +{};
    $md->{kind} = 'markdown';
    $md->{value} = $self->md_quote_code_as(yatt => "(macro) <$wname>");
    return $md;
  }

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

  if (my VarInfo $var = $self->locate_entity_var($sym, $cursor, [qw(code expr)])) {
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

# <yatt:NAME .../> calls the callable variable NAME (code/delegate) when
# one is in scope; CGen::Perl::gen_call looks it up before widgets, and
# only as_varcall_code / as_varcall_delegate exist. GH-280
sub locate_callable_var_of_element {
  (my MY $self, my AltNode $node, my Zipper $cursor) = @_;
  my @path = lexpand($node->{path});
  return unless @path == 2 and defined $path[1] and not ref $path[1];
  my SymbolInfo $varSym = +{};
  $varSym->{name} = $path[1];
  my VarInfo $var = $self->locate_entity_var($varSym, $cursor)
    or return;
  my ($type) = split /:/, ($var->{type} // '');
  return unless defined $type and $type =~ /^(?:code|delegate)\z/;
  $var;
}

# The macro_* method CGen::Perl::from_element would dispatch this
# element to, or undef. GH-280
sub macro_method_of_element {
  (my MY $self, my AltNode $node, my ($fileName, $line)) = @_;
  my @path = lexpand($node->{path});
  return unless @path == 2 and not grep {ref $_} @path;
  my ($part, $tmpl, $core) = $self->find_part_of_file_line($fileName, $line);
  return unless $core;
  my $cgen = $core->build_cgen_of('perl');
  $cgen->can("macro_" . join("_", @path)) || $cgen->can("macro_$path[-1]");
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
  # $ofType: type name, or an ARRAY of type names.
  for (my Zipper $c = $cursor; $c; $c = $c->{path}) {
    if (my $defs = $c->{defs}) {
      if (my VarInfo $var = $defs->{$sym->{name}}) {
        next if defined $ofType
          and not grep {$var->{type} eq $_} lexpand($ofType);
        return $var;
      }
    }
  }
}

sub locate_entity_function {
  (my MY $self, my SymbolInfo $sym, my Zipper $cursor) = @_;

  my ($tmpl, $core) = $self->find_template($sym->{filename});

  $self->find_entity_from($tmpl, $sym->{name});
}

sub md_quote_code_as {
  (my MY $self, my ($langId, $text)) = @_;
   my $pre = q{```}.$langId."\n";
   $text =~ s/\n*\z/\n/;
   $pre.$text.q{```}."\n";
}

sub widget_signature_md {
  (my MY $self, my Widget $widget, my $detail) = @_;
  my $wname = $widget->callsite_name;
  my $args = join("", map {
    my $var = $widget->{_arg_dict}{$_};
    " ".join("=", $_, q{"}.$var->spec_string.q{"}).($detail ? "\n" : "");
  } @{$widget->{_arg_order}});
  if ($detail) {
    $self->md_quote_code_as(yatt => "($widget->{kind}) <$wname$args/>");
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
    $sym->{name} = "$part->{kind} $part->{name}";
    $sym->{kind} = $part->isa(Widget) ? SymbolKind__Constructor
      : SymbolKind__Method;
    if ($part->isa(Widget)) {
      $sym->{detail} = $self->widget_signature_md($part);
    }
    $sym->{range} = $self->part_decl_range($part);
    $sym->{selectionRange} = $self->part_decl_range($part);
  }
  @result;
}

sub lookup_widget_from {
  (my MY $self, my ($wpath, $fileName, $line)) = @_;

  my ($part, $tmpl, $core) = $self->find_part_of_file_line($fileName, $line);
  return unless $part; # GH-275

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
  # The placeholder locate_node inserts (undef, or {} if something
  # autovivified it) is not a symbol. GH-280
  return unless defined $node->{kind};

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

sub is_debug_enabled {
  (my MY $self) = @_;
  defined $self->{dir} && -e "$self->{dir}/DEBUG_YATT_LANGSERVER";
}

sub debug_log {
  (my MY $self, my @message) = @_;
  return unless $self->is_debug_enabled;
  print STDERR "[YATT::Lite::Inspector] ", @message, "\n";
}

sub get_file_line {
  (my MY $self, my ($fileName, $lineNumber)) = @_;
  
  my ($tmpl) = $self->find_template($fileName);
  return unless $tmpl && defined $tmpl->{string};
  
  # Split template string into lines
  my @lines = split /\n/, $tmpl->{string};
  
  return $lines[$lineNumber] if $lineNumber < @lines;
  return;
}

sub get_completion_items {
  (my MY $self, my ($fileName, $line, $column, $triggerCharacter)) = @_;
  
  $self->debug_log("get_completion_items called: file=$fileName, line=$line, column=$column, trigger='" . ($triggerCharacter // 'undef') . "'");
  
  # Get active namespaces
  my @namespaces = lexpand($self->{_SITE}->cget('namespace'));
  @namespaces = ('yatt') unless @namespaces;
  $self->debug_log("Active namespaces: " . join(", ", @namespaces));
  
  # Get the current line text
  my $lineText = $self->get_file_line($fileName, $line);
  return unless defined $lineText;
  $self->debug_log("Line text: '$lineText'");
  
  # Extract the prefix before cursor position
  my $prefix = substr($lineText, 0, $column);
  $self->debug_log("Prefix before cursor: '$prefix'");
  
  # Determine completion context
  my @items;
  
  # Create namespace pattern
  my $ns_pattern = join('|', map { quotemeta } @namespaces);
  
  # Check for widget or entity completion
  if ($prefix =~ /<($ns_pattern):(\w*(?::\w*)*)$/) {
    # Widget completion: <namespace:widgetname
    my $namespace = $1;
    my $widgetPath = $2 // '';
    $self->debug_log("Widget completion detected: namespace=$namespace, path='$widgetPath'");
    push @items, $self->complete_widgets($fileName, $namespace, $widgetPath);
  }
  elsif ($prefix =~ /&($ns_pattern):(\w*)$/) {
    # Entity completion: &namespace:entity
    my $namespace = $1;
    my $entityName = $2 // '';
    $self->debug_log("Entity completion detected: namespace=$namespace, name='$entityName'");
    push @items, $self->complete_entities($fileName, $namespace, $entityName, $line);
  }
  elsif ($prefix =~ /<!($ns_pattern):(\w*)$/) {
    # Declaration completion: <!namespace:declaration
    my $namespace = $1;
    my $declName = $2 // '';
    $self->debug_log("Declaration completion detected: namespace=$namespace, name='$declName'");
    push @items, $self->complete_declarations($fileName, $namespace, $declName);
  }
  else {
    $self->debug_log("No completion pattern matched");
  }
  
  # TODO: Widget argument completion
  
  $self->debug_log("Returning " . scalar(@items) . " completion items");
  return @items;
}

sub complete_widgets {
  (my MY $self, my ($fileName, $namespace, $widgetPath)) = @_;
  
  $self->debug_log("complete_widgets: widgetPath='$widgetPath'");
  
  my @items;
  my @path = split /:/, $widgetPath;
  my $partialName = pop @path // '';
  $self->debug_log("Widget path parts: [" . join(", ", @path) . "], partial='$partialName'");
  
  # 1. First, add macro widgets (built-in widgets have highest priority)
  push @items, $self->complete_macro_widgets($fileName, $namespace, $partialName);
  $self->debug_log("Found " . scalar(grep { $_->{detail} =~ /macro/ } @items) . " macro widgets");
  
  # 2. Then search for user-defined widgets
  if (@path) {
    # Complex path like foo:bar:w*
    push @items, $self->complete_widgets_with_path($fileName, $namespace, \@path, $partialName);
  } else {
    # Simple completion like w*
    push @items, $self->complete_widgets_simple($fileName, $namespace, $partialName);
  }
  
  # Remove duplicates while preserving order
  my %seen;
  my @unique;
  foreach my $item (@items) {
    next if $seen{$item->{label}}++;
    push @unique, $item;
  }
  
  return @unique;
}

sub complete_entities {
  (my MY $self, my ($fileName, $namespace, $prefix, $line)) = @_;
  
  $self->debug_log("complete_entities: prefix='$prefix', line=$line");
  
  my @items;
  
  # 1. Entity macros (highest priority)
  push @items, $self->complete_entity_macros($fileName, $namespace, $prefix);
  $self->debug_log("Found " . scalar(grep { $_->{detail} =~ /entity macro/ } @items) . " entity macros");
  
  # 2. Variables (widget arguments)
  my $var_count_before = @items;
  push @items, $self->complete_entity_variables($fileName, $namespace, $prefix, $line);
  my $var_count = scalar(grep { $_->{kind} == 13 } @items) - scalar(grep { $_->{kind} == 13 } @items[0..$var_count_before-1]);
  $self->debug_log("Found $var_count variables");
  
  # 3. Entity functions
  my $func_count_before = @items;
  push @items, $self->complete_entity_functions($fileName, $namespace, $prefix);
  $self->debug_log("Found " . (@items - $func_count_before) . " entity functions");
  
  # Remove duplicates while preserving order
  my %seen;
  my @unique;
  foreach my $item (@items) {
    next if $seen{$item->{label}}++;
    push @unique, $item;
  }
  
  # Sort to show variables first, then entity macros, then entity functions
  my @sorted = sort {
    # Variables (kind == 13) come first
    my $a_is_var = $a->{kind} == 13 ? 0 : 1;
    my $b_is_var = $b->{kind} == 13 ? 0 : 1;
    if ($a_is_var != $b_is_var) {
      return $a_is_var <=> $b_is_var;
    }
    
    # Then entity macros
    my $a_is_macro = ($a->{detail} && $a->{detail} =~ /entity macro/) ? 0 : 1;
    my $b_is_macro = ($b->{detail} && $b->{detail} =~ /entity macro/) ? 0 : 1;
    if ($a_is_macro != $b_is_macro) {
      return $a_is_macro <=> $b_is_macro;
    }
    
    # Finally sort by label
    return $a->{label} cmp $b->{label};
  } @unique;
  
  $self->debug_log("Total unique entities: " . scalar(@sorted));
  return @sorted;
}

sub complete_macro_widgets {
  (my MY $self, my ($fileName, $namespace, $prefix)) = @_;
  
  my @items;
  my ($tmpl, $core) = $self->find_template($fileName);
  return unless $core;
  
  # Get the code generator
  my $cgen = $core->build_cgen_of('perl');
  
  # Find all macro_* methods
  my $cgen_class = ref($cgen) || $cgen;
  my @methods = $self->list_methods_starting_with($cgen_class, 'macro_');
  
  foreach my $method (@methods) {
    my $widget_name = $method;
    $widget_name =~ s/^macro_//;
    
    next unless $widget_name =~ /^\Q$prefix/;
    
    my CompletionItem $item = {};
    $item->{label} = $widget_name;
    $item->{kind} = SymbolKind__Constructor;
    $item->{detail} = "macro $namespace:$widget_name";
    $item->{documentation} = "Built-in macro widget";
    
    push @items, $item;
  }
  
  @items;
}

sub complete_widgets_simple {
  (my MY $self, my ($fileName, $namespace, $prefix)) = @_;
  
  my @items;
  my ($tmpl, $core) = $self->find_template($fileName);
  return unless $tmpl && $core;
  
  # Search in current template first
  foreach my Widget $widget ($tmpl->widget_list) {
    next if $widget->{name} eq '';  # Skip default widget
    next unless $widget->{name} =~ /^\Q$prefix/;
    
    push @items, $self->make_widget_completion_item($widget, $namespace);
  }
  
  # Search in current directory and inherited directories
  if (my Folder $folder = $tmpl->{parent}) {
    push @items, $self->complete_widgets_in_folder_recursive($folder, $fileName, $namespace, $prefix, $tmpl);
  }
  
  @items;
}

sub complete_widgets_with_path {
  (my MY $self, my ($fileName, $namespace, $pathRef, $prefix)) = @_;
  
  my @items;
  my @path = @$pathRef;
  my ($tmpl, $core) = $self->find_template($fileName);
  return unless $tmpl && $core;
  
  # Try with namespace first, then without
  my $target = $core->find_part_from($tmpl, $namespace, @path)
            || $core->find_part_from($tmpl, @path);
  
  if ($target) {
    if ($target->isa($self->Template)) {
      # Found a template file, complete widgets within it
      foreach my Widget $widget ($target->widget_list) {
        next if $widget->{name} eq '';
        next unless $widget->{name} =~ /^\Q$prefix/;
        
        foreach my CompletionItem $item ($self->make_widget_completion_item($widget, $namespace)) {
          # Adjust label to include full path
          my $full_path = join(':', @path, $widget->{name});
          my $original_label = $item->{label};
          if ($original_label =~ / \(self-closing\)$/) {
            $item->{label} = $full_path . " (self-closing)";
          } else {
            $item->{label} = $full_path;
          }
          $item->{detail} = "widget $namespace:" . $full_path;
          $item->{filterText} = $full_path;  # Update filter text too
          push @items, $item;
        }
      }
    } elsif ($target->isa('YATT::Lite::VFS::Folder')) {
      # Found a folder, complete files/widgets within it
      push @items, $self->complete_widgets_in_folder($target, $fileName, $namespace, $prefix, undef, \@path);
    }
  }
  
  @items;
}

sub complete_widgets_in_folder_recursive {
  (my MY $self, my Folder $folder, my ($fileName, $namespace, $prefix, $exclude_tmpl)) = @_;
  
  my @items;
  my %seen;
  my ($tmpl, $core) = $self->find_template($fileName);
  return unless $core;
  
  # Search current folder
  push @items, $self->complete_widgets_in_folder($folder, $fileName, $namespace, $prefix, $exclude_tmpl);
  
  # Search in base folders (inheritance)
  my @queue = ($folder);
  while (@queue) {
    my Folder $cur = shift @queue;
    next if $seen{$cur}++;
    
    if (my $base = $cur->{base}) {
      my @bases = ref($base) eq 'ARRAY' ? @$base : $base;
      foreach my Folder $base_folder (@bases) {
        push @items, $self->complete_widgets_in_folder($base_folder, $fileName, $namespace, $prefix);
        push @queue, $base_folder;
      }
    }
  }
  
  @items;
}

sub complete_widgets_in_folder {
  (my MY $self, my Folder $folder, my ($fileName, $namespace, $prefix, $exclude_tmpl, $pathPrefix)) = @_;
  
  my @items;
  $pathPrefix //= [];
  my ($tmpl, $core) = $self->find_template($fileName);
  return unless $core;
  
  # Refresh folder to ensure we have latest content
  $folder->refresh($core);
  
  # Get all parts in this folder
  foreach my Part $part ($folder->list_parts) {
    next unless $part;
    
    if ($part->isa($self->Template)) {
      my Template $tmpl = $part;
      next if $exclude_tmpl && $tmpl == $exclude_tmpl;
      
      # Extract base name without extension
      my $base_name = $tmpl->{name};
      $base_name =~ s/\.\w+$// if defined $base_name;
      
      # Check if this matches our prefix
      if ($base_name && $base_name =~ /^\Q$prefix/) {
        # File name matches - suggest the file itself (default widget)
        if (my $default_widget = $tmpl->{_Item}{''}) {
          foreach my CompletionItem $comp_item ($self->make_widget_completion_item($default_widget, $namespace)) {
            my $full_path = @$pathPrefix ? join(':', @$pathPrefix, $base_name) : $base_name;
            my $original_label = $comp_item->{label};
            if ($original_label =~ / \(self-closing\)$/) {
              $comp_item->{label} = $full_path . " (self-closing)";
            } else {
              $comp_item->{label} = $full_path;
            }
            $comp_item->{detail} = "template $namespace:$full_path (default widget)";
            $comp_item->{filterText} = $full_path;
            
            # Fix insertText for default widgets (which have empty name)
            if ($comp_item->{insertTextFormat} == InsertTextFormat__Snippet) {
              # Replace empty widget name with the actual path in snippet
              $comp_item->{insertText} =~ s/^>/$full_path>/;
              $comp_item->{insertText} =~ s/<\/\Q$namespace\E:>/<\/$namespace:$full_path>/;
            } else {
              # Replace empty widget name in plain text
              $comp_item->{insertText} =~ s/^\/>/$full_path\/>/;
            }
            
            push @items, $comp_item;
          }
        }
        
        # Also suggest widgets within this file
        foreach my Widget $widget ($tmpl->widget_list) {
          next if $widget->{name} eq '';
          
          foreach my CompletionItem $comp_item ($self->make_widget_completion_item($widget, $namespace)) {
            my $full_path = @$pathPrefix 
              ? join(':', @$pathPrefix, $base_name, $widget->{name})
              : join(':', $base_name, $widget->{name});
            my $original_label = $comp_item->{label};
            if ($original_label =~ / \(self-closing\)$/) {
              $comp_item->{label} = $full_path . " (self-closing)";
            } else {
              $comp_item->{label} = $full_path;
            }
            $comp_item->{detail} = "widget $namespace:$full_path";
            $comp_item->{filterText} = $full_path;
            push @items, $comp_item;
          }
        }
      }
    }
  }
  
  @items;
}

sub make_widget_completion_item {
  (my MY $self, my Widget $widget, my ($namespace)) = @_;
  
  # We'll return multiple items for different tag styles
  my @items;
  
  # Base item properties (shared between variants)
  my $base = {
    kind => SymbolKind__Function,
    detail => "widget $namespace:$widget->{name}",
  };
  
  # Add argument info if available
  my @args = $self->list_part_args_internal($widget);
  my $doc = '';
  my @snippet_params;
  my $param_count = 0;
  
  if (@args) {
    my @argSpecs;
    
    foreach my ArgSpec $arg (@args) {
      my $spec = $arg->{varname};
      $spec .= ": " . $arg->{type}->[0] if $arg->{type};
      $spec .= " (required)" if $arg->{is_required};
      push @argSpecs, $spec;
      
      # Build snippet parameters for required arguments
      if ($arg->{is_required} && $arg->{varname} ne 'body') {
        $param_count++;
        push @snippet_params, $arg->{varname} . '="${' . $param_count . ':' . $arg->{varname} . '}"';
      }
    }
    
    $doc = join("\n", @argSpecs) if @argSpecs;
  }
  
  # 1. Self-closing tag variant
  {
    my CompletionItem $item = { %$base };
    $item->{label} = $widget->{name} . " (self-closing)";
    $item->{sortText} = $widget->{name} . "_1";  # Sort after the main variant
    $item->{filterText} = $widget->{name};  # Filter by widget name only
    $item->{documentation} = $doc if $doc;
    
    if (@snippet_params) {
      $item->{insertText} = $widget->{name} . ' ' . join(' ', @snippet_params) . '/>';
      $item->{insertTextFormat} = InsertTextFormat__Snippet;
    } else {
      $item->{insertText} = $widget->{name} . '/>';
      $item->{insertTextFormat} = InsertTextFormat__PlainText;
    }
    push @items, $item;
  }
  
  # 2. Open/close tag variant
  {
    my CompletionItem $item = { %$base };
    $item->{label} = $widget->{name};
    $item->{sortText} = $widget->{name} . "_0";  # Sort before self-closing
    $item->{filterText} = $widget->{name};
    $item->{documentation} = $doc if $doc;
    
    my $next_pos = $param_count + 1;
    if (@snippet_params) {
      $item->{insertText} = $widget->{name} . ' ' . join(' ', @snippet_params) . '>$' . $next_pos . '</' . $namespace . ':' . $widget->{name} . '>';
    } else {
      $item->{insertText} = $widget->{name} . '>$1</' . $namespace . ':' . $widget->{name} . '>';
    }
    $item->{insertTextFormat} = InsertTextFormat__Snippet;
    push @items, $item;
  }
  
  # Return list in list context, single item in scalar context (for backward compatibility)
  wantarray ? @items : $items[0];
}

sub list_methods_starting_with {
  (my MY $self, my ($class, $prefix)) = @_;
  
  my @methods;
  my $symtab = symtab($class);
  
  foreach my $name (keys %$symtab) {
    next unless $name =~ /^\Q$prefix/;
    my $glob = MOP4Import::Util::globref($class, $name);
    next unless defined *{$glob}{CODE};
    push @methods, $name;
  }
  
  # Also check parent classes
  foreach my $parent (@{MOP4Import::Util::isa_array($class)}) {
    push @methods, $self->list_methods_starting_with($parent, $prefix);
  }
  
  # Remove duplicates
  my %seen;
  grep { !$seen{$_}++ } @methods;
}

sub complete_entity_macros {
  (my MY $self, my ($fileName, $namespace, $prefix)) = @_;
  
  my @items;
  my ($tmpl, $core) = $self->find_template($fileName);
  return unless $core;
  
  # Get the code generator
  my $cgen = $core->build_cgen_of('perl');
  
  # Find all entmacro_* methods
  my $cgen_class = ref($cgen) || $cgen;
  my @methods = $self->list_methods_starting_with($cgen_class, 'entmacro_');
  
  foreach my $method (@methods) {
    my $entity_name = $method;
    $entity_name =~ s/^entmacro_//;
    
    next unless $entity_name =~ /^\Q$prefix/;
    
    my CompletionItem $item = {};
    $item->{label} = $entity_name;
    $item->{kind} = SymbolKind__Function;
    $item->{detail} = "entity macro $namespace:$entity_name";
    $item->{documentation} = "Built-in entity macro";
    
    # Add snippets for common entity macros
    if ($entity_name eq 'if') {
      $item->{insertText} = 'if(${1:condition}, ${2:then}, ${3:else});';
      $item->{insertTextFormat} = InsertTextFormat__Snippet;
    }
    elsif ($entity_name eq 'unless') {
      $item->{insertText} = 'unless(${1:condition}, ${2:then}, ${3:else});';
      $item->{insertTextFormat} = InsertTextFormat__Snippet;
    }
    elsif ($entity_name eq 'ifeq') {
      $item->{insertText} = 'ifeq(${1:a}, ${2:b}, ${3:then}, ${4:else});';
      $item->{insertTextFormat} = InsertTextFormat__Snippet;
    }
    elsif ($entity_name eq 'value_checked' || $entity_name eq 'value_selected') {
      $item->{insertText} = $entity_name . '(${1:name}, ${2:value});';
      $item->{insertTextFormat} = InsertTextFormat__Snippet;
    }
    else {
      # Default: just add semicolon
      $item->{insertText} = $entity_name . ';';
      $item->{insertTextFormat} = InsertTextFormat__PlainText;
    }
    
    push @items, $item;
  }
  
  @items;
}

sub complete_entity_variables {
  (my MY $self, my ($fileName, $namespace, $prefix, $line)) = @_;
  
  my @items;
  
  # Find the part (widget) at the current line
  (my Part $part, my Template $tmpl, my $core)
    = $self->find_part_of_file_line($fileName, $line)
      or return;
  
  # List all arguments of the current widget
  foreach my $argName (@{$part->{_arg_order} || []}) {
    next unless $argName =~ /^\Q$prefix/;
    
    my $arg = $part->{_arg_dict}{$argName};
    my CompletionItem $item = {};
    $item->{label} = $argName;
    $item->{kind} = SymbolKind__Variable;
    $item->{detail} = "var $argName" . ($arg->type ? ": " . join(":", lexpand($arg->type)) : "");
    
    if ($arg->is_required) {
      $item->{documentation} = "Required argument";
    }
    
    # Variables just need a semicolon
    $item->{insertText} = $argName . ';';
    $item->{insertTextFormat} = InsertTextFormat__PlainText;
    
    push @items, $item;
  }

  # Page constants, unless shadowed by an argument. GH-286
  my $pagevars = $self->pagevar_defs_of_template($tmpl);
  foreach my $name (sort keys %$pagevars) {
    next unless $name =~ /^\Q$prefix/;
    next if $part->{_arg_dict}{$name};
    my VarInfo $var = $pagevars->{$name};
    my CompletionItem $item = {};
    $item->{label} = $name;
    $item->{kind} = SymbolKind__Variable;
    $item->{detail} = "pagevar $name: $var->{type}";
    $item->{documentation} = $var->{detail} if defined $var->{detail};
    $item->{insertText} = $name . ';';
    $item->{insertTextFormat} = InsertTextFormat__PlainText;
    push @items, $item;
  }
  
  @items;
}

sub complete_entity_functions {
  (my MY $self, my ($fileName, $namespace, $prefix)) = @_;
  
  my @items;
  my ($tmpl, $core) = $self->find_template($fileName);
  return unless $tmpl;
  
  # Get the entns for this template
  my $entns = $tmpl->cget('entns');
  return unless $entns;
  
  # Find all entity_* methods in the entns and its parents
  my @methods = $self->list_methods_starting_with($entns, 'entity_');
  
  foreach my $method (@methods) {
    my $entity_name = $method;
    $entity_name =~ s/^entity_//;
    
    next unless $entity_name =~ /^\Q$prefix/;
    
    my CompletionItem $item = {};
    $item->{label} = $entity_name;
    $item->{kind} = SymbolKind__Function;
    $item->{detail} = "entity $namespace:$entity_name";
    $item->{documentation} = "User-defined entity function";
    
    # For entity functions, add parentheses and semicolon
    $item->{insertText} = $entity_name . '($1);';
    $item->{insertTextFormat} = InsertTextFormat__Snippet;
    
    push @items, $item;
  }
  
  @items;
}

sub complete_declarations {
  (my MY $self, my ($fileName, $namespace, $prefix)) = @_;
  
  $self->debug_log("complete_declarations: prefix='$prefix'");
  
  my @items;
  my ($tmpl, $core) = $self->find_template($fileName);
  return unless $core;
  
  # Get the parser instance
  my $parser = $core->Parser;
  return unless $parser;
  
  # Get parser class
  my $parser_class = ref($parser) || $parser;
  
  # Find all build_* and declare_* methods
  my @build_methods = $self->list_methods_starting_with($parser_class, 'build_');
  my @declare_methods = $self->list_methods_starting_with($parser_class, 'declare_');
  
  # Extract declaration names
  my %declarations;
  foreach my $method (@build_methods) {
    my $decl_name = $method;
    $decl_name =~ s/^build_//;
    $declarations{$decl_name} = 1;
  }
  foreach my $method (@declare_methods) {
    my $decl_name = $method;
    $decl_name =~ s/^declare_//;
    $declarations{$decl_name} = 1;
  }
  
  # Create completion items
  foreach my $decl (sort keys %declarations) {
    next unless $decl =~ /^\Q$prefix/;
    
    my CompletionItem $item = {};
    $item->{label} = $decl;
    $item->{kind} = SymbolKind__Property;  # Using Property as Keyword doesn't exist
    $item->{detail} = "declaration $namespace:$decl";
    $item->{documentation} = "";  # Leave documentation empty as requested
    
    # Add snippet support for declarations
    if ($decl eq 'args') {
      $item->{insertText} = "args \${1:arguments}>\n\$0";
      $item->{insertTextFormat} = InsertTextFormat__Snippet;
    }
    elsif ($decl eq 'widget') {
      $item->{insertText} = "widget \${1:name} \${2:args}>\n\$0";
      $item->{insertTextFormat} = InsertTextFormat__Snippet;
    }
    elsif ($decl eq 'entity') {
      $item->{insertText} = "entity \${1:name} \${2:params}>\n\$0";
      $item->{insertTextFormat} = InsertTextFormat__Snippet;
    }
    elsif ($decl eq 'action') {
      $item->{insertText} = "action \${1:name}>\n\$0";
      $item->{insertTextFormat} = InsertTextFormat__Snippet;
    }
    elsif ($decl eq 'base') {
      $item->{insertText} = "base \${1:file=\"../base.ytmpl\"}>\n\$0";
      $item->{insertTextFormat} = InsertTextFormat__Snippet;
    }
    else {
      # For other declarations, just add the closing > and newline
      $item->{insertText} = "$decl \$1>\n\$0";
      $item->{insertTextFormat} = InsertTextFormat__Snippet;
    }
    
    push @items, $item;
  }
  
  $self->debug_log("Found " . scalar(@items) . " declarations");
  @items;
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
    # e.g. cursor past the last part. Not a symbol, not an error. GH-275
    $self->debug_log("position is out of part range: range="
                     .terse_dump($range)." line=$line col=$column");
    return;
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
  my $rangeMap = $self->arg_range_map_of_part($part);
  my $fileName = $self->part_filename($part);
  $outermost->{defs}{$_}
    //= $self->make_document_symbol_from_argument($part->{_arg_dict}{$_}
                                                  , $rangeMap, $fileName)
    for keys %{$part->{_arg_dict}};
  # Page constants form the outermost scope; arguments win. GH-286
  my $pagevars = $self->pagevar_defs_of_template($part->{folder});
  $outermost->{defs}{$_} //= $pagevars->{$_} for keys %$pagevars;
  $self->augment_defs_1($zipperList, 0, $fileName);
  $cursor;
}

# name => Range of each argument token written in the <!yatt:...>
# declaration. Args injected by argmacros have no token here. GH-275
# The implicit body argument maps to the declaration line. GH-280
sub arg_range_map_of_part {
  (my MY $self, my Part $part) = @_;
  my $decllist = $part->{_decllist} or return {};
  my Template $tmpl = $part->{folder};
  my %map;
  my @lines;
  # Reversed: the first ATTRIBUTE node of widget/page/entity/action
  # declarations is the part name itself. An argument with the same name
  # (a later node) must win.
  foreach my AltNode $node (reverse @{$self->alttree($tmpl, $decllist)}) {
    next unless defined $node->{kind}
      and $node->{kind} =~ /^(?:ATTRIBUTE|ATT_TEXT|ATT_BARENAME|ATT_NESTED)\z/;
    my ($name) = lexpand($node->{path});
    next if not defined $name or ref $name;
    my Range $range = $node->{symbol_range};
    if (not $range and $node->{kind} eq 'ATT_NESTED'
        and (my Range $tree = $node->{tree_range})) {
      # cb=[code a b]: the node starts at "[", so look back on the
      # same line for the "cb=" before it. GH-280
      @lines = split /\n/, ($tmpl->{string} // '') unless @lines;
      my $lineText = $lines[$tree->{start}{line}] // '';
      if (substr($lineText, 0, $tree->{start}{character})
          =~ /(\Q$name\E)\s*=\s*\z/) {
        $range = $self->make_range_on_line($tree->{start}{line}, $-[1], $+[1]);
      }
    }
    $map{$name} = $range // $node->{tree_range};
  }
  if (my $dict = $part->{_arg_dict}) {
    foreach my $name (keys %$dict) {
      next if $map{$name};
      my $arg = $dict->{$name};
      next unless $arg->is_body_argument;
      $map{$name} = $self->part_decl_range($part);
    }
  }
  \%map;
}

sub make_range_on_line {
  (my MY $self, my ($line, $startChar, $endChar)) = @_;
  my Range $range = +{};
  $range->{start} = +{line => $line, character => $startChar};
  $range->{end} = +{line => $line, character => $endChar};
  $range;
}

sub make_document_symbol_from_argument {
  (my MY $self, my ($arg, $rangeMap, $fileName)) = @_;
  my VarInfo $var = {};
  $var->{name} = $arg->varname;
  $var->{kind} = '(argument)';
  $var->{type} = join(":", lexpand($arg->type));
  if (my $spec = $arg->spec_string) {
    $var->{detail} = qq{"$spec"};
  }
  $var->{filename} = $fileName;
  # A real Range (start/end), not a Position. VarTypes lineno is 1-based.
  $var->{range} = ($rangeMap && $rangeMap->{$var->{name}})
    // $self->make_line_range(($arg->lineno // 1) - 1);
  $var;
}

# Page constants (pagevars, GH-282) of the page $tmpl as name => VarInfo,
# located in the pagevars module. Empty for non-page templates
# (page_name is undef) and when the module can't be loaded. GH-286
sub pagevar_defs_of_template {
  (my MY $self, my Template $tmpl) = @_;
  return {} unless $tmpl and defined(my $page = $tmpl->page_name);
  my $yatt = $self->find_yatt_for_template($tmpl->{path})
    or return {};
  my $pagevars = $yatt->cget('pagevars')
    or return {};
  my $consts = eval {
    YATT::Lite::Util::ckrequire($pagevars);
    $pagevars->find_consts($page);
  };
  if ($@) {
    $self->debug_log("Can't load pagevars $pagevars: $@");
    return {};
  }
  return {} unless $consts;
  my %defs;
  foreach my $name (keys %$consts) {
    my VarInfo $var = {};
    $var->{kind} = 'pagevar';
    $var->{name} = $name;
    $var->{type} = $pagevars->const_type($consts->{$name});
    $var->{detail} = $self->pagevar_value_preview($consts->{$name}
                                                  , $var->{type});
    my ($file, $line) = $pagevars->locate_const($page, $name);
    $var->{filename} = $file;
    # locate_const returns 1-based line.
    $var->{range} = $self->make_line_range(($line // 1) - 1);
    $defs{$name} = $var;
  }
  \%defs;
}

sub pagevar_value_preview {
  (my MY $self, my ($value, $type)) = @_;
  if ($type eq 'text' or $type eq 'html') {
    my $str = "$value";
    $str = substr($str, 0, 40) . "..." if length $str > 43;
    $str =~ s/\n/\\n/g;
    qq{"$str"};
  } elsif ($type eq 'list') {
    sprintf "[%d items]", scalar @$value;
  } else {
    undef;
  }
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
  (my MY $self, my ($zipperList, $depth, $fileName)) = @_;

  my Zipper $zipper = $zipperList->[$depth];

  my @nodes = @{$zipper->{array}}[0..$zipper->{index}];
  # $nodes[-1] may be the undef placeholder which locate_node inserts
  # when the cursor is between nodes. GH-275
  my $current = $nodes[-1];
  foreach my AltNode $node (@nodes) {
    unless (defined $node and defined $node->{kind}) {
      next;
    }
    my $method = join("_", augment_defs_1_ =>
                      , $node->{kind}, lexpand($node->{path}));
    my $sub = $self->can($method)
      or next;
    $sub->($self, $zipper, $node, (defined $current && $node == $current)
           , $fileName);
  }
}

sub augment_defs_1__ELEMENT_yatt_my {
  (my MY $self, my Zipper $cursor, my AltNode $node
   , my ($isCurrent, $fileName)) = @_;
  foreach my AltNode $subNode (@{$node->{subtree}}) {
    # $subNode aliases the array element: testing $subNode->{kind} on
    # the undef placeholder of locate_node would autovivify it. GH-280
    next unless defined $subNode and defined $subNode->{kind};
    next unless $subNode->{kind} eq "ATT_TEXT";
    my ($name, @type) = lexpand($subNode->{path});
    $cursor->{defs}{$name} = my VarInfo $var = +{};
    $var->{kind} = 'my';
    $var->{name} = $name;
    $var->{type} = @type ? join(":", @type) : 'text';
    $var->{range} = $subNode->{symbol_range} // $subNode->{tree_range};
    $var->{filename} = $fileName;
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
    } elsif ($node->{tree_range}
             and $self->is_in_range($node->{tree_range}, $pos)) {
      # Inside a leaf node, e.g. the bare value of a=y. GH-277
      return $current;
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

  my ($part, $tmpl, $core) = $self->find_part_of_file_line($fileName, $line);
  return unless $part; # GH-275

  $part->{_decllist}
}

sub dump_part_tree {
  (my MY $self, my ($fileName, $line)) = @_;
  $line //= 0;

  my ($part, $tmpl, $core) = $self->find_part_of_file_line($fileName, $line);
  return unless $part; # GH-275

  unless (UNIVERSAL::isa($part, 'YATT::Lite::Core::Widget')) {
    Carp::croak "part $part->{kind} $part->{name} is not a widget";
  }

  $core->ensure_parsed($part);
  my Widget $widget = $part;
  $widget->{_tree}
}

sub dump_tokens_at_file_position {
  (my MY $self, my ($fileName, $line, $column)) = @_;
  $line //= 0;

  my ($part, $tmpl, $core) = $self->find_part_of_file_line($fileName, $line);
  return unless $part; # GH-275

  return unless defined $tmpl->{nlines};

  unless ($line <= $tmpl->{nlines} - 1) {
    # warn?
    return;
  }

  # my $yatt = $self->find_yatt_for_template($fileName);
  $core->ensure_parsed($part);

  $part->{endln} //= $tmpl->{nlines}; # XXX:

  my $declkind = [$part->{namespace}, $part->{kind}];

  if ($line < $part->{bodyln} - 1) {
    # At declaration
    [decllist => $declkind
     , $self->part_decl_range($part)
     , $self->alttree($tmpl, $part->{_decllist})
     , $part
   ];
  } elsif (UNIVERSAL::isa($part, 'YATT::Lite::Core::Widget')) {
    # At body of widget, page, args...
    my Widget $widget = $part;
    [body => $declkind
     , $self->part_body_range($part)
     , $self->alttree($tmpl, $widget->{_tree})
     , $part
   ];
  } else {
    # At body of action, entity, ...
    # XXX: TODO extract tokens for host language.
    [body_string => $declkind
     , $self->part_body_range($part)
     , $part->{_toks}
     , $part
   ];
  }
}

sub part_decl_range {
  (my MY $self, my Part $part) = @_;
  my Range $range;
  $range->{start} = $self->make_line_position($part->{startln} - 1);
  $range->{end} = $self->make_line_position($part->{bodyln} - 1);
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
  $range->{start} = $self->make_line_position($part->{bodyln} - 1);
  my Template $tmpl = $part->{folder};
  my $hasLastNL = $tmpl->{string} =~ /\n\z/ ? 1 : 0;
  $range->{end} = $self->make_line_position($part->{endln}
                                            - ($hasLastNL ? 1 : 0));
  $range;
}

sub find_part_of_file_line {
  (my MY $self, my ($fileName, $line)) = @_;
  $line //= 0;
  my ($tmpl, $core) = $self->find_template($fileName);
  my Part $prev;
  foreach my Part $part ($tmpl->list_parts) {
    last if $line < $part->{startln} - 1;
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

  # perl コードの生成を行わないと、継承が設定されないため。
  try {
    $core->find_product(perl => $tmpl);
  } catch {
    # XXX
  };

  wantarray ? ($tmpl, $core) : $tmpl;
}

# Forget the in-memory text (didOpen/didChange) and re-read the file from
# disk. apply_changes stamps mtime with the wall clock; clearing it makes
# refresh reload unconditionally. GH-275
sub reload_file_from_disk {
  (my MY $self, my $fileName) = @_;
  my ($tmpl, $core) = $self->find_template($fileName);
  undef $tmpl->{mtime};
  $tmpl->refresh($core);
  $tmpl;
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
  (my MY $self, my ($tmplOrFile, $entityName)) = @_;

  my ($tmpl) = ref $tmplOrFile ? $tmplOrFile : $self->find_template($tmplOrFile);

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
        $self->{detail} ? [[+{@result}]] : [\@result]
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

  my $vfs_item = $self->{_SITE}->get_yatt_by_entns($entns);
  my $entity;

  my $sub;
  if ($vfs_item
      and $sub = $vfs_item->can("get_type_item")
      and $entity = $sub->($vfs_item, entity => $entityName)) {

    [name => $entityName, entns => $entns
     , file => $entity->{folder}{path}, line => $entity->{startln}];
    
  } else {
    require Sub::Identify;

    my $entSub = $entns->can("entity_$entityName");

    my ($file, $line) = Sub::Identify::get_code_location($entSub);

    [name => $entityName, entns => $entns
     , file => $file // $opts{path}, line => $line];
  }

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
      my Template $tmpl = $widget->{folder};
      my $path = $tmpl->{path};
      my $args = $self->{detail}
        ? [$self->list_part_args_internal($widget)]
        : $widget->{_arg_order};
      # XXX: 残念ながら、encode_json の keyword 順を制御できていない
      tie my %result, 'Tie::IxHash', (
        (map {$_ => $found->{$_}} sort keys %$found)
        , args => $args, path => $self->clean_path($path)
      );
      $self->cli_output([\%result]);
    },
    item => sub {
      my ($args) = @_;
      # print "# ", $args->{_tree}->cget('path'), "\n";
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
  foreach my $argName ($part->{_arg_order} ? @{$part->{_arg_order}} : ()) {
    next if $nameRe and not $argName =~ $nameRe;
    my $argObj = $part->{_arg_dict}{$argName};
    push @result, my ArgSpec $spec = {};
    foreach my $i (0 .. $#fields) {
      my $val = $argObj->[$i];
      $spec->{$fields[$i]} = $val;
    }
    # Add is_required field
    $spec->{is_required} = $argObj->is_required;
  }
  @result;
}

#========================================
# list_code_args [--with_body] [--type=TYPE] [--from=DIR]
#
# yatt 宣言 (<!yatt:args>, <!yatt:widget> ...) で宣言された code 型の引数を、
# 1 引数 1 レコードで列挙する。expr 型に移すべき引数を探すため (GH-300)。
# body は出力用であることが明らかなので、既定では出さない。
# --output=tsv では path, line, kind, name, arg, spec の順の一行になる。

sub cmd_list_code_args {
  (my MY $self, my @args) = @_;
  my $opts = $self->parse_opts(\@args, {});
  # コマンド固有でないもの (--output など) は全体の設定へ
  $self->configure(map {
    $_ => delete $opts->{$_}
  } grep {not /^(?:from|with_body|type)\z/} keys %$opts);
  my @fields = qw(path line kind name arg spec);
  my $as_tsv = ($self->{output} // '') eq 'tsv';
  foreach my $rec ($self->list_code_args(%$opts)) {
    $self->cli_output([$as_tsv ? [@{$rec}{@fields}] : do {
      tie my %result, 'Tie::IxHash', map {$_ => $rec->{$_}} @fields;
      \%result;
    }]);
  }
}

sub list_code_args {
  (my MY $self, my %opts) = @_;
  my $searchFrom = delete $opts{from};
  my $withBody = delete $opts{with_body};
  my $type = delete $opts{type} // 'code';
  if (%opts) {
    Carp::croak "Unknown options: ". join(", ", sort keys %opts);
  }
  my $bodyName = $self->{_SITE}->cget('body_argument') // 'body';

  my @result;
  walk(
    factory => $self->{_SITE},
    from => $self->list_target_dirs($searchFrom),
    ignore_symlink => $self->{ignore_symlink},
    widget => sub {
      my ($found) = @_;
      my Part $part = $found->{part};
      my Template $tmpl = $part->{folder};
      foreach my $argName ($part->{_arg_order} ? @{$part->{_arg_order}} : ()) {
        my $var = $part->{_arg_dict}{$argName};
        next unless $var->type->[0] eq $type;
        # 暗黙の body には印が付き、明示した body=[code ...] には付かない
        next if not $withBody
          and ($var->is_body_argument or $argName eq $bodyName);
        push @result, +{
          path => $self->clean_path($tmpl->{path}),
          line => $var->lineno // $part->{startln},
          kind => $found->{kind},
          name => $found->{name},
          arg => $argName,
          spec => $self->arg_spec_with_nested_args($var),
        };
      }
    },
    item => sub {},
  );
  @result;
}

# spec_string と違い、[code x y] のような内側の引数も含める
sub arg_spec_with_nested_args {
  (my MY $self, my $var) = @_;
  my $type = join(":", @{$var->type});
  my $widget = $var->can('widget') && $var->widget;
  my @nested = map {
    my $sub = $widget->{_arg_dict}{$_};
    ($sub->type->[0] eq 'text' and not defined $sub->dflag)
      ? $_ : "$_=".$self->arg_spec_with_nested_args($sub);
  } $widget && $widget->{_arg_order} ? @{$widget->{_arg_order}} : ();
  (@nested ? "[$type @nested]" : $type)
    . (defined $var->dflag ? $var->dflag . ($var->default_expr // '') : '');
}

#========================================

sub is_in_template_dir {
  (my MY $self, my $path) = @_;
  my Factory $factory = $self->{_SITE};
  foreach my $dir (lexpand($factory->{_tmpldirs})) {
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
