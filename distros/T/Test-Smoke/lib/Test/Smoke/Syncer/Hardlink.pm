package Test::Smoke::Syncer::Hardlink;
use warnings;
use strict;

use base 'Test::Smoke::Syncer::Base';

=head1 Test::Smoke::Syncer::Hardlink

This handles syncing by copying the source-tree from a local directory
using the B<link> function. This can be used as an alternative for
B<make distclean>.

Thanks to Nicholas Clark for donating this suggestion!

=cut

require File::Find;

=head2 Test::Smoke::Syncer::Hardlink->new( %args )

Keys for C<%args>:

  * ddir: destination directory
  * hdir: source directory
  * v:    verbose

=cut

=head2 $syncer->sync( )

C<sync()> uses the B<File::Find> module to make the hardlink forest in {ddir}.

=cut

sub sync {
    my $self = shift;

    $self->pre_sync;
    require File::Copy unless $self->{haslink};

    -d $self->{ddir} or File::Path::mkpath( $self->{ddir} );

    my $source_dir = File::Spec->canonpath( $self->{hdir} );

    File::Find::find( sub {
        my $dest = File::Spec->abs2rel( $File::Find::name, $source_dir );
        # nasty thing in older File::Spec::Win32::abs2rel()
        $^O eq 'MSWin32' and $dest =~ s|^[a-z]:(?![/\\])||i;
        $dest = File::Spec->catfile( $self->{ddir}, $dest );
        if ( -d ) {
            mkdir $dest, (stat _)[2] & 07777;
        } else {
            -e $dest and 1 while unlink $dest;
            $self->{v} > 1 and print "link $_ $dest";
            my $ok = $self->{haslink}
                ? link $_, $dest
                : File::Copy::copy( $_, $dest );
            if ( $self->{v} > 1 ) {
                print $ok ? " OK\n" : " $!\n";
            }
        }
    }, $source_dir );

    $self->clean_from_directory( $source_dir );

    $self->post_sync;
    return $self->check_dot_patch();
}

1;

=head1 COPYRIGHT

(c) 2002-2013, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

  * <http://www.perl.com/perl/misc/Artistic.html>,
  * <http://www.gnu.org/copyleft/gpl.html>

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
