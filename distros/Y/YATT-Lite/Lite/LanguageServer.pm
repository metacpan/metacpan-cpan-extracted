#!/usr/bin/env perl
package YATT::Lite::LanguageServer;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use File::AddInc;
use Cwd;

my $libDir = File::AddInc->libdir;

use JSON::MaybeXS;

use YATT::Lite::LanguageServer::Generic -as_base
  , [fields => qw/_initialized
                  _client_cap
                  _inspector
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

  if (my $path = $self->uri2localpath($params->{rootUri})) {
    $self->load_inspector($self->{current_workspace} = $path);
  }

  my InitializeResult $res = {};
  $res->{capabilities} = my ServerCapabilities $svcap = {};
  $svcap->{definitionProvider} = JSON()->true;
  $svcap->{implementationProvider} = JSON()->true;
  $svcap->{hoverProvider} = JSON()->true;
  $svcap->{documentSymbolProvider} = JSON()->true;
  $svcap->{textDocumentSync} = my TextDocumentSyncOptions $sopts = +{};
  $sopts->{openClose} = JSON()->true;
  $sopts->{save} = JSON()->true;
  $sopts->{change} = TextDocumentSyncKind__Incremental;
  $res;
}

sub lspcall__textDocument__didOpen {
  (my MY $self, my DidOpenTextDocumentParams $params) = @_;

  my TextDocumentItem $docItem = $params->{textDocument};
  my $fn = $self->uri2localpath($docItem->{uri});

  my LintResult $error
    = $self->inspector->load_string_into_file($fn, $docItem->{text});

  my PublishDiagnosticsParams $notif = {};
  $notif->{uri} = $docItem->{uri};
  $notif->{diagnostics} = [$error ? lexpand($error->{diagnostics}) : ()];

  $self->send_notification('textDocument/publishDiagnostics', $notif);
}

sub lspcall__textDocument__didChange {
  (my MY $self, my DidChangeTextDocumentParams $params) = @_;

  my TextDocumentIdentifier $docId = $params->{textDocument};
  my $fn = $self->uri2localpath($docId->{uri});

  (my $updated, my LintResult $error) = $self->inspector->apply_changes($fn, @{$params->{contentChanges}});

  print STDERR "# updated ", ($error ? "with error " : ""),"as: ", terse_dump($updated), "\n"
    unless $self->{quiet};

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

  print STDERR "# lint result: ", terse_dump($res), "\n"
    unless $self->{quiet};

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

#
# WIP
#
sub lspcall__textDocument__hover {
  (my MY $self, my TextDocumentPositionParams $params) = @_;

  my Hover $result = {};

  my TextDocumentIdentifier $docId = $params->{textDocument};
  my $fn = $self->uri2localpath($docId->{uri});
  my Position $pos = $params->{position};

  my ($symbol, $cursor) = $self->locate_symbol_at_file_position(
      $fn, $pos->{line}, $pos->{character}
    ) or return;

  if (my $contents = $self->inspector->describe_symbol($symbol, $cursor)) {
    $result->{contents} = $contents;
  } else {
    $result->{contents} = "XXX: $symbol->{kind} line=$pos->{line} col=$pos->{character} node="
      . terse_dump($cursor->{array}[$cursor->{index}]);
  }

  $result;
}


*lspcall__textDocument__definition = *lspcall__textDocument__implementation;
*lspcall__textDocument__definition = *lspcall__textDocument__implementation;

#
sub lspcall__textDocument__implementation {
  (my MY $self, my TextDocumentPositionParams $params) = @_;

  my TextDocumentIdentifier $docId = $params->{textDocument};
  my $fn = $self->uri2localpath($docId->{uri});
  my Position $pos = $params->{position};

  my ($symbol, $cursor) = $self->locate_symbol_at_file_position(
      $fn, $pos->{line}, $pos->{character}
    ) or return;

  my Location $found = $self->inspector->lookup_symbol_definition($symbol, $cursor)
    or return;

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
  my $fn = $self->uri2localpath($docId->{uri});

  if (my @result = $self->inspector->list_parts_in($fn)) {
    \@result
  } else {
    undef;
  }
}

#----------------------------------------

sub inspector {
  (my MY $self) = @_;
  $self->load_inspector($self->{current_workspace});
}

sub load_inspector {
  (my MY $self, my $rootPath) = @_;
  $self->{_inspector}{$rootPath} //= do {
    $self->Inspector->new(dir => $rootPath);
  };
}


#----------------------------------------

MY->run(\@ARGV) unless caller;

1;
