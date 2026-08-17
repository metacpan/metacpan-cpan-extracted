
use v5.14;
use warnings;

use Syntax::Construct qw (package-block package-version);

package Test::YAFT::Act v1.0.4 {
	use Ref::Util ();

	use Test::YAFT::Act::Context;

	sub new {
		my ($class, $act, @args) = @_;

		my $dispatch_type = ref ($args[0])
			? shift @args
			: [ ]
			;

		$dispatch_type = Ref::Util::is_hashref ($dispatch_type)
			? Test::YAFT::Act::Context::DISPATCH_HASH
			: Test::YAFT::Act::Context::DISPATCH_ARRAY
			;

		my (@dependencies, %options);
		while (@args) {
			push @dependencies, my $dependency = shift @args;

			$options{$dependency} = shift @args
				if ref $args[0]
				;
		}

		return bless {
			act           => $act,
			dependencies  => \ @dependencies,
			dispatch_type => $dispatch_type,
			options       => \ %options,
		}, $class;
	}

	sub act {
		$_[0]->{act};
	}

	sub context {
		Test::YAFT::Act::Context::->new ($_[0]);
	}

	sub dependencies {
		@{ $_[0]->{dependencies} }
	}

	sub options {
		$_[0]->{options}
	}

	1;
};

__END__

=pod

=encoding utf-8

=head1 NAME

Test::YAFT::Act - Internal implementation of act

=head1 AUTHOR

Branislav Zahradník <barney.cpan@gmail.com>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Test::YAFT> distribution.

=cut
