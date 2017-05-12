package jQuery::Functions;
use strict;
use warnings;
use subs 'this';
use HTTP::Request::Common qw(POST GET);
use LWP::UserAgent;
my $base_class = 'jQuery';
my $obj_class = 'jQuery::Obj';
sub jQuery { return jQuery::jQuery(@_) }

#mostly for internal use
sub editElement {
    my ($self,$attr,$value,$remove_old) = @_;   
    foreach my $element ($self->getNodes){
        my $cur_value;
        my $new = $value;
        if ( defined($element->GetSetAttr($attr)) ) {
            $cur_value = $element->GetSetAttr($attr);
            unless ($remove_old){
                $new = $cur_value.' '.$value;
            }
        }
        $element->GetSetAttr($attr,$new);
    }
    return $self;
}

sub GetSetAttr {
    my ($self, $key, $value) = @_;
    if (@_ == 3) {
        if (defined $value) {
            $self->setAttribute (lc $key, $value);
        } else {
            $self->removeAttribute(lc $key);
        }
    } else {
        return $self->getAttribute(lc $key);
    }
}

sub attr {    
    my ($self,$attr,$value) = @_;
    if (ref($attr) eq 'HASH'){
        while (my ($key,$val) = each(%{$attr})) {
            $self->editElement($key,$val,'remove old');
        }
    } elsif ($value){
        if (ref($value) eq 'CODE'){
            my $i = 0;
            $self->each(sub{
                my $i = shift;
                my $element = shift;
                my $val = &$value($i++,$element->GetSetAttr($attr));
                if ($val){
                    $element->GetSetAttr($attr,$val);
                }
            });
            
        } else {
            $self->editElement($attr,$value,'remove old');
        }
        return $self;
        
    } else {
        my $element = ($self->toArray)[0];
        if ($element){
            return $element->getAttribute($attr);
        }
        return '';
    }
}

sub removeAttr {
    my $self = shift;
    my $attr = shift;
    foreach my $element ($self->toArray){
        $element->removeAttribute( $attr );
    }
    return $self;
}

sub addClass {
    my ($self,$new_class) = @_;
    if (ref($new_class) eq 'CODE'){
        $self->each(sub{
            my $i = shift;
            my $node = shift;
            my $return = &$new_class($i,$node->GetSetAttr('class'));
            if ($return){
                $node->editElement('class',$return);
            }
        });
    } else {
        $self->editElement('class',$new_class);
    }
    return $self;
}

sub removeClass {    
    my ($self,$class_name) = @_;
    if (ref $class_name eq 'CODE'){
        return $self->each(sub{
            my $i = shift;
            my $ele = shift;
            $ele->removeClass(  &$class_name($i,$ele->GetSetAttr('class'))    );
        });
    }
    
    if (!$class_name){
        $self->removeAttr('class');
    } else {
        my @classes = split (/ /, $class_name);
        foreach my $element ($self->toArray){
            my $cur_value;
            my @new;
            $cur_value = $element->GetSetAttr('class');
            foreach my $cur_class (split(/ /, $cur_value)){
                unless (grep{$cur_class eq $_}@classes){
                    push @new,$cur_class;
                } 
            }
            my $new = join(' ',@new);
            $element->GetSetAttr('class',$new);
        }
    }
    return $self;   
}

sub toggleClass {    
    my ($this,$value,$stateVal) = @_;
    if ( ref $value eq 'CODE' ) {
	return $this->each( sub {
            my $i = shift;
            my $ele = shift;
	    this->toggleClass( &$value($i, $ele->GetSetAttr('class'), $stateVal), $stateVal );
	});
    }
    
    my $type = defined $value ? 1 : 0;
    my $isBool = defined $stateVal ? 1 : 0;
    return $this->each( sub {
        my $i = shift;
        my $ele = shift;
        if ( $type ) {
            #toggle individual class names
	    my $className;
	    my $state = $stateVal;
	    my @classNames = split (/ /, $value);
            foreach my $className ( @classNames ) {
		#check each className given, space seperated list
		$state = $isBool ? $state : !$ele->hasClass($className);
		$state ? $ele->addClass( $className ) : $ele->removeClass( $className );
	    }
	} elsif ( !$type   ) {
            this->removeClass();
        }
    });
}

sub hasClass {    
    my ($self,$has_class) = @_;
    foreach my $element ($self->toArray){
        if ( defined $element && defined($element->GetSetAttr('class')) ) {
            my $cur_value = $element->GetSetAttr('class');
            foreach my $cur_class (split(/ /, $cur_value)){               
                if ($cur_class eq $has_class){
                    return 1;
                }        
            }      
        }
    }
    return 0;
}

sub toString {
    return shift->[0];
}

sub val(){
    my ($self,$content) = @_;
    if (@_ == 2){
        my $i;
        foreach my $element ($self->getNodes){
            $content = &$content($element,$i++,$element->val()) if ref($content) eq 'CODE';
            if ($element->nodeName eq "input" || $element->nodeName eq "select"){
                if ($element->exists('self::*[@type="text"]')){
                    $content = join(', ',@{$content}) if ref($content) eq 'ARRAY';
                    $element->GetSetAttr('value',$content);
                } else {                    
                    if (!ref $content){$content = [$content]}
                    if (ref($content) eq 'ARRAY'){
                        if ($element->nodeName eq "select"){
                            #get options
                            my @options = $element->findnodes('self::*/option');
                            foreach my $option (@options){
                                if( ($option->hasAttribute('value') && grep{$option->GetSetAttr('value') eq $_}@{$content}) || (!$option->hasAttribute('value') && grep{ $option->findnodes('./text()')->string_value() eq $_}@{$content}) ){
                                    $option->GetSetAttr('selected','selected');
                                } else {
                                    $option->removeAttr('selected');
                                }
                            }
                        } elsif (grep{$element->exists('self::*[@value="'.$_.'"]')}@{$content}){
                            $element->GetSetAttr('checked','checked');
                        }
                    }
                }
	    ##if textarea
            } elsif ($element->nodeName eq "textarea"){
                $element->text($content);
            }
        }
        return $self;
    } else {
        my $node = ($self->toArray)[0];
        if (defined $node){
            if ($node->nodeName eq "input"){
                return $node->GetSetAttr('value');
            } elsif ($node->nodeName eq "textarea"){
                return $node->text();
            } elsif ($node->nodeName eq "select"){
                ##this is a multi select element, return array of values
                if ($node->hasAttribute('multiple')){
                    my @values;
                    my @nodes = $node->findnodes('./option[@selected]');
                    foreach my $nd (@nodes){
                        push (@values,$nd->text());
                    }
                    return bless(\@values,$obj_class);
                } else {
                    return $node->findnodes('./option[@selected]')->string_value() || $node->findnodes('./option[1]')->string_value();
                }
            }
        }
    }
}

sub id {
    return shift->GetSetAttr('id');
}

{
    no warnings 'redefine';
    #XML::LibXML::Element::find();
    *XML::LibXML::Element::find = \&find;
    sub find {
        my $self = shift;
        my $query = shift;
        my $custompath = shift;
        my @elements = ();
        my @nodes = $self->this;
        if (ref $query){
            return jQuery( $query )->filter(sub {
                
                my $index = shift;
                my $this = shift;
                
                for ( my $i = 0; $i <= $#nodes; $i++ ) {
                    if ( $self->contains( $nodes[$i], $this ) ) {
			return 1;
		    }
		}
	    });
        } else {
            foreach my $node (@nodes){                
                push (@elements, $self->_find($query,$node))
            }
        }
        return $self->pushStack(@elements);
    };
}

sub css {
    my ($self,$options,$val) = @_;
    my $style;
    if (ref($options) eq 'HASH'){
        while ( my ($key, $value) = each(%{$options}) ) {
            $style .= $key.":".$value.";";
        }
    } elsif ($val){
        $style = $options.":".$val.";";
    }
    $self->editElement('style',$style) if $style;
    return $self;
}

my $THIS;
sub each {
    my ($self,$sub,$type) = @_;
    my @elements;
    my $i = 0;
    my $return = 0;
    my @nodes = $self->getNodes();
    #loop and bless each element
    foreach my $element (@nodes) {
        $THIS = $element;
        $return = &$sub($i++,$element);
        if ($type && $type eq "map"){
            push (@elements,$return) if $return;
        } else {
            push (@elements,$element) if !$type || ($type && $return);
        }
    }
    
    return $self if $type && $type eq 'nopush';
    return wantarray 
        ? @elements
        : $self->pushStack(@elements);
}

sub this {
    shift;
    my $self = shift;
    return $self->toArray if ref $self;
    return $THIS;
}

my $data = {};
sub data {
    my ($self,$name,$value,$extra) = @_;
    if (ref $name){
	$self = $name;
	$name = $value;
	$value = $extra;
    }
    
    if (!$value){
	my $e = $self->get(0);
	return $data->{$$e}->{$name} || '';
    }
    
    $self->each(sub{
	my $i = shift;
	my $e = shift;
	$data->{$$e}->{$name} = $value;
    });
    
    return $self;
}

#TODO -- need some more tests
sub filter {
    my ($self,$selector,$filter_type) = @_;
    my @elements;
    my $i = 0;
    ##how I hack filter
    ##get new elements list of tree with the new selector
    ##then return duplicates
    my @new_nodes;
    my @old_nodes = $self->toArray;
    if (ref $selector eq 'CODE'){
        my @nodes = $self->each(sub {
            my $i = shift;
            my $this = shift;
            &$selector($i++,$this);
        },'filter');
        @new_nodes = @nodes;
    } else {
        @new_nodes = jQuery($selector,$self->document)->toArray;
    }
    
    if ($filter_type && $filter_type eq 'reverse'){
        foreach my $od (@old_nodes){
            if ( !grep{ $$_ == $$od }@new_nodes ){
                push (@elements,$od);
            }
        }
    } else {
        my %dup = ();
        @elements = (@new_nodes,@old_nodes);
        @elements = grep {$dup{$$_}++} @elements;
    }
    
    return wantarray 
        ? @elements
        : $self->pushStack(@elements);
}

sub matchesSelector {
    my ($self,$element,$selector) = @_;
    my @nodeList = $element->parentNode->querySelectorAll($selector);
    foreach my $node ( @nodeList ) {
        return 1 if $$node == $$element; 
    }
    return 0;
}

sub querySelectorAll {
    my ($self,$selector) = @_;
    my @nodeList = $self->_find($selector,$self);
    return @nodeList;
}

sub map {    
    my ($self, $elems, $callback, $arg) = @_;
    if (ref($elems) eq 'CODE'){
        $arg = $callback;
        $callback = $elems;
        $elems = $self->toArray;
    }
    
    my @ret;
    my @flat;
    my $value;
    my $i = 0;
    $self->each(sub{
        my $i = shift;
        $value = &$callback( $i, this, $arg );
	if ( $value ) {
            push(@ret,$value);
	}
    });
    
    #flatten nested arrays
    foreach ( @ret ) {
        if (ref $_ eq 'ARRAY'){
            map { push @flat, $_ } @{$_};
        } else {
            push @flat,$_;
        }
    }
    return $self->pushStack(@flat);
}

sub html {    
    my ($self,$content) = @_;
    if (ref $content eq 'CODE'){
        $self->each( sub {
            my $i = shift;
            my $ele = shift;
            $ele->html( &$content($i, $ele->html() ) );
	});
    } elsif (defined $content){
        my $i;
        my $nd;
        foreach my $element ($self->toArray) {
            $element->childNodes->remove();
            $element->append($content);
        }
    } else {
        my $nodeToGet = ($self->toArray)[0];
        if (defined $nodeToGet){
            my @childnodes = $nodeToGet->childNodes();
            my $html;
            foreach my $childnode (@childnodes){
                $html .= $childnode->serialize();
            }
            return $html;
            #return $self->decode_html($html);
        } else {
            return '';
        }
    }
    return $self;
}

sub text {
    my ($self,$text) = @_;
    if ( ref $text eq 'CODE' ) {
	return $self->each( sub {
            my $i = shift;
            my $ele = shift;
	    $ele->text( &$text($i, $ele->text() ) );
	});
    }
    if (defined $text){
        foreach my $element ($self->toArray) {
            $element->empty()->append( ($element && $element->ownerDocument || jQuery->document)->createTextNode( $text ) );
        }
    } else {
        foreach my $element ($self->toArray) {
            #$text .= bless($element, 'XML::LibXML::Text')->getData();
            $text .= $element->textContent();
        }
        return $text || '';
    }
    return $self;
}

sub empty {
    my $self = shift;
    foreach my $ele ($self->toArray){
        $ele->childNodes->remove();
    }
    return $self;
}

sub append { return shift->_pend(@_,'append'); }
sub prepend { return shift->_pend(@_,'prepend'); }
sub _pend {
    my ($self,$content,$content2,$method) = @_;
    if (!$method){
        $method = $content2;
        $content2 = undef;
    }
    if ( ref ($content) eq 'CODE' ){
        return $self->each(sub {
            my $i = shift;
            my $ele = shift;
            $self->$method( &$content( $i,$ele->html() ) );
        }); 
    }
    my @elements = $self->toArray;
    if ($content){
        ###get nodes to pend
        my $nodes = jQuery($content);
        foreach my $element (@elements) {       
            #get element html content
            my $html = $element->html();
            my @clone = $nodes->clone();
            @clone = reverse @clone if $method eq 'prepend';
            foreach my $nd (@clone){
                $element->appendChild($nd) if $method eq 'append';
                $element->insertBefore($nd,$element->firstChild()) if $method eq 'prepend';
            }
        }
        $nodes->remove();
    } if ($content2){
        return $self->$method($content2);
    }
    return $self;
}

sub appendTo { return $_[0]->_pendTo($_[1],'appendTo'); }
sub prependTo { return $_[0]->_pendTo($_[1],'prependTo'); }
sub _pendTo {
    my ($self,$content,$method) = @_;
    my @elements = $self->toArray;
    my @target;
    my @nodes = jQuery($content)->toArray;
    my @new;
    foreach my $node (@nodes){
        @elements = reverse(@elements) if $method eq 'prependTo';
        foreach my $ele (@elements){
            my $copy = $ele->cloneNode(1);
            push @new,$copy;
            $node->appendChild($copy) if $method eq 'appendTo';
            $node->insertBefore($copy,$node->firstChild()) if $method eq 'prependTo';
        }
    }
    ##remove original
    foreach my $ele2 (@elements){
        $ele2->unbindNode();
    }
    return $self->pushStack(@new);
}

sub add {
    my ( $self, $selector, $context ) = @_;
    my @set = jQuery($selector,$context)->toArray;
    my @all = jQuery::merge( [$self->toArray], [@set] );
    return $self->pushStack( @all );
}

sub add2 {
    my ( $self, $selector, $context ) = @_;
    my @set = !ref $selector ?
	jQuery( $selector, $context )->toArray :
	jQuery::makeArray( $selector && $selector->nodeType ? [ $selector ] : $selector )->toArray;        
        my @all = jQuery::merge( [$self->this], [@set] );
    
    return $self->pushStack( jQuery::isDisconnected( $set[0] ) || jQuery::isDisconnected( $all[0] ) ?
	@all :
	jQuery::unique( @all ) );
}

sub andSelf {
    return $_[0]->add( $_[0]->prevObject );
}

sub prevObject {
    return $_[0]->{prevObject};
}

sub next { return $_[0]->_next($_[1],'next'); }
sub nextAll { return $_[0]->_next($_[1],'nextAll'); }
sub nextUntil { return shift->_next(@_,'nextUntil'); }

sub prev { return $_[0]->_next($_[1],'prev'); }
sub prevAll { return $_[0]->_next($_[1],'prevAll'); }
sub prevUntil { return shift->_next(@_,'prevUntil'); }

sub parent { return $_[0]->_next($_[1],'parent'); }
sub parents { return $_[0]->_next($_[1],'parents'); }
sub parentsUntil { return shift->_next(@_,'parentsUntil'); }

sub siblings { return $_[0]->_next($_[1],'siblings'); }

sub _next {
    my $self = shift;
    my ($selector,$filter,$type);
    if (@_ == 3){
        $selector = shift;
        $filter = shift;
        $type = shift;
    } else {
        $selector = shift;
        $type = shift;
    }
    
    my @new_elements;
    my @nodes = $self->toArray;
    my @elements;
    my @self;
    my $sibling = {
        next=>'following-sibling::*[1]',
        nextAll=>'following-sibling::*',
        nextUntil=>'self::*|following-sibling::*',
        prev => 'preceding-sibling::*[1]',
        prevAll=>'preceding-sibling::*',
        prevUntil=>'self::*|preceding-sibling::*',
        parent=>'parent::*',
        parents=>'ancestor::*',
        parentsUntil=>'ancestor-or-self::*',
        siblings=>'preceding-sibling::*|following-sibling::*'
    };
    
    my @qr;
    my @self_qr;
    foreach my $node (@nodes){
        my $path = $node->nodePath;
        foreach my $p (split(/\|/,$sibling->{$type})){
            push(@qr,$path."/".$p);
        }
        push(@self_qr,$path.'/self::*');
    }
    
    my $query = join(' | ',@qr);
    my $self_query = join(' | ',@self_qr);
    @elements = $self->document->findnodes($query);
    @self = $self->document->findnodes($self_query);
    
    ##from w3 - http://www.w3.org/TR/xpath/#predicates
    ##the ancestor, ancestor-or-self, preceding, and preceding-sibling axes are reverse axes; 
    ##but I don't know why this is giving in a forward order
    ##let's reverse them with perl
    if ($type =~ /^(prevUntil|parentsUntil|parents|prevAll|prev)$/){
        @elements = reverse @elements;
    }
    
    if ($selector){
        if ($type =~ /Until/){
            my @filter = jQuery($selector,$self->document)->toArray;
            ##get until element
            my $do = 0;
            foreach my $ele (@elements){
                if (!$do && grep{ $$_ == $$ele }@self) {
                    $do = 1;
                    next;
                } if (grep{ $$_ == $$ele }@filter ){
                    $do = 0;
                }
                push (@new_elements,$ele) if $do == 1;
            }
            if ($type eq 'prevUntil' || $type eq 'parentsUntil'){ @elements = reverse @new_elements; }
            else{ @elements = @new_elements; }
            return $self->pushStack(@elements)->filter($filter) if $filter;
        } else {
            return $self->pushStack(@elements)->filter($selector);
        }
    }
    return $self->pushStack(@elements);
}

sub children {
    my $self = shift;
    my $selector = shift || '*';
    return $self->find($selector);
}

sub closest {
    my $self = shift;
    my $selector = shift;
    my $context = shift || $self->document;
    my @close_parent = ();
    my $parents = jQuery($selector,$context)->toArray;
    my @nodes = $self->toArray;
    foreach my $node (@nodes){
        ##get self and parents;
        my @parents = $node->findnodes('ancestor-or-self::*');
        foreach my $parent (reverse @{$parents}){
            if (grep{$$parent eq $$_}@parents){
                push(@close_parent,$parent);
                last;
            }
        }
    }
    return $self->pushStack(@close_parent);
}

sub contents {
    my $self  = shift;
    my $elem = shift;
    my @arr;
    $self->each(sub {
        push @arr, jQuery::makeArray( this->childNodes );
    });
    return $self->pushStack(@arr);
}

sub end {
    my $self = shift;
    return $self->pushStack( $self->prevObject() );
}

sub eq {
    my $self = shift;
    my $index = shift;
    my @ele = $self->toArray;
    my @node = ($ele[$index]);
    return $self->pushStack(@node);
}

sub first {
    return $_[0]->eq('0');
}

sub last {
    my $self = shift;
    my @ele = $self->getNodes;
    my @node = pop @ele;
    return $self->pushStack(@node);
}

sub has {
    my @elements;
    my ($self,$selector) = @_;
    my @nodes;
    my $nodes = jQuery($selector);
    return $self->filter(sub{
        my $this = shift;
        my $index = shift;
        foreach my $nd (@{$nodes}){
            if ($self->contains($this,$nd)){
                return 1;
            }
        }
    });
    return $self->pushStack(@nodes);
}

sub contains {
    my $self = shift;
    my $container = shift;
    my $contained = shift;
    #not sure why this didnt work
    #return $container->exists( $contained->nodePath );
    my @childs = $container->findnodes('descendant::*');
    foreach my $child (@childs){
        return 1 if $$contained == $$child;
    }
    return 0;
}

sub is {
    my $self = shift;
    my $selector = shift;
    return $selector && $self->filter($selector)->length > 0;
}

sub not  {
    my $self = shift;
    my $content = shift;
    return $self->filter($content,'reverse');
}

sub slice  {
    my ($self,$start,$end) = @_;
    my @nodes = $self->getNodes();
    my @elements;
    if ($end){
        $end = $end-$start;
        @elements = splice(@nodes,$start,$end); 
    }
    else{ @elements = splice(@nodes,$start); }
    return $self->pushStack(@elements);
}

######DOM Insertion, Around........ warp(), unrap(), wrapall(), wrapinner()
##couldn't figure out how to do this my self so I copied it from jquery.js :P
sub replaceWith {
    my $self = shift;
    my $selector = shift;
    my $value = $selector;
    my $nodes = jQuery($selector);
    if ( ref $selector eq 'CODE' ) {
	return $self->each( sub {
            my $i = shift;
            my $this = shift;
	    my $self2 = $self->jQuery($this);
            my $old = $self2->html();
            $self2->replaceWith( &$selector( $i, $this, $old ) );
	});
    }
    
    $value = $nodes->detach();
    $self->each( sub {
        shift;
        my $this = shift;
	my $next = $this->nextSibling;
	my $parent = $this->parentNode;
        $this->remove();
        if ( $next ) {
	    $next->before($value);
	} else {
	    $parent->append($value);
	}
    },'nopush');
}

sub wrap {
    my $self = shift;
    my $selector = shift;
    return $self->each( sub {
        shift;
        my $this = shift;
	$this->wrapAll( $selector );
    });
    #return $self->pushStack(@m);
}

sub unwrap {
    my $self = shift;
    my $t = $self;
    return $self->parent->each( sub {
        shift;
        my $this = shift;
	if ( $this->nodeName ne 'body') {
            my $childs = $this->childNodes;
	    $self->jQuery($this)->replaceWith( $childs );
	}
    },'nopush')->end();
}

sub wrapInner {
    my ( $this,$html ) = @_;
    if ( ref $html eq 'CODE' ) {
	return $this->each(sub{
            my $i = shift;
            my $this = shift;
            jQuery($this)->wrapInner( &$html($i,$this) );
        });
    }
    
    return $this->each( sub {
	my $self = jQuery( $this );
	my $contents = $self->contents();
        
	if ( jQuery::_length($contents) ) {
            $contents->wrapAll( $html );
        } else {
            $self->append( html );
	}
    });
}

#I think mine is better than the real jQuery one :P
sub wrapAll {
    my $self = shift;
    my $content = shift;
    ##create new node
    my $ele;
    my $return;
    my $to_append;
    my $i = 0;
    my $parent_node;
    my @nodes = $self->getNodes;
    my $append = jQuery($content);
    if (!$append){
        return $self;
    } if (ref $content eq 'CODE' ) {
	return $self->each( sub {
            my $i = shift;
            my $this = shift;
	    $this->wrapAll( &$content($i,$this) );
	});
    }
    
    my @clone = $append->clone('1');
    $parent_node = $clone[0];
    $to_append = $parent_node->findnodes('descendant-or-self::*[last()]')->[0];
    if (!$to_append){ return $self; }
    my @new_nodes;
    foreach my $node (@nodes){
        my $old_node = $node->cloneNode('1');
        push(@new_nodes,$old_node);
        $to_append->appendChild($old_node);
        $node->unbindNode() if $i > 0;
        $i++;
    }
    
    return $self if !@nodes;
    $nodes[0]->replaceNode($parent_node);
    return $self->pushStack(@new_nodes);
}

sub after {return $_[0]->_beforeAfter($_[1],'after');}
sub before {return $_[0]->_beforeAfter($_[1],'before');}
sub insertBefore {return $_[0]->_beforeAfter($_[1],'insertBefore');}
sub insertAfter {return $_[0]->_beforeAfter($_[1],'insertAfter');}

sub _beforeAfter {
    my ($this,$html,$insert_type) = @_;
    $insert_type ||= 'after';
    return $this if !$html;
    if ( ref $html eq 'CODE' ) {
	return $insert_type eq 'insertBefore' || $insert_type eq 'insertAfter' ?
        $this :
        $this->each(sub{
            my $i = shift;
            my $this = shift;
            my $t = &$html($i,$this);
            return if !$t;
            jQuery($this)->$insert_type( $t );
        });
    }   
    my $self;
    my @m;
    my $action = {
        after => 'insertAfter',
        before => 'insertBefore',
        insertBefore => sub {
            $self = $this;
            $this = jQuery( $html );
            return 'insertBefore';
        },
        insertAfter => sub {
            $self = $this;
            $this = jQuery( $html );
            return 'insertAfter';
        },
    };
    
    my $insert = $action->{$insert_type};
    if (ref $insert eq 'CODE'){
        $insert = $insert->();
    } else {
        $self = jQuery( $html );
    }
    
    foreach my $node (@{$this->toArray}){
        my @nd = $self->clone('1');
        @nd = reverse @nd if $insert_type eq 'after' || $insert_type eq 'insertAfter';
        push @m,@nd;
        foreach my $nd (@nd){
            $node->parentNode->$insert($nd,$node);
        }
    };
    #remove previous cloned object
    $self->remove();
    return $this->pushStack(@m);
}

sub getNode {
    my ($this,$num) = @_;
    return $this->toArray->[$num];
}

sub clone {
    my ($self,) = @_;
    my @cloned;
    my @nodes = $self->getNodes;
    return bless([], $base_class) if !@nodes;
    foreach my $node (@nodes){
        my $clone = $node->cloneNode(1);
        push(@cloned, $clone);
    }
    
    return wantarray ? @cloned
    : $self->pushStack(@cloned);
}

###load, post, get functions
### FIXME - should rewrite this!!!
sub get {
    my ( $self, $url, $data, $callback, $type ) = @_;
    ##get node, not Ajax function
    if (defined $url && $url =~ /\d+/){
        return $self->getNode($url);
    } elsif (!$url){
        return $self;
    }
    
    #shift arguments if data argument was omited
    if ( ref( $data ) eq 'CODE' ) {
	$type = $type || $callback;
	$callback = $data;
	$data = undef;
    }
    
    return $self->ajax({
	type => "GET",
	url => $url,
	data => $data,
	success => $callback,
	dataType => $type
    });
}

sub post {
    my ( $self, $url, $data, $callback, $type ) = @_;
    #shift arguments if data argument was omited
    if ( ref( $data ) eq 'CODE' ) {
	$type = $type || $callback;
	$callback = $data;
	$data = undef;
    }
    
    return $self->ajax({
	type => "POST",
	url => $url,
	data => $data,
	success => $callback,
	dataType => $type
    });
}

##TODO - tests
sub ajax {
    my ( $self, $options ) = @_;
    my $type = uc($options->{type}) || 'GET';
    my $beforeSend = $options->{beforeSend} || undef;
    my $success = $options->{success} || undef;
    my $context = $options->{context} || $self;
    my $timeout = $options->{timeout} || '300';
    my $agent = $options->{agent} || 'Perl-jQuery';
    my $data = $options->{data} || undef;
    my $contentType = $options->{contentType} || 'application/x-www-form-urlencoded';
    my $cache = $options->{cache} || undef;
    
    my $ua = new LWP::UserAgent(timeout => $timeout);
    $ua->agent($agent);
    my $req;
    if (uc $type eq 'POST'){
        $req = HTTP::Request->new( POST, $options->{url});
        $req = HTTP::Request::Common::POST($options->{url},Content=>$data);
    } else {
        $req = HTTP::Request->new();
        $req->uri( $options->{url} );
        if ($data){
            my $query = $req->uri->query;
            $req->uri->query_form( $data );
        }
    }
    
    $req->method($type);
    $req->content_type($contentType);
    
    ##excute beforeSend function
    if ($beforeSend){
        &$beforeSend($req);
    }
    
    ##send request
    my $response = $ua->request($req);
    my $content = $response->content;
    ###excute success function
    if ($success){
        #my @arg = ($content);
        #push (@arg,$context) if $options->{context};
        &$success($content);
    }
    #return $self->jQuery($content);
    return $content;
}

sub length {
    return scalar $_[0]->getNodes;
}

sub detach {
    my $self = shift;
    my $selector = shift;
    return $self->remove($selector,'true');
}

sub remove {
    my $self = shift;
    my $selector = shift;
    my $keepdata = shift;
    my @elements;
    my $elements;
    if ($selector){
        @elements = $self->filter($selector);
    } else {
        $elements = jQuery($self)->toArray;
    }
    
    foreach my $element (@{$elements}){
        $element->unbindNode();
    }
    
    return $self->pushStack($elements) if $keepdata;
    return $self->pushStack([]);
}

sub join {
    my ($self,$char) = @_;
    return join($char || '',$self->getNodes);
}

1;

__END__

