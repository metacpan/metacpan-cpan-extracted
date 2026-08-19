#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


#  Constants
#
package WebDyne::Chain::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %Constant);
use warnings;


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  Version information. Must be all on one line
#
$VERSION='3.019';


#  Constants are empty, but having this file allows for import of DEBUG and othe
#  vars from /etc/webdyne.conf.pl;
#
%Constant=();


#  Done
#
1;
__END__

=begin markdown

# WebDyne::Chain::Constant #

# NAME #

WebDyne::Chain::Constant - constant namespace for `WebDyne::Chain`

# SYNOPSIS #

```perl
use WebDyne::Chain::Constant;
```

# DESCRIPTION #

`WebDyne::Chain::Constant` exists primarily so the normal WebDyne constant-loading mechanism can import configuration for the chaining subsystem from standard WebDyne configuration files.

In the current code this module does not define any chain-specific constants of its own. It is an extension point and import target rather than a feature-bearing API.

# CONSTANTS #

This module currently defines an empty `%Constant` hash.

# NOTES #

Use this module when you want a stable configuration namespace for future `WebDyne::Chain`-specific settings in `webdyne.conf.pl`.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 WebDyne::Chain::Constant


=head1 NAME

WebDyne::Chain::Constant - constant namespace for C<WebDyne::Chain>


=head1 SYNOPSIS


 use WebDyne::Chain::Constant;

=head1 DESCRIPTION

C<WebDyne::Chain::Constant> exists primarily so the normal WebDyne constant-loading mechanism can import configuration for the chaining subsystem from standard WebDyne configuration files.

In the current code this module does not define any chain-specific constants of its own. It is an extension point and import target rather than a feature-bearing API.


=head1 CONSTANTS

This module currently defines an empty C<%Constant> hash.


=head1 NOTES

Use this module when you want a stable configuration namespace for future C<WebDyne::Chain>-specific settings in C<webdyne.conf.pl>.


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

This file is part of WebDyne.

This software is copyright (c) 2026 by Andrew Speer L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

L<http://dev.perl.org/licenses/>

=cut
