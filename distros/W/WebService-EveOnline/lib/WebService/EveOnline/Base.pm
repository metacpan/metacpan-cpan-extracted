package WebService::EveOnline::Base;

our $VERSION = "0.62";

use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;
use Data::Dumper;

use WebService::EveOnline::Cache;

use WebService::EveOnline::API::Character;
use WebService::EveOnline::API::Corporation;
use WebService::EveOnline::API::Skills;
use WebService::EveOnline::API::Transactions;
use WebService::EveOnline::API::Journal;
use WebService::EveOnline::API::Account;
use WebService::EveOnline::API::Map;

# U.G.L.Y. You ain't got no alibi (this is where we set up the API mappings, sort out the internal symbol conversion and set max cache times)
# max_cache overrides the cache time set in the default EVE webservice response XML (e.g. shorter for wallet, longer for bloodline which
# probably won't update every hour...)

our $API_MAP = {
    # Character
    skills            => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ], max_cache => 900     },
    balance           => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ], max_cache => 60      },
    race              => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ], max_cache => 604800  },
    bloodline         => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ], max_cache => 604800  },
    attributes        => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ],                      },
    enhancers         => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ],                      },
    gender            => { endpoint => 'char/CharacterSheet',     params => [ [ 'character_id',    'characterID'   ] ], max_cache => 604800  },
    training          => { endpoint => 'char/SkillInTraining',    params => [ [ 'character_id',    'characterID'   ] ],                      },
    accounts          => { endpoint => 'char/AccountBalance',     params => [ [ 'character_id',    'characterID'   ] ], max_cache => 60      },
    transactions      => { endpoint => 'char/WalletTransactions', params => [ 
                                                                              [ 'character_id',    'characterID'   ], 
                                                                              [ 'before_trans_id', 'beforeTransID' ], 
                                                                              [ 'account_key',     'accountKey'    ],  
                                                                                                                     ], max_cache => 3600    },
    kills             => { endpoint => 'char/Killlog',            params => [ [ 'character_id',    'characterID'   ] ],                      },
    orders            => { endpoint => 'char/MarketOrders',       params => [ [ 'character_id',    'characterID'   ] ],                      },
    assets            => { endpoint => 'char/AssetList',          params => [ [ 'character_id',    'characterID'   ] ],                      },

    # Corporation
    corp_accounts     => { endpoint => 'corp/AccountBalance',     params => [ [ 'character_id',    'characterID'   ] ], max_cache => 60      },
    corp_members      => { endpoint => 'corp/MemberTracking',     params => [ [ 'character_id',    'characterID'   ] ],                      },
    corp_assets       => { endpoint => 'corp/AssetList',          params => [ [ 'character_id',    'characterID'   ] ],                      },
    corp_sheet        => { endpoint => 'corp/CorporationSheet',   params => [ [ 'character_id',    'characterID'   ] ],                      },
    corp_transactions => { endpoint => 'corp/WalletTransactions', params => [ 
                                                                              [ 'character_id',    'characterID'   ], 
                                                                              [ 'before_trans_id', 'beforeTransID' ], 
                                                                              [ 'account_key',     'accountKey'    ],  
                                                                                                                     ], max_cache => 3600    },
    corp_kills        => { endpoint => 'corp/Killlog',            params => [ [ 'character_id',    'characterID'   ] ],                      },
    corp_orders       => { endpoint => 'corp/MarketOrders',       params => [ [ 'character_id',    'characterID'   ] ],                      },
    corp_baselist     => { endpoint => 'corp/StarbaseList',       params => [ [ 'character_id',    'characterID'   ] ],                      },
    corp_base         => { endpoint => 'corp/StarbaseDetail',     params => [ [ 'character_id',    'characterID'   ] ],                      },

    # Map
    map_jumps         => { endpoint => 'map/Jumps',               params => [ [ 'character_id',    'characterID'   ] ],                      },
    map_kills         => { endpoint => 'map/Kills',               params => [ [ 'character_id',    'characterID'   ] ],                      },
    map               => { endpoint => 'map/Sovereignty',         params => undef                                     ,                      },

    # Global/Misc
    character         => { endpoint => 'account/Characters',      params => undef,                                      max_cache => 3600    },
    all_skills        => { endpoint => 'eve/SkillTree',           params => undef,                                      max_cache => 86400   },
    all_reftypes      => { endpoint => 'eve/RefTypes',            params => undef,                                                           },
};

=head2 new

Called by WebService::EveOnline->new -- sets things up at the backend without cluttering things up.
Doesn't die if not passed an api_key/user_id combination, unlike the latter.

=cut

sub new {
    my ($class, $params) = @_;

    $params ||= {};
    $params->{cache_type}   ||= "SQLite";
    $params->{cache_user}   ||= "";
    $params->{cache_pass}   ||= "";
    $params->{cache_dbname} ||= ($^O =~ /MSWin/) ? "c:/windows/temp/webservice_eveonline.db" : "/tmp/webservice_eveonline.db";
    $params->{cache_init}   ||= "yes";
    $params->{cache_maxage} ||= (86400 * 7 * 4); # time (s) between cache rebuilds. 28 days, for now.
    
    my $evecache = WebService::EveOnline::Cache->new( { eve_user_id => $params->{user_id}, cache_type => $params->{cache_type}, cache_dbname => $params->{cache_dbname} } ) if $params->{cache_init} eq "yes";
    if ($evecache && $evecache->cache_age >= $params->{cache_maxage}) {
        $evecache->repopulate( { skills => call_api('all_skills'), map => call_api('map') } );
    } else {
        $evecache ||= WebService::EveOnline::Cache->new( { cache_type => "no_cache" } );
    }
    
    return bless({ _user_id => $params->{user_id}, _api_key => $params->{api_key}, _evecache => $evecache }, $class);
}

=head2 character, characters

Pull back character objects based on your API key -- see examples/show_characters 

Singlar and plural are provided so as to allow grammatically correct usage given
the appropriate context (they both do exactly the same thing under the hood and
can be used interchangeably -- handy for contractors... ;-) )

=cut

sub characters {
    return WebService::EveOnline::API::Character->new(@_);
}

sub character {
    return WebService::EveOnline::API::Character->new(@_);
}

=head2 corporation

Pull back a corporation information object -- use on a character object for best effect.
See examples/show_corporation

=cut

sub corporation {
    return WebService::EveOnline::API::Corporation->new(@_);
}

=head2 skill, skills

Pull back skill objects on a character. See examples/skills_overview for more
details.

Singlar and plural are provided so as to allow grammatically correct usage given
the appropriate context (they both do exactly the same thing under the hood and
can be used interchangeably).

=cut

sub skill {
    return WebService::EveOnline::API::Skills->new(@_);
}

sub skills {
    return WebService::EveOnline::API::Skills->new(@_);
}

=head2 transaction, transactions

Returns transaction objects for a particular character/corporation. Singular/plural as above;
See examples/show_transactions for more details.

=cut

sub transaction {
    return WebService::EveOnline::API::Transactions->new(@_);
}

sub transactions {
    return WebService::EveOnline::API::Transactions->new(@_);
}

=head2 journal

Placeholder, for the moment. 

=cut

sub journal {
    return WebService::EveOnline::API::Journal->new(@_);
}

=head2 account, accounts

Return detailed account objects for a particular character, including corporate
account info. The first member of the array ALWAYS returns the selected character's 
personal account object -- subsequent accounts are from the corporation the
character belongs to. See examples/show_character for an example of how to use this.

=cut

sub account {
    return WebService::EveOnline::API::Account->new(@_);    
}

sub accounts {
    return WebService::EveOnline::API::Account->new(@_);    
}

=head2 map

Another placeholder.

=cut

sub map {
    return WebService::EveOnline::API::Map->new(@_);
}


=head2 $eve->user_id

Returns the current user_id.

=cut

sub user_id {
    my ($self, $user_id) = @_;
    $self->{_user_id} = $user_id if $user_id;
    return $self->{_user_id};
}

=head2 $eve->api_key

Returns the current api_key.

=cut

sub api_key {
    my ($self, $api_key) = @_;
    $self->{_api_key} = $api_key if $api_key;
    return $self->{_api_key};
}

=head2 $eve->call_api(<command>, <params>)

Call the Eve API and retrieve the results. Look in the cache first. Cache results according to API map settings.

=cut

sub call_api {
    my ($self, $command, $params, $base) = @_;
    
    my $auth = { user_id => "", api_key => "" };

    if (ref($base)) {
        $auth = { user_id => $base->user_id, api_key => $base->api_key };
    } else {
        $command = $self;
    }

    if ( defined($API_MAP->{$command}) ) {
        my $cache = ref($self) ? $self->{_evecache} : $base->{_evecache};
        
        my $gen_params = _gen_params($self, $API_MAP->{$command}->{params}, $params);
        
        my $cached_response = $cache->retrieve( { command => "$command", params => $gen_params } ) if ref($cache);
        return $cached_response if $cached_response;
        
        my $ua = LWP::UserAgent->new;
        $ua->agent("$WebService::EveOnline::AGENT/$WebService::EveOnline::VERSION");

        my $req = HTTP::Request->new( POST => $WebService::EveOnline::EVE_API . $API_MAP->{$command}->{endpoint} . '.xml.aspx' );
        $req->content_type("application/x-www-form-urlencoded");

        my $content = 'userid=' . $auth->{user_id} . '&apikey=' . $auth->{api_key} . $gen_params;
        
        $req->content($content) ;
    
        my $res = $ua->request($req);
        if ($res->is_success) {
            my $xs = XML::Simple->new();
            my $xml = $res->content;

            warn "RAW XML is:\n$xml\n" if $ENV{EVE_DEBUG} =~ m/xml/i;

            my $pre = $xs->XMLin($xml);
            my $data = {};
            my $in_error_state = undef;

            # print out any error content if it's set.
            if ($pre->{error}) {
                # error 206 is returned on characters without corp permissions. ignore. FIXME: nasty hack
                if ($pre->{error}->{code} != "206") {
                    $in_error_state = 1;
                    $data->{error} = "EVE API Error: " . $pre->{error}->{content} . " (" . $pre->{error}->{code} . ")";
                }
            }

            # at the moment, we deal in hashrefs. one day, these will be objects (like everything else will be ;-P)
            unless ($in_error_state) {
                if ($command eq "character") {
                    $data = $pre->{result}->{rowset}->{row};
                } elsif ($command eq "skills") {
                    $data->{skills} = $pre->{result}->{rowset}->{skills}->{row} if $pre->{result}->{rowset}->{skills}->{row};
                } elsif ($command eq "attributes") {
                    $data = $pre->{result}->{attributes};
                } elsif ($command eq "enhancers") {
                    $data = $pre->{result}->{attributeEnhancers};
                } elsif ($command eq "gender") {
                    $data = $pre->{result};
                } elsif ($command eq "race") {
                    $data = $pre->{result};
                } elsif ($command eq "bloodline") {
                    $data = $pre->{result};
                } elsif ($command eq "balance") {
                    $data = $pre->{result};
                } elsif ($command eq "training") {
                    $data = $pre->{result};             
                } elsif ($command eq "kills") {
                    $data = $pre->{result}->{rowset}->{row};             
                } elsif ($command eq "orders") {
                    $data = $pre->{result}->{rowset}->{row};             
                } elsif ($command eq "corp_kills") {
                    $data = $pre->{result}->{rowset}->{row};             
                } elsif ($command eq "corp_members") {
                    $data = $pre->{result}->{rowset}->{row};             
                } elsif ($command eq "corp_orders") {
                    $data = $pre->{result}->{rowset}->{row};             
                } elsif ($command eq "assets") {
                    $data = $pre->{result}->{rowset}->{row};             
                } elsif ($command eq "transactions") {
                    $data->{transactions} = $pre->{result}->{rowset}->{row} if $pre->{result}->{rowset}->{row};
                } elsif ($command =~ /accounts/) {
                    my $acc = $pre->{result}->{rowset}->{row};
                    $data->{accounts} = ref($acc) eq "HASH" ? [ $acc ] : $acc; 
                } else {
                    $data = $pre;
                    return $data;
                }
            }

            $data->{_status} ||= "ok";
            $data->{_xml} = $xml;
            $data->{_parsed_as} = $pre;

            my $stripped_data = undef;
            
            unless ($WebService::EveOnline::DEBUG_MODE) {
                $stripped_data = {};
                foreach my $strip_debug (keys %{$data}) {
                    next if $strip_debug =~ /^_/; # skip meta keys
                    $stripped_data->{$strip_debug} = $data->{$strip_debug};
                }
            }


            if ($cache && ($stripped_data || $data) && !$in_error_state) {
                # error results are not cached
                return $cache->store( { command => $command, obj => $self, data => $stripped_data || $data, params => $gen_params, cache_until => $pre->{cachedUntil}, max_cache => $API_MAP->{$command}->{max_cache}  } );
            } elsif ($in_error_state) {
                warn $data->{error} . "\n";
                return undef; # better error handling is required...;
            } else {
                return $stripped_data || $data;
            }
        } else {
            warn "Error code received: " . $res->status_line . "\n" if $ENV{EVE_DEBUG};
            return { _status => "error", message => $res->status_line, _raw => undef };     
        }
    } else {
        return { _status => "error", message => "Bad command", _raw => undef };     
    }
    
}

=head2 $character->before_trans_id

Set to return transactions older than a particular trans id for character/corp transactions.

=cut

sub before_trans_id {
    my ($self, $before_trans_id) = @_;
    $self->{_before_trans_id} = $before_trans_id if $before_trans_id;
    return $self->{_before_trans_id} || undef;
}

=head2 id

This will not return anything useful on the base class; call id on characters, accounts, transactions, etc.
where appropriate.

=cut

sub id {
    return undef;
}

sub _gen_params {
    my ($self, $keys, $passed) = @_;
    return "" unless defined $keys;

    my @kvp = ();
    foreach my $param (@{$keys}) {
        my ($intkey, $evekey) = @{$param};
        if ($self->can($intkey)) {
            push(@kvp, "$evekey=" . ($self->$intkey || $passed->{$intkey})) if ($self->$intkey || $passed->{$intkey});
        } else {
            push(@kvp, "$evekey=" . ($passed->{$evekey} || $passed->{$intkey})) if ($passed->{$evekey} || $passed->{$intkey});
        }
    }

    return '&' . (join('&', @kvp));
}

1;
