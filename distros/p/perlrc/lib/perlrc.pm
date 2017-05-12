package perlrc;

our $VERSION = '0.01';

use strict;
use warnings;
use Carp;

sub _home {
    my $user = shift;
    my $uid = (length $user ? getpwnam($user) : $>);
    defined $uid or return "~$user";
    my $home = (getpwuid $uid)[7];
    defined $home or return "~$user";
    $home
}

sub import {
    shift;
    my $path;
    if (@_) {
        $path = join(',', @_);
    }
    else {
        $path = '~/.perlrc:/etc/perlrc';
    }

    my @path = split /:/, $path;
    for my $file (@path) {
        $file =~ s/^~([^\/]*)/_home($1)/e;
        $file = '.' unless length $file;
        $file =~ s/\/*$/\/.perlrc/ if -d $file;
        my @files = $file;
        push @files, "$file.pl" unless $file =~ /\.pl$/;
        for (@files) {
            if (-f $_) {
                package main;
                do $_;
                return;
            }
        }
    }
    warn "no perlrc file found in $path\n";
}

1;
__END__

=head1 NAME

perlrc - run perlrc file before script

=head1 SYNOPSIS

  $ perl -Mperlrc script.pl
  $ perl -Mperlrc=/path1:/path2:...

=head1 DESCRIPTION

This module executes a perlrc file containing perl code before calling
the main script.

By default it looks for the perlrc file in the following locations:

  ~/.perlrc
  ~/.perlrc.pl
  /etc/perlrc
  /etc/perlrc.pl

Alternatively, a list of directories and/or files can be passed to the
module. For instance:

  $ perl -Mperlrc=~root/:/tmp/myperlrc

Then the module would look for the perlrc file in

  ~root/.perlrc
  ~root/.perlrc.pl
  /tmp/myperlrc      # asumming /tmp/myperlrc is not a directory
  /tmp/myperlrc.pl


Some cases where this module may be handy are:

=over

=item modify @INC to include some paths

=item mock your development environment to mimic the one in production

=item load modules and define constants accesible from one-liners

=item etc.

=back

=head1 SEE ALSO

L<perlrun/-f>, L<Begin>

=head1 BUGS

At the moment, it only works on Unix systems.

Feel free to fork and send me a pull request with the modifications
required to make it work under Windows or any other operating systems.

The code is at GitHub: L<https://github.com/salva/p5-perlrc>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Qindel FormaciE<oacute>n y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
