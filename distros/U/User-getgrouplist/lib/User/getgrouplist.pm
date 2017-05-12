# Copyright (c) 2007-2014 Collax GmbH
package User::getgrouplist;

use 5.006001;
use strict;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);
our @EXPORT = qw(getgrouplist);

=head1 NAME

User::getgrouplist - Interface to glibc "getgrouplist" function

=head1 VERSION

Version 1.1.1

=cut

our $VERSION = '1.1.1';

=head1 SYNOPSIS

    use User::getgrouplist;

    my $username = 'johndoe';
    my @list = getgrouplist($username);
    print('Groups for user $username: ' . join(' ', @list) . "\n");

=head1 Description

C<User::getgrouplist> is an interface for the C<getgrouplist> function
available on many BSD-like Unix systems, and Linux. It returns the list of all
groups a user is in.

=head1 Exports

Function C<getgrouplist($username)>

=cut

bootstrap User::getgrouplist;

1;
