package XAS::Class;

our $VERSION = '0.02';

use Badger::Class
  version  => $VERSION,
  uber     => 'Badger::Class',
  constant => {
      UTILS     => 'XAS::Utils',
      CONSTANTS => 'XAS::Constants',
  }
;

1;

__END__

=head1 NAME

XAS::Class - A Perl extension for the XAS environment

=head1 SYNOPSIS

 use XAS::Class
     version => '0.01',
     base    => 'XAS::Base'
 ;

=head1 DESCRIPTION

This module ties the XAS environment to the base Badger object framework. It
exposes the defined constants and utilities that reside in L<XAS::Constants|XAS::Constants> and
L<XAS::Utils|XAS::Utils>. Which inherits from L<Badger::Constants|https://metacpan.org/pod/Badger::Constants> and 
L<Badger::Utils|http://metacpan.org/pod/Badger::Utils>.

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
