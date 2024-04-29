package Test::Smoke::App::ConfigSmoke::Sync;
use warnings;
use strict;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT = qw/ config_sync /;

use Test::Smoke::App::Options;

=head1 NAME

Test::Smoke::App::ConfigSmoke::Sync - Mixin for L<Test::Smoke::App::ConfigSmoke>

=head1 DESCRIPTION

These methods will be added to the L<Test::Smoke::App::ConfigSmoke> class.

=head2 config_sync

Configure options for C<sync_type> and each sync-type.

=cut

sub config_sync {
    my $self = shift;

    print "\n-- Sync section --\n";
    my $synctree = Test::Smoke::App::Options->synctree_config();

    my $sync_type = $self->handle_option(Test::Smoke::App::Options->sync_type);
    my @sync_options = sort {
        $a->configord <=> $b->configord
    } @{ $synctree->{$sync_type} };
    for my $option (@sync_options) {
        $self->handle_option($option);
    }

    # (post)handle gitbranchfile
    if (    exists($self->current_values->{gitbranchfile})
        and my $fn = $self->current_values->{gitbranchfile})
    {
        if ( open(my $fh, '>', $fn) ) {
            print $fh $self->current_values->{gitdfbranch};
            close($fh);
            printf "  >> Created '%s'\n", $fn;
        }
        else {
            print "!!!!!\nProblem: could not create '$fn': $!\n";
            print "Please correct your self.\n!!!!!\n";
        }
    }
}

1;

=head1 COPYRIGHT

(c) 2020, All rights reserved.

  * Abe Timmerman <abeltje@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See:

=over 4

=item * L<http://www.perl.com/perl/misc/Artistic.html>

=item * L<http://www.gnu.org/copyleft/gpl.html>

=back

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
