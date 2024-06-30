# -*- cperl; cperl-indent-level: 4 -*-
## no critic (RequirePodSections)
package WWW::Wookie::Module::Build::Standard v1.1.4;

use 5.016000;

use strict;
use warnings;

use Carp;
use English qw($OS_ERROR -no_match_vars);
use parent 'Module::Build';

## no critic (Capitalization)
sub ACTION_authortest {
## use critic
    my ($self) = @_;
    $self->authortest_dependencies();
    $self->depends_on('test');
    return;
}

## no critic (Capitalization)
sub ACTION_authortestcover {
## use critic
    my ($self) = @_;
    $self->authortest_dependencies();
    $self->depends_on('testcover');
    return;
}

## no critic (Capitalization)
sub ACTION_distdir {
## use critic
    my ( $self, @arguments ) = @_;
    $self->depends_on('authortest');
    return $self->SUPER::ACTION_distdir(@arguments);
}

## no critic (Capitalization)
sub ACTION_manifest {
## use critic
    my ( $self, @arguments ) = @_;
    if ( -e 'MANIFEST' ) {
        unlink 'MANIFEST' or Carp::croak qq{Can't unlink MANIFEST: $OS_ERROR};
    }
    return $self->SUPER::ACTION_manifest(@arguments);
}

sub tap_harness_args {
    my ($self) = @_;
    if ( $ENV{'RUNNING_UNDER_TEAMCITY'} ) {
        return $self->_tap_harness_args();
    }
    return;
}

sub _tap_harness_args {
    return { 'formatter_class' => 'TAP::Formatter::TeamCity', 'merge' => 1 };
}

sub authortest_dependencies {
    my ($self) = @_;
    $self->depends_on('build');
    $self->test_files(qw< t xt >);
    ## no critic (RequireLocalizedPunctuationVars)
    $ENV{'AUTHOR_TESTING'} = 1;
    ## use critic
    $self->recursive_test_files(1);
    return;
}

1;

__END__

=pod

=for stopwords authortest authortestcover distdir Ipenburg

=head1 NAME

WWW::Wookie::Module::Build::Standard - Customization of L<Module::Build> for
L<WWW::Wookie> distributions.

=head1 DESCRIPTION

This is a custom subclass of L<Module::Build> that enhances existing
functionality and adds more for the benefit of installing and developing
L<WWW::Wookie>. The following actions have been added or redefined:

=head1 ACTIONS

=over

=item authortest

Runs the regular tests plus the author tests (those in F<xt>). You've got to
explicitly ask for the author tests to be run.

=item authortestcover

As C<authortest> is to the standard C<test> action, C<authortestcover>
is to the standard C<testcover> action.

=item distdir

In addition to the standard action, this adds a dependency upon the
C<authortest> action so you can't do a release without passing the
author tests.

=back

=head1 METHODS

In addition to the above actions:

=head2 C<authortest_dependencies()>

Sets up dependencies upon the C<build>, C<manifest>, and C<distmeta> actions,
adds F<xt> to the set of test directories, and turns on the recursive
search for tests.

=head1 AUTHOR

Roland van Ipenburg <roland@rolandvanipenburg.com>, based on the work of Elliot
Shank <perl@galumph.com> in L<Perl::Critic>.

=head1 COPYRIGHT

Copyright (c) 2024 Roland van Ipenburg.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
