package Net::Server::Mail::ESMTP::STARTTLS;

use strict;
use base qw(Net::Server::Mail::ESMTP::Extension);
use vars qw($VERSION);
$VERSION     = '0.01';

sub init {
    my ($self, $parent) = @_;
    $self->{parent} = $parent;
    return $self;
}

#sub reply {
#    return (['DATA' =>  \&reply_mail_body],
#            ['MAIL' =>  \&reply_mail_from]);
#}

sub keyword {
    return 'STARTTLS';
}

sub verb {
    return (['STARTTLS' => '_tls_start' ]);
}

sub _tls_start {
    my ($self) = @_;
    if (not (require IO::Socket::SSL)){
        $self->reply(550, 'Can\'t SSL without IO::Socket::SSL');
    } else {
    use Data::Dumper;
    print STDERR Dumper($self);
        $self->reply(220, 'Go ahead');
        my $ssl_sock = IO::Socket::SSL->new_from_fd(
	        $self->{'out'}, 
	        SSL_server => 1,
		SSL_use_cert => 1,
		SSL_key_file => '/usr/share/mysql/mysql-test/std_data/server-key.pem',
		SSL_cert_file => '/usr/share/mysql/mysql-test/std_data/server-cert.pem',
		SSL_ca_file => '/usr/share/mysql/mysql-test/std_data/untrusted-cacert.pem')
	 or print STDERR IO::Socket::SSL::errstr();
	$self->{'_ssl_socket'} = $ssl_sock;
	$self->{'in'} = $self->{'out'} = $self->{'options'}->{'socket'} = $ssl_sock;
	
    use Data::Dumper;
    print STDERR Dumper($self);
#	$self->reply(220, $self-{'banner_string'});
    }
    return;
}

*Net::Server::Mail::ESMTP::_tls_start = \&_tls_start;

#################### main pod documentation begin ###################
## Below is the stub of documentation for your module. 
## You better edit it!


=head1 NAME

Net::Server::Mail::ESMTP::STARTTLS - STARTTLS implementation for the Net::Server::Mail::ESMTP server

=head1 SYNOPSIS

  use Net::Server::Mail::ESMTP::STARTTLS;
  blah blah blah


=head1 DESCRIPTION

Stub documentation for this module was created by ExtUtils::ModuleMaker.
It looks like the author of the extension was negligent enough
to leave the stub unedited.

Blah blah blah.


=head1 USAGE



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com
    http://www.pplusdomain.net

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

