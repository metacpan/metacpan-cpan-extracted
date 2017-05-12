package XAS::Lib::Mixins::Handlers;

our $VERSION = '0.02';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => ':validation compress',
  mixins  => 'exit_handler exception_handler error_handler parse_exception',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub exception_handler {
    my $self = shift;
    my ($ex, $alias) = validate_params(\@_, [
        1,
        { optional => 1, default => undef },
    ]);

    my $msg;
    my ($errors, $rc) = $self->parse_exception($ex);

    $msg = $errors;
    $msg = $self->message('exception', $alias, $errors) if (defined($alias));

    $self->log->error($msg);

    if ($self->env->alerts) {

        $self->alert->send($errors);

    }

}

sub exit_handler {
    my $self = shift;
    my ($ex, $alias) = validate_params(\@_, [
        1,
        { optional => 1, default => undef },
    ]);

    my $msg;
    my ($errors, $rc) = $self->parse_exception($ex);

    $msg = $errors;
    $msg = $self->message('exception', $alias, $errors) if (defined($alias));

    $self->log->error($msg);

    if ($self->env->alerts) {

        $self->alert->send($errors);

    }

    return $rc;

}

sub error_handler {
    my $self = shift;
    my ($ex, $alias) = validate_params(\@_, [
        1,
        { optional => 1, default => undef },
    ]);

    my $msg;
    my ($errors, $rc) = $self->parse_exception($ex);

    $msg = $errors;
    $msg = $self->message('exception', $alias, $errors) if (defined($alias));

    $self->log->error($msg);

}

sub parse_exception {
    my $self= shift;
    my ($ex) = validate_params(\@_, [1]);

    my $rc = 0;
    my $errors;
    my $ref = ref($ex);

    if ($ref) {

        if ($ex->isa('Badger::Exception')) {

            my $type = $ex->type;
            my $info = compress($ex->info);

            if ($ex->match_type('dbix.class')) {

                if ($info =~ m/(.*) XAS::Database::Model::dbix_exception/) {

                    $rc = 1;
                    $info = $1;  # strip off the dbix stack dump
   
                }

            } elsif ($ex->match_type('xas.lib.app.signal_handler')) {
   
                die $ex;         # propagate to the next level of error handlers

            }

            if ($ex->type =~ /pidfile\./) {

                $rc = 2;

            }

            $errors = $self->message('exception', $type, $info);

        } else {

            $rc = 1;
            $errors = $self->message('unexpected', compress($ex));

        }

    } else {

        $rc = 1;
        $errors = $self->message('unknownerror', compress($ex));

    }

    return $errors, $rc;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Mixin::Handlers - A mixin to provide exception handlers.

=head1 SYNOPSIS

 use XAS::Class
    version => '0.01',
    base    => 'XAS::Base',
    mixin   => 'XAS::Lib::Mixin::Handlers'
 ;


=head1 DESCRIPTION

This module provides exception handlers. It is implemented as a mixin.

=head1 METHODS

=head2 error_handler($ex)

This method will write an 'error' entry to the current log. It takes
these parameters:

=over 4

=item B<$ex>

The exception to handle.

=back

=head2 exception_hander($ex)

The method will write an 'error' entry to the current log and send an
alert. It takes these parameters:

=over 4

=item B<$ex>

The exception to handle.

=back

=head2 exit_handler($ex)

The method will write an 'fatal' entry to the current log, send an
alert and return an exit code. It takes these parameters:

=over 4

=item B<$ex>

The exception to handle.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
