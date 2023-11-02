package Test::Smoke::App::ConfigSmoke::MakeOptions;
use warnings;
use strict;

our $VERSION = '0.002';

use Exporter 'import';
our @EXPORT = qw/ config_make_options /;

use Test::Smoke::App::Options;
use Test::Smoke::Util::FindHelpers qw/ whereis /;

=head1 NAME

Test::Smoke::App::ConfigSmoke::MakeOptions - Mixin for L<Test::Smoke::App::ConfigSmoke>

=head1 DESCRIPTION

These methods will be added to the L<Test::Smoke::App::ConfigSmoke> class.

=head2 config_make_options

Configure options C<makeopt>, C<testmake>, C<harnessonly>, C<hasharness3> and C<harness3opts>.

Also C<force_c_locale>, C<locale>, C<defaultenv>

Also C<skip_tests>

=cut

sub config_make_options {
    my $self = shift;

    print "\n-- make all / make test section --\n";
    $self->current_values->{hasharness3} = 1;

    my @options = qw/ makeopt testmake harnessonly /;
    for my $opt (@options) {
        my $option = Test::Smoke::App::Options->$opt;
        $self->handle_option($option);
    }
    if ($self->current_values->{harnessonly} || $^O eq 'MSWin32') {
        $self->handle_option(Test::Smoke::App::Options->harness3opts);
    }
    $self->handle_option(Test::Smoke::App::Options->force_c_locale);
    if ( $^O ne 'MSWin32' ) {
        $self->handle_option(Test::Smoke::App::Options->defaultenv);
        if (! $self->current_values->{defaultenv}) {
            $self->handle_option(Test::Smoke::App::Options->perlio_only);
        }
    }
    else {
        $self->current_values->{defaultenv} = 1;
    }
    if (! $self->current_values->{defaultenv} ) {
        my @locales = _utf8_locales();
        if (@locales) {
            my $list = join(" |", @locales);
            { # It's still a format...
                no warnings 'uninitialized';
                local ($:, $^A) = ("|");
                formline('^' . ('<' x 66) . "~~\n" , $list);
                print "\nI found these UTF-8 locales:\n$^A";
            }

            $self->handle_option(Test::Smoke::App::Options->locale);
        }
    }

    my $skip_tests = $self->handle_option(Test::Smoke::App::Options->skip_tests);
    if ($skip_tests and  !-f $skip_tests) {
        if (open(my $fh, '>', $skip_tests)) {
            print {$fh} "# One test name per line\n";
            close($fh);
            print "  >> Created '$skip_tests'\n";
        }
        else {
            print "!!!!!\nProblem: Cannot create($skip_tests): $!\n!!!!!\n";
            print "Please, fix this yourself.\n";
        }
    }
}

sub _utf8_locales {
    # I only know one way... and one for Darwin (perhaps FreeBSD)
    if ( $^O =~ /darwin|bsd/i ) {
        opendir(my $dh, '/usr/share/locale') or return;
        my @list = grep { m/utf-?8$/i } readdir($dh);
        closedir($dh);
        return @list;
    }
    my $locale = whereis( 'locale' );
    return unless $locale;
    return grep { m/utf-?8$/i } split(m/\n/, qx/$locale -a/);
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
