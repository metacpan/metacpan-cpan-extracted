package t::lib::Harness;

use Exporter 'import';
use Test::More import => [qw(plan)];
use WebService::ConstructorIO;

our @EXPORT_OK = qw( constructor_io skip_unless_has_keys );

sub constructor_io {
    return WebService::ConstructorIO->new(
        api_token => api_token(),
        autocomplete_key => autocomplete_key(),
        base_url => "https://devac.cnstrc.com",
    )
}

sub api_token { $ENV{CONSTRUCTOR_IO_API_TOKEN} }
sub autocomplete_key { $ENV{CONSTRUCTOR_IO_AUTOCOMPLETE_KEY} }

sub skip_unless_has_keys {
  plan skip_all => 'env vars CONSTRUCTOR_IO_API_TOKEN and CONSTRUCTOR_IO_AUTOCOMPLETE_KEY are required' unless api_token() and autocomplete_key()
}

1;
