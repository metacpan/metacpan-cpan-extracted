package Validate::Yubikey;

our $VERSION = '0.03';

=head1 NAME

Validate::Yubikey - Validate Yubikey OTPs

=head1 SYNOPSIS

    use Validate::Yubikey;

    sub validate_callback {
        my $public_id = shift;

        return {
            iid => $iid,
            key => $key,
            count => $count,
            use => $use,
            lastuse => $lastuse,
            lastts => $lastts,
        };
    }

    sub update_callback {
        my ($public_id, $data) = @_;
    }

    sub log_message {
        print shift, "\n";
    }

    my $yubi = Validate::Yubikey->new(
        callback => \&validate_callback,
        update_callback => \&update_callback,
        log_callback => \&log_message,
    );

    my $otp_valid = $yubi->validate("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx");

=head1 DESCRIPTION

The Yubikey is a hardware OTP token produced by Yubico (L<http://www.yubico.com>).

This module provides validation of Yubikey OTPs.  It relies on you to specify
callback functions that handle retrieving token information from somewhere and
updating the persistent information associated with each token.

=cut

use Carp;
use Crypt::Rijndael;

sub hex2modhex {
    my $s = shift;
    $s =~ tr/0123456789abcdef/cbdefghijklnrtuv/;
    return $s;
}

sub modhex2hex {
    my $s = shift;
    $s =~ tr/cbdefghijklnrtuv/0123456789abcdef/;
    return $s;
}

sub yubicrc {
    my $data = shift;
    my $crc = 0xffff;

    foreach my $h (unpack('H2' x 16, $data)) {
        my $d = hex($h);
        $crc = $crc ^ ($d & 0xff);
        for (1..8) {
            my $n = $crc & 1;
            $crc = $crc >> 1;
            if ($n != 0) {
                $crc = $crc ^ 0x8408;
            }
        }
    }
    
    return $crc;
}

=head1 METHODS

=head2 new

Create a new Validate::Yubikey instance.

=over 4

=item callback

Required.

=item update_callback

Required.

=item log_callback

Optional.

=back

=cut

sub new {
    my ($class, %data) = @_;
    my $self = {};
    bless $self, $class;

    if (exists $data{callback} && ref($data{callback}) eq 'CODE') {
        $self->{callback} = $data{callback};
    } else {
        croak __PACKAGE__, '->new called without callback';
    }

    if (exists $data{update_callback} && ref($data{update_callback}) eq 'CODE') {
        $self->{update_callback} = $data{update_callback};
    } else {
        croak __PACKAGE__, '->new called without update_callback';
    }

    if (exists $data{log_callback} && ref($data{log_callback}) eq 'CODE') {
        $self->{log_callback} = $data{log_callback};
    } else {
        $self->{log_callback} = sub {};
    }

    if ($data{max_age}) {
        $self->{max_age} = $data{max_age};
    } else {
        $self->{max_age} = 60;
    }

    return $self;
}

=head2 validate

=over 4

=item Arguments: $otp, @callback_args

=item Return Value: $success

=back

Validate an OTP.

=cut

sub validate {
    my ($self, $otp, @cbargs) = @_;

    if ($otp =~ /^([cbdefghijklnrtuv]{0,16})([cbdefghijklnrtuv]{32})$/) {
        my ($public_id, $cipher) = ($1, $2);

        my $token = $self->{callback}->($public_id, @cbargs);

        if (!$token) {
            $self->{log_callback}->(sprintf('callback returned no token for pid %s', $public_id));
            return 0;
        }

        foreach my $k (qw/key count iid lastuse lastts use/) {
            if (!defined($token->{$k})) {
                carp "callback didn't return $k";
                return 0;
            }
        }

        $cipher = &modhex2hex($cipher);

        my $crypt = Crypt::Rijndael->new(pack('H*', $token->{key}));
        my $plaintext = $crypt->decrypt(pack('H*', $cipher));
		unless (length $plaintext) {
			carp 'decrypt failed';
			return 0;
		}
        my $plainhex = unpack('H*', $plaintext);

        if (substr($plainhex, 0, length($token->{iid})) eq $token->{iid}) {
            my $crc = &yubicrc($plaintext);

            if ($crc == 0xf0b8) {
                my $count = hex(substr($plainhex, 14, 2).substr($plainhex, 12, 2));
                my $use = hex(substr($plainhex, 22, 2));
                my $low = substr($plainhex, 18, 2).substr($plainhex, 16, 2);
                my $high = substr($plainhex, 20, 2);
                my $ts = ((hex($high) << 16) + hex($low)) / 8; # XXX magic

                my $tinfo = sprintf('iid=%s, count=%d, use=%d, ts=%d', $token->{iid}, $count, $use, $ts);
                my $tsnow = $token->{lastts} + (time() - $token->{lastuse});
                my $tsage = $tsnow - $ts;
                $self->{update_callback}->($public_id, { lastuse => time(), lastts => $ts });

                if ($count < $token->{count}) {
                    $self->{log_callback}->(sprintf('token %s failed: duplicate otp, count (%s)', $public_id, $tinfo));
                } elsif ($count == $token->{count}) {
                    if ($use <= $token->{use}) {
                        $self->{log_callback}->(sprintf('token %s failed: duplicate otp in same session (%s)', $public_id, $tinfo));
                    } elsif ($tsage > $self->{max_age}) {
                        $self->{log_callback}->(sprintf('token %s failed: expired otp is %d seconds old (%s)', $public_id, $tsage, $tinfo));
                    } else {
                        $self->{log_callback}->(sprintf('token %s ok, same session (%s)', $public_id, $tinfo));
                        $self->{update_callback}->($public_id, { count => $count, use => $use });
                        return 1;
                    }
                } elsif ($count > $token->{count}) {
                    $self->{log_callback}->(sprintf('token %s ok (%s)', $public_id, $tinfo));
                    $self->{update_callback}->($public_id, { count => $count, use => $use });
                    return 1;
                } else {
                    $self->{log_callback}->(sprintf('something bad with token %s (%s)', $public_id, $tinfo));
                }
            } else {
                $self->{log_callback}->(sprintf('token %s failed: corrupt otp (crc)', $public_id));
            }
        } else {
            $self->{log_callback}->(sprintf('token %s failed: corrupt otp (internal id)', $public_id));
        }
    } else {
        $self->{log_callback}->(sprintf('token %s failed: invalid otp', $public_id));
    }

    return 0;
}

=head1 CALLBACKS

=head2 callback

=over 4

=item Receives: $public_id, @callback_args

=item Returns: \%token_data

=back

Called during validation when information about the token is required.
Receives the public ID of the Yubikey.  It's expected that your subroutine
returns a hash reference containing the following keys:

=over 4

=item iid - Internal ID

=item key - Secret key

=back

Plus the four values stored by the L<update_callback>.

=head2 update_callback

=over 4

=item Receives: $public_id, \%token_data, @callback_args

=item Returns: nothing

=back

Called to update the persistent storage of token parameters that enable replay
protection.  C<%token_data> will contain one or more of the following keys,
which should be associated with the supplied C<$public_id>:

=over 4

=item count

=item use

=item lastuse

=item lastts

=back

These should all be integers.

=head2 log_callback

=over 4

=item Receives: $log_message

=item Returns: nothing

=back

Called with messages produced during validation.  If not supplied to L<new>,
logging will disabled.

=head1 EXAMPLE

Here's a simple program that uses L<DBIx::Class> to store token information.

    package YKKSM::DB::Token;
    use base qw/DBIx::Class/;
    
    __PACKAGE__->load_components(qw/PK::Auto Core/);
    __PACKAGE__->table('token');
    __PACKAGE__->add_columns(qw/uid pid iid key count use lastuse lastts/);
    __PACKAGE__->set_primary_key('uid');
    
    package YKKSM::DB;
    use base qw/DBIx::Class::Schema/;
    
    __PACKAGE__->load_classes(qw/Token/);
    
    package YKTest;
    use Validate::Yubikey;
    
    my $schema = YKKSM::DB->connect("dbi:SQLite:dbname=yktest.db");
    
    my $yk = Validate::Yubikey->new(
        callback => sub {
            my $pid = shift;
            my $token = $schema->resultset('Token')->find({ pid => $pid });
    
            if ($token) {
                return {
                    iid => $token->iid,
                    key => $token->key,
                    count => $token->count,
                    use => $token->use,
                    lastuse => $token->lastuse,
                    lastts => $token->lastts,
                };
            } else {
                return undef;
            }
        },
        update_callback => sub {
            my ($pid, $data) = @_;
            my $token = $schema->resultset('Token')->find({ pid => $pid });
            if ($token) {
                $token->update($data);
            } else {
                die "asked to update nonexistent token $pid";
            }
        },
        log_callback => sub {
            print shift, "\n";
        },
    );
    
    if ($yk->validate($ARGV[0])) {
        print "success!\n";
    } else {
        print "failure 8(\n";
    }

=head1 AUTHOR

Ben Wilber <ben@desync.com>

But most of this module was derived from Yubico's PHP stuff.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut

1;
