# Attibute Definitions:
#
#  name: Text - name of file, dir, ...
#  ext: Text - file extension
#  no_ext: Text - name without ext
#  full: Text - full path name
#  abs: Text - absolute path name
#
#  M,age: Number - Age of file (in days)
#                   [since script started says man(perlfunc)??]
#  cre,create: Date (see age)
#  A,acc_in_days: Number - Last access time in days
#  acc,access: Date (see A)
#    set with utime()
#  f,is_file: Boolean
#  d,is_dir: Boolean
#  l,is_link: Boolean
#  p,is_pipe: Boolean
#  e,exists: Boolean
#  z,is_zero: Boolean - whether size equals zero bytes
#  r,readable: Boolean
#  w,writable: Boolean
#  x,executable: Boolean
#  o,owned: Boolean - whether it is owned (by effective uid)
#
#---------------------------------------------------------------------------
# Todo: 
# - implement abs(): absolute filepath
# - support links: use lstat(), @link 
# - flags: -R,-W,-X,-O (by real uid/gid instead of effective uid,
#          -S (is_socket), -b (block special file), -c (char. special file),
#          -t  Filehandle is opened to a tty.
#          -u  File has setuid bit set.
#          -g  File has setgid bit set.
#          -k  File has sticky bit set.
#          -T  File is a text file.
#          -B  File is a binary file (opposite of -T).
#          -C  inode change time in days.
#              set with utime() ??
#
# stat() fields:
#
#         0 dev      device number of filesystem
#         1 ino      inode number
#         2 mode     file mode  (type and permissions)
#	    add mode_str ??: "rwxr-xr--"
#         3 nlink    number of (hard) links to the file
#         4 uid      numeric user ID of file's owner
#           add uname
#         5 gid      numeric group ID of file's owner
#           add gname
#         6 rdev     the device identifier (special files only)
# x       7 size     total size of file, in bytes
# -       8 atime    last access time since the epoch
# -       9 mtime    last modify time since the epoch
# -      10 ctime    inode change time (NOT creation time!) since the epoch
#        11 blksize  preferred block size for file system I/O
#        12 blocks   actual number of blocks allocated

package XML::XQL::DirXQL;

use strict;
use XML::XQL;
use XML::XQL::Date;

sub dirxql
{
    my ($context, $list, $filepath) = @_;

    $filepath = XML::XQL::toList ($filepath->solve ($context, $list));
    my @result;
    for my $file (@$filepath)
    {
	push @result, XML::XQL::DirDoc->new (Root => $file->xql_toString)->root;
    }
    \@result;
}

XML::XQL::defineFunction ("dirxql", \&XML::XQL::DirXQL::dirxql, 1, 1);

package XML::XQL::DirNode;
# extended by: DirDoc, DirAttr, DirElem (File, Dir), FileContents

use vars qw{ @ISA $SEP };
@ISA = qw{ XML::XQL::Node };

# Directory path separator (default: Unix)
$SEP = "/";

if ((defined $^O and
     $^O =~ /MSWin32/i ||
     $^O =~ /Windows_95/i ||
     $^O =~ /Windows_NT/i) ||
    (defined $ENV{OS} and
     $ENV{OS} =~ /MSWin32/i ||
     $ENV{OS} =~ /Windows_95/i ||
     $ENV{OS} =~ /Windows_NT/i))
{
    $SEP = "\\";	# Win32
}
elsif  ((defined $^O and $^O =~ /MacOS/i) ||
	(defined $ENV{OS} and $ENV{OS} =~ /MacOS/i))
{
    $SEP = ":";		# Mac
}

sub isElementNode { 0 }
sub isTextNode    { 0 }
sub xql_parent    { $_[0]->{Parent} }
#sub xql_document { $_[0]->{Doc} }
sub xml_xqlString { $_[0]->toString }

sub xql
{
    my $self = shift;

    # Odd number of args, assume first is XQL expression without 'Expr' key
    unshift @_, 'Expr' if (@_ % 2 == 1);
    my $query = new XML::XQL::Query (@_);
    $query->solve ($self);
}

sub xql_sortKey
{
    my $key = $_[0]->{SortKey};
    return $key if defined $key;

    $key = XML::XQL::createSortKey ($_[0]->{Parent}->xql_sortKey, 
				    $_[0]->xql_childIndex, 1);
#print "xql_sortKey $_[0] ind=" . $_[0]->xql_childIndex . " key=$key str=" . XML::XQL::keyStr($key) . "\n";
    $_[0]->{SortKey} = $key;
}

sub xql_node
{
    my $self = shift;
    $self->build unless $self->{Built};

    $self->{C};
}

sub getChildIndex
{
    my ($self, $kid) = @_;
    my $i = 0;
    for (@{ $self->xql_node })
    {
	return $i if $kid == $_;
	$i++;
    }
    return -1;
}

sub xql_childIndex
{
    $_[0]->{Parent}->getChildIndex ($_[0]);
}

# As it appears in the XML document
sub xql_xmlString
{
    $_[0]->toString;
#?? impl.
}

sub create_date_from_days
{
    my ($days, $srcNode) = @_;
    my $secs = int (0.5 + $days * 24 * 3600 );

    my $internal = Date::Manip::DateCalc ("today", "- $secs seconds");

    new XML::XQL::Date (SourceNode => $srcNode,
			Internal => $internal,
			String => $internal );
}

#------ WHITESPACE STUFF (DELETE??)

# Find previous sibling that is not a text node with ignorable whitespace
sub xql_prevNonWS
{
    my $self = shift;
    my $parent = $self->{Parent};
    return unless $parent;

    for (my $i = $parent->getChildIndex ($self) - 1; $i >= 0; $i--)
    {
	my $node = $parent->getChildAtIndex ($i);
	return $node unless $node->xql_isIgnorableWS;	# skip whitespace
    }
    undef;
}

# True if it's a Text node with just whitespace and xml::space != "preserve"
sub xql_isIgnorableWS
{
    0;
}

# Whether the node should preserve whitespace
# It should if it has attribute xml:space="preserve"
sub xql_preserveSpace
{
    $_[0]->{Parent}->xql_preserveSpace;
}

#---------------------------------------------------------------------------
package XML::XQL::DirDoc;		# The Document
use vars qw{ @ISA };
@ISA = qw{ XML::XQL::DirNode };

sub new
{
    my ($type, %hash) = @_;
    my $self = bless \%hash, $type;

    $self->{Root} = "." unless exists $self->{Root};

    my $dirname;
    if ($self->{Root} =~ /^(.+)\Q${XML::XQL::DirNode::SEP}\E(.+)$/)
    {
	$self->{Prefix} = $1;
	$dirname = $2;
    }
    else
    {
	$self->{Prefix} = "";
	$dirname = $self->{Root};
    }

    $self->{Dir} = new XML::XQL::Dir (TagName => $dirname, Parent => $self);
    $self->{Built} = 1;

    return $self;
}

sub xql
{
    shift->root->xql (@_);
}

sub root           { $_[0]->{Dir} }

sub isElementNode  { 0 }
sub xql_nodeType   { 9 }
sub xql_childCount { 1 }
sub fullname       { $_[0]->{Prefix} }
sub xql_sortKey    { "" }
sub xql_parent     { undef }
sub xql_nodeName   { "#document" }
sub depth          { 0 }
sub xql_node       { [ $_[0]->{Dir} ] }

sub xql_element
{
    my ($self, $elem) = @_;

    my $dir = $self->{Dir};
    if (defined $elem)
    {
	return [ $dir ] if $dir->{TagName} eq $elem;
    }
    else
    {
	return [ $dir ];
    }
}

# By default the elements in a document don't preserve whitespace
sub xql_preserveSpace
{
    0;
}

sub toString
{
    $_[0]->root->toString;
}

#----------------------------------------------------------------------------
package XML::XQL::DirAttrDef;	# Definitions for DirAttr nodes

sub new
{
    my ($type, %hash) = @_;
    bless \%hash, $type;
}

sub dump
{
    print $_[0]->toString . "\n";
}

sub toString
{
    my $self = shift;
    print "DirAttrDef $self\n";
    my $i = 0;
    for my $attrName ($self->in_order)
    {
	my $a = $self->{$attrName};
	print "[$i] name=$attrName"; $i++;
	print " order=" . $a->{Order};
	print " get=" . $a->{Get} if defined $a->{Get};
	print " set=" . $a->{Set} if defined $a->{Set};
	if (defined $a->{Alias})
	{
	    print " alias=" . join (",", @{ $a->{Alias} });
	}
	print "\n";
    }
    if (defined $self->{'@ALIAS'})
    {
	print "Alias: ";
	my $alias = $self->{'@ALIAS'};
	
	print join (",", map { "$_=" . $alias->{$_} } keys %$alias);
	print "\n";
    }
}

sub clone
{
    my $self = shift;
    my $n = new XML::XQL::DirAttrDef;
    $n->{'@IN_ORDER'} = [ @{ $self->{'@IN_ORDER'} } ];

    for my $a (@{ $self->{'@IN_ORDER'} })
    {
	$n->{$a} = { %{ $self->{$a} } };
	$n->{$a}->{Alias} = [ @{ $self->{$a}->{Alias} } ]
	    if defined $self->{$a}->{Alias};
    }
    $n->{'@ALIAS'} = { %{ $self->{'@ALIAS'} } }
	    if defined $self->{'@ALIAS'};

    return $n;
}

sub in_order { defined $_[0]->{'@IN_ORDER'} ? @{ $_[0]->{'@IN_ORDER'} } : () }
sub alias    { $_[0]->{'@ALIAS'}->{$_[1]} }
sub order    { $_[0]->{$_[1]}->{Order} }
sub get      { $_[0]->{$_[1]}->{Get} }
sub set      { $_[0]->{$_[1]}->{Set} }

sub remove_attr
{
    my ($self, $name) = @_;
    next unless defined $self->{$name};

    my $order = $self->{$name}->{Order};
    my @in_order = $self->in_order;
    splice @in_order, $order, 1;
    
    # Reassign Order numbers
    for (my $i = 0; $i < @in_order; $i++)
    {
	$self->{$name}->{Order} = $i;
    }
    $self->{'@IN_ORDER'} = \@in_order;
    
    delete $self->{$name};
}

sub define_attr
{
    my ($self, %hash) = @_;
    my $name = $hash{Name};

    if (defined $self->{$name})
    {
	$hash{Order} = $self->{$name}->{Order} unless defined $hash{Order};
	$self->remove_attr ($name);
    }

    my @in_order = $self->in_order;
    $hash{Order} = -1
	if $hash{Order} >= @in_order;
    
    if ($hash{Order} == -1)
    {
	push @in_order, $name;
    }
    else
    {
	splice @in_order, $hash{Order}, 0, $name;
    }
    $self->{$name} = \%hash;

    # Reassign Order numbers
    for (my $i = 0; $i < @in_order; $i++)
    {
	$self->{$name}->{Order} = $i;
    }
    $self->{'@IN_ORDER'} = \@in_order;

    my @alias = defined $hash{Alias} ? @{ $hash{Alias} } : ();
    for (@alias)
    {
	$self->{'@ALIAS'}->{$_} = $name;
    }
}

#----------------------------------------------------------------------------
package XML::XQL::DirAttr;	# Attr node
use vars qw{ @ISA %GET_ATTR_FUNC %SET_ATTR_FUNC };
@ISA = qw{ XML::XQL::DirNode };

sub new
{
    my ($type, %hash) = @_;
    my $self = bless \%hash, $type;
    
    $self->{xql_value} = $self->{Parent}->{AttrDef}->get ($hash{Name});
    $self->{xql_setValue} = $self->{Parent}->{AttrDef}->set ($hash{Name});
    $self;
}

sub isElementNode  { 0 }
sub xql_nodeType   { 2 }
sub xql_nodeName   { $_[0]->{Name} }
sub xql_childIndex { $_[0]->{Parent}->attrIndex ($_[0]->{Name}) }
sub xql_childCount { 0 }
sub xql_node       { [] }
sub is_defined     { exists $_[0]->{Value} }

sub create	{ XML::XQL::DirNode::create_date_from_days ($_[0]->{Parent}->age, $_[0]) }
sub age		{ new XML::XQL::Number ($_[0]->{Parent}->age, $_[0]) }
sub size	{ new XML::XQL::Text ($_[0]->{Parent}->size, $_[0]) }
sub ext		{ new XML::XQL::Text ($_[0]->{Parent}->ext, $_[0]) }
sub no_ext	{ new XML::XQL::Text ($_[0]->{Parent}->no_ext, $_[0]) }
sub name	{ new XML::XQL::Text ($_[0]->{Parent}->name, $_[0]) }
sub full	{ new XML::XQL::Text ($_[0]->{Parent}->full, $_[0]) }
sub abs 	{ new XML::XQL::Text ($_[0]->{Parent}->abs, $_[0]) }
sub is_file	{ new XML::XQL::Boolean ($_[0]->{Parent}->is_file, $_[0]) }
sub is_dir	{ new XML::XQL::Boolean ($_[0]->{Parent}->is_dir, $_[0]) }
sub is_link	{ new XML::XQL::Boolean ($_[0]->{Parent}->is_link, $_[0]) }
sub is_pipe	{ new XML::XQL::Boolean ($_[0]->{Parent}->is_pipe, $_[0]) }
sub it_exists	{ new XML::XQL::Boolean ($_[0]->{Parent}->it_exists, $_[0]) }
sub is_zero	{ new XML::XQL::Boolean ($_[0]->{Parent}->is_zero, $_[0]) }
sub readable	{ new XML::XQL::Boolean ($_[0]->{Parent}->readable, $_[0]) }
sub writable	{ new XML::XQL::Boolean ($_[0]->{Parent}->writable, $_[0]) }
sub executable	{ new XML::XQL::Boolean ($_[0]->{Parent}->executable, $_[0]) }
sub owned	{ new XML::XQL::Boolean ($_[0]->{Parent}->owned, $_[0]) }

sub last_access_in_days
{
    new XML::XQL::Number ($_[0]->{Parent}->last_access_in_days, $_[0]);
}

sub last_access
{ 
  XML::XQL::DirNode::create_date_from_days ($_[0]->{Parent}->last_access_in_days, $_[0]);
}

sub toString       
{ 
    my $old = ""; #$_[0]->is_defined ? "" : " (undef)";
    my $val = $_[0]->xql_value->xql_toString; #exists $_[0]->{Value} ? $_[0]->{Value}->xql_toString : "(undef)";
    $_[0]->{Name} . "=\"$val$old\""
#?? encodeAttrValue
}

sub xql_value
{
    $_[0]->{Value} ||= &{ $_[0]->{xql_value} } (@_);
}

sub xql_setValue
{
    my ($self, $text) = @_;
    my $set = $_[0]->{xql_setValue};
    if (defined $set)
    {
	&$set ($self, $text);
    }
    else
    {
	warn "xql_setValue not defined for DirAttr name=" . $self->{TagName};
    }
}

sub set_name
{
    my ($attr, $text) = @_;
    $attr->{Parent}->set_name ($text);
}

sub set_ext
{
    my ($attr, $text) = @_;
    $attr->{Parent}->set_ext ($text);
}

sub set_no_ext
{
    my ($attr, $text) = @_;
    $attr->{Parent}->set_no_ext ($text);
}

#----------------------------------------------------------------------------
package XML::XQL::DirElem;	# File or Dir
use vars qw{ @ISA $ATTRDEF };
@ISA = qw( XML::XQL::DirNode );

$ATTRDEF = new XML::XQL::DirAttrDef;
$ATTRDEF->define_attr (Name => 'name', Get => \&XML::XQL::DirAttr::name, 
		       Set => \&XML::XQL::DirAttr::set_name);
$ATTRDEF->define_attr (Name => 'full', Get => \&XML::XQL::DirAttr::full);
$ATTRDEF->define_attr (Name => 'abs', Get => \&XML::XQL::DirAttr::abs);
$ATTRDEF->define_attr (Name => 'no_ext', Get => \&XML::XQL::DirAttr::no_ext, 
		       Set => \&XML::XQL::DirAttr::set_no_ext);
$ATTRDEF->define_attr (Name => 'ext', Get => \&XML::XQL::DirAttr::ext, 
		       Set => \&XML::XQL::DirAttr::set_ext);

$ATTRDEF->define_attr (Name => 'age', Get => \&XML::XQL::DirAttr::age, 
		       Alias => [ 'M' ] );
$ATTRDEF->define_attr (Name => 'create', Get => \&XML::XQL::DirAttr::create, 
		       Alias => [ 'cre' ] );
$ATTRDEF->define_attr (Name => 'A', Get => \&XML::XQL::DirAttr::last_access_in_days,
		       Alias => [ 'acc_in_days' ] );
$ATTRDEF->define_attr (Name => 'access', Get => \&XML::XQL::DirAttr::last_access, 
		       Alias => [ 'acc' ] );

# These should only be implemented for Link and Pipe resp. !!
$ATTRDEF->define_attr (Name => 'l', Get => \&XML::XQL::DirAttr::is_link, 
		       Alias => [ 'is_link' ] );
$ATTRDEF->define_attr (Name => 'p', Get => \&XML::XQL::DirAttr::is_pipe, 
		       Alias => [ 'is_pipe' ] );

$ATTRDEF->define_attr (Name => 'e', Get => \&XML::XQL::DirAttr::it_exists, 
		       Alias => [ 'exists' ] );
$ATTRDEF->define_attr (Name => 'z', Get => \&XML::XQL::DirAttr::is_zero, 
		       Alias => [ 'is_zero' ] );
$ATTRDEF->define_attr (Name => 'r', Get => \&XML::XQL::DirAttr::readable, 
		       Alias => [ 'readable' ] );
$ATTRDEF->define_attr (Name => 'w', Get => \&XML::XQL::DirAttr::writable, 
		       Alias => [ 'writable' ] );
$ATTRDEF->define_attr (Name => 'x', Get => \&XML::XQL::DirAttr::executable, 
		       Alias => [ 'is_zero' ] );
$ATTRDEF->define_attr (Name => 'o', Get => \&XML::XQL::DirAttr::owned, 
		       Alias => [ 'owned' ] );

#dump_attr_def();

# mod => 0,
# create => 1,
# prot => 2,
# protn => 3,
# name => 4,
# path => 5,
# dir => 6,

sub isElementNode   { 1 }
sub xql_nodeType    { 1 }
sub xql_nodeName    { $_[0]->{TagName} }

sub dump_attr_def   { $ATTRDEF->dump; }
sub attrNames       { @{ $_[0]->{AttrDef}->{'@IN_ORDER'} } }
sub hasAttr         { exists $_[0]->{AttrDef}->{$_[1]} }

# Attributes set/get
sub full  		{ $_[0]->fullname }
sub abs      		{ $_[0]->abs }
sub no_ext		{ $_[0]->{TagName} }
sub set_no_ext		{ shift->set_name (@_) }
sub size		{ -s $_[0]->fullname }
sub age			{ -M $_[0]->fullname }
sub last_access_in_days	{ -A $_[0]->fullname }
sub is_file             { -f $_[0]->fullname }
sub is_dir              { -d $_[0]->fullname }
sub is_link             { -l $_[0]->fullname }
sub is_pipe             { -p $_[0]->fullname }
sub it_exists           { -e $_[0]->fullname }
sub is_zero             { -z $_[0]->fullname }
sub readable            { -r $_[0]->fullname }
sub writable            { -w $_[0]->fullname }
sub executable          { -x $_[0]->fullname }
sub owned               { -o $_[0]->fullname }

sub attr_alias    
{
    return undef unless defined $_[1];

    my $alias = $_[0]->{AttrDef}->alias ($_[1]);
    defined $alias ? $alias : $_[1];
}

sub create_path	# static
{
    my ($dir, $file) = @_;

    if ($dir =~ /\Q${XML::XQL::DirNode::SEP}\E$/)
    {
	return "$dir$file";
    }
    elsif ($dir eq "")	# e.g. when file is root directory '/'
    {
	return $file;
    }
    else
    { 
	return "$dir${XML::XQL::DirNode::SEP}$file";
    }
}

sub fullname
{ 
    my $pa = $_[0]->{Parent}->fullname;
    my $name = $_[0]->{TagName};
    create_path ($pa, $name);
}

#?? same as full name - for now
sub abs
{
    shift->fullname (@_);
}

sub parent_dir
{
    $_[0]->{Parent}->fullname;
}

# With 3 params, sets the specified attribute with $attrName to $attrValue.
# With 2 params, reinitializes the specified attribute with $attrName if
# it currently has a value.

sub update_attr
{
    my ($self, $attrName, $attrValue) = @_;

    if (@_ == 3)
    {
	my $attr = $self->getAttributeNode ($attrName);
	if (defined $attr && defined $attr->{Value})
	{
	    $attr->{Value} = $attrValue;
	}
    }
    else
    {
	return unless exists $self->{A}->{$attrName};
	my $a = $self->{A}->{$attrName};
	if (exists $a->{Value})
	{
	    delete $a->{Value};
	    $a->xql_value;	# reinitialize value
	}
    }
}

sub set_name
{
    my ($self, $text) = @_;
    my $fullName = $self->fullname;
    my $newName = create_path ($self->parent_dir, $text);

    if (rename ($fullName, $newName))
    {
	$self->{TagName} = $text;
	$self->update_attr ('name', $text);
	$self->update_attr ('ext');
	$self->update_attr ('no_ext');

	return 1;
    }
    else
    {
	warn "set_name: could not rename $fullName to $newName";
	return 0;
    }
}

sub ext
{
    my $name = $_[0]->{TagName};
    $name =~ /\.([^.]+)$/;
#    print "ext name=$name ext=$1\n";
    return $1;
}

sub set_ext
{
    my ($self, $text) = @_;
#    print "set_ext $text\n";
    my $no_ext = $self->no_ext;
    $self->set_name (length ($text) ? "$no_ext.$text" : $no_ext);
}

sub no_ext
{
    my $name = $_[0]->{TagName};
    $name =~ /^(.+)\.([^.]+)$/;
#    print "no_ext name=$name no_ext=$1\n";
    return $1;
}

sub set_no_ext
{
    my ($self, $text) = @_;
#    print "set_no_ext $text\n";
    my $ext = $self->ext;
    $self->set_name (length ($ext) ? "$text.$ext" : $text);
}

sub xql_attribute
{
    my ($node, $attrName) = @_;
    if (defined $attrName)
    {
	my $attr = $node->getAttributeNode ($attrName);
	defined ($attr) ? [ $attr ] : [];
    }
    else
    {
	my @attr;
	for my $name ($node->attrNames)
	{
	    push @attr, $node->getAttributeNode ($name);
	}
	\@attr;
    }
}

sub getAttributeNode
{
    my ($self, $attrName) = @_;
    $attrName = $self->attr_alias ($attrName);

    return undef unless $self->hasAttr ($attrName);

    my $attr = $_[0]->{A}->{$attrName} ||= 
	new XML::XQL::DirAttr (Parent => $self, Name => $attrName);
    $attr;
}

sub attrIndex
{
    $_[0]->{AttrDef}->order ($_[1]);
}

sub toString       
{ 
    my ($self, $depth) = @_;
    my $indent = "  " x $depth;
    my $str = $indent;
    my $tagName = $self->{TagName};

    my $tfp = $self->tag_for_print;

    $str .= "<$tfp name=\"$tagName\"";

    for my $attrName ($self->attrNames)
    {
	next unless exists $self->{A}->{$attrName};

#?? don't print un-retrieved attributes - for now	
	my $attr = $self->{A}->{$attrName};
	next unless $attr->is_defined;
	
	$str .= " " . $attr->toString;
    }

    my $kids = $self->print_kids ? $self->xql_node : [];
    if (@$kids)
    {
	$str .= ">\n";
	for (@$kids)
	{
	    $str .= $_->toString ($depth + 1);
	}
	$str .= $indent . "</dir>\n";
    }
    else
    {
	$str .= "/>\n";
    }
}

#----------------------------------------------------------------------------
package XML::XQL::Dir;	# Element node
use vars qw{ @ISA $ATTRDEF };
@ISA = qw( XML::XQL::DirElem );

$ATTRDEF = $XML::XQL::DirElem::ATTRDEF->clone;
$ATTRDEF->define_attr (Name => 'd', Get => \&XML::XQL::DirAttr::is_dir, 
		       Alias => [ 'is_dir' ] );
#dump_attr_def();

sub tag_for_print { "dir" }
sub print_kids    { 1 }
sub dump_attr_def { $ATTRDEF->dump }

sub new
{
    my ($type, %hash) = @_;
    $hash{AttrDef} = $ATTRDEF;
    bless \%hash, $type;
}

sub build
{
    my ($self) = @_;
    my $dirname = $self->fullname;
#    print "dirname=$dirname\n";

    if (opendir (DIR, $dirname))
    {
	my @kids;

	my @f = readdir (DIR);
	closedir DIR;

	for my $f (@f)
	{
	    next if $f =~ /^..?$/;
#	    print "dirname=$dirname f=$f\n";

	    my $full = defined $dirname ? "$dirname${XML::XQL::DirNode::SEP}$f" : $f;
#	    print "dirname=$dirname full=$full\n";

	    if (-f $full)
	    {
		push @kids, XML::XQL::File->new (Parent => $self, 
						 TagName => $f
						);
	    }
	    elsif (-d _)
	    {
		push @kids, XML::XQL::Dir->new (Parent => $self, 
						TagName => $f
					       );
	    }
	}
	$self->{C} = \@kids;
	$self->{Built} = 1;
    }
    else
    {
	print "can't opendir $dirname: $!";
    }
}

sub xql_childCount
{
    my $self = shift;
    $self->build unless $self->{Built};
    my $ch = $self->{C};

    defined $ch ? scalar(@$ch) : 0;
}

#----------------------------------------------------------------------------
package XML::XQL::File;	# Element node
use vars qw{ @ISA $ATTRDEF };
@ISA = qw( XML::XQL::DirElem );

$ATTRDEF = $XML::XQL::DirElem::ATTRDEF->clone;
$ATTRDEF->define_attr (Name => 'f', Get => \&XML::XQL::DirAttr::is_file, 
		       Alias => [ 'is_file' ] );
$ATTRDEF->define_attr (Name => 'size', Get => \&XML::XQL::DirAttr::size, 
		       Alias => [ 's' ]);
#dump_attr_def();

sub new
{
    my ($type, %hash) = @_;
    $hash{AttrDef} = $ATTRDEF;
    bless \%hash, $type;
}

sub getChildIndex  { 0 }
sub xql_childCount { 1 }
sub contents       { $_[0]->build unless $_[0]->{Built}; $_[0]->{C}->[0] }
sub xql_text       { $_[0]->contents->xql_text }
sub xql_rawText    { $_[0]->contents->xql_text }
sub tag_for_print  { "file" }
sub print_kids     { 0 }
sub dump_attr_def  { $ATTRDEF->dump }

sub xql_rawTextBlocks
{
    my $self = shift;
    ( [ 0, 0, $self->xql_text ])
}

sub xql_setValue
{
    my ($self, $text) = @_;
    $self->contents->xql_setValue ($text);
}

sub xql_replaceBlockWithText
{
    my ($self, $start, $end, $text) = @_;
    if ($start == 0 && $end == 0)
    {
	$self->xql_setValue ($text);
    }
    else
    {
	warn "xql_setText bad index start=$start end=$end";
    }
}

sub build
{
    my $self = shift;
    push @{ $self->{C} }, XML::XQL::FileContents->new (Parent => $self);
    $self->{Built} = 1;
}

#----------------------------------------------------------------------------
package XML::XQL::FileContents;	# Text node
use vars qw{ @ISA };
@ISA = qw{ XML::XQL::DirNode };

sub new
{
    my ($type, %hash) = @_;
    bless \%hash, $type;
}

sub isTextNode     { 1 }
sub xql_nodeType   { 3 }
sub xql_nodeName   { "#contents" }
sub getChildIndex  { 0 }
sub xql_childCount { 0 }
sub xql_rawText    { $_[0]->xql_text }

sub xql_text
{
    my $self = shift;
    unless ($self->{Built})
    {
	local *FILE;
	local $/;	# slurp mode

	if (open (FILE, $self->{Parent}->fullname))
	{
	    $self->{Data} = <FILE>;
	    close FILE;
	}
	else
	{
#?? warning
	}
	$self->{Built} = 1;
    }
    $self->{Data};
}

sub xql_setValue
{
    my ($self, $text) = @_;

    my $filename = $self->{Parent}->fullname;
    local *FILE;
    if (open (FILE, ">$filename"))
    {
	print FILE $text;
	$self->{Data} = $text;
	$self->{Built} = 1;
	close FILE;
    }
    else
    {
	warn "xql_setValue could not open $filename for writing";
    }
}

return 1;
