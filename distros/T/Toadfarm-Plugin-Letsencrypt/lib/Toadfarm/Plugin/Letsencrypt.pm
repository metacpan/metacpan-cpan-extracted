package Toadfarm::Plugin::Letsencrypt;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

use Mojo::Loader 'data_section';
use Mojo::Path;

use File::Spec::Functions qw(abs2rel catdir catfile splitdir);

sub register {
  my ($self, $app, $config) = @_;

  $config->{challenges} ||= '/tmp/letsencrypt/public_html';
  $config->{route} ||= '/.well-known/acme-challenge';

  $app->plugin('HeaderCondition');
  $app->routes->get($config->{route}.'/:challenge')->over(agent => qr{letsencrypt})->to(cb => sub {
    my $c = shift;
    my $challenge = $c->param('challenge');
    $c->app->log->debug("Let's Encrypt Verification: $challenge");
    if ( my $challenges = data_section('main', 'challenges') ) {
      if ( my $found = ((grep { /^$challenge\t/ } split /\n+/, $challenges)[0]) ) {
        if ( my $response = ((split /\s+/, $found)[1]) ) {
          return $c->render(text => $response);
        }
      }
    }
    my $le = catfile $config->{challenges}, $config->{route}, $challenge;
    if ( -e $le ) {
      $c->res->headers->content_type('text/plain');
      return $c->reply->asset(Mojo::Asset::File->new(path => $le));
    }
    $c->reply->not_found;
  });

};

1;
__END__

=encoding utf8

=head1 NAME

Toadfarm::Plugin::Letsencrypt - Toadfarm Plugin to handle letsencrypt.org
domain verifications.

=head1 SYNOPSIS

  # Toadfarm
  plugin 'Letsencrypt' => {...};

=head1 DESCRIPTION

L<Toadfarm::Plugin::Letsencrypt> is a L<Toadfarm> plugin that will generate
routes for providing responses for letsencrypt.org domain verification.

  Config options
  challenges -> /path/to/challenges/root (/tmp/letsencrypt/public_html)
  route -> /path/to/route/called/by/letsencrypt (/.well-known/acme-challenges)

In your Toadfarm script, make sure you mount your apps with a User-Agent
rejection (you should reject Github-Hookshot as well so you can use
Toadfarm::Plugin::Reload):

  mount '/var/mojo/myapp.pl' => {
    "User-Agent" => qr{^(?:(?!GitHub-Hookshot)(?!letsencrypt).)*$},
  };

Download letsencrypt.org
Run it with ./letsencrypt-auto certonly -a manual -d cn1.domain.tld -d ...
For each domain specified, letsenrypt will need to verify ownership and will
provide details for capturing the challenge / response:

  mkdir -p /tmp/letsencrypt/public_html/.well-known/acme-challenge
  cd /tmp/letsencrypt/public_html
  printf "%s" 123 > .well-known/acme-challenge/abc

Simplist thing to do is copy and paste that.  Toadfarm::Plugin::Letsencrypt
will pick up the verification request from letsencrypt and provide the correct
challenge response in order to verify domain ownership.

=head1 METHODS

L<Toadfarm::Plugin::Letsencrypt> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Toadfarm>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
