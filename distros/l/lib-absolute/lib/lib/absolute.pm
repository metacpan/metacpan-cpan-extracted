package lib::absolute;
BEGIN {
  $lib::absolute::AUTHORITY = 'cpan:GETTY';
}
{
  $lib::absolute::VERSION = '0.004';
}
# ABSTRACT: Convert all paths in @INC to absolute paths

use strict;
use warnings;
use Path::Class;

sub import {
	my ( $self, @args ) = @_;
	my $hard = grep { $_ eq '-hard' } @args;
	@INC = map {
		if (ref $_) {
			$_;
		} else {
			my $dir = dir($_)->absolute;
			if ($hard) {
				die $dir.' of @INC doesn\'t exist' unless -d $dir;
			}
			$dir->stringify, $_ eq '.' ? '.' : ();
		}
	} @INC;
	return;
}

1;


__END__
=pod

=head1 NAME

lib::absolute - Convert all paths in @INC to absolute paths

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use lib::absolute;

  use lib::absolute -hard; # crashs on non existing directories

=head1 DESCRIPTION

This package converts on load all your @INC path into absolute paths, if you have "." in your path, it gets additionally
added again (and also get added as absolute path).

=encoding utf8

=head1 SUPPORT

IRC

  Join #perl-help on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-lib-absolute
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-lib-absolute/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

