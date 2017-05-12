package Wx::WebKit;

use 5.008006;
use strict;
use warnings;
use Wx;

our $VERSION = '0.02';

Wx::wx_boot('Wx::WebKit', $VERSION);
package Wx::WebKitCtrl; our @ISA = 'Wx::Control';

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Wx::WebKit - Perl extension to access OS X's webkit framework under Wx

=head1 SYNOPSIS

  use Wx::WebKit;

=head1 DESCRIPTION

Provides access to the webkit framwork as a widget under Wx for OS X users.

=head2 EXPORT

None by default.


=head1 SEE ALSO

L<Wx>

=head1 AUTHOR

Dan Sugalski, E<lt>dan@sidhe.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Dan Sugalski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
