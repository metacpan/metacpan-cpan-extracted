use 5.006;
use strict;
use warnings;

package Test::Net::LDAP::Util;
use base 'Exporter';
use Net::LDAP;
use Net::LDAP::Constant qw(LDAP_SUCCESS);
use Net::LDAP::Util qw(ldap_error_name ldap_error_text canonical_dn);
use Test::Builder;

our @EXPORT_OK = qw(
    ldap_result_ok
    ldap_result_is
    ldap_mockify
    ldap_dn_is
);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

=head1 NAME

Test::Net::LDAP::Util - Testing utilities for Test::Net::LDAP

=cut

=head1 EXPORT

The following subroutines are exported on demand.

    use Test::Net::LDAP::Util qw(
        ldap_result_ok
        ldap_result_is
        ldap_mockify
        ldap_dn_is
    );

All the subroutines are exported if C<:all> is specified.

    use Test::Net::LDAP::Util ':all';

=cut

=head1 SUBROUTINES

=cut

sub _format_diag {
    my ($actual_text, $expected_text) = @_;

    # Indent spaces are based on Test::Builder::_is_diag implementation
    # ($Test::Builder::VERSION == 0.98)
    return sprintf("%12s: %s\n", 'got', $actual_text).
           sprintf("%12s: %s\n", 'expected', $expected_text);
}

=head2 ldap_result_ok

    ldap_result_ok($mesg, $name);

Tests the result of an LDAP operation to see if the code is C<LDAP_SUCCESS>.

C<$mesg> is either a Net::LDAP::Message object returned by LDAP operation
methods or a result code.

C<$name> is the optional test name.

=cut

sub ldap_result_ok {
    my ($mesg, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    return ldap_result_is($mesg, LDAP_SUCCESS, $name);
}

=head2 ldap_result_is

    ldap_result_is($mesg, $expect, $name);

Tests the result of an LDAP operation to see if the code is equal to C<$expect>.

The values of C<$mesg> and C<$expect> are either a Net::LDAP::Message object
returned by LDAP operation methods or a result code.

C<$name> is the optional test name.

=cut

my $test_builder;

sub ldap_result_is {
    my ($actual, $expected, $name) = @_;
    $expected = LDAP_SUCCESS unless defined $expected;
    
    $test_builder ||= Test::Builder->new;
    
    my $actual_code = ref $actual ? $actual->code : $actual;
    my $expected_code = ref $expected ? $expected->code : $expected;
    my $success = ($actual_code == $expected_code);
    
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $test_builder->ok($success, $name);
    
    unless ($success) {
        my $actual_text = ldap_error_name($actual).' ('.$actual_code.'): '.
            ((ref $actual && $actual->error) || ldap_error_text($actual));
        
        my $expected_text = ldap_error_name($expected).' ('.$expected_code.')';

        $test_builder->diag(_format_diag($actual_text, $expected_text));
    }
    
    return $actual;
}

=head2 ldap_mockify

    ldap_mockify {
        # CODE
    };

Inside the code block (recursively), all the occurrences of C<Net::LDAP::new>
are replaced by C<Test::Net::LDAP::Mock::new>.

Subclasses of C<Net::LDAP> are also mockified. C<Test::Net::LDAP::Mock> is inserted
into C<@ISA> of each subclass, only within the context of C<ldap_mockify>.

See L<Test::Net::LDAP::Mock> for more details.

=cut

sub ldap_mockify(&) {
    my ($callback) = @_;
    require Test::Net::LDAP::Mock;
    Test::Net::LDAP::Mock->mockify($callback);
}

=head2 ldap_dn_is

    ldap_dn_is($actual_dn, $expect_dn, $name);

Tests equality of two DNs that are not necessarily canonicalized.

The comparison is case-insensitive.

=cut

sub ldap_dn_is {
    my ($actual_dn, $expected_dn, $name) = @_;
    my ($actual_canonical_dn, $expected_canonical_dn) = ($actual_dn, $expected_dn);

    for my $dn ($actual_canonical_dn, $expected_canonical_dn) {
        $dn = lc canonical_dn($dn, casefold => 'none') if defined $dn;
    }

    my $success;

    if (defined $actual_dn) {
        if (defined $expected_dn) {
            $success = $actual_canonical_dn eq $expected_canonical_dn;
        } else {
            $success = 0;
        }
    } else {
        $success = !defined $expected_dn;
    }

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $test_builder ||= Test::Builder->new;
    $test_builder->ok($success, $name);

    unless ($success) {
        my ($actual_text, $expected_text) = ($actual_dn, $expected_dn);

        for my $text ($actual_text, $expected_text) {
            $text = defined $text ? "'$text'" : 'undef';
        }

        $test_builder->diag(_format_diag($actual_text, $expected_text));
    }
}

1;
