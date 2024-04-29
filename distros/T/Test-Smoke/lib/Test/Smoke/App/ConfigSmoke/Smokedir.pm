package Test::Smoke::App::ConfigSmoke::Smokedir;
use warnings;
use strict;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT = qw/ config_smokedir check_smokedir /;

use Test::Smoke::App::AppOption;
use Test::Smoke::App::Options;

=head1 NAME

Test::Smoke::App::ConfigSmoke::Smokedir - Mixin for Test::Smoke::App::ConfigSmoke.

=head1 DESCRIPTION

These methods will be added to the L<Test::Smoke::App::ConfigSmoke> class.

=head2 config_smokedir

Configure options: C<ddir>

=cut

sub config_smokedir {
    my $self = shift;

    print "\n-- Smoke working directory section --\n";
    my $use_dir = 0;
    do {
        $self->handle_option( Test::Smoke::App::Options->ddir() );
        $use_dir = $self->check_smokedir;
    } until $use_dir;
    delete($self->current_values->{use_smokedir});
}

=head2 check_smokedir

Will check if an existing dir already has a perl source tree.

=cut

sub check_smokedir {
    my $self = shift;

    my @makes_perl_dist = qw(Artistic perl.c perl.h .patch);
    my $looks_like_perl = 1;
    for my $file (@makes_perl_dist) {
        my $fn = File::Spec->catfile( $self->current_values->{ddir}, $file);
        $looks_like_perl &&= -f $fn;
    }
    if ($looks_like_perl) {
        printf "[%s]\n", $self->current_values->{ddir};
        return $self->handle_option(use_smokedir_option())
    }
    return 1;
}

=head2 use_smokedir_option

This option C<use_smokedir> will not be in the config-file. We use it for the
flow of the configuration, to see if an existing source-directory should be
(re)used.

=cut

sub use_smokedir_option {
    return Test::Smoke::App::AppOption->new(
        name       => 'use_smokedir',
        default    => 1,
        helptext   => "Smoke working directory already contains a perl source",
        configtext => "!! Would you still like to this directory?",
        configtype => 'prompt_yn',
        configalt  => sub { [qw/ Y n /] },
        configdft  => sub {'y'},
    );
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
