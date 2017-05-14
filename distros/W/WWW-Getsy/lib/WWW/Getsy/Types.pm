package WWW::Getsy::Types;

use MooseX::Types -declare => [qw(
    EnvVar 
    EnvConsumerKey 
    EnvConsumerSecret 
    RequestParams
    RequestMethod 
    )];
use MooseX::Types::Moose qw/Str HashRef/;
use JSON::XS;
use MooseX::Getopt::OptionTypeMap;

subtype EnvVar,
    as Str,
    where { grep {defined && length} $_ };

subtype EnvConsumerKey,
    as EnvVar,
    message { "Please set OAUTH_CONSUMER_KEY" };

subtype EnvConsumerSecret,
    as EnvVar,
    message { "Please set OAUTH_CONSUMER_SECRET" };

subtype RequestParams,
    as HashRef;

MooseX::Getopt::OptionTypeMap->add_option_type_to_map(
    RequestParams , '=s'
    );

coerce RequestParams,
    from Str,
    via {
        decode_json($_);
    };

enum RequestMethod , qw(get put post delete);

coerce RequestMethod,
    from Str,
    via {
        lc $_;
    };

