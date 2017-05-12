package XAS::Lib::Batch;

our $VERSION = '0.01';

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => ':validation run_cmd trim',
  vars => {
    PARAMS => {
      -interface => { optional => 1, default => 'XAS::Lib::Batch::Interface::Torque' },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub do_cmd {
    my $self = shift;
    my ($cmd, $sub) = validate_params(\@_, [1,1]);

    $self->log->debug("command = $cmd");

    my ($output, $rc, $sig) = run_cmd($cmd);

    if ($rc != 0) {

        my $msg = $output->[0] || '';

        $self->throw_msg(
            dotid($self->class) . ".$sub",
            'pbserr',
            $rc, trim($msg)
        );

    }

    return $output;

}

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->class->mixin($self->interface);

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Batch - A class for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
   version => '0.01',
   base    => 'XAS::Lib::Batch'
 ;

=head1 DESCRIPTION

This is a class for accessing a batch system. Batch systems are a controlled
way to run jobs in the background. Depending on how the batch system is
setup you may have access to hundreds of systems to run jobs on. These jobs 
can then controlled by issuing commads against the batch system. This module 
encapsulates those commands into Perl objects and methods. 

There is apparently a standardized command line interface to these batch
systems. This module also helps to abstract some of the differences between 
those standardized commands. Because if you work in this business long enough
you get to know what "standardized" really means.

Since this is Perl and you are loading a mixin. You could access the mixin
methods directly. But it is advisable to use the pre-defined classes to help 
with parameter checking and exception handling.

=head1 METHODS

=head2 new

This initializes the class and takes these parameters:

=over 4

=item B<-interface>

This defines the interface to load. It defaults to L<XAS::Lib::Batch::Interface::Torque|XAS::Lib::Batch::Interface::Torque>.

=back

=head2 do_cmd($command)

This method will run a command and capture its output. If an non zero return
code is detected, it will throw an exception with that return code and the 
first output line returned.

=over 4

=item B<$command>

The command to execute in the background using Perl's backtick function. STDERR
is redirected into STDOUT.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Batch::Job|XAS::Lib::Batch::Job>

=item L<XAS::Lib::Batch::Queue|XAS::Lib::Batch::Queue>

=item L<XAS::Lib::Batch::Server|XAS::Lib::Batch::Server>

=item L<XAS::Lib::Batch::Interface::Torque|XAS::Lib::Batch::Interface::Torque>

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
