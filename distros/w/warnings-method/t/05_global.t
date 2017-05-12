#!perl -w

use strict;
use Test::More tests => 1;

use FindBin qw($Bin);
use lib $Bin;

use warnings::method -global;

our $nwarns;

BEGIN{
	$nwarns = 0;

	my $msg_re = qr/Method \s+ \S+ \s+ called \s+ as \s+ a \s+ function/xms;

	$SIG{__WARN__} = sub{
		my $msg = join '', @_;

#		diag $msg;

		if($msg =~ /$msg_re/xms){
			$nwarns++;
			return;
		}

		warn $msg;
	};
}

use Foo;
#
#use B::Concise qw(concise_subref);
#concise_subref(basic => \&Foo::f);

is $nwarns, 1, '-global';
