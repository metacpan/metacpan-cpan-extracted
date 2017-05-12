package
    forks::signals; #hide from PAUSE
$VERSION = '0.36';

use strict;
use warnings;
use Carp ();
use vars qw($sig %usersig);
use List::MoreUtils;
use Sys::SigAction qw(set_sig_handler);

# Declare private package variables

my $tied;
my %sig_undefined_map;
my %sig_defined_map;
my %is_sig_user_defined;

sub import {
    shift;

# Overload and tie %SIG

    unless ($sig) {
        %usersig = %SIG;
        $sig = \%SIG;
        *SIG = {};
        $tied = tie %SIG, __PACKAGE__;
    }
    
# Load wrapper subroutines and prepare %SIG for signals that were already defined.

    if ((my $idx = List::MoreUtils::firstidx(
        sub { $_ eq 'ifdef' }, @_)) >= 0) {
        if (ref $_[$idx+1] eq 'HASH') {
            my (undef, $opts) = splice(@_, $idx, 2);
            %sig_defined_map = map { $_ => $opts->{$_} } 
                map(defined $opts->{$_} && $opts->{$_} ne ''
                    ? $_ : (), keys %{$opts});

            _STORE($_, $usersig{$_})
                 foreach map(defined $usersig{$_} && $usersig{$_} ne ''
                    ? $_ : (), keys %sig_defined_map);
        } else {
            splice(@_, $idx, 1);
            %sig_defined_map = ();
        }
    }
    
# Load wrapper subroutines and prepare %SIG for signals that were not already defined.

    if ((my $idx = List::MoreUtils::firstidx(
        sub { $_ eq 'ifndef' }, @_)) >= 0) {
        if (ref $_[$idx+1] eq 'HASH') {
            my (undef, $opts) = splice(@_, $idx, 2);
            %sig_undefined_map = map { $_ => $opts->{$_} } 
                map(defined $opts->{$_} && $opts->{$_} ne ''
                    ? $_ : (), keys %{$opts});

            _STORE($_, (defined $usersig{$_} ? $usersig{$_} : undef))
                 foreach map(!defined $usersig{$_} || $usersig{$_} eq ''
                    ? $_ : (), keys %sig_undefined_map);
        } else {
            splice(@_, $idx, 1);
            %sig_undefined_map = ();
        }
    }

    return $tied;
}

sub _STORE    {
    my $k = shift;
    my $s = shift;
    my $flags;
    
# Install or remove signal handler (including wrapper subroutine, when apporpriate)

    if (!defined($s) || $s eq '' || $s eq 'DEFAULT') {
        if (grep(/^$k$/, keys %sig_undefined_map)) {
            if (ref $sig_undefined_map{$k} eq 'ARRAY') {
                $sig->{$k} = $sig_undefined_map{$k}[0];
                $flags = $sig_undefined_map{$k}[1];
            } else {
                $sig->{$k} = $sig_undefined_map{$k};
            }
        } else {
            delete( $sig->{$k} );
        }
        delete( $is_sig_user_defined{$k} );
    } elsif ($s eq 'IGNORE') {
        $sig->{$k} = 'IGNORE';
        delete( $is_sig_user_defined{$k} );
    } else {
        $sig->{$k} = ref($s) eq 'CODE'
            ? grep(/^$k$/, keys %sig_defined_map)
                ? sub { $sig_defined_map{$k}->(@_); $s->(@_) }
                : $s
            : grep(/^$k$/, keys %sig_defined_map)
                ? sub { $sig_defined_map{$k}->(@_); $s; }
                : $s;
        $is_sig_user_defined{$k} = 1;
    }
    
# If subroutine signal handler has custom flags, apply them to the handler if possible.
# Example: CHLD handler may have SA_RESTART flag, to minimize side effects with programs
# that don't install a custom CHLD handler (very common) but use slow system signals;
# programs that do install a custom CHLD handler.
# Note: custom handler flags only currently applied to ifndef, as use with ifdef might
# unexpectedly overwrite user flags, if user is using POSIX::sigaction to set signals.

    if (defined $flags && ref($sig->{$k}) eq 'CODE') {
        untie %SIG;
        set_sig_handler($k, $sig->{$k}, {
            flags => $flags,
            safe  => $] < 5.008002 ? 0 : 1
        });
        tie %SIG, __PACKAGE__;
    }
    
    return $s;
}

# Package method returns wheter a user-defined handler is set for a given signal.
# Input argument must be a signal name string, i.e. INT, TERM, CHLD, etc.

sub is_sig_user_defined {
    return exists $is_sig_user_defined{$_[0]} ? $is_sig_user_defined{$_[0]} : 0;
}

sub CLONE {}

sub TIEHASH  { bless({}, shift) }
sub UNTIE    {
    my ($obj,$count) = @_;

# Note: refcount of 1 unavoidable, likely due to how %SIG is internally referenced
# in this module; however, anything larger indicates a potential issue.

    Carp::carp "untie attempted while $count inner references still exist" if $count > 1;
}
sub STORE    {
    $usersig{$_[1]} = $_[2];
    _STORE($_[1], $_[2]);
}
sub FETCH    { $sig->{$_[1]} }
sub FIRSTKEY { my $a = scalar keys %{$sig}; each %{$sig} }
sub NEXTKEY  { each %{$sig} }
sub EXISTS   { exists $sig->{$_[1]} }
sub DELETE   { _STORE($_[1], undef) }
sub CLEAR    {
    $_[0]->DELETE($_) while ($_) = each %{$sig};
    return;
}
sub SCALAR   { scalar %{$sig} }

1;

__END__

=head1 NAME

forks::signals - signal management for forks

=head1 DESCRIPTION

This module is only intended for internal use by L<forks>.

=head1 CREDITS

Implementation inspired by Cory Johns' L<libalarm/Alarm::_TieSIG>.

=head1 AUTHOR

Eric Rybski <rybskej@yahoo.com>.  Please send all module inquries to me.

=head1 COPYRIGHT

Copyright (c)
 2005-2014 Eric Rybski <rybskej@yahoo.com>.
All rights reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<forks>

=cut
