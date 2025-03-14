package lib::absolute;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Convert all paths in @INC to absolute paths
$lib::absolute::VERSION = '0.100';
use strict;
use warnings;
use Path::Tiny;

sub import {
	my ( $self, @args ) = @_;
	my $hard = grep { $_ eq '-hard' } @args;
	@INC = map {
		if (ref $_) {
			$_;
		} else {
			my $dir = path($_)->absolute;
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

=encoding UTF-8

=head1 NAME

lib::absolute - Convert all paths in @INC to absolute paths

=head1 VERSION

version 0.100

=head1 SYNOPSIS

  use lib::absolute;

  use lib::absolute -hard; # crashs on non existing directories

=head1 DESCRIPTION

This package converts on load all your @INC path into absolute paths, if you have "." in your path, it gets additionally
added again (and also get added as absolute path).

=head1 SUPPORT

IRC

  Join #perl-help on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  http://github.com/Getty/p5-lib-absolute
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-lib-absolute/issues

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/p5-lib-absolute>

  git clone https://github.com/Getty/p5-lib-absolute.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2025 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
