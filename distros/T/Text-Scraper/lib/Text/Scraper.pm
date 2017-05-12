package Text::Scraper;

use strict;
use Carp;

our $VERSION = '0.02';

=pod

=head1 NAME

Text::Scraper - Structured data from (un)structured text

=head1 SYNOPSIS   

    use Text::Scraper;

    use LWP::Simple;
    use Data::Dumper;

    #
    # 1. Get our template and source text
    #
    my $tmpl = Text::Scraper->slurp(\*DATA);
    my $src  = get('http://search.cpan.org/recent') || die $!;
    
    #
    # 2. Extract data from source
    #
    my $obj  = Text::Scraper->new(tmpl => $tmpl);
    my $data = $obj->scrape($src);

    #
    # 3. Do something really neat...(left as excercise)
    #
    print "Newest Submission: ", $data->[0]{submissions}[0]{name},  "\n\n";
    print "Scraper model:\n",    Dumper($obj),                      "\n\n";
    print "Parsed  model:\n",    Dumper($data) ,                    "\n\n";

    __DATA__

    <div class=path><center><table><tr>
    <?tmpl stuff pre_nav ?>
    <td class=datecell><span><big><b> <?tmpl var date_string ?> </b></big></span></td>
    <?tmpl stuff post_nav ?>
    </tr></table></center></div>

    <ul>
    <?tmpl loop submissions ?>
     <li><a href="<?tmpl var link ?>"><?tmpl var name ?></a>
      <?tmpl if has_description ?>
      <small> -- <?tmpl var description ?></small>
      <?tmpl end has_description ?>
     </li>
    <?tmpl end submissions ?>
     </ul>

=head1 ABSTRACT

Text::Scraper provides a fully functional base-class to quickly develop 
I<Screen-Scrapers> and other text extraction tools. Programmatically 
generated text such as dynamic webpages are trivially reversed engineered.

Using templates, the programmer is freed from staring at fragile, heavily 
escaped regular expressions, mapping capture groups to named variables or 
wrestling with the DOM and badly formed HTML. In addition, extracted data 
can be hierarchical, which is beyond the capabilities of vanilla regular 
expressions.

Text::Scraper's functionality overlaps some existing CPAN modules - 
L<Template::Extract|Template::Extract> and L<WWW::Scraper|WWW::Scraper>.

Text::Scraper is much more lightweight than either and has a 
more general application domain than the latter. It  has no dependencies on 
other frameworks, modules or design-decisions. On average, Text::Scraper 
benchmarks around I<250% faster> than Template::Extract - and uses 
significantly less memory.

Unlike both existing modules, Text::Scraper generalizes its functionality 
to allow the programmer to refine template capture groups beyond C<(.*?)>, 
fully redefine the template syntax and introduce new template constructs 
bound to custom classes.

=head1 BACKGROUND

Using templates is a popular method of seperating visual presentation from 
programming logic - particularly popular in programs generating dynamic webpages. 
Text::Scraper reverses this process, using templates to I<extract> the data 
back out of the surrounding presentation.

If you are familiar with templating concepts, then the L<SYNOPSIS> should be sufficient 
to get you started. If not, I would recommend reading the documentation for 
L<HTML::Template|HTML::Template> - a module thats syntax and terminology is very 
similar to Text::Scraper's.

=head1 DESCRIPTION

Template Tags are classed as I<Leaves> or I<Branches>. Like XML, Branches must 
have an associated closing tag, Leaves must not. By default, Leaf nodes return 
SCALARs and Branch nodes return ARRAYs of HASHes - each array element mapping 
to a matched sub-sequence. Blessing or filtering this data is left as an 
exercise for subclasses.

The default syntax is based on the XML preprocessor syntax:

    <?tmpl TYPE NAME [ATTRIBUTES] ?>
    
and for Branches:

    <?tmpl TYPE NAME [ATTRIBUTES] ?>  
        ...  
    <?tmpl end NAME ?>    

By default, Tags I<must> be named and any closing tag I<must> include the name of the 
opening tag it is closing. Attributes have the same syntax as XML attributes - 
but (similar to Perl regular expressions) can use any non-bracket punctuation character 
as quotation delimiters:

    <?tmpl var foo bar="baz" blah=/But dont "quote" me on that!/ ?> 

The only attribute acted on by the default tag classes is C<regex> - used to refine how 
the Tag is translated into a regular-expression capture group:

    <?tmpl var naiveEmailAddress  regex="([\w\d\.]+\@[\w\d\.]+)"  ?>

This can be used to further filter the parsed data - similar to using grep:

    <?tmpl var onlyFoocomEmailAddresses regex="([\w\d\.]+@(?:foo\.com))" ?>

Each tag should create I<only one> capture group - but it is fine to make the outer 
group non-capturing:

    <?tmpl var dateJustMonth regex="(?:\d+ (\S+) \d+)" ?>

I<The above would capture only the month field in dates formated as> C<02 July 1979>.

=head2 Default Tags

The default tags provided by Text::Scraper are typical for basic scraping but can be 
subclassed for additional functionality. All the default tags are demonstrated in the 
L<SYNOPSIS>:

=over 4

=item B<var>

Vars represent strings of text in a template. They are instances of 
C<Text::Scraper::Leaf>.

=item B<stuff>

Stuff tags represent spans of text that are of no interest in the 
extracted data, but can ease parsing in certain situations. They are instances 
of C<Text::Scraper:Ignorable> - a subclass of C<Text::Scraper::Leaf>.

=item B<loop>

Loops represent repeated information in a template and are extracted as an 
array of hashes. They are instances of C<Text::Scraper::Branch>.

=item B<if>

A conditional region in the template. If not present, the parent scope  
will contain a false value under the tags name. Otherwise the value will be true 
and any tags inside the if's scope will be exported to its parent scope also.

These are instances of C<Text::Scraper::Conditional>.

=back

=head1 User API

These methods alone are sufficient for a basic scraping session:

=cut

my $null       = bless \$0, "NULL";
my %protos     = ();  
  

sub TRACE () {0;}

=pod

=head2 C<< my $string = Text::Scraper->slurp( STRING|GLOBREF ) >>

Static utility method to return either a filename or filehandle as a string

=cut

sub slurp
{
    my $class = shift;
    my $file  = shift;
    my $data  = undef;
    local $/  = undef;

    if(!ref $file){
        open my $f, $file or Carp::croak("$class\::slurp: '$file' $!");
        $data = <$f>;
        close $f;
    }
    elsif(ref $file eq 'GLOB'){
        $data = <$file>;
    }
    else{
        Carp::croak("$class\::slurp: bad argument '$file'\n");
    }
    return $data;
}

=pod

=head2 C<< my $object = Text::Scraper->new(HASH) >>

Returns a new Text::Scraper object. Optional parameters are:

=over 4

=item B<tmpl>

A template as a string

=item B<syntax>

A Text::Scraper::Syntax instance. See L<Defining a custom syntax>.

=back

=cut

sub new
{
    my $proto  = shift;
    my $class  = ref($proto) || $proto;
    Carp::croak("Bad key/value arguments to $class::new") if @_ % 2;
    my $self   = bless {@_}, $class;

    $protos{$self} = $proto 
        unless $proto eq $class;
    
    $self->parse_attr(delete $self->{attributes})
        if exists $self->{attributes};
    $self->compile(delete $self->{tmpl}) 
        if $self->{tmpl};

    $self->on_create();
    return $self;
}

sub DESTROY
{
    my $self = shift;
    $self->on_destroy();
    delete $protos{$self};
    return;
}

=pod

=head2 C<< $obj->compile(STRING) >>

Only required for recompilation or if no B<tmpl> parameter is passed to the constructor.

=cut

sub compile
{
    my $self   = shift;
    my $tmpl   = shift;
    my $syntax = $self->{syntax} || Text::Scraper::Syntax->new();
    
    if($tmpl && $syntax)
    {
        $self->{tmpl}  = $tmpl;
        $self->{syntax}= $syntax;
        $self->{nodes} = [];

        my $rex_leaf   = $syntax->{regex}{leaf};
        my $rex_open   = $syntax->{regex}{open};
        my $rex_close  = $syntax->{regex}{close};
        my $rex_escape = $syntax->{regex}{escape};

        1 while $tmpl =~ s#$rex_open(?!=$rex_open.*?$rex_close)(.*?)$rex_close#$self->de_branch($1,$2,$3,$7)#sge;
        1 while $tmpl =~ s#$rex_leaf#$self->de_leaf($1,$2,$3)#sge;
        
        # TODO: Can this third substitution on escape sequences be removed? 
        #       May requires double escape on all above regex...slower?

        $tmpl =  $syntax->quote($tmpl);
        $tmpl =~ s/$rex_escape/$self->{nodes}[$1]->to_regex()/esg;

        $self->{compiled} = $tmpl;
        $self->{nodes}    = [ grep { $_ != $null } @{$self->{nodes}} ];
    }
}

#
# Compile scopes and replace with internal leafs
#
sub de_branch
{
    my($self, $type, $name, $args, $body) = @_;
    my $nodes  = $self->{nodes};
    my $idx    = scalar @$nodes;
    my $types  = $self->{syntax}{branches};
    Carp::croak("Invalid branch-type '$type'") 
        unless $types->{$type};
    my $node   = $types->{$type}->new(tmpl => $body, syntax => $self->{syntax}, type => $type, class => $types->{$type}, name => $name, attributes => $args);
    push @$nodes, $node;
    return $self->{syntax}->create_internal_leaf_string( $node, $idx );
}

#
# Insert leafs and branches in correct order (use $null to maintain indexes)
#
sub de_leaf
{
    my($self,$type,$name,$args) = @_;
    my $nodes  = $self->{nodes};
    my $idx    = scalar @$nodes;

    if($type =~ /^\d+$/o){  
        push @$nodes, splice(@$nodes, $type, 1, $null);
    }
    else{
        my $types = $self->{syntax}{leaves};
        Carp::croak("Invalid leaf-type '$type'") 
            unless $types->{$type}; 
        push @$nodes, $types->{$type}->new(syntax => $self->{syntax}, type => $type, class => $types->{$type}, name => $name, attributes => $args);        
    }
    return $self->{syntax}->create_escape_string($idx);
}

#
# NB: Prepends '$' to user attributes to seperate from private
#
sub parse_attr
{
    my $self = shift;
    my $args = shift;
    if(defined $args && length $args){
        while($args =~ /(\w+)\s*=\s*(\W)(.*?)\2/sg){
            $self->{"\$$1"} = $3;
        }
    }
}

=pod

=head2 C<< my $data = $obj->scrape(STRING) >>

Extract data from STRING based on compiled template.

=cut

# NB: $parent and $scope arguments are used internally to allow 
#     nodes to modify their parent, such as Text::Scraper::Conditional

sub scrape
{
    my ($self, $text, $parent, $scope) = @_;
    my $tmpl  = $self->{compiled};
    my $nodes = $self->{nodes};

    return $self->on_data($text) 
        if($self->isa('Text::Scraper::Leaf'));

    Carp::croak("$self->{name}: Cannot scrape without a compiled template!")
        unless $tmpl;

    $text =~ s/\s+/ /sg 
       unless $parent;

    my @matches = ($text =~ /$tmpl/gs);
    my $symbols = undef;
    my $returns = [];

    TRACE && print STDERR "$self matches: ",scalar @matches,"\n";

    for(my $i=0; $i<@matches; $i++)
    {
        my $mod  = $i % scalar @$nodes;
        my $node = $nodes->[$mod];
        my $name = $node->{name};       

        if($mod==0)
        {
            push @$returns, $symbols if $symbols;
            $symbols = {};         
        }
        next if $node->ignore();
        $symbols->{$name} = $node->scrape($matches[$i], $self, $symbols);
    }
    push @$returns, $symbols if $symbols;
    return $self->on_data($returns);
}

=pod

=head1 Subclass API

Text::Scraper allows its users to define custom tags and bless captured 
data into custom classes. Because Text::Scraper objects are prototype 
based, a subclass can both inherit the scraping logic and also encapsulate 
any particular instance of the scraped data.

During template compilation, a single instance of each tag type is created 
as the I<prototype object>. Its attributes will be related to the tag, any 
supplied tag attributes, etc. During scraping, each prototype is invoked 
to scrape the relevent I<sub-text> against its I<sub-template>.

=head2 C<< $subclass->on_create() >>

General construction callback. Text::Scraper objects are prototype based so 
overriding the constructor is not recommended. Objects are hash based; any 
constructor arguments become attributes of the new instance before invoking 
this method.

=head2 C<< $subclass->on_destroy() >>

General destruction callback. Text::Scraper uses the DESTROY hook so any 
custom functionality is best implemented here.

=head2 C<< $subclass->on_data(SCALAR) >> 

This is the subclasses opportunity to bless or otherwise process any parsed 
data. The return value from C<on_data> is added to the generated output 
data-structure. By default these values are just returned unblessed.

The SCALAR argument depends on the class of tag. For C<Text::Scraper::Leaf> 
subclasses, SCALAR will be the matched text. For C<Text::Scraper::Branch> 
subclasses, SCALAR will be a reference to an array of hashes. Below is an 
example of two custom tag classes that bless captured data into the same 
class:

    package Myleaf; 
    use base "Text::Scraper::Leaf";
    sub on_data
    {
        my ($self, $match) = @_;
        return $self->new(value => $match);
    }

    package MyBranch; 
    use base "Text::Scraper::Branch";
    sub on_data
    {
        my ($self, $matches) = @_;
        @$matches = map {  $self->new(%$_)  } @$matches;
        return $matches;
    }

=head2 C<< my $regex = $subclass->to_regex() >>

Returns this nodes representation as a regular expression, to be used 
in a compiled template. If you find yourself using a particular regex 
attribute a lot, it might be easier to define a custom tag that overloads 
this method.

=head2 C<< my $boolean = $subclass->ignore() >>

Returns a boolean value stating whether the parser should ignore the data 
captured by this object.

=head2 C<< $subclass->proto() $subclass->proto(SCALAR) >>

Utility method to allow Tag instances to access (attributes of) their prototype. 
This can be safely called from a prototype object, which just points to itself.

=head2 C<< my @children = $subclass->nodes() >>

Returns instance data I<in-order>, including any present conditional data. 

=cut

sub on_data
{
    return $_[1];
}

sub on_create
{
    my $self = shift;
}

sub on_destroy
{
    my $self = shift;
}

sub to_regex
{
    my $self  = shift;
    return $self->{"\$regex"} || '(.*?)';
}

sub ignore
{
    return 0;
}

sub nodes
{
    my $self  = shift;
    my $for   = shift || $self;
    my $proto = $self->proto();

    return @{$self->{nodes}} 
        if($proto == $self);

    my @vals = ();
    foreach my $n ( @{$proto->{nodes}} )
    {
        my $val = $for->{$n->{name}};
        next unless $val;
        push @vals, $val;
        push @vals, $val->nodes($for)
             if $val->isa('Text::Scraper::Conditional');
    }
    return @vals;
}

sub proto
{
    my $self  = shift;
    my $attr  = shift;
    my $proto = $protos{$self} || $self;
    return ($attr == undef)              ? $proto : 
           (defined $proto->{"\$$attr"}) ? $proto->{"\$$attr"} :
           (defined $proto->{$attr})     ? $proto->{$attr} : undef;
}

#
# Inherits all behaviour from Text::Scraper
#
package Text::Scraper::Branch;
our @ISA = ('Text::Scraper');

#
#
#
package Text::Scraper::Leaf;
our @ISA = ('Text::Scraper');

#
#
#
package Text::Scraper::Conditional;
our @ISA = ('Text::Scraper');

sub scrape
{
    my ($self, $text, $parent, $scope) = @_;
    my $data = $self->SUPER::scrape($text, $parent, $scope);
    my $tag;

    $data = shift @$data;
    unless($data){
        $tag = 0;
    }
    else{    
        $scope->{$_} = $data->{$_} foreach keys %$data;
        $tag = 1;
    }
    return $tag;
}

sub to_regex
{
    my $self  = shift;
    return $self->SUPER::to_regex()."?";
}

package Text::Scraper::Ignorable;
our @ISA = ('Text::Scraper::Leaf');

# TODO: Currently ignorables still capture their text...
#       which makes for a more elegent algorithm over efficiency.

sub ignore
{
    1;
}

=pod

=head2 Defining a custom syntax

The two areas of customization are Tag Syntax and Tag Classes. The defaults are 
encapsulated in the I<Text::Scraper::Syntax> class.

The interested reader is encouraged to copy the source of the default syntax class 
and play around with changes. All the over-ridable methods begin with B<define_*> 
and are fairly self explanatory or well commented.

Any new Tag classes should be subclassed from either I<Text::Scraper::Leaf>, 
I<Text::Scraper::Branch>, I<Text::Scraper::Ignorable> or I<Text::Scraper::Conditional>. 

=cut

package Text::Scraper::Syntax;

#
# Map tag types to classes
#

sub define_class_leaves
{
    return (var => 'Text::Scraper::Leaf', stuff => 'Text::Scraper::Ignorable');
}

sub define_class_branches
{
    return (loop => 'Text::Scraper::Branch', if => 'Text::Scraper::Conditional');
}

#
# Tag Syntax:
# TYPE, NAME, ATTRIBUTES, BACKREF, and ESCAPE are special
# markers that are substituted with either regular 
# expressions or values.
#

sub define_syntax_leaf
{
    '<?tmpl TYPE NAME ATTRIBUTES ?>';
}

sub define_syntax_branch_open
{
    '<?tmpl TYPE NAME ATTRIBUTES ?>';
}

sub define_syntax_branch_close
{
    '<?tmpl end BACKREF ?>';
}

#
# Escape sequences must never appear in input text
#
sub define_syntax_escape
{
    "$;ESCAPE$;";
}

#
# BACKREF must be able to match 2 unique identifiers 
# in nested branch nodes, hence \2\5. If you change 
# the order of TYPE and NAME, this will need updated.
#
sub define_backref
{
    '(?:\2|\5)';
}

#
# The methods below should NOT be overridden in custom Syntax subclasses
#

sub new
{
    my $class    = shift;
    my $self     = bless {}, $class;

    my $bref     = $self->define_backref();
    my %tokens   = (NAME => '(\w+)',TYPE => '((?:\w+|\d+))', ATTRIBUTES => '(.*?)?', ESCAPE => '(\d+?)', BACKREF => $bref );
    my $tokes    = join('|', keys %tokens);    

    # Load valid types:
    $self->{branches} = { $self->define_class_branches() };
    $self->{leaves}   = { $self->define_class_leaves()   };

    my $syn = 
    {
        leaf    => $self->define_syntax_leaf(),
        open    => $self->define_syntax_branch_open(),
        close   => $self->define_syntax_branch_close(),
        escape  => $self->define_syntax_escape()
    };

    # Create regexen from syntax:
    # 'escape' is a special case as it is invoked as a regex AFTER 
    # whole tmpl has been escaped - requiring double "escapation"

    my $rex        = {};
    $rex->{$_}     = $self->quote($syn->{$_}) foreach keys %$syn;
    $rex->{escape} = $self->quote(quotemeta($syn->{escape}));

    # Insert token regexes into compiled regex
    $_ =~ s/($tokes)/$tokens{$1}/sg 
        foreach values %$rex;

    $self->{syntax} = $syn;
    $self->{regex}  = $rex;
    return $self;
}

#
# Compact and escape a template
# TODO: needs knowledge of preserver_whitespace options
#
sub quote
{
    my $self   = shift;
    my $tmpl   = shift;

    $tmpl =~ s/\s+/ /sgo;
    $tmpl = qr/\Q$tmpl\E/;
    $tmpl =~ s/\\\s/\\s*/sgo;
    return $tmpl;
}

#
# Create the syntax specific escaped index (CANNOT clash with template data)
#
sub create_escape_string
{
    my $self = shift;
    my $num  = shift;
    my $str  = $self->define_syntax_escape();
    $str     =~ s/ESCAPE/$num/;
    return $str;
}

#
# Create syntax for an internal leaf referencing an already parsed branch
#
sub create_internal_leaf_string
{
    my $self = shift;
    my $node = shift;
    my $idx  = shift;
    my $str  = $self->define_syntax_leaf();
    $str     =~ s#TYPE#$idx#;
    $str     =~ s#NAME#$node->{name}#;
    $str     =~ s#ATTRIBUTES##;
    return $str;
}

=pod

=head1 BUGS & CAVEATS

Rather than write a slow parser in pure Perl, Text::Scraper 
farms a lot of the work out to Perl's optimized regular-expression engine.
This works well in general but, unfortunately, doesn't allow for a lot of 
error feedback during scraping. A fair understanding of the pros and cons 
of using regular expressions in this manner can be beneficial, but is outside 
the scope of this documentation. 

L<Data::Dumper|Data::Dumper> can be indespensible in following the success of 
your scraping. It can be safely applied to a Text::Scraper instance to analyze 
the parser's object model, or to the return value from a C<scrape()> invokation 
to analyze what was parsed.

Bug reports and suggestions welcome.

=head1 AUTHOR

Copyright (C) 2005 Chris McEwan - All rights reserved.

Chris McEwan <mcewan@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
