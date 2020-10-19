package Test::Run::CmdLine::Prove::App;

use strict;
use warnings;

use parent 'Exporter';

use vars (qw($VERSION));

$VERSION = '0.0132';

use vars qw(@EXPORT);

@EXPORT = (qw(run));

use Test::Run::CmdLine::Prove;

sub run
{
    my $p =
        Test::Run::CmdLine::Prove->create(
            {
                'args' => [@ARGV],
                'env_switches' => $ENV{'PROVE_SWITCHES'},
            }
        );
    exit(! $p->run());
}

1;

=head1 NAME

Test::Run::CmdLine::Prove::App - a module implementing a standalone command line
app for runprove.

=head1 SYNOPSIS

    $ perl -MTest::Run::CmdLine::Prove::App -e 'run()' -- [ARGS]

=head1 DESCRIPTION

This is a module implementing a standalone command line application. It was
created to replace the use of the C<runprove> executable which is not always
installed or available in the path.

=head1 EXPORTS

=head2 run()

Actually executed the command-line application.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-cmdline@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-CmdLine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the MIT X11 License.

=cut

