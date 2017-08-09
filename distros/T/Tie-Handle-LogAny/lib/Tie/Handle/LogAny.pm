package Tie::Handle::LogAny;

our $DATE = '2017-08-08'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

sub TIEHANDLE {
    require Log::Any;

    my ($class, %args) = @_;

    my $caller = caller(0);
    $args{category} //= $caller;

    my $level = delete($args{level}) // 'warn';

    bless {
        logger => Log::Any->get_logger(%args),
        level  => $level,
    }, $class;
}

sub PRINT {
    my $self = shift;
    my $level = $self->{level};
    $self->{logger}->$level(@_);
}

1;
# ABSTRACT: Filehandle to log to Log::Any

__END__

=pod

=encoding UTF-8

=head1 NAME

Tie::Handle::LogAny - Filehandle to log to Log::Any

=head1 VERSION

This document describes version 0.001 of Tie::Handle::LogAny (from Perl distribution Tie-Handle-LogAny), released on 2017-08-08.

=head1 SYNOPSIS

 use Tie::Handle::LogAny;
 tie *FH, 'Tie::Handle::LogAny',
     level => 'debug',       # optional, default is 'warn'
     category => 'Foo::Bar', # optional, default is current package
 ;

 print FH "this is a debug log message";
 print FH "this is another debug log message";

=head1 DESCRIPTION

This module ties a filehandle to L<Log::ger> logger object. For sure a silly
module, just a proof of concept.

=head1 METHODS

=head2 TIEHANDLE classname, list

=head2 PRINT list

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tie-Handle-LogAny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tie-Handle-LogAny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tie-Handle-LogAny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::Any>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
