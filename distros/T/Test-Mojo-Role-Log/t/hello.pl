use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';

use Mojolicious::Lite -signatures;

# Route with placeholder
get '/:foo' => sub ($c) {
  if ($c->log->can('trace')){
    $c->log->trace("trace");
  }
  $c->log->debug("debug");
  $c->log->info("info");
  $c->log->warn("warn");
  $c->log->error("error");
  $c->log->fatal("fatal");
  my $foo = $c->param('foo');
  $c->log->debug("got parameter $foo");
  $c->render(text => "Hello from $foo.");
};

# Start the Mojolicious command system
app->start;