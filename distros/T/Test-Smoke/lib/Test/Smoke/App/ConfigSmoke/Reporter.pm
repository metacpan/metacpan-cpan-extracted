package Test::Smoke::App::ConfigSmoke::Reporter;
use warnings;
use strict;

our $VERSION = '0.001';

use Exporter 'import';
our @EXPORT = qw/ config_reporter_options /;

use Test::Smoke::App::Options;

=head1 NAME

Test::Smoke::App::ConfigSmoke::Reporter - Mixin for L<Test::Smoke::App::ConfigSmoke>

=head1 DESCRIPTION

These methods will be added to the L<Test::Smoke::App::ConfigSmoke> class.

=head2 config_make_options

Configure options C<hostname>, C<usernote> and C<usernote_pos>

=cut

sub config_reporter_options {
    my $self = shift;

    print "\n-- Reporter section --\n";

    $self->handle_option(Test::Smoke::App::Options->hostname);

    my $un_file = $self->handle_option(Test::Smoke::App::Options->un_file);

    if ($un_file) {
        if (! -f $un_file) {
            open(my $fh, '>', $un_file);
            close($fh);
            print "  >> Created $un_file.\n";
        }
        $self->handle_option(Test::Smoke::App::Options->un_position);
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
