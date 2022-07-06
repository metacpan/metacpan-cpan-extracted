
use v5.14;
use warnings;

use Syntax::Construct 'package-block';

package Test::YAFT::Got {
	sub new {
		my ($class, $code) = @_;

		bless $code, $class;
	}

	sub resolve {
		$_[0]->();
	}

	1;
}
$Test::YAFT::Got::VERSION = '1.0.1';;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::YAFT::Got - Internals under got { }

=head1 SYNOPSIS

	use Test::YAFT;

	it "should ..."
		=> got { ... how to build test value ... }
		=> throws => 'My::Project::X::Something::Went::Wrong',
		;

=head1 DESCRIPTION

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENCE

This module is part of L<Test::YAFT> distribution.

=cut

