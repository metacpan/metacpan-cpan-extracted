package WWW::Postini::Exception::InvalidParameter;

use strict;
use warnings;

use WWW::Postini::Exception;

use vars qw( @ISA $VERSION );

@ISA = qw( WWW::Postini::Exception );
$VERSION = '0.01';

1;

__END__

=head1 NAME

WWW::Postini::Exception::InvalidParameter - Exception cause by failed
type-checking

=head1 SYNOPSIS

  use WWW::Postini::Exception::InvalidParameter;
  
  check(12);
  
  sub check {
    
    my $value = shift;
  
    if ($value > 10) {

      throw WWW::Postini::Exception::InvalidParameter('Value too high');
      
    }
    
  }

=head1 DESCRIPTION

Some methods within L<WWW::Postini|WWW::Postini> attempt a level of runtime
type-checking.  When a malformed parameter is passed to any such methods, a
L<WWW::Postini::Exception::InvalidParameter|WWW::Postini::Exception::InvalidParameter>
exception is thrown with the appropriate reason.

There is some overhead to this method, but it provides much more information
than C<die()>ing with some cryptic message or C<return()>ing C<undef> with no
reason.

Please refer to L<WWW::Postini::Exception> for information regarding
constructors and methods.

=head1 SEE ALSO

L<WWW::Postini>, L<WWW::Postini::Exception>

=head1 AUTHOR

Peter Guzis, E<lt>pguzis@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Peter Guzis

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

Postini, the Postini logo, Postini Perimeter Manager and preEMPT are
trademarks, registered trademarks or service marks of Postini, Inc. All
other trademarks are the property of their respective owners.

=cut