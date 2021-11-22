
use strict;
use warnings;

package require::relative;
$require::relative::VERSION = '1.0.0';
use Path::Tiny ();

sub import {
	my ($class, @paths) = @_;
	my ($package, $file) = (caller)[0, 1];

	my $dir = -e $file
		? Path::Tiny->new ($file)->absolute->parent
		: Path::Tiny->cwd
		;

	for my $path (@paths) {
		my $real_path = Path::Tiny->new ($path)->absolute ($dir);

		eval "package $package; require q[$real_path];";
		die if $@;
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

require::relative - like require for relative paths

=head1 SYNOPSIS

	use require::relative RELATIVE_FILE;

	use require::relative "../test-helper.pl";

=head1 DESCRIPTION

Behaves like require but accepts relative file name.

Primary motivation is for usage in tests where multiple tests can
share configuration or setup.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is distributed under Artistic license 2.0

=cut

