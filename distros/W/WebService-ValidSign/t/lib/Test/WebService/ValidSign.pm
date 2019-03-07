package Test::WebService::ValidSign;

use strict;
use warnings;

# ABSTRACT: A base test package for WebService::ValidSign

use namespace::autoclean ();
use Test::Most ();
use Import::Into;

sub import {

    my $caller_level = 1;

    # Test::Most imports *ALL* functions of Test::Deep, Test::Deep has
    # any, all, none, and some others that List::Utils also has.
    # Test::Deep has EXPORT_TAGS but they include pretty much everything
    my @TEST_DEEP_LIST_UTILS = qw(!any !all !none);
    Test::Most->import::into($caller_level, @TEST_DEEP_LIST_UTILS);

    my @imports = qw(
        strict
        warnings
        namespace::autoclean
        Sub::Override
    );

    $_->import::into($caller_level) for @imports;
}

1;

__END__

=head1 DESCRIPTION

Imports all the stuff we want plus sets strict/warnings etc

=head1 SYNOPSIS

    use lib qw(t/lib); # Or use Test::Lib
    use Test::WebService::ValidSign;

    # tests here

    done_testing;
