# -*- perl -*-
use strict;
use warnings;
use FindBin;

#
# use lib "$FindBin::Bin/lib", "$FindBin::Bin/local/lib/perl5";
#

#----------------------------------------
# Distribution-specific @INC setting.
use File::Basename;
my ($dist_root);
BEGIN {
  $dist_root = dirname(dirname(dirname($FindBin::Bin)));

  require lib; lib->import(do {
    if (-d ((my $dn = "$FindBin::Bin/lib") . "/YATT")) {
      # Prefer YATT submodule
      $dn;
    } elsif (basename($dist_root) eq "YATT") {
      # For distribution tests.
      dirname($dist_root);
    } else {
      ()
    }
  });
}
#----------------------------------------

use YATT::Lite::WebMVC0::SiteApp -as_base;
# use ViewFunctions -as_base, -entns;
# use YATT::Lite::WebMVC0::Partial::Session2 -as_base;

use YATT::Lite qw/Entity *CON/; # For Entity and $CON.

use Plack::Builder;

{
  my $app_root = $FindBin::Bin;

  # To add other option to $SITE, use MFields like this:
  # use YATT::Lite::MFields qw/dbi_dsn auto_deploy /;
  #

  my $SITE = MY->load_factory_for_psgi
    ($0
     , doc_root => "$app_root/public"
     , (-d "$app_root/ytmpl" ? (app_base => '@ytmpl') : ())
     # , app_ns => 'MyYATT'
     # , namespace => ['yatt', 'perl', 'js']
     # , header_charset => 'utf-8'
     # , use_subpath => 1
     # , ext_public => "yatt"
     # , always_refresh_deps => 1
     # , stash_unknown_params_to => ''
     , debug_cgen => $ENV{DEBUG_CGEN}
     , debug_psgi => $ENV{DEBUG_PSGI}
    );

  if (-d (my $staticDir = "$app_root/static")) {
    $SITE->mount_static("/static" => $staticDir);
  }

  {
    #
    # Site wide entity can be defined here.
    #
    #    Entity foo => sub {
    #      my ($this, $arg) = @_;
    #    };
    ;
  }

  my $app = $SITE->wrapped_by(builder {
    enable "SimpleLogger", level => "warn";
    enable 'Lint';
    enable 'StackTrace';

    $SITE->to_app;
  });

  if ($SITE->want_object) {
    # When caller wants $SITE object itself rather than app sub.
    #  (Usually for yatt.lint and other utils)
    return $SITE;

  } else {
    # Otherwise, returns psgi app.
    return $app;
  }
}
