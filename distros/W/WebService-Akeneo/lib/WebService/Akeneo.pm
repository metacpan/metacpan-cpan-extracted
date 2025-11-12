package WebService::Akeneo;
$WebService::Akeneo::VERSION = '0.001';
use v5.38;
use Object::Pad;

# ABSTRACT: Akeneo REST API client built with Mojo::UserAgent and Object::Pad
# VERSION

use WebService::Akeneo::Config;
use WebService::Akeneo::Auth;
use WebService::Akeneo::Transport;
use WebService::Akeneo::Paginator;
use WebService::Akeneo::Resource::Categories;
use WebService::Akeneo::Resource::Products;

use Mojo::UserAgent;

class WebService::Akeneo 0.001;

field $config   :param;
field $ua;
field $auth;
field $t;
field $categories;
field $products;

BUILD {
  $ua         = Mojo::UserAgent->new;
  $auth       = WebService::Akeneo::Auth->new( config => $config, ua => $ua );
  $t          = WebService::Akeneo::Transport->new( config => $config, auth => $auth );
  $categories = WebService::Akeneo::Resource::Categories->new( t => $t );
  $products   = WebService::Akeneo::Resource::Products->new( t => $t );
}

method categories { $categories }
method products   { $products }

method ua ($new_ua = undef) {
  if (defined $new_ua) {
    $t->set_ua($new_ua) if $t->can('set_ua');
    $ua = $new_ua;
  }
  return $ua;
}

method on_request ($cb) { $t->on_request($cb) }
method on_response($cb) { $t->on_response($cb) }

1;

__END__

=pod

=head1 SYNOPSIS

  use v5.38;
  use WebService::Akeneo;
  use WebService::Akeneo::Config;

  my $cfg = WebService::Akeneo::Config->new(
    base_url      => 'https://my-site.com',
    client_id     => $ENV{AKENEO_CLIENT_ID},
    client_secret => $ENV{AKENEO_CLIENT_SECRET},
    username      => $ENV{AKENEO_USER},
    password      => $ENV{AKENEO_PASS},
  );

  my $ak = WebService::Akeneo->new(config => $cfg);

  $ak->on_request(sub ($i){ say "--> $i->{method} $i->{url}" });
  $ak->on_response(sub ($i){ say "<-- $i->{code}" });

  my $res = $ak->categories->upsert_ndjson([
    { code => 'smagic', parent=>'master', labels=>{ es_ES => 'Espada Magica' } },
    { code => 'mixers', parent=>'master', labels=>{ es_ES => 'Batidora' } },
  ]);

=cut
