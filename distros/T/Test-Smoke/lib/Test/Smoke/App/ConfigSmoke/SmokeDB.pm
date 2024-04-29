package Test::Smoke::App::ConfigSmoke::SmokeDB;
use warnings;
use strict;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT = qw/ config_smoke_db /;

use Test::Smoke::App::AppOption;
use Test::Smoke::App::Options;

=head1 NAME

Test::Smoke::App::ConfigSmoke::SmokeDB - Mixin for Test::Smoke::App::ConfigSmoke.

=head1 DESCRIPTION

These methods will be added to the L<Test::Smoke::App::ConfigSmoke> class.

=head2 config_smoke_db

Configure options: C<smokedb_url>, C<send_log>, C<send_out>, C<ua_timeout> and C<poster_type>

=cut

sub config_smoke_db {
    my $self = shift;

    print "\n-- CoreSmokeDB section --\n";

    my $url = $self->handle_option(Test::Smoke::App::Options->smokedb_url);
    if (! $url ) {
        $self->current_values->{poster} = '';
        return;
    }

    my $poster = Test::Smoke::App::Options->poster_config();
    my $post_type = $self->handle_option(Test::Smoke::App::Options->poster);

    my @poster_options = sort {
        $a->configord <=> $b->configord
    } @{ $poster->{$post_type} };
    for my $option (@poster_options) {
        $self->handle_option($option);
    }

    for my $send_stuff (qw/send_log send_out/) {
        $self->handle_option(Test::Smoke::App::Options->$send_stuff);
    }

    $self->current_values->{mail} = 0;
}

1;

=head1 COPYRIGHT

E<copy> MMXX - All rights reserved.

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
