package XML::LibXML::jQuery;

use 5.008001;
use strict;
use warnings;
use Exporter qw(import);
use Scalar::Util qw/ blessed /;
use XML::LibXML;
use HTML::Selector::XPath qw/selector_to_xpath/;
use Carp qw/ confess /;
use JSON qw/ decode_json /;

our $VERSION = "0.08";

our @EXPORT_OK = qw/ j fn /;
our @EXPORT = qw/ j /;

use constant {
    XML_ELEMENT_NODE            => 1,
    XML_TEXT_NODE               => 3,
    XML_COMMENT_NODE            => 8,
    XML_DOCUMENT_NODE           => 9,
    XML_DOCUMENT_FRAG_NODE      => 11,
    XML_HTML_DOCUMENT_NODE      => 13
};

our ($PARSER);

# plugin functions
my %fn;

# for data()
my $data = {};

sub fn($$) {
    my ($name, $sub) = @_;

    die sprintf("fn '$name' already defined by %s (at %s line %s)", @{$fn{$name}->{caller}})
        if exists $fn{$name};

    $fn{$name} = {
        sub => $sub,
        caller => [caller]
    };
}



#*j = \&jQuery;
sub j {
    __PACKAGE__->new(@_);
}


sub new {
    my ($class, $stuff, $before) = @_;
    my ($self, $document, $nodes);

    # instance method, reuse document
    if (ref $class) {
        $self = $class;
        $class = ref $self;
        $document = $self->{document};
    }

    if (defined $stuff) {

        $nodes = _stuff_to_nodes($stuff);

        # catch bugs :)
        # confess "undefined node" if grep { !defined } @$nodes;

        # adopt nodes to existing document
        # - if its not in the same dorcument already
        # - if its not a document node
        # - testing only first node for better performance
        if (defined $document
            && defined $nodes->[0]
            && $nodes->[0] ->nodeType != XML_DOCUMENT_NODE
            && !$nodes->[0]->ownerDocument->isSameNode($document)) {

            # my $doc_id = $existing_document->unique_key;
            foreach my $n (@$nodes) {
                $document->adoptNode($n);
            }
        }
    }

    # resolve document
    unless (defined $document) {

        $document = defined $nodes->[0] ? $nodes->[0]->ownerDocument
                                        : XML::LibXML->createDocument;
    }

    # increment document data refcount
    my $doc_id = $document->unique_key;
    $data->{$doc_id}{refcount}++;
    # printf STDERR "[%s] incremented document %d data ref count: %d\n", __PACKAGE__, $doc_id, $data->{$doc_id}{refcount};

    bless {
        document => $document,
        document_id => $doc_id,
        nodes => $nodes,
        before => $before
    }, $class;
}

# faster instantiation for new nodes of the same document
sub _new_nodes {
    my ($self, $nodes, $before, $new_document) = @_;

    my $doc_id = $new_document ? $new_document->unique_key
                               : $self->{document_id};

    $data->{$doc_id}{refcount}++;

    bless {
        document => $new_document || $self->{document},
        document_id => $doc_id,
        nodes    => $nodes,
        before   => $before
    }, ref $self;
}

sub _stuff_to_nodes {

    my $reftype = ref $_[0];
    my $nodes;

    # string
    if (not $reftype) {

        # parse as xml
        if ($_[0] =~ /^\s*<\?xml/) {

            $nodes = [ $PARSER->parse_string($_[0]) ];
        # parse as html
        } else {
            $nodes = _parse_html($_[0]);
        }
    }

    # arrayref
    elsif ($reftype eq 'ARRAY') {

        $nodes = $_[0];
    }

    # object
    elsif (blessed $_[0]) {

        if ($_[0]->isa(__PACKAGE__)) {
            $nodes = $_[0]->{nodes};
        }
        # TODO this is too restrictive.. what about text, comment, other nodes?
        elsif ($_[0]->isa('XML::LibXML::Element')) {
            $nodes = [$_[0]];
        }
        else {
            confess "Can't handle this type of object: '$reftype'";
        }
    }
    else {

        confess "Can't handle this type of data: '$reftype'";
    }

    $nodes;
}

sub _parse_html {
    my $source = $_[0];

    if (!$PARSER){
        $PARSER = XML::LibXML->new();
        $PARSER->recover(1);
        $PARSER->recover_silently(1);
        $PARSER->keep_blanks(0);
        $PARSER->expand_entities(1);
        $PARSER->no_network(1);
        # local $XML::LibXML::skipXMLDeclaration = 0;
        # local $XML::LibXML::skipDTD = 0;
    }

    my $dom  = $PARSER->parse_html_string($source);
    my @nodes;


    # full html
    if ($source =~ /<html/i) {
        @nodes = $dom->getDocumentElement;
    }
    # html fragment
    elsif ($source =~ /<(?!!).*?>/) { # < not followed by ! then stuff until >    (match a html tag)
        @nodes = map { $_->childNodes } $dom->findnodes('/html/head | /html/body');
    }
    # plain text
    else {
        $dom->removeInternalSubset;
        @nodes = $dom->exists('//p') ? $dom->findnodes('/html/body/p')->pop->childNodes : $dom->childNodes;
    }

    confess "empy nodes :[" unless @nodes;
    confess "undefined node :[" if grep { ! defined } @nodes;
    # new doc (setDocumentElement accepts only element nodes)
    if ($nodes[0]->nodeType == XML_ELEMENT_NODE) {
        my $doc = XML::LibXML->createDocument;
        if ($source =~ /^\s*<!DOCTYPE/ && (my $dtd = $nodes[0]->ownerDocument->internalSubset)) {
            $doc->createInternalSubset( $dtd->getName, $dtd->publicId, $dtd->systemId );
        }
        $doc->setDocumentElement($nodes[0]);
        $nodes[0]->addSibling($_) foreach @nodes[1..$#nodes];
    }

    \@nodes;
}


sub get {
    my ($self, $i) = @_;
    $self->{nodes}->[$i];
}

sub eq {
    my ($self, $i) = @_;
    $self->_new_nodes([ $self->{nodes}[$i] || () ], $self);
}


sub end {
    shift->{before};
}

sub document {
    my $self = shift;
    $self->_new_nodes([ $self->{document} ], $self);
}

sub tagname {
    my $self = shift;
    defined $self->{nodes}[0]
        ? $self->{nodes}[0]->localname
        : undef;
}

sub first {
    my $self = shift;
    $self->_new_nodes([ $self->{nodes}[0] || () ], $self);
}

sub last {
    my $self = shift;
    $self->_new_nodes([ $self->{nodes}[-1] || () ], $self);
}

sub serialize {
    my ($self) = @_;
    my $output = '';

    $output .= $_->serialize
        for (@{$self->{nodes}});

    $output;
}


sub as_html {
    my ($self) = @_;

    my $output = '';

    foreach (@{$self->{nodes}}) {

        # TODO benchmark as_html() using can() vs nodeType to detect document nodes
        # best method, but only document nodes can toStringHTML()
        if ($_->can('toStringHTML')) {
            # printf STDERR "%s: toStringHTML\n", ref $_;
            $output .= $_->toStringHTML;
            next;
        }


        # second best is to call toStringC14N(1), which generates valid HTML (eg. no auto closed <div/>),
        # but dies on some cases with "Failed to convert doc to string in doc->toStringC14N" error.
        # so we fallback to toString()
        # the most common case where toStringC14N fails is unbound nodes (getOwner returns a DocumentFragment)
        {
            local $@; # protect existing $@
            my $html = eval { $_->toStringC14N(1) };
            # printf STDERR "%s: %s\n", ref $_->getOwner, ($@ ? "toString: $@" : 'toStringC14N');
            $output .= $@ ? $_->toString : $html;
        }
    }

    $output;
}

sub html {
    my ($self, $stuff) = @_;

    # output
    unless ($stuff) {
        my $out = '';
        foreach my $node (map { $_->childNodes } @{$self->{nodes}}) {
            {
                local $@;
                my $html = eval { $node->toStringC14N(1) };
                $out .= $@ ? $node->toString : $html;
            }
        }
        return $out;
    }

    # replace content
    my $nodes = $self->new($stuff)->{nodes};

    foreach my $node (@{$self->{nodes}}) {
        $node->removeChildNodes;
        $node->appendChild($_->cloneNode(1)) for @$nodes;
    }

    $self;
}

sub text {
    my ($self, $stuff) = @_;

    # output
    unless (defined $stuff) {
        my $out = '';
        $out .= $_->textContent for @{$self->{nodes}};
        return $out;
    }

    # replace content
    return $self unless @{$self->{nodes}};

    my $textnode = $self->{nodes}[0]->ownerDocument->createTextNode($stuff);

    foreach my $node (@{$self->{nodes}}) {
        $node->removeChildNodes;
        $node->appendChild($textnode->cloneNode(1));
    }

    $self;
}


sub size {
    my ($self) = @_;
    scalar @{$self->{nodes}};
}

sub children {
    my ($self, $selector) = @_;

    my $xpath = selector_to_xpath($selector, root => '.')
        if $selector;

    my @new = map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () }
        map { $xpath ? $_->findnodes($xpath) : $_->childNodes }
        @{$self->{nodes}};

    $self->_new_nodes(\@new, $self);
}

sub find {
    my ($self, $selector) = @_;

    my $xpath = selector_to_xpath($selector, root => './');
    my @new = map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () }
        map { $_->findnodes($xpath) }
        @{$self->{nodes}};

    $self->_new_nodes(\@new, $self);
}

sub xfind {
    my ($self, $xpath) = @_;
    my @new = map { $_->findnodes($xpath) } @{$self->{nodes}};
    $self->_new_nodes(\@new, $self);
}

sub filter {
    my ($self, $selector) = @_;

    my $xpath = selector_to_xpath($selector, root => '.');
    my @new = map { _node_matches($_, $xpath) ? $_ : () }
        map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () } @{$self->{nodes}};

    $self->_new_nodes(\@new, $self);
}

sub xfilter {
    my ($self, $xpath) = @_;

    my @new = map { _node_matches($_, $xpath) ? $_ : () }
        map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () } @{$self->{nodes}};

    $self->_new_nodes(\@new, $self);
}

sub parent {
    my ($self, $selector) = @_;

    my $xpath = selector_to_xpath($selector, root => '.')
        if $selector;

    my @new = map {

        !$xpath ? $_
                : _node_matches($_, $xpath) ? $_ : ()
    }
    grep { defined }
    map { $_->parentNode } @{$self->{nodes}};

    $self->_new_nodes(\@new, $self);
}

sub clone {
    my ($self) = @_;
    return $self unless @{$self->{nodes}};

    my @clones = map { $_->cloneNode(1) } @{$self->{nodes}};
    # when cloning a document node, pass it as the new jQuery document (3rd arg)
    $self->_new_nodes(\@clones, $self, $clones[0]->nodeType == XML_DOCUMENT_NODE ? $clones[0] : () );
}

sub _node_matches {
    my ($node, $xpath) = @_;
    # warn sprintf "# matching node: %s (%s)\n", ref $node, $node;
    foreach ($node->parentNode->findnodes($xpath)) {
        # warn sprintf "#     - against node: %s (%s)\n", ref $_, $_;
        return 1 if $_->isSameNode($node);
    }
    0;
}

# TODO add() can ruin our refcount for data()
sub add {
    my ($self, $stuff, $context) = @_;
    $context ||= $self->document;

    # find(): add(selector[, context])
    # new: add(html), add(elements), add(jQuery)
    my $new_selection = !ref $stuff && $stuff !~ /<(?!!).*?>/
                            ? $context->find($stuff)
                            : $self->new($stuff);

    # prepend our nodes
    unshift @{$new_selection->{nodes}}, @{ $self->{nodes} };

    $new_selection;
}

sub each {
    my ($self, $cb) = @_;

    for (my $i = 0; $i < @{$self->{nodes}}; $i++) {

        local $_ = $self->{nodes}[$i];
        my @rv = $cb->($i, $_);
        last if @rv == 1 && !defined $rv[0];
    }

    $self;
}


sub append {
    my $self = shift;
    my $nodes = _stuff_to_nodes($_[0]);
    _append_to($nodes, $self->{nodes});
    $self;
}

sub append_to {
    my $self = shift;
    my $nodes = _stuff_to_nodes($_[0]);
    _append_to($self->{nodes}, $nodes);
    $self;
}

sub _append_to {
    my ($content, $target) = @_;

    for (my $i = 0; $i < @$target; $i++) {

        my $is_last = $i == $#$target;
        my $node = $target->[$i];


        # thats because appendChild() is not supported on a Document node (as of XML::LibXML 2.0017)
        if ($node->isa('XML::LibXML::Document')) {

            foreach (@$content) {
                confess "# Document->setDocumentElement: doc\n"
                    if ref $_ eq 'XML::LibXML::Document';

                $node->hasChildNodes ? $node->lastChild->addSibling($is_last ? $_ : $_->cloneNode(1))
                                     : $node->setDocumentElement($is_last ? $_ : $_->cloneNode(1));
            }
        }
        else {
            $node->appendChild($is_last ? $_ : $_->cloneNode(1))
                for @$content;
        }
    }
}


sub prepend {
    my $self = shift;
    _prepend_to($self->new(@_)->{nodes}, $self->{nodes});
    $self;
}

sub prepend_to {
    my $self = shift;
    _prepend_to($self->{nodes}, (ref $self)->new(@_)->{nodes});
    $self;
}

sub _prepend_to {
    my ($content, $target) = @_;

    for (my $i = 0; $i < @$target; $i++) {

        my $is_last = $i == $#$target;
        my $node = $target->[$i];

        # thats because insertBefore() is not supported on a Document node (as of XML::LibXML 2.0017)
        if ($node->isa('XML::LibXML::Document')) {

            foreach (@$content) {
                $node->hasChildNodes ? $node->lastChild->addSibling($is_last ? $_ : $_->cloneNode(1))
                                     : $node->setDocumentElement($is_last ? $_ : $_->cloneNode(1));
            }

            # rotate
            while (not $node->firstChild->isSameNode($content->[0])) {
                my $first_node = $node->firstChild;
                $first_node->unbindNode;
                $node->lastChild->addSibling($first_node);

            }
        }

        # insert before first child
        my $first_child = $node->firstChild;
        $node->insertBefore($is_last ? $_ : $_->cloneNode(1), $first_child || undef) for @$content;
    }
}


sub before {
    my $self = shift;
    my $content = ref $_[0] eq 'CODE'
                  ? $_[0]
                  : [map { @{ $self->new($_)->{nodes} } } @_];

    $self->_insert_before($content, $self->{nodes});
    $self;
}

sub insert_before {
    my ($self, $target) = @_;
    $target = _is_selector($target) ? $self->document->find($target)
                                    : (ref $self)->new($target);

    $self->_insert_before($self->{nodes}, $target->{nodes});
    $self;
}

sub _insert_before {
    my ($self, $content, $target) = @_;
    return if ref $content eq 'ARRAY' && @$content == 0;

    for (my $i = 0; $i < @$target; $i++) {

        my $is_last = $i == $#$target;
        my $node = $target->[ $i ];
        my $parent = $node->parentNode;
        my $items;

        if (ref $content eq 'CODE') {
            local $_ = $node;
            $items = (ref $self)->new($content->($i, $_))->{nodes};
        }
        else {
            # content is cloned except for last target
            $items = $i == $#$target ? $content : [map { $_->cloneNode(1) } @$content];
        }

        # thats because insertAfter() is not supported on a Document node (as of XML::LibXML 2.0017)
        unless ($parent->isa('XML::LibXML::Document')) {

            $parent->insertBefore($_, $node) for @$items;
            next;
        }

        # workaround for when parent is document:
        # append nodes then rotate until content is before node
        $parent->lastChild->addSibling($_) for @$items;

        my $next = $node;
        while (not $next->isSameNode($items->[0])) {
            my $node_to_move = $next;
            $next = $node_to_move->nextSibling;
            $parent->lastChild->addSibling($node_to_move);
        }
    }
}


sub after {
    my $self = shift;
    my $content = ref $_[0] eq 'CODE'
                  ? $_[0]
                  : [map { @{ $self->new($_)->{nodes} } } @_];

    $self->_insert_after($content, $self->{nodes});
    $self;
}

sub insert_after {
    my ($self, $target) = @_;
    $target = _is_selector($target) ? $self->document->find($target)
                                    : (ref $self)->new($target);

    $self->_insert_after($self->{nodes}, $target->{nodes});
    $self;
}

sub _insert_after {
    my ($self, $content, $target) = @_;
    return if ref $content eq 'ARRAY' && @$content == 0;

    for (my $i = 0; $i < @$target; $i++) {

        my $node = $target->[ $i ];
        my $parent = $node->parentNode;
        my $items;

        if (ref $content eq 'CODE') {
            local $_ = $node;
            $items = (ref $self)->new($content->($i, $_))->{nodes};
        }
        else {

            # content is cloned except for last target
            $items = $i == $#$target ? $content : [map { $_->cloneNode(1) } @$content];
        }

        # thats because insertAfter() is not supported on a Document node (as of XML::LibXML 2.0017)
        unless ($parent->isa('XML::LibXML::Document')) {

            $parent->insertAfter($_, $node) for reverse @$items;
            next;
        }

        # workaround for when parent is document:
        # append nodes then rotate next siblings until content is after node
        $parent->lastChild->addSibling($_) for @$items;
        # warn "# rotating until $items[0] is after to $node\n";
        while (not $node->nextSibling->isSameNode($items->[0])) {
            my $next = $node->nextSibling;
            # warn "#    - next: $next\n";
            # $next->unbindNode;
            $parent->lastChild->addSibling($next);
        }
    }
}


sub contents {
    my $self = shift;
    my @new = map { $_->childNodes } @{$self->{nodes}};
    $self->_new_nodes(\@new, $self);
}

{
    no warnings;
    *detach = \&remove;
}

sub remove {
    my ($self, $selector) = @_;

    if ($selector) {
        $self->find($selector)->remove;
        return $self;
    }

    foreach (@{$self->{nodes}}) {
        # TODO test when there is no parent node
        $_->parentNode->removeChild($_);
    }

    $self;
}



sub replace_with {
    my ($self, $content) = @_;
    $content = $self->new($content)->{nodes}
        unless ref $content eq 'CODE';

    my $target = $self->{nodes};
    for (my $i = 0; $i < @$target; $i++) {

        my $node = $target->[ $i ];
        my $parent = $node->parentNode;
        my $final_content = $content;

        if (ref $content eq 'CODE') {
            local $_ = $self->new($node);
            $final_content = $content->($i, $_); # TODO check this callback signature
            $final_content = $self->new($final_content)->{nodes};
        }

        # no content, just remove node
        unless (@$final_content) {
            $parent->removeChild($node);
            delete $data->{$node->ownerDocument->unique_key}->{$node->unique_key};
            return $self;
        }

        # content is cloned except for last target
        my @items = $i == $#$target ? @$final_content : map { $_->cloneNode(1) } @$final_content;

        # on doc: append then rotate
        if ($parent->nodeType == XML_DOCUMENT_NODE) {

            $parent->lastChild->addSibling($_) for @items;
            while (not $node->nextSibling->isSameNode($items[0])) {
                $parent->lastChild->addSibling($node->nextSibling);
            }

            $parent->removeChild($node);
        }
        else {
            # my $new_node = shift @items;
            # $parent->replaceChild($new_node, $node);
            foreach (reverse @items) {
                $parent->insertAfter($_, $node);
                # $new_node = $_;
            }
            $parent->removeChild($node);
        }

    }

    $self;
}

sub attr {
    my $self = shift;
    my $attr_name = shift;

    return unless defined $attr_name;

    # only element nodes
    my @nodes = @{$self->{nodes}};

    # get
    return $nodes[0] ? $nodes[0]->getAttribute(lc $attr_name) : undef
        unless @_ || ref $attr_name;

    # set
    return $self unless @nodes;

    # set multiple
    if (ref $attr_name eq 'HASH') {

        foreach (@nodes) {
            while (my ($k, $v) = CORE::each %$attr_name) {
                $_->setAttribute($k, $v);
            }
        }

        return $self;
    }

    $attr_name = lc $attr_name;

    # from callback
    if (ref $_[0] eq 'CODE') {

        for (my $i = 0; $i < @nodes; $i++) {

            local $_ = $nodes[$i];
            my $value = $_[0]->($i, $_->getAttribute($attr_name));
            $_->setAttribute($attr_name, $value)
                if defined $value;
        }
    }
    else {
        $_->setAttribute($attr_name, $_[0])
            for @nodes;
    }

    $self;
}

sub remove_attr {
    my ($self, $attr_name) = @_;
    return $self unless defined $attr_name;

    $attr_name =~ s/(?:^\s*|\s$)//g;

    foreach my $node (map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () } @{$self->{nodes}}) {
        foreach my $attr (split /\s+/, $attr_name) {
            $node->removeAttribute($attr);
        }
    }

    $self;
}


sub add_class {
    my ($self, $class) = @_;

    # only element nodes
    my @nodes = map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () } @{$self->{nodes}};

    for (my $i = 0; $i < @nodes; $i++) {

        my $node = $nodes[$i];
        my $new_classes = $class;
        my $current_class = $node->getAttribute('class') || '';

        # from callback
        if (ref $class eq 'CODE') {
            local $_ = $self->new($node);
            $new_classes = $class->($i, $current_class);
        }

        my %distinct;
        $node->setAttribute('class', join ' ', grep { !$distinct{$_}++ } split(/\s+/, "$current_class $new_classes"));
    }

    $self
}

sub remove_class {
    my ($self, $class) = @_;

    # only element nodes
    my @nodes = map { $_->nodeType == XML_ELEMENT_NODE ? $_ : () } @{$self->{nodes}};

    for (my $i = 0; $i < @nodes; $i++) {

        my $node = $nodes[$i];

        # remove all classes
        unless (defined $class) {
            $node->removeAttribute('class');
            next;
        }

        my $to_remove = $class;
        my $current_class = $node->getAttribute('class') || '';

        # from callback
        if (ref $class eq 'CODE') {
            local $_ = $self->new($node);
            $to_remove = $class->($i, $current_class);
        }

        my %to_remove = map { $_ => 1 } split /\s+/, $to_remove;
        my @new_classes = grep { !$to_remove{$_} } split /\s+/, $current_class;

        @new_classes > 0 ? $node->setAttribute('class', join ' ', @new_classes)
                         : $node->removeAttribute('class');
    }

    $self
}

sub data {

    my $self = shift;

    # class method: return whole $data (mainly for test/debug)
    return $data unless ref $self;

    # data(key, val)
    if (@_ == 2 && defined $_[1]) {

        $data->{$_->ownerDocument->unique_key}->{$_->unique_key}->{$_[0]} = $_[1]
            foreach @{$self->{nodes}};

        return $self;
    }


    if (@_ == 1) {

        # no nodes
        return unless defined $self->{nodes}->[0];

        # data(undefined)
        return $self unless defined $_[0];

        # data(obj)
        if (ref $_[0]) {

            die 'data(obj) only accepts a hashref' unless ref $_[0] eq 'HASH';

            $data->{$_->ownerDocument->unique_key}->{$_->unique_key} = $_[0]
                foreach @{$self->{nodes}};

            return $self;
        }

        # data(key)
        my $key = $_[0];
        my $node = $self->{nodes}->[0];

        $data->{$node->ownerDocument->unique_key}->{$node->unique_key} = {}
            unless $data->{$node->ownerDocument->unique_key}->{$node->unique_key};

        my $node_data = $data->{$node->ownerDocument->unique_key}->{$node->unique_key};

        # try to pull from data-* attribute
        my $data_attr = 'data-'._decamelize($key);
        $data_attr =~ tr/_/-/;

        $node_data->{$key} = _convert_data_attr_value($node->getAttribute($data_attr))
            if !exists $node_data->{$key}
                && $node->nodeType == XML_ELEMENT_NODE
                && $node->hasAttribute($data_attr);

        return $node_data->{$key};
    }

    # data()
    if (@_ == 0) {

        # return all data for first node
        my $node = $self->{nodes}[0];
        return unless $node;

        # poor man's //= {} (for perls < 5.10)
        exists $data->{$node->ownerDocument->unique_key}->{$node->unique_key}->{autovivify_hash};
        my $node_data = $data->{$node->ownerDocument->unique_key}->{$node->unique_key};

        # pull data-* attributes
        foreach my $attr (grep { $_->name =~ /^data-/ } $node->attributes) {

            my $key = substr($attr->name, 5);
            $key =~ tr/-/_/;
            $key = lcfirst _camelize($key);

            next if exists $node_data->{$key};
            $node_data->{$key} = _convert_data_attr_value($attr->value);
        }

        return $node_data;
    }

    $self;
}

sub _convert_data_attr_value {

    # number
    return $_[0] += 0
        if $_[0] =~ /^\d+$/;

    # json array or object
    return decode_json($_[0])
        if  $_[0] =~ /^(?:\{|\[)/;

    # boolean
    return JSON::true  if $_[0] eq 'true';
    return JSON::false if $_[0] eq 'false';

    # undef
    return undef if $_[0] eq 'null' || $_[0] eq 'undefined';

    # other stuff, return unmodified
    $_[0];
}



sub _decamelize {
    my $s = shift;
    $s =~ s{([^a-zA-Z]?)([A-Z]*)([A-Z])([a-z]?)}{
            my $fc = pos($s)==0;
            my ($p0,$p1,$p2,$p3) = ($1,lc$2,lc$3,$4);
            my $t = $p0 || $fc ? $p0 : '_';
            $t .= $p3 ? $p1 ? "${p1}_$p2$p3" : "$p2$p3" : "$p1$p2";
            $t;
    }ge;
    $s;
}

sub _camelize {
        my $s = shift;
        join('', map{ ucfirst $_ } split(/(?<=[A-Za-z])_(?=[A-Za-z])|\b/, $s));
}

sub _is_selector {
    defined $_[0]
    && !ref $_[0]
    && length $_[0]
    && $_[0] !~ /<(?!!).*?>/
}

# TODO rethink this autoload thing... issues:
# - global var is bad... spooky action at a distance;
# - and if thats ok, we could just add the subref to the symbol table directly

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    (my $method = $AUTOLOAD) =~ s/.*:://s;

    die sprintf "unknown method '$method'"
        unless ref $self && exists $fn{$method};

    local $_ = $self;
    $fn{$method}{sub}->(@_);
}



# decrement data ref counter, delete data when counter == 0
sub DESTROY {
    my $self = shift;

    # Don't know why, but document is undefined in some situations..
    # wiped out by XS code probably.
    return unless defined $self->{document_id};

    # decrement $data refcount
    my $doc_id = $self->{document_id};
    $data->{$doc_id}{refcount}--;
    # printf STDERR "[%s] decremented document %d data ref count: %d\n", __PACKAGE__, $doc_id, $data->{$doc_id}{refcount};

    # delete document data if refcount is 0
    delete $data->{$doc_id}
        if $data->{$doc_id}{refcount} == 0;
}


# TODO create camelized methods alias



1;
__END__

=encoding utf-8

=head1 NAME

XML::LibXML::jQuery - Fast, jQuery-like DOM manipulation over XML::LibXML

=head1 SYNOPSIS

    use XML::LibXML::jQuery;

    my $div = j(<<HTML);
        <div>
            <h1>Hello World</h1>
            <p> ... </p>
            <p> ... </p>
        </div>
    HTML

    $div->find('h1')->text; # Hello World

    $div->find('p')->size; # 2

=head1 DESCRIPTION

XML::LibXML::jQuery is a jQuery-like DOM manipulation module build on top of
L<XML::LibXML> for speed. The goal is to be as fast as possible, and as compatible
as possible with the javascript version of jQuery. Unlike similar modules,
web fetching functionality like C<->append($url)> was intentionally not implemented.

=head1 SIMILAR MODULES

Following is a list of similar CPAN modules.

=over

=item Web::Query::LibXML

L<Web::Query::LibXML> is my previous attempt to create a fast, jQuery-like module.
But since it uses L<HTML::TreeBuilder::LibXML> (for compatibility with L<Web::Query>)
for the underlying DOM system, its not as fast as if it used XML::LibXML directly.
Also, maintaining it was a bit of a pain because of the API contracts to L<Web::Query>
and L<HTML::TreeBuilder>.

=item jQuery

L<jQuery> seemed to be the perfect candidade for me to use/contribute since its
a jQuery port implemented directly over XML::LibXML, but discarded the idea after
finding some issues. It was slower than Web::Query::LibXML for some methods, it
has its own css selector engine (whose code was a bit scary, I'd rather just
use HTML::Selector::XPath), invalid html output (spits xml) and even some broken
methods. Which obviously could be fixed, but honestly I didn't find its codebase
fun to work on.

=item Web::Query

L<Web::Query> uses the pure perl DOM implementation L<HTML::TreeBuilder>, so its
slow.

=item pQuery

L<pQuery> is also built on top of L<HTML::TreeBuilder>, so..

=back

=head1 CONSTRUCTOR

=head2 new

Parses a HTML source and returns a new L<XML::LibXML::jQuery> instance.

=head1 EXPORTED FUNCTION

=head2 j

A shortcut to L<new>.

=head1 METHODS

Unless otherwise noted, all methods behave exactly like the javascript version.

=head2 add

Implemented signatures:

=over

=item add(selector)

=item add(selector, L<context|XML::LibXML::jQuery>)

=item add(html)

=item add(L<elements|XML::LibXML::Node>)

=item add(L<selection|XML::LibXML::jQuery>)

=back

Documentation and examples at L<http://api.jquery.com/add/>.

=head2 add_class

Implemented signatures:

=over

=item add_class(className)

=item add_class(function)

=back

Documentation and examples at L<http://api.jquery.com/addClass/>.

=head2 after

Implemented signatures:

=over

=item after(content[, content])

=item after(function)

=back

Documentation and examples at L<http://api.jquery.com/after/>.

=head2 append

=head2 append_to

=head2 as_html

=head2 attr

=head2 before

=head2 children

=head2 clone

=head2 contents

=head2 data

Implemented signatures:

=over

=item data(key, value)

=item data(key)

=item data(obj)

=back

Documentation and examples at L<http://api.jquery.com/data/>.

=head2 detach

=head2 document

=head2 each

=head2 eq

=head2 end

=head2 find

=head2 get

=head2 html

=head2 insert_after

Implemented signatures:

=over

=item insert_after(target)

All targets supported: selector, element, array of elements, HTML string, or jQuery object.

=back

Documentation and examples at L<http://api.jquery.com/insertAfter/>.

=head2 insert_before

=head2 filter

=head2 first

=head2 last

=head2 parent

=head2 prepend

=head2 prepend_to

=head2 remove

=head2 remove_attr

=head2 remove_class

=head2 replace_with

=head2 serialize

=head2 size

=head2 tagname

=head2 text

=head2 xfind

Like L</find>, but uses a xpath expression instead of css selector.

=head2 xfilter

Like L</filter>, but uses a xpath expression instead of css selector.

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
