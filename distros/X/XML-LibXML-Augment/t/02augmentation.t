=pod

=encoding utf-8

=head1 PURPOSE

Check L<XML::LibXML::Augment> actually works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

{
	package Local::Document::Example;

	use 5.010;
	use strict;
	use XML::LibXML::Augment
		-type   => 'Document',
		-names  => [qw! {http://example.com/}* !];
}

{
	package Local::Element::Bar;

	use 5.010;
	use strict;
	use XML::LibXML::Augment
		-type   => 'Element',
		-names  => [qw! {http://example.com/}bar !];

	sub tellJoke
	{
		return q{A man walked into a bar.}
			. q{"Ouch," he said.}
			. q{It was an iron bar.};
	}

	sub tellAnotherJoke
	{
		my $self = shift;
		sprintf("Did you hear the one about the %s?\n", $self->_get_pkg);
	}

	sub _get_pkg
	{
		__PACKAGE__;
	}
}

{
	package Local::Element::Bar2;

	use 5.010;
	use strict;
	use XML::LibXML::Augment
		-type   => 'Element',
		-names  => [qw! {http://example.com/}bar !];

	sub tellJoke2
	{
		return "An Englishman, a Scotsman and an Irishman walk into a bar."
			. "The bartender says, 'is this some kind of joke?'";
	}

	sub tellAnotherJoke2
	{
		my $self = shift;
		sprintf("Have you heard the one about the %s?\n", $self->_get_pkg);
	}

	sub _get_pkg
	{
		__PACKAGE__;
	}

	sub yetAnotherJoke2
	{
		my $self = shift;
		my $get_pkg = __PACKAGE__->can('_get_pkg');
		sprintf("Have you heard the one about the safer %s?\n", $self->$get_pkg);
	}
}

package main;

use 5.010;
use strict;
use Test::More tests => 7;
use XML::LibXML::Augment;

my $doc = XML::LibXML::Augment::upgrade( XML::LibXML->load_xml(IO => \*DATA) );
my $bar = $doc->findnodes('//*[@baz]')->shift;

isa_ok($doc, 'Local::Document::Example', '$doc');
isa_ok($bar, 'Local::Element::Bar', '$bar');
isa_ok($bar, 'Local::Element::Bar2', '$bar');
is($bar->tellJoke, Local::Element::Bar->tellJoke, 'method inherited from L:E:Bar');
is($bar->tellJoke2, Local::Element::Bar2->tellJoke2, 'method inherited from L:E:Bar2');
is($bar->tellAnotherJoke, Local::Element::Bar->tellAnotherJoke);
is($bar->yetAnotherJoke2, Local::Element::Bar2->yetAnotherJoke2);

__DATA__
<foo xmlns="http://example.com/">
	<bar baz="1" />
</foo>
