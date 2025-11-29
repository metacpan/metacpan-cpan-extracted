package WWW::Noss::Util;
use 5.016;
use strict;
use warnings;
our $VERSION = '2.01';

use Exporter qw(import);
our @EXPORT_OK = qw(dir resolve_url);

use File::Spec;

sub dir {

    my ($dir, %param) = @_;
    my $hidden = $param{ hidden } // 0;

    opendir my $dh, $dir
        or die "Failed to open $dir as a directory: $!\n";
    my @f = sort grep { ! /^\.\.?$/ } readdir $dh;
    closedir $dh;

    unless ($hidden) {
        @f = grep { ! /^\./ } @f;
    }

    return map { File::Spec->catfile($dir, $_) } @f;

}

sub resolve_url {

    my ($url, $from) = @_;

    my ($proto, $root, $path) = $from =~ /^(\w+:\/\/)?([^\/]+)(.*)$/;
    $proto //= '';

    if ($url =~ /^\w+:\/\//) {
        return $url;
    }

    if ($proto eq 'shell://' or $proto eq 'file://') {
        return undef;
    }

    if ($url =~ /^\/\//) {
        $url =~ s/^\/\///;
        return $proto . $url;
    } elsif ($url =~ /^\//) {
        return $proto . $root . $url;
    } else {
        $url =~ s/^\.\/+//;
        $root =~ s/\/+[^\/]*$//;
        return $proto . $root . '/' . $url;
    }

}

1;

=head1 NAME

WWW::Noss::Util - Misc. utility functions for noss

=head1 USAGE

  use WWW::Noss::Util qw(dir resolve_url);

  my @files = dir('/');

  my $full_url = resolve_url('/pages', 'https://example.com/home');

=head1 DESCRIPTION

B<WWW::Noss::Util> is a module that provides various utility functions for
L<noss>. This is a private module, please consult the L<noss> manual for user
documentation.

=head1 SUBROUTINES

Subroutines are not exported automatically.

=over 4

=item @children = dir($dir, [ %param ])

Returns list of children files under directory C<$dir>. C<%param> is an
optional hash of additional parameters.

The following are valid fields in C<%param>:

=over 2

=item hidden

Boolean determining whether to include hidden files or not. Defaults to false.

=back

=item $full_url = resolve_url($url, $from)

Resolves URL C<$url> found on the page linked by C<$from>. Retuns C<undef> if
the URL could not be resolved.

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg page|https://codeberg.org/1-1sam/noss.git>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=head1 SEE ALSO

L<noss>

=cut

# vim: expandtab shiftwidth=4
