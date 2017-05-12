#============================================================= -*-perl-*-
#
# XML::Schema::Test
#
# DESCRIPTION
#   Module for testing XML::Schema modules.
#
# AUTHOR
#   Andy Wardley <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2001 Canon Research Centre Europe Ltd.
#   All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id: Test.pm,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

package XML::Schema::Test;

use strict;
use XML::Schema;
use base qw( Exporter );
use vars qw( $VERSION $DEBUG $ERROR @EXPORT );

$VERSION = sprintf("%d.%02d", q$Revision: 1.1.1.1 $ =~ /(\d+)\.(\d+)/);
$DEBUG   = 0 unless defined $DEBUG;
$ERROR   = '';

@EXPORT  = qw( ntests ok match assert );

my $ok_count;
my @results;

sub ntests {
    my $ntests = shift;
    # add the number of any cached results to $ntests
    $ntests += scalar @results;
    $ok_count  = 1;
    print "1..$ntests\n";
    # flush cached results
    foreach (@results) { ok(@$_) };
}

sub ok {
    my ($ok, $msg) = @_;

    # cache results if ntests() not yet called
    unless ($ok_count) {
	push(@results, [ $ok, $msg ]);
	return $ok;
    }

    if ($ok) {
	print "ok ", $ok_count++, "\n";
    }
    else {
	print "FAILED $ok_count: $msg\n" if defined $msg;
	print "not ok ", $ok_count++, "\n";
    }
}

sub assert {
    my ($ok, $err) = @_;
    return ok(1) if $ok;

    # failed
    my ($pkg, $file, $line) = caller();
    $err ||= "assert failed";
    $err .= " at $file line $line\n";
    ok(0);
    die $err;
}

    
sub match {
    my ($result, $expect) = @_;

    # force stringification of $result to avoid 'no eq method' overload errors
    $result = "$result" if ref $result;	   

    if ($result eq $expect) {
	ok(1);
    }
    else {
	ok(0, "match failed:\n  expect: [$expect]\n  result: [$result]\n");
    }
}

sub flush {
    ntests(0) unless $ok_count;
}

sub END {
    flush();	    # ensure any cached results get flushed
}


1;

__END__

=head1 NAME

XML::Schema::Test - utility module for XML::Schema regression tests

=head1 SYNOPSIS

    use XML::Schema::Test;

    # specify number of tests
    ntests(2);

    # test if passed value equates true (ok) or false (not ok) 
    ok( $true_or_false );

    # test if result matches expected value (ok) or not (not ok)
    match( $result, $expect )

=head1 DESCRIPTION

This module implements some basic subroutines which are used in the
XML::Schema regression test suite.  The tests themselves can be found 
in the 't' subdirectory of the distribution directory.

=head1 SUBROUTINES

This module exports the following subroutines into the caller's package.

=head2 ntests($n)

Called before any tests to declare how many tests are expected to follow.

    ntests(2);

This generates the familiar output which is compatible with Perl's 
Test::Harness module (i.e. that which gets run when you 'make test').

    1..2

If the ntests() subroutine isn't called then the test module will cache
all results generated via ok() and match() and then display the results
as the script finishes executing, having counted them to determine the 
total number of tests.

=head2 ok($truth, $error)

Called to register a test result.  The first value should be any true 
value to indicate success or any false value to indicate failure.  

    ok( $foo );
    ok( defined $foo );
    ok( $foo > 10 );

The second optional value may be a error message which is printed in the 
case of the test failing.  This is very useful for determining which test
failed without having to count through your script to find the nth test.

    ok( $foo, '$foo is not true' );
    ok( defined $foo, '$foo is not defined' );
    ok( $foo > 10, '$foo is not > 10' );

=head2 match($result, $expect)

Called to test that a result string matches an expected string.

    match( $foo, 'The foo string' );

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 VERSION

This is version $Revision: 1.1.1.1 $ of the XML::Schema::Test module, distributed
with version 0.1 of the XML::Schema module set.

=head1 COPYRIGHT

Copyright (C) 2001 Canon Research Centre Europe Ltd.  All Rights
Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

See the XML::Schema regression test suite in the 't' subdirectory of the 
distribution.


