package YATT::Lite::CLI; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use mro 'c3';

use parent qw(YATT::Lite::Object);
use YATT::Lite::MFields qw/_registry site_opts/;

use YATT::Lite::Util::CmdLine qw(parse_opts parse_params);

#========================================
# Base class for yatt.* command line tools.
#
# This layer owns argv parsing, policy defaults and output formatting
# ONLY. Anything a language server would also need belongs to
# YATT::Lite::Site, not here.
#
# Policy guarantee: this layer never installs $SIG{__DIE__} or
# $SIG{__WARN__}. Combined with Site->render_file's default raw-die
# policy, `perl -d scripts/yatt.*` keeps its full usefulness.
#========================================

# Entry point for scripts:
#
#   exit(YATT::Lite::CLI::Render->run(\@ARGV));
#
# Leading --opt=value pairs are configured into the instance,
# the rest goes to main(). Returns the exit code.
sub run {
  my ($pack, $list) = @_;
  my $self = $pack->new($pack->parse_opts($list));
  $self->main(@$list);
}

sub main {
  my ($self) = @_;
  croak ref($self) . " must override ->main()";
}

#========================================
# Per-app-root site cache. Tools which take files from multiple sites
# (like yatt.genperl or a language server) share one registry.
#========================================

sub registry {
  my ($self) = @_;
  $self->{_registry} //= do {
    require YATT::Lite::Site::Registry;
    YATT::Lite::Site::Registry->new
      ($self->{site_opts} ? (default_opts => $self->{site_opts}) : ());
  };
}

sub site_for {
  my ($self, $fn) = @_;
  $self->registry->site_for($fn);
}

1;
