# WebFetch::Output::Dump
# ABSTRACT: save WebFetch data in a Perl structure dump
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

package WebFetch::Output::Dump;
$WebFetch::Output::Dump::VERSION = '0.15.9';
use base "WebFetch";

use Data::Dumper;

# define exceptions/errors
use Exception::Class ();

# no user-servicable parts beyond this point

# register capabilities with WebFetch
__PACKAGE__->module_register("output:dump");

# Perl structure dump format handler
sub fmt_handler_dump
{
    my ( $self, $filename ) = @_;

    $self->raw_savable( $filename, Dumper( $self->{data} ) );
    return 1;
}

1;

=pod

=encoding UTF-8

=head1 NAME

WebFetch::Output::Dump - save WebFetch data in a Perl structure dump

=head1 VERSION

version 0.15.9

=head1 SYNOPSIS

In perl scripts:

C<use WebFetch::Output::Dump;>

From the command line:

C<perl -w -MWebFetch::Output::Dump -e "&fetch_main" -- --dir directory
     --format dump --save save-path [...WebFetch output options...]>

=head1 DESCRIPTION

This is an output module for WebFetch which simply outputs a Perl
structure dump from C<Data::Dumper>.  It can be read again by a Perl
script using C<eval>.

=over 4

=item $obj->fmt_handler_dump( $filename )

This function dumps the data into a string for saving by the WebFetch::save()
function.

=back

=head1 SEE ALSO

L<WebFetch>
L<https://github.com/ikluft/WebFetch>

=head1 BUGS AND LIMITATIONS

Please report bugs via GitHub at L<https://github.com/ikluft/WebFetch/issues>

Patches and enhancements may be submitted via a pull request at L<https://github.com/ikluft/WebFetch/pulls>

=head1 AUTHOR

Ian Kluft <https://github.com/ikluft>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998-2023 by Ian Kluft.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

__END__
# POD docs follow

