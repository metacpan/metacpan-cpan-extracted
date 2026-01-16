use 5.010001;
use strict;
use warnings;

package Types::Capabilities::CoercedValue::ARRAYREF;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003000';

use Types::Common qw( ArrayRef ArrayLike assert_ArrayLike HasMethods );

sub new {
	my ( $class, $data ) = @_;
	assert_ArrayLike( $data );
	my $new = bless \$data, $class;
	Internals::SvREADONLY( $new, 1 );
	return $new;
}

sub _coercions {
	my $k = B::perlstring( shift );
	return (
		ArrayRef,            qq{$k->new(\$_)},
		HasMethods['each'],  qq{do { my \@tmp; \$_->each(sub { push \@tmp, \@_?shift:\$_  }); $k->new(\\\@tmp) }},
		HasMethods['grep'],  qq{$k->new([\$_->grep(sub{1})])},
		HasMethods['map'],   qq{$k->new([\$_->map(sub{\@_?shift:\$_})])},
		ArrayLike,           qq{$k->new(\$_)},
	);
}

sub __TO_ARRAYREF__ {
	my ( $self ) = @_;
	return $$self;
}

no Types::Common;

__PACKAGE__
__END__
