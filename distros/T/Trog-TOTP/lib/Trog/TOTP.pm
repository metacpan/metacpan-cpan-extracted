package Trog::TOTP 1.005;

use strict;
use warnings;

use 5.006;
use v5.14.0;    # Before 5.006, v5.10.0 would not be understood.

# ABSTRACT: Fork of Authen::TOTP

use Ref::Util qw{is_coderef is_hashref};
use Digest::SHA();
use Encode::Base2N();
use List::Util qw{first};
use POSIX qw{floor};

use Carp::Always;



sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $self  = {};
    bless $self, $class;

    return $self->_initialize(@_);
}

sub _initialize {
    my $self = shift;

    $self->{DEBUG} //= 0;

    if ( @_ != 0 ) {
        if ( is_hashref( $_[0] ) ) {
            my $hash = $_[0];
            foreach ( keys %$hash ) {
                $self->{ lc $_ } = $hash->{$_};
            }
        }
        elsif ( !( scalar(@_) % 2 ) ) {
            my %hash = @_;
            foreach ( keys %hash ) {
                $self->{ lc $_ } = $hash{$_};
            }
        }
    }

    $self->_valid_digits();
    $self->_valid_period();
    $self->_valid_algorithm();
    $self->_valid_when();
    $self->_valid_tolerance();
    $self->_valid_secret();

    return $self;
}


sub _logger {
    my $self = shift;
    return $self->{logger}->(@_) if is_coderef( $self->{logger} );
    warn @_;
}

sub _debug_print {
    my $self = shift;
    return unless $self->{DEBUG};
    $self->_logger(@_);

    return 1;
}

sub _process_sub_arguments {
    my $self = shift;

    my $args  = shift;
    my $wants = shift;
    my @rets;

    if ( @$args != 0 ) {
        if ( is_hashref( $args->[0] ) ) {
            foreach my $want (@$wants) {
                push @rets, $args->[0]->{$want};
            }
        }
        elsif ( !( scalar(@$args) % 2 ) ) {
            my %hash = @$args;
            foreach my $want (@$wants) {
                push @rets, $hash{$want};
            }
        }
    }
    return @rets;
}

sub _valid_digits {
    my $self   = shift;
    my $digits = shift;

    if ( $digits && $digits =~ m|^[68]$| ) {
        $self->{digits} = $digits;
    }
    elsif ( !defined( $self->{digits} ) || $self->{digits} !~ m|^[68]$| ) {
        $self->{digits} = 6;
    }
    1;
}

sub _valid_period {
    my $self   = shift;
    my $period = shift;

    if ( $period && $period =~ m|^[36]0$| ) {
        $self->{period} = $period;
    }
    elsif ( !defined( $self->{period} ) || $self->{period} !~ m|^[36]0$| ) {
        $self->{period} = 30;
    }
    1;
}

sub _valid_algorithm {
    my $self      = shift;
    my $algorithm = shift;

    if ( $algorithm && $algorithm =~ m|^SHA\d+$| ) {
        $self->{algorithm} = $algorithm;
    }
    elsif ( !defined( $self->{algorithm} ) || $self->{algorithm} !~ m|^SHA\d+$| ) {
        $self->{algorithm} = "SHA1";
    }
    1;
}

sub _valid_when {
    my $self = shift;
    my $when = shift;

    if ( $when && $when =~ m|^\-?\d+$| ) {    #negative epoch is valid, though not sure how useful :)
        $self->{when} = $when;
    }
    elsif ( !defined( $self->{when} ) || $self->{when} !~ m|^\-?\d+$| ) {
        $self->{when} = time;
    }
    1;
}

sub _valid_tolerance {
    my $self      = shift;
    my $tolerance = shift;

    if ( $tolerance && $tolerance =~ m|^\d+$| && $tolerance > 0 ) {
        $self->{tolerance} = ( $tolerance - 1 );
    }
    elsif ( !defined( $self->{tolerance} ) || $self->{tolerance} !~ m|^\d+$| ) {
        $self->{tolerance} = 0;
    }
    1;
}

sub _valid_secret {
    my $self = shift;
    my ( $secret, $base32secret ) = @_;

    if ($secret) {
        $self->{secret} = $secret;
    }
    elsif ($base32secret) {
        $self->{secret} = Encode::Base2N::decode_base32($base32secret);
    }
    else {
        if ( defined( $self->{base32secret} ) ) {
            $self->{secret} = Encode::Base2N::decode_base32( $self->{base32secret} );
        }
        else {
            if ( defined( $self->{algorithm} ) ) {
                if ( $self->{algorithm} eq "SHA512" ) {
                    $self->{secret} = $self->_gen_secret(64);
                }
                elsif ( $self->{algorithm} eq "SHA256" ) {
                    $self->{secret} = $self->_gen_secret(32);
                }
                else {
                    $self->{secret} = $self->_gen_secret(20);
                }
            }
            else {
                $self->{secret} = $self->_gen_secret(20);
            }
        }
    }

    $self->{base32secret} = Encode::Base2N::encode_base32( $self->{secret} );
    1;
}


sub secret {
    my $self = shift;
    return $self->{secret};
}


sub base32secret {
    my $self = shift;
    return $self->{base32secret};
}


sub algorithm {
    my $self      = shift;
    my $algorithm = shift;
    $self->_valid_algorithm($algorithm) if $algorithm;

    return $self->{algorithm};
}

sub _hmac {
    my $self = shift;
    my $Td   = shift;
    if ( $self->{algorithm} eq 'SHA512' ) {
        return Digest::SHA::hmac_sha512_hex( $Td, $self->{secret} );
    }
    elsif ( $self->{algorithm} eq 'SHA256' ) {
        return Digest::SHA::hmac_sha256_hex( $Td, $self->{secret} );
    }
    else {
        return Digest::SHA::hmac_sha1_hex( $Td, $self->{secret} );
    }
}


sub expected_totp_code {
    my ( $self, $when ) = @_;
    $self->_debug_print( "using when $when (" . ( $when - $self->{when} ) . ")" );

    my $T  = sprintf( "%016x", int( $when / $self->{period} ) );
    my $Td = pack( 'H*', $T );

    my $hmac = $self->_hmac($Td);

    # take the 4 least significant bits (1 hex char) from the encrypted string as an offset
    my $offset = hex( substr( $hmac, -1 ) );

    # take the 4 bytes (8 hex chars) at the offset (* 2 for hex), and drop the high bit
    my $encrypted = hex( substr( $hmac, $offset * 2, 8 ) ) & 0x7fffffff;

    return sprintf( "%0" . $self->{digits} . "d", ( $encrypted % ( 10**$self->{digits} ) ) );
}


sub time_for_code {
    my ( $self, $code, $now, $period ) = @_;
    chomp $code;
    $now //= time;
    $period //= 86400;
    my @past   = map { $now - ($_ * $self->{period}) } 0 .. floor($period / $self->{period});
    my @future = map { $now + ($_ * $self->{period}) } 0 .. floor($period / $self->{period});
    return first { $self->expected_totp_code($_) == $code } (@past, @future);
    return;
}

sub _gen_secret {
    my $self   = shift;
    my $length = shift || 20;

    my $secret;
    ## no critic (Variables::RequireLexicalLoopIterators)
    for ( 0 .. int( rand($length) ) + $length ) {
        $secret .= join '', ( '/', 1 .. 9, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '_', '+', '=', 'A' .. 'H', 'J' .. 'N', 'P' .. 'Z', 'a' .. 'h', 'm' .. 'z' )[ rand 58 ];
    }
    if ( length($secret) > ( $length + 1 ) ) {
        $self->_debug_print( "have len " . length($secret) . " ($secret) so cutting down" );
        return substr( $secret, 0, $length );
    }
    return $secret;
}


sub generate_otp {
    my $self = shift;
    my ( $digits, $period, $algorithm, $secret, $base32secret, $issuer, $user ) =
      $self->_process_sub_arguments( \@_, [ 'digits', 'period', 'algorithm', 'secret', 'base32secret', 'issuer', 'user' ] );

    unless ($user) {
        die "need user to use as prefix in generate_otp()";
    }

    $self->_valid_digits($digits);
    $self->_valid_period($period);
    $self->_valid_algorithm($algorithm);
    $self->_valid_secret( $secret, $base32secret );

    if ($issuer) {
        $issuer = qq[&issuer=] . $issuer;
    }
    else {
        $issuer = '';
    }

    return qq[otpauth://totp/$user?secret=] . $self->{base32secret} . qq[&algorithm=] . $self->{algorithm} . qq[&digits=] . $self->{digits} . qq[&period=] . $self->{period} . $issuer;
}


sub validate_otp {
    my $self = shift;
    my ( $digits, $period, $algorithm, $secret, $when, $tolerance, $base32secret, $otp, $return_when ) =
      $self->_process_sub_arguments( \@_, [ 'digits', 'period', 'algorithm', 'secret', 'when', 'tolerance', 'base32secret', 'otp', 'return_when' ] );

    unless ( $otp && $otp =~ m|^\d{6,8}$| ) {
        $otp ||= "";
        die "invalid otp $otp passed to validate_otp()";
    }

    $self->_valid_digits($digits);
    $self->_valid_period($period);
    $self->_valid_algorithm($algorithm);
    $self->_valid_when($when);
    $self->_valid_tolerance($tolerance);
    $self->_valid_secret( $secret, $base32secret );

    my $tperiod = $self->{tolerance} * $self->{period};
    my $res = $self->time_for_code( $otp, $when, $tperiod );
    return $res if $return_when;
    return $res ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Trog::TOTP - Fork of Authen::TOTP

=head1 VERSION

version 1.005

=head1 DESCRIPTION

C<Trog::TOTP> is a fork of C<Authen::TOTP>.

While patches were initially merged upstream, no CPAN releases happened, so here we are.

Also includes a bin/ script totp_debugger to help you debug situations where TOTP isn't working for your users.

=head1 NAME

Trog::TOTP - Interface to RFC6238 two factor authentication (2FA)

=head1 USAGE

 my $gen = Trog::TOTP->new(
     # not needed when setting up TOTP for the first time;
     # we generate a secret automatically which you should grab and store.
	 secret		=>	"some_random_stuff",
     # ACHTUNG! lots of TOTP apps on various devices ignore this field
     # and hardcode 30s periods.  Probably best to never touch this.
     period     => 30,
     # callback used when emitting messages;
     # use me for integrating into your own logging framework
     logger     => sub { my $msg = shift; ... },
 );

 # Be sure to store this as binary data
 my $secret = $gen->secret();

 # This is what you will want to show users for input into their TOTP apps when their camera is failing
 my $b32secret = $gen->base32secret();

 # will generate a TOTP URI, suitable to use in a QR Code
 my $uri = $gen->generate_otp(user => 'user\@example.com', issuer => "example.com");

 # use Imager::QRCode to plot the secret for the user
 use Imager::QRCode;
 my $qrcode = Imager::QRCode->new(
       size          => 4,
       margin        => 3,
       level         => 'L',
       casesensitive => 1,
       lightcolor    => Imager::Color->new(255, 255, 255),
       darkcolor     => Imager::Color->new(0, 0, 0),
 );

 my $img = $qrcode->plot($uri);
 $img->write(file => "totp.png", type => "png");

 # compare user's OTP with computed one
 if ($gen->validate_otp(otp => <user_input>, secret => <stored_secret>, tolerance => 1)) {
	#2FA success
 }
 else {
	#no match
 }

  # Just print out the dang code
  print $gen->expected_totp_code(time);

  # For when your users just can't seem to get it to work (100% chance of this)
  # This is the only way to have them dead to rights that their clock is wrong, or they have the wrong code
  print $gen->time_for_code($code);

=head1 CONSTRUCTOR

=head2 new

 my $gen = Trog::TOTP->new(
	 digits 	=>	[6|8],
	 period		=>	[30|60],
	 algorithm	=>	"SHA1", #SHA256 and SHA512 are equally valid
	 secret		=>	"some_random_stuff",
	 when		=>	<some_epoch>,
	 tolerance	=>	0,
     logger     => sub { my $msg=shift; ... },
 );

=head2 Parameters/Properties (defaults listed)

=over 4

=item digits

C<6>=> How many digits to produce/compare

=item period

C<30>=> OTP is valid for this many seconds

=item algorithm

C<SHA1>=> supported values are SHA1, SHA256 and SHA512, although most clients only support SHA1 AFAIK

=item secret

C<random_20byte_string>=> Secret used as seed for the OTP

=item base32secret

C<base32_encoded_random_12byte_string>=> Alternative way to set secret (base32 encoded)

=item when

C<epoch>=> Time used for comparison of OTPs

=item tolerance

C<1>=> Due to time sync issues, you may want to tune this and compare
this many OTPs before and after

=item logger

Log callback subroutine.  Use to integrate various messages from this modules into your logging framework.

=item DEBUG

Turn on extended log messaging.

=back

=head1 METHODS

=head2 secret

Return the current secret used by this object.

=head2 base32secret

Return the base32encoded secret used by this object.

=head2 algorithm([STRING $algo])

Returns, and optionally sets the algorithm if passed.

=head2 expected_totp_code( TIME_T $when )

Returns what a code "ought" to be at any given unix timestamp.
Useful for integrating into command line tooling to fix things when people have "tecmological differences" with their telephone.

=head2 time_for_code( STRING $code, TIME_T $when, TIME_T $period )

Search at what time during the prior (or future!) period (default 24 hrs) about $when in which the provided code is valid
This is useful for dealing with users that just inexplicably fail due to bad clocks

Returns undef in the event the code is not valid for the period, in which case their scan of a QR was bogus, or their validator app is buggy.

=head2 generate_otp

Create a TOTP URI using the parameters specified or the defaults from
the new() method above

Usage:

 $gen->generate_otp(
	 digits 	=>	[6|8],
	 period		=>	[30|60],
	 algorithm	=>	"SHA1", #SHA256 and SHA512 are equally valid
	 secret		=>	"some_random_stuff",
	 issuer		=>	"example.com",
	 user		=>	"some_identifier",
 );

 Google Authenticator displays <issuer> (<user>) for a TOTP generated like this

=head2 validate_otp

Compare a user-supplied TOTP using the parameters specified. Obviously the secret
MUST be the same secret you used in generate_otp() above/
Returns 1 on success, undef if OTP doesn't match

Usage:

 $gen->validate_otp(
	 digits 	 =>	[6|8],
	 period		 =>	[30|60],
	 algorithm	 =>	"SHA1", #SHA256 and SHA512 are equally valid
	 secret		 =>	"the_same_random_stuff_you_used_to_generate_the_TOTP",
	 when		 =>	<epoch_to_use_as_reference>,
	 tolerance	 =>	<try this many iterations before/after when>
	 otp		 =>	<OTP to compare to>
     return_when => Boolean.  When high, return true or false.  Otherwise return the time @ which the code was valid (useful for tolerance > 1).
 );

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/teodesian/Trog-TOTP/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <teodesian@gmail.com>

=back

=head1 CONTRIBUTOR

=for stopwords Thanos Chatziathanassiou

Thanos Chatziathanassiou <tchatzi@arx.net>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2023 Troglodyne LLC

The "Artistic License"
Preamble
The intent of this document is to state the conditions under which a
Package may be copied, such that the Copyright Holder maintains some
semblance of artistic control over the development of the package,
while giving the users of the package the right to use and distribute
the Package in a more-or-less customary fashion, plus the right to make
reasonable modifications.
Definitions:
"Package" refers to the collection of files distributed by the
Copyright Holder, and derivatives of that collection of files
created through textual modification.
"Standard Version" refers to such a Package if it has not been
modified, or has been modified in accordance with the wishes
of the Copyright Holder as specified below.
"Copyright Holder" is whoever is named in the copyright or
copyrights for the package.
"You" is you, if you're thinking about copying or distributing
this Package.
"Reasonable copying fee" is whatever you can justify on the
basis of media cost, duplication charges, time of people involved,
and so on.  (You will not be required to justify it to the
Copyright Holder, but only to the computing community at large
as a market that must bear the fee.)
"Freely Available" means that no fee is charged for the item
itself, though there may be fees involved in handling the item.
It also means that recipients of the item may redistribute it
under the same conditions they received it.
1. You may make and give away verbatim copies of the source form of the
Standard Version of this Package without restriction, provided that you
duplicate all of the original copyright notices and associated disclaimers.
2. You may apply bug fixes, portability fixes and other modifications
derived from the Public Domain or from the Copyright Holder.  A Package
modified in such a way shall still be considered the Standard Version.
3. You may otherwise modify your copy of this Package in any way, provided
that you insert a prominent notice in each changed file stating how and
when you changed that file, and provided that you do at least ONE of the
following:
a) place your modifications in the Public Domain or otherwise make them
Freely Available, such as by posting said modifications to Usenet or
an equivalent medium, or placing the modifications on a major archive
site such as uunet.uu.net, or by allowing the Copyright Holder to include
your modifications in the Standard Version of the Package.
b) use the modified Package only within your corporation or organization.
c) rename any non-standard executables so the names do not conflict
with standard executables, which must also be provided, and provide
a separate manual page for each non-standard executable that clearly
documents how it differs from the Standard Version.
d) make other distribution arrangements with the Copyright Holder.
4. You may distribute the programs of this Package in object code or
executable form, provided that you do at least ONE of the following:
a) distribute a Standard Version of the executables and library files,
together with instructions (in the manual page or equivalent) on where
to get the Standard Version.
b) accompany the distribution with the machine-readable source of
the Package with your modifications.
c) give non-standard executables non-standard names, and clearly
document the differences in manual pages (or equivalent), together
with instructions on where to get the Standard Version.
d) make other distribution arrangements with the Copyright Holder.
5. You may charge a reasonable copying fee for any distribution of this
Package.  You may charge any fee you choose for support of this
Package.  You may not charge a fee for this Package itself.  However,
you may distribute this Package in aggregate with other (possibly
commercial) programs as part of a larger (possibly commercial) software
distribution provided that you do not advertise this Package as a
product of your own.  You may embed this Package's interpreter within
an executable of yours (by linking); this shall be construed as a mere
form of aggregation, provided that the complete Standard Version of the
interpreter is so embedded.
6. The scripts and library files supplied as input to or produced as
output from the programs of this Package do not automatically fall
under the copyright of this Package, but belong to whoever generated
them, and may be sold commercially, and may be aggregated with this
Package.  If such scripts or library files are aggregated with this
Package via the so-called "undump" or "unexec" methods of producing a
binary executable image, then distribution of such an image shall
neither be construed as a distribution of this Package nor shall it
fall under the restrictions of Paragraphs 3 and 4, provided that you do
not represent such an executable image as a Standard Version of this
Package.
7. C subroutines (or comparably compiled subroutines in other
languages) supplied by you and linked into this Package in order to
emulate subroutines and variables of the language defined by this
Package shall not be considered part of this Package, but are the
equivalent of input as in Paragraph 6, provided these subroutines do
not change the language in any way that would cause it to fail the
regression tests for the language.
8. Aggregation of this Package with a commercial distribution is always
permitted provided that the use of this Package is embedded; that is,
when no overt attempt is made to make this Package's interfaces visible
to the end user of the commercial distribution.  Such use shall not be
construed as a distribution of this Package.
9. The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written permission.
10. THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
The End[-Transformer]

=cut
