package # no pause
	accessors::fast::tie;

use strict;
use Carp ();
use accessors::fast ();
our $VERSION = $accessors::fast::VERSION;
use constant::def {
    DEBUG   => accessors::fast::DEBUG || 0,
    CONFESS => accessors::fast::CONFESS || 0,
};

BEGIN {
    *croak = CONFESS ? sub (@) { goto &Carp::confess } : sub (@) { goto &Carp::croak };
}

sub TIEHASH {
	my ($pkg,$cls,$fld) = @_;
	return bless {
		o => {},
		k => [],
		f  => {
			(map { $_ => 1 } @$fld),
		},
		class => $cls,
	},$pkg;
}

sub check {
	my ($self,$f) = @_;
	my $clr = caller(1);
	return if $clr eq 'accessors::fast'
	       or $clr eq 'Data::Dumper';
	my $ft = $self->{f}->{$f};
	croak "Class $self->{class} have no field $f" unless $ft;
}

sub FETCH {
	warn "fetch `$_[1]'\n" if DEBUG;
	&check;
	$_[0]->{o}->{$_[1]};
}
sub STORE {
	warn "store `$_[1]'\n" if DEBUG;
	&check;
	$_[0]->{o}->{$_[1]} = $_[2];
}
sub DELETE {
	warn "delete $_[1]\n" if DEBUG;
	&check;
	delete $_[0]->{o}->{$_[1]};
}
sub CLEAR {
	warn "clear\n" if DEBUG;
	%{$_[0]->{o}} = ();
}
sub EXISTS {
	warn "exists $_[1]\n" if DEBUG;
	return unless exists $_[0]->{f}->{$_[1]};
	exists $_[0]->{o}->{$_[1]};
}
#sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
#sub NEXTKEY  { each %{$_[0]} }

sub FIRSTKEY {
	warn "firstkey\n" if DEBUG;
	local $a = scalar keys %{$_[0]->{o}};
	each %{$_[0]->{o}};
}
sub NEXTKEY {
	warn "nextkey\n" if DEBUG;
	each %{$_[0]->{o}};
}
sub SCALAR {
	warn "scalar\n" if DEBUG;
	scalar(%{$_[0]->{o}})
}

1;
