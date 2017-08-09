=head1 NAME

XAO::DO::Cache::Memcached - memcached back-end for XAO::Cache

=head1 SYNOPSIS

You should not use this object directly, it is a back-end for
XAO::Cache.

 if($backend->exists(\@c)) {
     return $backend->get(\@c);
 }

=head1 DESCRIPTION

This back end uses either Memcached::Client (preferred) or
Cache::Memcached modules to store and access distributed data in
memcached servers.

It does not work without special support data stored in the site
configuration:

    /cache/memcached => {
        servers             => [ '192.168.0.100','192.168.0.101' ],
        compress_threshold  => 15000,
        ...
    },

The only default is having namespace set to the current site name
so that the same keys in different sites don't overlap. If you feel
adventurous you can explicitly set "namespace" to an empty string in the
config to enable cross-site data caching.

The keys are built from cache name and concatenated coordinate values.

NOTE: The memcached backend does not work well on nameless caches. The
name in that case will be simply "$self" (typically something like
XAO::DO::Cache::Memcached=GLOB(0x8d850f0)) -- which almost makes the
cache useless, as several instances of the process will store data
duplicates. Don't do that.

Thankfully all caches used through $config->cache interface have names
by definition.

The XAO::Cache "size" parameter is ignored and must be controlled in
memcached configuration. The "expire" argument is given to MemCacheD to
honor and is not locally enforced.

A couple additional cache parameters are accepted on a per-cache level:

   separator       => used for building cache keys from coordinates
   digest_keys     => if set SHA-1 digests are used instead of actual
                      concatenated coordinate keys
   debug           => if set then dprint is used for extra logging
   value_maxlength => maximum length of an individual value
   
=head1 METHODS

=over

=cut

###############################################################################
package XAO::DO::Cache::Memcached;
use strict;
use XAO::Utils;
use XAO::Objects;
use XAO::Projects;
use JSON;
use Storable qw(freeze thaw);
use Encode;
use Digest::SHA;

use base XAO::Objects->load(objname => 'Atom');

###############################################################################

=item drop (@)

Drops an element from the cache.

=cut

sub drop ($@) {
    my $self=shift;
    $self->memcached->delete($self->make_key(@_));
}

###############################################################################

=item drop (@)

Drops all elements from the cache.

=cut

sub drop_all ($@) {
    my $self=shift;
    $self->memcached->flush_all();
}

###############################################################################

=item get (\@)

Retrieves an element from the cache. Does not validate expiration time,
trusts memcached on that.

=cut

sub get ($$) {
    my $self=shift;

    my $key=$self->make_key(shift);

    # We need to support storing undefs. All data is stored as JSON.
    #
    my $frozen_text=$self->memcached->get($key);

    if($self->{'debug'}) {
        dprint "MEMCACHED:get('$key')=",(defined $frozen_text ? "'".substr($frozen_text,0,30)."...'" : '<UNDEF>')," length=".length(defined $frozen_text ? $frozen_text : '');
    }

    if(defined $frozen_text) {

        my $data;
        if(substr($frozen_text,0,1) eq '[') {
            $data=decode_json($frozen_text)->[0];
        }
        else {
            $data=thaw($frozen_text)->[0];
        }

        return \$data;
    }
    else {
        return undef;
    }
}

###############################################################################

=item make_key (\@)

Makes a key from the given reference to a list of coordinates.

=cut

sub make_key ($$) {
    my $self=shift;

    my $key=join($self->{'separator'},map { defined($_) ? $_ : '' } @{$_[0]});

    # Ascii memcached protocol cannot handle whitespace in keys
    #
    $key=Encode::encode('utf8',$key) if Encode::is_utf8($key);

    $key=~s/([\s\r\n])/'%'.unpack('H2',$1)/sge;

    # Memcached has a 250 character limit on key length. Compacting it
    # if it's over the limit, or if we are told to compact all keys.
    #
    if(length($key)>=$self->{'key_maxlength'} || $self->{'digest_keys'}) {
        ### dprint "...changing key (length=".length($key).") to a digest";
        $key=Digest::SHA::sha1_hex($key);
        ### dprint "....key=$key";
    }

    $key=$self->{'key_prefix'} . $key;

    ### if($self->{'debug'}) {
    ###     dprint "MEMCACHED:key length=".length($key)." $key";
    ### }

    return $key;
}

###############################################################################

=item put (\@\$)

Add a new element to the cache.

=cut

sub put ($$$) {
    my $self=shift;
    my $key=$self->make_key(shift);
    my $data=shift;

    # JSON destroys information about UNICODE/OCTETS status of strings,
    # always returning perl UNICODE. Freeze/Thaw does not have that
    # problem, but stored strings are not human readable.
    #
    if(1) {

        # We need to support storing complex data and undefs.
        #
        my $frozen_text=freeze([$$data]);

        # If the value is too large we silently ignore it and do not
        # store. It is going to be rejected by the cache anyway.
        #
        if(length($frozen_text) > $self->{'value_maxlength'}) {
            if($self->{'debug'}) {
                eprint "MEMCACHED:put('$key'=>",(defined $frozen_text ? "'".substr($frozen_text,0,30)."...'" : '<UNDEF>')." length=".length($frozen_text).">".$self->{'value_maxlength'}." NOT STORED";
            }
            return;
        }

        if($self->{'debug'}) {
            dprint "MEMCACHED:put('$key'=>",(defined $frozen_text ? "'".substr($frozen_text,0,30)."...'" : '<UNDEF>')." length=".length($frozen_text);
        }

        my $expire=$self->{'expire'};

        $self->memcached->set($key,$frozen_text,($expire ? time + $expire : 0));
    }

    else {

        # We need to support storing complex data and undefs. Using JSON to
        # accomplish both.
        #
        my $json_text=encode_json([$$data]);

        # If the value is too large we silently ignore it and do not
        # store. It is going to be rejected by the cache anyway.
        #
        if(length($json_text) > $self->{'value_maxlength'}) {
            if($self->{'debug'}) {
                eprint "MEMCACHED:put('$key'=>",(defined $json_text ? "'".substr($json_text,0,30)."...'" : '<UNDEF>')." length=".length($json_text).">".$self->{'value_maxlength'}." NOT STORED";
            }
            return;
        }

        if($self->{'debug'}) {
            dprint "MEMCACHED:put('$key'=>",(defined $json_text ? "'".substr($json_text,0,30)."...'" : '<UNDEF>')." length=".length($json_text);
        }

        my $expire=$self->{'expire'};

        $self->memcached->set($key,$json_text,($expire ? time + $expire : 0));
    }
}

###############################################################################

=item setup (%)

Sets expiration time and maximum cache size.

=cut

sub setup ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    ### use Data::Dumper;
    ### dprint Dumper($args);

    # Checking if we have a configuration
    #
    my $siteconfig=$args->{'sitename'}
            ? XAO::Projects::get_project($args->{'sitename'})
            : (XAO::Projects::get_current_project_name() && XAO::Projects::get_current_project());

    $siteconfig ||
        throw $self "- can only be used within a site context";

    $siteconfig->can('get') ||
        throw $self "- site configuration needs to support a get() method";

    $siteconfig->get('/cache/memcached/servers') ||
        throw $self "- need at least /cache/memcached/servers in the site config";

    $self->{'siteconfig'}=$siteconfig;

    # Having a name is really advisable. Showing a warning if it's not
    # given. Without a name the cache degrades to a per-process cache,
    # losing all of memcached benefits.
    #
    my $name=$args->{'name'};

    if(!$name) {
        $name="$self";
        eprint "Memcached is nearly useless without a 'name' (assumed '$name')";
    }

    $self->{'name'}=$name;

    # Separator for building keys from a set of coordinates
    #
    my $separator=$args->{'separator'} || "\001";

    $self->{'separator'}=$separator;

    # We may have a namespace. Typically it is the site name, but can also be
    # hard-coded in case the cache is shared between multiple differently
    # named sites.
    #
    my $namespace=$args->{'namespace'};

    if(!defined $namespace) {
        $namespace=$siteconfig->get('/cache/memcached/namespace');
    }

    if(!defined $namespace) {
        $namespace=XAO::Projects::get_current_project_name() || '';

        if($self->{'debug'}) {
            dprint "MEMCACHED: assumed namespace is '$namespace'";
        }
    }

    $self->{'namespace'}=$namespace;

    # We need a key prefix for all keys.
    #
    my $key_prefix=$namespace . $separator .  $name . $separator;

    $key_prefix=Encode::encode('utf8',$key_prefix) if Encode::is_utf8($key_prefix);

    $key_prefix=~s/([\s\r\n])/'%'.unpack('H2',$1)/sge;

    my $key_maxlength=250 - length($key_prefix);

    # We need at least 40 characters to put the digest into
    #
    if($key_maxlength < 40) {
        my $key_prefix_digest=Digest::SHA::sha1_hex($key_prefix);
        $key_prefix=$key_prefix_digest . $separator;
        $key_maxlength=250 - length($key_prefix);
    }

    $self->{'key_prefix'}=$key_prefix;
    $self->{'key_maxlength'}=$key_maxlength;

    # Additional per-cache configuration
    #
    $self->{'expire'}=$args->{'expire'} || 0;

    $self->{'digest_keys'}=$args->{'digest_keys'};

    $self->{'debug'}=$args->{'debug'};

    # Maximum size of a stored element, memcached default.
    #
    $self->{'value_maxlength'}=$args->{'value_maxlength'} || 1*1024*1024-1;

    if($self->{'debug'}) {
        dprint "MEMCACHED:namespace=      ",$self->{'namespace'};
        dprint "MEMCACHED:name=           ",$self->{'name'};
        dprint "MEMCACHED:expire=         ",$self->{'expire'};
        dprint "MEMCACHED:separator=      ",$self->{'separator'};
        dprint "MEMCACHED:digest_keys=    ",$self->{'digest_keys'};
        dprint "MEMCACHED:key_prefix=     ",$self->{'key_prefix'};
        dprint "MEMCACHED:key_maxlength=  ",$self->{'key_maxlength'};
        dprint "MEMCACHED:value_maxlength=",$self->{'value_maxlength'};
    }
}

###############################################################################

sub memcached ($) {
    my $self=shift;

    my $memcached=$self->{'memcached'};

    return $memcached if $memcached;

    my $cfg=$self->{'siteconfig'}->get('/cache/memcached') ||
        throw $self "- need a /config/memcached in the site configuration";

    # We deal with namespace locally, must not also give it to the module!
    #
    if(exists $cfg->{'namespace'}) {
        $cfg=merge_refs($cfg);
        delete $cfg->{'namespace'};
    }

    # Creating the cache interface.
    #
    my $have_memcached_client;
    my $have_cache_memcached;
    eval {
        require Memcached::Client;
        $self->{'client'}='Memcached::Client';
        $have_memcached_client=1;
    };
    if($@) {
        eval {
            require Cache::Memcached;
            $self->{'client'}='Cache::Memcached';
            $have_cache_memcached=1;
        };
    }

    if($have_memcached_client) {
        $memcached=Memcached::Client->new($cfg);
    }
    elsif($have_cache_memcached) {
        $memcached=Cache::Memcached->new($cfg);
    }
    else {
        throw $self "- no  Memcached::Client and no Cache::Memcached available";
    }

    $memcached ||
        throw $self "- unable to instantiate Cache::Memcached";

    $self->{'memcached'}=$memcached;

    if($self->{'debug'}) {
        dprint "MEMCACHED:client=       $self->{'client'}";
    }

    return $memcached;
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2013 Andrew Maltsev <am@ejelta.com>.

=head1 SEE ALSO

Have a look at:
L<XAO::Cache>,
L<XAO::Objects>,
L<XAO::Base>,
L<XAO::FS>,
L<XAO::Web>.
