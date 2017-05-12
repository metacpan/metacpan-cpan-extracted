package Test::FTP::Server::Server;

use strict;
use warnings;

our $VERSION = '0.011';

use Carp;
use File::Temp qw/ tempfile tempdir /;

use Net::FTPServer;
use Net::FTPServer::Full::Server;
use Test::FTP::Server::DirHandle;
use base qw/ Net::FTPServer::Full::Server /;

sub test_users {
	my $self = shift;
	$self->{'_test_users'} = shift if @_;
	$self->{'_test_users'} || undef;
}

sub options_hook {
	my $self = shift;
	my ($args) = @_;

	for (my $i = 0; $i < scalar(@$args); $i++) {
		if (! ref($args->[$i]) && $args->[$i] =~ m/^_test_/) {
			$self->{$args->[$i]} = $args->[$i+1];
			splice(@$args, $i, 2);
			$i--;
		}
	}

	return if grep($_ eq '-C', @$args);

	if (-e $self->{_config_file}) {
		my ($fh, $filename) = tempfile();
		close($fh);
		push(@$args, '-C', $filename);
	}
}

sub authentication_hook {
	my $self = shift;
	my ($user, $pass, $user_is_anon) = @_;

	if (defined(my $users = $self->test_users)) {
		return scalar(grep({
			$_->{'user'} eq $user && $_->{'pass'} eq $pass
		} @$users)) ? 0 : -1;
	}

	$self->SUPER::authentication_hook(@_);
}

sub user_login_hook {
	my $self = shift;

	if (defined(my $users = $self->test_users)) {
		my ($u) = grep({
			$_->{'user'} eq $self->{'user'}
		} @$users);
		if ($u && $u->{'root'}) {
			$self->{'_test_root'} = $u->{'root'};
		}
		return;
	}

	$self->SUPER::user_login_hook(@_);
}

sub root_directory_hook {
	my $self = shift;

	if ($self->{'_test_root'}) {
		new Test::FTP::Server::DirHandle($self);
	}
	else {
		$self->SUPER::root_directory_hook(@_);
	}
}

1;
__END__

=head1 NAME

Test::FTP::Server::Server - The server for Test::FTP::Server.

=head1 SYNOPSIS

  use Test::FTP::Server::Server;

=head1 DESCRIPTION

=head1 AUTHOR

Taku Amano E<lt>taku@toi-planning.netE<gt>

=head1 SEE ALSO

L<Test::FTP::Server>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
