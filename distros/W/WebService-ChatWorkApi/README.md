NAME

    WebService::ChatWorkApi - An ORM Styled ChatWork API Client

SYNOPSIS

      use utf8;
      use WebService::ChatWorkApi;
      my $connection = WebService::ChatWorkApi->new(
          api_token => $api_token,
      );
      my $dataset = $connection->ds( "me" );
      my $me = $dataset->retrieve;
      my( $room ) = $me->rooms( name => "マイチャット" );
      my @messages = $room->new_messages;
      $room->post_message( "asdf" );

DESCRIPTION

    ChatWork provides REST API to access their web chat service.

    Onece API is provided, there will be perl API module. Then ChatWork API
    exists too. See `SEE ALSO` to what modules are released before this
    module.

    I think these modules is a user agent module, but I want to write API
    client likes Object Relation Mapping.

SUB MODULES

    - WebService::ChatWorkApi::UserAgent -
    WebService::ChatWorkApi::Response - WebService::ChatWorkApi::DataSet -
    WebService::ChatWorkApi::Data

SEE ALSO

    - API Document <http://developer.chatwork.com/ja/> -
    WebService::Chatwork
    <https://github.com/naoto43/perl-webservice-chatwork> -
    WWW::Chatwork::API <https://github.com/takaya1992/p5-WWW-Chatwork-API>

