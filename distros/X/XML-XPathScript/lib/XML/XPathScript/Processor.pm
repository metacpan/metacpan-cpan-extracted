package XML::XPathScript::Processor;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: XML::XPathScript transformation engine
$XML::XPathScript::Processor::VERSION = '2.00';
use strict;
use warnings;
use Carp;

use base qw/ Exporter /;

use XML::XPathScript::Template;
use Readonly;

our @EXPORT = qw/ 
        $DO_SELF_AS_CHILD 
        $DO_SELF_AND_KIDS
        $DO_SELF_ONLY
        $DO_NOT_PROCESS
		DO_SELF_AND_KIDS
		DO_SELF_ONLY
		DO_NOT_PROCESS
		DO_TEXT_AS_CHILD  
/;

our @EXPORT_OK = qw(
        $DO_SELF_AS_CHILD 
        $DO_SELF_AND_KIDS
        $DO_SELF_ONLY
        $DO_NOT_PROCESS
		DO_SELF_AND_KIDS
		DO_SELF_ONLY
		DO_NOT_PROCESS
		DO_TEXT_AS_CHILD  
        processor
        findnodes
        findvalue
        findvalues
        findnodes_as_string
		xpath_to_string
        apply_templates
        matches
        set_namespace
		is_element_node
		is_text_node
        is_comment_node
		is_pi_node
		is_nodelist
		is_utf8_tainted
		get_xpath_of_node
        set_dom
        get_dom
        get_parser
        enable_binmode
        set_binmode
        get_binmode
        set_template
        get_template
        set_interpolation
        get_interpolation
        set_interpolation_regex
        get_interpolation_regex
        );

use constant DO_TEXT_AS_CHILD =>  2;
use constant DO_SELF_AND_KIDS =>  1;
use constant DO_SELF_ONLY     => -1;
use constant DO_NOT_PROCESS   =>  0;

our( $DO_SELF_AS_CHILD, $DO_SELF_AND_KIDS,
     $DO_SELF_ONLY,     $DO_NOT_PROCESS    );
Readonly::Scalar $DO_SELF_AS_CHILD =>  2;
Readonly::Scalar $DO_SELF_AND_KIDS =>  1;
Readonly::Scalar $DO_SELF_ONLY     => -1;
Readonly::Scalar $DO_NOT_PROCESS   =>  0;


sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
    # $XML::XPathScript::xp => {doc}
    #                          {parser}
    #                          {binmode}
    #                          {template}
    # $XML::XPathScript::current->interpolating() {is_interpolating}
    # $XML::XPathScript::current->{interpolation_regex}  {interpolation_regex}
}

#### accessors #############################################
    
sub processor {
    return $_[0];
}

sub set_dom { 
    my( $self, $dom ) = @_;
    my $class = ref( $self->{dom} = $dom )
        or croak "usage: \$processor->set_dom( \$dom )";

    if ( $class =~ /((?:XML::)(?:LibXML|XPath))/ ) {
        $self->set_parser( $1 );
    }
    elsif ( $class =~ /B::XPath/ ) {
        $self->set_parser( 'B::XPath' );
    }
    else {
        die "no parser assigned to class $class\n";
    }


    return;
}

sub set_parser {
    my ( $self, $parser ) = @_;

    $self->{parser} = $parser;
    if ( $parser eq 'XML::LibXML' ) {
        require XML::XPathScript::Processor::LibXML;
        bless $self, 'XML::XPathScript::Processor::LibXML';
    }
    elsif ( $parser eq 'XML::XPath' ) {
        require XML::XPathScript::Processor::XPath;
        bless $self, 'XML::XPathScript::Processor::XPath';
    }
    elsif ( $parser eq 'B::XPath' ) {
        require XML::XPathScript::Processor::B;
        bless $self, 'XML::XPathScript::Processor::B';
    }
    else {
        die "parser $parser not supported\n";
    }

}

sub get_dom { $_[0]->{dom} }
sub get_parser { $_[0]->{parser} }
sub enable_binmode { $_[0]->{binmode} = 1 }
sub set_binmode { $_[0]->enable_binmode; }
sub get_binmode { $_[0]->{binmode} }
sub set_template { $_[0]->{template} = $_[1] }
sub get_template { $_[0]->{template} }
sub set_interpolation { $_[0]->{is_interpolating} = $_[1] }
sub get_interpolation { $_[0]->{is_interpolating} }
sub set_interpolation_regex { $_[0]->{interpolation_regex} = $_[1] }
sub get_interpolation_regex { $_[0]->{interpolation_regex} }


# $processor->import_functional( $prefix )
# XML::XPathScript::Processor->import_functional( $prefix )

sub import_functional {
    my( $self, $prefix ) = @_;

    $self or croak "import_functional not called properly";
    
    # call as XML::XPathScript::Processor->import_functional
    $self = XML::XPathScript::Processor->new unless ref $self;

    my($caller) = caller;

    $self->_export( $caller, $_, $prefix ) for @EXPORT_OK;

    return;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _export {
    # heavily inspired by David James' Class::Exporter
    # (which is a nice way to say I stole it and
    # twisted it to my own perverted needs)
    
    no strict qw/ refs /;
    no warnings qw/ uninitialized /;

    my( $self, $caller, $export, $prefix ) = @_;

    my $type = $export =~ s/^(\W)// ? $1 : '&';
    my $export_sym = __PACKAGE__.'::'.$export;

    #if ( $export =~ /^DO_/ ) {
    #    #warn $caller.'::'.$prefix.$export;
    #    eval "sub ${caller}::$prefix$export () { ". $export->() ." };";
        #warn &{$caller.'::'.$prefix.$export};
        #    \&XML::XPathScript::Processor::DO_SELF_AND_KIDS;
    #    return;
    #}

    *{$caller.'::'.$prefix.$export} = $type eq '&' ? sub { $self->$export(@_) } 
                                    : $type eq '$' ? \${$export_sym} 
                                    : $type eq '@' ? \@{$export_sym} 
                                    : $type eq '%' ? \%{$export_sym} 
                                    : $type eq '*' ?  *{$export_sym} 
                                    : croak "Can't export symbol: $type$export"
                                    ;
}

##### stylesheet API #######################################

sub findnodes {
    my $self = shift;

	if ($self->{parser} eq 'XML::XPath' ) {
		return $self->{dom}->findnodes(@_);
	}

	my ($path, $context) = @_;
	$context = $self->{dom} if (!defined $context);
	return $context->findnodes($path);
}

sub findvalue {
    my $self = shift;
	if ( $self->{parser} eq 'XML::XPath' ) {
		return $self->xpath_to_string(scalar $self->{dom}->findvalue(@_));
	}

	my ($path, $context) = @_;
	$context = $self->{dom} if (!defined $context);
	return $self->xpath_to_string($context->findvalue($path));
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub xpath_to_string {
    my $self = shift;
	my ($blob)=@_;
	return $blob unless ref $blob ;

	# Was simply C<< return "$blob" >> but Perl 5.6.1 seems to have
	# issues with UTF8-flag used in overloaded stringification :-(
	return $blob->can("data")    ? $blob->data() 
         : $blob->can("value")   ? $blob->value() 
         : $blob->string_value()
         ;
}

sub findvalues {
    my $self = shift;
    my @nodes = $self->findnodes(@_);
    map { $self->findvalue('.', $_) } @nodes;
}

sub findnodes_as_string {
    my $self = shift;
	$self->{dom}->findnodes_as_string( @_ ) 
}

sub matches {
    my $self = shift;
	$self->{dom}->matches(@_)
}

sub set_namespace
{
    my $self = shift;
	eval { $self->{dom}->set_namespace(@_) };
	warn "set_namespace failed: $@" if $@;
}

sub apply_templates {
    my $self = shift;

    my $params = ref( $_[-1] ) eq 'HASH' ? pop @_ : {} ;

	# catch the calls to apply_templates() 
    @_ = $self->findnodes('/') unless @_;

    unless( ref $_[0] ) { # called with a path to find
		@_ = $self->findnodes( @_ );
    }

    return unless @_;

    my $retval;

    no warnings qw/ uninitialized /;
    $retval .= $self->translate_node( $_, $params ) 
        for $self->is_nodelist($_[0]) ? $_[0]->get_nodelist
                                      : @_
                                      ;
    return $retval;
}

sub call_template {
    my ($self,$node,$t,$template)=@_;

    if (defined(my $sub=$template->{testcode})) {
	return &$sub($node,$t);
    } elsif (exists $t->{prechild} || exists $t->{prechildren} ||
	     exists $t->{postchild} || exists $t->{postchildren}) {
	warn "XML::XPathScript::Processor::call_template: cannot handle this sort of templates yet";
	# Attempt to recover
	$t->{pre}="";
	$t->{post}="";
	return 1;
    } else {
	$t->{pre}=$template->{pre};
	$t->{post}=$template->{post};
	return 1;
    };
}

sub _apply_templates {
    my $self = shift;
    my $params = pop;
	no warnings 'uninitialized';
	return join '', map $self->translate_node($_,$params), @_;
}

sub is_utf8_tainted {
    my $self = shift;
    my ($string) = @_;

    my $ghost = ($string x 0) .
        "ab"; # Very quick and conserves UTF-8 flag (and taintedness)

    $ghost .= do { use bytes; "\xc3" };
    $ghost .= do { use bytes; "\xa9" };
    my $charlength = do { no bytes; length($ghost) };
    my $bytelength = do { use bytes; length($ghost) };

    if ($charlength == 3) {
        # The two bytes we added got lumped in core into a single
        # UTF-8 char. This is a Perl bug (arising e.g. because $string
        # is tainted, see t/04unicode.t) but we recover gracefully.
        return 1;
    } elsif ($charlength == 4 && $bytelength == 4) {
        return 0;
    } elsif ($charlength == 4 && $bytelength == 6) {
        return 1; # The bytes were upgraded
    } else {
        die "is_utf8_tainted assertion check failed".
            " (charlength = $charlength, bytelength=$bytelength)";
    }
}

	sub get_xpath_of_node {
		my $self =shift;
        my $node = shift;

		# ugly hacks all over in this function, because the quirky
		# refcount-proof aliasing (i.e. XML::XPath::Element versus
		# XML::XPath::ElementImpl) in XML::XPath gets in the way badly
		$node = $$node if $node->isa( 'XML::XPath::Node::Element' ) 
                      and not $self->isa( 'XML::XPath::Node::ElementImpl' ) 
                      and $node =~ /SCALAR/;

		my $parent = $node->can("parentNode") ?  $node->parentNode() 
                                              :  $node->getParentNode()
                                              ;

		return "" unless defined $parent;

		my $name;
		if ($self->is_element_node($node)) {
			$name = $node->findvalue('name()');
		} elsif ($self->is_text_node($node)) {
			$name = "text()";
	    } elsif ($self->is_comment_node($node)) {
			$name = "comment()";
		} elsif ($self->is_pi_node($node)) {
			$name = "processing-instruction()";
		} else {
			# YKYBPTMNW...
			return $self->get_xpath_of_node($parent)."/strange-node()";
		}

		# ugly hack, part II
		my @brothers = map{ ($_->isa( 'XML::XPath::Node::Element' ) ) ? $$_ : $_ } $parent->findnodes("./$name");

		# Short-cut for nodes that have an ID. FIXME: not all DTDs use
		# attribute named "id" as the SGML ID!
	if ($self->is_element_node($node) && (my $id=$self->findvalue('@id',$node))) {
		return $self->get_xpath_of_node($parent).sprintf('/%s[@id="%s"]', $name, $id);
	}

	# Bug: the matches() function from XML::XPath is hosed, and only
	# works towards ancestors. We resort to comparing references for
	# identity. See above for details on the $$self quirk.
	my $theself=($node =~ m/SCALAR/?$$node:$node);

	for my $i ( 0..$#brothers ) {
		my $thebrother=($brothers[$i] =~ m/SCALAR/?
						${$brothers[$i]}:$brothers[$i]);

		return sprintf '%s/%s[%d]', $self->get_xpath_of_node($parent), $name, $i+1 
			if $theself eq $thebrother;
	};

	return $self->get_xpath_of_node($parent)."/$name"."[?]";
}


########################## End of exportable stuff ####################

sub translate_node {
    my( $self, $node, $params ) = @_;

	my $retval = $self->is_element_node( $node ) 
                        ? $self->translate_element_node( $node, $params )
               : $self->is_text_node($node)
                        ? $self->translate_text_node( $node, $params )
               : $self->is_comment_node($node) 
                        ?  $self->translate_comment_node( $node, $params )
               : $self->is_pi_node($node)
                        ? eval { if ($node->getParentNode->getParentNode) {
                                    return $node->toString;
                                 } else { '' }  }
               : $self->to_string( $node )
               ;

	if ( $self->{binmode} &&
		$self->is_utf8_tainted($retval)) {
		use Carp qw(confess);  # TODO remove this
		confess("Wrong translation by stylesheet".
				" (result is Unicode-tainted) at ".$self->get_xpath_of_node($node).
				"\n$retval\n");
	}

	return $retval;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub translate_text_node {
    my $self = shift;	
	my $node = shift;
    my $params = shift;
    my $translations = $self->{template};

	my $trans = $translations->{'#text'} || $translations->{'text()'};

	return $node->toString unless $trans;

    my $action = $trans->{action};

    my $t = new XML::XPathScript::Template::Tag;
    $t->{$_} = $trans->{$_} for keys %{$trans};
	if (my $code = $trans->{testcode}) 
	{
		$action = $code->( $node, $t, $params );
    }
		
	no warnings 'uninitialized';
    return if defined($action) and $action == DO_NOT_PROCESS();

	my $middle;
    $middle = $node->toString if defined($action) 
                                    and $action == DO_TEXT_AS_CHILD();

	return $self->_transform_tag( $t->{pre}, $node, $t, $params ) 
         . $middle 
         . $self->_transform_tag( $t->{post}, $node, $t, $params );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub translate_element_node {
    my( $self, $node, $params ) = @_;
    my $translations = $self->{template};

    my $node_name = $self->get_node_name( $node );

    my $namespace = $self->get_namespace( $node );

    my $trans = XML::XPathScript::Template::resolve( $translations, 
                                                $namespace, $node_name );

    unless( $trans ) {
        # no specific and no generic? Okay, okay, return as is...
        no warnings qw/ uninitialized /;
        my @kids = $self->get_child_nodes( $node );
        return $self->start_tag($node)  
               . $self->_apply_templates( @kids, $params )
               . $self->end_tag($node);	
		
    }

    my $t = new XML::XPathScript::Template::Tag;
    $t->{$_} = $trans->{$_} for keys %{$trans};

    # we officially support 'content', but also allow
    # 'contents'
    if ( my $content = $trans->{content} || $trans->{contents} ) {
        return $self->_transform_content( $content, $node, $t, $params );
    }

    # by default we do the kids
    my $dokids = 1;  
    my $search;

    my $action = $trans->{action};
    
	if ($trans->{testcode}) {
        $action = $trans->{testcode}->($node, $t, $params );
    }

	no warnings 'uninitialized';
    return if $action =~ /^-?\d+$/ and $action == DO_NOT_PROCESS();

    if( defined( $action) and $action !~ /^-?\d+/ ) {
        # ah, an xpath expression
        $dokids = 0;
        $search = $action;
    }
    elsif ($action == DO_SELF_ONLY() ) {
        $dokids = 0;
    }

    my @kids = $dokids ? $node->getChildNodes()
             : $search ? $node->findnodes($search)
             : ()
             ;

    my @args = ( $node, $t, $params );

    my $pre = $self->_transform_tag( $t->{pre}, @args );
	$pre   .= $self->start_tag( $node , $t->{rename}) if $t->{showtag};
	$pre   .= $self->_transform_tag( $t->{intro}, @args );
	$pre   .= $self->_transform_tag( $t->{prechildren}, @args ) if @kids;
	
	my $post;
	$post .= $self->_transform_tag( $t->{postchildren}, @args ) if @kids;
	$post .= $self->_transform_tag( $t->{extro}, @args );
	$post .= $self->end_tag( $node, $t->{rename} ) if  $t->{showtag};
	$post .= $self->_transform_tag( $t->{post}, @args );

	my $middle;

    for my $kid ( @kids ) 
    {
        my $kid_is_element = $self->is_element_node( $kid );

        $middle .= $self->_transform_tag( $trans->{prechild}, 
                        $kid, $t, $params ) if $kid_is_element;

        $middle .= $self->apply_templates($kid, $params );

        $middle .= $self->_transform_tag( $trans->{postchild}, 
                        $kid, $t, $params ) if $kid_is_element;
    }
        
	return $pre . $middle . $post;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _transform_content {
   my ( $self, $content, $node, $t, $params ) = @_;

    return $content->( $node, $t, $params ) if ref $content eq 'CODE';

    my $interpolated = $self->interpolate( $node, $content );

    local *STDOUT;
    my $output;
    open STDOUT, '>', \$output or die "couldn't redirect STDOUT: $!\n";

    my $xps = XML::XPathScript::current();

    my $code = $xps->extract( $interpolated );

    local $self->{dom} = $node;

    eval <<"END_CONTENT";
        package XML::XPathScript::Template::Content; 
        my \$processor = \$self; 
        my \%params = \%\$params;
        \$self->import_functional unless exists \&get_template;
        $code;
END_CONTENT

    die $@ if $@;

    return $output;
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# bad terminology, here a tag is 'pre', 'post', etc

sub _transform_tag {
    my ( $self, $tag, $node, $t, $params ) = @_;

    return unless $tag;

    return $tag->( $node, $t, $params ) if ref $tag eq 'CODE';

    return $self->interpolate( $node, $tag );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub translate_comment_node {
    my ( $self, $node, $params ) = @_;
    my $translations = $self->{template};

	my $trans = $translations->{'#comment'} || $translations->{'comment()'};

	return $node->toString unless $trans;

	my $middle = $self->get_text_content( $node );

    my $t = new XML::XPathScript::Template::Tag;
    $t->{$_} = $trans->{$_} for keys %{$trans};

    my $action = $trans->{action};

	if (my $code = $trans->{testcode}) 
	{
		$action = $code->( $node, $t, $params );
		if ($action and %$t) {
			foreach my $tkey (keys %$t) {
				$trans->{$tkey} = $t->{$tkey};
			}
		}
	}

	no warnings 'uninitialized';
    return if $action =~ /^-?\d+$/ and $action == $DO_NOT_PROCESS;
    
    $middle = undef if $action == $DO_SELF_ONLY;
	return $self->_transform_tag( $trans->{pre}, $node, $t, $params )
         . $middle
         . $self->_transform_tag( $trans->{post}, $node, $t, $params );
}

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub start_tag {
    my( $self, $node, $name ) = @_;

    $name ||= $self->get_qualified_name( $node ) or return;

    my $string = '<'.$name;

	# do we need this for libXML?
	if( $self->{parser} eq 'XML::XPath' )
	{
    	$string .= $_->toString for $node->getNamespaceNodes;
	}

    for my $attr ( $self->get_attributes( $node )  ) {
		$string .= $self->get_attribute( $attr );
    }

    $string .= '>';

    return $string;
}

sub end_tag {
    my $self = shift;
    if (my $name = $_[1] || $self->get_qualified_name( $_[0] ) ) {
        return "</$name>";
    }
	return '';
}

sub interpolate {
    my ($self, $node, $string) = @_;
	
	# if string is empty or no interpolation,
	# we return
    return( $string || '' ) unless 
		defined( $string ) and 
        $self->{is_interpolating};

	my $regex = $self->{interpolation_regex};
	$string =~ s/$regex/ $node->findvalue($1) /egs;
	
	no warnings 'uninitialized';
    return $string;
}

'end of module XML::XPathScript::Processor';

__END__

=pod

=encoding UTF-8

=head1 NAME

XML::XPathScript::Processor - XML::XPathScript transformation engine

=head1 VERSION

version 2.00

=head1 SYNOPSIS

    # OO API
    use XML::XPathScript::Processor;

    my $processor = XML::XPathScript::Processor->new;
    $processor->set_xml( $dom );
    $processor->set_template( $template );

    my $transformed = $processor->apply_templates( '//foo' );

    # functional API
    use XML::XPathScript::Processor;
    XML::XPathscript::Processor->import_functional;

    set_xml( $dom );
    set_template( $template );
    my $transformed = apply_templates( '//foo' );

=head1 SYNOPSIS

    # OO API
    use XML::XPathScript::Processor;

    my $processor = XML::XPathScript::Processor->new;
    $processor->set_xml( $dom );
    $processor->set_template( $template );

    my $transformed = $processor->apply_templates( '//foo' );

    # functional API
    use XML::XPathScript::Processor;
    XML::XPathscript::Processor->import_functional;

    set_xml( $dom );
    set_template( $template );
    my $transformed = apply_templates( '//foo' );

=head1 DESCRIPTION

The I<XML::XPathScript> distribution offers an XML parser glue, an
embedded stylesheet language, and a way of processing an XML document
into a text output. This module implements the latter part: it takes
an already filled out C<< $template >> template object and an already parsed
XML document (which are usually both provided by the parent
L<XML::XPathScript> object),
and provides a simple API to implement stylesheets. 

Typically, the processor is encapsulated within a L<XML::XPathScript>
object. In which case, all the black magick is already done for you,
and the only part you have to worry about is the XPathScript 
language functions that XML::XPathScript::Processor imports into
the stylesheet (see L</XPATHSCRIPT LANGUAGE FUNCTIONS>).

It is also possible to use a processor on its own, without using a
stylesheet. This might be desirable, for example, to use XPathScript
within a different templating system, like L<Embperl> or L<HTML::Mason>.
For a discussion on how to use this module in such cases, see section 
L</Embedding XML::XPathScript::Processor in a Templating System>.

=head2 Embedding XML::XPathScript::Processor in a Templating System

It is possible to use the XPathScript processing engine without having 
to rely on stylesheets. This can be desirable if one wishes to use XPathScript
within a different templating system, like Embperl or HTML::Mason. To do 
so, one simply has to directly use XML::XPathScript::Processor. 

Example, with HTML::Mason:

    <%perl>
        use XML::XPathScript::Processor;
        use XML::XPathScript::Template;
        use XML::LibXML;

        my $processor = XML::XPathScript::Processor->new;

        # load the dom
        my $dom = XML::LibXML->new->parse_string( <<'END_XML' );
            <orchid>
                <genus>Miltonesia</genus>
                <species>spectabilis</species>
                <variety>moreliana</variety>
            </orchid>
    END_XML
        $processor->set_dom( $dom );

        # load the template
        my $template = XML::XPathScript::Template->new;
        $processor->set_template( $template );
        $template->set( orchid => { showtag => 0 } );
        $template->set( genus  => { rename => 'i' } );
        $template->set( species  => { rename => 'i' } );
        $template->set( variety  => { pre => 'var. '  } );
    </%perl>

    <p>This orchid is a <% $processor->apply_templates( '//orchid' )  %>.</p>

Same example, with Embperl:

    [!
        use XML::XPathScript::Processor;
        use XML::XPathScript::Template;
        use XML::LibXML;
    !]

    [-
        $processor = XML::XPathScript::Processor->new;

        # load the dom
        $dom = XML::LibXML->new->parse_string( <<'END_XML' );
            <orchid>
                <genus>Miltonesia</genus>
                <species>spectabilis</species>
                <variety>moreliana</variety>
            </orchid>
    END_XML
        $processor->set_dom( $dom );

        # load the template
        $template = XML::XPathScript::Template->new;
        $processor->set_template( $template );
        $template->set( orchid => { showtag => 0 } );
        $template->set( genus  => { rename => 'i' } );
        $template->set( species  => { rename => 'i' } );
        $template->set( variety  => { pre => 'var. '  } );
    -]

    <p>This orchid is a [+ $processor->apply_templates( '//orchid' ) +].</p>

=head1 DESCRIPTION

The I<XML::XPathScript> distribution offers an XML parser glue, an
embedded stylesheet language, and a way of processing an XML document
into a text output. This module implements the latter part: it takes
an already filled out C<< $template >> template object and an already parsed
XML document (which are usually both provided by the parent
L<XML::XPathScript> object),
and provides a simple API to implement stylesheets. 

Typically, the processor is encapsulated within a L<XML::XPathScript>
object. In which case, all the black magick is already done for you,
and the only part you have to worry about is the XPathScript 
language functions that XML::XPathScript::Processor imports into
the stylesheet (see L</XPATHSCRIPT LANGUAGE FUNCTIONS>).

It is also possible to use a processor on its own, without using a
stylesheet. This might be desirable, for example, to use XPathScript
within a different templating system, like L<Embperl> or L<HTML::Mason>.
For a discussion on how to use this module in such cases, see section 
L</Embedding XML::XPathScript::Processor in a Templating System>.

=head2 Embedding XML::XPathScript::Processor in a Templating System

It is possible to use the XPathScript processing engine without having 
to rely on stylesheets. This can be desirable if one wishes to use XPathScript
within a different templating system, like Embperl or HTML::Mason. To do 
so, one simply has to directly use XML::XPathScript::Processor. 

Example, with HTML::Mason:

    <%perl>
        use XML::XPathScript::Processor;
        use XML::XPathScript::Template;
        use XML::LibXML;

        my $processor = XML::XPathScript::Processor->new;

        # load the dom
        my $dom = XML::LibXML->new->parse_string( <<'END_XML' );
            <orchid>
                <genus>Miltonesia</genus>
                <species>spectabilis</species>
                <variety>moreliana</variety>
            </orchid>
    END_XML
        $processor->set_dom( $dom );

        # load the template
        my $template = XML::XPathScript::Template->new;
        $processor->set_template( $template );
        $template->set( orchid => { showtag => 0 } );
        $template->set( genus  => { rename => 'i' } );
        $template->set( species  => { rename => 'i' } );
        $template->set( variety  => { pre => 'var. '  } );
    </%perl>

    <p>This orchid is a <% $processor->apply_templates( '//orchid' )  %>.</p>

Same example, with Embperl:

    [!
        use XML::XPathScript::Processor;
        use XML::XPathScript::Template;
        use XML::LibXML;
    !]

    [-
        $processor = XML::XPathScript::Processor->new;

        # load the dom
        $dom = XML::LibXML->new->parse_string( <<'END_XML' );
            <orchid>
                <genus>Miltonesia</genus>
                <species>spectabilis</species>
                <variety>moreliana</variety>
            </orchid>
    END_XML
        $processor->set_dom( $dom );

        # load the template
        $template = XML::XPathScript::Template->new;
        $processor->set_template( $template );
        $template->set( orchid => { showtag => 0 } );
        $template->set( genus  => { rename => 'i' } );
        $template->set( species  => { rename => 'i' } );
        $template->set( variety  => { pre => 'var. '  } );
    -]

    <p>This orchid is a [+ $processor->apply_templates( '//orchid' ) +].</p>

=head1 XPATHSCRIPT LANGUAGE FUNCTIONS

This section covers the utility functions that are available 
within a stylesheet. 

=over

=item processor

    $processor = processor()

Returns the processor object. Useful for when XML::XPathScript::Processor is
used in functional mode.

=item set_dom, get_dom

    set_dom( $dom )
    $dom = get_dom

Accessors for the dom the processor is to transform. I<$dom> must be
an XML::LibXML or XML::XPath document or element.

=item get_parser

    $parser = get_parser()

Returns the parser associated with the loaded dom as a string ( 'XML::LibXML'
or 'XML::XPath'), or B<undef> if no dom has been loaded yet.

=item enable_binmode

    enable_binmode()

Enables binmode for the processor's output. See L<XML::XPathScript/binmode>.

=item get_binmode

    $mode = get_binmode()

Returns true if binmode has been enabled, false otherwise.

=item set_template, get_template

    set_template( $t )
    $t = get_template

Accessors for the processor's template. The template I<$t> must be an
L<XML::XPathScript::Template> object.

=item set_interpolation, get_interpolation

    set_interpolation( $bool )
    $bool = get_interpolation()

Sets / accesses the interpolation mode (on or off) of the processor.

=item set_interpolation_regex, get_interpolation_regex

Sets / accesses the interpolation regex used by the processor.

=item findnodes

   @nodes = findnodes( $path )
   @nodes = findnodes( $path, $context ) 

Returns a list of nodes found by XPath expression $path, optionally
using $context as the context node (if not provided,
defaults to the root node of the document).  
In scalar context returns a NodeSet object (but
you do not want to do that, see L<XML::XPathScript/XPath scalar return
values considered harmful>).

=item findvalue

    $value = findvalue( $path )
    $value = findvalue( $path, $context )

Evaluates XPath expression $path and returns the resulting value. If
the path returns an object, 
stringification is done automatically for you using
L</xpath_to_string>.

=item xpath_to_string

    $string = xpath_to_string( $blob )

Converts any XPath data type, such as "Literal", "Numeric",
"NodeList", text nodes, etc. into a pure Perl string (UTF-8 tainted
too - see L</is_utf8_tainted>). Scalar XPath types are interpreted in
the straightforward way, DOM nodes are stringified into conform XML,
and NodeList's are stringified by concatenating the stringification of
their members (in the latter case, the result obviously is not
guaranteed to be valid XML).

See L<XML::XPathScript/XPath scalar return values considered harmful>
on why this is useful.

=item findvalues

    @values = findvalues( $path )
    @values = findvalues( $path, $context )

Evaluates XPath expression $path as a nodeset expression, just like
L</findnodes> would, but returns a list of UTF8-encoded XML strings
instead of node objects or node sets. See also
L<XML::XPathScript/XPath scalar return values considered harmful>.

=item findnodes_as_string

    @nodes = findnodes_as_string( $path )
    @nodes = findnodes_as_string( $path, $context )

Similar to L</findvalues> but concatenates the XML snippets.  The
result obviously is not guaranteed to be valid XML.

=item matches

    $bool = matches( $node, $path )
    $bool = matches( $node, $path, $context )

Returns true if the node matches the path (optionally in context $context)

=item apply_templates

    $transformed = apply_templates( @nodes, \%params )
    $transformed = apply_templates( $xpath, $context, \%params )
    $transformed = apply_templates( $xpath, \%params )

This is where the whole magic in XPathScript resides: recursively
applies the stylesheet templates to the nodes provided either
literally (first invocation form) or through an XPath expression
(second and third invocation forms), and returns a string
concatenation of all results. 

If called without nodes or an xpath. 
renders the whole document (same as C<< apply_templates('/') >>).

An hash of parameters, I<%params> can also be passed to 
B<apply_templates>, which will be passed to any
B<testcode> function called from the template. 

Calls to I<apply_templates()> may occur both implicitly (at the top of
the document, and for rendering subnodes when the templates choose to
handle that by themselves), and explicitly (because C<testcode>
routines require the XML::XPathScript::Processor to
L</DO_SELF_AND_KIDS>).

If appropriate care is taken in all templates (especially the
C<testcode> routines and the I<text()> template), the string result of
I<apply_templates> need not be UTF-8 (see
L<XML::XPathScript/binmode>): it is thus possible to use XPathScript
to produce output in any character set without an extra translation
pass.

=item call_template

    call_template( $node, $t, $templatename )

B<EXPERIMENTAL> - allows C<testcode> routines to invoke a template by
name, even if the selectors do not fit (e.g. one can apply template B
to an element node of type A). Returns the stylesheeted string
computed out of $node just like L</apply_templates> would.

=item is_element_node 

    $bool = is_element_node( $object )

Returns true if $object is an element node, false otherwise.

=item is_text_node

    $bool = is_text_node( $object )

Returns true if $object is a "true" text node (B<not> a comment node),
false otherwise.

=item is_comment_node

    $bool = is_comment_node ( $object )

Returns true if $object is an XML comment node, false otherwise.

=item is_pi_node

    $bool = is_pi_node( $object )

Returns true iff $object is a processing instruction node.

=item is_nodelist

    $bool = is_nodelist( $object )

Returns true if $node is a node list (as returned by L</findnodes> in
scalar context), false otherwise.

=item is_utf8_tainted

    $bool = is_utf8_tainted( $string )

Returns true if Perl thinks that $string is a string of characters (in
UTF-8 internal representation), and false if Perl treats $string as a
meaningless string of bytes.

The dangerous part of the story is when concatenating a non-tainted
string with a tainted one, as it causes the whole string to be
re-interpreted into UTF-8, even the part that was supposedly
meaningless character-wise, and that happens in a nonportable fashion
(depends on locale and Perl version). So don't do that - and use this
function to prevent that from happening.

=item get_xpath_of_node

 $xpath = get_xpath_of_node( $node )

Returns an XPath string that points to $node, from the root. Useful to
create error messages that point at some location in the original XML
document.

=for comment =head2 Functional and OO APIs
    If used within a stylesheet, 

=back

=head1 XPATHSCRIPT LANGUAGE CONSTANTS

B<$DO_SELF_AND_KIDS>, B<$DO_SELF_ONLY>, B<$DO_NOT_PROCESS>,
B<$DO_TEXT_AS_CHILD>

B<DO_SELF_AND_KIDS>, B<DO_SELF_ONLY>, B<DO_NOT_PROCESS>, B<DO_TEXT_AS_CHILD>

These constants are used to define the B<action> tag of an element, 
or the return value of a B<testcode> function (see 
L<XML::XPathScript/Stylesheet#action>). They are automatically
exported.

The pseudo-bareword way to refer to the constants (e.g., C<DO_SELF_ONLY>) 
is deprecated, and will eventually be removed in a future release.

=head1 METHODS

=over

=item import_functional

    XML::XPathScript::Processor->import_functional( $prefix )
    $processor->import_functional( $prefix )

Imports the stylesheet utility functions into the current 
namespace. If I<$prefix> is given, is it prepended to the
function names (i.e., if I<$prefix> is 'B<xps_>',
B<apply_templates> will become B<xps_apply_templates>).

If the first form is used, a new processor object is secretly
created and assigned to the namespace (it can be retrieved using 
the function B<processor()>). The second form uses the already
existing I<$processor> as the underlaying processor object for
the namespace.

Example:

    use XML::XPathScript::Processor;

    # import the goodies in the current namespace
    XML::XPathScript::Processor->import_functional;

    # set the document and template we want to use
    set_dom( $xml_dom );
    set_template( $template );

    my @foo_nodes = findnodes( '//foo' );
    # print the last foo, transformed
    print apply_templates( $foo_nodes[-1] );

=back

=head1 NAME

XML::XPathScript::Processor - XML::XPathScript transformation engine

=head1 XPATHSCRIPT LANGUAGE FUNCTIONS

This section covers the utility functions that are available 
within a stylesheet. 

=over

=item processor

    $processor = processor()

Returns the processor object. Useful for when XML::XPathScript::Processor is
used in functional mode.

=item set_dom, get_dom

    set_dom( $dom )
    $dom = get_dom

Accessors for the dom the processor is to transform. I<$dom> must be
an XML::LibXML or XML::XPath document or element.

=item get_parser

    $parser = get_parser()

Returns the parser associated with the loaded dom as a string ( 'XML::LibXML'
or 'XML::XPath'), or B<undef> if no dom has been loaded yet.

=item enable_binmode

    enable_binmode()

Enables binmode for the processor's output. See L<XML::XPathScript/binmode>.

=item get_binmode

    $mode = get_binmode()

Returns true if binmode has been enabled, false otherwise.

=item set_template, get_template

    set_template( $t )
    $t = get_template

Accessors for the processor's template. The template I<$t> must be an
L<XML::XPathScript::Template> object.

=item set_interpolation, get_interpolation

    set_interpolation( $bool )
    $bool = get_interpolation()

Sets / accesses the interpolation mode (on or off) of the processor.

=item set_interpolation_regex, get_interpolation_regex

Sets / accesses the interpolation regex used by the processor.

=item findnodes

   @nodes = findnodes( $path )
   @nodes = findnodes( $path, $context ) 

Returns a list of nodes found by XPath expression $path, optionally
using $context as the context node (if not provided,
defaults to the root node of the document).  
In scalar context returns a NodeSet object (but
you do not want to do that, see L<XML::XPathScript/XPath scalar return
values considered harmful>).

=item findvalue

    $value = findvalue( $path )
    $value = findvalue( $path, $context )

Evaluates XPath expression $path and returns the resulting value. If
the path returns an object, 
stringification is done automatically for you using
L</xpath_to_string>.

=item xpath_to_string

    $string = xpath_to_string( $blob )

Converts any XPath data type, such as "Literal", "Numeric",
"NodeList", text nodes, etc. into a pure Perl string (UTF-8 tainted
too - see L</is_utf8_tainted>). Scalar XPath types are interpreted in
the straightforward way, DOM nodes are stringified into conform XML,
and NodeList's are stringified by concatenating the stringification of
their members (in the latter case, the result obviously is not
guaranteed to be valid XML).

See L<XML::XPathScript/XPath scalar return values considered harmful>
on why this is useful.

=item findvalues

    @values = findvalues( $path )
    @values = findvalues( $path, $context )

Evaluates XPath expression $path as a nodeset expression, just like
L</findnodes> would, but returns a list of UTF8-encoded XML strings
instead of node objects or node sets. See also
L<XML::XPathScript/XPath scalar return values considered harmful>.

=item findnodes_as_string

    @nodes = findnodes_as_string( $path )
    @nodes = findnodes_as_string( $path, $context )

Similar to L</findvalues> but concatenates the XML snippets.  The
result obviously is not guaranteed to be valid XML.

=item matches

    $bool = matches( $node, $path )
    $bool = matches( $node, $path, $context )

Returns true if the node matches the path (optionally in context $context)

=item apply_templates

    $transformed = apply_templates()
    $transformed = apply_templates( $xpath )
    $transformed = apply_templates( $xpath, $context )
    $transformed = apply_templates( @nodes )

This is where the whole magic in XPathScript resides: recursively
applies the stylesheet templates to the nodes provided either
literally (last invocation form) or through an XPath expression
(second and third invocation forms), and returns a string
concatenation of all results. If called without arguments at all,
renders the whole document (same as C<< apply_templates("/") >>).

Calls to I<apply_templates()> may occur both implicitly (at the top of
the document, and for rendering subnodes when the templates choose to
handle that by themselves), and explicitly (because C<testcode>
routines require the XML::XPathScript::Processor to
L</DO_SELF_AND_KIDS>).

If appropriate care is taken in all templates (especially the
C<testcode> routines and the I<text()> template), the string result of
I<apply_templates> need not be UTF-8 (see
L<XML::XPathScript/binmode>): it is thus possible to use XPathScript
to produce output in any character set without an extra translation
pass.

=item call_template

    call_template( $node, $t, $templatename )

B<EXPERIMENTAL> - allows C<testcode> routines to invoke a template by
name, even if the selectors do not fit (e.g. one can apply template B
to an element node of type A). Returns the stylesheeted string
computed out of $node just like L</apply_templates> would.

=item is_element_node 

    $bool = is_element_node( $object )

Returns true if $object is an element node, false otherwise.

=item is_text_node

    $bool = is_text_node( $object )

Returns true if $object is a "true" text node (B<not> a comment node),
false otherwise.

=item is_comment_node

    $bool = is_comment_node ( $object )

Returns true if $object is an XML comment node, false otherwise.

=item is_pi_node

    $bool = is_pi_node( $object )

Returns true iff $object is a processing instruction node.

=item is_nodelist

    $bool = is_nodelist( $object )

Returns true if $node is a node list (as returned by L</findnodes> in
scalar context), false otherwise.

=item is_utf_tainted

    $bool = is_utf8_tainted( $string )

Returns true if Perl thinks that $string is a string of characters (in
UTF-8 internal representation), and false if Perl treats $string as a
meaningless string of bytes.

The dangerous part of the story is when concatenating a non-tainted
string with a tainted one, as it causes the whole string to be
re-interpreted into UTF-8, even the part that was supposedly
meaningless character-wise, and that happens in a nonportable fashion
(depends on locale and Perl version). So don't do that - and use this
function to prevent that from happening.

=item get_xpath_of_node

 $xpath = get_xpath_of_node( $node )

Returns an XPath string that points to $node, from the root. Useful to
create error messages that point at some location in the original XML
document.

=for comment =head2 Functional and OO APIs
    If used within a stylesheet, 

=back

=head1 METHODS

=over

=item import_functional

    XML::XPathScript::Processor->import_functional( $prefix )
    $processor->import_functional( $prefix )

Imports the stylesheet utility functions into the current 
namespace. If I<$prefix> is given, is it prepended to the
function names (i.e., if I<$prefix> is 'B<xps_>',
B<apply_templates> will become B<xps_apply_templates>).

If the first form is used, a new processor object is secretly
created and assigned to the namespace (it can be retrieved using 
the function B<processor()>). The second form uses the already
existing I<$processor> as the underlaying processor object for
the namespace.

Example:

    use XML::XPathScript::Processor;

    # import the goodies in the current namespace
    XML::XPathScript::Processor->import_functional;

    # set the document and template we want to use
    set_dom( $xml_dom );
    set_template( $template );

    my @foo_nodes = findnodes( '//foo' );
    # print the last foo, transformed
    print apply_templates( $foo_nodes[-1] );

=back

=head1 AUTHORS

=over 4

=item *

Yanick Champoux <yanick@cpan.org>

=item *

Dominique Quatravaux <domq@cpan.org>

=item *

Matt Sergeant <matt@sergeant.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2008, 2007 by Matt Sergeant.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
