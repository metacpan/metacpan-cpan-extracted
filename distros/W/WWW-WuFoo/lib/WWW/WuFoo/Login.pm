package WWW::WuFoo::Login;
{
  $WWW::WuFoo::Login::VERSION = '0.007';
}

use Moose;

# ABSTRACT: The Login API is designed to allow approved partners access to user’s API keys given an email, password and (optionally) a subdomain. In other words, this API gives you the ability to gather the API key for a user without them having to visit Wufoo. This keeps your user engaged in your process because they don’t have to leave your site.


has '_wufoo'            => (is => 'rw', isa => 'WWW::WuFoo');
has 'integrationkey'    => (is => 'rw', isa => 'Str');
has 'email'             => (is => 'rw', isa => 'Str');
has 'password'          => (is => 'rw', isa => 'Str');
has 'subdomain'         => (is => 'rw', isa => 'Str');




1;
