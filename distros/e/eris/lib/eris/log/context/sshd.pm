package eris::log::context::sshd;
# ABSTRACT: Parse sshd logs into structured data

use Const::Fast;
use Moo;
use namespace::autoclean;
with qw(
    eris::role::context
);

our $VERSION = '0.008'; # VERSION


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


const my %RE => (
    extract_details => qr/(?:Accepted|Failed) (\S+) for (\S+) from (\S+) port (\S+) (\S+)/,
    IPv4            => qr/\d{1,3}(?:\.\d{1,3}){3}/,
);
const my %F => (
    extract_details => [qw(driver acct src_ip src_port proto_app)],
);
const my %SDATA => qw(
    user  acct
);

sub contextualize_message {
    my ($self,$log) = @_;
    my $c   = $log->context;
    my $str = $c->{message};

    my %ctxt = ();
    $ctxt{status} = $str =~ /Accepted/ ? 'success'
                  : $str =~ /Failed/   ? 'failure'
                  : undef;
    if( defined $ctxt{status} ) {
        $ctxt{action} = 'authentication';
        if( my @data = ($str =~ /(?>$RE{extract_details})/o) ) {
            @ctxt{@{ $F{extract_details} }} = @data;
        }
    }
    elsif( $str =~ /Invalid/ ) {
        $ctxt{status} = 'invalid';
        @ctxt{qw(acct src_ip)} = ($str =~ /Invalid user (\S+) from (\S+)/);
    }
    else {
        delete $ctxt{status};
    }
    if( exists $c->{sdata} ) {
        foreach my $k (keys %SDATA) {
            $ctxt{$SDATA{$k}} = $c->{sdata}{$k} if exists $c->{sdata}{$k};
        }
        if( exists $c->{sdata}{rhost} ) {
            my $k = $c->{sdata}{rhost} =~ /^$RE{IPv4}$/o ? 'src_ip' : 'src_host';
            $ctxt{$k} = $c->{sdata}{rhost};
        }
    }

    $log->add_context($self->name,\%ctxt) if keys %ctxt;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::context::sshd - Parse sshd logs into structured data

=head1 VERSION

version 0.008

=head1 SYNOPSIS

Parse sshd logs into structured data

=head1 METHODS

=head2 contextualize_message

Parses an sshd log and extracts the relevant details

    action    => authentication/..
    status    => succes/failure/invalid
    driver    => keyboard/password/public key
    acct      => user in question
    proto_app => sshv2 / sshv1

And

    src_ip, src_port

=for Pod::Coverage sample_messages

=head1 SEE ALSO

L<eris::log::contextualizer>, L<eris::role::context>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
