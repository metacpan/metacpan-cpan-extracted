package XAS::Lib::Log::File;

our $VERSION = '0.01';

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => ':validation dotid',
  constants => 'HASHREF',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub output {
    my $self  = shift;
    my ($args) = validate_params(\@_, [
        { type => HASHREF }
    ]);

    $self->env->log_file->append(
        sprintf("[%s] %-5s - %s\n", 
            $args->{'datetime'}->strftime('%Y-%m-%d %H:%M:%S'),
            uc($args->{'priority'}), 
            $args->{'message'}
    ));

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    # check to see if the file exists, otherwise create it

    unless ($self->env->log_file->exists) {

        if (my $fh = $self->env->log_file->open('>')) {
                                    
            $fh->close;

        } else {

            $self->throw_msg(
                dotid($self->class) . '.init.creatfile',
                'file_create', 
                $self->env->log_file->path
            );

        }

    }

    # Change the file permissions to rw-rw-r, skip this on Windows 
    # as this will create a read only file.

    if ($^O ne "MSWin32") {

        my ($cnt, $mode, $permissions);

        # set file permissions

        $mode = ($self->env->log_file->stat)[2];
        $permissions = sprintf("%04o", $mode & 07777);

        if ($permissions ne "0664") {

            $cnt = chmod(0664, $self->env->log_file->path);
            $self->throw_msg(
                dotid($self->class) . '.init.invperms',
                'file_perms', 
                $self->env->log_file->path) if ($cnt < 1);

        }

    }

    return $self;

}

1;

__END__

=head1 NAME

XAS::Lib::Log::File - A class for logging to files

=head1 DESCRIPTION

This module logs to a file.

=head1 METHODS

=head2 new

This method initializes the module. It checks to make sure it exists, if 
it doesn't it creates the file. On a Unix like system, it will change the 
file permissions to rw-rw-r.

=head2 output($hashref)

The method formats the hashref and writes out the results.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::Log|XAS::Lib::Log>

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
