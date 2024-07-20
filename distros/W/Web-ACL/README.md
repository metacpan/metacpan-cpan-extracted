# Web-ACL

A helper for creating basic apikey/slug/IP/path/UA based ACLs.

Slugs should be though of as a freeform field for use function names
or the like.

```perl
    use Web::ACL;

    my $acl = Web::ACL->new(acl=>{
            fooBar=>{
				ip_auth       => 1,
				slug_auth     => 0,
				require_ip    => 1,
				require_slug  => 0,
				final         => 1,
				slugs         => [],
				slugs_regex   => [],
				allow_subnets => ['192.168.0.0/16','127.0.0.1/32'],
				deny_subnets  => [],
             },
            derp=>{
				ip_auth       => 1,
				slug_auth     => 1,
				require_ip    => 1,
				require_slug  => 0,
				final         => 1,
				slugs         => ['derp'],
				slugs_regex   => [],
				allow_subnets => ['192.168.0.0/16','127.0.0.1/32'],
				deny_subnets  => ['10.0.10.0/24'],
             },
            derpderp=>{
				ip_auth       => 0,
				slug_auth     => 1,
				require_ip    => 1,
				require_slug  => 0,
				final         => 1,
				slugs         => ['derp'],
				slugs_regex   => [],
				allow_subnets => [],
				deny_subnets  => [],
             },
        });

    my $results=$acl->check(
                    apikey=>'a_test',
                    ip=>'10.1.3.4',
                    slugs=>['test2'],
                );
    if ($results) {
        print "Authed\n";
    }else{
        print "Not Authed\n";
    }

    my $results=$acl->check(
                    apikey=>'fooBar',
                    ip=>'192.168.1.2',
                    slugs=>['test2'],
                );
    if ($results) {
        print "Authed\n";
    }else{
        print "Not Authed\n";
    }

    my $results=$acl->check(
                    apikey=>'fooBar',
                    ip=>'192.168.1.2',
                    slugs=>['test2'],
                );
    if ($results) {
        print "Authed\n";
    }else{
        print "Not Authed\n";
    }

    my $results=$acl->check(
                    apikey=>'derpderp',
                    ip=>'192.168.1.2',
                    slugs=>['derp'],
                );
    if ($results) {
        print "Authed\n";
    }else{
        print "Not Authed\n";
    }

    my $results=$acl->check(
                    apikey=>'derpderp',
                    ip=>'192.168.1.2',
                    slugs=>['not_derp'],
                );
    if ($results) {
        print "Authed\n";
    }else{
        print "Not Authed\n";
    }
```

## ACL HASH

The ACL hash is a hash of hashes. The keys for primary hash are API
keys. The keys for the subhashes are as below.

Slugs should be though of a freeform text field for access
check. Function name or whatever.

```
    - ip_auth :: Use IP for authing. If false, the IP will not be checked.
        - Default :: 0

    - slug_auth :; Use the slug for authing. If false it won't be checked.
        - Default :: 0

    - require_ip :: Require a value for IP to be specified.
        - Default :: 0

    - require_slug :: Require a value for slug to be specified.
        - Default :: 0

    - final :: The return value for if none of the auth checks are denied.
         - Default for 'undef'/'nonexistent' apikeys:: 0
         - Default for other apikeys:: 1

    - slugs :; Slugs that are allowed for access.
        - Default :: []

    - slugs_regex :: Regexps to check slug values against.
        - Default :: []

    - allow_subnets :: Allowed subnets for remote IPs. This is a array of CIDRs.
        - Default :: []

    - deny_subnets :: Denied subnets for remote IPs. This is a array of CIDRs.
        - Default :: []
```

There are two special ones for the ACL hash. Those are `undef` and
`nonexistent` and they should not be used as API keys. These are for
in the instances that the apikey for the checkis undef or if specified
and does not exist `nonexistent` is used.

By default they are as below.

```perl
		{
			'undef' => {
				ip_auth       => 0,
				slug_auth     => 0,
				require_ip    => 0,
				require_slug  => 0,
				final         => 0,
				slugs         => [],
				slugs_regex   => [],
				allow_subnets => [],
				deny_subnets  => [],
			},
			'nonexistent' => {
				ip_auth       => 0,
				slug_auth     => 0,
				require_ip    => 0,
				require_slug  => 0,
				final         => 0,
				slugs         => [],
				slugs_regex   => [],
				allow_subnets => [],
				deny_subnets  => [],
			},
		}
```
