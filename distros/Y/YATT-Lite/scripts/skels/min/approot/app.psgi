# -*- perl -*-
use strict;
sub MY () {__PACKAGE__}; # omissible
use FindBin;
use lib "$FindBin::Bin/lib";
use YATT::Lite::WebMVC0::SiteApp -as_base;
use YATT::Lite qw/Entity *CON/;
{
  my $app_root = $FindBin::Bin;
  my $site = MY->new(app_root => $app_root
		     , doc_root => "$app_root/html");
  Entity param => sub { my ($this, $name) = @_; $CON->param($name) };
  return $site if MY->want_object;
  $site->to_app;
}
