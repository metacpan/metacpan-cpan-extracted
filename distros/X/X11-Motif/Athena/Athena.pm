package X11::Athena;

# Copyright 1997, 1998 by Ken Fox

use DynaLoader;

use strict;
use vars qw($VERSION @ISA);

BEGIN {
    $VERSION = 1.1;
    @ISA = qw(DynaLoader);

    bootstrap X11::Athena;
    bootstrap X11::Toolkit;

    use X11::Toolkit qw(:private);
    use X11::AthenaCons;

    X11::Toolkit::use_standard_aliases();
}

sub beta_version { 2 };

sub import {
    my $module = shift;
    my %done;

    foreach my $sym (@_) {
	next if ($done{$sym});

	if ($sym eq ':X') {
	    export_pattern(\%X::, '^X');
	}
	elsif ($sym eq ':Xt') {
	    export_pattern(\%X::Toolkit::, '^Xt');
	    export_pattern(\%X::Toolkit::Context::, '^Xt');
	    export_pattern(\%X::Toolkit::Widget::, '^Xt');
	}
	elsif ($sym eq ':widgets') {
	    export_pattern(\%X::Athena::, '^xaw');
	}
	else {
	    export_symbol(\%X::Athena::, $sym);
	}

	$done{$sym} = 1;
    }
}

my $finished_standard_aliases = 0;

sub use_standard_aliases {
    if (!$finished_standard_aliases) {
	$finished_standard_aliases = 1;
    }
}

package X::Athena;

X11::Athena::use_standard_aliases();

1;
