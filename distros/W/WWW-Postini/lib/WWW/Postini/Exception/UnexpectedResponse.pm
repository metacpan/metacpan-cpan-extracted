package WWW::Postini::Exception::UnexpectedResponse;

use strict;
use warnings;

use WWW::Postini::Exception;

use vars qw( @ISA $VERSION );

@ISA = qw( WWW::Postini::Exception );
$VERSION = '0.01';

1;

__END__

=head1 NAME

WWW::Postini::Exception::UnexpectedResponse - Exception thrown by incorrect
content

=head1 SYNOPSIS

  use WWW::Postini::Exception::UnexpectedResponse;
  
  my $content = 'Hello world';
  my $expected = 'Goodbye world';
  
  if ($content ne $expected) {
  
    throw WWW::Postini::Exception::UnexpectedResponse(
      "Expected $expected, got $content"
    );
    
  }  

=head1 DESCRIPTION

Whenever a response returned from a web server does not match what is
expected, a
L<WWW::Postini::Exception::UnexpectedResponse|WWW::Postini::Exception::UnexpectedResponse>
exception is thrown.  

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