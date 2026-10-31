package YATT::Lite::Site::Registry; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use mro 'c3';

use parent qw(YATT::Lite::Object);
use YATT::Lite::MFields qw/_sites default_opts/;

require File::Spec;
require File::Basename;

use YATT::Lite::Site;

#========================================
# Per-app-root site cache, for tools which walk over files belonging to
# multiple sites (yatt.genperl, language servers and so on).
#
#   my $reg = YATT::Lite::Site::Registry->new(default_opts => {...});
#   my $site = $reg->site_for($filename);
#
# Files under the same app root (the directory of app.psgi/runyatt.psgi)
# share one site object. Files without a factory script get a default
# site (Site->load_or_default) keyed by their directory.
#========================================

sub site_for {
  my ($self, $fn) = @_;
  defined $fn and $fn ne ''
    or croak "site_for: filename is missing!";
  my $dir = File::Basename::dirname
    (YATT::Lite::Util::normalize_fs_path(File::Spec->rel2abs($fn)));
  require YATT::Lite::Factory;
  my $key = do {
    if (my $script = YATT::Lite::Factory->find_factory_script($dir)) {
      File::Basename::dirname($script);
    } else {
      $dir;
    }
  };
  $self->{_sites}{$key}
    //= YATT::Lite::Site->load_or_default
    (dir => $dir, %{$self->{default_opts} // +{}});
}

sub list_sites {
  my ($self) = @_;
  map {$self->{_sites}{$_}} sort keys %{$self->{_sites} // +{}};
}

1;
