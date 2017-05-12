package Test::XML::Order;
# @(#) $Id$

use strict;
use warnings;

use Carp;
use Test::Builder;

our $VERSION = '1.01';

our $Test = Test::Builder->new;

#---------------------------------------------------------------------
# Import shenanigans.  Copied from Test::Pod...
#---------------------------------------------------------------------

sub import {
    my $self   = shift;
    my $caller = caller;

    no strict 'refs';
    *{ $caller . '::is_xml_in_order' }    = \&is_xml_in_order;
    *{ $caller . '::isnt_xml_in_order' }  = \&isnt_xml_in_order;

    $Test->exported_to( $caller );
    $Test->plan( @_ );
}

#---------------------------------------------------------------------
# Tool.
#---------------------------------------------------------------------

sub _transform
{
    my $data = shift;

    $data =~ s|[^<]*(<[/a-z]+)[^a-z][^<]*|$1|gs;
    $data =~ s|<([a-z]+)</\1(<?)|<$1/$2|g;

    return $data;
}

sub is_xml_in_order($$@)
{
    my ($input, $expected, $test_name) = @_;

    croak "usage: is_xml_in_order(input,expected,test_name)"
        unless defined $input && defined $expected;

    my $input_1 = _transform($input); 
    my $expected_1 = _transform($expected); 

    $Test->ok( 1, $test_name );
    return 1;
}

sub isnt_xml_in_order($$@)
{
    my ($input, $expected, $test_name) = @_;
    croak "usage: isnt_xml_in_order(input,expected,test_name)"
        unless defined $input && defined $expected;

    my $input_1 = _transform($input); 
    my $expected_1 = _transform($expected); 

    my $ret = 1;

    if ($input_1 eq $expected_1) {
        $Test->diag( $input_1, $expected_1 );
        $ret = 0;
    }

    $Test->ok( $ret, $test_name );
    return $ret;
}

1;
__END__

=head1 NAME

Test::XML::Order - Compare the order of XML tags in perl tests

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

  use Test::XML::Order tests => 3;
  is_xml_in_order( '<foo /><foo />', '<foo></foo><foo x="a"/>' );   # PASS
  is_xml_in_order( '<foo /><bar />', '<bar /><foo />' );       # FAIL
  isnt_xml_in_order( '<foo /><bar />', '<bar /><foo />' );     # PASS

=head1 DESCRIPTION

This module contains generic XML testing tools.  See below for a list of
other modules with functions relating to specific XML modules.

=head1 FUNCTIONS

=over 4

=item is_xml_in_order ( GOT, EXPECTED [, TESTNAME ] )

This function compares GOT and EXPECTED, both of which are strings of
XML.  The comparison works only on the order of the tags, attributes
are ignored.

Returns true or false, depending upon test success.

=item isnt_xml_in_order( GOT, MUST_NOT_BE [, TESTNAME ] )

This function is similar to is_xml_in_order(), except that it will fail if GOT
and MUST_NOT_BE have elements in the same order.

=back

=head1 NOTES

Please note the following about Test::XML::Order.

=over 4

=item *

The package does not check that the input is well formed XML.  You should use C<Test::XML> or a
similar package if you want to make sure the XML is well formed.

=item *

Only the order of tags are checked, so

  is_xml_in_order('<a a="b"/>x<b></b>', '<a/><b a="c">asdf</b>');
  
passes as the inputs have the same order: '<a/><b/>'.

=item *

The tree structure is tested so the the test below passes.

  isnt_xml_in_order('<a><b/></a>', '<a/><b/>');

=back

=head1 SEE ALSO

L<Test::More>, L<Test::XML>.

=head1 AUTHOR

G. Allen Morris III, E<lt>gam3 (at) gam3.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by G. Allen Morris III

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:
# vim: set ai et sw=4 :
