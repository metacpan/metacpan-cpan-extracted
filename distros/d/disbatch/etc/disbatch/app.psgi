use Limper::Engine::PSGI;
use Disbatch::Web;
use Try::Tiny;

try { Disbatch::Web::init(config_file => '/etc/disbatch/config.json') } catch { warn "Sleeping 30 seconds due to error loading /etc/disbatch/config.json\n"; sleep 30; die $_ };
Disbatch::Web::limp({workers => 10});
