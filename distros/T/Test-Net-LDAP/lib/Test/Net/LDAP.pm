use 5.006;
use strict;
use warnings;

package Test::Net::LDAP;
use base qw(Net::LDAP Test::Net::LDAP::Mixin);

=head1 NAME

Test::Net::LDAP - A Net::LDAP subclass for testing

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

Basic testing utility

    use Test::More tests => 1;
    use Test::Net::LDAP;
    
    # Create an object, just like Net::LDAP->new()
    my $ldap = Test::Net::LDAP->new(...);
    
    # Same as $ldap->search(), testing the result to see if it is success
    my $search = $ldap->search_ok(...search args...);

Mocking (See L<Test::Net::LDAP::Mock>)

    use Test::More tests => 1;
    use Test::Net::LDAP::Util qw(ldap_mockify);
    
    ldap_mockify {
        # Net::LDAP->new() will invoke Test::Net::LDAP::Mock->new()
        my $ldap = Net::LDAP->new('ldap.example.com');
        
        # Add entries to in-memory data tree
        $ldap->add('uid=user1, ou=users, dc=example, dc=com');
        $ldap->add('uid=user2, ou=users, dc=example, dc=com');
        
        # Test your application
        ok my_application_routine();
    };

=head1 DESCRIPTION

This module provides some testing methods for LDAP operations, such as
C<search>, C<add>, and C<modify>, where each method is suffixed with either
C<_ok> or C<_is>.

C<Test::Net::LDAP> is a subclass of C<Net::LDAP>, so all the methods defined
for C<Net::LDAP> are available in addition to C<search_ok>, C<add_is>, etc.

See L<Test::Net::LDAP::Mock> for in-memory testing with fake data, without
connecting to the real LDAP servers.

See L<Test::Net::LDAP::Util> for some helper subroutines.

=head1 METHODS

=cut

=head2 new

Creates a new object. The parameters are the same as C<Net::LDAP::new>.

    my $ldap = Test::Net::LDAP->new('ldap.example.com');

=cut

=head2 search_ok

Available methods:
C<search_ok>, C<compare_ok>,
C<add_ok>, C<modify_ok>, C<delete_ok>, C<moddn_ok>,
C<bind_ok>, C<unbind_ok>, C<abandon_ok>

Synopsis:

    $ldap->search_ok(@params);
    $ldap->search_ok(\@params, $name);

Invokes the corresponding method with C<@params> passed as arguments,
and tests the result to see if the code is C<LDAP_SUCCESS>.

Alternatively, C<@params> can be given as an array ref, so that the second
argument C<$name> is specified as the test name.

C<$name> is an optional test name, and if it is omitted, the test name is
automatically configured based on C<$method> and C<@params>.

    my $search = $ldap->search_ok(
        base => 'dc=example, dc=com', scope => 'sub', filter => '(cn=*)',
    );

    my $search = $ldap->search_ok(
        [base => 'dc=example, dc=com', scope => 'sub', filter => '(cn=*)'],
        'Testing search (cn=*)'
    );

=cut

=head2 search_is

Available methods:
C<search_is>, C<compare_is>,
C<add_is>, C<modify_is>, C<delete_is>, C<moddn_is>,
C<bind_is>, C<unbind_is>, C<abandon_is>

Synopsis:

    $ldap->search_is(\@params, $expect, $name);

Invokes the corresponding method with C<@params> passed as arguments,
and tests the result to see if the code is equal to C<$expect>.

C<$expect> can be a result code such as C<LDAP_NO_SUCH_OBJECT> or an object of
C<Net::LDAP::Message> returned by LDAP operations.

C<$name> is an optional test name, and if it is omitted, the test name is
automatically configured based on C<$method> and C<@params>.

    use Net::LDAP::Constant qw(LDAP_ALREADY_EXISTS);

    my $mesg = $ldap->add_is(
        ['uid=duplicate, dc=example, dc=com'],
        LDAP_ALREADY_EXISTS
    );

=cut

=head2 method_ok

    $ldap->method_ok($method, @params);
    $ldap->method_ok($method, \@params, $name);

Invokes the method as C<< $ldap->$method(@params) >> and tests the result to see
if the code is C<LDAP_SUCCESS>.

C<$name> is an optional test name, and if it is omitted, the test name is
automatically configured based on C<$method> and C<@params>.

=cut

=head2 method_is

    $ldap->method_is($method, \@params, $expect, $name);

Invokes the method as C<< $ldap->$method(@params) >> and tests the result to see
if the code is equal to C<$expect>.

C<$expect> can be a result code such as C<LDAP_NO_SUCH_OBJECT> or an object of
C<Net::LDAP::Message> returned by LDAP operations.

C<$name> is an optional test name, and if it is omitted, the test name is
automatically configured based on C<$method> and C<@params>.

=cut

=head1 SEE ALSO

=over 4

=item * L<Test::More>

=item * L<Net::LDAP>

=item * L<Test::Net::LDAP::Mock>

=item * L<Test::Net::LDAP::Util>

=back

=head1 AUTHOR

Mahiro Ando, C<< <mahiro at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-net-ldap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Net-LDAP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Net::LDAP

You can also look for information at:

=over 4

=item * GitHub repository (report bugs here)

L<https://github.com/mahiro/perl-Test-Net-LDAP>

=item * RT: CPAN's request tracker (report bugs here, alternatively)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Net-LDAP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Net-LDAP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Net-LDAP>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Net-LDAP/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2015 Mahiro Ando.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Test::Net::LDAP
