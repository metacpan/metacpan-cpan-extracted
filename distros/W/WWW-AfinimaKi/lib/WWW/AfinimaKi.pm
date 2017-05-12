package WWW::AfinimaKi;
use strict;

require RPC::XML;
require RPC::XML::Client;
use Digest::SHA	qw(hmac_sha256_hex);
use Encode;
use Carp;
use Data::Dumper;
use Cache::Memcached::Fast;
use Storable;
use Digest::MD5	qw(md5_hex);

our $VERSION = '0.85';

use constant KEY_LENGTH     => 32;
use constant TIME_SHIFT     => 10;

use constant  MAX_TS    => 1234567890;
use constant  TIMEOUT   => 120;
use constant  MEMC_TTL  => 1200;

## Exportable Constants
sub OP_CODE_ADD_TO_WISHLIST { return 0; }
sub OP_CODE_ADD_TO_BLACKLIST { return 1; }
sub OP_CODE_REMOVE_FROM_LISTS { return 2; }
sub OP_CODE_SET_RATE { return 3; }
sub OP_CODE_SET_NULL_RATE { return 4; }

sub dbg { print STDERR __PACKAGE__ . ' '.  join(' ', @_)."\n"; }

=head1 NAME

WWW::AfinimaKi - AfinimaKi Recommendation Engine Client


=head1 SYNOPSIS

    use WWW::AfinimaKi;         # Notice the uppercase "K"!

    my $api = WWW::AfinimaKi->new( $your_api_key, $your_api_secret);

    ...

    $api->set_rate($email_sha256, $user_id, $rates);

    ...

    my $estimated_rate = $api->estimate_rate($email_sha256, $rate);

    ...

    my $recommendations = $api->get_recommendations($email_sha256);
    foreach (@$recommendations) {
        print "item_id: $_->{item_id} estimated_rate: $_->{estimated_rate}\n";
    }

    ...

    my $recommendations = $api->get_recommendations($email_sha256);
    foreach (@$recommendations) {
        print "item_id: $_->{item_id} estimated_rate: $_->{estimated_rate}\n";
    }

    ...

    my $soul_mates = $api->get_soul_mates($email_sha256);
    foreach (@$soul_mates) {
        print "user_id: $_->{user_id} afinimaki: $_->{afinamki} email_sha256: $_->{email_sha256}\n";
    }

=head1 DESCRIPTION

WWW::AfinimaKi is a simple client for the AfinimaKi Recommendation API. 
Check http://www.afinimaki.com for more details.

All functions use an email digest of your users, in orden to maintain their privacy. The digest function is SHA256. You can generate the digest with the function sha256_hex from the module Digest::SHA.

=head1 Methods

=head3 new

    my $api = WWW::AfinimaKi->new( 
                    api_key     => $your_api_key, 
                    api_secret  => $your_api_secret, 
                    debug       => $debug_level,
                    memcached   => $memcached_server
    );

    if (!$api) {
        die "Error construction afinimaki, wrong keys length?";
    }

    new Construct the AfinimaKi object. No network traffic is 
    generated (the account credentialas are not checked at this point). 

    The given keys must be 32 character long. You can get them at 
    www.afinimaki.com 
    
    Debug level can be 0 or 1.

=cut

sub new {
    my ($class, %args) = @_;  

    my $key     =  $args{api_key};
    my $secret  =  $args{api_secret};
    my $debug   =  $args{debug};
    my $url     =  $args{url} || 'http://api.afinimaki.com/RPC2';

    # url parameter is undocumented on purpose to simplify.

    if ( !$key  || ! $secret ) {
        carp "api_key and api_secret parameters are mandatory";
        return undef;
    }

    if ( length($key) != KEY_LENGTH ) {
        carp "Bad api_key '$key': it must be " .  KEY_LENGTH . " character long";
        return undef;
    }


    if ( length($secret) != KEY_LENGTH  ) {
        carp "Bad api_secret '$secret': it must be ". KEY_LENGTH . " character long";
        return undef;
    }

    if ( $url && $url !~ /^http:\/\// ) {
        carp "Bad URL given : $url";
        return undef;
    }

    my $self = {
        key     => $key,
        secret  => $secret,
        cli     => RPC::XML::Client->new($url),
        debug   => $debug,
        secret_bin => pack( 'H2' x 16, 
                                        grep { $_ }
                                        split /(..)/ , 
                                        $secret
                        ),
    };

    if ( $args{memcached} ) {
            $self->{memcached} = new Cache::Memcached::Fast({
                    servers => [ { address =>  $args{memcached} },
                    ],
                    namespace           => 'afiniapi::',
                    compress_threshold  => 100_000,
                    max_failures        => 3,
                    failure_timeout     => 5,
                    nowait              => 1,
                    hash_namespace      => 1,
                    serialize_methods   => [ \&Storable::freeze, \&Storable::thaw ],
                    max_size            => 512 * 1024,
#                    utf8 => 1,
            });

        dbg "AFINIAPI: using $args{memcached}";
        $self->{memcached}->set("test",1, MEMC_TTL) or dbg "AFINIAPI: memc server failed";
    }

    $self->{cli}->timeout(TIMEOUT);

    bless $self, $class;

    return $self;
}

sub _auth_code {
    my ($self, $method, $first_arg) = @_;
    return undef if ! $method;

    $first_arg ||= '';

    my $code = 
        $method 
        . $first_arg 
        . int( time() >> TIME_SHIFT )
        ;

    #print STDERR "CODE: $code\n" if $self->{debug};

    return hmac_sha256_hex( $code, $self->{secret_bin}  );
        
}

sub _is_error {
    my ($r) = @_;

    if ( !$r ) {
        return 1;
    }
    elsif ( $r->is_fault()) {
        carp __PACKAGE__ . " Error: ". $r->string;
        return 1;
    }
    return 0;
}

sub send_request {
    my ($self, $method, @args) = @_;

    my $val = $args[0] ? $args[0]->value : undef;


    dbg ( $method,  map { $_->value } @args )
        if $self->{debug};

    my $r;

    eval {
        $r = $self->{cli}->send_request(
            $method,
            $self->{key},
            $self->_auth_code($method, $val),
            @args
        );
    };
    if ($@){
        dbg  "ERROR: $@";
    }

    if (ref($r)) {
        return $r;
    }

    carp $r;

    return undef;
}

sub _set_memc_ts {
    my ($self, $email_sha256, $ts) = @_;

    dbg "Storing last rate TS: " . ($ts || MAX_TS);

    if ( $self->{memcached} ) {
        $self->{memcached}->set('last-rate-'.$email_sha256, $ts || MAX_TS, MEMC_TTL);
    }
}


=head2 user-item services


=head3 set_rate_, add_to_wishlist, add_to_blacklist, remove_from_lists

    $api->set_rate(
        $email_sha256, 
        $user_id,
        $item_id,
        $rate,
        $ts,
    );

    $api->add_to_wishlist(
        $email_sha256,
        $user_id,
        $item_id,
        $ts,
    );

    $api->add_to_blacklist( ... same as add_to_wishlist ...);
    $api->remove_from_lists( ... same as add_to_wishlist ...);

    $ts is the unix timestamp when the action was done 
    (if $ts is not given, the action was performed now).

    user_id indicate the API to store your user_id in the DB, 
    besides the email_sha256. Then, functions like get_soul_mates 
    can return you back your user's ID for your conveniente.

    All calls wait until the RPC call has ended. 
    On error, return is undef, and the RPC::XML error will be carp'ed.
    On success, the returned values are:

    1: The rate was inserted 
    2: The rate existed previous, and it was NOT modified 
    3: The rate existed previous, and it was updated by 
       this call
    -1: Error in parameters

=head4 set_rate 

    Stores rates in the server 

=head4 add_to_wishlist

    Adds the given $item_ids to user's wishlist. This 
    means that id will not be in the user's recommentation 
    list, and the action will be use to tune users's 
    recommendations (The user seems to like this item).

=head4 add_to_blacklist


    Adds the given $item_ids to user's blacklist. This 
    means that id will not be in the user's recommentation 
    list, and the action will be use to tune users's 
    recommendations (The user seems to dislike this item).

=head4 remove_from_lists Stores a rate in the server. 

    Removes the given items from user's wish and black lists, 
    and also removes user item's rating (if any).

=head4 set_null_rate 

    Set rate rate as NULL. This is useful when the user has already experienced the item (watched a movie, bought the product) but did set a rate. Therefore the item shouldn't be recommended again to the user.

=cut

sub set_rate {
    my ($self, $email_sha256, $user_id,  $item_id, $rate, $ts ) = @_;
    return [] if ! $email_sha256 || ! $rate || !$item_id ;

    my $r = $self->send_request(
        'set_rate', 
        RPC::XML::string->new($email_sha256),
        RPC::XML::i8->new($user_id || 0),
        RPC::XML::i8->new($item_id),
        RPC::XML::double->new($rate),
        RPC::XML::i4->new($ts||0),
    );


    $self->_set_memc_ts($email_sha256, $ts || $^T);

    return undef if _is_error($r);

    return $r;
}

sub generic_add {
    my ($self, $method, $email_sha256, $user_id, $item_id, $ts ) = @_;
    return undef if ! $email_sha256  || !$item_id ;


    my $r = $self->send_request(
        $method, 
        RPC::XML::string->new($email_sha256),
        RPC::XML::i8->new($user_id || 0),
        RPC::XML::i8->new($item_id),
        RPC::XML::i4->new($ts||0),
    );

    $self->_set_memc_ts($email_sha256, $ts || $^T );

    return undef if _is_error($r);
    return $r->value;
}

sub add_to_wishlist {
    my $self = shift;
    return $self->generic_add('add_to_wishlist', @_);
}

sub add_to_blacklist {
    my $self = shift;
    return $self->generic_add('add_to_blacklist', @_);
}

sub remove_from_lists {
    my $self = shift;
    return $self->generic_add('remove_from_lists', @_);
}


sub set_null_rate {
    my $self = shift;
    return $self->generic_add('set_null_rate', @_);
}



sub set_rates_bulk {
    my ($self, $rates ) = @_;
    return [] if ! $rates || !@$rates ;

    my $first_email = $rates->[0]->{email_SHA} || return [];

    my @arg = map { RPC::XML::array->new(
            RPC::XML::i4->new($_->{op_code}),
            RPC::XML::string->new($_->{email_SHA}),
            RPC::XML::i8->new($_->{user_id}),
            RPC::XML::i8->new($_->{item_id}),
            RPC::XML::i4->new($_->{ts} || 0),
            RPC::XML::double->new($_->{rate} || 0),
    ) } @$rates;

    my $r = $self->send_request(
        'set_rates_bulk', 
        RPC::XML::string->new($first_email),
        RPC::XML::array->new(@arg),
    );

    return undef if _is_error($r);

    ## expire
    if ($self->{memcached}) {
        my %unique;
        foreach (@$rates ) {
            next if $unique{$_->{email_SHA}}++;
            $self->_set_memc_ts($_->{email_SHA}); # No ts, => use MAX TS, expire all
        }
    }

    return $r;
}


=head3 estimate_rate

    my $estimated_rate = $api->estimate_rate($email_sha256, $item_id);

    Estimate a rate. Undef is returned if the rate could not 
    be estimated (usually because the given user or the given 
    item does not have many rates).

    On error, returns undef, and carp the RPC::XML error.
=cut

sub estimate_rate {
    my ($self, $email_sha256, $item_id) = @_;
    return undef if ! $email_sha256 || ! $item_id;

    my ($value, $from_cache, $ts);

#dbg "estimate";
    if ($self->{memcached}) {
        $ts = $self->{memcached}->get('last-rate-' . $email_sha256);

#dbg "last rate ts". $ts;
        if ($ts) {
#    dbg "key"."estimate-rate-$email_sha256-$item_id-$ts";
            $value =  $self->{memcached}->get("estimate-rate-$email_sha256-$item_id-$ts");
#dbg "value". $value;
            if ($value) {
                $from_cache = 1;
#                dbg "AFINIAPI : restored in cache: $item_id";
            }
        }
        else {
            $ts = $^T;
            $self->_set_memc_ts($email_sha256, $ts);
        }
    }

   if ( !$value ) {

        my $r = $self->send_request(
            'estimate_rate', 
            RPC::XML::string->new($email_sha256),
            RPC::XML::i8->new($item_id),
        );

        return undef if _is_error($r);

        $value = 1.0 * $r->value;
    }

    if ($self->{memcached} && ! $from_cache) {
#        dbg "AFINIAPI : storing in cache $item_id : $value";

        $self->{memcached}->set("estimate-rate-$email_sha256-$item_id-$ts",  
                $value, MEMC_TTL)
            or dbg "memc server failed...";
    }

    return $value;
}



=head3 estimate_multiple_rates

    my $rates_hashref = $api->estimate_rate($email_sha256, @item_ids);

    foreach my $item_id (keys %$rates_hashref) {
        print "Estimated rate for $item_id is 
            $rates_hashref->{$item_id}\n";
    }

    Estimate multimple rates. The returned hash has 
    the structure: 

            item_id => estimated_rate

    On error, returns undef, and carp the RPC::XML error.

=cut

sub estimate_multiple_rates {
    my ($self, $email_sha256,  @item_ids) = @_;
    return undef if ! $email_sha256 || ! @item_ids;

    my ($sig, $from_cache, $ts, $ret);


    if ($self->{memcached}) {

        $sig = md5_hex join ("", @item_ids);

        $ts = $self->{memcached}->get('last-rate-' . $email_sha256);

        if ($ts) {
            $ret =  $self->{memcached}->get("multiple-$email_sha256-$sig-$ts");

            if ($ret) {
                $from_cache = 1;
                dbg "AFINIAPI : restored multiple from cache: $sig";
            }
        }
        else {
            $ts = $^T;
            $self->_set_memc_ts($email_sha256, $ts);
        }
    }

    if (!$ret) {
        my $r = $self->send_request(
                'estimate_multiple_rates', 
                RPC::XML::string->new($email_sha256),
                RPC::XML::array->new( 
                        map {
                            RPC::XML::i8->new($_)
                        } @item_ids
                    )
            );
        return undef if _is_error($r);
        
        $ret = {}; 
        my $i = 0;
        eval { 
            foreach (@$r) {
                $ret->{$item_ids[$i++]} = 1.0 * $_->value;
            }
        };
    }

    if ($self->{memcached} && ! $from_cache) {
        dbg "AFINIAPI : storing in cache multiple: $sig";
        $self->{memcached}->set("multiple-$email_sha256-$sig-$ts",  $ret, MEMC_TTL)
            or dbg "memc server failed...";

    }


    return $ret;
}

=head3 get_recommendations 

    my $recommendations = $api->get_recommendations($email_sha256);

    foreach (@$recommendations) {
        print "item_id: $_->{item_id} 
                estimated_rate: $_->{estimated_rate}\n";
    }

    Get a list of user's recommentations, based on users' 
    and community previous rates.  Recommendations does not 
    include rated or marked items (in the whish or black list).

=cut

sub get_recommendations {
    my ($self, $email_sha256) = @_;
    return undef if ! $email_sha256;

    my $r = $self->send_request(
        'get_recommendations', 
        RPC::XML::string->new($email_sha256),
        RPC::XML::boolean->new(0),
    );
    return undef if _is_error($r);

#print __PACKAGE__ .":". Dumper $r;    
    
    return [] if ref($r) ne 'RPC::XML::array';

    return [
        map { {
            item_id         => 1   * $_->[0]->value,
            estimated_rate  => 1.0 * $_->[1]->value,
        } } @$r
    ];
}

=head2 user-user services

=head3 get_user_user_afinimaki 

    my $afinimaki = 
        $api->get_user_user_afinimaki($email_sha256_user_1, $email_sha256_user_2);

    Gets user vs user afinimaki. AfinimaKi range is [0.0-1.0].

=cut

sub get_user_user_afinimaki {
    my ($self, $email_sha256_1,  $email_sha256_2) = @_;
    return undef if ! $email_sha256_1 || ! $email_sha256_2;
    
    my $r = $self->send_request(
        'get_user_user_afinimaki', 
        RPC::XML::string->new($email_sha256_1),
        RPC::XML::string->new($email_sha256_2),
    );
    return undef if _is_error($r);

    return 1.0 * $r->value;
}



=head3 get_soul_mates 

    my $soul_mates = $api->get_soul_mates($email_sha256);

    foreach (@$soul_mates) {
        print "user_id: $_->{user_id} 
                afinimaki: $_->{afinimaki}
                email_sha: $_->{email_sha256}
                \n";
    }

    Get a list of user's soul mates (users with similar 
    tastes). AfinimaKi range is [0.0-1.0].

    Note that user_id in the results will ONLY be filled if you have 
    upload you user_id's using set_rate or a similar function.

=cut

sub get_soul_mates {
    my ($self, $email_sha256) = @_;
    return undef if ! $email_sha256;

    my $r = $self->send_request(
        'get_soul_mates', 
        RPC::XML::string->new($email_sha256),
    );
    return undef if _is_error($r);

    return [] if ref($r) ne 'RPC::XML::array';

    return [
        map { {
            email_sha256    => $_->[0]->value,
            afinimaki       => 1.0 * $_->[1]->value,
            user_id         => 1   * ($_->[2]->value || 0),
        } } @$r
    ];
}



__END__

=head1 AUTHORS

WWW::AfinimaKi by Matias Alejo Garcia (matiu at cpan.org)

=head1 COPYRIGHT

Copyright (c) 2010 Matias Alejo Garcia. All rights reserved.  
This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=head1 SUPPORT / WARRANTY

The WWW::AfinimaKi is free Open Source software. IT COMES 
WITHOUT WARRANTY OF ANY KIND. 

Github repository is at http://github.com/matiu/WWW--AfinimaKi


=head1 BUGS

None discovered yet... please let me know if you run into one.
	

