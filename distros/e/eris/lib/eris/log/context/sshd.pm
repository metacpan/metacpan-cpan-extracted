package eris::log::context::sshd;

use Const::Fast;
use Moo;
use namespace::autoclean;

with qw(
    eris::role::context
);

# Constants
const my %RE => (
    extract_details => qr/(?:Accepted|Failed) (\S+) for (\S+) from (\S+) port (\S+) (\S+)/,
);
const my %F => (
    extract_details => [qw(driver acct src_ip src_port proto_app)],
);

sub sample_messages {
    my @msgs = split /\r?\n/, <<EOF;
Jul 26 15:47:32 ether sshd[30700]: Accepted password for canuck from 2.82.66.219 port 54085 ssh2
Jul 26 15:47:32 ether sshd[30700]: pam_unix(sshd:session): session opened for user canuck by (uid=0)
Jul 26 15:50:14 ether sshd[4291]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=43.229.53.60  user=root
Jul 26 15:50:16 ether sshd[4291]: Failed password for root from 43.229.53.60 port 57806 ssh2
Jul 26 15:50:18 ether sshd[4291]: Failed password for root from 43.229.53.60 port 57806 ssh2
Jul 26 15:50:21 ether sshd[4291]: Failed password for root from 43.229.53.60 port 57806 ssh2
Jul 26 15:50:21 ether sshd[4292]: Disconnecting: Too many authentication failures for root
Jul 26 15:50:21 ether sshd[4291]: PAM 2 more authentication failures; logname= uid=0 euid=0 tty=ssh ruser= rhost=43.229.53.60  user=root
Jul 26 15:50:22 ether sshd[4663]: pam_unix(sshd:auth): authentication failure; logname= uid=0 euid=0 tty=ssh ruser= rhost=43.229.53.60  user=root
Jul 26 15:50:21 ether sshd[4291]: Invalid user trudy from 43.229.53.60
EOF
    return @msgs;
}

sub contextualize_message {
    my ($self,$log) = @_;
    my $str = $log->context->{message};

    my %ctxt = ();
    $ctxt{status} = index($str,'Accepted') >= 0 ? 'success'
                  : index($str,'Failed')   >= 0 ? 'failure'
                  : undef;
    if( defined $ctxt{status} ) {
        $log->add_tags(qw(authentication));
        if( my @data = ($str =~ /$RE{extract_details}/o) ) {
            for(my $i=0; $i < @data; $i++) {
                $ctxt{$F{extract_details}->[$i]} = $data[$i];
            }
        }
    }
    elsif( index($str, 'Invalid') >= 0 ) {
        $ctxt{status} = 'invalid';
        @ctxt{qw(acct src_ip)} = ($str =~ /Invalid user (\S+) from (\S+)/);
    }
    else {
        delete $ctxt{status};
    }

    $log->add_context($self->name,\%ctxt);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::context::sshd

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
