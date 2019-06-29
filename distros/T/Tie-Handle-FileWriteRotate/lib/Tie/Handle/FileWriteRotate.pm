package Tie::Handle::FileWriteRotate;

our $DATE = '2019-06-27'; # DATE
our $VERSION = '0.040'; # VERSION

use 5.010001;
use strict;
use warnings;

use File::Write::Rotate;

sub TIEHANDLE {
    my ($class, %args) = @_;

    bless {
        fwr => File::Write::Rotate->new(%args),
    }, $class;
}

sub PRINT {
    my $self = shift;
    $self->{fwr}->write(@_);
}

sub CLOSE {
}

1;
# ABSTRACT: Filehandle tie to write to autorotated file with File::Write::Rotate

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Handle::FileWriteRotate - Filehandle tie to write to autorotated file with File::Write::Rotate

=head1 VERSION

This document describes version 0.040 of Tie::Handle::FileWriteRotate (from Perl distribution Tie-Handle-FileWriteRotate), released on 2019-06-27.

=head1 SYNOPSIS

 use Tie::Handle::FileWriteRotate;
 tie *FH, 'Tie::Handle::FileWriteRotate',
     dir=>'/some/dir', prefix=>'myapp', size=>25*1024*1024, histories=>5;
 print FH "Logging a line\n";
 print FH "Logging another line\n";

=head1 DESCRIPTION

This module ties a filehandle to L<File::Write::Rotate> object.

I first wrote this module to tie STDERR, so that warnings/errors are logged to
file instead of terminal (with autorotation, for good behavior).

=head1 TIPS

To log warnings/errors to terminal I<as well as> autorotated file, you can do
something like this instead:

 my $fwr = File::Write::Rotate->new(...);
 $SIG{__WARN__} = sub {
     $fwr->write(~~localtime, " ", $_[0], "\n");
     warn $_[0];
 };
 $SIG{__DIE__} = sub {
     $fwr->write(~~localtime, " ", $_[0], "\n");
     die $_[0];
 };

=head1 METHODS

=head2 TIEHANDLE classname, LIST

Tie this package to file handle. C<LIST> will be passed to
L<File::Write::Rotate>'s constructor.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Handle-FileWriteRotate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Handle-FileWriteRotate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Handle-FileWriteRotate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Write::Rotate>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
