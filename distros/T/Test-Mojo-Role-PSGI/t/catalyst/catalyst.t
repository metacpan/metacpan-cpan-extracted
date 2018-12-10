use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use File::Spec;
use FindBin;

push @INC, File::Spec->catdir($FindBin::Bin, 'MyApp', 'lib');

plan( skip_all => 'Tests need Catalyst installed to run' ) unless eval { require Catalyst };
plan( skip_all => 'Tests need Catalyst::Action::RenderView installed to run' ) unless eval { require Catalyst::Action::RenderView };

my $t = Test::Mojo->with_roles('+PSGI')->new(File::Spec->catfile($FindBin::Bin, 'MyApp', 'myapp.psgi'));
$t->get_ok("/")->status_is(200);

$t->post_ok("/" => json => {foo => 1} )
  ->json_is('/foo', 1, 'JSON comes back correctly');

done_testing;
