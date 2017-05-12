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
		say q{A man walked into a bar.};
		say q{"Ouch," he said.};
		say q{It was an iron bar.};
	}

	sub tellAnotherJoke
	{
		my $self = shift;
		printf("Did you hear the one about the %s?\n", $self->_get_pkg);
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
		say "An Englishman, a Scotsman and an Irishman walk into a bar.";
		say "The bartender says, 'is this some kind of joke?'";
	}

	sub tellAnotherJoke2
	{
		my $self = shift;
		printf("Have you heard the one about the %s?\n", $self->_get_pkg);
	}

	sub _get_pkg
	{
		__PACKAGE__;
	}

	sub yetAnotherJoke2
	{
		my $self = shift;
		my $get_pkg = __PACKAGE__->can('_get_pkg');
		printf("Have you heard the one about the safer %s?\n", $self->$get_pkg);
	}
}

package main;

use 5.010;
use strict;
use XML::LibXML::Augment;

my $doc = XML::LibXML::Augment::upgrade( XML::LibXML->load_xml(IO => \*DATA) );
my $bar = $doc->findnodes('//*[@baz]')->shift;

say ref $doc;
say "--";
$bar->tellJoke;
say "--";
$bar->tellJoke2;
say "--";
$bar->tellAnotherJoke;
say "--";
$bar->tellAnotherJoke2; # disappointing
say "--";
$bar->yetAnotherJoke2;  # work around
say "--";

__DATA__
<foo xmlns="http://example.com/">
	<bar baz="1" />
</foo>
