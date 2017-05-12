package XML::Rules;

use warnings;
no warnings qw(uninitialized);
use strict;
use Carp;
use 5.008;
use Scalar::Util qw(weaken);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(paths2rules);

use XML::Parser::Expat;

use constant STRIP => "0000";
use constant STRIP_RULE => 'pass';

#use Data::Dumper;
#$Data::Dumper::Indent = 1;
#$Data::Dumper::Terse = 1;
#$Data::Dumper::Quotekeys = 0;
#$Data::Dumper::Sortkeys = 1;


=head1 NAME

XML::Rules - parse XML and specify what and how to keep/process for individual tags

=head1 VERSION

Version 1.16

=cut

our $VERSION = '1.16';

=head1 SYNOPSIS

	use XML::Rules;

	$xml = <<'*END*';
	<doc>
	 <person>
	  <fname>...</fname>
	  <lname>...</lname>
	  <email>...</email>
	  <address>
	   <street>...</street>
	   <city>...</city>
	   <country>...</country>
	   <bogus>...</bogus>
	  </address>
	  <phones>
	   <phone type="home">123-456-7890</phone>
	   <phone type="office">663-486-7890</phone>
	   <phone type="fax">663-486-7000</phone>
	  </phones>
	 </person>
	 <person>
	  <fname>...</fname>
	  <lname>...</lname>
	  <email>...</email>
	  <address>
	   <street>...</street>
	   <city>...</city>
	   <country>...</country>
	   <bogus>...</bogus>
	  </address>
	  <phones>
	   <phone type="office">663-486-7891</phone>
	  </phones>
	 </person>
	</doc>
	*END*

	@rules = (
		_default => sub {$_[0] => $_[1]->{_content}},
			# by default I'm only interested in the content of the tag, not the attributes
		bogus => undef,
			# let's ignore this tag and all inner ones as well
		address => sub {address => "$_[1]->{street}, $_[1]->{city} ($_[1]->{country})"},
			# merge the address into a single string
		phone => sub {$_[1]->{type} => $_[1]->{_content}},
			# let's use the "type" attribute as the key and the content as the value
		phones => sub {delete $_[1]->{_content}; %{$_[1]}},
			# remove the text content and pass along the type => content from the child nodes
		person => sub { # lets print the values, all the data is readily available in the attributes
			print "$_[1]->{lname}, $_[1]->{fname} <$_[1]->{email}>\n";
			print "Home phone: $_[1]->{home}\n" if $_[1]->{home};
			print "Office phone: $_[1]->{office}\n" if $_[1]->{office};
			print "Fax: $_[1]->{fax}\n" if $_[1]->{fax};
			print "$_[1]->{address}\n\n";
			return; # the <person> tag is processed, no need to remember what it contained
		},
	);
	$parser = XML::Rules->new(rules => \@rules);
	$parser->parse( $xml);

=head1 INTRODUCTION

There are several ways to extract data from XML. One that's often used is to read the whole file and transform it into a huge maze of objects and then write code like

	foreach my $obj ($XML->forTheLifeOfMyMotherGiveMeTheFirstChildNamed("Peter")->pleaseBeSoKindAndGiveMeAllChildrenNamedSomethingLike("Jane")) {
		my $obj2 = $obj->sorryToKeepBotheringButINeedTheChildNamed("Theophile");
		my $birth = $obj2->whatsTheValueOfAttribute("BirthDate");
		print "Theophile was born at $birth\n";
	}

I'm exagerating of course, but you probably know what I mean. You can of course shorten the path and call just one method ... that is if you spend the time to learn one more "cool" thing starting with X. XPath.

You can also use XML::Simple and generate an almost equaly huge maze of hashes and arrays ... which may make the code more or less complex. In either case you need to have enough memory
to store all that data, even if you only need a piece here and there.

Another way to parse the XML is to create some subroutines that handle the start and end tags and the text and whatever else may appear in the XML. Some modules will let you specify just one for start tag, one for text and one for end tag, others will let you install different handlers for different tags. The catch is that you have to build your data structures yourself, you have to know where you are, what tag is just open and what is the parent and its parent etc. so that you could add the attributes and especially the text to the right place. And the handlers have to do everything as their side effect. Does anyone remember what do they say about side efects? They make the code hard to debug, they tend to change the code into a maze of interdependent snippets of code.

So what's the difference in the way XML::Rules works? At the first glance, not much. You can also specify subroutines to be called for the tags encountered while parsing the XML, just like the other even based XML parsers. The difference is that you do not have to rely on side-effects if all you want is to store the value of a tag. You simply return whatever you need from the current tag and the module will add it at the right place in the data structure it builds and will provide it to the handlers for the parent tag. And if the parent tag does return that data again it will be passed to its parent and so forth. Until we get to the level at which it's convenient to handle all the data we accumulated from the twig.

Do we want to keep just the content and access it in the parent tag handler under a specific name?

	foo => sub {return 'foo' => $_[1]->{_content}}

Do we want to ornament the content a bit and add it to the parent tag's content?

	u => sub {return '_' . $_[1]->{_content} . '_'}
	strong =>  sub {return '*' . $_[1]->{_content} . '*'}
	uc =>  sub {return uc($_[1]->{_content})}

Do we want to merge the attributes into a string and access the string from the parent tag under a specified name?

	address => sub {return 'Address' => "Street: $_[1]->{street} $_[1]->{bldngNo}\nCity: $_[1]->{city}\nCountry: $_[1]->{country}\nPostal code: $_[1]->{zip}"}

and in this case the $_[1]->{street} may either be an attribute of the <address> tag or it may be ther result of the handler (rule)

	street => sub {return 'street' => $_[1]->{_content}}

and thus come from a child tag <street>. You may also use the rules to convert codes to values

	our %states = (
	  AL => 'Alabama',
	  AK => 'Alaska',
	  ...
	);
	...
	state => sub {return 'state' => $states{$_[1]->{_content}}; }

 or

	address => sub {
		if (exists $_[1]->{id}) {
			$sthFetchAddress->execute($_[1]->{id});
			my $addr = $sthFetchAddress->fetchrow_hashref();
			$sthFetchAddress->finish();
			return 'address' => $addr;
		} else {
			return 'address' => $_[1];
		}
	}

so that you do not have to care whether there was

	<address id="147"/>

or

	<address><street>Larry Wall's St.</street><streetno>478</streetno><city>Core</city><country>The Programming Republic of Perl</country></address>

And if you do not like to end up with a datastructure of plain old arrays and hashes, you can create
application specific objects in the rules

	address => sub {
		my $type = lc(delete $_[1]->{type});
		$type.'Address' => MyApp::Address->new(%{$_[1]})
	},
	person => sub {
		'@person' => MyApp::Person->new(
			firstname => $_[1]->{fname},
			lastname => $_[1]->{lname},
			deliveryAddress => $_[1]->{deliveryAddress},
			billingAddress => $_[1]->{billingAddress},
			phone => $_[1]->{phone},
		)
	}


At each level in the tree structure serialized as XML you can decide what to keep, what to throw away, what to transform and
then just return the stuff you care about and it will be available to the handler at the next level.

=head1 CONSTRUCTOR

	my $parser = XML::Rules->new(
		rules => \@rules,
		[ start_rules => \@start_rules, ]
		[ stripspaces => 0 / 1 / 2 / 3   +   0 / 4   +   0 / 8, ]
		[ normalisespaces => 0 / 1, ]
		[ style => 'parser' / 'filter', ]
		[ ident => '  ', [reformat_all => 0 / 1] ],
		[ encode => 'encoding specification', ]
		[ output_encoding => 'encoding specification', ]
		[ namespaces => \%namespace2alias_mapping, ]
		[ handlers => \%additional_expat_handlers, ]
		# and optionaly parameters passed to XML::Parser::Expat
	);

Options passed to XML::Parser::Expat : ProtocolEncoding Namespaces NoExpand Stream_Delimiter ErrorContext ParseParamEnt Base

The "stripspaces" controls the handling of whitespace. Please see the C<Whitespace handling> bellow.

The "style" specifies whether you want to build a parser used to extract stuff from the XML or filter/modify the XML. If you specify
style => 'filter' then all tags for which you do not specify a subroutine rule or that occure inside such a tag are copied to the output filehandle
passed to the ->filter() or ->filterfile() methods.

The "ident" specifies what character(s) to use to ident the tags when filtering, by default the tags are not formatted in any way. If the
"reformat_all" is not set then this affects only the tags that have a rule and their subtags. And in case of subtags only those that were
added into the attribute hash by their rules, not those left in the _content array!

The "warnoverwrite" instructs XML::Rules to issue a warning whenever the rule cause a key in a tag's hash to be overwritten by new
data produced by the rule of a subtag. This happens eg. if a tag is repeated and its rule doesn't expect it.

The "encode" allows you to ask the module to run all data through Encode::encode( 'encoding_specification', ...)
before being passed to the rules. Otherwise all data comes as UTF8.

The "output_encoding" on the other hand specifies in what encoding is the resulting data going to be, the default is again UTF8.
This means that if you specify

	encode => 'windows-1250',
	output_encoding => 'utf8',

and the XML is in ISO-8859-2 (Latin2) then the filter will 1) convert the content and attributes of the tags you are not interested in from Latin2
directly to utf8 and output and 2) convert the content and attributes of the tags you want to process from Latin2 to Windows-1250, let you mangle
the data and then convert the results to utf8 for the output.

The C<encode> and C<output_enconding> affects also the C<$parser->toXML(...)>, if they are different then the data are converted from
one encoding to the other.

The C<handlers> allow you to set additional handlers for XML::Parser::Expat->setHandlers.
Your Start, End, Char and XMLDecl handlers are evaluated before the ones installed by XML::Rules and may
modify the values in @_, but you should be very carefull with that. Consider that experimental and if you do make
that work the way you needed, please let me know so that I know what was it good for and can make sure
it doesn't break in a new version.

=head2 The Rules

The rules option may be either an arrayref or a hashref, the module doesn't care, but if you want to use regexps to specify the groups of tags to be handled
by the same rule you should use the array ref. The rules array/hash is made of pairs in form

	tagspecification => action

where the tagspecification may be either a name of a tag, a string containing comma or pipe ( "|" ) delimited list of tag names
or a string containing a regexp enclosed in // optionaly followed by the regular expression modifiers or a qr// compiled regular expressions.
The tag names and tag name lists take precedence to the regexps, the regexps are (in case of arrayrefs only!!!) tested in the order in which
they are specified.

These rules are evaluated/executed whenever a tag if fully parsed including all the content and child tags and they may access the content and attributes of the
specified tag plus the stuff produced by the rules evaluated for the child tags.

The action may be either

	- an undef or empty string = ignore the tag and all its children
	- a subroutine reference = the subroutine will be called to handle the tag data&contents
		sub { my ($tagname, $attrHash, $contexArray, $parentDataArray, $parser) = @_; ...}
	- one of the built in rules below

=head3 Custom rules

The subroutines in the rules specification receive five parameters:

	$rule->( $tag_name, \%attrs, \@context, \@parent_data, $parser)

It's OK to destroy the first two parameters, but you should treat the other three as read only
or at least treat them with care!

	$tag_name = string containing the tag name
	\%attrs = hash containing the attributes of the tag plus the _content key
		containing the text content of the tag. If it's not a leaf tag it may
		also contain the data returned by the rules invoked for the child tags.
	\@context = an array containing the names of the tags enclosing the current
		one. The parent tag name is the last element of the array. (READONLY!)
	\@parent_data = an array containing the hashes with the attributes
		and content read&produced for the enclosing tags so far.
		You may need to access this for example to find out the version
		of the format specified as an attribute of the root tag. You may
		safely add, change or delete attributes in the hashes, but all bets
		are off if you change the number or type of elements of this array!
	$parser = the parser object
		you may use $parser->{pad} or $parser->{parameters} to store any data
		you need. The first is never touched by XML::Rules, the second is set to
		the last argument of parse() or filter() methods and reset to undef
		before those methods exit.

The subroutine may decide to handle the data and return nothing or
tweak the data as necessary and return just the relevant bits. It may also
load more information from elsewhere based on the ids found in the XML
and provide it to the rules of the ancestor tags as if it was part of the XML.

The possible return values of the subroutines are:

1) nothing or undef or "" - nothing gets added to the parent tag's hash

2) a single string - if the parent's _content is a string then the one produced by this rule is appended to the parent's _content.
If the parent's _content is an array, then the string is push()ed to the array.

3) a single reference - if the parent's _content is a string then it's changed to an array containing the original string and this reference.
If the parent's _content is an array, then the string is push()ed to the array.

4) an even numbered list - it's a list of key & value pairs to be added to the parent's hash.

The handling of the attributes may be changed by adding '@', '%', '+', '*' or '.' before the attribute name.

Without any "sigil" the key & value is added to the hash overwriting any previous values.

The values for the keys starting with '@' are push()ed to the arrays referenced by the key name
without the @. If there already is an attribute of the same name then the value will be preserved and will become
the first element in the array.

The values for the keys starting with '%' have to be either hash or array references. The key&value pairs
in the referenced hash or array will be added to the hash referenced by the key. This is nice for rows of tags like this:

  <field name="foo" value="12"/>
  <field name="bar" value="24"/>

if you specify the rule as

  field => sub { '%fields' => [$_[1]->{name} => $_[1]->{value}]}

then the parent tag's has will contain

  fields => {
    foo => 12,
	bar => 24,
  }

The values for the keys starting with '+' are added to the current value, the ones starting with '.' are
appended to the current value and the ones starting with '*' multiply the current value.

5) an odd numbered list - the last element is appended or push()ed to the parent's _content, the rest is handled as in the previous case.

=head3 Builtin rules

	'content' = only the content of the tag is preserved and added to
		the parent tag's hash as an attribute named after the tag. Equivalent to:
		sub { $_[0] => $_[1]->{_content}}
	'content trim' = only the content of the tag is preserved, trimmed and added to
		the parent tag's hash as an attribute named after the tag
		sub { s/^\s+//,s/\s+$// for ($_[1]->{_content}); $_[0] => $_[1]->{_content}}
	'content array' = only the content of the tag is preserved and pushed
		to the array pointed to by the attribute
		sub { '@' . $_[0] => $_[1]->{_content}}
	'as is' = the tag's hash is added to the parent tag's hash
		as an attribute named after the tag
		sub { $_[0] => $_[1]}
	'as is trim' = the tag's hash is added to the parent tag's hash
		as an attribute named after the tag, the content is trimmed
		sub { $_[0] => $_[1]}
	'as array' = the tag's hash is pushed to the attribute named after the tag
		in the parent tag's hash
		sub { '@'.$_[0] => $_[1]}
	'as array trim' = the tag's hash is pushed to the attribute named after the tag
		in the parent tag's hash, the content is trimmed
		sub { '@'.$_[0] => $_[1]}
	'no content' = the _content is removed from the tag's hash and the hash
		is added to the parent's hash into the attribute named after the tag
		sub { delete $_[1]->{_content}; $_[0] => $_[1]}
	'no content array' = similar to 'no content' except the hash is pushed
		into the array referenced by the attribute
	'as array no content' = same as 'no content array'
	'pass' = the tag's hash is dissolved into the parent's hash,
		that is all tag's attributes become the parent's attributes.
		The _content is appended to the parent's _content.
		sub { %{$_[1]}}
	'pass no content' = the _content is removed and the hash is dissolved
		into the parent's hash.
		sub { delete $_[1]->{_content}; %{$_[1]}}
	'pass without content' = same as 'pass no content'
	'raw' = the [tagname => attrs] is pushed to the parent tag's _content.
		You would use this style if you wanted to be able to print
		the parent tag as XML preserving the whitespace or other textual content
		sub { [$_[0] => $_[1]]}
	'raw extended' = the [tagname => attrs] is pushed to the parent tag's _content
		and the attrs are added to the parent's attribute hash with ":$tagname" as the key
		sub { (':'.$_[0] => $_[1], [$_[0] => $_[1]])};
	'raw extended array' = the [tagname => attrs] is pushed to the parent tag's _content
		and the attrs are pushed to the parent's attribute hash with ":$tagname" as the key
		sub { ('@:'.$_[0] => $_[1], [$_[0] => $_[1]])};
	'by <attrname>' = uses the value of the specified attribute as the key when adding the
		attribute hash into the parent tag's hash. You can specify more names, in that case
		the first found is used.
		sub {delete($_[1]->{name}) => $_[1]}
	'content by <attrname>' = uses the value of the specified attribute as the key when adding the
		tags content into the parent tag's hash. You can specify more names, in that case
		the first found is used.
		sub {$_[1]->{name} => $_[1]->{_content}}
	'no content by <attrname>' = uses the value of the specified attribute as the key when adding the
		attribute hash into the parent tag's hash. The content is dropped. You can specify more names,
		in that case the first found is used.
		sub {delete($_[1]->{_content}); delete($_[1]->{name}) => $_[1]}
	'==...' = replace the tag by the specified string. That is the string will be added to
		the parent tag's _content
		sub { return '...' }
	'=...' = replace the tag contents by the specified string and forget the attributes.
		sub { return $_[0] => '...' }
	'' = forget the tag's contents (after processing the rules for subtags)
		sub { return };

I include the unnamed subroutines that would be equivalent to the builtin rule in case you need to add
some tests and then behave as if one of the builtins was used.

=head3 Builtin rule modifiers

You can add these modifiers to most rules, just add them to the string literal, at the end, separated from the base rule by a space.

	no xmlns	= strip the namespace alias from the $_[0] (tag name)
	remove(list,of,attributes) = remove all specified attributes (or keys produced by child tag rules) from the tag data
	only(list,of,attributes) = filter the hash of attributes and keys+values produced by child tag rules in the tag data
		to only include those specified here. In case you need to include the tag content do not forget to include
		_content in the list!

Not all modifiers make sense for all rules. For example if the  rule is 'content', it's pointless to filter the attributes, because the only one
used will be the content anyway.

The behaviour of the combination of the 'raw...' rules and the rule modifiers is UNDEFINED!

=head3 Different rules for different paths to tags

Since 0.19 it's possible to specify several actions for a tag if you need to do something different based on the path to the tag like this:

	tagname => [
		'tag/path' => action,
		'/root/tag/path' => action,
		'/root/*/path' => action,
		qr{^root/ns:[^/]+/par$} => action,
		default_action
	],

The path is matched against the list of parent tags joined by slashes.

If you need to use more complex conditions to select the actions you have to use a single subroutine rule and implement
the conditions within that subroutine. You have access both to the list of enclosing tags and their attribute hashes (including
the data obtained from the rules of the already closed subtags of the enclosing tags.


=head2 The Start Rules

Apart from the normal rules that get invoked once the tag is fully parsed, including the contents and child tags, you may want to
attach some code to the start tag to (optionaly) skip whole branches of XML or set up attributes and variables. You may set up
the start rules either in a separate parameter to the constructor or in the rules=> by prepending the tag name(s) by ^.

These rules are in form

	tagspecification => undef / '' / 'skip'	--> skip the element, including child tags
	tagspecification => 1 / 'handle'	--> handle the element, may be needed
		if you specify the _default rule.
	tagspecification => \&subroutine

The subroutines receive the same parameters as for the "end tag" rules except of course the _content, but their return value is treated differently.
If the subroutine returns a false value then the whole branch enclosed by the current tag is skipped, no data are stored and no rules are
executed. You may modify the hash referenced by $attr.

You may even tie() the hash referenced by $attr, for example in case you want to store the parsed data in a DBM::Deep.
In such case all the data returned by the immediate subtags of this tag will be stored in the DBM::Deep.
Make sure you do not overwrite the data by data from another occurance of the same tag if you return $_[1]/$attr from the rule!

	YourHugeTag => sub {
		my %temp = %{$_[1]};
		tie %{$_[1]}, 'DBM::Deep', $filename;
		%{$_[1]} = %temp;
		1;
	}

Both types of rules are free to store any data they want in $parser->{pad}. This property is NOT emptied
after the parsing!

=head2 Whitespace handling

There are two options that affect the whitespace handling: stripspaces and normalisespaces. The normalisespaces is a simple flag that controls
whether multiple spaces/tabs/newlines are collapsed into a single space or not. The stripspaces is more complex, it's a bit-mask,
an ORed combination of the following options:

	0 - don't remove whitespace around tags
	    (around tags means before the opening tag and after the closing tag, not in the tag's content!)
	1 - remove whitespace before tags whose rules did not return any text content
	    (the rule specified for the tag caused the data of the tag to be ignored,
		processed them already or added them as attributes to parent's \%attr)
	2 - remove whitespace around tags whose rules did not return any text content
	3 - remove whitespace around all tags

	0 - remove only whitespace-only content
	    (that is remove the whitespace around <foo/> in this case "<bar>   <foo/>   </bar>"
		but not this one "<bar>blah   <foo/>  blah</bar>")
	4 - remove trailing/leading whitespace
	    (remove the whitespace in both cases above)

	0 - don't trim content
	8 - do trim content
		(That is for "<foo>  blah   </foo>" only pass to the rule {_content => 'blah'})


That is if you have a data oriented XML in which each tag contains either text content or subtags, but not both,
you want to use stripspaces => 3 or stripspaces => 3|4. This will not only make sure you don't need to bother
with the whitespace-only _content of the tags with subtags, but will also make sure you do not keep on wasting
memory while parsing a huge XML and processing the "twigs". Without that option the parent tag of
the repeated tag would keep on accumulating unneeded whitespace in its _content.

=cut

sub new {
	my $class = shift;
	my %params = @_;
	croak "Please specify the rules=> for the parser!" unless $params{rules} and ref($params{rules});

	my $self = {rules => {}, start_rules => {}};
	bless $self, $class;

	my @rules = (ref($params{rules}) eq 'HASH' ? %{$params{rules}} : @{$params{rules}}); # dereference and copy
	delete $params{rules};

	my @start_rules;
	if ($params{start_rules} and ref($params{start_rules})) {
		@start_rules = ref($params{start_rules}) eq 'HASH' ? %{$params{start_rules}} : @{$params{start_rules}}; # dereference and copy
	};
	delete $params{start_rules};

	for (my $i=0; $i <= $#rules; $i+=2) {
		next unless $rules[$i] =~ s/^\^//;
		push @start_rules, splice( @rules, $i, 2);
		$i-=2;
	}

	$self->_split_rules( \@rules, 'rules', 'as is');
	$self->_split_rules( \@start_rules, 'start_rules', 'handle');

	$self->{for_parser} = {};
	{ # extract the params for the XML::Parser::Expat constructor
		my @for_parser = grep exists($params{$_}), qw(ProtocolEncoding Namespaces NoExpand Stream_Delimiter ErrorContext ParseParamEnt Base);
		if (@for_parser) {
			@{$self->{for_parser}}{@for_parser} = @params{@for_parser};
			delete @params{@for_parser};
		}
	}

	$self->{namespaces} = delete($params{namespaces});
	if (defined($self->{namespaces})) {
		croak 'XML::Rules->new( ... , namespaces => ...HERE...) must be a hash reference!'
			unless ref($self->{namespaces}) eq 'HASH';
		$self->{xmlns_map} = {};
		if (defined $self->{namespaces}{'*'}) {
			if (! grep $_ eq $self->{namespaces}{'*'}, qw(warn die keep strip), '') {
#				local $Carp::CarpLevel = 2;
				croak qq{Unknown namespaces->{'*'} option '$self->{namespaces}{'*'}'!};
			}
		} else {
			$self->{namespaces}{'*'} = 'warn';
		}
	}

	$self->{custom_escape} = delete($params{custom_escape}) if exists $params{custom_escape};
	$self->{style} = delete($params{style}) || 'parser';

	my $handlers = delete $params{handlers}; # need to remove it so that it doesn't end up in opt

	$self->{opt}{lc $_} = $params{$_} for keys %params;

	delete $self->{opt}{encode} if $self->{opt}{encode} =~ /^utf-?8$/i;
	delete $self->{opt}{output_encoding} if $self->{opt}{output_encoding} =~ /^utf-?8$/i;

	for (qw(normalisespace normalizespace normalizespaces)) {
		last if defined($self->{opt}{normalisespaces});
		$self->{opt}{normalisespaces} = $self->{opt}{$_};
		delete $self->{opt}{$_};
	}
	$self->{opt}{normalisespaces} = 0 unless(defined($self->{opt}{normalisespaces}));
	$self->{opt}{stripspaces} = 0 unless(defined($self->{opt}{stripspaces}));

	require 'Encode.pm' if ($self->{opt}{encode} or $self->{opt}{output_encoding});

	if ($handlers) {
		croak qq{The 'handlers' option must be a hashref!} unless ref($handlers) eq 'HASH';
		my %handlers = %{$handlers}; # shallow copy

		for (qw(Start End Char XMLDecl), ($self->{style} eq 'filter' ? qw(CdataStart CdataEnd) : ())) {
			no strict 'refs';
			if ($handlers{$_}) {
				my $custom = $handlers{$_};
				my $mine = "_$_"->($self);
#				$handlers{$_} = sub {$custom->(@_); $mine->(@_)}
				$handlers{$_} = sub {&$custom; &$mine}
			} else {
				$handlers{$_} = "_$_"->($self);
			}
		}

		for (qw(Start End Char XMLDecl)) {
			$self->{basic_handlers}{$_} = delete $self->{other_handlers}{$_} if exists $self->{other_handlers}{$_};
		}
		$self->{normal_handlers} = [ %handlers ];
	} else {
		$self->{normal_handlers} = [
			Start => _Start($self),
			End => _End($self),
			Char => _Char($self),
			XMLDecl => _XMLDecl($self),
			(
				$self->{style} eq 'filter' ? (CdataStart => _CdataStart($self), CdataEnd  => _CdataEnd ($self)) : ()
			)
		];
	}
	$self->{ignore_handlers} = [
		Start => _StartIgnore($self),
		Char => undef,
		End => _EndIgnore($self),
	];

	return $self;
}

sub _split_rules {
	my ($self, $rules, $type, $default) = @_;

	$self->{$type}{_default} = $default unless exists($self->{$type}{_default});

	while (@$rules) {
		my ($tag, $code) = (shift(@$rules), shift(@$rules));

		if (ref($code) eq 'ARRAY') {
			for( my $i = 0; $i < $#$code; $i+=2) {
				$code->[$i] = _xpath2re($code->[$i]);
			}
			push @$code, $self->{$type}{_default} if @$code % 2 == 0; # add the default type if there's even number of items (path => code, path => code)
		}

		if ($tag =~ m{^/([^/].*)/([imosx]*)$}) { # string with a '/regexp/'
			if ($2) {
				push @{$self->{$type.'_re'}}, qr/(?$2)$1/;
			} else {
				push @{$self->{$type.'_re'}}, qr/$1/;
			}
			push @{$self->{$type.'_re_code'}}, $code;
		} elsif (ref($tag) eq 'Regexp') { # a qr// created regexp
			push @{$self->{$type.'_re'}}, $tag;
			push @{$self->{$type.'_re_code'}}, $code;
		} elsif ($tag =~ /[,\|]/) { # a , or | separated list
			if ($tag =~ s/^\^//) {
				my @tags = split(/\s*[,\|]\s*/, $tag);
				$self->{$type}{'^'.$_} = $code for (@tags);
			} else {
				my @tags = split(/\s*[,\|]\s*/, $tag);
				$self->{$type}{$_} = $code for (@tags);
			}
		} else { # a single tag
			$self->{$type}{$tag} = $code;
		}
	}
}

sub _xpath2re {
	my $s = shift;
	return $s if ref($s);
	for ($s) {
		s/([\.\[\]+{}\-])/\\$1/g;
		s{\*}{.+}g;
		s{^//}{}s;
		s{^/}{^}s;
	}
	return qr{$s$};
}

sub _import_usage {
	croak
"Usage: use XML::Rules subroutine_name => {method => '...', rules => {...}, ...};
   or  use XML::Rules inferRules => 'file/path.dtd';
   or  use XML::Rules inferRules => 'file/path.xml';
   or  use XML::Rules inferRules => ['file/path1.xml','file/path2.xml'];"
}

sub import {
	my $class = shift();
	return unless @_;
	_import_usage() unless scalar(@_) % 2 == 0;
	my $caller_pack = caller;
	while (@_) {
		my $subname = shift;
		my $params = shift;

		if (lc($subname) eq 'inferrules') {
			require Data::Dumper;
			local $Data::Dumper::Terse = 1;
			local $Data::Dumper::Indent = 1;
			if (ref $params) {
				if (ref $params eq 'ARRAY') {
					print Data::Dumper::Dumper(inferRulesFromExample(@$params))
				} else {
					_import_usage()
				}
			} elsif ($params =~ /\.dtd$/i) {
				print Data::Dumper::Dumper(inferRulesFromDTD($params))
			} else {
				print Data::Dumper::Dumper(inferRulesFromExample($params))
			}
		} else {
			_import_usage()
				unless !ref($subname) and ref($params) eq 'HASH';

			my $method = delete $params->{method} || $subname;
			if (!$params->{rules} && $method =~ /^[tT]oXML$/) {
				$params->{rules} = {};
			}
			my $parser = XML::Rules->new(%$params);

			no strict 'refs';
			*{$caller_pack . '::' . $subname} = sub {unshift @_, $parser; goto &$method; };
		}
	}
}

sub skip_rest {
	die "[XML::Rules] skip rest\n";
}

sub return_nothing {
	die "[XML::Rules] return nothing\n";
}

sub return_this {
	my $self = shift();
	die bless({val => [@_]}, "XML::Rules::return_this");
}

sub _run {
	my $self = shift;
	my $string = shift;

	croak "This parser is already busy parsing a document!" if exists $self->{parser};

	$self->{parameters} = shift;

	$self->{parser} = XML::Parser::Expat->new( %{$self->{for_parser}});

	$self->{parser}->setHandlers( @{$self->{normal_handlers}} );

	$self->{data} = [];
	$self->{context} = [];
	$self->{_ltrim} = [0];

	if (! eval {
		$self->{parser}->parse($string) and 1;
	}) {
		my $err = $@;
		undef $@;
		if ($err =~ /^\[XML::Rules\] skip rest/) {
			my (undef, $handler) = $self->{parser}->setHandlers(End => undef);
			foreach my $tag (reverse @{$self->{context} = []}) {
				$handler->( $self->{parser}, $tag);
			}
		} else {

			delete $self->{parameters};
			$self->{parser}->release();

			$self->{data} = [];
			$self->{context} = [];

			if ($err =~ /^\[XML::Rules\] return nothing/) {
				return;
			} elsif (ref $err eq 'XML::Rules::return_this') {
				if (wantarray()) {
					return @{$err->{val}}
				} else {
					return ${$err->{val}}[-1]
				}
			}

			$err =~ s/at \S+Rules\.pm line \d+$//
				and croak $err or die $err;
		}
	};

	$self->{parser}->release();
	delete $self->{parser};

	delete $self->{parameters};
	my $data; # return the accumulated data, without keeping a copy inside the object
	($data, $self->{data}) = ($self->{data}[0], undef);
	if (!defined(wantarray()) or ! keys(%$data)) {
		return;

	} elsif (keys(%$data) == 1 and exists(${$data}{_content})) {
		if (ref(${$data}{_content}) eq 'ARRAY' and @{${$data}{_content}} == 1) {
			return ${${$data}{_content}}[0]
		} else {
			return ${$data}{_content}
		}

	} else {
		return $data;
	}
}


sub parsestring;
*parsestring = \&parse;
sub parse_string;
*parse_string = \&parse;
sub parse {
	if (!ref $_[0] and $_[0] eq 'XML::Rules') {
		my $parser = &new; # get's the current @_
		return sub {unshift @_, $parser; goto &parse;}
	}
	my $self = shift;
	croak("This XML::Rules object may only be used as a filter!") if ($self->{style} eq 'filter');
	$self->_run(@_);
}

sub parse_file;
*parse_file = \&parsefile;
sub parsefile {
	if (!ref $_[0] and $_[0] eq 'XML::Rules') {
		my $parser = &new; # get's the current @_
		return sub {unshift @_, $parser; goto &parsefile;}
	}
	my $self = shift;
	croak("This XML::Rules object may only be used as a filter!") if ($self->{style} eq 'filter');
	my $filename = shift;
	open my $IN, '<', $filename or croak "Cannot open '$filename' for reading: $^E";
	return $self->_run($IN, @_);
}


sub filterstring;
*filterstring = \&filter;
sub filter_string;
*filter_string = \&filter;
sub filter {
	if (!ref $_[0] and $_[0] eq 'XML::Rules') {
		my $parser = &new; # get's the current @_
		return sub {unshift @_, $parser; goto &filter;}
	}
	my $self = shift;
	croak("This XML::Rules object may only be used as a parser!") unless ($self->{style} eq 'filter');

	my $XML = shift;
	$self->{FH} = shift || select(); # either passed or the selected filehandle
	if (!ref($self->{FH})) {
		if ($self->{FH} =~ /^main::(?:STDOUT|STDERR)$/) {
			# yeah, select sometimes returns the name of the filehandle, not the filehandle itself. eg. "main::STDOUT"
			no strict;
			$self->{FH} = \*{$self->{FH}};
		} else {
			open my $FH, '>:utf8', $self->{FH} or croak(qq{Failed to open "$self->{FH}" for writing: $^E});
			$self->{FH} = $FH;
		}
	} elsif (ref($self->{FH}) eq 'SCALAR') {
		open my $FH, '>', $self->{FH};
		$self->{FH} = $FH;
	}
	if (! $self->{opt}{skip_xml_version}) {
		if ($self->{opt}{output_encoding}) {
			print {$self->{FH}} qq{<?xml version="1.0" encoding="$self->{opt}{output_encoding}"?>\n};
		} else {
			print {$self->{FH}} qq{<?xml version="1.0"?>\n};
		}
	}

	$self->_run($XML, @_);
	print {$self->{FH}} "\n";
	delete $self->{FH};
}

sub filterfile {
	if (!ref $_[0] and $_[0] eq 'XML::Rules') {
		my $parser = &new; # get's the current @_
		return sub {unshift @_, $parser; goto &filterfile;}
	}
	my $self = shift;
	croak("This XML::Rules object may only be used as a parser!") unless ($self->{style} eq 'filter');

	my $filename = shift;
	open my $IN, '<', $filename or croak "Cannot open '$filename' for reading: $^E";

	$self->{FH} = shift || select(); # either passed or the selected filehandle
	if (!ref($self->{FH})) {
		if ($self->{FH} =~ /^main::(?:STDOUT|STDERR)$/) {
			# yeah, select sometimes returns the name of the filehandle, not the filehandle itself. eg. "main::STDOUT"
			no strict;
			$self->{FH} = \*{$self->{FH}};
		} else {
			open my $FH, '>:utf8', $self->{FH} or croak(qq{Failed to open "$self->{FH}" for writing: $^E});
			$self->{FH} = $FH;
		}
	} elsif (ref($self->{FH}) eq 'SCALAR') {
		open $self->{FH}, '>', $self->{FH};
	}
	if (! $self->{opt}{skip_xml_version}) {
		if ($self->{opt}{output_encoding}) {
			print {$self->{FH}} qq{<?xml version="1.0" encoding="$self->{opt}{output_encoding}"?>\n};
		} else {
			print {$self->{FH}} qq{<?xml version="1.0"?>\n};
		}
	}
	$self->_run($IN, @_);
	print {$self->{FH}} "\n";
	delete $self->{FH};
}

## chunk processing

sub parse_chunk {
	my $self = shift;
	croak("This XML::Rules object may only be used as a filter!") if ($self->{style} eq 'filter');
	$self->_parse_or_filter_chunk(@_);
}

sub _parse_or_filter_chunk {
	my $self = shift;
	my $string = shift;

	if (exists $self->{parser}) {
		if (ref($self->{parser}) ne 'XML::Parser::ExpatNB') {
			croak "This parser is already busy parsing a full document!";
		} else {
			if (exists $self->{chunk_processing_result}) {
				if (defined $self->{chunk_processing_result}) {
					if (wantarray()) {
						return @{$self->{chunk_processing_result}}
					} else {
						return ${$self->{chunk_processing_result}}[-1]
					}
				} else {
					return;
				}
			}

			if (! eval {
				$self->{parser}->parse_more($string) and 1;
			}) {
				my $err = $@;
				undef $@;
				if ($err =~ /^\[XML::Rules\] skip rest/) {
					my (undef, $handler) = $self->{parser}->setHandlers(End => undef);
					foreach my $tag (reverse @{$self->{context} = []}) {
						$handler->( $self->{parser}, $tag);
					}
				} else {

					delete $self->{parameters};
					$self->{parser}->release();

					$self->{data} = [];
					$self->{context} = [];

					if ($err =~ /^\[XML::Rules\] return nothing/) {
						$self->{chunk_processing_result} = undef;
						return;
					} elsif (ref $err eq 'XML::Rules::return_this') {
						$self->{chunk_processing_result} = $err->{val};
						if (wantarray()) {
							return @{$err->{val}}
						} else {
							return ${$err->{val}}[-1]
						}
					}

					$err =~ s/at \S+Rules\.pm line \d+$//
						and croak $err or die $err;
				}
			};
			return 1;
		}
	}

	$self->{parameters} = shift;

	$self->{parser} = XML::Parser::ExpatNB->new( %{$self->{for_parser}});

	$self->{parser}->setHandlers( @{$self->{normal_handlers}} );

	$self->{data} = [];
	$self->{context} = [];
	$self->{_ltrim} = [0];

	return $self->_parse_or_filter_chunk($string);
}

sub filter_chunk {
	my $self = shift;
	croak("This XML::Rules object may only be used as a parser!") unless ($self->{style} eq 'filter');

	my $XML = shift;

	if (!exists $self->{FH}) {
		$self->{FH} = shift || select(); # either passed or the selected filehandle
		if (!ref($self->{FH})) {
			if ($self->{FH} =~ /^main::(?:STDOUT|STDERR)$/) {
				# yeah, select sometimes returns the name of the filehandle, not the filehandle itself. eg. "main::STDOUT"
				no strict;
				$self->{FH} = \*{$self->{FH}};
			} else {
				open my $FH, '>:utf8', $self->{FH} or croak(qq{Failed to open "$self->{FH}" for writing: $^E});
				$self->{FH} = $FH;
			}
		} elsif (ref($self->{FH}) eq 'SCALAR') {
			open my $FH, '>', $self->{FH};
			$self->{FH} = $FH;
		}
		if (! $self->{opt}{skip_xml_version}) {
			if ($self->{opt}{output_encoding}) {
				print {$self->{FH}} qq{<?xml version="1.0" encoding="$self->{opt}{output_encoding}"?>\n};
			} else {
				print {$self->{FH}} qq{<?xml version="1.0"?>\n};
			}
		}
	}

	$self->_parse_or_filter_chunk($XML, @_);
}

sub last_chunk {
	my $self = shift;
	my $string = shift;
	if (exists $self->{parser}) {
		if (ref($self->{parser}) ne 'XML::Parser::ExpatNB') {
			if (exists $self->{FH}) { # in case it was a filter ...
				print {$self->{FH}} "\n";
				delete $self->{FH};
			}
			croak "This parser is already busy parsing a full document!";
		} else {
			if (exists $self->{chunk_processing_result}) {
				if (exists $self->{FH}) { # in case it was a filter ...
					print {$self->{FH}} "\n";
					delete $self->{FH};
				}
				if (defined $self->{chunk_processing_result}) {
					if (wantarray()) {
						return @{$self->{chunk_processing_result}}
					} else {
						return ${$self->{chunk_processing_result}}[-1]
					}
				} else {
					return;
				}
			}
		}
	} elsif (defined $string) {
		return ($self->{style} eq 'filter') ? $self->filter($string,@_) : $self->parse($string); # no chunks in processing
	} else {
		return;
	}

	if (defined $string) {
		$self->_parse_or_filter_chunk($string);
	}

	$self->{parser}->parse_done();
	delete $self->{parser};

	if (exists $self->{FH}) {
		print {$self->{FH}} "\n";
		delete $self->{FH};
	}

	delete $self->{parameters};
	my $data; # return the accumulated data, without keeping a copy inside the object
	($data, $self->{data}) = ($self->{data}[0], undef);
	if (!defined(wantarray()) or ! keys(%$data)) {
		return;

	} elsif (keys(%$data) == 1 and exists(${$data}{_content})) {
		if (ref(${$data}{_content}) eq 'ARRAY' and @{${$data}{_content}} == 1) {
			return ${${$data}{_content}}[0]
		} else {
			return ${$data}{_content}
		}

	} else {
		return $data;
	}
}

##

sub _XMLDecl {
	weaken( my $self = shift);
	return sub {
		my ( $Parser, $Version, $Encoding, $Standalone) = @_;
		$self->{opt}{original_encoding} = $Encoding
	}
}

=begin comment

start tag
	& 3 = 3 -> rtrim parent's _content
	& 8 = 8 -> $ltrim = 1

string content
	$ltrim -> ltrim the string, if not completely whitespace set $ltrim  0

end tag
	& 8 = 8 -> rtrim own content
	& 3 = 3 -> $ltrim = 1
	empty_returned_content and & 3 in (1,2) -> rtrim parent content
	empty_returned_content and & 3  = 2 -> $ltrim

=end comment

=cut

sub _rtrim {
	my ($self, $attr, $more) = @_;

	if ($more) {
		if (ref $attr->{_content}) {
			if (!ref($attr->{_content}[-1])) {
				$attr->{_content}[-1] =~ s/\s+$//s;
				pop @{$attr->{_content}} if $attr->{_content}[-1] eq '';
				delete $attr->{_content} unless @{$attr->{_content}};
			}
		} else {
			$attr->{_content} =~ s/\s+$//s;
			delete $attr->{_content} if $attr->{_content} eq '';
		}
	} else {
		if (ref $attr->{_content}) {
			if (!ref($attr->{_content}[-1]) and $attr->{_content}[-1] =~ /^\s*$/s) {
				pop @{$attr->{_content}} ;
				delete $attr->{_content} unless @{$attr->{_content}};
			}
		} else {
			delete $attr->{_content} if $attr->{_content}  =~ /^\s*$/s;
		}
	}
}

sub _findUnusedNs {
	my ($self, $old_ns) = @_;
	my $new_ns = $old_ns;
	my %used;
	@used{values %{$self->{namespaces}}, values %{$self->{xmlns_map}}}= ();
	no warnings 'numeric';
	while (exists $used{$new_ns}) {
		$new_ns =~ s/(\d*)$/$1+1/e;
	}
	return $new_ns;
}

sub _Start {
	weaken( my $self = shift);
	my $encode = $self->{opt}{encode};
	my $output_encoding = $self->{opt}{output_encoding};
	return sub {
		my ( $Parser, $Element , %Attr) = @_;

		if (($self->{opt}{stripspaces} & 3) == 3) {
			#rtrim parent
#print "rtrim parent content in _Start\n";
			if ($self->{data}[-1] and $self->{data}[-1]{_content}) {
				$self->_rtrim( $self->{data}[-1], ($self->{opt}{stripspaces} & 4));
			}
		}
		if ($self->{opt}{stripspaces} & 8) {
#print "ltrim own content in _Start\n";
			push @{$self->{_ltrim}}, 2;
		} else {
			push @{$self->{_ltrim}}, 0;
		}

		if ($self->{namespaces}) {
			my %restore;
			foreach my $attr (keys %Attr) { # find the namespace aliases
				next unless $attr =~ /^xmlns:(.*)$/;
				my $orig_ns = $1;
				$restore{$orig_ns} = $self->{xmlns_map}{$orig_ns};
				if (! exists($self->{namespaces}{ $Attr{$attr} })) {
					if ($self->{namespaces}{'*'} eq 'die') {
						local $Carp::CarpLevel = 2;
						croak qq{Unexpected namespace "$Attr{$attr}" found in the XML!};
					} elsif ($self->{namespaces}{'*'} eq '') {
						delete $Attr{$attr};
						$self->{xmlns_map}{$orig_ns} = '';
					} elsif ($self->{namespaces}{'*'} eq 'strip') {
						delete $Attr{$attr};
						$self->{xmlns_map}{$orig_ns} = STRIP;
					} else {
						warn qq{Unexpected namespace "$Attr{$attr}" found in the XML!\n} if ($self->{namespaces}{'*'} eq 'warn');
						my $new_ns = $self->_findUnusedNs( $orig_ns);
						if ($orig_ns ne $new_ns) {
							$Attr{'xmlns:' . $new_ns} = delete $Attr{$attr};
						}
						$self->{xmlns_map}{$orig_ns} = $new_ns;
					}
				} else {
					$self->{xmlns_map}{$orig_ns} = $self->{namespaces}{ delete($Attr{$attr}) };
				}
			}
			if (exists $Attr{xmlns}) { # find the default namespace
#print "Found a xmlns attribute in $Element!\n";
				$restore{''} = $self->{xmlns_map}{''};
				if (!exists($self->{namespaces}{ $Attr{xmlns} })) { # unknown namespace
					if ($self->{namespaces}{'*'} eq 'die') {
						local $Carp::CarpLevel = 2;
						croak qq{Unexpected namespace "$Attr{xmlns}" found in the XML!};
					} elsif ($self->{namespaces}{'*'} eq '') {
						delete $Attr{xmlns};
					} elsif ($self->{namespaces}{'*'} eq 'strip') {
						delete $Attr{xmlns};
						$self->{xmlns_map}{''} = STRIP;
					} else { # warn or keep
						warn qq{Unexpected namespace "$Attr{xmlns}" found in the XML!\n} if ($self->{namespaces}{'*'} eq 'warn');
						my $new_ns = $self->_findUnusedNs( 'ns1');
						$Attr{'xmlns:'.$new_ns} = delete $Attr{xmlns};
						$self->{xmlns_map}{''} = $new_ns;
					}
				} else {
					$self->{xmlns_map}{''} = $self->{namespaces}{ delete($Attr{xmlns}) };
				}
			}
			if (%restore) {
				push @{$self->{xmlns_restore}}, \%restore;
			} else {
				push @{$self->{xmlns_restore}}, undef;
			}

			if (%{$self->{xmlns_map}}) {
#print "About to map aliases for $Element\n";
				# add or map the alias for the tag
				if ($Element =~ /^([^:]+):(.*)$/) {
#print "Mapping an alias $1 for tag $Element\n";
					if (exists($self->{xmlns_map}{$1})) {
						if ($self->{xmlns_map}{$1} eq '') {
							$Element = $2 ;
						} else {
							$Element = $self->{xmlns_map}{$1} . ':' . $2 ;
						}
					}
#print " -> $Element\n";
				} elsif (defined($self->{xmlns_map}{''}) and $self->{xmlns_map}{''} ne '') { # no namespace alias in the tag and there's a default
#print "Adding default alias $self->{xmlns_map}{''}:\n";
					$Element = $self->{xmlns_map}{''} . ':' . $Element;
#print " -> $Element\n";
				}
				if (substr( $Element, 0, length(STRIP)+1) eq STRIP.':') {%Attr = ()}

				# map the aliases for the attributes
				foreach my $attr (keys %Attr) {
					next unless $attr =~ /^([^:]+):(.*)$/; # there's an alias
					next unless exists($self->{xmlns_map}{$1}); # and there's a mapping
					if ($self->{xmlns_map}{$1} eq '') {
						$Attr{$2} = delete($Attr{$attr}); # rename the attribute
					} elsif ($self->{xmlns_map}{$1} eq STRIP) {
						delete($Attr{$attr}); # remove the attribute
					} else {
						$Attr{$self->{xmlns_map}{$1} . ':' . $2} = delete($Attr{$attr}); # rename the attribute
					}
				}
			}
		} # /of namespace handling


		my ( $start_rule, $end_rule) = map {
			if ($self->{$_}{$Element} and ref($self->{$_}{$Element}) ne 'ARRAY') {
				$self->{$_}{$Element}
			} else {
				$self->_find_rule( $_, $Element, $self->{context})
			}
		} ( 'start_rules', 'rules');

		if ($start_rule ne 'handle'
		and (
			!$start_rule
			or $start_rule eq 'skip'
			or !$start_rule->($Element,\%Attr, $self->{context}, $self->{data}, $self)
			)
		) {
			# ignore the tag and the ones below
			$Parser->setHandlers(@{$self->{ignore_handlers}});
			$self->{ignore_level}=1;

		} else {
			# process the tag and the ones below
			if ($encode) {
				foreach my $value (values %Attr) {
					$value = Encode::encode( $encode, $value);
				}
			}

			push @{$self->{context}}, $Element;
			push @{$self->{data}}, \%Attr;
			$self->{lastempty} = 0;

			if ($self->{style} eq 'filter') {
				$self->{in_interesting}++ if ref($end_rule) or $end_rule =~ /^=/s; # is this tag interesting?

				if (! $self->{in_interesting}) { # it neither this tag not an acestor is interesting, just copy the tag
#print "Start:R ".$Parser->recognized_string()."\n";
#print "Start:O ".$Parser->original_string()."\n";
#print "Start:R ".$Parser->recognized_string()."\n";
#print "Start:O ".$Parser->original_string()."\n";
					if (! $output_encoding) {
						print {$self->{FH}} $Parser->recognized_string();
					} elsif ($output_encoding eq $self->{opt}{original_encoding}) {
						print {$self->{FH}} $Parser->original_string();
					} else {
						print {$self->{FH}} $self->toXML($Element, \%Attr, "don't close");
					}
				}
			}

		}
	}
}

sub _find_rule {
	my ($self, $type, $Element, $path) = @_;

	if (substr( $Element, 0, length(STRIP)+1) eq STRIP.':') {
		return ($type eq 'rules' ? STRIP_RULE : 'handle');
	}

	if (exists($self->{$type.'_re'})) {
		for(my $i = 0; $i < @{$self->{$type.'_re'}}; $i++) {
			if ($Element =~ $self->{$type.'_re'}[$i]) {
				$self->{$type}{$Element} = $self->{$type.'_re_code'}[$i];
				last;
			}
		}
	}
	if (! exists $self->{$type}{$Element}) {
		$self->{$type}{$Element} = $self->{$type}{_default};
	}

	if (ref $self->{$type}{$Element} eq 'ARRAY') {
		$path = join( '/', @$path);
		for(my $i=0; $i < $#{$self->{$type}{$Element}}; $i+=2) {
			if ($path =~ $self->{$type}{$Element}[$i]) {
				return $self->{$type}{$Element}[$i+1];
			}
		}
		return $self->{$type}{$Element}[-1];
	} else {
		return $self->{$type}{$Element};
	}
}

sub _CdataStart  {
	my $self = shift;
	my $encode = $self->{opt}{encode};
	return $self->{style} eq 'filter'
	? sub {
		my ( $Parser, $String) = @_;

		return if (substr( $self->{context}[-1], 0, length(STRIP)+1) eq STRIP.':');

		if (! $self->{in_interesting}) {
			print {$self->{FH}} '<![CDATA[';
		}
	}
	: undef;
}

sub _CdataEnd {
	my $self = shift;
	my $encode = $self->{opt}{encode};
	return $self->{style} eq 'filter'
	? sub {
		my ( $Parser, $String) = @_;

		return if (substr( $self->{context}[-1], 0, length(STRIP)+1) eq STRIP.':');

		if (! $self->{in_interesting}) {
			print {$self->{FH}} ']]>';
		}
	}
	: undef;
}

sub _Char {
	weaken( my $self = shift);
	my $encode = $self->{opt}{encode};
	return sub {
		my ( $Parser, $String) = @_;

		return if (substr( $self->{context}[-1], 0, length(STRIP)+1) eq STRIP.':');

		if ($self->{style} eq 'filter' and ! $self->{in_interesting}) {
			if (! $self->{opt}{output_encoding}) {
				print {$self->{FH}} $Parser->recognized_string();
			} elsif ($self->{opt}{output_encoding} eq $self->{opt}{original_encoding}) {
				print {$self->{FH}} $Parser->original_string();
			} else {
				print {$self->{FH}} encode($self->{opt}{output_encoding}, $Parser->recognized_string());
			}
			return;
		}

		if ($encode) {
			$String = Encode::encode( $encode, $String);
		}

		if ($self->{_ltrim}[-1]) {
#print "ltrim in $self->{context}[-1] ($String)\n";
			if ($self->{_ltrim}[-1] == 2) {
				$String =~ s/^\s+//s;
				return if $String eq '';
			} else {
				return if $String =~ /^\s*$/s;
			}
			$self->{_ltrim}[-1] = 0;
#print "  ($String)\n";
		}
		$String =~ s/\s+/ /gs if ($self->{opt}{normalisespaces});

		if (!exists $self->{data}[-1]{_content}) {
			$self->{data}[-1]{_content} = $String;
		} elsif (!ref $self->{data}[-1]{_content}) {
			if ($self->{opt}{normalisespaces} and $self->{data}[-1]{_content} =~ /\s$/ and $String =~ /^\s/) {
				$String =~ s/^\s+//s;
			}
			$self->{data}[-1]{_content} .= $String;
		} else {
			if (ref $self->{data}[-1]{_content}[-1]) {
				push @{$self->{data}[-1]{_content}}, $String;
			} else {
				if ($self->{opt}{normalisespaces} and $self->{data}[-1]{_content}[-1] =~ /\s$/ and $String =~ /^\s/) {
					$String =~ s/^\s+//s;
				}
				$self->{data}[-1]{_content}[-1] .= $String;
			}
		}
	}
}

sub _End {
	weaken( my $self = shift);
	return sub {
		my ( $Parser, $Element) = @_;
		$Element = pop @{$self->{context}}; # the element name may have been mangled by XMLNS aliasing

		if ($self->{opt}{stripspaces} & 8) {
#print "rtrim own content\n";
			if ($self->{data}[-1] and $self->{data}[-1]{_content}) {
				$self->_rtrim( $self->{data}[-1], 1);
			}
		}
		pop(@{$self->{_ltrim}});

		if ($self->{namespaces}) {
			if (my $restore = pop @{$self->{xmlns_restore}}) { # restore the old default namespace and/or alias mapping
				while (my ($their, $our)  = each %$restore) {
					if (defined($our)) {
						$self->{xmlns_map}{$their} = $our;
					} else {
						delete $self->{xmlns_map}{$their};
					}
				}
			}
		}

		my ($rule) = map {
			if ($self->{$_}{$Element} and ref($self->{$_}{$Element}) ne 'ARRAY') {
				$self->{$_}{$Element}
			} else {
				$self->_find_rule( $_, $Element, $self->{context})
			}
		} ('rules');

		my $data = pop @{$self->{data}};

		my @results;
		if (ref $rule or $rule =~ /^=/s) {
			if ($rule =~ /^==(.*)$/s) { # change the whole tag to a string
				@results = ($1);
			} elsif ($rule =~ /^=(.*)$/s) { # change the contents to a string
				@results = ($Element => $1);
			} else {
				@results = $rule->($Element, $data, $self->{context}, $self->{data}, $self);
			}

			if ($self->{style} eq 'filter') {

				$self->{in_interesting}--;
				if (!$self->{in_interesting}) {
					if (@{$self->{data}}) {
						print {$self->{FH}} $self->escape_value($self->{data}[-1]{_content});
						delete $self->{data}[-1]{_content};
					}
					my $base;
					if ($self->{opt}{ident} ne '') {
						$base = $self->{opt}{ident} x scalar(@{$self->{context}});
					}
					@results and $results[0] =~ s/^[\@%\+\*\.]//;
					while (@results) {
#use Data::Dumper;
#print "\@results=".Dumper(\@results)."\n";
						if (ref($results[0])) {
							croak(ref($results[0]) . " not supported as the return value of a filter") unless ref($results[0]) eq 'ARRAY';
							if (@{$results[0]} ==2 and ref($results[0][1]) eq 'HASH') {
								print {$self->{FH}} $self->toXML(@{$results[0]}[0,1], 0, $self->{opt}{ident}, $base);
							} else {
								foreach my $item (@{$results[0]}) {
									if (ref($item)) {
										croak(ref($item) . " not supported in the return value of a filter") unless ref($item) eq 'ARRAY';
										croak("Empty array not supported in the return value of a filter") unless @$item;
										if (@$item <= 2) {
											print {$self->{FH}} $self->toXML(@{$item}[0,1], 0, $self->{opt}{ident}, $base);
										} else { # we suppose the 3rd and following elements are parameters to ->toXML()
											print {$self->{FH}} $self->toXML(@$item);
										}
									} else {
										print {$self->{FH}} $self->escape_value($item);
									}
								}
							}
							shift(@results);
						} else {
							if (@results == 1) {
								print {$self->{FH}} $self->escape_value($results[0]);
								@results = ();last;
							} else {
								print {$self->{FH}} $self->toXML(shift(@results), shift(@results), 0, $self->{opt}{ident}, $base);
							}
						}
					}
				}
			}
		} elsif ($self->{style} eq 'filter' and ! $self->{in_interesting}) {
#print "End: \$Element=$Element; \$Parser->recognized_string()=".$Parser->recognized_string()."; \$Parser->original_string()=".$Parser->original_string()."\n";
die "Unexpected \$data->{_content}={$data->{_content}} in filter outside interesting nodes!\n" if $data->{_content} ne '';
				if (! $self->{opt}{output_encoding}) {
					print {$self->{FH}} $Parser->recognized_string();
				} elsif ($self->{opt}{output_encoding} eq $self->{opt}{original_encoding}) {
					print {$self->{FH}} $Parser->original_string();
				} else {
					print {$self->{FH}} encode($self->{opt}{output_encoding}, $Parser->recognized_string());
				}
#			print {$self->{FH}} $self->escape_value($data->{_content})."</$Element>";

		} else { # a predefined rule

			if ($rule =~ s/(?:^| )no\s+xmlns$//) {
				$Element =~ s/^\w+://;
				$rule = 'as is' if $rule eq '';
			}
			if ($rule =~ s/^((?:(?:no\s+)?content\s+)?by\s+(\S+))\s+remove\(([^\)]+)\)$/$1/) {
				my $keep = $2;
				my @remove = split /\s*,\s*/, $3;
				foreach (@remove) {
					next if $_ eq $keep;
					delete $data->{$_};
				}
				$rule = 'as is' if $rule eq '';
			} elsif ($rule =~ s/\s*\bremove\(([^\)]+)\)//) {
				my @remove = split /\s*,\s*/, $1;
				foreach (@remove) {
					delete $data->{$_};
				}
				$rule = 'as is' if $rule eq '';
			}
			if ($rule =~ s/^((?:(?:no\s+)?content\s+)?by\s+(\S+))\s+only\(([^\)]+)\)$/$1/) {
				my %only;
				$only{$2} = undef;
				@only{split /\s*,\s*/, $3} = ();
				foreach (keys %$data) {
					delete $data->{$_} unless exists $only{$_};
				}
				$rule = 'as is' if $rule eq '';
			} elsif ($rule =~ s/\s*\bonly\(([^\)]+)\)//) {
				my %only;
				@only{split /\s*,\s*/, $1} = ();
				foreach (keys %$data) {
					delete $data->{$_} unless exists $only{$_};
				}
				$rule = 'as is' if $rule eq '';
			}

			if ($rule eq '') {
				@results = ();
			} elsif ($rule eq 'content') {
				@results = ($Element => $data->{_content});
			} elsif ($rule eq 'content trim') {
				s/^\s+//,s/\s+$// for ($data->{_content});
				@results = ($Element => $data->{_content});
			} elsif ($rule eq 'content array') {
				@results = ('@'.$Element => $data->{_content});
			} elsif ($rule eq 'as is') {
				@results = ($Element => $data);
			} elsif ($rule eq 'as is trim') {
				s/^\s+//,s/\s+$// for ($data->{_content});
				@results = ($Element => $data);
			} elsif ($rule eq 'as array') {
				@results = ('@'.$Element => $data);
			} elsif ($rule eq 'as array trim') {
				s/^\s+//,s/\s+$// for ($data->{_content});
				@results = ('@'.$Element => $data);
			} elsif ($rule eq 'no content') {
				delete ${$data}{_content}; @results = ($Element => $data);
			} elsif ($rule eq 'no content array' or $rule eq 'as array no content') {
				delete ${$data}{_content}; @results = ('@' . $Element => $data);

			} elsif ($rule eq 'pass') {
				@results = (%$data);
			} elsif ($rule eq 'pass trim') {
				s/^\s+//,s/\s+$// for ($data->{_content});
				@results = (%$data);
			} elsif ($rule eq 'pass no content' or $rule eq 'pass without content') {
				delete ${$data}{_content}; @results = (%$data);
			} elsif ($rule =~ /^pass\s+(\S+)$/) {
                my %allowed = map {$_ => 1} split( /\s*,\s*/, $1);
                @results = map { $_ => $data->{$_} } grep {$allowed{$_}} keys %allowed;

			} elsif ($rule eq 'raw') {
				@results = [$Element => $data];

			} elsif ($rule eq 'raw extended') {
				@results = (':'.$Element => $data, [$Element => $data]);

			} elsif ($rule eq 'raw extended array') {
				@results = ('@:'.$Element => $data, [$Element => $data]);

			} elsif ($rule =~ /^((?:no )?content )?by\s+(\S+)$/) {
				my ($cnt,$attr) = ($1,$2);
				if ($cnt eq 'no content ') {
					delete $data->{_content};
				}
				if ($attr =~ /,/) {
					my @attr = split /,/, $attr;
					foreach (@attr) {
						next unless exists ($data->{$_});
						if ($cnt eq 'content ') {
							@results = ($data->{$_} => $data->{_content})
						} else {
							@results = (delete $data->{$_} => $data)
						}
						last;
					}
				} else {
					if ($cnt eq 'content ') {
						@results = ($data->{$attr} => $data->{_content})
					} else {
						@results = (delete $data->{$attr} => $data);
					}
				}

			} else {
				croak "Unknown predefined rule '$rule'!";
			}
		}

		if (! @results or (@results % 2 == 0) or $results[-1] eq '') {
			if ($self->{opt}{stripspaces} & 3 and @{$self->{data}} and $self->{data}[-1]{_content}) { # stripping some spaces, it's not root and it did not return content
#print "maybe stripping some spaces in $Element, it's not root and it did not return content\n";
				if (($self->{opt}{stripspaces} & 3) < 3 and $self->{data}[-1]{_content}) {
					# rtrim parent content
#print "  yes, rtrim parent '$self->{data}[-1]{_content}'\n";
					$self->_rtrim( $self->{data}[-1], ($self->{opt}{stripspaces} & 4));
#print "  result '$self->{data}[-1]{_content}'\n";
				}

				$self->{_ltrim}[-1] = (($self->{opt}{stripspaces} & 4) ? 2 : 1)
					if ($self->{opt}{stripspaces} & 3) == 2;
			}
		} else {
			$self->{_ltrim}[-1] = 0;
		}
		if (($self->{opt}{stripspaces} & 3) == 3) {
			$self->{_ltrim}[-1] = (($self->{opt}{stripspaces} & 4) ? 2 : 1);
		}


		return unless scalar(@results) or scalar(@results) == 1 and ($results[0] eq '' or !defined($results[0]));

		@{$self->{data}} = ({}) unless @{$self->{data}}; # oops we are already closing the root tag! We do need there to be at least one hashref in $self->{data}

		if (scalar(@results) % 2) {
			# odd number of items, last is content
			my $value = pop(@results);
			_add_content( $self->{data}[-1], $value);
		}

		while (@results) {
			my ($key, $value) = ( shift(@results), shift(@results));
			if ($key eq '_content') {
				_add_content( $self->{data}[-1], $value);
			} elsif ($key =~ s/^\@//) {
				if (exists($self->{data}[-1]{$key}) and ref($self->{data}[-1]{$key}) ne 'ARRAY') {
					$self->{data}[-1]{$key} = [$self->{data}[-1]{$key}, $value];
				} else {
					push @{$self->{data}[-1]{$key}}, $value;
				}
			} elsif ($key =~ s/^\+//) {
				if (exists($self->{data}[-1]{$key})) {
					$self->{data}[-1]{$key} += $value;
				} else {
					$self->{data}[-1]{$key} = $value;
				}
			} elsif ($key =~ s/^\*//) {
				if (exists($self->{data}[-1]{$key})) {
					$self->{data}[-1]{$key} *= $value;
				} else {
					$self->{data}[-1]{$key} = $value;
				}
			} elsif ($key =~ s/^\.//) {
				if (exists($self->{data}[-1]{$key})) {
					$self->{data}[-1]{$key} .= $value;
				} else {
					$self->{data}[-1]{$key} = $value;
				}
#			} elsif ($key =~ s/^\%//) {
#				if (exists($self->{data}[-1]{$key})) {
#					if (ref($value) eq 'HASH') {
#						%{$self->{data}[-1]{$key}} = (%{$self->{data}[-1]{$key}}, %$value);
#					} elsif (ref($value) eq 'ARRAY') {
#						%{$self->{data}[-1]{$key}} = (%{$self->{data}[-1]{$key}}, @$value);
#					} else {
#						croak "The value of the rule return \%$key must be a hash or array ref!";
#					}
			} elsif ($key =~ s/^\%//) {
				if (exists($self->{data}[-1]{$key})) {
					if (ref($value) eq 'HASH') {
						if ($self->{opt}{warnoverwrite}) {
							foreach my $subkey (%$value) {
								warn "The key '$subkey' already exists in attribute $key for tag $self->{context}[-1].\n  old value: $self->{data}[-1]{$key}{$subkey}\n new value: $value->{$subkey}\n"
									if (exists $self->{data}[-1]{$key}{$subkey} and $self->{data}[-1]{$key}{$subkey} ne $value->{$subkey});
								$self->{data}[-1]{$key}{$subkey} = $value->{$subkey};
							}
						} else {
							%{$self->{data}[-1]{$key}} = (%{$self->{data}[-1]{$key}}, %$value);
						}
					} elsif (ref($value) eq 'ARRAY') {
						if ($self->{opt}{warnoverwrite}) {
							$value = {@$value}; # convert to hash
							foreach my $subkey (%$value) {
								warn "The key '$subkey' already exists in attribute $key for tag $self->{context}[-1].\n  old value: $self->{data}[-1]{$key}{$subkey}\n  new value: $value->{$subkey}\n"
									if (exists $self->{data}[-1]{$key}{$subkey} and $self->{data}[-1]{$key}{$subkey} ne $value->{$subkey});
								$self->{data}[-1]{$key}{$subkey} = $value->{$subkey};
							}
						} else {
							%{$self->{data}[-1]{$key}} = (%{$self->{data}[-1]{$key}}, @$value);
						}
					} else {
						croak "The value of the rule return \%$key must be a hash or array ref!";
					}
				} else {
					if (ref($value) eq 'HASH') {
						$self->{data}[-1]{$key} = $value;
					} elsif (ref($value) eq 'ARRAY') {
						$self->{data}[-1]{$key} = {@$value};
					} else {
						croak "The value of the rule return \%$key must be a hash or array ref!";
					}
				}
			} else {
				warn "The attribute '$key' already exists for tag $self->{context}[-1].\n  old value: $self->{data}[-1]{$key}\n  new value: $value\n"
					if ($self->{opt}{warnoverwrite} and exists $self->{data}[-1]{$key} and $self->{data}[-1]{$key} ne $value);
				$self->{data}[-1]{$key} = $value;
			}
		}
	}
}

sub _StartIgnore {
	weaken( my $self = shift);
	return sub {
		$self->{ignore_level}++
	}
}

sub _EndIgnore {
	weaken( my $self = shift);
	return sub {
		return if --$self->{ignore_level};

		$self->{parser}->setHandlers(@{$self->{normal_handlers}})
	}
}

sub _add_content {
	my ($hash, $value) = @_;
	if (ref($value)) {
		if (ref($hash->{_content})) {
			# both are refs, push to @_content
			push @{$hash->{_content}}, $value;
		} elsif (exists($hash->{_content})) {
			# result is ref, _content is not -> convert to an arrayref containing old _content and result
			$hash->{_content} = [ $hash->{_content}, $value]
		} else {
			# result is ref, _content is not present
			$hash->{_content} = [ $value]
		}
	} else {
		if (ref($hash->{_content})) {
			# _content is an arrayref, value is a string
			if (ref $hash->{_content}[-1]) {
				# the last element is a ref -> push
				push @{$hash->{_content}}, $value;
			} else {
				# the last element is a string -> concatenate
				$hash->{_content}[-1] .= $value;
			}
		} else {
			# neither is ref, concatenate
			$hash->{_content} .= $value;
		}
	}
}

=head1 INSTANCE METHODS

=head2 parse

	$parser->parse( $string [, $parameters]);
	$parser->parse( $IOhandle [, $parameters]);

Parses the XML in the string or reads and parses the XML from the opened IO handle,
executes the rules as it encounters the closing tags and returns the resulting structure.

The scalar or reference passed as the second parameter to the parse() method is assigned to
$parser->{parameters} for the parsing of the file or string. Once the XML is parsed the key is
deleted. This means that the $parser does not retain a reference to the $parameters after the parsing.

=head2 parsestring

	$parser->parsestring( $string [, $parameters]);

Just an alias to ->parse().

=head2 parse_string

	$parser->parse_string( $string [, $parameters]);

Just an alias to ->parse().

=head2 parsefile

	$parser->parsefile( $filename [, $parameters]);

Opens the specified file and parses the XML and executes the rules as it encounters
the closing tags and returns the resulting structure.

=head2 parse_file

	$parser->parse_file( $filename [, $parameters]);

Just an alias to ->parsefile().

=head2 parse_chunk

	while (my $chunk = read_chunk_of_data()) {
		$parser->parse_chunk($chunk);
	}
	my $data = $parser->last_chunk();

This method allows you to process the XML in chunks as you receive them. The chunks do not need to be in any
way valid ... it's fine if the chunk ends in the middle of a tag or attribute.

If you need to set the $parser->{parameters}, pass it to the first call to parse_chunk() the same way you would to parse().
The first chunk may be empty so if you need to set up the parameters, but read the chunks in a loop or in a callback, you can do this:

	$parser->parse_chunk('', {foo => 15, bar => "Hello World!"});
	while (my $chunk = read_chunk_of_data()) {
		$parser->parse_chunk($chunk);
	}
	my $data = $parser->last_chunk();

or

	$parser->parse_chunk('', {foo => 15, bar => "Hello World!"});
	$ua->get($url, ':content_cb' => sub { my($data, $response, $protocol) = @_; $parser->parse_chunk($data); return 1 });
	my $data = $parser->last_chunk();

The parse_chunk() returns 1 or dies, to get the accumulated data, you need to call last_chunk(). You will want to either agressively trim the data remembered
or handle parts of the file using custom rules as the XML is being parsed.

=head2 filter

	$parser->filter( $string);
	$parser->filter( $string, $LexicalOutputIOhandle [, $parameters]);
	$parser->filter( $LexicalInputIOhandle, $LexicalOutputIOhandle [, $parameters]);
	$parser->filter( $string, \*OutputIOhandle [, $parameters]);
	$parser->filter( $LexicalInputIOhandle, \*OutputIOhandle [, $parameters]);
	$parser->filter( $string, $OutputFilename [, $parameters]);
	$parser->filter( $LexicalInputIOhandle, $OutputFilename [, $parameters]);
	$parser->filter( $string, $StringReference [, $parameters]);
	$parser->filter( $LexicalInputIOhandle, $StringReference [, $parameters]);

Parses the XML in the string or reads and parses the XML from the opened IO handle,
copies the tags that do not have a subroutine rule specified and do not occure under such a tag,
executes the specified rules and prints the results to select()ed filehandle, $OutputFilename or
$OutputIOhandle or stores them in the scalar referenced by $StringReference using the ->ToXML() method.

The scalar or reference passed as the third parameter to the filter() method is assigned to
$parser->{parameters} for the parsing of the file or string. Once the XML is parsed the key is
deleted. This means that the $parser does not retain a reference to the $parameters after the parsing.

=head2 filterstring

	$parser->filterstring( ...);

Just an alias to ->filter().

=head2 filter_string

	$parser->filter_string( ...);

Just an alias to ->filter().

=head2 filterfile

	$parser->filterfile( $filename);
	$parser->filterfile( $filename, $LexicalOutputIOhandle [, $parameters]);
	$parser->filterfile( $filename, \*OutputIOhandle [, $parameters]);
	$parser->filterfile( $filename, $OutputFilename [, $parameters]);

Parses the XML in the specified file, copies the tags that do not have a subroutine rule specified
and do not occure under such a tag, executes the specified rules and prints the results to select()ed
filehandle, $OutputFilename or $OutputIOhandle or stores them in the scalar
referenced by $StringReference.

The scalar or reference passed as the third parameter to the filter() method is assigned to
$parser->{parameters} for the parsing of the file or string. Once the XML is parsed the key is
deleted. This means that the $parser does not retain a reference to the $parameters after the parsing.

=head2 filter_file

Just an alias to ->filterfile().

=head2 filter_chunk

	while (my $chunk = read_chunk_of_data()) {
		$parser->filter_chunk($chunk);
	}
	$parser->last_chunk();

This method allows you to process the XML in chunks as you receive them. The chunks do not need to be in any
way valid ... it's fine if the chunk ends in the middle of a tag or attribute.

If you need to set the file to store the result to (default is the select()ed filehandle) or set the $parser->{parameters}, pass it to the first call to filter_chunk() the same way you would to filter().
The first chunk may be empty so if you need to set up the parameters, but read the chunks in a loop or in a callback, you can do this:

	$parser->filter_chunk('', "the-filtered.xml", {foo => 15, bar => "Hello World!"});
	while (my $chunk = read_chunk_of_data()) {
		$parser->filter_chunk($chunk);
	}
	$parser->last_chunk();

or

	$parser->filter_chunk('', "the_filtered.xml", {foo => 15, bar => "Hello World!"});
	$ua->get($url, ':content_cb' => sub { my($data, $response, $protocol) = @_; $parser->filter_chunk($data); return 1 });
	filter_chunk$parser->last_chunk();

The filter_chunk() returns 1 or dies, you need to call last_chunk() to sign the end of the data and close the filehandles and clean the parser status.
Make sure you do not set a rule for the root tag or other tag containing way too much data. Keep in mind that even if the parser works as a filter,
the data for a custom rule must be kept in memory for the rule to execute!

=head2 last_chunk

	my $data = $parser->last_chunk();
	my $data = $parser->last_chunk($the_last_chunk_contents);

Finishes the processing of a XML fed to the parser in chunks. In case of the parser style, returns the accumulated data. In case of the filter style,
flushes and closes the output file. You can pass the last piece of the XML to this method or call it without parameters if all the data was passed to parse_chunk()/filter_chunk().

You HAVE to execute this method after call(s) to parse_chunk() or filter_chunk()! Until you do, the parser will refuse to process full documents and
expect another call to parse_chunk()/filter_chunk()!

=cut

sub escape_value {
	my($self, $data, $level) = @_;

	if (exists $self->{custom_escape}) {
		if (ref $self->{custom_escape}) {
			return $self->{custom_escape}->($data,$level);
		} else {
			return $data;
		}
	}

	return '' unless(defined($data) and $data ne '');

	if ($self->{opt}{output_encoding} ne $self->{opt}{encode}) {
		$data = Encode::decode( $self->{opt}{encode}, $data) if $self->{opt}{encode};
		$data = Encode::encode( $self->{opt}{output_encoding}, $data) if $self->{opt}{output_encoding};
	}

	$data =~ s/&/&amp;/sg;
	$data =~ s/</&lt;/sg;
	$data =~ s/>/&gt;/sg;
	$data =~ s/"/&quot;/sg;

	$level = $self->{opt}->{numericescape} unless defined $level;
	return $data unless $level;

	if($self->{opt}->{numericescape} eq '2') {
		$data =~ s/([^\x00-\x7F])/'&#' . ord($1) . ';'/gse;
	} else {
		$data =~ s/([^\x00-\xFF])/'&#' . ord($1) . ';'/gse;
	}
	return $data;
}

=head2 escape_value

	$parser->escape_value( $data [, $numericescape])

This method escapes the $data for inclusion in XML, the $numericescape may be 0, 1 or 2
and controls whether to convert 'high' (non ASCII) characters to XML entities.

0 - default: no numeric escaping (OK if you're writing out UTF8)

1 - only characters above 0xFF are escaped (ie: characters in the 0x80-FF range are not escaped), possibly useful with ISO8859-1 output

2 - all characters above 0x7F are escaped (good for plain ASCII output)

You can also specify the default value in the constructor

	my $parser = XML::Rules->new(
		...
		NumericEscape => 2,
	);

=cut

sub ToXML;*ToXML=\&toXML;
sub toXML {
	my $self = shift;
	if (!ref($self) and $self eq 'XML::Rules') {
		$self = XML::Rules->new(rules=>{}, ident => '  ');
	}
	my ($tag, $attrs, $no_close, $ident, $base);
	if (ref $_[0]) {
		($tag, $no_close, $ident, $base) = @_;
	} else {
		($tag, $attrs, $no_close, $ident, $base) = @_;
	}
	$ident = $self->{opt}{ident} unless defined $ident;

	if ($ident eq '') {
		$self->_toXMLnoformat(@_)
	} else {
		$base = '' unless defined $base;
		$base = "\n" . $base unless $base =~ /^\n/s;
		if (ref $tag) {
			$self->_toXMLformat($tag, $no_close, $ident, $base)
		} else {
			$self->_toXMLformat($tag, $attrs, $no_close, $ident, $base)
		}
	}
}

sub _toXMLnoformat {
	my ($self, $tag, $attrs, @body, $no_close);
	if (ref $_[1]) {
		if (ref $_[1] eq 'ARRAY') {
			($self, $tag, $no_close) = @_;
			($tag, $attrs, @body) = @$tag;
			if (defined $attrs and ref $attrs ne 'HASH') {
				unshift( @body, $attrs);
				$attrs = undef;
			}
		} else {
			croak("The first parameter to ->ToXML() must be the tag name or the arrayref containing [tagname, {attributes}, content]")
		}
	} else {
		($self, $tag, $attrs, $no_close) = @_;
		if (ref $attrs ne 'HASH') {
			if (defined $attrs and ref $attrs eq 'ARRAY') {
				return '' unless @$attrs;
				($attrs,@body) = (undef,@$attrs);
			} else {
				($attrs,@body) = (undef,$attrs);
			}
		}
	}

	push @body, $attrs->{_content} if $attrs and defined $attrs->{_content};
	$attrs = undef if (ref $attrs eq 'HASH' and (keys(%{$attrs}) == 0 or keys(%{$attrs}) == 1 and exists $attrs->{_content})); # ->toXML( $tagname, {}, ...)

#use Data::Dumper;
#print Dumper( [$tag, $attrs, \@body]);
#sleep(1);

	if ($tag eq '') {
		# \%attrs is ignored
		if (@body) {
			return join( '', map {
				if (!ref($_)) {
					$self->escape_value($_)
				} elsif (ref($_) eq 'ARRAY') {
					$self->_toXMLnoformat($_, 0)
				} else {
					croak "The content in XML::Rules->ToXML( '', here) must be a string or an arrayref containing strings and arrayrefs!";
				}
			} @body);
		} else {
			return '';
		}
	}

	if (@body > 1) {
		if (! $attrs) {
			my $result = '';
			while (@body) {
				my $content = shift(@body);
				if (ref $content eq 'HASH') {
					if (@body and ref($body[0]) ne 'HASH') {
						$result .= $self->_toXMLnoformat([$tag, $content, shift(@body)], 0)
					} else {
						$result .= $self->_toXMLnoformat([$tag, $content], 0)
					}
				} else {
					$result .= $self->_toXMLnoformat([$tag, undef, $content], 0)
				}
			}
			return $result;
		} else {
			my $result = '';
			while (@body) {
				my $content = shift(@body);
				if (ref $content eq 'HASH') {
					my %h = (%$attrs, %$content);
					if (@body and ref($body[0]) ne 'HASH') {
						$result .= $self->_toXMLnoformat([$tag, \%h, shift(@body)], 0)
					} else {
						$result .= $self->_toXMLnoformat([$tag, \%h], 0)
					}
				} else {
					$result .= $self->_toXMLnoformat([$tag, $attrs, $content])
				}
			}
			return $result;
		}
	}

	if (! $attrs and !ref($body[0])) { # ->toXML( $tagname, $string_content, ...)
		if ($no_close) {
			return "<$tag>" . $self->escape_value($body[0]);
		} elsif (! defined $body[0]) {
			return "<$tag/>";
		} else {
			return "<$tag>" . $self->escape_value($body[0]) . "</$tag>";
		}
	}

	my $content = $body[0];
	my $result = "<$tag";
	my $subtags = '';
	foreach my $key (sort keys %$attrs) {
		next if $key =~ /^:/ or $key eq '_content';
		if (ref $attrs->{$key}) {
			if (ref $attrs->{$key} eq 'ARRAY') {
				if (@{$attrs->{$key}}) {
					foreach my $subtag (@{$attrs->{$key}}) {
						$subtags .= $self->_toXMLnoformat($key, $subtag, 0);
					}
				} else {
					$subtags .= "<$key/>";
				}
			} elsif (ref $attrs->{$key} eq 'HASH') {
				$subtags .= $self->_toXMLnoformat($key, $attrs->{$key}, 0)
			} else {
				croak(ref($attrs->{$key}) . " attributes not supported in XML::Rules->toXML()!");
			}
		} else {
			$result .= qq{ $key="} . $self->escape_value($attrs->{$key}) . qq{"};
		}
	}
	if (! defined $content and $subtags eq '') {
		if ($no_close) {
			return $result.">";
		} else {
			return $result."/>";
		}

	} elsif (!ref($content)) { # content is a string, not an array of strings and subtags
		if ($no_close) {
			return "$result>$subtags" . $self->escape_value($content);
		} elsif ($content eq '' and $subtags ne '') {
			return "$result>$subtags</$tag>";
		} else {
			return "$result>$subtags" . $self->escape_value($content) ."</$tag>";
		}

	} elsif (ref($content) eq 'ARRAY') {
		$result .= ">$subtags";
		foreach my $snippet (@$content) {
			if (!ref($snippet)) {
				$result .= $self->escape_value($snippet);
			} elsif (ref($snippet) eq 'ARRAY') {
				$result .= $self->_toXMLnoformat($snippet, 0);
			} else {
				croak(ref($snippet) . " not supported in _content in XML::Rules->toXML()!");
			}
		}
		if ($no_close) {
			return $result;
		} else {
			return $result."</$tag>";
		}
	} else {
		croak(ref($content) . " _content not supported in XML::Rules->toXML()!");
	}
}

sub _toXMLformat {
	my ($self, $tag, $attrs, @body, $no_close, $ident, $base);
	if (ref $_[1]) {
		if (ref $_[1] eq 'ARRAY') {
			($self, $tag, $no_close, $ident, $base) = @_;
			($tag, $attrs, @body) = @$tag;
			if (defined $attrs and ref $attrs ne 'HASH') {
				unshift( @body, $attrs);
				$attrs = undef;
			}
		} else {
			croak("The first parameter to ->ToXML() must be the tag name or the arrayref containing [tagname, {attributes}, content]")
		}
	} else {
		($self, $tag, $attrs, $no_close, $ident, $base) = @_;
		if (ref $attrs ne 'HASH') {
			if (defined $attrs and ref $attrs eq 'ARRAY') {
				return '' unless @$attrs;
				($attrs,@body) = (undef,@$attrs);
			} else {
				($attrs,@body) = (undef,$attrs);
			}
		}
	}

	push @body, $attrs->{_content} if $attrs and defined $attrs->{_content};
	$attrs = undef if (ref $attrs eq 'HASH' and (keys(%{$attrs}) == 0 or keys(%{$attrs}) == 1 and exists $attrs->{_content})); # ->toXML( $tagname, {}, ...)

#use Data::Dumper;
#print Dumper( [$tag, $attrs, \@body]);
#sleep(1);

	if ($tag eq '') {
		# \%attrs is ignored
		if (@body) {
			return join( '', map {
				if (!ref($_)) {
					$self->escape_value($_)
				} elsif (ref($_) eq 'ARRAY') {
					$self->_toXMLformat($_, 0, $ident, $base)
				} else {
					croak "The content in XML::Rules->ToXML( '', here) must be a string or an arrayref containing strings and arrayrefs!";
				}
			} @body);
		} else {
			return '';
		}
	}

	if (@body > 1) {
		if (! $attrs) {
			my $result = '';
			while (@body) {
				$result .= $base if $result ne '';
				my $content = shift(@body);
				if (ref $content eq 'HASH') {
					if (@body and ref($body[0]) ne 'HASH') {
						$result .= $self->_toXMLformat([$tag, $content, shift(@body)], 0, $ident, $base)
					} else {
						$result .= $self->_toXMLformat([$tag, $content], 0, $ident, $base)
					}
				} else {
					$result .= $self->_toXMLformat([$tag, undef, $content], 0, $ident, $base)
				}
			}
			return $result;
		} else {
			my $result = '';
			while (@body) {
				$result .= $base if $result ne '';
				my $content = shift(@body);
				if (ref $content eq 'HASH') {
					my %h = (%$attrs, %$content);
					if (@body and ref($body[0]) ne 'HASH') {
						$result .= $self->_toXMLformat([$tag, \%h, shift(@body)], 0, $ident, $base)
					} else {
						$result .= $self->_toXMLformat([$tag, \%h], 0, $ident, $base)
					}
				} else {
					$result .= $self->_toXMLformat([$tag, $attrs, $content], 0, $ident, $base)
				}
			}
			return $result;
		}
	}

	if (! $attrs and !ref($body[0])) { # ->toXML( $tagname, $string_content, ...)
		if ($no_close) {
			return "<$tag>" . $self->escape_value($body[0]);
		} elsif (! defined $body[0]) {
			return "<$tag/>";
		} else {
			return "<$tag>" . $self->escape_value($body[0]) . "</$tag>";
		}
	}

	my $content = $body[0];
	my $result = "<$tag";
	my $subtags = '';
	my $had_child = 0;
	foreach my $key (sort keys %$attrs) {
		next if $key =~ /^:/ or $key eq '_content';
		if (ref $attrs->{$key}) {
			if (ref $attrs->{$key} eq 'ARRAY') {
				if (@{$attrs->{$key}}) {
					foreach my $subtag (@{$attrs->{$key}}) {
						$subtags .= $base . $ident . $self->_toXMLformat($key, $subtag, 0, $ident, $base.$ident);
						$had_child = 1;
					}
				} else {
					$subtags .= $base . $ident . "<$key/>";
				}
			} elsif (ref $attrs->{$key} eq 'HASH') {
				$subtags .= $base . $ident . $self->_toXMLformat($key, $attrs->{$key}, 0, $ident, $base.$ident);
				$had_child = 1;
			} else {
				croak(ref($attrs->{$key}) . " attributes not supported in XML::Rules->toXML()!");
			}
		} else {
			$result .= qq{ $key="} . $self->escape_value($attrs->{$key}) . qq{"};
		}
	}
	if (! defined $content and $subtags eq '') {
		if ($no_close) {
			return $result.">";
		} else {
			return $result."/>";
		}

	} elsif (!ref($content)) { # content is a string, not an array of strings and subtags
		if ($no_close) {
			return "$result>$subtags" . $self->escape_value($content);
		} elsif ($content eq '' and $subtags ne '') {
			return "$result>$subtags".($had_child ? $base : '')."</$tag>";
		} else {
			return "$result>$subtags" . $self->escape_value($content) . ($had_child ? $base : '') ."</$tag>";
		}

	} elsif (ref($content) eq 'ARRAY') {
		$result .= ">$subtags";
		foreach my $snippet (@$content) {
			if (!ref($snippet)) {
				$result .= $self->escape_value($snippet);
			} elsif (ref($snippet) eq 'ARRAY') {
				$result .= $base.$ident . $self->_toXMLformat($snippet, 0, $ident, $base.$ident);
				$had_child = 1;
			} else {
				croak(ref($snippet) . " not supported in _content in XML::Rules->toXML()!");
			}
		}
		if ($no_close) {
			return $result;
		} else {
			if ($had_child) {
				return $result.$base."</$tag>";
			} else {
				return $result."</$tag>";
			}
		}
	} else {
		croak(ref($content) . " _content not supported in XML::Rules->toXML()!");
	}
}


sub parentsToXML {
	my ($self, $level) = @_;
	my $tag_names = $self->{context};
	my $tag_attrs = $self->{data};

	$level = scalar(@$tag_names) unless $level;

	my $result = '';
	for (my $i = -1; -$i <= $level; $i--) {
		$result = $self->toXML( ${$tag_names}[$i], ${$tag_attrs}[$i], 1) . $result;
	}
	return $result;
}

sub closeParentsToXML {
	my ($self, $level) = @_;
	my $tag_names = $self->{context};

	if ($level) {
		return '</' . join( '></', (reverse(@{$tag_names}))[0..$level-1]) . '>';
	} else {
		return '</' . join( '></', reverse(@$tag_names)) . '>';
	}
}

=head2 toXML / ToXML

	$xml = $parser->toXML( $tagname, \%attrs[, $do_not_close, $ident, $base])

You may use this method to convert the datastructures created by parsing the XML into the XML format.
Not all data structures may be printed! I'll add more docs later, for now please do experiment.

The $ident and $base, if defined, turn on and control the pretty-printing. The $ident specifies the character(s)
used for one level of identation, the base contains the identation of the current tag. That is if you want to include the data inside of

	<data>
		<some>
			<subtag>$here</subtag>
		</some>
	</data>

you will call

	$parser->toXML( $tagname, \%attrs, 0, "\t", "\t\t\t");

The method does NOT validate that the $ident and $base are whitespace only, but of course if it's not you end up with invalid
XML. Newlines are added only before the start tag and (if the tag has only child tags and no content) before the closing tag,
but not after the closing tag! Newlines are added even if the $ident is an empty string.

=head2 parentsToXML

	$xml = $parser->parentsToXML( [$level])

Prints all or only the topmost $level ancestor tags, including the attributes and content (parsed so far),
but without the closing tags. You may use this to print the header of the file you are parsing,
followed by calling toXML() on a structure you build and then by closeParentsToXML() to close
the tags left opened by parentsToXML(). You most likely want to use the style => 'filter' option
for the constructor instead.

=head2 closeParentsToXML

	$xml = $parser->closeParentsToXML( [$level])

Prints the closing tags for all or the topmost $level ancestor tags of the one currently processed.

=head2 paths2rules

	my $parser = XML::Rules->new(
		rules => paths2rules {
			'/root/subtag/tag' => sub { ...},
			'/root/othertag/tag' => sub {...},
			'tag' => sub{ ... the default code for this tag ...},
			...
		}
	);

This helper function converts a hash of "somewhat xpath-like" paths and subs/rules into the format required by the module.
Due to backwards compatibility and efficiency I can't directly support paths in the rules and the direct syntax for their
specification is a bit awkward. So if you need the paths and not the regexps, you may use this helper instead of:

	my $parser = XML::Rules->new(
		rules => {
			'tag' => [
				'/root/subtag' => sub { ...},
				'/root/othertag' => sub {...},
				sub{ ... the default code for this tag ...},
			],
			...
		}
	);

=cut

sub paths2rules {
	my ($paths) = @_;

	my %rules;
	while ( my ($tag, $val) = each %$paths) {

		if ($tag =~ m{^(.*)/(.*)$}) {
			my ($path, $tagname) = ($1, $2);

			if (exists $rules{$tagname} and ref($rules{$tagname}) eq 'ARRAY') {
				if (@{$rules{$tagname}} % 2) {
					push @{$rules{$tagname}}, $path, $val;
				} else {
					splice @{$rules{$tagname}}, -1, 0, $path, $val;
				}
			} else {
				$rules{$tagname} = [ $path => $val]
			}

		} elsif (exists $rules{$tag} and ref($rules{$tag}) eq 'ARRAY') {
			push @{$rules{$tag}}, $val;
		} else {
			$rules{$tag} = $val
		}
	}

	return \%rules;
}

=head2 return_nothing

Stop parsing the XML, forget any data we already have and return from the $parser->parse().
This is only supposed to be used within rules and may be called both as a method and as
an ordinary function (it's not exported).

=head2 return_this

Stop parsing the XML, forget any data we already have and return the attributes passed to this subroutine
from the $parser->parse(). This is only supposed to be used within rules and may be called both as a method
and as an ordinary function (it's not exported).

=head2 skip_rest

Stop parsing the XML and return whatever data we already have from the $parser->parse().
The rules for the currently opened tags are evaluated as if the XML contained all
the closing tags in the right order.

These three work via raising an exception, the exception is caught within the $parser->parse() and does not propagate outside.
It's also safe to raise any other exception within the rules, the exception will be caught as well, the internal state of the $parser object
will be cleaned and the exception rethrown.

=head1 CLASS METHODS

=head2 parse

When called as a class method, parse() accepts the same parameters as new(), instantiates a new parser object
and returns a subroutine reference that calls the parse() method on that instance.

  my $parser = XML::Rules->new(rules => \%rules);
  my $data = $parser->parse($xml);

becomes

  my $read_data = XML::Rules->parse(rules => \%rules);
  my $data = $read_data->($xml);

or

  sub read_data;
  *read_data = XML::Rules->parse(rules => \%rules);
  my $data = read_data($xml);

=head2 parsestring, parsefile, parse_file, filter, filterstring, filter_string, filterfile, filter_file

All these methods work the same way as parse() when used as a class method. They accept the same parameters as new(),
instantiate a new object and return a subroutine reference that calls the respective method.

=head2 inferRulesFromExample

	Dumper(XML::Rules::inferRulesFromExample( $fileOrXML, $fileOrXML, $fileOrXML, ...)
	Dumper(XML::Rules->inferRulesFromExample( $fileOrXML, $fileOrXML, $fileOrXML, ...)
	Dumper($parser->inferRulesFromExample( $fileOrXML, $fileOrXML, $fileOrXML, ...)

The subroutine parses the listed files and infers the rules that would produce the minimal, but complete datastructure.
It finds out what tags may be repeated, whether they contain text content, attributes etc. You may want to give
the subroutine several examples to make sure it knows about all possibilities. You should use this once and store
the generated rules in your script or even take this as the basis of a more specific set of rules.

=cut

sub inferRulesFromExample {
	shift(@_) if $_[0] eq 'XML::Rules' or ref($_[0]);
	my @files = @_;

	my %rules;

	my $parser = XML::Rules->new(
		namespaces => { '*' => ''},
		rules => {
			_default => sub {
				my ($tag, $attrs, $context, $parent_data, $parser) = @_;
				my $repeated = (exists $parent_data->[-1] and exists $parent_data->[-1]{$tag});
				my $has_content = (exists $attrs->{_content});
				my $has_children = grep ref($_) eq 'HASH', values %$attrs;
				my $has_attr = grep {$_ ne '_content' and !ref($attrs->{$_})} keys %$attrs;

				my $rule = do {
					if ($repeated) {
						if ($has_content) {
							if ($has_attr or $has_children) {
								'as array'
							} else {
								'content array'
							}
						} else {
							if ($has_attr or $has_children) {
								'as array no content'
							} else {
								'content array'
							}
						}
					} else {
						if ($has_content) {
							if ($has_attr or $has_children) {
								'as is'
							} else {
								'content'
							}
						} else {
							if ($has_attr or $has_children) {
								'no content'
							} else {
								'content'
							}
						}
					}
				};

				if (not exists $rules{$tag}) {
					$rules{$tag} = $rule
				} elsif($rules{$tag} ne $rule) {
					# we've already seen the tag and it had different type
					if ($rules{$tag} eq 'raw extended array') {
					} elsif ($rule eq 'raw extended array') {
						$rules{$tag} = 'raw extended array';
					} elsif ($rules{$tag} eq 'raw extended' and $rule =~ /array/
						or $rule eq 'raw extended' and $rules{$tag} =~ /array/) {
						$rules{$tag} = 'raw extended array'
					} elsif ($rules{$tag} eq 'as array' or $rule eq 'as array') {
						$rules{$tag} = 'as array'
					} elsif ($rules{$tag} eq 'content array' and $rule eq 'content'
						or $rule eq 'content array' and $rules{$tag} eq 'content') {
						$rules{$tag} = 'content array'
					} elsif ($rules{$tag} eq 'content array' and $rule eq 'as array no content'
						or $rule eq 'content array' and $rules{$tag} eq 'as array no content') {
						$rules{$tag} = 'as array'
					} elsif ($rules{$tag} eq 'content array' and $rule eq 'as is'
						or $rule eq 'content array' and $rules{$tag} eq 'as is') {
						$rules{$tag} = 'as array'
					} elsif ($rules{$tag} eq 'content array' and $rule eq 'no content'
						or $rule eq 'content array' and $rules{$tag} eq 'no content') {
						$rules{$tag} = 'as array'
					} elsif ($rules{$tag} eq 'as array no content' and $rule eq 'as is'
						or $rule eq 'as array no content' and $rules{$tag} eq 'as is') {
						$rules{$tag} = 'as array'
					} elsif ($rules{$tag} eq 'as array no content' and $rule eq 'content'
						or $rule eq 'as array no content' and $rules{$tag} eq 'content') {
						$rules{$tag} = 'as array'
					} elsif ($rules{$tag} eq 'as array no content' and $rule eq 'no content'
						or $rule eq 'as array no content' and $rules{$tag} eq 'no content') {
						$rules{$tag} = 'as array no content'
					} elsif ($rules{$tag} eq 'as is' and ($rule eq 'no content' or $rule eq 'content')
						or $rule eq 'as is' and ($rules{$tag} eq 'no content' or $rules{$tag} eq 'content')) {
						$rules{$tag} = 'as is'
					} elsif ($rules{$tag} eq 'content' and $rule eq 'no content'
						or $rule eq 'content' and $rules{$tag} eq 'no content') {
						$rules{$tag} = 'as is'
					} else {
						die "Unexpected combination of rules: old=$rules{$tag}, new=$rule for tag $tag\n";
					}
				}

				if ($has_content and $has_children) { # the tag contains both text content and subtags!, need to use the raw extended rules
					foreach my $child (grep ref($attrs->{$_}) eq 'HASH', keys %$attrs) {
						next if $rules{$child} =~ /^raw extended/;
						if ($rules{$child} =~ /array/) {
							$rules{$child} = 'raw extended array'
						} else {
							$rules{$child} = 'raw extended'
						}
					}
				}
				return $tag => {};
			}
		},
		stripspaces => 7,
	);

	for (@files) {
		eval {
			if (! ref($_) and $_ !~ /\n/ and $_ !~ /^\s*</) {
				$parser->parsefile($_);
			} else {
				$parser->parse($_);
			}
		} or croak "Error parsing $_: $@\n";
	}

	my %short_rules;
	foreach my $tag (sort keys %rules) {
		push @{$short_rules{$rules{$tag}}}, $tag
	}

	foreach my $tags (values %short_rules) {
		$tags = join ',', sort @$tags;
	}
	%short_rules = reverse %short_rules;

	return \%short_rules;
}

=head2 inferRulesFromDTD

	Dumper(XML::Rules::inferRulesFromDTD( $DTDorDTDfile, [$enableExtended]))
	Dumper(XML::Rules->inferRulesFromDTD( $DTDorDTDfile, [$enableExtended]))
	Dumper($parser->inferRulesFromDTD( $DTDorDTDfile, [$enableExtended]))

The subroutine parses the DTD and infers the rules that would produce the minimal, but complete datastructure.
It finds out what tags may be repeated, whether they contain text content, attributes etc. You may use this
each time you are about to parse the XML or once and store the generated rules in your script or even take this
as the basis of a more specific set of rules.

With the second parameter set to a true value, the tags included in a mixed content will use the "raw extended"
or "raw extended array" types instead of just "raw". This makes sure the tag data both stay at the right place in
the content and are accessible easily from the parent tag's atrribute hash.

This subroutine requires the XML::DTDParser module!

=cut

sub inferRulesFromDTD {
	shift(@_) if $_[0] eq 'XML::Rules' or ref($_[0]);
	require XML::DTDParser;

	my ($DTDfile, $enable_extended) = @_;

	my $DTD = ( ($DTDfile=~ /\n/) ? XML::DTDParser::ParseDTD($DTDfile) : XML::DTDParser::ParseDTDFile($DTDfile));

	my $has_mixed = 0;
	foreach my $tag (values %$DTD) {
		$tag->{is_mixed} = (($tag->{content} and $tag->{children}) ? 1 : 0)
		 and $has_mixed = 1;
	}

	my %settings;
	foreach my $tagname (keys %$DTD) {
		my $tag = $DTD->{$tagname};

		my $repeated = ($tag->{option} =~ /^[+*]$/ ? 1 : 0);
		my $has_content = $tag->{content};

		my $in_mixed = grep {$DTD->{$_}{is_mixed}} @{$tag->{parent}};

		if ($in_mixed) {
			if ($enable_extended) {
				if ($repeated) {
					$settings{$tagname} = "raw extended array"
				} else {
					$settings{$tagname} = "raw extended"
				}
			} else {
				$settings{$tagname} = "raw"
			}
		} else {
			if (exists $tag->{attributes} or exists $tag->{children}) {
				my @ids ;
				if (exists $tag->{attributes}) {
					@ids = grep {$tag->{attributes}{$_}[0] eq 'ID' and $tag->{attributes}{$_}[1] eq '#REQUIRED'} keys %{$tag->{attributes}};
				}
				if (scalar(@ids) == 1) {
					if ($has_content) {
						$settings{$tagname} = "by $ids[0]"
					} else {
						$settings{$tagname} = "no content by $ids[0]"
					}
				} else {
					if ($has_content) {
						if ($repeated) {
							$settings{$tagname} = "as array"
						} else {
							$settings{$tagname} = "as is"
						}
					} else {
						if ($repeated) {
							$settings{$tagname} = "as array no content"
						} else {
							$settings{$tagname} = "no content"
						}
					}
				}
			} elsif ($repeated) {
				$settings{$tagname} = "content array"
			} else {
				$settings{$tagname} = "content"
			}
		}
	}

#	use Data::Dumper;
#	print Dumper(\%settings);

	my %compressed;
	{
		my %tmp;
		while (my ($tag, $option) = each %settings) {
			push @{$tmp{$option}}, $tag;
		}

		while (my ($option, $tags) = each %tmp) {
			$compressed{join ',', sort @$tags} = $option
		}
	}

	if ($has_mixed) {
		$compressed{"#stripspaces"} = 0;
	} else {
		$compressed{"#stripspaces"} = 7;
	}

	return \%compressed;
}

=head2 toXML / ToXML

The ToXML() method may be called as a class/static method as well. In that case the default identation is two spaces and the output encoding is utf8.

=head1 PROPERTIES

=head2 parameters

You can pass a parameter (scalar or reference) to the parse...() or filter...() methods, this parameter
is later available to the rules as $parser->{parameters}. The module will never use this parameter for
any other purpose so you are free to use it for any purposes provided that you expect it to be reset by
each call to parse...() or filter...() first to the passed value and then, after the parsing is complete, to undef.

=head2 pad

The $parser->{pad} key is specificaly reserved by the module as a place where the module users can
store their data. The module doesn't and will not use this key in any way, doesn't set or reset it under any
circumstances. If you need to share some data between the rules and do not want to use the structure built
by applying the rules you are free to use this key.

You should refrain from modifying or accessing other properties of the XML::Rules object!

=head1 IMPORTS

When used without parameters, the module does not export anything into the caller's namespace. When used with parameters
it either infers and prints a set of rules from a DTD or example(s) or instantiates a parser
and exports a subroutine calling the specified method similar to the parse() and other methods when called as class methods:

  use XML::Rules inferRules => 'c:\temp\example.xml';
  use XML::Rules inferRules => 'c:\temp\ourOwn.dtd';
  use XML::Rules inferRules => ['c:\temp\example.xml', c:\temp\other.xml'];
  use XML::Rules
    read_data => {
	  method => 'parse',
	  rules => { ... },
	  ...
	};
  use XML::Rules ToXML => {
    method => 'ToXML',
    rules => {}, # the option is required, but may be empty
    ident => '   '
  };
  ...
  my $data => read_data($xml);
  print ToXML(
    rootTag => {
      thing => [
        {Name => "english", child => [7480], otherChild => ['Hello world']},
        {Name => "espanol", child => [7440], otherChild => ['Hola mundo']},
    ]
  });


Please keep in mind that the use statement is executed at "compile time", which means that the variables declared and assigned above the statement
do not have the value yet! This is wrong!

  my %rules = ( _default => 'content', foo => 'as is', ...};
  use XML::Rules
    read_data => {
      method => 'parse',
      rules => \%rules,
      ...
    };

If you do not specify the method, then the method named the same as the import is assumed. You also do not have to specify the rules option for
the ToXML method as it is not used anyway:

  use XML::Rules ToXML => { ident => '  ' };
  use XML::Rules parse => {stripspaces => 7, rules => { ... }};

You can use the inferRules form the command line like this:

  perl -e "use XML::Rules inferRules => 'c:\temp\example.xml'"

or this:

  perl -MXML::Rules=inferRules,c:\temp\example.xml -e 1

or use the included xml2XMLRules.pl and dtd2XMLRules.pl scripts.

=head1 Namespace support

By default the module doesn't handle namespaces in any way, it doesn't do anything special with
xmlns or xmlns:alias attributes and it doesn't strip or mangle the namespace aliases
in tag or attribute names. This means that if you know for sure what namespace
aliases will be used you can set up rules for tags including the aliases and unless
someone decides to use a different alias or makes use of the default namespace
your script will work without turning the namespace support on.

If you do specify any namespace to alias mapping in the constructor it does
start processing the namespace stuff. The xmlns and xmlns:alias attributes
for the known namespaces are stripped from the datastructures and
the aliases are transformed from whatever the XML author decided to use
to whatever your namespace mapping specifies. Aliases are also added to all
tags that belong to a default namespace.

Assuming the constructor parameters contain

	namespaces => {
		'http://my.namespaces.com/foo' => 'foo',
		'http://my.namespaces.com/bar' => 'bar',
	}

and the XML looks like this:

	<root>
		<Foo xmlns="http://my.namespaces.com/foo">
			<subFoo>Hello world</subfoo>
		</Foo>
		<other xmlns:b="http://my.namespaces.com/bar">
			<b:pub>
				<b:name>NaRuzku</b:name>
				<b:address>at any crossroads</b:address>
				<b:desc>Fakt <b>desnej</b> pajzl.</b:desc>
			</b:pub>
		</other>
	</root>

then the rules wil be called as if the XML looked like this
while the namespace support is turned off:

	<root>
		<foo:Foo>
			<foo:subFoo>Hello world</foo:subfoo>
		</foo:Foo>
		<other>
			<bar:pub>
				<bar:name>NaRuzku</bar:name>
				<bar:address>at any crossroads</bar:address>
				<bar:desc>Fakt <b>desnej</b> pajzl.</bar:desc>
			</bar:pub>
		</other>
	</root>


This means that the namespace handling will normalize the aliases used so that you can use
them in the rules.

It is possible to specify an empty alias, so eg. in case you are processing a SOAP XML
and know the tags defined by SOAP do not colide with the tags in the enclosed XML
you may simplify the parsing by removing all namespace aliases.

You can control the behaviour with respect to the namespaces that you did not include
in your mapping by setting the "alias" for the special pseudonamespace '*'. The possible values
of the "alias"are: "warn" (default), "keep", "strip", "" and "die".

warn: whenever an unknown namespace is encountered, XML::Rules prints a warning.
The xmlns:XX attributes and the XX: aliases are retained for these namespaces.
If the alias clashes with one specified by your mapping it will be changed in all places,
the xmlns="..." referencing an unexpected namespace are changed to xmlns:nsN
and the alias is added to the tag names included.

keep: this works just like the "warn" except for the warning.

strip: all attributes and tags in the unknown namespaces are stripped. If
a tag in such a namespace contains a tag from a known namespace,
then the child tag is retained.

"": all the xmlns attributes and the aliases for the unexected namespaces are removed,
the tags and normal attributes are retained without any alias.

die: as soon as any unexpected namespace is encountered, XML::Rules croak()s.


=head1 HOW TO USE

You may view the module either as a XML::Simple on steriods and use it to build a data structure
similar to the one produced by XML::Simple with the added benefit of being able
to specify what tags or attributes to ignore, when to take just the content, what to store as an array etc.

You could also view it as yet another event based XML parser that differs from all the others only in one thing.
It stores the data for you so that you do not have to use globals or closures and wonder where to attach
the snippet of data you just received onto the structure you are building.

You can use it in a way similar to XML::Twig with simplify(): specify the rules to transform the lower
level tags into a XML::Simple like (simplify()ed) structure and then handle the structure in the rule for
the tag(s) you'd specify in XML::Twig's twig_roots.

=head1 Unrelated tricks

If you need to parse a XML file without the root tag (something that each and any sane person would allow,
but the XML comitee did not), you can parse

  <!DOCTYPE doc [<!ENTITY real_doc SYSTEM "$the_file_name">]><doc>&real_doc;</doc>

instead.

=head1 AUTHOR

Jan Krynicky, C<< <Jenda at CPAN.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-rules at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Rules>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Rules

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Rules>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Rules>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Rules>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Rules>

=item * PerlMonks

Please see L<http://www.perlmonks.org/?node_id=581313> or
L<http://www.perlmonks.org/?node=XML::Rules> for discussion.

=back

=head1 SEE ALSO

L<XML::Twig>, L<XML::LibXML>, L<XML::Pastor>

=head1 ACKNOWLEDGEMENTS

The escape_value() method is taken with minor changes from XML::Simple.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2012 Jan Krynicky, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# if I ever attempt to switch to SAX I want to look at XML::Handler::Trees

1; # End of XML::Rules
