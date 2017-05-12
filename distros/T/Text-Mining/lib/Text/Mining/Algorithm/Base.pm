package Text::Mining::Algorithm::Base;
use base qw(Text::Mining::Base);
use Class::Std;
use Class::Std::Utils;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.8');

{
	my %attribute_of : ATTR( get => 'attribute', set => 'attribute' );
	
	sub version { return "Text::Mining::Algorithm::Base Version $VERSION"; }

	sub BUILD {      
		my ($self, $ident, $arg_ref) = @_;

		return;
	}

	sub _by_text() {
		my ($self, $arg_ref) = @_;
		my $text = $arg_ref->{text};
		my @count = split(/\s+/, $text);
		print "algorithm->_by_text(): Found ", scalar(@count), " tokens.\n";

		return;
	}

	sub _by_section() {
		my ($self, $arg_ref) = @_;
		my $section = $arg_ref->{section};
		my @count = split(/\s+/, $section);
		print "algorithm->_by_section(): Found ", scalar(@count), " tokens.\n";

		return;
	}

	sub _by_paragraph() {
		my ($self, $arg_ref) = @_;
		my $paragraph = $arg_ref->{paragraph};
		my @count = split(/\s+/, $paragraph);
		print "algorithm->_by_paragraph(): Found ", scalar(@count), " tokens.\n";
		
		return;
	}

	sub _by_line() {
		my ($self, $arg_ref) = @_;
		my $line = $arg_ref->{line};
		my @count = split(/\s+/, $line);
		print "algorithm->_by_line(): Found ", scalar(@count), " tokens.\n";
		
		return;
	}
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Text::Mining::Algorithm::Base - Flexible Token Algorithms for Text Mining


=head1 VERSION

This document describes Text::Mining::Algorithm::Base version 0.0.8


=head1 SYNOPSIS

See L<Text::Mining::Parser|http://search.cpan.org/~rogerhall/Text-Mining/lib/Text/Mining/Parser.pm>
  
=head1 DESCRIPTION

This is the base module for token algorithms. It implements each scope method with 
nulls returned.  To create a new token algorithm, create a new module in the same 
directory, use this module as a base, and implement one or more _by_<scope>() methods.

=head1 INTERFACE 


=head1 DIAGNOSTICS


=head1 CONFIGURATION AND ENVIRONMENT


=head1 DEPENDENCIES


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-text-mining-algorithm-base@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHORS

Roger A Hall  C<< <rogerhall@cpan.org> >>
Michael Bauer  C<< <mbkodos@gmail.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, the Authors. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
