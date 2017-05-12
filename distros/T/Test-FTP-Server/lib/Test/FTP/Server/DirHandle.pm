package Test::FTP::Server::DirHandle;

use strict;
use warnings;

our $VERSION = '0.011';

use Net::FTPServer::Full::DirHandle;
use Test::FTP::Server::FileHandle;
use Test::FTP::Server::Util;

sub new {
	my $class = shift;
	my $handle = Net::FTPServer::Full::DirHandle->new(@_);
	my $self = bless({
		'_test_root' => ($_[0]{'_test_root'} ? $_[0]{'_test_root'} : ''),
		'handle' => $handle,
	}, $class);

	Test::FTP::Server::Util::normalize($self, $handle);

	$self;
}

sub wrap {
	my $class = shift;
	my $super = shift;
	my $handle = shift;
	bless({
		'_test_root' => ($super->{'_test_root'} ? $super->{'_test_root'} : ''),
		'handle' => $handle,
	}, $class);
}

sub isa {
	my $self = shift;
	my $class = shift;
	$class eq 'Net::FTPServer::DirHandle';
}

sub AUTOLOAD {
	my $self = shift;
	my $method = our $AUTOLOAD;
	$method =~ s/.*:://o;

	return if ($method eq 'DESTROY');

	no strict 'refs';
	if (wantarray) {
		Test::FTP::Server::Util::execute($self, $self->{'handle'}, $method, @_);
	}
	else {
		my $ret = Test::FTP::Server::Util::execute(
			$self, $self->{'handle'}, $method, @_
		);

		if (ref $ret eq 'Net::FTPServer::Full::DirHandle') {
			Test::FTP::Server::DirHandle->wrap(
				$self, Test::FTP::Server::Util::normalize($self, $ret),
			);
		}
		elsif (ref $ret eq 'Net::FTPServer::Full::FileHandle') {
			Test::FTP::Server::FileHandle->wrap(
				$self, Test::FTP::Server::Util::normalize($self, $ret),
			);
		}
		elsif (defined($ret) && ! ref $ret) {
			if ($self->{'_test_root'}) {
				my $reg = '^' . quotemeta($self->{'_test_root'});
				$ret =~ s/$reg//;
			}
			$ret;
		}
		else {
			$ret;
		}
	}
}

1;
__END__

=head1 NAME

Test::FTP::Server::DirHandle - The directory handle for Test::FTP::Server.

=head1 SYNOPSIS

  use Test::FTP::Server::DirHandle;

=head1 DESCRIPTION

=head1 AUTHOR

Taku Amano E<lt>taku@toi-planning.netE<gt>

=head1 SEE ALSO

L<Test::FTP::Server>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
