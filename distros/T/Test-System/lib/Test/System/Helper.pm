#
# Test::System::Helper
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 11/08/2009 14:03:24 PST 14:03:24
package Test::System::Helper;

=head1 NAME

Test::System::Helper - Helper for the Test::System

=head1 DESCRIPTION

The purpose of this module is to provide the easiness of getting the list of
nodes you want to test (if that is the case) and as well to let you fetch
the value of the params you specified in your L<Test::System> instance.

=cut

use strict;
use warnings;
use vars qw(@EXPORT @EXPORT_OK);
use Exporter qw(import);

@EXPORT_OK = qw(get_nodes get_param);
@EXPORT = @EXPORT_OK;

my @node_list;

our $VERSION = '0.02';

=head1 Functions

=over 4

=item B<get_nodes( )>

Returns as an array the nodes you specified via L<Test::System>. It basically
joins splits by CSV the C<TEST_SYSTEM_NODES> environment variable value and
returns it.

=cut
sub get_nodes {
    if (@node_list) {
        return @node_list;
    }
    if ($ENV{'TEST_SYSTEM_NODES'}) {
        @node_list = split(',', $ENV{'TEST_SYSTEM_NODES'});
    }
    # We don't like duplicated nodes..
    my %seen;
    my @unique = grep { ! $seen{$_}++ } @node_list;
    @node_list = @unique;
}

=item B<get_param( $key )>

Returns the parameter value of the given key.

The key name is the same key passed to the L<Test::System>, not the environment
variable that is set by L<Test::System>.

It returns the parameter by checking the environment variable that stores its
value. The name of the environments variables can be explained in the
L<Test::System> module, however a quick example will be:

    use Test::System::Helper;

    my $value = get_param('foo').

    # It will returns the value of: TEST_SYSTEM_FOO

Please note that since the values come from the environment the only type of
data that will be returned will be scalar unless the key is not found then
C<undef> will be returned.

=back

=cut
sub get_param {
    my ($key) = @_;

    use Data::Dumper;
    $key = 'TEST_SYSTEM_' . uc($key);

    if (!defined $ENV{$key}) {
        return undef;
    }
    return $ENV{$key};
}

=head1 AUTHOR
 
Pablo Fischer, pablo@pablo.com.mx.
 

=head1 COPYRIGHT
 
Copyright (C) 2009 by Pablo Fischer
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
1;

