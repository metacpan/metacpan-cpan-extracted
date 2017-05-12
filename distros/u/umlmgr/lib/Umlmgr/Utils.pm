package Umlmgr::Utils;

use 5.010000;
use strict;
use warnings;
use POSIX;

sub get_id {
    my ($user) = @_;
    my @pwnam = POSIX::getpwnam($user) or return;
    $pwnam[2]
}

sub become_user {
    my ($user) = @_;

    if ($< != 0 && $> != 0) { return 1 }
    my $id = get_id($user) or return;
    #$> = $< = $id;
    if (POSIX::setuid($id)) {
        my @puid = POSIX::getpwuid($id);
        POSIX::setgid($puid[3]);
        $ENV{HOME} = $puid[7];
        $ENV{TMP} = "$puid[7]/tmp";
        $ENV{TMPDIR} = "$puid[7]/tmp";
        $ENV{USER} = $user;
        return 1;
    } else { return }
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Umlmgr - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Umlmgr;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Umlmgr, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Olivier Thauvin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
