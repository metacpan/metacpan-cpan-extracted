use 5.010001;
use strict;
use warnings;

package Types::Capabilities::CoercedValue::ARRAYREF;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002001';

use Types::Common qw( ArrayRef ArrayLike HasMethods );

sub new {
	my $class = shift;
	my $new = bless [ @{+shift} ], $class;
	&Internals::SvREADONLY($new, 1);
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

no Types::Common;

1;

__END__
