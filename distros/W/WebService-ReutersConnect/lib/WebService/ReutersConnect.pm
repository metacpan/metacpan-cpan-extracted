package WebService::ReutersConnect;
use Moose;
extends qw/Exporter/;

use constant REUTERS_DEMOUSER => 'demo.user';
use constant REUTERS_DEMOPASSWORD => 'vYkLo4Lv';
our @EXPORT_OK = qw/REUTERS_DEMOPASSWORD REUTERS_DEMOUSER/;
our %EXPORT_TAGS = ( demo => [ qw/REUTERS_DEMOUSER REUTERS_DEMOPASSWORD/ ] );

use WebService::ReutersConnect::APIResponse;
use WebService::ReutersConnect::Channel;
use WebService::ReutersConnect::Category;
use WebService::ReutersConnect::Item;
use WebService::ReutersConnect::XMLDocument;
use WebService::ReutersConnect::ResultSet;

use WebService::ReutersConnect::DB;



BEGIN{
  eval{ require File::Share; File::Share->import('dist_file'); };
  if( $@ ){
    require File::ShareDir;
    File::ShareDir->import('dist_file');
  }
};

use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;
use Log::Log4perl qw/:easy/;

use DateTime;
use DateTime::Format::ISO8601;

unless( Log::Log4perl->initialized() ){
  Log::Log4perl->easy_init($WARN);
}

my $LOGGER = Log::Log4perl->get_logger();

our $VERSION = '0.06';

## Reuters stuff
has 'login_entry_point' => ( is => 'ro' , isa => 'Str' , default => 'https://commerce.reuters.com/rmd/rest/xml/', required => 1 );
has 'entry_point' => ( is => 'ro' , isa => 'Str' , default => 'http://rmb.reuters.com/rmd/rest/xml/', required => 1 );
has 'username' => ( is => 'rw', isa => 'Str' );
has 'password' => ( is => 'rw', isa => 'Str' );
has 'authToken' => ( is => 'rw', isa => 'Maybe[Str]' , lazy_build => 1);

has 'categories_idx' => ( is => 'ro', isa => 'HashRef[WebService::ReutersConnect::Category]' , default => sub{ {}; }, required => 1);

## General stuff
has 'user_agent' => ( is => 'rw' , isa => 'LWP::UserAgent', lazy_build => 1);
has 'debug' => ( is => 'rw' , isa => 'Bool' , default => 0, required => 1);
has 'refresh_token' => ( is => 'ro', isa => 'Bool', default => 0 , required => 1);
has 'after_refresh_token' => ( is => 'ro', isa => 'CodeRef', default => sub{ sub{}; }, required => 1);

has 'date_created' => ( is => 'ro' , isa => 'DateTime' , default => sub{ return DateTime->now();} , required => 1);

## Querying stuff
has 'default_limit' => ( is => 'rw' , isa => 'Int' , default => 10 , required => 1 );

## Internal DB stuff
has 'db_file' => ( is => 'ro' , isa => 'Str' , lazy_build => 1 , required => 1 );
has 'schema' => ( is => 'ro', isa => 'DBIx::Class::Schema' , lazy_build => 1 , required => 1);

sub _build_db_file{
  my ($self) = @_;
  my $concepts_file = dist_file('WebService-ReutersConnect' , 'concepts.db');
  ## my $concepts_file = dist_file('WebService-ReutersConnect' , 'concepts.db');
  return $concepts_file;
}

sub _build_schema{
  my ($self) = @_;
  my $concepts_file = $self->db_file();
  $LOGGER->warn("Will use SQLite DB $concepts_file");
  my $schema = WebService::ReutersConnect::DB->connect('dbi:SQLite:'.$concepts_file , "", "" , { AutoCommit => 1,
                                                                                                 sqlite_unicode => 1,
                                                                                               });
  $schema->storage->dbh()->do("PRAGMA foreign_keys = ON");
  return $schema;
}

sub _build_user_agent{
  my ($self) = @_;
  return LWP::UserAgent->new();
}

sub _build_authToken{
  my ($self) = @_;

  unless( $self->username() && $self->password() ){
    ## Try to scrape some from demo login page.
    $LOGGER->info("No username/password given. Trying to scrape the demo ones");
    unless( $self->scrape_demo_credentials() ){
      confess("No username AND password could be found. Cannot request authentication token");
    }
  }

  my $response = $self->_query('login', { username => $self->username(),
                                          password => $self->password() },
                               { entry_point => $self->login_entry_point() }
                              );

  if( $response->is_reuters_success() ){
    my $token =  $response->xml_document()->documentElement->findvalue('/authToken');
    ## Call the after refresh trigger.
    $self->after_refresh_token()->($token);
    return $token;
  }

  $LOGGER->error("Failed to get authentication token. Reuters STATUS CODE ".$response->reuters_status());
  $LOGGER->info($response->reuters_errors_string());
  return;
}

sub scrape_demo_credentials{
  my ($self) = @_;
  my $agent = $self->user_agent();

  my $demo_page = 'http://reutersconnect.com/docs/Demo_Login_Page';
  my $req = HTTP::Request->new( GET =>  $demo_page );
  my $resp = $agent->request($req);

  unless( $resp->is_success ){
    $LOGGER->error("Cannot scape $demo_page:".$resp->status_line());
    return 0;
  }

  my $content = $resp->content();
  my ($username, $password) = ( $content =~ m|<strong>Username: (\S+?)<br /><span> </span>Password: &nbsp;(\S+?)</strong>| );

  unless( $username && $password ){
    $LOGGER->error("Cannot find Username and password in content");
    return 0;
  }

  $LOGGER->info("Found '$username/$password' credentials");

  $self->username($username);
  $self->password($password);
  return 1;
}


sub fetch_channels{
  my ($self, $opts) = @_;
  $opts //= {};

  my %http_params = %$opts;

  my $response = $self->_main_query('channels' , \%http_params);

  ## Find channel nodes and build channel objects.
  my @channels = ();
  my @channel_nodes = $response->xml_document()->documentElement()->findnodes('/availableChannels/channelInformation');
  foreach my $channel_node ( @channel_nodes ){
    push @channels , WebService::ReutersConnect::Channel->from_node($self, $channel_node);
  }
  return @channels;
}


sub channels{ goto &fetch_channels; }

sub fetch_items{
  my ($self, $channel_id_or_obj, $opts) = @_;
  $opts //= {};

  unless( $channel_id_or_obj ){
    confess("You MUST specify a channel (alias) to fetch news items");
  }

  my $channel = $self->_expand_channel( $channel_id_or_obj );

  my %http_params = ( channel => $channel->alias() );

  if( $opts->{'date_from'} ){
    my $date_param = $self->_date_to_reuters($self->_parse_date($opts->{'date_from'}));
    if( $opts->{'date_to'} ){
      $date_param .= '-'.$self->_date_to_reuters($self->_parse_date($opts->{'date_to'}));
    }
    $http_params{dateRange} = $date_param;
  }

  if( my $media_types = $opts->{media_types} ){
    $http_params{mediaType} = $media_types;
  }

  $http_params{limit} = $opts->{limit} // $self->default_limit();

  my $response = $self->_main_query('items' , \%http_params);

  my @items = ();
  my @item_nodes = $response->xml_document()->documentElement()->findnodes('/results/result');
  foreach my $item_node ( @item_nodes ){
    push @items , WebService::ReutersConnect::Item->from_node($item_node,$self, $channel);
  }
  return @items;
}

sub items{ goto &fetch_items; }

sub fetch_packages{
  my ($self, $channel_id_or_obj,  $opts) = @_;
  $opts //= {};

  unless( $channel_id_or_obj ){
    confess("Please give a channel");
  }

  my $channel = $self->_expand_channel( $channel_id_or_obj );
  my %http_params = ( channel => $channel->alias() );

  $http_params{limit} = $opts->{limit} // $self->default_limit();

  if( $opts->{'date_from'} ){
    my $date_param = $self->_date_to_reuters($self->_parse_date($opts->{'date_from'}));
    if( $opts->{'date_to'} ){
      $date_param .= '-'.$self->_date_to_reuters($self->_parse_date($opts->{'date_to'}));
    }
    $http_params{dateRange} = $date_param;
  }

  $http_params{useSNEP} = $opts->{use_snep} ? 'true'  : 'false' ;

  my $response = $self->_main_query('packages' , \%http_params);

  my @items = ();
  my @item_nodes = $response->xml_document()->documentElement()->findnodes('/results/result');
  foreach my $item_node ( @item_nodes ){
    $LOGGER->debug("Building item from ".$item_node->toString(1)) if $self->debug();
    push @items , WebService::ReutersConnect::Item->from_node($item_node,$self, $channel);
  }
  return @items;
}

sub olr{ goto &fetch_olr; }
sub fetch_olr{
  my ($self, $opts) = @_;
  $opts //= {};

  my %http_params = ();
  ## No limit option in the doc
  ## $http_params{limit} = $opts->{limit} // $self->default_limit();

  my $response = $self->_main_query('olr' , \%http_params);
  $LOGGER->debug(" ANALYSING ".$response->xml_document()->toString(1)) if $self->debug();
  my @items = ();
  my @item_nodes = $response->xml_document()->documentElement()->findnodes('/results/result');
  foreach my $item_node ( @item_nodes ){
    $LOGGER->debug("Building item from ".$item_node->toString(1)) if $self->debug();
    push @items , WebService::ReutersConnect::Item->from_node($item_node,$self);
  }
  return @items;
}

sub packages{ goto &fetch_packages; }

sub fetch_package{
  my ($self, $channel_id_or_obj , $items , $opts ) = @_;
  $opts //= {};

  unless( $channel_id_or_obj ){
    confess("Please give a channel");
  }
  unless( $items && ( ref($items) // '' ) eq 'ARRAY' ){
    confess("Missing items ArrayRef");
  }
  my $channel = $self->_expand_channel( $channel_id_or_obj );
  my %http_params = ( channel => $channel->alias() );

  $http_params{id} = [ map { $self->_flatten_item($_); }@$items ];
  $http_params{completeSentences} = 'true';

  my $response = $self->_main_query('package', \%http_params );
  my @items = ();

  my $doc_elem = $response->xml_document()->documentElement();
  my @item_nodes = $doc_elem->findnodes('/results/result');
  foreach my $item_node ( @item_nodes ){
    push @items , WebService::ReutersConnect::Item->from_node($item_node, $self, $channel);
  }

  return @items;

}

sub fetch_search{
  my ($self, $opts) = @_;
  $opts //= {};

  my %http_params = ();

  if( $opts->{'date_from'} ){
    my $date_param = $self->_date_to_reuters($self->_parse_date($opts->{'date_from'}));
    if( $opts->{'date_to'} ){
      $date_param .= '-'.$self->_date_to_reuters($self->_parse_date($opts->{'date_to'}));
    }
    $http_params{dateRange} = $date_param;
  }

  $http_params{limit} = $opts->{limit} // $self->default_limit();
  $http_params{sort} = $opts->{sort} if $opts->{sort};

  if( my $channels = $opts->{channels} ){
    $http_params{channel} = [ map { $self->_flatten_channel($_) } @$channels ];
  }

  if( my $categories = $opts->{categories} ){
    $http_params{channelCategory} = [ map { $self->_flatten_category($_) } @$categories ];
  }

  if( my $q = $opts->{q} ){
    $http_params{q} = $q;
  }

  if( my $media_types = $opts->{media_types} ){
    $http_params{mediaType} = $media_types;
  }

  my $response = $self->_main_query('search', \%http_params );
  my @items = ();

  my $doc_elem = $response->xml_document()->documentElement();
  my @item_nodes = $doc_elem->findnodes('/results/result');
  foreach my $item_node ( @item_nodes ){
    push @items , WebService::ReutersConnect::Item->from_node($item_node, $self);
  }

  ## If wantarray, dont bother building a result set.
  if( wantarray ){
    return @items;
  }

  ## If not, build one.
  return WebService::ReutersConnect::ResultSet
    ->new( { start => $doc_elem->findvalue('/results/start'),
             num_found => $doc_elem->findvalue('/results/numFound'),
             size => $doc_elem->findvalue('/results/size'),
             items => \@items });
}

sub search{ goto &fetch_search; }

sub fetch_item_xdoc{
  my ($self, $opts) = @_;
  $opts //= {};

  my %http_params = ();

  if( $opts->{item} ){
    my $item = $opts->{'item'};
    %http_params = ( id => $item->guid() , channel => $item->channel()->alias() );
  }elsif( $opts->{'guid'} && $opts->{'channel'} ){
    %http_params = ( id => $opts->{'guid'} , channel => $self->_expand_channel($opts->{'channel'})->alias() );
  }elsif( $opts->{'item_id'} ){
    %http_params = ( id => $opts->{item_id} );
  }else{
    confess("Missing item OR ( guid + channel ) OR item_id. See documentation");
  }

  if( $opts->{'company_markup'} ){
    $http_params{'entityMarkup'} = 'newsml';
  }

  my $response = $self->_main_query('item' , \%http_params );
  return WebService::ReutersConnect::XMLDocument->new({ xml_document => $response->xml_document(),
                                                        reuters => $self });
}

sub item{
  goto &fetch_item_xdoc;
}

## Find the concept by ID
sub _find_concept{
  my ($self , $id ) = @_;
  if( my $direct = $self->schema->resultset('Concept')->find($id) ){
    return $direct;
  }

  if( my $aliased = $self->schema->resultset('ConceptAlias')->find( { alias_id => $id } ) ){
    return $aliased->concept();
  }
  return undef;
}

sub _expand_channel{
  my ($self, $channel_alias) = @_;
  if( ref($channel_alias) ){ return $channel_alias; }
  my ($channel) = $self->fetch_channels({ channel => [ $channel_alias ] });
  unless( $channel ){
    confess("Cannot find channel for channel alias ".$channel_alias );
  }
  return $channel;
}


sub _main_query{
  my ($self, $method, $params, $opts ) = @_;
  $opts //= {};

  my %ext_params = %{$params // {}};

  $ext_params{token} = $self->authToken();

  my $response = $self->_query($method, \%ext_params);
  if($self->refresh_token && !$response->is_reuters_success()
     && ( $response->has_reuters_error(3003) ||
          $response->has_reuters_error(3002)
        )
    ){
    ## Attempt refreshing the token
    $LOGGER->warn("Authentication token was invalid. ".$response->reuters_errors_string()
                  ." Attempting another authentication");
    $self->authToken($self->_build_authToken());
    unless( $self->authToken() ){
      confess("Authentication failed again. Giving up");
    }
    ## Ok do the query again with the new token
    $ext_params{token} = $self->authToken();
    $response = $self->_query($method,\%ext_params);
  }

  if( ! $response->is_reuters_success() ){
    confess("Query failed: ".$response->reuters_errors_string());
  }

  return $response;
}

sub _query{
  my ($self, $method , $params, $opts ) = @_;

  $params //= {};
  $opts //= {};

  ## Flatten http_params.
  my @http_params = ();
  while( my ($p, $v) = each(%$params) ){
    unless( ref($v) ){
      push @http_params , { p => $p , v => $v };
      next;
    }

    foreach my $vv ( @$v ){
      push @http_params , { p => $p , v => $vv };
    }
  }

  my $req = HTTP::Request->new( GET => ( $opts->{entry_point} // $self->entry_point()).$method.'?'.
                                join('&',
                                     map {
                                       $_->{p}.'='.uri_escape_utf8($_->{v});
                                     } @http_params
                                    )
                              );

  $LOGGER->info("$req:".$req->as_string()) if $self->debug();
  my $resp = $self->user_agent->request($req);

  $LOGGER->info("$resp:".$resp->as_string()) if $self->debug();

  unless( $resp->is_success() ){
    $LOGGER->error("HTTP Request ".$req->as_string()." was unsuccessful: ".$resp->status_line()."\n");
  }

  my $api_response = WebService::ReutersConnect::APIResponse->new({ http_response => $resp });

  unless( $api_response->is_reuters_success() ){
    $LOGGER->error("REUTER Response is NOT a success: (".$api_response->reuters_status().") Messages: ".$api_response->reuters_errors_string());
  }
  return $api_response;
}

sub _vivify_category{
  my ($self, $opts) = @_;

  my $category = $self->categories_idx()->{$opts->{id}};
  unless( $category ){
    $category = $self->categories_idx()->{$opts->{id}} =
      WebService::ReutersConnect::Category->new({ id => $opts->{id},
                                                  description => $opts->{description} });
  }
  return $category;
}

## Turns a DateTime in a Reuter string.
sub _date_to_reuters{
  my ($self, $datetime) = @_;
  ## Fix the datetime in UTC.
  my $dt = $datetime->clone()->set_time_zone('UTC');
  return $dt->ymd('.');
}

## Parse an ISO8601 date time.
sub _parse_date{
  my ($self, $date_str) = @_;
  if( ref($date_str) ){ return $date_str ;} ## Date is already a DateTime.
  return DateTime::Format::ISO8601->parse_datetime($date_str)->set_time_zone('UTC');
}

sub _flatten_category{
  my ($self, $category) = @_;
  unless( ref($category) ){ return $category; }
  return $category->id();
}

sub _flatten_channel{
  my ($self , $channel) = @_;
  unless( ref($channel) ){ return $channel ;}
  return $channel->alias();
}

sub _flatten_item{
  my ($self, $item) = @_;
  unless( ref($item) ){ return $item ;}
  return $item->id();
}

__PACKAGE__->meta->make_immutable();

1; # End of WebService::ReutersConnect

__END__

=head1 NAME

WebService::ReutersConnect - Use the ReutersConnect Live News API

=head1 VERSION

Version 0.05

=head1 INSTALLATION

=head2 Debian based

This module depends only on debian distributed packages. If you're using a debian based system, do

 $ sudo apt-get install perl-modules libtest-fatal-perl perl-base libdbd-sqlite3-perl libdbix-class-perl libdatetime-perl \
 libdatetime-format-iso8601-perl libdevel-repl-perl libfile-sharedir-perl libwww-perl liblog-log4perl-perl libmoose-perl \
 libterm-readkey-perl liburi-perl libxml-libxml-perl

 $ sudo cpan -i WebService::ReutersConnect ## or anything you like.

=head2 Other OSs

Use your favorite Perl package installation method.

 $ sudo cpan -i WebService::ReutersConnect ## Should do the job on *NIX systems

=head1 SYNOPSIS

This module allows access to Reuters Connect APIs as described here:

L<http://reutersconnect.com/>

It is based on the REST APIs.

You WILL have to contact reuters to get yourself some API credentials if
you want to use this module. This is out of scope of this distribution.
However, some demo credentials are supplied by this module for your convenience.

By the way, those demo credential change from time to time, so have a look at
L<http://reutersconnect.com/docs/Demo_Login_Page> if you get authentication errors.

For your convenience, this module will try scraping the demo credentials from this page
if you don't feel like looking at it yourself :)

=head2 Shell

This module provides a 'reutersconnect' shell so you can interactively play with
the API.

Example:

 $ reutersconnect
 2013/03/20 16:45:05 Will try to use the demo account. Use '/usr/local/bin/reutersconnect -u <username>' to login as a specific user
 2013/03/20 16:45:05 No username/password given. Trying to scrape the demo ones
 2013/03/20 16:45:07 Found 'demo.user/vYkLo4Lv' credentials
 2013/03/20 16:45:08 Granted access to 6 channels
 2013/03/20 16:45:08 Starting shell. ReutersConnect object is '$rc'
                                                                                                                                                                            demo.user@reutersconnect.com> map{ $_->alias().' '.$_->description()."\n" } $rc->channels()
 FES376 US Online Report Top News
 QTZ240 NVO
 STK567 Reuters World Service
 mkc191 Unique-Product-For-User-26440
 txb889 Unique-Product-For-Account-26439
 xHO143 Italy Picture Service

 demo.user@reutersconnect.com> [CTRL-D] to quit

See the rest of this module doc and L<WebService::ReutersConnect::Channel> and L<WebService::ReutersConnect::Item>
for a detailed API description.

=head2 Perl

Example:

   use WebService::ReutersConnect qw/:demo/;

   my $reuters = WebService::ReutersConnect->new({ username => REUTERS_DEMOUSER,
                                                   password => REUTERS_DEMOPASSWORD });

   my @channels = $reuters->channels();
   my @items    = $reuters->items( $channels[0] );
   my $full_xml_doc = $reuters->fetch_item_xdoc({ item => $items[0] });

Additionally, a very basic demo page scraping mechanism is provided, so you
can build an API object without any credential at all if you feel lucky:

   my $reuters = WebService::ReutersConnect->new();
   my @channels = $reuters->channels();


=head1 EXAMPLES

Here are some example of usage to get you started quickly:

=head2 Fetch the last news about britain from all your channels

  my $res = $reuters->search({ q => 'headline:britain' ,
                               sort => 'date'
                             });
  say("Size: ".$res->size());
  say("Num Found: ".$res->num_found());
  say("Start: ".$res->start());
  foreach my $item ( @{ $res->items() } ){
    say($item->headline());
  }

=head2 Fetch the last 5 pictures accross all your channels

  my @items = $reuters->search({ limit => 5 , media_types => [ 'P' ] });
  foreach my $item ( @items ){
    print "\n".$item->date_created().' : '.$item->headline()."\n\n";
    print " CLICK: ".$item->preview_url()."\n\n";
  }

=head2 Get the freshest version of the rich NewsML-G2 document about a news item:

  my $xdoc = $reuters->item({  guid => $item->guid() , channel => $item->channel_alias() });
  say $xdoc->asString(); ## That will help you :)

  my ($body_node) = $xc->findnodes('//x:html/x:body'); ## Find the HTML content (in case of article).
  say $body_node->toString(1); ## Print the whole html.

  ## You can also print only the content of the body:
  my @body_parts = $xdoc->get_html_body();
  map { say $_->toString(1) } @body_parts;

  ## Find the subjects:
  my @subjects = $xdoc->get_subjects();
  foreach my $subject ( @subjects ){
    say "This is about: ".$subject->name_main();
  }

=head1 AUTHENTICATION

If you supply a ReutersConnect username and password, this module will fetch
an authentication token from the service and use it in all subsequent requests.

The basic usage involves giving some classical username and password as demonstrated
in the synopsys section.

You can access the authentication token: $this->authToken() for diagnostic and external storage.

You can also build an instance of this module using an authentication token that you
stored somewhere:

  my $reuters = WebService::ReutersConnect->new( { authToken => $authToken } );

Beware that ReutersConnect authentication tokens are only valid for 24 hours.
It is advised to effectively renew the authentication token more often to avoid
any expiration issue. For instance every 12 hours.

This module does NOT contain any mecanism to renew authentication tokens at regular
intervals. If you keep long standing instances of this module, it's your responsability
to renew them regularly enough.

However, for very simple cases, where there's no concurrent access to the token storage,
or when you have only one longstanding instance, the options refresh_token and
after_refresh_token can be useful.


=head2 DEMO AUTHENTICATION

Reuters provides a demo account so you can try out this API without holding an account
with them. The demo credentials live on this page http://reutersconnect.com/docs/Demo_Login_Page

They do change every month, but this module provides a very basic method to scrape them if no
username/password is given in the constructor. See SYNOPSIS section.

=head1 LOGGING & DEBUGGING

This module uses L<Log::Log4perl> and is automatically initialized to the ERROR level.
Feel free to initialize L<Log::Log4perl> to your taste in your application.

Additionally, there's is the debug option that will output very verbose
(HTTP traffic) at the INFO level.

=head1 ATTRIBUTES

Most attributes are read only and have a default value.
Set them at construction time if necessary.

=head2 entry_point

Get/Set the ReutersConnect entry URL. Default should work.

=head2 login_entry_point

Get/Set the ReutersConnect login entry URL. Default should work.

=head2 username

ReutersConnect API username.

=head2 password

ReutersConnect API password.

head2 authToken

ReutersConnect authentication token. If not set, this will try to get a new one using the username/password

=head2 refresh_token

Option. When true, the module will attempt ONCE fetching a fresh authentication token.
from ReutersConnect in case the token held is invalid or expired.

Of course, turning that on only makes sense if you give the username and password at instanciation time.

If you want to be notified of the new token in your client code, you can register a callback:

=head2 after_refresh_token

This is a callback called after this module has fetched a new authentication token from ReutersConnect.
It's normally used in combination with refresh_token.

Usage:

   my $reuters = WebService::ReutersConnect->new({ username => ...,
                                                   password => ....,
                                                   on_refresh_token => sub{
                                                      my ($new_token) = @_;
                                                      ## Store new token somewhere
                                                   }
                                                 });

=head2 user_agent

A L<LWP::UserAgent>. There's a default instance but feel free to replace it with your application one.

=head2 debug

Swicthes on/off extra debugging (Specially HTTP Requests and Responses).

=head2 date_created

L<DateTime> At which this instance was created.

=head1 METHODS

=head2 scrape_demo_credentials

Quick and very dirty method to scrape demo credentials from http://reutersconnect.com/docs/Demo_Login_Page
This is used automatically when no credential at all are provided in the constructor. You shouldn't have
to use that yourself. Returns 1 for success, 0 for failure.

Usage:

  unless( $this->scrape_demo_credentials() ){
     ## Woopsy
  }

=head2 channels

Alias for fetch_channels

=head2 items

Alias for fetch_items

=head2 packages

Alias for fetch_packages

=head2 search

Alias for fetch_search

=head2 olr

Alias for fetch_olr

=head2 item

Alias for fetch_item_xdoc.

=head2 fetch_channels

Fetch the L<WebService::ReutersConnect::Channel>'s according to the given options (or not).

Usage:

  my @all_channels = $this->fetch_channels();
  my ( $channel ) = $this->fetch_channels({ channel => [ '56HD' ] });

  ## Filter on channel alias(s)
  my @specific_channels = $this->fetch_channels({ channel => [ '567', '7654' ,... ] });

  ## Filter on channel Category(s) ID(s)
  my @channels = $this->fetch_channels({ channelCategory => [ 'JDJD' , 'JDJD' ] });


=head2 fetch_items

Fetch L<WebService::ReutersConnect::Item> news item from Reuters Connect. This is the core method.
You MUST specify ONE channel (Get the list using the fetch_channels method). You can give
indiferently a channel or a channel alias.

This method returns REAL TIME items.

Usage:

   my @items = $this->fetch_items($channel->alias, { %options  });

Options:

  media_types: An Array of media types to compose from the following options: T (text), P (pictures), V (video), G (graphics) and C (composite)

  date_from: YYYY-MM-DD or DateTime object. Defaults to now - 24h. This is INCLUSIVE
  date_to:   idem but cannot be specified without date_from. Defaults to now. Not that this date is NOT INCLUSIVE

  limit: Number of items to fetch. Default to $this->default_limit()
  sort:  Sort by 'date' (newest first) or by 'score' (more relevant first).


=head2 fetch_search

Search for L<WebService::ReutersConnect::Item>'s in all Reuters news (from the channels you have access to).

Items found through this method can suffer from a slight delay compared to the live 'items' method.

Options:

 q: Free Text Style query string. See search method in http://reutersconnect.com/files/Reuters_Connect_Web_Services_Developer_Guide.pdf
    for an extended specification

 channels : An Array Ref of restriction Channels (Or channel Aliases)
 categories : An Array Ref of restriction Categories (Or catecogy IDs)
 media_types: An Array of media types to compose from the following options: T (text), P (pictures), V (video), G (graphics) and C (composite)

 limit: Number of items to fetch. Default to $this->default_limit()
 sort:  Sort by 'date' (newest first) or by 'score' (more relevant first).

Usage:

  my @items = $this->fetch_search();

  ## Only videos
  my @items = $this->fetch_search({ media_types => [ 'V' ] });

  ## Only pictures or videos about Britney Spears
  my @items = $this->fetch_search({ q => 'britney spears' , media_types => [ 'P' , 'V'  ] });


  ## Additionally, if you want a L<WebService::ReutersConnect::ResultSet>, use the scalar version of this method:
  my $res = $this->fetch_search({ media_types => [ 'V' ] });
  print $res->num_found().' results in total';
  print $res->size().' results effectively returned (because of limit)';
  print $res->start().' offset in the total result space';
  my @items = @{$res->items()};

=head2 fetch_olr

Fetches OnLine Reports (SNI, NEPs, SNEPs, .. ) from the Channels you have access to,
You can optionally filter by channel(s).

Options:

  channels: An array ref of channel restriction.

=head2 fetch_packages

Fetches the edited NEPs (News Event Package) from a specific Reuters Channel.
NEPs comes as L<WebService::ReutersConnect::Item>'s with added 'main links' sub items and 'supplemental links' sub items.
You can view them as editorially put together news items.

Options:

   use_snep: Use editor Super NEPs. Defaults to false (just returns the latest ones).

   limit: Fetch a limited number of NEPs, defaults to $this->default_limit()


Usage:

 my @items = $reuters->fetch_packages( $channel );
 my @items = $reuters->fetch_packages( $channel->alias() , { options .. } );

=head2 fetch_package

Fetches a richer version of some specific NEPs (News Event Package). Despite the
name of this method, you can actually specify multiple NEPs:

Usage:

  my @nep_items = $this->fetch_package($channel->alias(), [ $item1->id() , $item2->id() ] );


=head2 fetch_item_xdoc

Fetches one L<WebService::ReutersConnect::XMLDocument> from Reuters, given the Item or the item ID.

This document is a NewsMLG2 document as specified here: http://reutersconnect.com/files/NewsML-G2_Quick_Reference_Guide.pdf

You can view a NewMLG2 document as a 'full view' of a simple WebService::ReutersConnect::Item (Simple News Item).

Implementing a full NewsMSG2 Object from such a document is out of the scope of this module.
HOWEVER, for your convenience and enjoyement, the returned object comes with an already
instantiated XML::LibXML::XPathContext object on which you can query things of interest.

You are also strongly encouraged to read the 'item' method section of
http://reutersconnect.com/files/Reuters_Connect_Web_Services_Developer_Guide.pdf.

Options:

  item: An item

   OR

  guid: GUI of an ITEM
  channel: Combined with guid to get the freshest version of the news item.

   OR

  item_id: The the specific version of the Item by item ID.

   ------

  company_markup: 0 or 1 (default 0). If set, will markup the content with company name. See Reuters documentation.

Usage:

  my $xml_doc = $this->fetch_item_xdoc({  guid => $item->guid() , channel => $item->channel()->alias() });
  my $xml_doc = $this->fetch_item_xdoc({ item_id => $item->id() });
  my $xml_doc  = $this->fetch_item_xdoc( { item => $item_object } );

  print $xml_doc->toString(); ## Print the whole document.
  print $xml_doc->xml_xpath->findvalue('//rcx:description'); ## The default namespace for xpath is 'rcx'
  print $xml_doc->xml_xpath->findvalue('//rcx:headline');
  my ($body_node) = $xc->findnodes('//x:html/x:body'); ## Find the HTML content (in case of article).
  print $body_node->toString(); ## Print the whole html.

=head2 REUTERS_DEMOUSER

Returns the username for the demo account. This is exportable:

  use WebService::ReutersConnect qw/:demo/;
  print REUTERS_DEMOUSER;

=head2 REUTERS_DEMOPASSWORD

Returns the password for the demo account. This is exportable:

  use WebService::ReutersConnect qw/:demo/;
  print REUTERS_DEMOPASSWORD;

=head1 AUTHOR

Jerome Eteve, C<< <jerome at eteve.net> >>

=head1 KNOWN ISSUES

This module is known to be correct, but not to be complete.

Some ReutersConnect method options and some objects properties might not be implemented.

Also, it lacks the preference methods and the OpenCalais method of the ReutersConnect API (for now).

Please file any feature you might be missing in the issue tracking system. See BUGS section.

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-reutersconnect at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-ReutersConnect>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::ReutersConnect


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-ReutersConnect>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-ReutersConnect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-ReutersConnect>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-ReutersConnect/>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to C. Gevrey from Reuters for his guidance and inspiration
in writing this module.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jerome Eteve.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
