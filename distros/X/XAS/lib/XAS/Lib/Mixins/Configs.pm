package XAS::Lib::Mixins::Configs;

our $VERSION = '0.01';

use Try::Tiny;
use Config::IniFiles;

use XAS::Class
  debug   => 0,
  version => $VERSION,
  base    => 'XAS::Base',
  utils   => ':validation dotid compress',
  mixins  => 'load_config',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub load_config {
    my $self = shift;
    my ($filename, $handle) = validate_params(\@_, [
        { optional => 1, isa => 'Badger::Filesystem::File', default => $self->env->cfg_file },
        { optional => 1, default => 'cfg' },
    ]);

    # really... using carp() as an exception handler is lame

    local $SIG{__WARN__} = sub {
        my $error = shift;

        my ($reason) = $error =~ /(.*)at\s+/;

        $self->throw_msg(
            dotid($self->class) . '.load_config.badini',
            'config_badini',
            $filename->path,
            $reason,
        );

    };

    $self->{$handle} = Config::IniFiles->new(-file => $filename->path);

    unless (defined($self->{$handle})) {

        $self->throw_msg(
            dotid($self->class) . '.load_config.badini',
            'config_badini',
            $filename->path,
            compress(join('', @Config::IniFiles::errors)),
        );

    }

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Mixins::Configs - A mixin for handling config files

=head1 SYNOPSIS

 use XAS::Class;
   version   => '0.01',
   base      => 'XAS::Base',
   mixin     => 'XAS::Lib::Mixins::Configs',
   accessors => 'cfg',
 ;

=head1 DESCRIPTION

This mixin provides a standardized way to load .ini files.

=head1 METHODS

=head2 load_config($filename, $handle)

This method will load a .ini style configuration file. It uses the following 
parameters:

=over 4

=item B<$filename>

The file name for the configuration file.

=item B<$handle>

An optional name to the accessor that will access the 
L<Config::IniFiles|https://metacpan.org/pod/Config::IniFiles> 
object in the current self. This name defaults to 'cfg'.

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
