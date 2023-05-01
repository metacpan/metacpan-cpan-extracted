package Test::Smoke::App::RunApp;
use warnings;
use strict;

our $VERSION = '0.001';

use Test::Smoke::App::Options;

use Exporter 'import';
our @EXPORT = qw( run_smoke_app );

sub run_smoke_app {
    my ($app_name) = @_;
    my $app_config = sprintf("%s_config", lc($app_name));

    my $module = "Test::Smoke::App::$app_name";
    eval qq{ use $module; };
    if (my $error = $@) { die "$error\n" }

    my $app = $module->new(Test::Smoke::App::Options->$app_config);
    if (my $error = $app->configfile_error) { die "$error\n"; }
    $app->run;
};

1;

=head1 NAME

Test::Smoke::App::RunApp - Run a Test::Smoke::App applet.

=head1 DESCRIPTION

Runs the applet...

=head2 run_smoke_app($app_name)

Load the module, instantiate the applet with the correct Options and run.

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

