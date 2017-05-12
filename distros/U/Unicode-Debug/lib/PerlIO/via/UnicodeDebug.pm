package PerlIO::via::UnicodeDebug;

use 5.008001;
use strict;
use warnings;
use utf8;

use Unicode::Debug 'unidecode';

BEGIN
{
	$PerlIO::via::UnicodeDebug::AUTHORITY = 'cpan:TOBYINK';
	$PerlIO::via::UnicodeDebug::VERSION   = '0.002';
}

sub PUSHED
{
	bless \*PUSHED, $_[0];
}

sub FILL
{
	my $line = readline( $_[1] );
	(defined $line) ? unidecode( $line ) : undef;
}

sub WRITE
{
	my $x = $_[1];
	utf8::decode($x);
	unidecode($x);
	( print {$_[2]} $x ) ? length($_[1]) : -1;
}

__PACKAGE__
__END__

=pod

=encoding utf8

=head1 NAME

PerlIO::via::UnicodeDebug - debug Unicode input/output

=head1 SYNOPSIS

 use Unicode::Debug;
 binmode STDOUT, ':via(UnicodeDebug)' or die $!;
 
 print "Héllò Wörld\n";

Or perhaps in your test suite...

 use strict;
 use warnings;
 use utf8;
 use Test::More;
 
 if (eval { require Unicode::Debug })
 {
    my $builder = Test::More->builder;
    binmode $builder->$_, ':via(UnicodeDebug)'
       for qw/ output failure_output todo_output /;
 }
 
 ...;   # Unicode-emitting tests go here

=head1 DESCRIPTION

Passes IO through L<Unicode::Debug>.

=begin private

=item PUSHED

=item FILL

=item WRITE

=end private

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Unicode-Debug>.

=head1 SEE ALSO

L<Unicode::Debug>,
L<Devel::Unicode>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

