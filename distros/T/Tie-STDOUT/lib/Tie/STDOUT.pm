package Tie::STDOUT;

use 5.008;

no warnings; # in case they've been turned on

$VERSION = '1.0500';

use strict;

open(REALSTDOUT, ">&STDOUT");

# do this late to avoid bogus warning about only using REALSTDOUT once
use warnings;

=head1 NAME

Tie::STDOUT - intercept writes to STDOUT and apply user-defined functions
to them.

=head1 SYNOPSIS

    use Tie::STDOUT
        print => sub {
            print map { uc } @_;
        },
        printf => ... 
        syswrite => ... ;

=head1 DESCRIPTION

This module intercepts all writes to the STDOUT filehandle and applies
whatever function you desire to what would have gone to STDOUT.  In the
example above, any use of the print() function on this filehandle will
have its output transmogrified into upper case.

You will have noticed that we blithely print to the default filehandle
(which is almost always STDOUT) in the function we supplied.  Relax, this
doesn't cause an infinite loop, because your functions are always called
with a *normal* STDOUT.

You may provide up to three user-defined functions which are respectively
called whenever you use print(), printf() or syswrite() on the filehandle:

=over 4

=item print

defaults to printing to the real STDOUT;

=item printf

defaults to passing all parameters through sprintf() and then passing
them to whatever the 'print' function is;

=item syswrite

Defaults to going straight through to the real STDOUT.

=back

You will note that the default behaviour is exactly the same as it would
be without this module.

Because we have a sensible default for 'printf' and because syswrite is so
rarely used, you will normally only have to provide your own code for
'print'.

=head1 BUGS

Doesn't work on perl 5.6, because it seems that localising tied
filehandles doesn't work.

=head1 SEE ALSO

=over 4

=item Capture::Tiny

=item IO::Capture::Stdout

=item Tie::STDERR

=back

=head1 FEEDBACK

I like to know who's using my code.  All comments, including constructive
criticism, are welcome.  Please email me.

=head1 AUTHOR

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

=head1 COPYRIGHT

Copyright 2006 David Cantrell

This module is free-as-in-speech software, and may be used, distributed,
and modified under the same terms as Perl itself.

=cut

sub import {
    my $class = shift;
    my %params = @_;
    tie *STDOUT, $class, %params;
}

sub TIEHANDLE {
    my($class, %params) = @_;
    my $self = {
        print => $params{print} || sub { print @_; },
        syswrite => $params{syswrite} || sub {
            my($buf, $len, $offset) = @_;
            syswrite(STDOUT, $buf, $len, defined($offset) ? $offset : 0);
        }
    };
    $self->{printf} = $params{printf} || sub {
        $self->{print}->(sprintf($_[0], @_[1 .. $#_]))
    };
    bless($self, $class);
}

sub _with_real_STDOUT {
    open(local *STDOUT, ">&REALSTDOUT");
    $_[0]->(@_[1 .. $#_]);
}

sub PRINT   { _with_real_STDOUT(shift()->{print},  @_); }
sub PRINTF  { _with_real_STDOUT(shift()->{printf}, @_); }
sub WRITE   { _with_real_STDOUT(shift()->{syswrite}, @_); }
sub BINMODE { binmode(REALSTDOUT, $_[1]); }

1;
