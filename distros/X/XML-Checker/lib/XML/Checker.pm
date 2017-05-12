use warnings;
use strict;
#
#
# TO DO
# - update docs regarding PerlSAX interface
# - add current node to error context when checking DOM subtrees
# - add parsed Entity to test XML files
# - free circular references
# - Implied handler?
# - Notation, Entity, Unparsed checks, Default handler?
# - check no root element (it's checked by expat) ?

package XML::Checker::Term;
use strict;

sub new     
{ 
    my ($class, %h) = @_;
    bless \%h, $class;
}

sub str     
{ 
    '<' . $_[0]->{C} . $_[0]->{N} . '>'
}

sub re
{ 
    $_[0]->{S} 
}

sub rel 
{ 
    my $self = shift;
    defined $self->{SL} ? @{ $self->{SL} } : ( $self->{S} );
}

sub debug
{
    my $t = shift;
    my ($c, $n, $s) = ($t->{C}, $t->{N}, $t->{S});
    my @sl = $t->rel;
    "{C=$c N=$n S=$s SL=@sl}";
}

#-------------------------------------------------------------------------

package XML::Checker::Context;

sub new
{
    my ($class) = @_;
    my $scalar;
    bless \$scalar, $class;
}

sub Start {}
sub End   {}
sub Char  {}

#
# The initial Context when checking an entire XML Document
#
package XML::Checker::DocContext;
use vars qw( @ISA );
@ISA = qw( XML::Checker::Context );

sub new
{
#??checker not used
    my ($class, $checker) = @_;
    bless { }, $class;
}

sub setRootElement
{
    $_[0]->{RootElement} = $_[1];
}

sub Start 
{
    my ($self, $checker, $tag) = @_;
    if (exists $self->{Elem})
    {
	my $tags = join (", ", @{$self->{Elem}});
	$checker->fail (155, "more than one root Element [$tags]");
	push @{$self->{Elem}}, $tag;
    }
    else
    {
	$self->{Elem} = [ $tag ];
    }

    my $exp_root = $self->{RootElement};
    $checker->fail (156, "unexpected root Element [$tag], expected [$exp_root]")
	if defined ($exp_root) and $tag ne $exp_root;
}

sub debug
{
    my $self = shift;
    "DocContext[Count=" . $self->{Count} . ",Root=" . 
	$self->{RootElement} . "]";
}

package XML::Checker::Context::ANY;
use vars qw( @ISA );
@ISA = qw( XML::Checker::Context );

# No overrides, because everything is accepted

sub debug { "XML::Checker::Context::ANY" }

package XML::Checker::Context::EMPTY;
use vars qw( @ISA $ALLOW_WHITE_SPACE );
@ISA = qw( XML::Checker::Context );

$ALLOW_WHITE_SPACE = 0;

sub debug { "XML::Checker::Context::EMPTY" }

sub Start
{
    my ($self, $checker, $tag) = @_;
    $checker->fail (152, "Element should be EMPTY, found Element [$tag]");
}

sub Char
{
    my ($self, $checker, $str) = @_;
    $checker->fail (153, "Element should be EMPTY, found text [$str]")
	unless ($ALLOW_WHITE_SPACE and $checker->isWS ($str));

    # NOTE: if $ALLOW_WHITE_SPACE = 1, the isWS call does not only check
    # whether it is whitespace, but it also informs the checker that this 
    # might be insignificant whitespace
}

#?? what about Comments

package XML::Checker::Context::Children;
use vars qw( @ISA );
@ISA = qw( XML::Checker::Context );

sub new
{
    my ($class, $rule) = @_;
    bless { Name => $rule->{Name}, RE => $rule->{RE}, Buf => "", N => 0 }, $class;
}

sub phash
{
    my $href = shift;
    my $str = "";
    for (keys %$href)
    {
	$str .= ' ' if $str;
	$str .= $_ . '=' . $href->{$_};
    }
    $str;
}

sub debug
{
    my $self = shift;
    "Context::Children[Name=(" . phash ($self->{Name}) . ",N=" . $self->{N} .
	",RE=" . $self->{RE} . ",Buf=[" . $self->{Buf} . "]";
}

sub Start
{
    my ($self, $checker, $tag) = @_;

#print "Children.Start tag=$tag rule=$checker drule=" . $checker->debug . "\n";

    if (exists $self->{Name}->{$tag})
    {
#print "Buf=[".$self->{Buf}. "] tag=[" . $self->{Name}->{$tag}->{S} . "]\n";
	$self->{Buf} .= $self->{Name}->{$tag}->{S};
    }
    else
    {
      $checker->fail (157, "unexpected Element [$tag]", 
			ChildElementIndex => $self->{N})
    }
    $self->{N}++;
}

sub decode
{
    my ($self) = @_;
    my $re = $self->{RE};
    my $name = $self->{Name};
    my $buf = $self->{Buf};

    # length of token, in a content model all tokens are the same length
    my $len = 0;		
    my %s = ();
    while (my ($key, $val) = each %$name)
    {
      $len = length($val->{S}) unless $len;
      $s{$val->{S}} = $key;
    }
    # ex. $key = C_31 and $name = 01
    #use warnings;
    my $dots = "[^()*+?|]" x $len;
    $buf =~ s/($dots)/$s{$1} . ","/ge;
    chop $buf;

    $re =~ s/($dots)/"(" . $s{$1} . ")"/ge;

    "Found=[$buf] RE=[$re]"
}

sub End
{
    my ($self, $checker) = @_;
    my $re = $self->{RE};

    unless ( $self->{Buf} =~ /\S/ ) {
      unless ( $self->{Buf} =~ /^$re$/ ) {
	$checker->fail (170, "Element can't be empty " . $self->decode);
	return;
      }
    }
    unless ( $self->{Buf} =~ /^$re$/ ) {
      $checker->fail (154, "bad order of Elements " . $self->decode);
    }
}

sub Char
{
    my ($self, $checker, $str) = @_;
    $checker->fail (149, "Element should only contain sub elements, found text [$str]")
      unless ($checker->isWS ($str));
}

package XML::Checker::Context::Mixed;
use vars qw( @ISA );
@ISA = qw( XML::Checker::Context );

sub new
{
    my ($class, $rule) = @_;
    bless { Name => $rule->{Name}, N => 0 }, $class;
}

sub debug
{
    my $self = shift;
    "Context::Mixed[Name=" . $self->{Name} . ",N=" , $self->{N} . "]";
}

sub Start
{
    my ($self, $checker, $tag) = @_;

    $checker->fail (157, "unexpected Element [$tag]",
		    ChildElementIndex => $self->{N})
	unless exists $self->{Name}->{$tag};
    $self->{N}++;
}

package XML::Checker::ERule;

package XML::Checker::ERule::EMPTY;
use vars qw( @ISA );
@ISA = qw( XML::Checker::ERule );

sub new
{
    my ($class) = @_;
    bless {}, $class;
}

my $context = new XML::Checker::Context::EMPTY;
sub context { $context }	# share the context

sub debug { "EMPTY" }

package XML::Checker::ERule::ANY;
use vars qw( @ISA );
@ISA = qw( XML::Checker::ERule );

sub new
{
    my ($class) = @_;
    bless {}, $class;
}

my $any_context = new XML::Checker::Context::ANY;
sub context { $any_context }	# share the context

sub debug { "ANY" }

package XML::Checker::ERule::Mixed;
use vars qw( @ISA );
@ISA = qw( XML::Checker::ERule );

sub new
{
    my ($class) = @_;
    bless { Name => {} }, $class;
}

sub context 
{
    my ($self) = @_;
    new XML::Checker::Context::Mixed ($self);
}

sub setModel
{
    my ($self, $model) = @_;
    my $rule = $model;

    # Mixed := '(' '#PCDATA' ')' '*'?
    if ($rule =~ /^\(\s*#PCDATA\s*\)(\*)?$/)
    {
#? how do we interpret the '*' ??
         return 1;
    }
    else	# Mixed := '(' '#PCDATA' ('|' Name)* ')*'
    {
	return 0 unless $rule =~ s/^\(\s*#PCDATA\s*//;
	return 0 unless $rule =~ s/\s*\)\*$//;

	my %names = ();
	while ($rule =~ s/^\s*\|\s*($XML::RegExp::Name)//)
	{
	    $names{$1} = 1;
	}
	if ($rule eq "")
	{
	    $self->{Name} = \%names;
	    return 1;
	}
    }
    return 0;
}

sub debug
{
    my ($self) = @_;
    "Mixed[Names=" . join("|", keys %{$self->{Name}}) . "]";
}

package XML::Checker::ERule::Children;
use vars qw( @ISA %_name %_map $_n );
@ISA = qw( XML::Checker::ERule );

sub new
{
    my ($class) = @_;
    bless {}, $class;
}

sub context 
{
    my ($self) = @_;
    new XML::Checker::Context::Children ($self);
}

sub _add	# static
{
    my $exp = new XML::Checker::Term (@_);
    $_map{$exp->{N}} = $exp;
    $exp->str;
}

my $IDS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
sub _tokenize
{
    my ($self, $rule) = @_;

    # Replace names with Terms of the form "<n#>", e.g. "<n2>".
    # Lookup already used names and store new names in %_name.
    # 
    $$rule =~ s/($XML::RegExp::Name)(?!>)/
	if (exists $_name{$1})		# name already used?
	{
	    $_name{$1}->str;
	}
        else
	{
	    my $exp = new XML::Checker::Term (C => 'n', N => $_n++, 
					      Name => $1);
	    $_name{$1} = $_map{$exp->{N}} = $exp;
	    $exp->str;
	}
    /eg;

    if ($_n < length $IDS)
    {
	# Generate regular expression for the name Term, i.e.
	# a single character from $IDS
	my $i = 0;
	for (values %_name)
	{
	    $_->{S} = substr ($IDS, $i++, 1);
#print "tokenized " . $_->{Name} . " num=" . $_->{N} . " to " . $_->{S} . "\n";
	}
    }
    else
    {
	# Generate RE, convert Term->{N} to hex string 
	# e.g. "03d". Calculate needed length of hex string first.
	my $len = 0;
	for (my $n = $_n - 1; $n > 0; $len++) {
	  $n = $n >> 4; 
	}
	my $i = 0;
	for (values %_name)
	{
	  $_->{S} = sprintf ("%0${len}lx", $i++);
#print "tokenized " . $_->{Name} . " num=" . $_->{N} . " to " . $_->{S} . "\n";
	}
    }
}

sub setModel
{
    my ($self, $rule) = @_;

    local $_n = 0;
    local %_map = ();
    local %_name = ();
    
    $self->_tokenize (\$rule);

#?? check for single name - die "!ELEMENT contents can't be just a NAME" if $rule =~ /^$XML::RegExp::Name$/;

    for ($rule)
    {
	my $n = 1;
	while ($n)
	{
	    $n = 0;

	    # cp := ( name | choice | seq ) ('?' | '*' | '+')?
	    $n++ while s/<[ncs](\d+)>([?*+]?)/_add
	    (C => 'a', N => $_n++, 
	    S => ($_map{$1}->re . $2))/eg;

	    # choice := '(' ch_l ')'
	    $n++ while s/\(\s*<[ad](\d+)>\s*\)/_add
	    (C => 'c', N => $_n++, 
	     S => "(" . join ("|", $_map{$1}->rel) . ")")/eg;
	
	    # ch_l := ( cp | ch_l ) '|' ( cp | ch_l )
	    $n++ while s/<[ad](\d+)>\s*\|\s*<[ad](\d+)>/_add
	    (C => 'd', N => $_n++, 
	     SL => [ $_map{$1}->rel, $_map{$2}->rel ])/eg;

	    # seq := '(' (seq_l ')'
	    $n++ while s/\(\s*<[at](\d+)>\s*\)/_add
	    (C => 's', N => $_n++, 
	     S => "(".join("", $_map{$1}->rel).")")/eg;

	    # seq_l := ( cp | seq_l ) ',' ( cp | seq_l )
	    $n++ while s/<[at](\d+)>\s*,\s*<[at](\d+)>/_add
	    (C => 't', N => $_n++, 
	     SL => [ $_map{$1}->rel, $_map{$2}->rel ])/eg;
	}
    }

    return 0 if ($rule !~ /^<a(\d+)>$/);

    $self->{Name} = \%_name;
    $self->{RE} = $_map{$1}->re; 

    return 1;
}

sub debug
{
    my ($self) = @_;
    "Children[RE=" . $self->{RE} . "]";
}


package XML::Checker::ARule;
use XML::RegExp;

sub new
{
    my ($class, $elem, $checker) = @_;
    bless { Elem => $elem, Checker => $checker, Required => {} }, $class;
}

sub Attlist
{
    my ($self, $attr, $type, $default, $fixed, $checker) = @_;
    my ($c1, $c2);

    if ($self->{Defined}->{$attr})
    {
	my $tag = $self->{Elem};
	$self->fail ($attr, 110, "attribute [$attr] of element [$tag] already defined");
    }
    else
    {
	$self->{Defined}->{$attr} = 1;
    }

    if ($default =~ /^\#(REQUIRED|IMPLIED)$/)
    {
	$c1 = $1;

	# Keep list of all required attributes
	if ($default eq '#REQUIRED')
	{
	    $self->{Required}->{$attr} = 1;
	}
    }
    else
    {
	$self->fail ($attr, 122, "invalid default attribute value [$default]")
	    unless $default =~ /^$XML::RegExp::AttValue$/;
				   
	$default = substr ($default, 1, length($default)-2);
	$self->{Default}->{$attr} = $default;
	$c1 = 'FIXED' if $fixed;
    }

    if ($type eq 'ID')
    {
	$self->fail ($attr, 123, "invalid default ID [$default], must be #REQUIRED or #IMPLIED")
	    unless $default =~ /^#(REQUIRED|IMPLIED)$/;

	if (exists ($self->{ID}) && $self->{ID} ne $attr)
	{
	    $self->fail ($attr, 151, "only one ID allowed per ELEMENT " .
			 "first=[" . $self->{ID} . "]");
	}
	else
	{
	    $self->{ID} = $attr;
	}
	$c2 = 'ID';
    }
    elsif ($type =~ /^(IDREF|IDREFS|ENTITY|ENTITIES|NMTOKEN|NMTOKENS)$/)
    {
	my $def = $self->{Default}->{$attr};
	if (defined $def)
	{
	    my $re = ($type =~ /^[IE]/) ? $XML::RegExp::Name : $XML::RegExp::NmToken;
	    if ($type =~ /S$/)
	    {
		for (split (/\s+/, $def))
		{
		    $self->fail ($attr, 121,
				 "invalid default [$_] in $type [$def]")
			unless $_ =~ /^$re$/;
		}
	    }
	    else	# singular
	    {
		$self->fail ($attr, 120, "invalid default $type [$def]")
			unless $def =~ /^$re$/;
	    }
	}
	$c2 = $type;
    }
    elsif ($type ne 'CDATA')	# Enumerated := NotationType | Enumeration
    {
	if ($type =~ /^\s*NOTATION\s*\(\s*($XML::RegExp::Name(\s*\|\s*$XML::RegExp::Name)*)\s*\)\s*$/)
	{
	    $self->fail ($attr, 135, "empty NOTATION list in ATTLIST")
		unless defined $1;

	    my @tok = split (/\s*\|\s*/, $1);
	    for (@tok)
	    {
		$self->fail ($attr, 100, "undefined NOTATION [$_] in ATTLIST")
			unless exists $checker->{NOTATION}->{$_};
	    }

	    my $re = join ("|", @tok);
	    $self->{NotationRE} = "^($re)\$";
	    $c2 = 'NotationType';
	}
	elsif ($type =~ /^\s*\(\s*($XML::RegExp::NmToken(\s*\|\s*$XML::RegExp::NmToken)*)\s*\)\s*$/)
	{
	    # Enumeration

	    $self->fail ($attr, 136, "empty Enumeration list in ATTLIST")
		    unless defined $1;

	    my @tok = split (/\s*\|\s*/, $1);
	    for (@tok)
	    {
		$self->fail ($attr, 134,
			     "invalid Enumeration value [$_] in ATTLIST")
		unless $_ =~ /^$XML::RegExp::NmToken$/;
	    }
	    $self->{EnumRE}->{$attr} = '^(' . join ("|", @tok) . ')$'; #';
	    $c2 = 'Enumeration';
	}
	else
	{
	    $self->fail ($attr, 137, "invalid ATTLIST type [$type]");
	}
    }

    $self->{Check1}->{$attr} = $c1 if $c1;
    $self->{Check2}->{$attr} = $c2 if $c2;
}

sub fail
{
    my $self = shift;
    my $attr = shift;
    $self->{Checker}->fail (@_, Element => $self->{Elem}, Attr => $attr);
}

sub check
{
    my ($self, $attr) = @_;
    my $func1 = $self->{Check1}->{$attr};
    my $func2 = $self->{Check2}->{$attr};
#    print "check func1=$func1 func2=$func2 @_\n";

    if (exists $self->{ReqNotSeen}->{$attr})
    {
	delete $self->{ReqNotSeen}->{$attr};
    }
    no strict;

    &$func1 (@_) if defined $func1;
    &$func2 (@_) if defined $func2;
}

# Copies the list of all required attributes from $self->{Required} to
# $self->{ReqNotSeen}. 
# When check() encounters a required attribute, it is removed from ReqNotSeen. 
# In EndAttr we look at which attribute names are still in ReqNotSeen - those
# are the ones that were not specified and are, therefore, in error.
sub StartAttr
{
    my $self = shift;
    my %not_seen = %{ $self->{Required} };
    $self->{ReqNotSeen} = \%not_seen;
}

# Checks which of the #REQUIRED attributes were not specified
sub EndAttr
{
    my $self = shift;

    for my $attr (keys %{ $self->{ReqNotSeen} })
    {
	$self->fail ($attr, 159, 
		     "unspecified value for \#REQUIRED attribute [$attr]");
    }
}

sub FIXED
{
    my ($self, $attr, $val, $specified) = @_;

    my $default = $self->{Default}->{$attr};
    $self->fail ($attr, 150, 
		 "bad \#FIXED attribute value [$val], it should be [$default]")
	unless ($val eq $default);
}

sub IMPLIED
{
    my ($self, $attr, $val, $specified) = @_;

#?? should #IMPLIED be specified?
    $self->fail ($attr, 158, 
		 "unspecified value for \#IMPLIED attribute [$attr]")
	unless $specified;

#?? Implied handler ?
}

# This is called when an attribute is passed to the check() method by
# XML::Checker::Attr(), i.e. when the attribute was specified explicitly
# or defaulted by the parser (which should never happen), *NOT* when the 
# attribute was omitted. (The latter is checked by StartAttr/EndAttr)
sub REQUIRED
{
    my ($self, $attr, $val, $specified) = @_;
#    print "REQUIRED attr=$attr val=$val spec=$specified\n";

    $self->fail ($attr, 159, 
		 "unspecified value for \#REQUIRED attribute [$attr]")
	unless $specified;
}

sub ID		# must be #IMPLIED or #REQUIRED
{
    my ($self, $attr, $val, $specified) = @_;

    $self->fail ($attr, 131, "invalid ID [$val]")
	unless $val =~ /^$XML::RegExp::Name$/;

    $self->fail ($attr, 111, "ID [$val] already defined")
	if $self->{Checker}->{ID}->{$val}++;
}

sub IDREF
{
    my ($self, $attr, $val, $specified) = @_;
    
    $self->fail ($attr, 132, "invalid IDREF [$val]")
	unless $val =~ /^$XML::RegExp::Name$/;

    $self->{Checker}->{IDREF}->{$val}++;
}

sub IDREFS
{
    my ($self, $attr, $val, $specified) = @_;
    for (split /\s+/, $val)
    {
	$self->IDREF ($attr, $_);
    }
}

sub ENTITY
{
    my ($self, $attr, $val, $specified) = @_;
#?? should it be specified?

    $self->fail ($attr, 133, "invalid ENTITY name [$val]")
	unless $val =~ /^$XML::RegExp::Name$/;

    $self->fail ($attr, 102, "undefined unparsed ENTITY [$val]")
	unless exists $self->{Checker}->{Unparsed}->{$val};
}

sub ENTITIES
{
    my ($self, $attr, $val, $specified) = @_;
    for (split /\s+/, $val)
    {
	$self->ENTITY ($attr, $_);
    }
}

sub NMTOKEN
{
    my ($self, $attr, $val, $specified) = @_;
    $self->fail ($attr, 130, "invalid NMTOKEN [$val]")
	unless $val =~ /^$XML::RegExp::NmToken$/;
}

sub NMTOKENS
{
    my ($self, $attr, $val, $specified) = @_;
    for (split /\s+/, $val)
    {
	$self->NMTOKEN ($attr, $_, $specified);
    }
}

sub Enumeration
{
    my ($self, $attr, $val, $specified) = @_;
    my $re = $self->{EnumRE}->{$attr};
    
    $self->fail ($attr, 160, "invalid Enumeration value [$val]")
	unless $val =~ /$re/;
}

sub NotationType
{
    my ($self, $attr, $val, $specified) = @_;
    my $re = $self->{NotationRE};

    $self->fail ($attr, 161, "invalid NOTATION value [$val]")
	unless $val =~ /$re/;

    $self->fail ($attr, 162, "undefined NOTATION [$val]")
	unless exists $self->{Checker}->{NOTATION}->{$val};
}

package XML::Checker;
use vars qw ( $VERSION $FAIL $INSIGNIF_WS );

BEGIN 
{ 
    $VERSION = '0.13'; 
}

$FAIL = \&print_error;

# Whether the last seen Char data was insignicant whitespace
$INSIGNIF_WS = 0;

sub new
{
    my ($class, %args) = @_;

    $args{ERule} = {};
    $args{ARule} = {};
    $args{InCDATA} = 0;

    #$args{Debug} = 1;
    bless \%args, $class;
}

# PerlSAX API
sub element_decl
{
    my ($self, $hash) = @_;
    $self->Element ($hash->{Name}, $hash->{Model});
}

# Same parameter order as the Element handler in XML::Parser module
sub Element
{
    my ($self, $name, $model) = @_;
    
    if (defined $self->{ERule}->{$name})
    {
	$self->fail (115, "ELEMENT [$name] already defined",
		     Element => $name);
    }

    if ($model eq "EMPTY")
    {
	$self->{ERule}->{$name} = new XML::Checker::ERule::EMPTY;
    }
    elsif ($model eq "ANY")
    {
	$self->{ERule}->{$name} = new XML::Checker::ERule::ANY;
    }
    elsif ($model =~ /#PCDATA/)
    {
        my $rule = new XML::Checker::ERule::Mixed;
	if ($rule->setModel ($model))
        {
	    $self->{ERule}->{$name} = $rule;
	}
        else
        {
	    $self->fail (124, "bad model [$model] for ELEMENT [$name]",
			 Element => $name);
	}
    }
    else
    {
        my $rule = new XML::Checker::ERule::Children;
	if ($rule->setModel ($model))
        {
	    $self->{ERule}->{$name} = $rule;
	}
        else
        {
	    $self->fail (124, "bad model [$model] for ELEMENT [$name]",
			 Element => $name);
	}
    }
    my $rule = $self->{ERule}->{$name};
    print "added ELEMENT model for $name: " . $rule->debug . "\n"
	   if $rule and $self->{Debug};
}

# PerlSAX API
sub attlist_decl
{
    my ($self, $hash) = @_;
    $self->Attlist ($hash->{ElementName}, $hash->{AttributeName},
		    $hash->{Type}, $hash->{Default}, $hash->{Fixed});
}

sub Attlist
{ 
    my ($self, $tag, $attrName, $type, $default, $fixed) = @_;
    my $arule = $self->{ARule}->{$tag} ||= 
	new XML::Checker::ARule ($tag, $self);

    $arule->Attlist ($attrName, $type, $default, $fixed, $self);
}

# Initializes the context stack to check an XML::DOM::Element
sub InitDomElem
{
    my $self = shift;

    # initialize Context stack
    $self->{Context} = [ new XML::Checker::Context::ANY ($self) ];
    $self->{InCDATA} = 0;
}

# Clears the context stack after checking an XML::DOM::Element
sub FinalDomElem
{
    my $self = shift;
    delete $self->{Context};
}

# PerlSAX API
sub start_document
{
    shift->Init;
}

sub Init
{
    my $self = shift;

    # initialize Context stack
    $self->{Context} = [ new XML::Checker::DocContext ($self) ];
    $self->{InCDATA} = 0;
}

# PerlSAX API
sub end_document
{
    shift->Final;
}

sub Final
{
    my $self = shift;
#?? could add more statistics: unreferenced Unparsed, ID

    for (keys %{ $self->{IDREF} })
    {
	my $n = $self->{IDREF}->{$_};
	$self->fail (200, "undefined ID [$_] was referenced [$n] times")
	    unless defined $self->{ID}->{$_};
    }

    for (keys %{ $self->{ID} })
    {
	my $n = $self->{IDREF}->{$_} || 0;
	$self->fail (300, "[$n] references to ID [$_]");
    }

    delete $self->{Context};
}

sub getRootElement
{
    my $self = shift;
#    print "getRoot $self " . $self->{RootElement} . "\n";
    $_[0]->{RootElement};
}

# PerlSAX API
sub doctype_decl
{
    my ($self, $hash) = @_;
    $self->Doctype ($hash->{Name}, $hash->{SystemId},
		    $hash->{PublicId}, $hash->{Internal});
}

sub Doctype
{
    my ($self, $name, $sysid, $pubid, $internal) = @_;
    $self->{RootElement} = $name;

    my $context = $self->{Context}->[0];
    $context->setRootElement ($name);

#?? what else
}

sub Attr
{
    my ($self, $tag, $attr, $val, $specified) = @_;

#print "Attr for tag=$tag attr=$attr val=$val spec=$specified\n";

    my $arule = $self->{ARule}->{$tag};
    if (defined $arule && $arule->{Defined}->{$attr})
    {
	$arule->check ($attr, $val, $specified);
    }
    else
    {
	$self->fail (103, "undefined attribute [$attr]", Element => $tag);
    }
}

sub EndAttr
{
    my $self = shift;

    my $arule = $self->{CurrARule};
    if (defined $arule)
    {
	$arule->EndAttr;
    }
}

# PerlSAX API
sub start_element
{
    my ($self, $hash) = @_;
    my $tag = $hash->{Name};
    my $attr = $hash->{Attributes};

    $self->Start ($tag);

    if (exists $hash->{AttributeOrder})
    {
	my $defaulted = $hash->{Defaulted};
	my @order = @{ $hash->{AttributeOrder} };

	# Specified attributes
	for (my $i = 0; $i < $defaulted; $i++)
	{
	    my $a = $order[$i];
	    $self->Attr ($tag, $a, $attr->{$a}, 1);
	}

	# Defaulted attributes
	for (my $i = $defaulted; $i < @order; $i++)
	{
	    my $attr = $order[$i];
	    $self->Attr ($tag, $a, $attr->{$a}, 0);
	}
    }
    else
    {
	# Assume all attributes were specified
	my @attr = %$attr;
	my ($key, $val);
	while ($key = shift @attr)
	{
	    $val = shift @attr;
	    
	    $self->Attr ($tag, $key, $val, 1);
	}
    }
    $self->EndAttr;
}

sub Start
{
    my ($self, $tag) = @_;
#?? if first tag, check with root element - or does expat check this already?

    my $context = $self->{Context};
    $context->[0]->Start ($self, $tag);

    my $erule = $self->{ERule}->{$tag};
    if (defined $erule)
    {
	unshift @$context, $erule->context;
    }
    else
    {
	# It's not a real error according to the XML Spec.
	$self->fail (101, "undefined ELEMENT [$tag]");
	unshift @$context, new XML::Checker::Context::ANY;
    }

#?? what about ARule ??
    my $arule = $self->{ARule}->{$tag};
    if (defined $arule)
    {
	$self->{CurrARule} = $arule;
	$arule->StartAttr;
    }
}

# PerlSAX API
sub end_element
{
    shift->End;
}

sub End
{
    my ($self) = @_;
    my $context = $self->{Context};

    $context->[0]->End ($self);
    shift @$context;
}

# PerlSAX API
sub characters
{
    my ($self, $hash) = @_;
    my $data = $hash->{Data};

    if ($self->{InCDATA})
    {
	$self->CData ($data);
    }
    else
    {
	$self->Char ($data);
    }
}

# PerlSAX API
sub start_cdata
{
    $_[0]->{InCDATA} = 1;
}

# PerlSAX API
sub end_cdata
{
    $_[0]->{InCDATA} = 0;
}

sub Char
{
    my ($self, $text) = @_;
    my $context = $self->{Context};

    # NOTE: calls to isWS may set this to 1.
    $INSIGNIF_WS = 0;

    $context->[0]->Char ($self, $text);
}

# Treat CDATASection same as Char (Text)
sub CData
{
    my ($self, $cdata) = @_;
    my $context = $self->{Context};

    $context->[0]->Char ($self, $cdata);

    # CDATASection can never be insignificant whitespace
    $INSIGNIF_WS = 0;
#?? I'm not sure if this assumption is correct
}

# PerlSAX API
sub comment
{
    my ($self, $hash) = @_;
    $self->Comment ($hash->{Data});
}

sub Comment
{
# ?? what can be checked here?
}

# PerlSAX API
sub entity_reference
{
    my ($self, $hash) = @_;
    $self->EntityRef ($hash->{Name}, 0);
#?? parameter entities (like %par;) are NOT supported!
# PerlSAX::handle_default should be fixed!
}

sub EntityRef
{
    my ($self, $ref, $isParam) = @_;

    if ($isParam)
    {
	# expand to "%name;"
	print STDERR "XML::Checker::Entity -  parameter Entity (%ent;) not implemented\n";
    }
    else
    {
	# Treat same as Char - for now
	my $context = $self->{Context};
	$context->[0]->Char ($self, "&$ref;");
	$INSIGNIF_WS = 0;
#?? I could count the number of times each Entity is referenced
    }
}

# PerlSAX API
sub unparsed_entity_decl
{
    my ($self, $hash) = @_;
    $self->Unparsed ($hash->{Name});
#?? what about Base, SytemId, PublicId ?
}

sub Unparsed
{
    my ($self, $entity) = @_;
#    print "ARule::Unparsed $entity\n";
    if ($self->{Unparsed}->{$entity})
    {
	$self->fail (112, "unparsed ENTITY [$entity] already defined");
    }
    else
    {
	$self->{Unparsed}->{$entity} = 1;
    }
}

# PerlSAX API
sub notation_decl
{
    my ($self, $hash) = @_;
    $self->Notation ($hash->{Name});
#?? what about Base, SytemId, PublicId ?
}

sub Notation
{
    my ($self, $notation) = @_;
    if ($self->{NOTATION}->{$notation})
    {
	$self->fail (113, "NOTATION [$notation] already defined");
    }
    else
    {
	$self->{NOTATION}->{$notation} = 1;
    }
}

# PerlSAX API
sub entity_decl
{
    my ($self, $hash) = @_;

    $self->Entity ($hash->{Name}, $hash->{Value}, $hash->{SystemId},
		   $hash->{PublicId}, $hash->{'Notation'});
}

sub Entity
{
    my ($self, $name, $val, $sysId, $pubId, $ndata) = @_;

    if (exists $self->{ENTITY}->{$name})
    {
	$self->fail (114, "ENTITY [$name] already defined");
    }
    else
    {
	$self->{ENTITY}->{$name} = $val;
    }    
}

# PerlSAX API
#sub xml_decl {} $hash=> Version, Encoding, Standalone
# Don't implement resolve_entity() which is called by ExternEnt!
#sub processing_instruction {} $hash=> Target, Data

# Returns whether the Char data is whitespace and also updates the
# $INSIGNIF_WS variable to indicate whether it is insignificant whitespace.
# Note that this method is only called in places where potential whitespace
# can be insignificant (i.e. when the ERule is Children or EMPTY)
sub isWS
{
  # pverdret: why not /\A\s+\Z/ ???
  $INSIGNIF_WS = ($_[1] =~ /^\s*$/);
}

sub isInsignifWS
{
    $INSIGNIF_WS;
}

sub fail
{
    my $self = shift;
    &$FAIL (@_);
}

sub print_error		# static
{
    my $str = error_string (@_);
    print STDERR $str;
}

sub error_string	# static
{
    my $code = shift;
    my $msg = shift;

    my @a = ();
    my ($key, $val);
    while ($key = shift)
    {
	$val = shift;
	push @a, ("$key " . (defined $val ? $val : "(undef)"));
    }

    my $cat = $code >= 200 ? ($code >= 300 ? "INFO" : "WARNING") : "ERROR";
    my $str = join (", ", @a);
    $str = length($str) ? "\tContext: $str\n" : "";

    "XML::Checker $cat-$code: $msg\n$str";
}

sub debug
{
    my ($self) = @_;
    my $context = $self->{Context}->[0];
    my $c = $context ? $context->debug : "no context";
    my $root = $self->{RootElement};

    "Checker[$c,RootElement=$root]";
}

1; # package return code

__END__

=head1 NAME

XML::Checker - A perl module for validating XML

=head1 SYNOPSIS

L<XML::Checker::Parser> - an L<XML::Parser> that validates at parse time

L<XML::DOM::ValParser> - an L<XML::DOM::Parser> that validates at parse time

(Some of the package names may change! This is only an alpha release...)

=head1 DESCRIPTION

XML::Checker can be used in different ways to validate XML. See the manual
pages of L<XML::Checker::Parser> and L<XML::DOM::ValParser>
for more information. 

This document only describes common topics like error handling
and the XML::Checker class itself.

WARNING: Not all errors are currently checked. Almost everything is subject to
change. Some reported errors may not be real errors.  For production code,
it is recommended that you use L<XML::LibXML> or L<XML::GDOME> instead of
L<XML::Checker>.  Both modules share the same DTD validation code with libxml2
and L<XML::LibXML> is easier to install.

=head1 ERROR HANDLING

Whenever XML::Checker (or one of the packages that uses XML::Checker) detects a
potential error, the 'fail handler' is called. It is currently also called 
to report information, like how many times an Entity was referenced. 
(The whole error handling mechanism is subject to change, I'm afraid...)

The default fail handler is XML::Checker::print_error(), which prints an error 
message to STDERR. It does not stop the XML::Checker, so it will continue 
looking for other errors. 
The error message is created with XML::Checker::error_string().

You can define your
own fail handler in two ways, locally and globally. Use a local variable to
temporarily override the fail handler. This way the default fail handler is restored
when the local variable goes out of scope, esp. when exceptions are thrown e.g.

 # Using a local variable to temporarily override the fail handler (preferred)
 { # new block - start of local scope
   local $XML::Checker::FAIL = \&my_fail;
   ... your code here ...
 } # end of block - the previous fail handler is restored

You can also set the error handler globally, risking that your code may not 
be reusable or may clash with other modules that use XML::Checker.

 # Globally setting the fail handler (not recommended)
 $XML::Checker::FAIL = \&my_fail;
 ... rest of your code ...

The fail handler is called with the following parameters ($code, $msg, @context), 
where $code is the error code, $msg is the error description and 
@context contains information on where the error occurred. The @context is
a (ordered) list of (key,value) pairs and can easily be turned into a hash.
It contains the following information:

 Element - tag name of Element node (if applicable)
 Attr - attribute name (if applicable)
 ChildElementIndex - if applicable (see error 157)
 line - only when parsing
 column - only when parsing
 byte - only when parsing (-1 means: end of file)

Some examples of fail handlers:

 # Don't print info messages
 sub my_fail
 {
     my $code = shift;
     print STDERR XML::Checker::error_message ($code, @_)
         if $code < 300;
 }

 # Die when the first error is encountered - this will stop
 # the parsing process. Ignore information messages.
 sub my_fail
 {
     my $code = shift;
     die XML::Checker::error_message ($code, @_) if $code < 300;
 }

 # Count the number of undefined NOTATION references
 # and print the error as usual
 sub my_fail
 {
     my $code = shift;
     $count_undef_notations++ if $code == 100;
     XML::Checker::print_error ($code, @_);
 }

 # Die when an error is encountered.
 # Don't die if a warning or info message is encountered, just print a message.
 sub my_fail {
     my $code = shift;
     die XML::Checker::error_string ($code, @_) if $code < 200;
     XML::Checker::print_error ($code, @_);
 }

=head1 INSIGNIFICANT WHITESPACE

XML::Checker keeps track of whether whitespace found in character data 
is significant or not. It is considered insignicant if it is found inside
an element that has a ELEMENT rule that is not of type Mixed or of type ANY. 
(A Mixed ELEMENT rule does contains the #PCDATA keyword. 
An ANY rule contains the ANY keyword. See the XML spec for more info.)

XML::Checker can not determine whether whitespace is insignificant in those two 
cases, because they both allow regular character data to appear within
XML elements and XML::Checker can therefore not deduce whether whitespace 
is part of the actual data or was just added for readability of the XML file.

XML::Checker::Parser and XML::DOM::ValParser both have the option to skip
insignificant whitespace when setting B<SkipInsignifWS> to 1 in their constructor.
If set, they will not call the Char handler when insignificant whitespace is
encountered. This means that in XML::DOM::ValParser no Text nodes are created
for insignificant whitespace.

Regardless of whether the SkipInsignifWS options is set, XML::Checker always 
keeps track of whether whitespace is insignificant. After making a call to
XML::Checker's Char handler, you can find out if it was insignificant whitespace
by calling the isInsignifWS method.

When using multiple (nested) XML::Checker instances or when using XML::Checker
without using XML::Checker::Parser or XML::DOM::ValParser (which hardly anybody
probably will), make sure to set a local variable in the scope of your checking
code, e.g.

  { # new block - start of local scope
    local $XML::Checker::INSIGNIF_WS = 0;
    ... insert your code here ...
  } # end of scope

=head1 ERROR CODES

There are 3 categories, errors, warnings and info messages.
(The codes are still subject to change, as well the error descriptions.) 

Most errors have a link to the appropriate Validaty Constraint (B<VC>)
or other section in the XML specification.

=head2 ERROR Messages

=head2 100 - 109

=over 4

=item *

B<100> - undefined NOTATION [$notation] in ATTLIST

The ATTLIST contained a Notation reference that was not defined in a
NOTATION definition. 
B<VC:> L<Notation Attributes|http://www.w3.org/TR/REC-xml#notatn>
 

=item *

B<101> - undefined ELEMENT [$tagName]

The specified Element was never defined in an ELEMENT definition.
This is not an error according to the XML spec.
See L<Element Type Declarations|http://www.w3.org/TR/REC-xml#elemdecls>
 

=item *

B<102> - undefined unparsed ENTITY [$entity]

The attribute value referenced an undefined unparsed entity.
B<VC:> L<Entity Name|http://www.w3.org/TR/REC-xml#entname>
 

=item *

B<103> - undefined attribute [$attrName]

The specified attribute was not defined in an ATTLIST for that Element.
B<VC:> L<Attribute Value Type|http://www.w3.org/TR/REC-xml#ValueType>
 

=back

=head2 110 - 119

=over 4

=item *

B<110> - attribute [$attrName] of element [$tagName] already defined

The specified attribute was already defined in this ATTLIST definition or
in a previous one.
This is not an error according to the XML spec.
See L<Attribute-List Declarations|http://www.w3.org/TR/REC-xml#attdecls>
 

=item *

B<111> - ID [$value] already defined

An ID with the specified value was already defined in an attribute
within the same document.
B<VC:> L<ID|http://www.w3.org/TR/REC-xml#id>
 

=item *

B<112> - unparsed ENTITY [$entity] already defined

This is not an error according to the XML spec.
See L<Entity Declarations|http://www.w3.org/TR/REC-xml#sec-entity-decl>
 

=item *

B<113> - NOTATION [$notation] already defined
 

=item *

B<114> - ENTITY [$entity] already defined

This is not an error according to the XML spec.
See L<Entity Declarations|http://www.w3.org/TR/REC-xml#sec-entity-decl>
 

=item *

B<115> - ELEMENT [$name] already defined
B<VC:> L<Unique Element Type Declaration|http://www.w3.org/TR/REC-xml#EDUnique>
 

=back

=head2 120 - 129

=over 4

=item *

B<120> - invalid default ENTITY [$default]

(Or IDREF or NMTOKEN instead of ENTITY.)
The ENTITY, IDREF or NMTOKEN reference in the default attribute 
value for an attribute with types ENTITY, IDREF or NMTOKEN was not
valid.
B<VC:> L<Attribute Default Legal|http://www.w3.org/TR/REC-xml#defattrvalid>
 

=item *

B<121> - invalid default [$token] in ENTITIES [$default]

(Or IDREFS or NMTOKENS instead of ENTITIES)
One of the ENTITY, IDREF or NMTOKEN references in the default attribute 
value for an attribute with types ENTITIES, IDREFS or NMTOKENS was not
valid.
B<VC:> L<Attribute Default Legal|http://www.w3.org/TR/REC-xml#defattrvalid>
 

=item *

B<122> - invalid default attribute value [$default]

The specified default attribute value is not a valid attribute value.
B<VC:> L<Attribute Default Legal|http://www.w3.org/TR/REC-xml#defattrvalid>
 

=item *

B<123> - invalid default ID [$default], must be #REQUIRED or #IMPLIED

The default attribute value for an attribute of type ID has to be 
#REQUIRED or #IMPLIED.
B<VC:> L<ID Attribute Default|http://www.w3.org/TR/REC-xml#id-default>
 

=item *

B<124> - bad model [$model] for ELEMENT [$name]

The model in the ELEMENT definition did not conform to the XML syntax 
for Mixed models.
See L<Mixed Content|http://www.w3.org/TR/REC-xml#sec-mixed-content>
 

=back

=head2 130 - 139

=over 4

=item *

B<130> - invalid NMTOKEN [$attrValue]

The attribute value is not a valid NmToken token.
B<VC:> L<Enumeration|http://www.w3.org/TR/REC-xml#enum>
 

=item *

B<131> - invalid ID [$attrValue]

The specified attribute value is not a valid Name token.
B<VC:> L<ID|http://www.w3.org/TR/REC-xml#id>
 

=item *

B<132> - invalid IDREF [$value]

The specified attribute value is not a valid Name token.  
B<VC:> L<IDREF|http://www.w3.org/TR/REC-xml#idref>
 

=item *

B<133> - invalid ENTITY name [$name]

The specified attribute value is not a valid Name token.  
B<VC:> L<Entity Name|http://www.w3.org/TR/REC-xml#entname>
 

=item *

B<134> - invalid Enumeration value [$value] in ATTLIST

The specified value is not a valid NmToken (see XML spec for def.)
See definition of L<NmToken|http://www.w3.org/TR/REC-xml#NT-Nmtoken>
 

=item *

B<135> - empty NOTATION list in ATTLIST

The NOTATION list of the ATTLIST definition did not contain any NOTATION
references.
See definition of L<NotationType|http://www.w3.org/TR/REC-xml#NT-NotationType>
 

=item *

B<136> - empty Enumeration list in ATTLIST

The ATTLIST definition of the attribute of type Enumeration did not
contain any values.
See definition of L<Enumeration|http://www.w3.org/TR/REC-xml#NT-Enumeration>
 

=item *

B<137> - invalid ATTLIST type [$type]

The attribute type has to be one of: ID, IDREF, IDREFS, ENTITY, ENTITIES, 
NMTOKEN, NMTOKENS, CDATA, NOTATION or an Enumeration.
See definition of L<AttType|http://www.w3.org/TR/REC-xml#NT-AttType>
 

=back

=head2 149 - 159

=over 4

=item *

B<149> - invalid text content [$value]

A text was found in an element that should only include sub-elements
The text is not made of non-significant whitespace.

B<150> - bad #FIXED attribute value [$value], it should be [$default]

The specified attribute was defined as #FIXED in the ATTLIST definition
and the found attribute $value differs from the specified $default value.
B<VC:> L<Fixed Attribute Default|http://www.w3.org/TR/REC-xml#FixedAttr>


=item *

B<151> - only one ID allowed in ATTLIST per element first=[$attrName]

The ATTLIST definitions for an Element may contain only one attribute
with the type ID. The specified $attrName is the one that was found first.
B<VC:> L<One ID per Element Type|http://www.w3.org/TR/REC-xml#one-id-per-el>


=item *

B<152> - Element should be EMPTY, found Element [$tagName]

The ELEMENT definition for the specified Element said it should be
EMPTY, but a child Element was found.
B<VC:> L<Element Valid (sub1)|http://www.w3.org/TR/REC-xml#elementvalid>
 

=item *

B<153> - Element should be EMPTY, found text [$text]

The ELEMENT definition for the specified Element said it should be
EMPTY, but text was found. Currently, whitespace is not allowed between the
open and close tag. (This may be wrong, please give feedback.)
To allow whitespace (subject to change), set:

    $XML::Checker::Context::EMPTY::ALLOW_WHITE_SPACE = 1;

B<VC:> L<Element Valid (sub1)|http://www.w3.org/TR/REC-xml#elementvalid>
 

=item *

B<154> - bad order of Elements Found=[$found] RE=[$re]

The child elements of the specified Element did not match the
regular expression found in the ELEMENT definition. $found contains
a comma separated list of all the child element tag names that were found.
$re contains the (decoded) regular expression that was used internally.
B<VC:> L<Element Valid|http://www.w3.org/TR/REC-xml#elementvalid>
 

=item *

B<155> - more than one root Element [$tags]

An XML Document may only contain one Element.
$tags is a comma separated list of element tag names encountered sofar.
L<XML::Parser> (expat) throws 'no element found' exception.
See two_roots.xml for an example.
See definition of L<document|http://www.w3.org/TR/REC-xml#dt-root>
 

=item *

B<156> - unexpected root Element [$tagName], expected [$rootTagName]

The tag name of the root Element of the XML Document differs from the name 
specified in the DOCTYPE section.
L<XML::Parser> (expat) throws 'not well-formed' exception.
See bad_root.xml for an example.
B<VC:> L<Root Element Type|http://www.w3.org/TR/REC-xml#vc-roottype>
 

=item *

B<157> - unexpected Element [$tagName]

The ELEMENT definition for the specified Element does not allow child
Elements with the specified $tagName.
B<VC:> L<Element Valid|http://www.w3.org/TR/REC-xml#elementvalid>

The error context contains ChildElementIndex which is the index within 
its parent Element (counting only Element nodes.)
 

=item *

B<158> - unspecified value for #IMPLIED attribute [$attrName]

The ATTLIST for the specified attribute said the attribute was #IMPLIED,
which means the user application should supply a value, but the attribute
value was not specified. (User applications should pass a value and set
$specified to 1 in the Attr handler.)
 

=item *

B<159> - unspecified value for #REQUIRED attribute [$attrName]

The ATTLIST for the specified attribute said the attribute was #REQUIRED,
which means that a value should have been specified.
B<VC:> L<Required Attribute|http://www.w3.org/TR/REC-xml#RequiredAttr>
 

=back

=head2 160 - 169

=over 4

=item *

B<160> - invalid Enumeration value [$attrValue]

The specified attribute value does not match one of the Enumeration values
in the ATTLIST.
B<VC:> L<Enumeration|http://www.w3.org/TR/REC-xml#enum>
 

=item *

B<161> - invalid NOTATION value [$attrValue]

The specifed attribute value was not found in the list of possible NOTATION 
references as found in the ATTLIST definition.
B<VC:> L<Notation Attributes|http://www.w3.org/TR/REC-xml#notatn>
 

=item *

B<162> - undefined NOTATION [$attrValue]

The NOTATION referenced by the specified attribute value was not defined.
B<VC:> L<Notation Attributes|http://www.w3.org/TR/REC-xml#notatn>
 

=back

=head2 WARNING Messages (200 and up)

=over 4

=item *

B<200> - undefined ID [$id] was referenced [$n] times

The specified ID was referenced $n times, but never defined in an attribute
value with type ID.
B<VC:> L<IDREF|http://www.w3.org/TR/REC-xml#idref>
 

=back

=head2 INFO Messages (300 and up)

=over 4

=item *

B<300> - [$n] references to ID [$id]

The specified ID was referenced $n times.
 

=back

=head2 Not checked

The following errors are already checked by L<XML::Parser> (expat) and
are currently not checked by XML::Checker:

(?? TODO - add more info)

=over 4

=item root element is missing

L<XML::Parser> (expat) throws 'no element found' exception. 
See no_root.xml for an example.

=back

=head1 XML::Checker

XML::Checker can be easily plugged into your application. 
It uses mostly the same style of event handlers (or callbacks) as L<XML::Parser>.
See L<XML::Parser> manual page for descriptions of most handlers. 
 
It also implements PerlSAX style event handlers. See L<PerlSAX interface>.

Currently, the XML::Checker object is a blessed hash with the following 
(potentially useful) entries:

 $checker->{RootElement} - root element name as found in the DOCTYPE
 $checker->{NOTATION}->{$notation} - is 1 if the NOTATION was defined
 $checker->{ENTITY}->{$name} - contains the (first) ENTITY value if defined
 $checker->{Unparsed}->{$entity} - is 1 if the unparsed ENTITY was defined
 $checker->{ID}->{$id} - is 1 if the ID was defined
 $checker->{IDREF}->{$id} - number of times the ID was referenced

 # Less useful:
 $checker->{ERule}->{$tag} - the ELEMENT rules by Element tag name
 $checker->{ARule}->{$tag} - the ATTLIST rules by Element tag name
 $checker->{Context} - context stack used internally
 $checker->{CurrARule} - current ATTLIST rule for the current Element

=head2 XML:Checker methods

This section is only interesting when using XML::Checker directly.
XML::Checker supports most event handlers that L<XML::Parser> supports with minor 
differences. Note that the XML::Checker event handler methods are 
instance methods and not static, so don't forget to call them like this,
without passing $expat (as in the L<XML::Parser>) handlers:

 $checker->Start($tagName);

=over 4

=item Constructor

 $checker = new XML::Checker;
 $checker = new XML::Checker (%user_args);

User data may be stored by client applications. Only $checker->{User} is
guaranteed not to clash with internal hash keys.

=item getRootElement ()

 $tagName = $checker->getRootElement;

Returns the root element name as found in the DOCTYPE

=back

=head2 Expat interface

XML::Checker supports what I call the I<Expat> interface, which is 
the collection of methods you normally specify as the callback handlers
when using XML::Parser.

Only the following L<XML::Parser> handlers are currently supported:
Init, Final, Char, Start, End, Element, Attlist, Doctype,
Unparsed, Entity, Notation. 

I don't know how to correctly support the Default handler for all L<XML::Parser>
releases. The Start handler works a little different (see below) and I
added Attr, InitDomElem, FinalDomElem, CDATA and EntityRef handlers.
See L<XML::Parser> for a description of the handlers that are not listed below.

Note that this interface may disappear, when the PerlSAX interface stabilizes.

=over 4

=item Start ($tag)

 $checker->Start($tag);

Call this when an Element with the specified $tag name is encountered.
Different from the Start handler in L<XML::Parser>, in that no attributes 
are passed in (use the Attr handler for those.)

=item Attr ($tag, $attrName, $attrValue, $isSpecified)

 $checker->Attr($tag,$attrName,$attrValue,$spec);

Checks an attribute with the specified $attrName and $attrValue against the
ATTLIST definition of the element with the specified $tag name.
$isSpecified means whether the attribute was specified (1) or defaulted (0).

=item EndAttr ()

 $checker->EndAttr;

This should be called after all attributes are passed with Attr().
It will check which of the #REQUIRED attributes were not specified and generate
the appropriate error (159) for each one that is missing.

=item CDATA ($text)

 $checker->CDATA($text);

This should be called whenever CDATASections are encountered.
Similar to Char handler (but might perform different checks later...)

=item EntityRef ($entity, $isParameterEntity)

 $checker->EntityRef($entity,$isParameterEntity);

Checks the ENTITY reference. Set $isParameterEntity to 1 for 
entity references that start with '%'.

=item InitDomElem () and FinalDomElem ()

Used by XML::DOM::Element::check() to initialize (and cleanup) the 
context stack when checking a single element.

=back

=head2 PerlSAX interface

XML::Checker now also supports the PerlSAX interface, so you can use XML::Checker
wherever you use PerlSAX handlers.

XML::Checker implements the following methods: start_document, end_document,
start_element, end_element, characters, processing_instruction, comment,
start_cdata, end_cdata, entity_reference, notation_decl, unparsed_entity_decl,
entity_decl, element_decl, attlist_decl, doctype_decl, xml_decl

Not implemented: set_document_locator, ignorable_whitespace

See PerlSAX.pod for details. (It is called lib/PerlSAX.pod in the libxml-perl 
distribution which can be found at CPAN.)

=head1 CAVEATS

This is an alpha release.  It is not actively maintained, patches are accepted and
incoporated in new releases, but that's about it.  If you are interested in taking
over maintimance of the module, email tjmather@tjmather.com.

For a much faster, and correct DTD validator, see L<XML::LibXML>.  It
uses the libxml2 library to validate DTD.

=head1 AUTHOR

Enno Derksen is the original author.

Send patches to T.J. Mather at
<F<tjmather@tjmather.com>>. 

=head1 SEE ALSO

L<XML::LibXML> provides validating parsers against a DTD
and is recommended over XML::Checker since it uses the libxml2 library which is
fast and well-tested.

The XML spec (Extensible Markup Language 1.0) at L<http://www.w3.org/TR/REC-xml>

The L<XML::Parser> and L<XML::Parser::Expat> manual pages.

The other packages that come with XML::Checker: 
L<XML::Checker::Parser>, L<XML::DOM::ValParser>

The DOM Level 1 specification at L<http://www.w3.org/TR/REC-DOM-Level-1>

The PerlSAX specification. It is currently in lib/PerlSAX.pod in the
libxml-perl distribution by Ken MacLeod. 

The original SAX specification (Simple API for XML) can be found at 
L<http://www.megginson.com/SAX> and L<http://www.megginson.com/SAX/SAX2>
