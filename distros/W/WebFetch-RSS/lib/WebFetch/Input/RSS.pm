# WebFetch::Input::RSS
# ABSTRACT: compatibility mode to access WebFetch::RSS under its previous name
#
# Copyright (c) 1998-2022 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  https://www.gnu.org/licenses/gpl-3.0-standalone.html

# pragmas to silence some warnings from Perl::Critic
## no critic (Modules::RequireExplicitPackage)
# This solves a catch-22 where parts of Perl::Critic want both package and use-strict to be first
use strict;
use warnings;
use utf8;
## use critic (Modules::RequireExplicitPackage)

package WebFetch::Input::RSS;
$WebFetch::Input::RSS::VERSION = '0.3.2';

# inherit everything as a derived class - this exists just for backward compatibility
use base "WebFetch::RSS";

1;

=pod

=encoding UTF-8

=head1 NAME

WebFetch::Input::RSS - compatibility mode to access WebFetch::RSS under its previous name

=head1 VERSION

version 0.3.2

=head1 SYNOPSIS

In perl scripts:

  C<use WebFetch::Input::RSS;>

From the command line:

  C<perl -w -MWebFetch::Input::RSS -e "&fetch_main" -- --dir directory --source rss-feed-url [...output options...]>

or

  C<perl -w -MWebFetch::Input::RSS -e "&fetch_main" -- --dir directory [...input options...]> --dest_format=rss --dest=file

=head1 DESCRIPTION

I<WebFetch::Input::RSS> is an alias for L<WebFetch::RSS> to provide backward compatibility under its previous name.

=head1 SEE ALSO

L<WebFetch>
L<https://github.com/ikluft/WebFetch>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/WebFetch/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/WebFetch/pulls>

=head1 AUTHOR

Ian Kluft <https://github.com/ikluft>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998-2022 by Ian Kluft.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__
# POD docs follow

