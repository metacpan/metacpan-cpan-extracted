package XML::LibXML::Augment;

use 5.010;
use strict;
use warnings;

use Carp qw//;
use Class::Inspector;
use match::simple qw/match/;
use Module::Runtime qw/module_notional_filename/;
use Scalar::Util qw/blessed/;
use XML::LibXML 1.95 qw/:libxml/;

my %Delegates;

BEGIN
{
	$XML::LibXML::Augment::AUTHORITY = 'cpan:TOBYINK';
	$XML::LibXML::Augment::VERSION   = '0.004';
	
	no strict 'refs';
	no warnings 'once';
	
	my @_CLASSES = qw/
		Node Document DocumentFragment Element Attr
		Text CDATASection Comment Dtd PI NodeList
	/;

	# It would be nice to not need to include this block,
	# but it's currently necessary for Dist::Inkt and the
	# PAUSE indexer...
	{
		package XML::LibXML::Augment::Node;
		package XML::LibXML::Augment::Document;
		package XML::LibXML::Augment::DocumentFragment;
		package XML::LibXML::Augment::Element;
		package XML::LibXML::Augment::Attr;
		package XML::LibXML::Augment::Text;
		package XML::LibXML::Augment::CDATASection;
		package XML::LibXML::Augment::Comment;
		package XML::LibXML::Augment::Dtd;
		package XML::LibXML::Augment::PI;
		package XML::LibXML::Augment::NodeList;
	}

	foreach my $class (@_CLASSES)
	{
		if (match $class, [qw/Comment CDATASection/])
		{
			# Comment and CDATASection inherit from Text
			push @{"XML::LibXML::Augment::${class}::ISA"},
				"XML::LibXML::Augment::Text";
		}
		elsif ($class ne 'Node' and $class ne 'NodeList')
		{
			# Everything inherits from Node
			push @{"XML::LibXML::Augment::${class}::ISA"},
				"XML::LibXML::Augment::Node";
		}
		
		# Inherit from XML::LibXML counterpart
		push @{"XML::LibXML::Augment::${class}::ISA"},
			"XML::LibXML::${class}";

		# $AUTHORITY and $VERSION
		${"XML::LibXML::Augment::${class}::AUTHORITY"} =
			$XML::LibXML::Augment::AUTHORITY;
		${"XML::LibXML::Augment::${class}::VERSION"} =
			$XML::LibXML::Augment::VERSION;
		
		# Trick "use".
		$INC{ module_notional_filename("XML::LibXML::Augment::${class}") }
			= __FILE__;

		# Create &rebless.
		my $our_rebless = sprintf('%s::%s::%s', __PACKAGE__, $class, 'rebless');
		*$our_rebless = sub
		{
			my $self = bless $_[1], $_[0];
			if (my $onbless = $self->can('BLESS'))
			{
				$self->$onbless;
			}
			return $self;
		};
		
		# Create stub functions mirroring the superclass.
		my $our_handler = sprintf('%s::%s', __PACKAGE__, '_handler');
		my $functions   = Class::Inspector->functions('XML::LibXML::'.$class);
		foreach my $fname (@$functions)
		{
			next if $fname =~ /^(_|DESTROY|AUTOLOAD)/;
			my $our_qname   = sprintf('%s::%s::%s', __PACKAGE__, $class, $fname);
			*$our_qname     = sub { unshift @_, $class, $fname; goto \&{$our_handler} };
		}
	}
}

sub import
{
	my ($class, %args) = @_;
	
	my $caller  = caller;
	my $type    = ucfirst lc(delete($args{'-type'}) || 'Element');
	my $names   = delete($args{'-names'});
	my $isa     = delete($args{'-isa'})
		|| ["XML::LibXML::Augment::$type"];
	
	if (keys %args)
	{
		my $args = join q{, }, map {"'$_'"} sort keys %args;
		Carp::croak(__PACKAGE__." does not support args: $args");
	}
	
	Carp::croak("-type argument must be 'Element', 'Attr' or 'Document'")
		unless match $type, [qw/Attr Document Element/];
	
	foreach my $n (@$names)
	{
		if (ref $Delegates{$type}{$n} eq 'ARRAY')
		{
			push @{ $Delegates{$type}{$n} }, $caller;
		}
		elsif (defined $Delegates{$type}{$n})
		{
			$Delegates{$type}{$n} = [$Delegates{$type}{$n}, $caller];
		}
		else
		{
			$Delegates{$type}{$n} = $caller;
		}
	}

	no strict 'refs';
	push @{"$caller\::ISA"}, @$isa;
	
	$class;
}

sub rebless
{
	my ($class, $object) = @_;
	my $ideal = $class->ideal_class_for_object($object);
	$ideal->rebless($object) if $ideal;
	return $object;
}

sub ideal_class_for_object
{
	my ($me, $object) = @_;
	return unless ref $object && blessed $object;
	my $nodeType = $object->can('nodeType') && $object->nodeType;
	$nodeType = -1 if $object->isa('XML::LibXML::NodeList');
	return unless $nodeType;
	
	my $ideal = {
		(-1)                      => 'NodeList',
		(XML_ELEMENT_NODE)        => 'Element',
		(XML_ATTRIBUTE_NODE)      => 'Attr',
		(XML_TEXT_NODE)           => 'Text',
		(XML_CDATA_SECTION_NODE)  => 'CDATASection',
		(XML_PI_NODE)             => 'PI',
		(XML_COMMENT_NODE)        => 'Comment',
		(XML_DOCUMENT_NODE)       => 'Document',
		(XML_DOCUMENT_FRAG_NODE)  => 'DocumentFragment',
		(XML_DTD_NODE)            => 'Dtd',
	}->{$nodeType};
	
	# This is where we get smart
	if ($ideal eq 'Element' or $ideal eq 'Attr' or $ideal eq 'Document')
	{
		my ($ns, $local);
		if ($ideal eq 'Document')
		{
			$ns = $object->documentElement->namespaceURI // '';
			$ns = sprintf('{%s}', $ns) if length $ns;
			$local = $object->documentElement->localname;
		}
		else
		{
			$ns = $object->namespaceURI // '';
			$ns = sprintf('{%s}', $ns) if length $ns;
			$local = $object->localname;
		}
		
		foreach my $clark (map { sprintf('%s%s', $ns, $_) } $local, '*')
		{
			if (my $i = $Delegates{$ideal}{$clark})
			{
				$Delegates{$ideal}{$clark} = $me->make_class(@{$i}) if ref $i;
				return $Delegates{$ideal}{$clark};
			}
		}
	}
	
	return sprintf('%s::%s', __PACKAGE__, $ideal) if defined $ideal;
	return;
}

sub make_class
{
	shift;
	state $COUNT = 0;
	state $NS    = (__PACKAGE__.'::_ANON_::');
	
	if (scalar @_ == 1)
	{
		return $_[0];
	}
	
	$COUNT++;
	no strict 'refs';
	
	my $newpkg = sprintf('%sCLS%04d', $NS, $COUNT);
	
	my @super;
	foreach my $x (@_)
	{
		if ($x =~ m{ ^ $NS }x)
		{
			push @super, @{"$x\::ISA"};
		}
		else
		{
			push @super, $x;
		}
	}
	@{"$newpkg\::ISA"} = @super;
	
	my @blesses = map { my $x = $_->can('BLESS'); $x ? ($x) : () } @super;
	*{"$newpkg\::BLESS"} = sub
	{
		my $self = shift;
		$self->$_ foreach @blesses;
	};
	
	return $newpkg;
}

sub _handler
{
	no strict 'refs';
	my $class   = shift;
	my $sub     = shift;
	my $coderef = "XML::LibXML::$class"->can($sub);
	
	if (!defined wantarray)
	{
		goto $coderef;
	}
	
	if (wantarray)
	{
		@_ = $coderef->(@_);
		goto \&upgrade;
	}
	
	@_ = (my $r = $coderef->(@_));
	goto \&upgrade;
}

sub upgrade
{
	for my $i (0 .. $#_)
	{
		if (blessed($_[$i]) and $_[$i]->isa('XML::LibXML::NodeList'))
		{
			my $me = __PACKAGE__->can('upgrade');
			$_[$i] = $_[$i]->foreach($me);
			next;
		}
		my $ideal = __PACKAGE__->ideal_class_for_object($_[$i]);
		$ideal->rebless($_[$i]) if defined $ideal;
	}
	
	wantarray ? @_ : $_[0]
}

__PACKAGE__
__END__

=pod

=encoding utf-8

=head1 NAME

XML::LibXML::Augment - extend XML::LibXML::{Attr,Element,Document} on a per-namespace/element basis

=head1 SYNOPSIS

 {
   package Local::Element::Bar;
   
   use 5.010;
   use strict;
   use warnings;
   use XML::LibXML::Augment -names => ['{http://example.com/}bar'];
   
   sub tellJoke
   {
     say q{A man walked into a bar.};
     say q{"Ouch," he said.};
     say q{It was an iron bar.};
   }
 }
 
 {
   package main;
   
   use 5.010;
   use strict;
   use warnings;
   use XML::LibXML::Augment;
   
   my $doc = XML::LibXML->load_xml(string => <<'XML');
   <foo xmlns="http://example.com/">
     <bar baz="1" />
   </foo>
   XML
   
   XML::LibXML::Augment->upgrade($doc);
   $doc->findnodes('//*[@baz]')->shift->tellJoke;
 }

=head1 DESCRIPTION

XML::LibXML is super-awesome. However, I don't know about you, but
sometimes I wish it had some domain-specific knowledge. For example,
if I have an XML::LibXML::Element which represents an HTML C<< <form> >>
element, why can't it have a C<submit> method?

OK, so I can subclass XML::LibXML::Element, but then I call C<childNodes>
on my subclass, and get back plain, non-subclassed objects, and I'm
back where I first began.

XML::LibXML::Augment is the package I've been meaning to write for
quite some time, to take care of all those issues.

The magic is in the import method. You write a package which imports
XML::LibXML::Augment with particular settings. Then, once you've parsed 
the document, you call C<< XML::LibXML::Augment->upgrade >> on the root
node.

=head2 C<< import %args >>

Currently three options are supported. Each has a leading hyphen.

=head3 C<< -names => \@list >>

Each item on the list is the name of an element you want to override.
If the element is in a namespace, use Clark notation:

 {http://www.example.com/namespace}localname

If the element is not in a namespace, then leave out the curly braces.
Because of clashes (see "Conflict resolution" in CAVEATS below) it
seems like a bad idea to try to augment non-namespaced elements based
entirely on their localname. But, hey, you want to do it? It's your
funeral.

You can use "*" as the localname to indicate that you wish to subclass all
elements in a particular namespace. (Again, see "Conflict resolution".)

Yes, this is a list, because it might make sense to use the same package
to cover, say, HTML C<< <a> >>, C<< <link> >> and C<< <area> >> elements.

=head3 C<< -type => $type >>

C<$type> can be either 'Element', 'Attr' or 'Document', but defaults to
'Element'. This indicates what sort of thing you're subclassing. Only
elements, attributes and documents are supported. (Document subclassing
is based on the namespace and localname of its root element.)

Elements, attributes and documents are pairwise disjoint classes, so you
cannot (for example) subclass elements B<and> attributes in the same package.

=head3 C<< -isa => \@packages >>

Normally the import routine will automatically establish your package
as a subclass of XML::LibXML::Augment::Attr or XML::LibXML::Augment::Element
by monkeying around with your C<< @ISA >>.

There are times when you want more precise control over C<< @ISA >>
though, such as inheritance heirarchies:

  Local::HTML::TableHeader
     -> Local::HTML::TableCell
        -> Local::HTML::Element
           -> XML::LibXML::Augment::Element

In this case, you probably want to use the automatic subclassing for
Local::HTML::Element, but not for the other two classes, which would work
better with explicit subclassing:

 {
   package Local::HTML::TableCell;
   use XML::LibXML::Augment
     -names => ['{http://www.w3.org/1999/xhtml}td'],
     -isa   => ['Local::HTML::Element'];
 }

=head2 C<< upgrade(@things) >>

This is a function, not a method. It's not exported, so call it with its
full name:

 XML::LibXML::Augment::upgrade(@things);

Upgrades the things in-place, skipping over things that cannot be upgraded,
and returns the things as a list. You can of course call it like this:

 @upgraded = XML::LibXML::Augment->upgrade(@things);

But bear in mind that because of the way Perl method calls work, this is
effectively the same as:

 @upgraded = (
   'XML::LibXML::Augment',
   XML::LibXML::Augment::upgrade(@things),
   );

What is upgrading? Things that are not blessed objects are not upgradable.
Blessed objects that XML::LibXML::Augment can find an appropriate subclass
for are reblessed into that package (e.g. XML::LibXML::Comment is reblessed
into XML::LibXML::Augment::Comment). The nodes in XML::LibXML::NodeLists
are reblessed.

=head2 C<< rebless($thing) >>

This is basically a single-argument version C<upgrade> but designed to be
called as a class method, and doesn't recurse into nodelists.

  my $upgraded = XML::LibXML::Augment->rebless($element);

Note that $element is actually upgraded in-place.

  refaddr($upgraded) == refaddr($element); # true

=head2 C<< ideal_class_for_object($object) >>

Calculates the class that C<rebless> would bless the object into, but doesn't
actually do the reblessing.

=head2 C<< make_class(@superclasses) >>

Constructs a new class that is a subclass of the given classes. Call
this as a class method. Returns the class name. This is a method used
internally by XML::LibXML::Augment, documented in case anybody else
wants to use it.

=head2 C<< BLESS >>

XML::LibXML::Augment doesn't actually have a method called C<BLESS>, but
your package can do.

Inspired by Moose's C<BUILD> method, your package's C<BLESS> method will
be called (if it exists) just after an XML::LibXML node is reblessed into
your package. Unlike Moose's C<BUILD> method, the inheritance chain isn't
automatically walked. It is your package's responsibility to call
C<SUPER::BLESS> if required.

Do bear in mind that XML::LibXML's node objects are little more than
pointers to the "real" XML nodes that live on the C side of the XS
divide. As such, XML::LibXML can (and frequently does) destroy and
re-instantiate the pointers willy-nilly. This may limit the usefulness
of C<BLESS>.

=head1 HOW DOES IT WORK?

Mostly just careful use of inheritance.

=head1 CAVEATS

=head2 Conflict resolution

Only one class can handle any given element. If two different modules
want to subclass, say, XHTML C<< <form> >> elements, there can be only
one winner. So, which one wins? Neither. XML::LibXML::Augment creates
a brand, spanking new class which inherits from both, and that new class
wins. This will usually work, but may trip up sometimes. The C<joke.pl>
example bundled with the XML-LibXML-Augment release gives a demonstration
of this feature.

Note that packages which use an element wildcard, for instance:

 package Local::HTML::Element;
 use XML::LibXML::Augment -names => ['{http://www.w3.org/1999/xhtml}*'];

are treated purely as fallbacks. If there exists a non-wildcard class
to handle an element, then the wildcard class will be ignored
altogether - it won't be included in the funky on-the-fly class
generation described above.

For these reasons, wildcards are perhaps best avoided. It's usually better
to do something like:

 package Local::HTML::Element;
 our @ELEMENTS;
 BEGIN {
   @ELEMENTS = map { "{http://www.w3.org/1999/xhtml}$_" }
     qw/a area b col colgroup ... u/;
 }
 use XML::LibXML::Augment -names => \@ELEMENTS;


=head2 XML::LibXML::XPathContext

We don't touch XML::LibXML::XPathContext. Results from calling, e.g.
C<findnodes> on an XPath context will return plain old XML::LibXML
nodes. (You can of course upgrade them.) That doesn't render XPath
completely unusable though - XML::LibXML::Node also has a C<findnodes>
method, which B<will> return upgraded objects.

=head2 Subclassing B<all> elements (or all attributes)

XML::LibXML::Augment requires you to specify the namespace URI and
localname of the elements/attributes you wish to subclass. If you want
to provide additional methods to B<all> XML::LibXML::Elements, then
perhaps XML::LibXML::Augment is not for you. Try:

 sub XML::LibXML::Element::myAwesomeMethod {
   ...
 }

If you think adding methods to other peoples' classes is evil, then
go write some Java and quit complaining.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=XML-LibXML-Augment>.

=head1 SEE ALSO

L<XML::LibXML>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

