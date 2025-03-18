#!/pro/bin/perl

use strict;
use warnings;

use Test::More;
use Tie::Hash::DBD;

require "./t/util.pl";
require "./t/hashtest.pl";
require "./t/arraytest.pl";

sub streamtests {
    my $DBD = shift;

    # Test connect without serializer to check if DBD is available
    my %hash;
    eval { tie %hash, "Tie::Hash::DBD", dsn ($DBD) };
    tied  %hash or plan_fail ($DBD);
    untie %hash;

    hashtests  ($DBD, $_) for supported_serializers ();
    arraytests ($DBD, $_) for supported_serializers ();

    cleanup ($DBD);
    } # streamtests

unless (caller) {
    foreach my $str (supported_serializers ()) {
	my $v = eval "require $str; \$${str}::VERSION";
	if ($@) {
	    ok (1, "$str not available");
	    next;
	    }
	ok (1, "$str $v");
	my %deep = deep ("dbi:CSV:", $str);

	my %h;
	eval {
	    tie %h, "Tie::Hash::DBD", "dbi:CSV:", { str => $str };
	    $h{deep} = \%deep;
	    };
	my $deep = $h{deep};
	if ($deep) {
	    is_deeply ($h{deep}, \%deep, "Data ok");
	    }
	else {
	    ok (1, "$str: FAIL $@");
	    }
	}
    done_testing;
    }

1;
