#!/usr/bin/env perl
package YATT::Lite::LanguageServer;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use File::AddInc;
use Cwd;

my $libDir = File::AddInc->libdir;

use JSON::MaybeXS;
use Try::Tiny;

use YATT::Lite::LanguageServer::Generic -as_base
  , [fields => qw/_initialized
                  _client_cap
                  _inspector
                  _last_error
                  current_workspace
                 /
   ];

use MOP4Import::Util qw/terse_dump lexpand/;

use YATT::Lite::LanguageServer::Protocol;

use YATT::Lite::Inspector [as => 'Inspector']
  , qw/Zipper AltNode LintResult/;

sub after_configure_default {
  (my MY $self) = @_;
  $self->next::method;
  $self->{current_workspace} = $ENV{PWD} || getcwd;
}

sub lspcall__initialize {
  (my MY $self, my InitializeParams $params) = @_;
  $self->{_client_cap} = $params->{capabilities};

  # Protocol.pm predates LSP 3.17: workspaceFolders, rootPath and
  # positionEncoding(s) are accessed untyped.
  my $untyped = $params;
  my $rootUri = $params->{rootUri};
  if (not defined $rootUri
      and ref $untyped->{workspaceFolders} eq 'ARRAY'
      and @{$untyped->{workspaceFolders}}) {
    $rootUri = $untyped->{workspaceFolders}[0]{uri};
  }
  if (my $path = $self->uri2localpath($rootUri) // $untyped->{rootPath}) {
    $self->load_inspector($self->{current_workspace} = $path);
  }

  my InitializeResult $res = {};
  $res->{capabilities} = my ServerCapabilities $svcap = {};
  $svcap->{definitionProvider} = JSON()->true;
  $svcap->{implementationProvider} = JSON()->true;
  $svcap->{hoverProvider} = JSON()->true;
  $svcap->{documentSymbolProvider} = JSON()->true;
  $svcap->{completionProvider} = my CompletionOptions $copts = {};
  $copts->{triggerCharacters} = ['<', ':', "\$", '&', '=', '"', "'"];
  $copts->{resolveProvider} = JSON()->false;
  $svcap->{textDocumentSync} = my TextDocumentSyncOptions $sopts = +{};
  $sopts->{openClose} = JSON()->true;
  $sopts->{save} = JSON()->true;
  $sopts->{change} = TextDocumentSyncKind__Incremental;

  # Positions are exchanged as perl character offsets, which equal UTF-32
  # code units. Advertise that when the client can handle it (eglot does).
  # Clients limited to utf-16 get the same offsets, so their columns drift
  # after a non-BMP character on the same line. GH-275
  my $encodings = $untyped->{capabilities}{general}{positionEncodings};
  if ($encodings and grep {$_ eq 'utf-32'} lexpand($encodings)) {
    $res->{capabilities}{positionEncoding} = 'utf-32';
  }
  $res;
}

sub lspcall__initialized {
  (my MY $self, my $params) = @_;
  $self->{_initialized} = 1;
  undef;
}

# '$/cancelRequest'. Requests are processed to completion anyway;
# accepted so that the client does not see "Not implemented".
sub lspcall____ext__cancelRequest {
  (my MY $self, my $params) = @_;
  undef;
}

sub lspcall__textDocument__didOpen {
  (my MY $self, my DidOpenTextDocumentParams $params) = @_;

  my TextDocumentItem $docItem = $params->{textDocument};
  my $fn = $self->uri2localpath($docItem->{uri});

  my LintResult $error
    = $self->inspector->load_string_into_file($fn, $docItem->{text});

  $self->{_last_error}{$docItem->{uri}} = $error;

  my PublishDiagnosticsParams $notif = {};
  $notif->{uri} = $docItem->{uri};
  $notif->{diagnostics} = [$error ? lexpand($error->{diagnostics}) : ()];

  $self->send_notification('textDocument/publishDiagnostics', $notif);
}

sub last_error {
  (my MY $self, my TextDocumentIdentifier $docId) = @_;
  $self->{_last_error}{$docId->{uri}}
}

sub lspcall__textDocument__didChange {
  (my MY $self, my DidChangeTextDocumentParams $params) = @_;

  my TextDocumentIdentifier $docId = $params->{textDocument};
  my $fn = $self->uri2localpath($docId->{uri});

  (my $updated, my LintResult $error) = $self->inspector->apply_changes($fn, @{$params->{contentChanges}});

  $self->{_last_error}{$docId->{uri}} = $error;

  $self->logmsg("updated ", ($error ? "with error " : ""), "as: "
                , sub {$self->truncate_for_log(terse_dump($updated), 300)});

  my PublishDiagnosticsParams $notif = {};
  $notif->{uri} = $docId->{uri};
  $notif->{diagnostics} = [$error ? lexpand($error->{diagnostics}) : ()];

  $self->send_notification('textDocument/publishDiagnostics', $notif);
}

sub lspcall__textDocument__didSave {
  (my MY $self, my DidSaveTextDocumentParams $params) = @_;

  my TextDocumentIdentifier $docId = $params->{textDocument};
  my $fn = $self->uri2localpath($docId->{uri});

  my LintResult $res = $self->inspector->lint($fn); # XXX: process isolation

  $self->{_last_error}{$docId->{uri}} = $res->{is_success} ? undef : $res;

  $self->logmsg("lint result: ", sub {terse_dump($res)});

  my PublishDiagnosticsParams $notif = {};
  $notif->{uri} = $docId->{uri};

  if ($res->{is_success}) {
    # ok.
    $notif->{diagnostics} = [];
  } elsif ($res->{diagnostics}) {

    $notif->{diagnostics} = [lexpand($res->{diagnostics})];
  }

  if ($notif->{diagnostics}) {
    $self->send_notification('textDocument/publishDiagnostics', $notif);
  }
}

sub lspcall__textDocument__didClose {
  (my MY $self, my $params) = @_;

  my TextDocumentIdentifier $docId = $params->{textDocument};
  delete $self->{_last_error}{$docId->{uri}};

  my $fn = $self->uri2localpath($docId->{uri})
    or return undef;

  # The buffer is gone: drop its (possibly unsaved) text from the template
  # cache so that lookups from other files see what is on disk.
  try {
    $self->inspector->reload_file_from_disk($fn) if -r $fn;
  } catch {
    $self->logmsg("didClose: reload of $fn failed: $_");
  };
  undef;
}

#
# WIP
#
sub lspcall__textDocument__hover {
  (my MY $self, my TextDocumentPositionParams $params) = @_;

  my Hover $result = {};

  my TextDocumentIdentifier $docId = $params->{textDocument};

  # Skip if the document has error
  return undef if $self->last_error($docId);

  my $fn = $self->uri2localpath($docId->{uri})
    or return undef;
  my Position $pos = $params->{position};

  my $found;
  try {
    my ($symbol, $cursor) = $self->locate_symbol_at_file_position(
      $fn, $pos->{line}, $pos->{character}
    ) or return;

    # Nothing to say (e.g. an attribute of a macro element): null, not a
    # debug dump. GH-277
    if (my $contents = $self->inspector->describe_symbol($symbol, $cursor)) {
      $result->{contents} = $contents;
      $found = $result;
    }
  } catch {
    $self->logmsg("hover failed at $fn:$pos->{line}:$pos->{character}: $_");
  };

  $found;
}


sub lspcall__textDocument__definition {
  goto &lspcall__textDocument__implementation;
}

#
# No last_error guard here on purpose: parts before a syntax error still
# resolve. Any failure degrades to null (no definition) instead of a
# JSON-RPC error, which eglot would show as an error. GH-275
#
sub lspcall__textDocument__implementation {
  (my MY $self, my TextDocumentPositionParams $params) = @_;

  my TextDocumentIdentifier $docId = $params->{textDocument};
  my $fn = $self->uri2localpath($docId->{uri})
    or return undef;
  my Position $pos = $params->{position};

  my $found;
  try {
    my ($symbol, $cursor) = $self->locate_symbol_at_file_position(
      $fn, $pos->{line}, $pos->{character}
    ) or return;

    $found = $self->inspector->lookup_symbol_definition($symbol, $cursor);
  } catch {
    $self->logmsg("definition failed at $fn:$pos->{line}:$pos->{character}: $_");
  };

  $found;
}

#
# Extract a symbol at file/position.
# In list context, also returns $cursor for later tree walk.
#
sub locate_symbol_at_file_position {
  (my MY $self, my ($fn, $line, $character)) = @_;

  my ($symbol, $cursor) = $self->inspector->locate_symbol_at_file_position(
      $fn, $line, $character // 0
    ) or return;

  wantarray ? ($symbol, $cursor) : $symbol;
}

sub lspcall__textDocument__documentSymbol {
  (my MY $self, my DocumentSymbolParams $params) = @_;

  my TextDocumentIdentifier $docId = $params->{textDocument};

  # Skip if the document has error
  return undef if $self->last_error($docId);

  my $fn = $self->uri2localpath($docId->{uri});

  if (my @result = $self->inspector->list_parts_in($fn)) {
    \@result
  } else {
    undef;
  }
}

sub lspcall__textDocument__completion {
  (my MY $self, my CompletionParams $params) = @_;

  my TextDocumentIdentifier $docId = $params->{textDocument};
  
  # Don't skip even if the document has error - completion is often triggered while typing
  # and the document may be in an incomplete/error state

  my $fn = $self->uri2localpath($docId->{uri});
  my Position $pos = $params->{position};
  my CompletionContext $context = $params->{context};

  # Get completion items from inspector
  my @items = $self->inspector->get_completion_items(
    $fn, $pos->{line}, $pos->{character},
    $context ? $context->{triggerCharacter} : undef
  );

  unless (@items) {
    return undef;
  }

  my CompletionList $result = {};
  $result->{isIncomplete} = JSON()->false;
  $result->{items} = \@items;
  
  $result;
}

#----------------------------------------

sub inspector {
  (my MY $self) = @_;
  $self->load_inspector($self->{current_workspace});
}

sub load_inspector {
  (my MY $self, my $rootPath) = @_;
  $self->{_inspector}{$rootPath} //= do {
    # The workspace root is the trust boundary the editor named: only an
    # app.psgi/runyatt.psgi inside it (in practice: directly in it) may be
    # executed. Without this, a script planted in any ancestor directory
    # (e.g. /tmp/app.psgi for a workspace under /tmp) would run on
    # initialize.
    $self->Inspector->new(dir => $rootPath, search_boundary => $rootPath);
  };
}


#----------------------------------------

MY->run(\@ARGV) unless caller;

1;
