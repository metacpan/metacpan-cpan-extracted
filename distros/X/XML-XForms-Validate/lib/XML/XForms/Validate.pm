package XML::XForms::Validate;

use 5.008;
use strict;
use warnings;
our $VERSION = '0.9';

use XML::LibXML;
use XML::LibXML::XPathContext;
use XML::Schema::Type::Builtin;
use Time::Piece;
use Time::Seconds;

use fields qw(base model refs instances submissions parser schemas binds);
use constant NSURI_XF => 'http://www.w3.org/2002/xforms';
use constant NSURI_XSD => 'http://www.w3.org/2001/XMLSchema-datatypes';
use constant NSURI_XSI => 'http://www.w3.org/2001/XMLSchema-instance';
use constant NSURI_XS => 'http://www.w3.org/2001/XMLSchema';
use constant NSURI_XI => 'http://www.w3.org/2001/XInclude';
use Exporter qw(import);
our @EXPORT_OK = qw(&validate &normalize);

# General-purpose globals. Each object uses specialized private instances as well.
my $parser = new XML::LibXML;

my $xpc = new XML::LibXML::XPathContext(new XML::LibXML::Document());
$xpc->registerNs('xf', NSURI_XF);

my $cbs = new XML::LibXML::InputCallback();
$cbs->register_callbacks([ sub {die}, sub {die}, sub {die}, sub {die} ]);

my $doc = new XML::LibXML::Document();

sub normalize {
	shift if UNIVERSAL::isa($_[0],'XML::XForms::Validate');
	my ($dom, $noclean) = @_;
	return $dom if !ref($dom);
	my $parser = new XML::LibXML(ext_ent_handler => sub {die});
	$parser->validation(0);
	$parser->load_ext_dtd(0);
	$parser->expand_xinclude(0);
	$parser->expand_entities(0);
	$parser->input_callbacks($cbs);
	$parser->clean_namespaces(1);
	$parser->no_network(1);
	$dom = { '' => $dom } if ref($dom) ne 'HASH';
	my $result = { };
	foreach my $id (keys %$dom) {
		my $old = $$dom{$id};
		$old = $old->documentElement if $old->can('documentElement');
		my $new = $parser->parse_string($old->toStringC14N(0));
		normalizeRecursive($new->documentElement, $noclean, {});
		$$result{$id} ||= $parser->parse_string($new->documentElement->toStringC14N(0));
		$$result{''} = $$result{$id} if ($id ne '' && $$dom{$id} eq $$dom{''});
	}

	return (ref($_[0]) eq 'HASH'?$result:$$result{''});
}

my %allowed = map { (eval('&XML_'.$_.'_NODE') => 1) } qw(ELEMENT ATTRIBUTE TEXT);
$allowed{&XML_NAMESPACE_DECL} = 1;
sub normalizeRecursive {
	my ($parent, $noclean, $usedns) = @_;

	my %newns;
	$newns{($parent->prefix||'').'='.($parent->namespaceURI||'')} = 1;
	foreach my $attr ($parent->attributes) {
		next if !$attr || $attr->nodeType == XML_NAMESPACE_DECL;
		$newns{($attr->prefix||'').'='.($attr->namespaceURI||'')} = 1;
	}

	foreach my $node ($parent->childNodes) {
		if ($allowed{$node->nodeType} && ($node->namespaceURI||'') ne NSURI_XI) {
			normalizeRecursive($node, \%newns);
		} else {
			$parent->removeChild($node);
		}
	}

	if (!$noclean) {
		foreach my $ns ($parent->getNamespaces) {
			my $prefix = $ns->nodeName || '';
			$prefix =~ s/^xmlns:?//;
			next if delete $newns{$prefix.'='.($ns->nodeValue||'')};
			$parent->setNamespaceDeclURI($prefix, undef);
		}
		%$usedns = (%$usedns, %newns);
	}
}

sub new {
	my XML::XForms::Validate $self = shift;
	$self = fields::new($self) unless (ref $self);

	$self->{parser} = new XML::LibXML();
	$self->{parser}->no_network(1);
	$self->{parser}->input_callbacks($cbs);
	$self->{parser}->{ext_ent_handler} = sub { die };
	$self->{parser}->clean_namespaces(1);
	$self->{parser}->expand_xinclude(0);
	$self->{parser}->validation(0);
	$self->{parser}->load_ext_dtd(0);
	$self->{parser}->no_network(1);

	my %options = @_;
	my ($xforms, $model, $base) = @options{'xforms', 'model', 'base'};
	$xforms = $self->getDom($xforms, $base);

	my $default;
	my ($id, $node);
	foreach my $m ($xpc->findnodes('//xf:model', $xforms)) {
		$id = $m->getAttribute('id');
		$id = '' if !defined $id;
		$default = $id if !defined $default;
		next if defined $model && $model ne $id;
		$self->{model} = $m;
		$model = $id;
		last;
	}

	my $anon = 0;
	$self->processBinds($self->{model}, [], $anon);

	$self->{refs} = [];
	$self->processRefs($xpc->findnodes('/*[1]', $xforms), [], $model, $default);

	if (!$xpc->findnodes('./xf:instance', $self->{model})) {
		my $instelt = $xforms->createElementNS(NSURI_XF, 'xf:instance');
		$self->{model}->addChild($instelt);
		$node = $xforms->createElement('instanceData');
		$instelt->addChild($node);

		foreach my $ui (@{$self->{refs}}) {
			next unless @$ui == 1;
			$node->addChild($xforms->createElement($$ui[0]));
		}
	}

	$self->{instances} = {};
	$self->{schemas} = {};
	foreach my $instance ($xpc->findnodes('./xf:instance', $self->{model})) {
		$id = $instance->getAttribute('id');
		$id = '' if !defined $id;
		if (defined (my $link = $instance->getAttribute('src'))) {
			$node = $self->{parser}->parse_file($link);
		} else {
			($node) = $xpc->findnodes('./*', $instance);
			$node = $self->{parser}->parse_string($node->toStringC14N());
		}
		$node = $node->documentElement();
		$self->{instances}{$id} ||= $node;
		$self->{instances}{''} ||= $node;

		my %loc;
		my $loc;
		$loc = $node->getAttributeNS(NSURI_XSI, 'schemaLocation');
		%loc = split(/\s+/, $loc) if $loc;
		$loc = $node->getAttributeNS(NSURI_XSI, 'noNamespaceSchemaLocation');
		$loc{''} = $loc if $loc;
		my $nsuri = $node->namespaceURI || '';
		$self->{schemas}{$id} = new XML::LibXML::Schema(location => $loc{$nsuri})
			if exists $loc{$nsuri};
	}

	$self->{submissions} = {};
	foreach my $s ($xpc->findnodes('./xf:submission', $self->{model})) {
		$id = $s->getAttribute('id');
		next unless defined $id && !$self->{submissions}{$id};
		$self->{submissions}{$id} = { id => $id };
		if (my $b = $s->getAttribute('bind')) {
			die "Invalid XForms document: referenced bind \"$b\" not found" unless exists $self->{binds}{$b};
			$self->{submissions}{$id}{'ref'} = [ @{$self->{binds}{$s->getAttribute('bind')}{nodeset}} ];
		} else {
			$self->{submissions}{$id}{'ref'} = [ $s->getAttribute('ref') || '/' ];
		}
		$self->{submissions}{''} = $self->{submissions}{$id} unless $self->{submissions}{''};
	}
	die "submission element is missing in model $model" unless %{$self->{submissions}};

	return $self;
}

sub getDom {
	my XML::XForms::Validate $self = shift;
	my ($data, $base) = @_;

	if (@_ == 2) {
		$self->{parser}->base_uri($base);
		$self->{base} = $base;
	}

	if (!ref($data)) {
		if (@_ == 2 && !defined $base) {
			$self->{parser}->base_uri($data);
			$self->{base} = $data;
		}
		$data = $parser->parse_file($data);
	} elsif (UNIVERSAL::isa($data, 'GLOB')) {
		$data = $parser->parse_fh($data, $base);
	} elsif (ref($data) eq 'SCALAR') {
		$data = $parser->parse_string($$data, $base);
	}
	die "Not an XML::LibXML DOM" unless UNIVERSAL::isa($data, 'XML::LibXML::Document');

	return $data;
}

my @mips = qw(type readonly required relevant constraint calculate p3ptype);
sub processBinds {
	my XML::XForms::Validate $self = shift;
	my $node = shift;
	my $context = shift;
	for my $anon ($_[0]) {
		foreach my $b ($xpc->findnodes('./xf:bind', $node)) {
			my $id = $b->getAttribute('id');
			$id = ' '.($anon++) unless defined $id;
			next if $self->{binds}{$id} || !$b->getAttribute('nodeset');
			my $ctx = [ @$context, $b->getAttribute('nodeset') ];
			$self->{binds}{$id} = { nodeset => $ctx, id => $id, node => $b };
			foreach my $a (@mips) {
				$self->{binds}{$id}{$a} = $b->getAttribute($a) if $b->getAttribute($a);
			}
			$self->processBinds($b, $ctx, $anon);
		}
	}
}

my %formControls = map {$_=>1} qw(input secret textarea output upload range submit select select1 setvalue);
sub processRefs {
	my XML::XForms::Validate $self = shift;
	my ($node, $context, $model, $default) = @_;

	foreach my $ui ($node->childNodes) {
		next unless $ui->isa('XML::LibXML::Element');
		my $ctx = $context;
		my $newdefault = $default;

		if (($ui->namespaceURI||'') eq NSURI_XF) {
			my $id = $ui->localName eq 'model'?($ui->getAttribute('id')||''):($ui->getAttribute('model')||$default);
			next if $id ne $model || $ui->localName eq 'instance';
			$newdefault = $id;
			my @expr;
			if (my $b = $ui->getAttribute('bind')) {
				die "Invalid XForms document: referenced bind \"$b\" not found" unless exists $self->{binds}{$b};
				@expr = @{$self->{binds}{$b}{'nodeset'}}
			}
			$expr[0] ||= $ui->getAttribute('nodeset');
			$expr[0] ||= $ui->getAttribute('ref');

			if (defined $expr[0]) {
				$ctx = [ @$context, @expr ];
				push @{$self->{refs}}, $ctx if exists $formControls{$ui->localName};
			}
		}
		$self->processRefs($ui, $ctx, $model, $newdefault);
	}
}

use Carp qw(cluck);
sub findNodes {
	my XML::XForms::Validate $self = shift;
	my ($expr, $context, $xpath) = @_;
	cluck("undef") if !$expr;
	my @expr = @$expr;
	my $last = pop @expr;
	foreach my $e (@expr) {
		($context) = $xpath->findnodes($e, $context);
	}
	my @nodes = $xpath->findnodes($last, $context);
	return @nodes;
}

sub findBoolean {
	my XML::XForms::Validate $self = shift;
	my ($expr, $context, $xpath) = @_;
	return $xpath->find("boolean($expr)", $context) && 1;
}

sub getInput {
	my XML::XForms::Validate $self = shift;
	my ($input, $orig, $submission) = @_;

	my $dom = {};
	foreach my $key (keys %{$orig}) {
		$$dom{$key} ||= $self->{parser}->parse_string($$orig{$key}->toString())->documentElement();
		$$dom{''} = $$dom{$key} if $key ne '' && $$orig{$key} eq $$orig{''};
	}

	my $ixpc = makeXPathContext(sub {
		my ($id) =  @_;
		my $result = XML::LibXML::NodeList->new;
		$result->push($$dom{$id});
		return $result;
	});

	my ($node) = $self->findNodes($submission, $$dom{''}, $ixpc);

	if (ref($input) eq 'HASH') {
		my @values;
		while (my ($key, $vals) = each %$input) {
			push @values, map { $key => $_ } (ref($vals)?@$vals:$vals);
		}
		$input = \@values;
	}

	if (ref($input) eq 'ARRAY') {
		my %pos;
		while (@$input) {
			my $key = shift @$input;
			my $val;
			if (ref($key)) { ($key, $val) = @$key; }
			else { $val = shift @$input }
			($key) = $key =~ m/([a-zA-Z0-9:_-]*)/; # FIXME: QName.
			my $pos = ++$pos{$key};
			my ($node) = $xpc->findnodes(".//*[local-name() = '${key}' and not(*)][$pos]", $node);
			$node->removeChildNodes();
			$node->appendTextNode($val);
		}
	} else {
		my $parent = $node->parentNode();
		if (!$parent) {
			$parent = $self->{parser}->parse_string($self->getDom($input)->documentElement()->toStringC14N());
			foreach my $key (keys %$dom) {
				$$dom{$key} = $parent->documentElement if ${$$dom{$key}->ownerDocument} eq ${$node->ownerDocument};
			}
			$node = $parent;
		} else {
			my $new = $self->{parser}->parse_balanced_chunk($self->getDom($input)->documentElement()->toStringC14N())->firstChild;
			$parent->replaceChild($new, $node);
			$node = $new;
		}
	}

	return ($dom, $node);
}

sub makeNodeName {
	my ($node) = @_;
	my $name = $node->nodeName;
	$name = '<anon>' if !defined $name;
	return '' if $name =~ m/^xmlns/;
	$name =~ s/^[^:]*://;
	my $ns = $node->namespaceURI();
	$ns = (defined $ns?"{$ns}":"");
	return $ns.$name;
}

sub checkTreeRecursive {
	my XML::XForms::Validate $self = shift;
	my ($new, $orig, $added) = @_;

	my $path = $new->nodePath;
	my $ndoc = $new->ownerDocument;

	my $nname = makeNodeName($new);
	my $oname = makeNodeName($orig);
	return "Original node \"$oname\" doesn't match \"$nname\" ($path)"
		if $nname ne $oname;

	my @added;

	my %nattr = map { (makeNodeName($_) => $_) } $new->attributes;
	my %oattr = map { (makeNodeName($_) => $_) } $orig->attributes;
	delete $nattr{''};
	delete $oattr{''};
	foreach my $attr (keys %oattr) {
		delete $nattr{$attr}, next if exists $nattr{$attr};
		$new->setAttributeNS($oattr{$attr}->namespaceURI, $oattr{$attr}->nodeName, $oattr{$attr}->nodeValue);
		my $clone = $new->getAttributeNodeNS($oattr{$attr}->namespaceURI, $oattr{$attr}->nodeName);
		push @added, $clone;
	}

	return "Additional attributes found: ".join(", ", keys %nattr)." ($path)"
		if %nattr;

	my @nelem = grep { $_->isa('XML::LibXML::Element') } $new->childNodes;
	my @oelem = grep { $_->isa('XML::LibXML::Element') } $orig->childNodes;
	my $firstmsg;
	my $lastmsg;
	while (@oelem) {
		last if !@nelem;
		my $nnext = $nelem[0];
		my $onext = shift @oelem;
		my $msg = $self->checkTreeRecursive($nnext, $onext, \@added);
		$firstmsg = undef, shift @nelem, next if !$msg;
		my $clone = $self->{parser}->parse_balanced_chunk($onext->toString())->firstChild;
		$new->insertBefore($clone, $nelem[0]);
		$new->insertAfter($new->ownerDocument->createTextNode(''), $clone) if $onext->nextSibling->nodeType == XML_TEXT_NODE;
		push @added, $clone;
		$firstmsg ||= $msg;
	}

	push(@$added, @added), return undef if !@nelem && !@oelem;

	$_->parentNode->removeChild($_) foreach @added;
	$firstmsg ||= "Additional child elements found: ".join(", ", map { $_->nodeName } @nelem)." ($path)" if @nelem;
	$firstmsg ||= "Child elements missing: ".join(", ", map { $_->nodeName } @oelem)." ($path)" if @oelem;

	return $firstmsg;
}

sub hasParents {
	my ($child, $parents) = @_;
	my $test = $child;
	do {
		return 1 if exists $$parents{${$test}};
	} while ($test = $test->parentNode);
	return 0;
}

sub checkTree {
	my XML::XForms::Validate $self = shift;
	my ($new, $orig, $ixpc, $oxpc, $subtree) = @_;

	my $added = [];
	foreach my $key (keys %$orig) {
		my $result = $self->checkTreeRecursive($$new{$key}, $$orig{$key}, $added);
		return $result if $result;
	}

	$added = { map { ${$_} => $_ } @$added };
	my %leftover = %$added;
	foreach my $bind (values %{$self->{binds}}) {
		next if !exists $$bind{relevant};
		foreach my $node ($self->findNodes($$bind{nodeset}, $$new{''}, $ixpc)) {
			next if $self->findBoolean($$bind{relevant}, $node, $ixpc);
			my $deleted = delete $leftover{${$node}};
			next if hasParents($node, $added) || !hasParents($node, $subtree);
			return "Submission contains non-relevant node: ".$node->nodePath if !$deleted;
		}
	}

	foreach my $rest (values %leftover) {
		delete $$added{${$rest}};
		delete $leftover{${$rest}} if hasParents($rest, $added);
		$$added{${$rest}} = $rest;
	}
	return "Missing relevant nodes: ".join(", ", map { $_->nodePath } values %leftover) if %leftover;

	return undef;
}

sub checkReadonlyRecursive {
	my XML::XForms::Validate $self = shift;
	my ($new, $orig, $nrw, $orw) = @_;

	my %nattr = map { (makeNodeName($_) => $_) } $new->attributes;
	my %oattr = map { (makeNodeName($_) => $_) } $orig->attributes;
	delete $nattr{''};
	delete $oattr{''};
	foreach my $attr (keys %oattr) {
		next if exists $$nrw{${$nattr{$attr}}} || exists $$orw{${$oattr{$attr}}};
		$nattr{$attr}->setValue($oattr{$attr}->getValue());
	}

	my @nelem = grep { $_->isa('XML::LibXML::Element') } $new->childNodes;
	my @oelem = grep { $_->isa('XML::LibXML::Element') } $orig->childNodes;
	while (@oelem) {
		my $nnext = shift @nelem;
		my $onext = shift @oelem;
		if (!exists $$nrw{${$nnext}} && !exists $$orw{${$onext}}) {
			my ($ntext) = $nnext->findnodes('./text()[1]');
			my ($otext) = $onext->findnodes('./text()[1]');
			$otext = ($otext?$otext->nodeValue:'');
			if (!$ntext) {
				$ntext = $nnext->appendText($otext);
			} else {
				$ntext->setData($otext);
			}
		}
		my $result = $self->checkReadonlyRecursive($nnext, $onext, $nrw, $orw);
		return $result if $result;
	}

	@nelem = grep { $_->isa('XML::LibXML::Text') } $new->childNodes;
	@oelem = grep { $_->isa('XML::LibXML::Text') } $orig->childNodes;
	while (@oelem) {
		my $nnext = shift @nelem;
		my $onext = shift @oelem;
		if (!$nnext) {
			my $val = $onext->nodeValue;
			$val =~ s/^\s*|\s*$//g;
			return "Text node missing for ".$onext->nodePath if length($val) && !exists $$orw{${onext}};
			$new->appendText('') if exists $$orw{${onext}};
			next;
		}
		next if exists $$nrw{${$nnext}} || exists $$orw{${$onext}};
		$nnext->setData($onext->nodeValue);
	}
	foreach my $node (@nelem) {
		$new->removeChild($node) unless exists $$nrw{${$node}};
	}

	return undef;
}

sub setRW {
	my ($rw, $n) = @_;
	if ($n) {
		$$rw{${$n}} = $n;
		($n) = $n->findnodes('./text()[1]');
		$$rw{${$n}} = $n if $n;
	}
}

sub checkReadonly {
	my XML::XForms::Validate $self = shift;
	my ($new, $orig, $ixpc, $oxpc, $subtree) = @_;

	my %nrw;
	my %orw;
	foreach my $expr (@{$self->{refs}}) {
		setRW(\%nrw, $self->findNodes($expr, $$new{''}, $ixpc));
		setRW(\%orw, $self->findNodes($expr, $$orig{''}, $oxpc));
	}

	foreach my $bind (values %{$self->{binds}}) {
		my $ro = $$bind{readonly};
		next if !defined $ro;
		foreach my $node ($self->findNodes($$bind{nodeset}, $$new{''}, $ixpc)) {
			next if defined $ro && !$self->findBoolean($ro, $node, $ixpc);
			delete $nrw{${$_}} foreach $node->findnodes('.|.//*|.//@*|.//text()');
		}
		foreach my $node ($self->findNodes($$bind{nodeset}, $$orig{''}, $oxpc)) {
			next if defined $ro && !$self->findBoolean($ro, $node, $oxpc);
			delete $orw{${$_}} foreach $node->findnodes('.|.//*|.//@*|.//text()');
		}
	}

	foreach my $bind (values %{$self->{binds}}) {
		if (defined $$bind{calculate}) {
			setRW(\%nrw, $_) foreach ($self->findNodes($$bind{nodeset}, $$new{''}, $ixpc));
			setRW(\%orw, $_) foreach ($self->findNodes($$bind{nodeset}, $$orig{''}, $oxpc));
		}
	}

	foreach my $key (keys %$orig) {
		my $result = $self->checkReadonlyRecursive($$new{$key}, $$orig{$key}, \%nrw, \%orw);
		return $result if $result;
	}
}

sub checkBinds {
	my XML::XForms::Validate $self = shift;
	my ($new, $orig, $ixpc, $oxpc, $subtree) = @_;

	foreach my $bind (values %{$self->{binds}}) {
		my ($prefix, $type) = ($$bind{type}||'') =~ m/^(?:([^:]*):)?(.*)$/;
		$prefix ||= '';
		my $calc = $$bind{calculate};
		my $constraint = $$bind{constraint};
		my $required = $$bind{required};
		my $relevant = $$bind{relevant};
		next unless defined $type || defined $calc || defined $constraint || defined $required;

		foreach my $node ($self->findNodes($$bind{nodeset}, $$new{''}, $ixpc)) {
			next if !hasParents($node, $subtree) || (defined $relevant && !$self->findBoolean($relevant, $node, $ixpc));

			my $val = ($node->isa('XML::LibXML::Element')?$node->findvalue('./text()[1]'):$node->nodeValue);
			my $path = $node->nodePath;

			return "Value required for $path" if defined $required
				&& $self->findBoolean($required, $node, $ixpc) && !length($val);
			return "Constraint error for $path ($constraint)" if defined $constraint
				&& !$self->findBoolean($constraint, $node, $ixpc);
			return "Calculation mismatch for $path ($calc): expected \"".$ixpc->findvalue($calc, $node)."\", found \"$val\"" if defined $calc
				&& $ixpc->findvalue($calc, $node) ne $val;

			next unless $type;
			# FIXME: really needs switch to libxm
			my $nsuri = $$bind{node}->lookupNamespaceURI($prefix) || '';
			my $class;
			$class = XML::Schema::Type::Simple->builtin($type) if $nsuri eq NSURI_XSD || $nsuri eq NSURI_XS; 
			$class = "XML::XForms::Validate::Type::$type" if $nsuri eq NSURI_XF; 
			my $const = UNIVERSAL::can($class, 'new');
			return "Type $prefix:$type unsupported for $path" if !defined $const;
			my $obj = $const->($class);
			return "Could not create object for $path ($type)" if !$obj;
			return "Type mismatch for $path ($type)"
				if !$obj->instance($val);
		}
	}

	return undef;
}

sub checkSchema {
	my XML::XForms::Validate $self = shift;
	my ($new) = @_;

	foreach my $id (keys %{$self->{schemas}}) {
		eval { $self->{schemas}{$id}->validate($$new{$id}->ownerDocument) };
		return "Schema validation failed for instance \"$id\": $@" if $@;
	}
	return undef;
}

sub validate {
	my XML::XForms::Validate $self;
	$self = shift if UNIVERSAL::isa($_[0], 'XML::XForms::Validate');
	my %options = @_;
	if (!$self) {
		$self = new XML::XForms::Validate(xforms => $options{xforms}, model => $options{model}, base => $options{base});
	}

	my $model = $self->{model};

	my $orig = { %{$self->{instances}} };

	if ($options{instance}) {
		$options{instance} = { '' => $options{instance} } if ref($options{instance}) ne 'HASH';
		foreach my $key (keys %{$options{instance}}) {
			my $replaced = $$orig{$key};
			$$orig{$key} = $self->getDom($options{instance}{$key});
			$$orig{''} = $$orig{$key} if $$orig{''} eq $replaced;
		}
	}

	$options{submission} = '' unless defined $options{submission};
	my $subref = $self->{submissions}{$options{submission}}{'ref'};

	my ($new, $subnode) = $self->getInput($options{input}, $orig, $subref);

	my $oxpc = makeXPathContext(sub {
		my ($id) =  @_;
		my $result = XML::LibXML::NodeList->new;
		$result->push($$orig{$id});
		return $result;
	});
	my $ixpc = makeXPathContext(sub {
		my ($id) =  @_;
		my $result = XML::LibXML::NodeList->new;
		$result->push($$new{$id});
		return $result;
	});

	my ($newsub) = $self->findNodes($subref, $$new{''}, $ixpc);
	return "Submission does not match subtree reference (@$subref)"
		if !$newsub || ${$newsub} ne ${$subnode};

	if ($options{schema}) {
		eval { XML::LibXML::Schema->new(location => $options{schema})->validate($subnode) };
		return "Schema validation failed: $@" if $@;
		return $new;
	}

	my $subtree = { ${$subnode} => $subnode };
	my $result = $self->checkTree($new, $orig, $ixpc, $oxpc, $subtree);
	return $result if $result;
	($newsub) = $self->findNodes($subref, $$new{''}, $ixpc);
	return "Submission does not match subtree reference (@$subref) after relevancy processing"
		if !$newsub || ${$newsub} ne ${$subnode};

	$result = $self->checkReadonly($new, $orig, $ixpc, $oxpc, $subtree);
	return $result if $result;

	$result = $self->checkBinds($new, $orig, $ixpc, $oxpc, $subtree);
	return $result if $result;

	$result = $self->checkSchema($new);
	return $result if $result;

	return $new;
}

# XPath Extensions
# These use an internal XPathContext for calculations to make sure XPath
# semantics are obeyed, especially regarding type conversion.

sub makeXPathContext {
	my ($instancefunc) = @_;
	my $xpc = new XML::LibXML::XPathContext;
	$xpc->registerNs('xf', NSURI_XF); # FIXME: must be done on a per-evaluation basis instead
	$xpc->registerFunction('instance', $instancefunc);
	$xpc->registerFunction('boolean-from-string', \&XPath_booleanFromString);
	$xpc->registerFunction('if', \&XPath_if);
	$xpc->registerFunction('avg', \&XPath_avg);
	$xpc->registerFunction('min', \&XPath_min);
	$xpc->registerFunction('max', \&XPath_max);
	$xpc->registerFunction('count-non-empty', \&XPath_countNonEmpty);
	$xpc->registerFunction('index', \&XPath_index);
	$xpc->registerFunction('property', \&XPath_property);
	$xpc->registerFunction('now', \&XPath_now);
	$xpc->registerFunction('days-from-date', \&XPath_daysFromDate);
	$xpc->registerFunction('seconds-from-dateTime', \&XPath_secondsFromDateTime);
	$xpc->registerFunction('seconds', \&XPath_seconds);
	$xpc->registerFunction('months', \&XPath_months);
	return $xpc;
}

sub XPath_booleanFromString {
	my ($str) = @_;
	my $xpc = new XML::LibXML::XPathContext;
	$xpc->registerVarLookupFunc(sub { return $str }, undef);
	$str = $xpc->findvalue('string($str)', $doc);
	return XML::LibXML::Boolean->True if (lc($str) eq 'true' || $str eq '1');
	return XML::LibXML::Boolean->False if (lc($str) eq 'false' || $str eq '0');
	die "Invalid boolean string value: $str";
}

sub XPath_if {
	my ($bool, $true, $false) = @_;
	my $xpc = new XML::LibXML::XPathContext;
	$xpc->registerVarLookupFunc(sub { return $bool }, undef);
	$bool = $xpc->findvalue('boolean($bool)', $doc);
	return ($bool eq 'true'?$true:$false);
}

sub XPath_avg {
	my ($nodeset) = @_;

	my $xpc = new XML::LibXML::XPathContext;
	$xpc->registerVarLookupFunc(sub { return $nodeset }, undef);
	return $xpc->find('sum($x) div count($x)', $doc);
}

sub XPath_min {
	my ($nodeset) = @_;
	return new XML::LibXML::Number('NaN') if (!$nodeset->size());
	my $min = $nodeset->shift;
	my $cur = $min;

	my $xpc = new XML::LibXML::XPathContext;
	$xpc->registerVarLookupFunc(sub { return $min }, undef);
	while ($nodeset->size()) {
		$cur = $nodeset->shift;
		$min = $cur if $xpc->findvalue('. < $min', $cur) eq 'true';
	}

	return $min;
}

sub XPath_max {
	my ($nodeset) = @_;
	return new XML::LibXML::Number('NaN') if (!$nodeset->size());
	my $max = $nodeset->shift;
	my $cur = $max;

	my $xpc = new XML::LibXML::XPathContext;
	$xpc->registerVarLookupFunc(sub { return $max }, undef);
	while ($nodeset->size()) {
		$cur = $nodeset->shift;
		$max = $cur if $xpc->findvalue('. > $max', $cur) eq 'true';
	}

	return $max;
}

sub XPath_countNonEmpty {
	my ($nodeset) = @_;
	my $cur;
	my $result = 0;

	my $xpc = new XML::LibXML::XPathContext;
	while ($nodeset->size()) {
		$cur = $nodeset->shift;
		$result++ if $xpc->findvalue('string-length(.)', $cur) > 0;
	}

	return new XML::LibXML::Number($result);
}

sub XPath_index {
	# Doesn't apply to validation.
	die "index() not supported.";
}

sub XPath_property {
	my ($str) = @_;
	my $xpc = new XML::LibXML::XPathContext;
	$xpc->registerVarLookupFunc(sub { return $str }, undef);
	$str = $xpc->findvalue('string($str)', $doc);
	return new XML::LibXML::Literal('1.0') if ($str eq 'version');
	return new XML::LibXML::Literal('full') if ($str eq 'conformance-level');
	return new XML::LibXML::Literal('');
}

sub XPath_now {
	my $now = localtime;
	my $off = $now->tzoffset;
	my $time = $now->datetime().sprintf('%+03d:%02d', int($off->hours), abs($off->minutes)%60);
	return new XML::LibXML::Literal($time);
}

sub XPath_daysFromDate {
	my ($day) = @_;
	my $xpc = new XML::LibXML::XPathContext;
	$xpc->registerVarLookupFunc(sub { return $day }, undef);
	$day = $xpc->findvalue('string($day)', $doc);
	$day =~ s/T.*//;
	my $time = Time::Piece->strptime($day, "%Y-%m-%d")->epoch / ONE_DAY;
	return new XML::LibXML::Number($time);
}

sub XPath_secondsFromDateTime {
	my ($date) = @_;
	my $xpc = new XML::LibXML::XPathContext;
	$xpc->registerVarLookupFunc(sub { return $date }, undef);
	$date = $xpc->findvalue('string($date)', $doc);
	my ($day, $sign, $h, $m) = $date =~ m/^(.*?)(?:\.[0-9]*)?(?:Z|([+-])([0-9]{2}):([0-9]{2}))?$/;
	my $time = Time::Piece->strptime($day, "%Y-%m-%dT%H:%M:%S")->epoch;
	$sign ||= '';
	if ($sign eq '+') {
		$time -= $h*60+$m;
	} elsif ($sign eq '-') {
		$time += $h*60+$m;
	}
	return new XML::LibXML::Number($time);
}

sub XPath_seconds {
	my ($duration) = @_;
	my $xpc = new XML::LibXML::XPathContext;
	$xpc->registerVarLookupFunc(sub { return $duration }, undef);
	$duration = $xpc->findvalue('string($duration)', $doc);
	my ($sign, $d, $h, $m, $s) = $duration =~ m/^([+-]?)P.*?(?:([0-9]+)D)?(?:T(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9.]+)S)?)?$/;
	$sign .= 1;
	return new XML::LibXML::Number(((($d*24+$h)*60+$m)*60+$s)*$sign);
}

sub XPath_months {
	my ($duration) = @_;
	my $xpc = new XML::LibXML::XPathContext;
	$xpc->registerVarLookupFunc(sub { return $duration }, undef);
	$duration = $xpc->findvalue('string($duration)', $doc);
	my ($sign, $y, $m) = $duration =~ m/^([+-]?)P(?:([0-9]+)Y)?(?:([0-9]+)M)?.*$/;
	$sign .= 1;
	return new XML::LibXML::Number(($y*12+$m)*$sign);
}

package XML::Schema::Type::duration;
use base qw( XML::Schema::Type::timeDuration );
# FIXME: hack for XML::Schema bug

package XML::Schema::Type::dateTime;
use base qw( XML::Schema::Type::recurringDuration );
use vars qw( $ERROR @FACETS );
@FACETS = (
    period   => { value => 'P10000Y', fixed => 1 },
    duration => { value => 'P0Y', fixed => 1 },
);
# FIXME: hack for XML::Schema bug

package XML::XForms::Validate::Type::listItem;
use base qw( XML::Schema::Type::string );
use vars qw( $ERROR @FACETS );

@FACETS = (
    pattern => {
        value  => '^\S+$',
        errmsg => 'value is not a valid listItem',
    }
);

package XML::XForms::Validate::Type::listItems;
use base qw( XML::Schema::Type::string );
use vars qw( $ERROR @FACETS );
# FIXME: this is technically wrong, but sufficient for our purposes.

@FACETS = (
    pattern => {
        value  => '^((\S+\s+)*\S+)?$',
        errmsg => 'value is not a valid listItem list',
    }
);

package XML::XForms::Validate::Type::dayTimeDuration;
use base qw( XML::Schema::Type::duration );
use vars qw( $ERROR @FACETS );
# FIXME: no idea if this works as intended.

@FACETS = (
    duration => { value => 'P0Y0M', fixed => 1 },
);

package XML::XForms::Validate::Type::yearMonthDuration;
use base qw( XML::Schema::Type::duration );
use vars qw( $ERROR @FACETS );
# FIXME: no idea if this works as intended.

@FACETS = (
    duration => { value => 'P0DT0H0M0S', fixed => 1 },
);


1;
__END__

=head1 NAME

XML::XForms::Validate - Perl extension for validation of XForms submissions

=head1 SYNOPSIS

  use XML::XForms::Validate qw(validate);
  
  # For method="post":
  $msg = validate(input => $filename, xforms => $file, base => '../instances', model => 'form2') and die $msg;
  
  # For method="get", method="urlencoded-post" or method="form-data-post":
  $result = validate(input => \%parameters, xforms => \$xml_string);
  die $result if !ref($result);
  
  # OO usage:
  my $validator = XML::XForms::Validate->new(input => \$xml_string, model => $model, base => $base);
  $result = $validator->validate(input => $input);
  die $result if !ref($result);
  $result = $validator->normalize($validator->validate(input => $input2));
  die $result if !ref($result);

=head1 DESCRIPTION

This module validates input data against an XML document containing one or more
XForms models. It is able to process all serializations except C<multipart/related>,
relying on pre-parsed data for C<multipart/form-data> or C<application/x-www-form-urlencoded>.

Usage is rather simple: Supply input data (usually a submitted XML instance), an XML
document containing one or more XForms models, and possibly some optional arguments.
The return value is a hash of validated (and possibly modified) result DOM trees, one
entry per original instance, or an error message string if validation failed.

Since XForms is a sufficient complex standard to make perfect validation of submission
data impossible in the general case, some assumptions must be made. Most forms should
work fine, but it is possible (and easy, if you know how) to create forms that yield
submissions which are rejected as invalid. Likewise, there are some constructions
which can allow invalid submissions to pass as valid. These limitations are documented
in L</VALIDATION>, so please read that section carefully.

=head2 RATIONALE

In a networked scenario, XForms is a client-side technology. Having a Perl module may
seem a bit useless, since Perl is usually used on the server side. On the other hand,
everyone knows that user input should always be validated, but client-side validation is
inherently untrusted.

There are several options for server-side validation of XML data, for example XML Schema
or RelaxNG/Schematron. This module, in contrast, tries to deduce the allowed modifications
directly from the XForms document that was used to build the input. It makes life easier
for simple forms that do not warrant a full-blown XML Schema document. Most importantly,
it is able to perform additional checks that are impossible with standalone schema
validation, like readonly value enforcement and calculation result checks.

=head2 VALIDATION

The submitted data is checked, and a result instance is built according to the
following rules. Only if all checks succeed will the submitted instance be declared
valid. Note that if a model item property relies on content of a non-relevant instance
node, behaviour is undefined, since non-relevant nodes are not submitted.

=head3 Comparison to the original instance, C<relevant> MIP check

The element tree must be equal to the original instance. If there are more nodes than
in the original, validation fails. If nodes are missing, they are copied from the original
instance to the result instance. For these added nodes, the C<relevant> model item property
must evaluate to C<false>. If any added nodes are C<relevant>, validation fails. If any
non-added nodes are non-C<relevant>, validation fails.

Only elements and attributes are checked (actually, their localName and namespaceURI).
Text content is checked later, and all other nodes are ignored.

C<xforms:insert> and C<xforms:delete> are I<not> processed, which means that instances
that contain additional or less elements due to these actions are regarded as invalid,
even though it may be valid to create such instances.

=head3 C<readonly> nodes, unreferenced nodes

If a node is read-only in both, the original and the submitted instance, it will be reset
to the original value. Validation continues, as the node might have been non-readonly at
some time during user interaction. Otherwise, modification is allowed freely. Instance
nodes not referenced by any form control or C<setvalue> action are treated as readonly.

This step may alter whitespace-only text nodes in some rare cases, since some guessing
is involved when non-relevant nodes are present.

Note that readonly checks may not work correctly if binding expressions reference text
nodes directly (instead of their parent elements).

=head3 C<required>, C<constraint>, C<calculate> and C<type> model item properties

Only C<relevant> nodes are checked in this step. Validation fails:

=over 4

=item * if the string length of any C<required> node's text content is zero

=item * if any node's C<constraint> model item property evaluates to C<false()>

=item * if any node's C<calculate> model item property evaluates to a value different
than that node's text content

=item * if any node's text content isn't valid according to the C<type> model item property

=back 4

For C<type>, only of the built-in data types as specified in section 5 of the XForms
specification are supported. Even this is incomplete, see L<XML::Schema::Type::Builtin>.
C<xsi:type> attributes are not checked.

=head3 XML Schema validation

Schema documents may be specified by using the xsi:schemaLocation or
xsi:noNamespaceSchemaLocation attributes on the original instance(s) root node(s).
Each instance is validated using it's own XML Schema(s).

If the C<schema> option is given, the given XML Schema will be used to validate the
submitted data. No result instance is built, and none of the above checks are done.
This is useful if the above assumptions and limitations reject valid documents. This
can happen if the XForms document uses scripting, expressions that rely on non-relevant
nodes, or certain combinations of XForms Actions. On success, the submission data is
returned as a DOM tree.

=head2 METHODS AND FUNCTIONS

=head3 C<new>(I<%options>)

Creates a new validator object which contains preprocessed data structures. Thus, OO
usage will need less processing time if multiple validations against one XForms model
are done.

=head3 C<validate>(I<%options>)

Perform actual validation. Returns a hash of XML::LibXML::Document object on success
(keyed by instance id, empty key C<''> for the default instance), or a plain string
containing an error message in English language. Since validation errors are not supposed
to occur on well-behaving XForms clients, no way to localize these messages is provided.

May be called as function or object method.

=head3 C<normalize>(I<$dom>, I<$keep_extra_namespaces>)

Normalize an XML::LibXML::Document (or a hash as returned by validate) by converting it
(all of them) to its canonicalized form and stripping anything that is not an element,
attribute, text node, or namespace node. It will strip nodes in the XInclude namespace.
It will also strip namespace nodes that are unused unless you specify a true value as
second parameter. It will return a new XML::LibXML::Document (or hash, respectively).
The original DOM tree will be left unmodified.

The result should not contain any security-relevant or unexpected content anymore so that
it is safe for further processing.

May be called as function or object method, and as a convenience, it will pass through
strings unmodified.

=head2 OPTIONS

Behavior of the validator is controlled via named options.

For OO usage, the constructor takes the C<xforms>, C<model> and C<base> options. These
are ignored on the validate method call.

=head3 C<xforms>

An XML document that contains at least one C<xforms:model> element. The value is
interpreted like this:

=over 4

=item * A plain scalar is taken as file name to parse as XML.

=item * A scalarref is taken as reference to an XML string.

=item * A GLOB or IO::Handle is taken as file handle to parse as XML.
 
=item * An XML::LibXML::Document object is used as-is.

=back 4

=head3 C<input>

The submitted instance. Input type is autodetected using these rules:

=over 4

=item * A plain scalar is taken as file name to parse as XML.

=item * A scalarref is taken as reference to an XML string.

=item * A GLOB or IO::Handle is taken as file handle to parse as XML.
 
=item * An XML::LibXML::Document object is used as-is.

=item * A hashref is taken as a hash of parsed POST/GET parameters. Values may be
arrayrefs if a parameter was submitted multiple times.

=item * An arrayref is taken as a list of [ name => $value ] arrayref pairs, with
multiple occurences of I<name> permitted. The list may instead be flattened.

=back 4
 
The latter two data types are used for C<multipart/form-data> and
C<application/x-www-form-urlencoded> serializations. Note that rebuilding the
instance from these involves a certain amount of guessing. If any element local-name
occurs more than once in the submitted instance, correct association of submitted
values with DOM nodes may fail.

The other data types assume C<text/xml> serialization. C<multipart/related> is
currently unsupported.

=head3 C<base>

A base URL for external references. Relative URLs are resolved as per the xml:base
specification. This is only used for the C<src> attribute of C<xforms:instance>
elements. For security reasons, no external DTD subsets, external entities or XIncludes
are processed.

=head3 C<model>

The model id to use, in case there are multiple models in the XForms file. If not
specified, the first model in document order is used.

The contained instances (including those specified via the C<src> attribute) are
considered trusted. External references might be retrieved and XML Schema information
is honoured (except when noted otherwise). Never use unchecked user input as original
instance data!

=head3 C<submission>

The id of a submission element that was used to submit the input. If not given, the
first submission element is used.

=head3 C<instance>

Override for instance data. If given and defined, the value is interpreted similar
to the C<xforms> option. The default C<xforms:instance> node in the model is replaced
by the resulting XML data.

If a hashref is given, keys are instance IDs to replace, and the corresponding values
are processed as above.

=head3 C<schema>

An XML Schema document that will be used for schema validation of the submitted
instance B<instead of> the usual checks. Value is a URL or file name relative to the
current working directory.

=head2 SECURITY

Since validation is inherently about security, there are a few measures to allow this
module to be used with potentially untrusted input:

=over 4

=item * Submitted input is considered untrusted: No DTD or XInclude processing is done,
consequently no external entity references are resolved. No network access is allowed
except for parsing the XForms document.

=item * The C<readonly> check semantics make sure that nodes that carry a constant
readonly model item property are in fact unmodified, e.g. for immutable document IDs.
Note that this may interfer with script-based modification of the instance data, which
can't be detected. The XForms Action module is mostly accounted for, however.

=item * The input document is checked as described above. This means that despite
validation, there can be additional namespace declarations, processing instructions,
comments, CDATA sections instead of text nodes, unresolved entity references, internal
subsets and possibly more things you wouldn't expect. As a convenience, a C<normalize>
utility function is provided, which tries to ensure no content is present which could
compromise security.

=item * XML Schema validation can make sure that the result honours constraints not
expressed in the XForms document. The C<schema> parameter even allows to bypass the
usual checks and rely solely on this.

=item * Various information is taken from the XForms document, hence it is considered
trusted, including any referenced instance data. This is particularly important if you
incorporate submitted and validated data into your data storage: always normalize or
postprocess.

=back 4

XForms validation has some inherent limitations. It is difficult to associate original
instance nodes with their corresponding submitted instance nodes, especially for text
nodes. Furthermore, submissions do not contain non-relevant nodes, thus part of the
DOM tree is guessed. See L</VALIDATION> above for a detailed description of checks
and their individual limitations.

=head2 EXPORT

None by default.

The C<validate> and C<normalize> functions can be imported on request. Both can be
used as standalone functions or as object methods.

=head2 KNOWN BUGS / TODO

=over 4

=item * Construction of instance data in case none was specified
isn't 100% standards conformant. For some highly unlikely forms, this may lead to
rejection of valid submissions.

=item * Nesting of form controls that belong to different models is may lead to
undefined behaviour (nodes interpreted as readonly even though they aren't).

=item * C<multipart/related> is unsupported

=item * Currently, C<XML::Schema> is used for data type support, which isn't terribly
complete. When C<XML::LibXML> gets a binding for libxml's XML Schema Datatypes
implementation, it will be used instead.

=item * C<RelaxNG> validation.

=item * More XForms Action processing to allow and verify added/deleted nodesets.

=item * check if C<calculate> processing is too strict and should recalculate the whole
document instead (according to the XForms rules).

=item * C<xsi:type> and C<xsi:nil> processing

=back 4


=head1 SEE ALSO

The XForms 1.0 specification.

L<XML::LibXML> and L<http://www.libxml.org> for supported features, especially regarding
XML Schema validation (which isn't complete as of writing this documentation).

L<XML::Schema> for supported data types.

=head1 AUTHOR

Jörg Walter, E<lt>info@syntax-k.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Jörg Walter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl version 5.8.0 itself.


=cut
