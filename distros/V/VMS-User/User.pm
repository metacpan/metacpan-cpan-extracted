package VMS::User;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw(&user_list);
$VERSION = '0.02';

bootstrap VMS::User $VERSION;

# Preloaded methods go here.

sub user_list {
    print "in user_list\n";
    my $name_regex = shift;
    my @names;

    print "starting\n";
    @names = map {/^.{21}(\S+)/; $1} `mcr authorize show/brief *`;
    print "found ", scalar(@names), " names\n";
    if (defined $name_regex) {
        @names = grep {/$name_regex/o;} @names;
    }

    return @names;
}
        
1;
__END__

=head1 NAME

VMS::User - list VMS user information

=head1 SYNOPSIS

  use VMS::User;

  @users = VMS::User::user_list();

  $uairef = VMS::User::user_info($UserName);
  print "Default dir is ",$uairef->{DEFDIR}, "\n";

=head1 DESCRIPTION

The VMS::User module provides access to the SYSUAF.  Read-only at the
moment, but that may change with later versions of this module.

=head1 AUTHOR

Dan Sugalski E<lt>sugalskd@ous.eduE<gt>
Version 0.02 released by by Peter Prymmer in 2007 

=head1 BUGS

None known, but it is beta code...

=head1 LIMITATIONS

The C<user_list()> function spawns a subprocess that invokes C<AUTHORIZE> and
parses the output of C<SHOW/BRIEF *>. This means that you need read access to
SYSUAF and execute privs on AUTHORIZE to use it.

=head1 COPYRIGHT AND LICENSE

Copyright 1999 by Dan Sugalski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
