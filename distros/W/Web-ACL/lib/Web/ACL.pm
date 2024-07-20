package Web::ACL;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Net::Subnet;

=head1 NAME

Web::ACL - A helper for creating basic apikey/slug/IP based ACLs.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

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
				require_ip    => 0,
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


=head1 METHODS

=head2 new

Initiates the object.

    - acl :: The ACL hash to use.
        - Default :: {
			'undef' => {
				ip_auth       => 0,
				path_auth     => 0,
				slug_auth     => 0,
				ua_auth       => 0,
				require_ip    => 0,
				require_slug  => 0,
				final         => 0,
				slugs         => [],
				slugs_regex   => [],
				allow_subnets => [],
				deny_subnets  => [],
				ua_regex_allow    => [],
				ua_regex_deny     => [],
				paths_regex_allow => [],
				paths_regex_deny  => [],
			},
			'nonexistent' => {
				ip_auth       => 0,
				path_auth      => 0,
				slug_auth     => 0,
				ua_auth       => 0,
				require_ip    => 0,
				require_slug  => 0,
				final         => 0,
				slugs         => [],
				slugs_regex   => [],
				allow_subnets => [],
				deny_subnets  => [],
				ua_regex_allow    => [],
				ua_regex_deny     => [],
				paths_regex_allow => [],
				paths_regex_deny  => [],
			},
		}

=cut

sub new {
	my ( $blank, %opts ) = @_;

	my $self = {
		perror        => undef,
		error         => undef,
		errorLine     => undef,
		errorFilename => undef,
		errorString   => "",
		errorExtra    => {
			all_errors_fatal => 1,
			flags            => {
				1 => 'ACLnotHash',
				2 => 'ACLitemNotArray',
				3 => 'subnetError',
				4 => 'ACLnotString',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		acl => {
			'undef' => {
				ip_auth           => 0,
				slug_auth         => 0,
				ua_auth           => 0,
				path_auth         => 0,
				require_ip        => 0,
				require_slug      => 0,
				require_ua        => 0,
				require_path      => 0,
				final             => 0,
				slugs             => [],
				slugs_regex       => [],
				allow_subnets     => [],
				deny_subnets      => [],
				ua_regex_allow    => [],
				ua_regex_deny     => [],
				paths_regex_allow => [],
				paths_regex_deny  => [],
			},
			'nonexistent' => {
				ip_auth           => 0,
				slug_auth         => 0,
				ua_auth           => 0,
				path_auth         => 0,
				require_ip        => 0,
				require_slug      => 0,
				require_ua        => 0,
				require_path      => 0,
				final             => 0,
				slugs             => [],
				slugs_regex       => [],
				allow_subnets     => [],
				deny_subnets      => [],
				ua_regex_allow    => [],
				ua_regex_deny     => [],
				paths_regex_allow => [],
				paths_regex_deny  => [],
			},
		},
	};
	bless $self;

	if ( defined( $opts{acl} ) && ref( $opts{acl} ) eq 'HASH' ) {

		my @acl_keys = keys( %{ $opts{acl} } );
		foreach my $acl (@acl_keys) {
			# check boolean items and define if undef
			my @keys_that_are_boolean = (
				'ip_auth', 'require_ip', 'slug_auth', 'require_slug', 'path_auth', 'require_path',
				'ua_auth', 'require_ua', 'final',
			);
			foreach my $boolean_key (@keys_that_are_boolean) {
				if ( !defined( $opts{acl}{$acl}{$boolean_key} ) ) {
					$opts{acl}{$acl}{$boolean_key} = 0;
				} else {
					if ( ref( $opts{acl}{$acl}{$boolean_key} ) ne '' ) {
						$self->{perror} = 1;
						$self->{error}  = 4;
						$self->{errorString}
							= '$opts{acl}{acl}{'
							. $boolean_key
							. '} is not ref "", but "'
							. ref( $opts{acl}{$acl}{$boolean_key} ) . '"';
						$self->warn;
						return;
					} ## end if ( ref( $opts{acl}{$acl}{$boolean_key} )...)
				} ## end else [ if ( !defined( $opts{acl}{$acl}{$boolean_key...}))]
			} ## end foreach my $boolean_key (@keys_that_are_boolean)

			if ( !defined( $opts{acl}{$acl}{final} ) && ( $acl eq 'undef' || $acl eq 'nonexistent' ) ) {
				$opts{acl}{$acl}{final} = 0;
			} elsif ( !defined( $opts{acl}{$acl}{final} ) ) {
				$opts{acl}{$acl}{final} = 1;
			}

			# check array items and error if they are not a array
			# if undef, create a empty array
			my @keys_that_are_arrays = (
				'slugs',            'ua_regex_allow', 'ua_regex_deny', 'paths_regex_allow',
				'paths_regex_deny', 'slugs_regex',    'allow_subnets', 'deny_subnets',
			);
			foreach my $array_key (@keys_that_are_arrays) {
				if ( !defined( $opts{acl}{$acl}{$array_key} ) ) {
					$opts{acl}{$acl}{$array_key} = [];
				} elsif ( ref( $opts{acl}{$acl}{$array_key} ) ne 'ARRAY' ) {
					$self->{perror} = 1;
					$self->{error}  = 2;
					$self->{errorString}
						= '$opts{acl}{acl}{'
						. $array_key
						. '} is not ref ARRAY, but "'
						. ref( $opts{acl}{$acl}{$array_key} ) . '"';
					$self->warn;
					return;
				} ## end elsif ( ref( $opts{acl}{$acl}{$array_key} ) ne...)
			} ## end foreach my $array_key (@keys_that_are_arrays)
		} ## end foreach my $acl (@acl_keys)

		if ( !defined( $opts{acl}{'undef'} ) ) {
			$opts{acl}{'undef'} = {
				ip_auth           => 0,
				slug_auth         => 0,
				ua_auth           => 0,
				path_auth         => 0,
				require_ip        => 0,
				require_slug      => 0,
				require_ua        => 0,
				require_path      => 0,
				final             => 0,
				slugs             => [],
				slugs_regex       => [],
				allow_subnets     => [],
				deny_subnets      => [],
				ua_regex_allow    => [],
				ua_regex_deny     => [],
				paths_regex_allow => [],
				paths_regex_deny  => [],
			};
		} ## end if ( !defined( $opts{acl}{'undef'} ) )

		if ( !defined( $opts{acl}{'nonexistent'} ) ) {
			$opts{acl}{'nonexistent'} = {
				ip_auth           => 0,
				slug_auth         => 0,
				ua_auth           => 0,
				path_auth         => 0,
				require_ip        => 0,
				require_slug      => 0,
				require_ua        => 0,
				require_path      => 0,
				final             => 0,
				slugs             => [],
				slugs_regex       => [],
				allow_subnets     => [],
				deny_subnets      => [],
				ua_regex_allow    => [],
				ua_regex_deny     => [],
				paths_regex_allow => [],
				paths_regex_deny  => [],
			};
		} ## end if ( !defined( $opts{acl}{'nonexistent'} ))

		$self->{acl} = $opts{acl};
	} elsif ( defined( $opts{acl} ) && ref( $opts{acl} ) ne 'HASH' ) {
		$self->{perror}      = 1;
		$self->{error}       = 1;
		$self->{errorString} = '$opts{acl} is not ref HASH, but "' . ref( $opts{acl} ) . '"';
		$self->warn;
		return;
	}

	return $self;
} ## end sub new

=head2 check

    - apikey :: The API key to check for. If not specified it is set to 'undef'
            and if none match, the it is set to 'nonexistent'.
        - Default :: 'undef'

    - slugs :: An array of slugs to check again. All must match. If undef or none
            are specified, a value of 'undef' is added.
        - Default :: ['undef']

    - ip :: An IP to check for.
        - Default :: undef

=cut

sub check {
	my ( $self, %opts ) = @_;

	# set what API key we should check against
	# undef and nonexistent are two special ones set based on apikey being undef or not being a defined one
	if ( !defined( $opts{apikey} ) ) {
		$opts{apikey} = 'undef';
	} elsif ( !defined( $self->{acl}{ $opts{apikey} } ) ) {
		$opts{apikey} = 'nonexistent';
	}

	# get the slugs
	my @slugs;
	if ( !defined( $opts{slugs} ) ) {
		# no point in continuing if we require a slug and
		if ( $self->{acl}{ $opts{apikey} }{require_slug} ) {
			return 0;
		}
	} else {
		if ( ref( $opts{slugs} ) eq 'ARRAY' ) {
			push( @slugs, @{ $opts{slugs} } );
		} elsif ( ref( $opts{slugs} ) eq '' ) {
			push( @slugs, $opts{slugs} );
		}

		if ( $self->{acl}{ $opts{apikey} }{require_slug} && !defined( $slugs[0] ) ) {
			return 0;
		} elsif ( !defined( $slugs[0] ) ) {
			push( @slugs, 'undef' );
		}
	} ## end else [ if ( !defined( $opts{slugs} ) ) ]

	# ensure we have a UA if required
	my $ua;
	if ( !defined( $opts{ua} ) ) {
		if ( $self->{acl}{ $opts{apikey} }{require_ua} ) {
			return 0;
		}
	} else {
		$ua = $opts{ua};
	}

	# ensure we have a path if required
	my $path;
	if ( !defined( $opts{path} ) ) {
		if ( $self->{acl}{ $opts{apikey} }{require_path} ) {
			return 0;
		}
	} else {
		$path = $opts{path};
	}

	# ensure we have a IP if required
	my $ip;
	if ( !defined( $opts{ip} ) ) {
		if ( $self->{acl}{ $opts{apikey} }{require_ip} ) {
			return 0;
		}
	} else {
		$ip = $opts{ip};
	}

	# process IP
	if ( defined($ip) && $self->{acl}{ $opts{apikey} }{ip_auth} ) {
		my $denied_subnets;
		eval { $denied_subnets = subnet_matcher( @{ $self->{acl}{ $opts{apikey} }{deny_subnets} } ); };
		if ($@) {
			$self->{error} = 3;
			$self->{errorString}
				= 'creating subnet_matcher for deny_subnets for apikey "' . $opts{apikey} . '" failed... ' . $@;
			$self->warn;
			return 0;
		}
		if ( $denied_subnets->($ip) ) {
			return 0;
		}

		my $allowed_subnets;
		eval { $allowed_subnets = subnet_matcher( @{ $self->{acl}{ $opts{apikey} }{allow_subnets} } ); };
		if ($@) {
			$self->{error} = 3;
			$self->{errorString}
				= 'creating subnet_matcher for allow_subnets for apikey "' . $opts{apikey} . '" failed... ' . $@;
			$self->warn;
			return 0;
		}
		if ( !$allowed_subnets->($ip) ) {
			return 0;
		}
	} elsif ( !defined($ip) && $self->{acl}{ $opts{apikey} }{ip_auth} ) {
		return 0;
	}

	# process slugs
	if ( $self->{acl}{ $opts{apikey} }{slug_auth} ) {
		my %matched_slugs;

		# look for matching slugs
		foreach my $slug (@slugs) {
			foreach my $item ( @{ $self->{acl}{ $opts{apikey} }{slugs} } ) {
				if ( $item eq $slug ) {
					$matched_slugs{$slug} = 1;
				}
			}

			# only need to check regex if the previous did not match
			if ( !$matched_slugs{$slug} ) {
				foreach my $item ( @{ $self->{acl}{ $opts{apikey} }{slugs_regex} } ) {
					if ( $slug =~ /$item/ ) {
						$matched_slugs{$slug} = 1;
					}
				}
			}
		} ## end foreach my $slug (@slugs)

		# check for any slugs not matched
		foreach my $slug (@slugs) {
			if ( !$matched_slugs{$slug} ) {
				return 0;
			}
		}
	} ## end if ( $self->{acl}{ $opts{apikey} }{slug_auth...})

	# process useragent info
	if ( defined($ua) && $self->{acl}{ $opts{apikey} }{ua_auth} ) {
		# process allows if we have any
		if ( defined( $self->{acl}{ $opts{apikey} }{ua_regex_allow}[0] ) ) {
			my $ua_matched = 0;
			foreach my $item ( @{ $self->{acl}{ $opts{apikey} }{ua_regex_allow} } ) {
				eval {
					if ( $ua =~ /$item/ ) {
						$ua_matched = 1;
					}
				};
			}
			# if no allowed regexp matched, deny it
			if ( !$ua_matched ) {
				return 0;
			}
		} ## end if ( defined( $self->{acl}{ $opts{apikey} ...}))
		# process allows if we have any
		if ( defined( $self->{acl}{ $opts{apikey} }{ua_regex_deny}[0] ) ) {
			my $ua_matched = 0;
			foreach my $item ( @{ $self->{acl}{ $opts{apikey} }{ua_regex_dney} } ) {
				eval {
					if ( $ua =~ /$item/ ) {
						$ua_matched = 1;
					}
				};
			}
			# if any deny regexp matched, deny it
			if ($ua_matched) {
				return 0;
			}
		} ## end if ( defined( $self->{acl}{ $opts{apikey} ...}))
	} elsif ( !defined($ua) && $self->{acl}{ $opts{apikey} }{ua_auth} ) {
		return 0;
	}

	# process path info
	if ( defined($path) && $self->{acl}{ $opts{apikey} }{path_auth} ) {
		# process allows if we have any
		if ( defined( $self->{acl}{ $opts{apikey} }{path_regex_allow}[0] ) ) {
			my $path_matched = 0;
			foreach my $item ( @{ $self->{acl}{ $opts{apikey} }{path_regex_allow} } ) {
				eval {
					if ( $path =~ /$item/ ) {
						$path_matched = 1;
					}
				};
			}
			# if no allowed regexp matched, deny it
			if ( !$path_matched ) {
				return 0;
			}
		} ## end if ( defined( $self->{acl}{ $opts{apikey} ...}))
		# process allows if we have any
		if ( defined( $self->{acl}{ $opts{apikey} }{ua_regex_deny}[0] ) ) {
			my $path_matched = 0;
			foreach my $item ( @{ $self->{acl}{ $opts{apikey} }{path_regex_dney} } ) {
				eval {
					if ( $path =~ /$item/ ) {
						$path_matched = 1;
					}
				};
			}
			# if any deny regexp matched, deny it
			if ($path_matched) {
				return 0;
			}
		} ## end if ( defined( $self->{acl}{ $opts{apikey} ...}))
	} elsif ( !defined($path) && $self->{acl}{ $opts{apikey} }{path_auth} ) {
		return 0;
	}

	return $self->{acl}{ $opts{apikey} }{final};
} ## end sub check

=head1 ACL HASH

The ACL hash is a hash of hashes. The keys for primary hash are API keys. The keys
for the subhashes are as below.

Slugs should be though of a freeform text field for access check. Function name or whatever.

    - ip_auth :: Use IP for authing. If false, the IP will not be checked.
        - Default :: 0

    - path_auth :; Use the path for authing. If false it won't be checked.
        - Default :: 0

    - slug_auth :; Use the slug for authing. If false it won't be checked.
        - Default :: 0

    - ua_auth :; Use the UA for authing. If false it won't be checked.
        - Default :: 0

    - require_ip :: Require a value for IP to be specified.
        - Default :: 0

    - require_path :: Require a value for path to be specified.
        - Default :: 0

    - require_slug :: Require a value for slug to be specified.
        - Default :: 0

    - require_slug :: Require a value for UA to be specified.
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

    - paths_regex_allow :: Allowed paths.
        - Default :: []

    - paths_regex_deny :: Denied paths.
        - Default :: []

    - ua_regex_allow :: Allowed UAs.
        - Default :: []

    - ua_regex_deny :: Denied UAs.
        - Default :: []

There are two special ones for the ACL hash. Those are 'undef' and 'nonexistent'
and they should not be used as API keys. These are for in the instances that
the apikey for the checkis undef or if specified and does not exist 'nonexistent'
is used.

By default they are as below.

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

=head1 ERROR CODES / FLAGS

=head2 1, ACLnotHash

'acl' as passed to new is not of the of the ref type 'HASH'.

=head2 2, ACLitemNotArray

The expected item is expected to be of the ref type ARRAY.

=head2 3, subnetError

Could not init sub_matcher.

=head2 4, ACLnotString

'acl' as passed to new is not of the of the ref type ''.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-web-acl at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Web-ACL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Web::ACL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Web-ACL>

=item * Search CPAN

L<https://metacpan.org/release/Web-ACL>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991


=cut

1;    # End of Web::ACL
