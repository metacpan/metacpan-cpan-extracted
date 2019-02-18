use Test2::V0 -no_srand => 1;
use Test2::Plugin::FFI::Package;
sub require_ok ($);

require_ok 'Alien::libt2t';
require_ok 'Test2::Tools::FFI';
require_ok 'Test2::Plugin::FFI::Package';

done_testing;

sub require_ok ($)
{
  # special case of when I really do want require_ok.
  # I just want a test that checks that the modules
  # will compile okay.  I won't be trying to use them.
  my($mod) = @_;
  my $ctx = context();
  eval qq{ require $mod };
  my $error = $@;
  my $ok = !$error;
  $ctx->ok($ok, "require $mod");
  $ctx->diag("error: $error") if $error ne '';
  $ctx->release;
}
