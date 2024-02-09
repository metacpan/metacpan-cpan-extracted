package Web::ACL;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use Net::Subnet;

=head1 NAME

Web::ACL - A helper for creating basic apikey/slug/IP based ACLs.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';

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


=head1 METHODS

=head2 new

Initiates the object.

    - acl :: The ACL hash to use.
        - Default :: {
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
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		acl => {
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
		},
	};
	bless $self;

	if ( defined( $opts{acl} ) && ref( $opts{acl} ) eq 'HASH' ) {

		my @acl_keys = keys( %{ $opts{acl} } );
		foreach my $acl (@acl_keys) {
			if ( !defined( $opts{acl}{$acl}{ip_auth} ) ) {
				$opts{acl}{$acl}{ip_auth} = 0;
			}

			if ( !defined( $opts{acl}{$acl}{slug_auth} ) ) {
				$opts{acl}{$acl}{slug_auth} = 0;
			}

			if ( !defined( $opts{acl}{$acl}{require_ip} ) ) {
				$opts{acl}{$acl}{require_ip} = 0;
			}

			if ( !defined( $opts{acl}{$acl}{require_slug} ) ) {
				$opts{acl}{$acl}{require_slug} = 0;
			}

			if ( !defined( $opts{acl}{$acl}{final} ) && ( $acl eq 'undef' || $acl eq 'nonexistent' ) ) {
				$opts{acl}{$acl}{final} = 0;
			} elsif ( !defined( $opts{acl}{$acl}{final} ) ) {
				$opts{acl}{$acl}{final} = 1;
			}

			if ( !defined( $opts{acl}{$acl}{slugs} ) ) {
				$opts{acl}{$acl}{slugs} = [];
			} elsif ( ref( $opts{acl}{$acl}{slugs} ) ne 'ARRAY' ) {
				$self->{perror} = 1;
				$self->{error}  = 2;
				$self->{errorString}
					= '$opts{acl}{acl}{slugs} is not ref ARRAY, but "' . ref( $opts{acl}{$acl}{slugs} ) . '"';
				$self->warn;
				return;
			}

			if ( !defined( $opts{acl}{$acl}{slugs_regex} ) ) {
				$opts{acl}{$acl}{slugs_regex} = [];
			} elsif ( ref( $opts{acl}{$acl}{slugs_regex} ) ne 'ARRAY' ) {
				$self->{perror}      = 1;
				$self->{error}       = 2;
				$self->{errorString} = '$opts{acl}{acl}{slugs_regex} is not ref ARRAY, but "'
					. ref( $opts{acl}{$acl}{slugs_regex} ) . '"';
				$self->warn;
				return;
			}

			if ( !defined( $opts{acl}{$acl}{slugs_regex} ) ) {
				$opts{acl}{$acl}{deny_subnets} = [];
			} elsif ( ref( $opts{acl}{$acl}{slugs_regex} ) ne 'ARRAY' ) {
				$self->{perror}      = 1;
				$self->{error}       = 2;
				$self->{errorString} = '$opts{acl}{acl}{slugs_regex} is not ref ARRAY, but "'
					. ref( $opts{acl}{$acl}{slugs_regex} ) . '"';
				$self->warn;
				return;
			}

			if ( !defined( $opts{acl}{$acl}{allow_subnets} ) ) {
				$opts{acl}{$acl}{allow_subnets} = [];
			} elsif ( ref( $opts{acl}{$acl}{allow_subnets} ) ne 'ARRAY' ) {
				$self->{perror}      = 1;
				$self->{error}       = 2;
				$self->{errorString} = '$opts{acl}{acl}{allow_subnets} is not ref ARRAY, but "'
					. ref( $opts{acl}{$acl}{allow_subnets} ) . '"';
				$self->warn;
				return;
			}

			if ( !defined( $opts{acl}{$acl}{deny_subnets} ) ) {
				$opts{acl}{$acl}{deny_subnets} = [];
			} elsif ( ref( $opts{acl}{$acl}{deny_subnets} ) ne 'ARRAY' ) {
				$self->{perror}      = 1;
				$self->{error}       = 2;
				$self->{errorString} = '$opts{acl}{acl}{deny_subnets} is not ref ARRAY, but "'
					. ref( $opts{acl}{$acl}{deny_subnets} ) . '"';
				$self->warn;
				return;
			}
		} ## end foreach my $acl (@acl_keys)

		if ( !defined( $opts{acl}{'undef'} ) ) {
			$opts{acl}{'undef'} = {
				ip_auth       => 0,
				slug_auth     => 0,
				require_ip    => 0,
				require_slug  => 0,
				final         => 0,
				slugs         => [],
				slugs_regex   => [],
				allow_subnets => [],
				deny_subnets  => [],
			};
		} ## end if ( !defined( $opts{acl}{'undef'} ) )

		if ( !defined( $opts{acl}{'nonexistent'} ) ) {
			$opts{acl}{'nonexistent'} = {
				ip_auth       => 0,
				slug_auth     => 0,
				require_ip    => 0,
				require_slug  => 0,
				final         => 0,
				slugs         => [],
				slugs_regex   => [],
				allow_subnets => [],
				deny_subnets  => [],
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

	if ( !defined( $opts{apikey} ) ) {
		$opts{apikey} = 'undef';
	} elsif ( !defined( $self->{acl}{ $opts{apikey} } ) ) {
		$opts{apikey} = 'nonexistent';
	}

	my @slugs;
	if ( !defined( $opts{slugs} ) ) {
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

	my $ip;
	if ( !defined( $opts{ip} ) ) {
		if ( $self->{acl}{ $opts{apikey} }{require_ip} ) {
			return 0;
		}
	} else {
		$ip = $opts{ip};
	}

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

	return $self->{acl}{ $opts{apikey} }{final};
} ## end sub check

=head1 ACL HASH

The ACL hash is a hash of hashes. The keys for primary hash are API keys. The keys
for the subhashes are as below.

Slugs should be though of a freeform text field for access check. Function name or whatever.

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
