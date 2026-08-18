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



#  Constants file
#
package WebDyne::Install::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %Constant);
use warnings;


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  External Modules
#
use File::Path;
use File::Spec;


#  Version information
#
$VERSION='3.018';


#------------------------------------------------------------------------------


#  Work out default cache directory location if none spec'd by user and
#  no PREFIX supplied
#
my $cache_default_dn;


#  Windows ?
#
if ($^O=~/MSWin[32|64]/) {
    $cache_default_dn=File::Spec->catdir($ENV{'SYSTEMROOT'}, qw(TEMP webdyne))
}

#  No - set to /var/cache/webdyne
#
else {
    $cache_default_dn=File::Spec->catdir(
        File::Spec->rootdir(), qw(var cache webdyne)
    );
}


#  Real deal
#
%Constant=(


    #  Default cache directory
    #
    DIR_CACHE_DEFAULT => $cache_default_dn


);


#  Done
#
1;__END__

=begin markdown

# WebDyne::Install::Constant #

# NAME #

WebDyne::Install::Constant - installer defaults used by WebDyne installation helpers

# SYNOPSIS #

```perl
use WebDyne::Install::Constant;
```

# DESCRIPTION #

`WebDyne::Install::Constant` defines shared defaults used by the installer modules. In the current code this is limited to the default cache directory path chosen when no explicit cache directory is supplied.

# CONSTANTS #

* **DIR_CACHE_DEFAULT**

    Default cache directory path used by the installer layer.
    
    On Unix-like systems this defaults to `/var/cache/webdyne`.
    
    On Windows it defaults under `%SYSTEMROOT%/TEMP/webdyne`.

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


=head1 WebDyne::Install::Constant


=head1 NAME

WebDyne::Install::Constant - installer defaults used by WebDyne installation helpers


=head1 SYNOPSIS


 use WebDyne::Install::Constant;

=head1 DESCRIPTION

C<WebDyne::Install::Constant> defines shared defaults used by the installer modules. In the current code this is limited to the default cache directory path chosen when no explicit cache directory is supplied.


=head1 CONSTANTS

=over

=item *

B<DIR_CACHE_DEFAULT>

Default cache directory path used by the installer layer.

On Unix-like systems this defaults to C</var/cache/webdyne>.

On Windows it defaults under C<%SYSTEMROOT%/TEMP/webdyne>.



=back


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
