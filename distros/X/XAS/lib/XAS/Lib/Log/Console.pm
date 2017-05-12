package XAS::Lib::Log::Console;

our $VERSION = '0.02';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  utils     => ':validation',
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

    warn sprintf("%-5s - %s\n", 
        uc($args->{'priority'}), 
        $args->{'message'}
    );

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

1;

__END__

=head1 NAME

XAS::Lib::Log::Console - A class for logging

=head1 DESCRIPTION

This module is for logging to the terminal. It logs to stderr.

=head1 METHODS

=head2 new

This method initializes the module.

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
