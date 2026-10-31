package YATT::Lite::CLI::GenPerl; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro 'c3';

use parent qw(YATT::Lite::CLI);
use YATT::Lite::MFields qw/all/;

use YATT::Lite::Entities qw/*SYS/;

require File::Spec;

#========================================
# yatt.genperl [--all] FILE...
#
# Emits the perl code YATT::Lite generates for each template
# (the jspc-style offline entry to the transpiler).
# --all also emits the generated code of dependencies (base templates,
# widgets in other files); by default only the target (depth == 1).
#
# Note: open_trans/find_product are still VFS-internal API. They are
# shared with the language server (Inspector), so they are candidates
# for a future $site->compile facade - tracked in GH-270.
#========================================

sub main {
  my ($self, @files) = @_;
  my $nerror = 0;
  foreach my $fn (@files) {
    my $abs = YATT::Lite::Util::normalize_fs_path(File::Spec->rel2abs($fn));
    unless (-e $abs) {
      # Note: VFS find_file would lazily create a Template object even
      # for a missing file, so test the filesystem here.
      warn "No such file: $fn\n";
      $nerror++;
      next;
    }
    my $site = $self->site_for($abs);
    local $SYS = $site;
    my ($dh, $name) = $site->resolve_file($abs);
    $dh->fconfigure_encoding(\*STDOUT, \*STDERR);
    my $trans = $dh->open_trans;
    my $tmpl = $trans->find_file($name) or do {
      warn "No such file: $fn\n";
      $nerror++;
      next;
    };
    $trans->find_product
      (perl => $tmpl, sink => sub {
	 my ($info, @script) = @_;
	 print @script if $self->{all} || $info->{depth} == 1;
	 eval {
	   # Generated scripts must be evaluated even when not printed,
	   # so that entity definitions materialize for dependent
	   # templates. Errors in generated code are yatt.lint's job,
	   # not ours - hence the bare eval.
	   YATT::Lite::Util::ckeval(@script);
	 };
       });
  }
  $nerror ? 1 : 0;
}

1;
