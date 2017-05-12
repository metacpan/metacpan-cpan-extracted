package XAS::Apps::Alert;

our $VERSION = '0.01';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Lib::App',
  utils     => 'dotid',
  accessors => 'message',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub main {
    my $self = shift;

    $self->alert->send($self->message);

}

sub options {
    my $self = shift;

    return {
        'script=s' => sub {
            $self->env->script($_[1]);
        }
    };

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    unless (defined($ARGV[0])) {

        $self->throw_msg(
            dotid($self->class) . '.nomessage',
            'nomessage',
        );

    }

    $self->{'message'} = $ARGV[0];

    return $self;

}

1;

__END__

=head1 NAME

XAS::Apps::Alert - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Apps::Alert;

 my $app = XAS::Apps::Alert->new(
     -throws => 'xas-alert'
 );

 exit $app->run;

=head1 DESCRIPTION

This module is used to send an alert from the command line.

=head1 METHODS

=head2 main

This method will start the processing.

=head2 options

This module provides these additonal cli options. 

=over 4

=item B<--script>

This provides a name for the script. Default is 'xas-alert'.

=back

=head1 SEE ALSO

=over 4

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
