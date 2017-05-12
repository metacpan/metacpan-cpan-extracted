package Test::FTP::Server::FileHandle;

use strict;
use warnings;

our $VERSION = '0.011';

use Net::FTPServer::Full::FileHandle;
use Test::FTP::Server::Util;

use File::Spec;
use File::Basename;

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
	$class eq 'Net::FTPServer::FileHandle';
}

sub move {
	my $fh_wrap = shift;
	my $dh_wrap = shift;

	my $fh = $fh_wrap->{'handle'};
	my $dh = $dh_wrap->{'handle'};
	my $filename = shift;

	die if $filename =~ /\//;	# Should never happen.

	my $src = File::Spec->catfile(
		$fh_wrap->{'_test_root'}, $fh->{'_pathname'}
	);
	my $dst = File::Spec->catfile(
		$fh_wrap->{'_test_root'}, $dh->{'_pathname'}, $filename
	);

	rename $src, $dst or return -1;

	$fh->{'_pathname'} = File::Spec->catfile(
		dirname($dh->{'_pathname'}), $filename
	);

	return 0;
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

Test::FTP::Server::FileHandle - The file handle for Test::FTP::Server.

=head1 SYNOPSIS

  use Test::FTP::Server::FileHandle;

=head1 DESCRIPTION

=head1 AUTHOR

Taku Amano E<lt>taku@toi-planning.netE<gt>

=head1 SEE ALSO

L<Test::FTP::Server>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
