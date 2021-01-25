package Test::Inline::Content;
# ABSTRACT: Test::Inline 2 Content Handlers

#pod =pod
#pod
#pod =head1 DESCRIPTION
#pod
#pod One problem with the initial versions of L<Test::Inline> 2 was the method
#pod by which it generated the script contents.
#pod
#pod C<Test::Inline::Content> provides a basic API by which more sophisticated
#pod extensions can be written to control the content of the generated scripts.
#pod
#pod =head1 METHODS
#pod
#pod =cut

use strict;
use Params::Util '_INSTANCE';

our $VERSION = '2.214';

#pod =pod
#pod
#pod =head2 new
#pod
#pod A default implementation of the C<new> method is provided that takes no
#pod parameters and creates a default (empty) object.
#pod
#pod Returns a new C<Test::Inline::Content> object.
#pod
#pod =cut

sub new {
	my $class = ref $_[0] || $_[0];
	bless {}, $class;
}

#pod =pod
#pod
#pod =head2 process $Inline $Script
#pod
#pod The C<process> method does the work of generating the script content. It
#pod takes as argument the parent L<Test::Inline> object, and the completed
#pod L<Test::Inline::Script> object for which the file is to be generated.
#pod
#pod The default implementation returns only an empty script that dies with
#pod an appropriate error message.
#pod
#pod Returns the content of the script as a string, or C<undef> on error.
#pod
#pod =cut

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Inline::Content - Test::Inline 2 Content Handlers

=head1 VERSION

version 2.214

=head1 DESCRIPTION

One problem with the initial versions of L<Test::Inline> 2 was the method
by which it generated the script contents.

C<Test::Inline::Content> provides a basic API by which more sophisticated
extensions can be written to control the content of the generated scripts.

=head1 METHODS

=head2 new

A default implementation of the C<new> method is provided that takes no
parameters and creates a default (empty) object.

Returns a new C<Test::Inline::Content> object.

=head2 process $Inline $Script

The C<process> method does the work of generating the script content. It
takes as argument the parent L<Test::Inline> object, and the completed
L<Test::Inline::Script> object for which the file is to be generated.

The default implementation returns only an empty script that dies with
an appropriate error message.

Returns the content of the script as a string, or C<undef> on error.

=head1 SUPPORT

See the main L<SUPPORT|Test::Inline/SUPPORT> section.

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Test-Inline>
(or L<bug-Test-Inline@rt.cpan.org|mailto:bug-Test-Inline@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
