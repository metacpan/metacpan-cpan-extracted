# -*- mode: perl -*-
#
# $Id: Entry.pm,v 1.2 1999/10/10 15:04:08 tai Exp $
#

package Tie::LDAP::Entry;

=head1 NAME

 Tie::LDAP::Entry - Tie LDAP database entry to Perl hash.

=head1 SYNOPSIS

 use Tie::LDAP;

 tie %LDAP, 'Tie::LDAP', {
     host => $host,
     user => $user,
     pass => $user,
     base => $base,
 };

 $data = $LDAP{$path};

 ## Simple hash operation, but also updates corresponding LDAP entry
 $data->{username} = 'tai@imasy.or.jp';
 ...

=head1 DESCRIPTION

See L<Tie::LDAP>.

=cut

use strict;
use Carp;

use vars qw($DEBUG $VERSION);

$DEBUG   = 0;
$VERSION = '0.02';

sub TIEHASH {
    my $name = shift;
    my $opts = shift;

    print STDERR "[$name] TIEHASH\n" if $DEBUG;

    bless {
        conn => $opts->{conn},
        path => $opts->{path},
        data => $opts->{data},
    }, $name;
}

sub FETCH {
    my $self = shift;
    my $name = shift;

    print STDERR "[$self] FETCH\n" if $DEBUG;

    $self->{data}->{$name};
}

sub STORE {
    my $self = shift;
    my $name = shift;
    my $data = shift;

    print STDERR "[$self] STORE\n" if $DEBUG;

    $self->{conn}->modify_s($self->{path}, { $name => { "rb" => $data } });
    $self->{data}->{$name} = $data;
}

sub DELETE {
    my $self = shift;
    my $name = shift;

    print STDERR "[$self] DELETE\n" if $DEBUG;

    $self->{conn}->modify_s($self->{path}, { $name => { "d" => [] } });
    delete $self->{data}->{$name};
}

sub CLEAR {
    my $self = shift;
    my $name;

    print STDERR "[$self] CLEAR\n" if $DEBUG;

    $name = $self->FIRSTKEY || return;
    do {
        $self->DELETE($name);
    } while ($name = $self->NEXTKEY);

    %{$self->{data}} = ();
}

sub EXISTS {
    my $self = shift;
    my $name = shift;

    print STDERR "[$self] EXISTS\n" if $DEBUG;

    exists $self->{data}->{$name};
}

sub FIRSTKEY {
    my $self = shift;

    print STDERR "[$self] FIRSTKEY\n" if $DEBUG;

    each %{$self->{data}};
}

sub NEXTKEY {
    my $self = shift;
    my $last = shift;

    print STDERR "[$self] NEXTKEY\n" if $DEBUG;

    each %{$self->{data}};
}

sub DESTROY {
    my $self = shift;

    print STDERR "[$self] DESTROY\n" if $DEBUG;
}

=head1 COPYRIGHT

Copyright 1998-1999, T. Yamada <tai@imasy.or.jp>.
All rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Tie::LDAP>, L<Net::LDAP>

=cut

1;
