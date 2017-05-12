package Test::FTP::Server::Util;

use strict;
use warnings;

our $VERSION = '0.011';

use Cwd qw/ realpath /;
use File::Spec;

sub execute {
	my ($parent, $handle, $method, @args) = @_;
	if (! $parent->{'_test_root'}) {
		$handle->$method(@_);
	}
	else {
		my $original_pathname = $handle->{_pathname};
		$handle->{_pathname} = File::Spec->catfile(
			$parent->{'_test_root'}, $handle->{_pathname}
		);

		# $handle->{_pathname} should be under the $parent->{'_test_root'}
		if (my $realpath = realpath($handle->{_pathname})) {
			my $reg = '^' . quotemeta(realpath($parent->{'_test_root'}));
			if ($realpath !~ m/$reg/) {
				$handle->{_pathname} = $parent->{'_test_root'};
			}
		}
		# normalization
		if (-d $handle->{_pathname}) {
			$handle->{_pathname} .= '/';
		}
		$handle->{_pathname} =~ s{/+}{/}g;

		my (@array, $scalar);
		if (wantarray) {
			@array = $handle->$method(@args);
		}
		else {
			$scalar = $handle->$method(@args);
		}
		$handle->{_pathname} = $original_pathname;

		if (wantarray) {
			@array;
		}
		else {
			$scalar;
		}
	}
}

sub normalize {
	my ($parent, $handle) = @_;
	if ($parent->{'_test_root'}) {
		my $reg = '^' . quotemeta($parent->{'_test_root'});
		$handle->{_pathname} =~ s/$reg//;
	}
	$handle;
}

1;
__END__

=head1 NAME

Test::FTP::Server::Util - The utilities for Test::FTP::Server.

=head1 SYNOPSIS

  use Test::FTP::Server::Util;

=head1 DESCRIPTION

=head1 AUTHOR

Taku Amano E<lt>taku@toi-planning.netE<gt>

=head1 SEE ALSO

L<Test::FTP::Server>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
