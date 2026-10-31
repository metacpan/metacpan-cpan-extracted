package YATT::Lite::CLI::Lint; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro 'c3';

use parent qw(YATT::Lite::CLI);
use YATT::Lite::MFields qw/tap all format _inspectors/;

require File::Spec;
require File::Basename;

#========================================
# yatt.lint [--tap] [--all] [--format=gnu|old] FILE...
#
# The lint logic itself lives in YATT::Lite::Inspector::lint
# (LintResult, non-destructive cf_let) - the same engine the language
# server uses. This class only formats the results (to stderr; exit 1):
#
#   --format=gnu (default)   FILE:LINE: MESSAGE
#   --format=old             TYPE [[file] FILE [line] LINE]
#                             MESSAGE
#
# The old format is what elisp/yatt-lint-any-mode.el parses.
# --all checks every file instead of stopping at the first failure.
# --tap emits TAP (implies --all).
#========================================

sub main {
  my ($self, @files) = @_;
  binmode STDOUT, ':encoding(utf-8)';
  binmode STDERR, ':encoding(utf-8)';

  $self->{all} //= 1 if $self->{tap};
  print "1..".scalar(@files)."\n" if $self->{tap};

  my $nerror = 0;
  my $i = 1;
  foreach my $fn (@files) {
    my $abs = YATT::Lite::Util::normalize_fs_path(File::Spec->rel2abs($fn));
    my $result = $self->inspector_for($abs)->lint($abs);
    if ($result->{is_success}) {
      print "ok $i - $fn\n" if $self->{tap};
    } else {
      $nerror++;
      my $msg = $self->format_result($fn, $result);
      if ($self->{tap}) {
	print "not ok $i - $fn\n";
	print map {"# $_\n"} split /\n/, $msg;
      } else {
	print STDERR $msg, "\n";
      }
      last unless $self->{all};
    }
  } continue { $i++ }

  $nerror ? 1 : 0;
}

sub format_result {
  my ($self, $fn, $result) = @_;
  my $format = $self->{format} // 'gnu';
  my $sub = $self->can("format_result_$format")
    or die "Unknown lint output format: $format (gnu or old)\n";
  $sub->($self, $self->_result_fields($fn, $result));
}

sub _result_fields {
  my ($self, $fn, $result) = @_;
  my $diag = $result->{diagnostics};
  my $file = $result->{file} // $fn;
  my $line = ($diag and $diag->{range}
	      and defined $diag->{range}{start}{line})
    ? $diag->{range}{start}{line} + 1 : '-';
  my $msg = ($diag ? $diag->{message} : undef)
    // $result->{message} // 'unknown lint failure';
  ($file, $line, "$msg", $result->{type} // 'error');
}

# "FILE:LINE: MESSAGE"
sub format_result_gnu {
  my ($self, $file, $line, $msg) = @_;
  sprintf "%s:%s: %s", $file, $line, $msg;
}

# "TYPE [[file] FILE [line] LINE]\n MESSAGE" - the historical
# format_error() shape which elisp/yatt-lint-any-mode.el parses.
sub format_result_old {
  my ($self, $file, $line, $msg, $type) = @_;
  sprintf "%s [[file] %s [line] %s]\n %s", $type, $file, $line, $msg;
}

# One Inspector per app root (files under the same app.psgi share one).
# $fn must be an absolute path.
sub inspector_for {
  my ($self, $fn) = @_;
  require YATT::Lite::Inspector;
  require YATT::Lite::Factory;
  my $dir = File::Basename::dirname($fn);
  my $key = do {
    if (my $script = YATT::Lite::Factory->find_factory_script($dir)) {
      File::Basename::dirname($script);
    } else {
      $dir;
    }
  };
  $self->{_inspectors}{$key}
    //= YATT::Lite::Inspector->new(dir => $dir);
}

1;
