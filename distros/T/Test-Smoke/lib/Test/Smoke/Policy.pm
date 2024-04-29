package Test::Smoke::Policy;
use strict;

our $VERSION = '0.004';

use File::Spec;
use Test::Smoke::LogMixin;

=head1 NAME

Test::Smoke::Policy - OO interface to handle the Policy.sh stuff.

=head1 SYNOPSIS

    use Test::Smoke::Policy;

    my $srcpath = File::Spec->updir;
    my $policy = Test::Smoke::Policy->new( $srcpath );

    $policy->substitute( [] );
    $policy->write;

=head1 DESCRIPTION

I wish I understood what Merijn is doeing in the original code.

=head1 METHODS

=head2 Test::Smoke::Policy->new( $srcpath )

Create a new instance of the Policy object.
Read the file or take data from the DATA section.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = bless { }, $class;
    $self->reset_rules;
    $self->_read_Policy( @_ );
    $self;
}

=head2 $policy->verbose

Get verbosity.

=cut

sub verbose { $_[0]->{v} }

=head2 $policy->set_rules( $rules )

Set the rules for substitutions.

=cut

sub set_rules {
    my( $self, $rules ) = @_;

    push @{ $self->{_rules} }, $rules;
}

=head2 $policy->reset_rules( )

Reset the C<_rules> property.

=cut

sub reset_rules {
    $_[0]->{_rules} = [ ];
    $_[0]->{_new_policy} = undef;
}

=head2 $policy->_do_subst( )

C<_do_subst()> does the substitutions and stores the substituted version
as the B<_new_policy> attribute.

=cut

sub _do_subst {
    my $self = shift;

    my %substs;
    foreach my $rule ( @{ $self->{_rules} } ) {
        push @{ $substs{ $rule->[0] } }, $rule->[1];
    }
    my $policy = $self->{_policy};
    while ( my( $target, $values ) = each %substs ) {
        unless ( $policy =~ s{^(\s*ccflags=.*?)$target}
                             {$1 . join " ",
                                   grep $_ && length $_ => @$values}meg ) {
            require Carp;
            Carp::carp( "Policy target '$target' failed to match" );
        }
    }
    $self->{_new_policy} = $policy;
}

=head2 $policy->write( )

=cut

sub write {
    my $self = shift;

    defined $self->{_new_policy} or $self->_do_subst;

    local *POL;
    my $p_name = shift || 'Policy.sh';
    unlink $p_name; # or carp "Can't unlink '$p_name': $!";
    if ( open POL, "> $p_name" ) {
        print POL $self->{_new_policy};
        close POL or do {
            require Carp;
            Carp::carp( "Error rewriting '$p_name': $!" );
        };
    } else {
        require Carp;
        Carp::carp( "Unable to rewrite '$p_name': $!" );
    }
}

=head2 $policy->_read_Policy( $srcpath[, $verbose[, @ccflags]] )

C<_read_Policy()> checks the C<< $srcpath >> for these conditions:

=over 4

=item B<Reference to a SCALAR> Policy is in C<$$srcpath>

=item B<Reference to an ARRAY> Policy is in C<@$srcpath>

=item B<Reference to a GLOB> Policy is read from the filehandle

=item B<Other values> are taken as the base path for F<Policy.sh>

=back

The C<@ccflags> are passed to C<< $self->default_Policy() >>

=cut

sub _read_Policy {
    my( $self, $srcpath, $verbose, @ccflags ) = @_;
    $srcpath = '' unless defined $srcpath;

    $self->{v} ||= defined $verbose ? $verbose : 0;
    my $vmsg = "";
    local *POLICY;
    if ( ref $srcpath eq 'SCALAR' ) {

        $self->{_policy} = $$srcpath;
        $vmsg = "internal content";

    } elsif ( ref $srcpath eq 'ARRAY' ) {

        $self->{_poliy} = join "", @$srcpath;
        $vmsg = "internal content";

    } elsif ( ref $srcpath eq 'GLOB' ) {

        *POLICY = *$srcpath;
        $self->{_policy} = do { local $/; <POLICY> };
        $vmsg = "anonymous filehandle";

    } else {
        $srcpath = File::Spec->curdir
            unless defined $srcpath && length $srcpath;
        my $p_name = File::Spec->catfile( $srcpath, 'Policy.sh' );

        unless ( open POLICY, $p_name ) {
            $self->{_policy} = $self->default_Policy( @ccflags );
            $vmsg = "default content";
        } else {
            $self->{_policy} = do { local $/; <POLICY> };
            close POLICY;
            $vmsg = $p_name;
        }

    }
    $self->log_info("Reading 'Policy.sh' from %s (v=%d)", $vmsg, $self->verbose);
}

=head2 $policy->default_Policy( [@ccflags] )

Generate the default F<Policy.sh> from a set of ccflags, but be
backward compatible.

=cut

sub default_Policy {
    my $self = shift;
    my @ccflags = @_ ? @_ : qw( -DDEBUGGING );

    local $" = " ";
    return <<__EOPOLICY__;
#!/bin/sh

# Default Policy.sh from Test::Smoke

# Be sure to define -DDEBUGGING by default, it's easier to remove
# it from Policy.sh than it is to add it in on the correct places

ccflags='@ccflags'
__EOPOLICY__
}

1;

=head1 COPYRIGHT

(c) 2001-2015, All rights reserved.

  * H.Merijn Brand <hmbrand@hccnet.nl>
  * Nicholas Clark <nick@unfortu.net>
  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

  * <http://www.perl.com/perl/misc/Artistic.html>,
  * <http://www.gnu.org/copyleft/gpl.html>

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
