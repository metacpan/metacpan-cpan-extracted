package Test::Syntax::Aggregate::Checker;

use strict;
use warnings;

our $VERSION = '0.03';

=head1 NAME

Test::Syntax::Aggregate::Checker - runs syntax checks on specified files

=head1 DESCRIPTION

This module is used by L<Test::Syntax::Aggregate>, you don't normally want use it directly

=head1 SUBROUTINES

=cut

=head2 run

Reads file names from the standart input. Tries to compile each file in a
forked process.  Prints "ok" if compilation succeed, or "not ok" otherwise.

=cut

sub run {
    my $class = shift;
    my %params = @_;

    autoflush STDOUT, 1;
    while (<STDIN>) {
        chomp;
        my $pid = fork;

        if ($pid) {
            waitpid $pid, 0;
            print $? ? "not ok\n" : "ok\n";
        }
        else {
            open my $scr, "<", $_ or die "Can't open $_: $!";
            my $script = do { local $/; <$scr>; };
            close $scr;

            # shebang_to_perl
            my $shebang = '';
            if ( $script =~ /^#!.* -[A-Za-vx-z]*w/ ) {
                $shebang = "use warnings;\n";
            }

            # strip_end_data_segment
            $script =~ s/^__(END|DATA)__(.*)//ms;
            my $package = "$_";
            $package =~ s{[^A-Za-z0-9]}{_}g;
            $package = __PACKAGE__ . "::$package";
            my $eval = <<EOS;
package $package;
sub script {
local \$0 = '$_';
$shebang;
#line 1 $_
$script
}
EOS
            my $dir = $_;
            $dir =~ s/(?<=[\\\/])[^\\\/]+$//;
            chdir $dir if $dir;

            my @warnings;
            {
                no strict;
                no warnings;
                local $SIG{__WARN__} = sub { push @warnings, shift };
                local *STDIN;
                local *STDOUT;
                local *STDERR;
                eval $eval;
            }
            my $err = $@;

            # Print warnings if there's an error or if hide_warnings is false
            if ($err or not $params{hide_warnings}) {
                print STDERR $_ for @warnings;
            }

            # Don't want to run END blocks
            require POSIX;

            if ($err) {
                warn "Can't compile $_: $@\n";
                close STDERR;
                close STDOUT;
                POSIX::_exit(1);
            }
            else {
                POSIX::_exit(0);
            }
        }
    }
}

1;

__END__

=head1 AUTHOR

Pavel Shaydo, C<< <zwon at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Pavel Shaydo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
