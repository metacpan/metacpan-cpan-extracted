package Test::Inline::Content;

=pod

=head1 NAME

Test::Inline::Content - Test::Inline 2 Content Handlers

=head1 DESCRIPTION

One problem with the initial versions of L<Test::Inline> 2 was the method
by which it generated the script contents.

C<Test::Inline::Content> provides a basic API by which more sophisticated
extensions can be written to control the content of the generated scripts.

=head1 METHODS

=cut

use strict;
use Params::Util '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '2.213';
}

=pod

=head2 new

A default implementation of the C<new> method is provided that takes no
parameters and creates a default (empty) object.

Returns a new C<Test::Inline::Content> object.

=cut

sub new {
	my $class = ref $_[0] || $_[0];
	bless {}, $class;
}

=pod

=head2 process $Inline $Script

The C<process> method does the work of generating the script content. It
takes as argument the parent L<Test::Inline> object, and the completed
L<Test::Inline::Script> object for which the file is to be generated.

The default implementation returns only an empty script that dies with
an appropriate error message.

Returns the content of the script as a string, or C<undef> on error.

=cut

sub process {
	my $self   = shift;
	my $Inline = _INSTANCE(shift, 'Test::Inline')         or return undef;
	my $Script = _INSTANCE(shift, 'Test::Inline::Script') or return undef;

	# If used directly, create a valid script file that just dies
	my $class   = $Script->class;
	my $content = <<"END_PERL";
#!/usr/bin/perl

use strict;
use Test::More tests => 1;

fail('Generation of inline test script for $class failed' );

exit(0);
END_PERL

	return $content;
}

1;

=pod

=head1 SUPPORT

See the main L<SUPPORT|Test::Inline/SUPPORT> section.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2004 - 2013 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
