package uni::perl::encodebase;

use uni::perl;
m{
use strict;
use warnings;
}x;
use Encode ();

sub _generate($;$) {
	my ($pkg, $encoding) = @_;
	$encoding //= $pkg;
	my $e = Encode::find_encoding($encoding)
		or croak "Can't load encoding `$encoding'";
	my $as = 'uni::perl';
	my $decode = $e->can('decode');
	my $encode = $e->can('encode');
	{
		no strict 'refs';
		for my $method (qw(encode decode)) {
			if (defined &{$pkg.'::'.$method}) {
				carp "$pkg\::$method already defined"
					if ref \&{$pkg.'::'.$method} ne $as;
			} else {
				my $s = qq{
					sub $pkg\::$method (\$;\$) { \$e->\$$method(\@_); };
					#bless \\&$pkg\::$method, '$as';
					1
				};
				eval $s or die "$s\n$@";
			}
		}
	}
	return;
}

sub generate {
	_generate(ref $_ ? $_->[0] : $_, ref $_ ? $_->[1] : $_) for (@_);
}

1;
