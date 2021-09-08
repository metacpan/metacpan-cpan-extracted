use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use Mojo::File qw(curfile);
use Mojo::Base -strict;
use Mojo::Util qw(dumper);
use Test::Mojo;
use Test::More;

# Start a Mojolicious app named "Celestial"
my $t = Test::Mojo->with_roles('+Log')->new(curfile->sibling('hello.pl'));

if ($t->app->log->can('trace')){
$t->get_ok('/gugus')
    ->log_like(qr{GET "/gugus"})
    ->log_trace_like(qr{GET "/gugus"})
    ->log_debug_unlike(qr{GET "/gugus"})
    ->log_like(qr{200 OK.+s.+/s})
    ->log_unlike(qr{aargh})
    ->log_like(qr{gugus})
    ->log_trace_like(qr{trace})
    ->log_debug_like(qr{debug})
    ->log_info_like(qr{info})
    ->log_warn_like(qr{warn})
    ->log_error_like(qr{error})
    ->log_fatal_like(qr{fatal})
    ->log_trace_unlike(qr{xtrace})
    ->log_debug_unlike(qr{xdebug})
    ->log_info_unlike(qr{xinfo})
    ->log_warn_unlike(qr{xwarn})
    ->log_error_unlike(qr{xerror})
    ->log_fatal_unlike(qr{xfatal});
}
else {
$t->get_ok('/gugus')
    ->log_like(qr{GET "/gugus"})
    ->log_debug_like(qr{GET "/gugus"})
    ->log_info_unlike(qr{GET "/gugus"})
    ->log_debug_like(qr{200 OK.+s.+/s})
    ->log_unlike(qr{aargh})
    ->log_like(qr{gugus})
    ->log_debug_like(qr{debug})
    ->log_info_like(qr{info})
    ->log_warn_like(qr{warn})
    ->log_error_like(qr{error})
    ->log_fatal_like(qr{fatal})
    ->log_debug_unlike(qr{xdebug})
    ->log_info_unlike(qr{xinfo})
    ->log_warn_unlike(qr{xwarn})
    ->log_error_unlike(qr{xerror})
    ->log_fatal_unlike(qr{xfatal});
}
done_testing();