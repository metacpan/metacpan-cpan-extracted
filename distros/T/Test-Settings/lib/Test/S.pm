package Test::S;
{
  $Test::S::VERSION = '0.003';
}

use strict;
use warnings;

use Test::Settings qw(:all);

my %allowed = (
	smoke           => \&enable_smoke,
	non_interactive => \&enable_non_interactive,
	extended        => \&enable_extended,
	author          => \&enable_author,
	release         => \&enable_release,
	all             => \&enable_all,

	no_smoke           => \&disable_smoke,
	no_non_interactive => \&disable_non_interactive,
	no_extended        => \&disable_extended,
	no_author          => \&disable_author,
	no_release         => \&disable_release,
	none               => \&disable_all,
);

sub import {
	my ($pkg, @wants) = @_;

	for my $want (@wants) {
		unless ($allowed{$want}) {
			require Carp;
			Carp::croak("Unknown test setting $want");
		}

		$allowed{$want}->();
	}
}

1;
__END__

=head1 NAME

Test::S - Change test settings on the command line

=head1 VERSION

version 0.003

=head1 SYNOPSIS

Run author test

  perl -MTest::S=author test.t

Or with prove

  prove -MTest::S=author -r .

Change a few settings

  prove -MTest::S=author,smoke

Or disable certain kinds explicitly

  prove -MTest::S=no_smoke

Don't run interactive tests

  prove -MTest::S=non_interactive -r .

=head1 DESCRIPTION

Test::S is a shortened interface to the functionality provided by 
L<Test::Settings> for use on the command line to modify the environment on the 
fly. B<This should not be used in modules! It will not behave!>

This allows one to enable or disable certain types of tests on the command line 
without needing to set environment variables by hand.

=head2 Allowed modifiers

To use the modifiers on the command line, with many tools you can load the 
module with C<-M> and provide a comma separated list of the modifiers you want:

  perl -MTest::S=all,no_smoke

The following can all be used in combination with each other (though some 
combinations obviously cancel each other out)

=over 4

=item *

smoke

=item *

non_interactive

=item *

extended

=item *

author

=item *

release

=item *

all

=item *

no_smoke

=item *

no_non_interactive

=item *

no_extended

=item *

no_author

=item *

no_release

=item *

none

=back

=head2 Notes

B<non_interactive> means do not run interactive tests, and B<no_non_interactive> 
means run interactive tests. This can be slightly confusing.

B<all> and B<none>, if used, should be the first items in the list else they 
will override the other settings.

=head1 SEE ALSO

L<Test::Settings> - Ask or tell when certain types of tests should be run

L<Test::DescribeMe> - Tell test runners what kind of test you are

L<Test::Is> - Skip test in a declarative way, following the Lancaster Consensus

=head1 AUTHOR

Matthew Horsfall (alh) - <wolfsage@gmail.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
