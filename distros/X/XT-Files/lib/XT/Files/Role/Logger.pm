package XT::Files::Role::Logger;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Role::Tiny;

use Carp          ();
use Scalar::Util  ();
use Test::Builder ();

sub log {    ## no critic (Subroutines::ProhibitBuiltinHomonyms)
    my ( $self, $msg ) = @_;

    my $msg_with_prefix = $self->_msg_with_prefix($msg);
    Test::Builder->new->note($msg_with_prefix);

    return;
}

sub log_debug {
    my ( $self, $msg ) = @_;

    return if !$ENV{XT_FILES_DEBUG};

    $self->log($msg);

    return;
}

sub log_fatal {
    my ( $self, $msg ) = @_;

    $self->log($msg);

    my $msg_with_prefix = $self->_msg_with_prefix($msg);

    my $package = __PACKAGE__;
    local $Carp::CarpInternal{$package} = 1;    ## no critic (Variables::ProhibitPackageVars)
    Carp::confess($msg_with_prefix);
}

sub log_prefix {
    my ($self) = @_;

    return Scalar::Util::blessed($self);
}

sub _msg_with_prefix {
    my ( $self, $msg ) = @_;

    my $msg_with_prefix = '[' . $self->log_prefix . '] ' . $msg;
    return $msg_with_prefix;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XT::Files::Role::Logger - logging role

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

    use Role::Tiny::With;
    with 'XT::Files::Role::Logger';

    $self->log($message);
    $self->log_debug($message);
    $self->log_fatal($message);

=head1 DESCRIPTION

This L<Role::Tiny> role adds logging functionality to all L<XT::Files>
classes.

=head1 USAGE

=head2 log ( MESSAGE )

Logs the message with L<Test::Builder>s C<note> method. This should be used
for all output instead of just printing it to work nicely with the Perl
testing environment.

=head2 log_debug ( MESSAGE )

Logs the message with C<log> but only if the environment variable
C<XT_FILES_DEBUG> is set and true.

=head2 log_fatal ( MESSAGE )

Logs the message with C<log>, then dies with L<Carp>s C<confess>.

=head2 log_prefix

Returns the prefix that is prepended to every logged message. Defaults to
the objects class.

Method can be overwritten to change the prefix.

=head1 SEE ALSO

L<XT::Files>, L<Carp>, L<Test::Builder>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/XT-Files/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/XT-Files>

  git clone https://github.com/skirmess/XT-Files.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
