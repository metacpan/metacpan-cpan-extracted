
package Tree::Parser;

use strict;
use warnings;

our $VERSION = '0.15';

use Scalar::Util qw(blessed);

use Tree::Simple;
use Array::Iterator;

### constructor		
		
sub new {
	my ($_class, $input) = @_;
	my $class = ref($_class) || $_class;
	my $tree_parser = {};
	bless($tree_parser, $class);
    $tree_parser->_init($input);
	return $tree_parser;
}

sub _init {
    my ($self, $input) = @_;
    # make slots for our 2 filters
    $self->{parse_filter} = undef;
    $self->{deparse_filter} = undef;
    $self->{deparse_filter_cleanup} = undef;
    # check the input and decide what to 
    # do with it
    if ($input) {
        # we accept a Tree::Simple object
        # and expect then it to be deparsed
        if (blessed($input) && $input->isa("Tree::Simple")) {
            $self->{iterator} = undef;
            $self->{tree} = $input;
        }
        # or we can take a number of types of input
        # see prepareInput below 
        else {
            $self->{iterator} = $self->prepareInput($input);
            $self->{tree} = Tree::Simple->new(Tree::Simple->ROOT);
        }
    }
    # if no input is given we create
    # an empty tree a no iterator
    else {
        $self->{iterator} = undef;
        $self->{tree} = Tree::Simple->new(Tree::Simple->ROOT);
    }
}

### methods

sub setFileEncoding {
    my ($self, $file_encoding) = @_;
    (defined($file_encoding)) || die "Insufficient Arguments : file_encoding must be defined";
    $self->{file_encoding} = $file_encoding;    
}

sub setInput {
    my ($self, $input) = @_;
    (defined($input)) || die "Insufficient Arguments : input undefined";
    $self->{iterator} = $self->prepareInput($input);
}

# prepareInput accepts any of the follow
# types of arguments:
# 	- a .tree file
# 	- an array reference of lines
# 	- a single string of code (can have embedded newlines)
# and then returns an iterator.
# references will be stringified, unless they are array references or
# Array::Iterator objects.
sub prepareInput {
	my ($self, $input) = @_;
	
    # already an A:I instance
    return $input
        if blessed($input) and $input->isa('Array::Iterator');

    # a simple array
    return Array::Iterator->new($input)
        if ref($input) eq 'ARRAY';

    # stringifies to something that ends in .tree
	if ($input =~ /\.tree$/) {
	    IS_A_FILE:
	        my $encoding = (defined $self->{file_encoding} 
	            ? (":" . $self->{file_encoding}) 
	            : '');
    		open(TREE_FILE, ("<" . $encoding), $input) || die "cannot open file: $!";
    		my @lines = <TREE_FILE>;
    		close(TREE_FILE);
    		return Array::Iterator->new(@lines);	
	}
    # everything else
	else {
        my @lines;
        if ($input =~ /\n/) {
            @lines = split /\n/ => $input;
            (scalar(@lines) > 1) 
                || die "Incorrect Object Type : input looked like a single string, but only a single line ($input) unable to parse input into line (" . (join "==" => @lines) . ")";
        }
        elsif ($input =~ /^\(/) {
            @lines = grep { $_ ne "" } split /(\(|\)|\s|\")/ => $input; #"
        }
        else {
            # lets check if it is a file though
            goto IS_A_FILE if -f $input;
            # otherwise, croak on this sucker ...
            die "Incorrect Object Type : input looked like a single string, but has no newlines or does not start with paren";
        }
		return Array::Iterator->new(@lines);		
	}
}

## ----------------------------------------------------------------------------
## Filters
## ----------------------------------------------------------------------------

## tab indented filters
## ----------------------------------------------
{
    my $TAB_INDENTED_PARSE = sub ($) {
        my ($line_iterator) = @_;
        my $line = $line_iterator->next();
        my ($tabs, $node) = $line =~ /(\t*)(.*)/;
        my $depth = length $tabs;
        return ($depth, $node);
    };
    
    my $TAB_INDENTED_DEPARSE = sub ($) { 
        my ($tree) = @_;
        return ("\t" x $tree->getDepth()) . $tree->getNodeValue();
    };
    
    sub useTabIndentedFilters {
        my ($self) = @_;
        $self->{parse_filter} = $TAB_INDENTED_PARSE;
        $self->{deparse_filter} = $TAB_INDENTED_DEPARSE;
        $self->{deparse_filter_cleanup} = undef;
    }
}

## space indented filters
## ----------------------------------------------
{
    my $make_SPACE_INDENTED_PARSE = sub {
        my ($num_spaces) = @_;
        return sub ($) {
            my ($line_iterator) = @_;
            my $line = $line_iterator->next();
            my ($spaces, $node) = $line =~ /(\s*)(.*)/;
            my $depth = (length($spaces) / $num_spaces) ;
            return ($depth, $node);
            };
    };
    
    my $make_SPACE_INDENTED_DEPARSE = sub {
        my ($num_spaces) = @_;
        my $spaces = (" " x $num_spaces);
        return sub ($) {
                my ($tree) = @_;
                return ($spaces x $tree->getDepth()) . $tree->getNodeValue();
            };
    };
    
    sub useSpaceIndentedFilters {
        my ($self, $num_spaces) = @_;
        $num_spaces ||= 4;
        $self->{parse_filter} = $make_SPACE_INDENTED_PARSE->($num_spaces);
        $self->{deparse_filter} = $make_SPACE_INDENTED_DEPARSE->($num_spaces);
        $self->{deparse_filter_cleanup} = undef;
    }
}

## space indented filters
## ----------------------------------------------
{

    my @default_level_identifiers = (1 .. 100);

    my $make_DOT_SEPERATED_LEVEL_PARSE = sub {
        my (@level_identifiers) = @_;
        @level_identifiers = @default_level_identifiers unless @level_identifiers;
        return sub {
            my ($line_iterator) = @_;
            my $line = $line_iterator->next();
            my $level_identifiers_reg_ex = join "|" => @level_identifiers;
            my ($numbers, $value) = $line =~ /([($level_identifiers_reg_ex)\.]*)\s(.*)/;
            # now split the numbers
            my @numbers = split /\./ => $numbers;
            # we know the depth of the tree by home many
            # numbers are present, and we assume we were
            # given them in sequential order anyway
            my $depth = $#numbers;
            return ($depth, $value);
        };
    };
    
    my $make_DOT_SEPERATED_LEVEL_DEPARSE = sub {
        my (@level_identifiers) = @_;
        @level_identifiers = @default_level_identifiers unless @level_identifiers;
        return sub {
            my ($tree) = @_;
            my @numbers = $level_identifiers[$tree->getIndex()];
            my $current_tree = $tree->getParent();
            until ($current_tree->isRoot()) {
                unshift @numbers => $level_identifiers[$current_tree->getIndex()];
                $current_tree = $current_tree->getParent();
            }
            return ((join "." => @numbers) . " " . $tree->getNodeValue()); 
        };
    };    
        
    sub useDotSeparatedLevelFilters {
        my ($self, @level_identifiers) = @_;
        $self->{parse_filter} = $make_DOT_SEPERATED_LEVEL_PARSE->(@level_identifiers);
        $self->{deparse_filter} = $make_DOT_SEPERATED_LEVEL_DEPARSE->(@level_identifiers);
        $self->{deparse_filter_cleanup} = undef;
    }   
    
    *useDotSeperatedLevelFilters = \&useDotSeparatedLevelFilters; 

}

## nested parens filters
## ----------------------------------------------
{
    
    my $make_NESTED_PARENS_PARSE = sub {
        my @paren_stack;
        return sub {
            my ($line_iterator) = @_;
            my $line = $line_iterator->next();
            my $node = "";
            while (!$node && $node ne 0) {
                if ($line eq "(") {
                    push @paren_stack => $line;
                    last unless $line_iterator->hasNext();
                    $line = $line_iterator->next();
                }
                elsif ($line eq ")") {            
                    pop @paren_stack;
                    last unless $line_iterator->hasNext();
                    $line = $line_iterator->next();
                }
                elsif ($line eq '"') {           
                    $line = ""; # clear the quote
                    while ($line_iterator->hasNext()) {
                        my $next = $line_iterator->next();
                        last if $next eq '"';
                        $line .= $next;
                    }
                }  
                elsif ($line eq ' ') {
                    # discard misc whitespace
                    $line = $line_iterator->next();
                    next;
                }                               
                else {              
                    $node = $line;
                }
            }
            my $depth = $#paren_stack;
            $depth = 0 if $depth < 0;
            return ($depth, $node);
        };
    };

    # this is used in clean up as well
    my $prev_depth;
    my $NESTED_PARENS_DEPARSE = sub {
        my ($tree) = @_;
        my $output = "";
        unless (defined($prev_depth)) { 
            $output .= "(";
            $prev_depth = $tree->getDepth();
        }
        else {
            my $current_depth = $tree->getDepth();                        
            if ($prev_depth == $current_depth) {
                $output .= " ";
            }
            elsif ($prev_depth < $current_depth) {
                $output .= " (";                
            }
            elsif ($prev_depth > $current_depth) {
                my $delta = $prev_depth - $current_depth;
                $output .= ")" x $delta . " ";
            }
            $prev_depth = $current_depth;
        }
        my $current_node = $tree->getNodeValue();
        $current_node = '"' . $current_node . '"' if $current_node =~ /\s/;
        $output .= $current_node;
        return $output;
    };
    
    my $NESTED_PARENS_CLEANUP = sub { 
        my $closing_parens = $prev_depth;
        # unset this so it can be used again
        undef $prev_depth;
        return @_, (")" x ($closing_parens + 1)) 
    };
    
    sub useNestedParensFilters {
        my ($self) = @_;
        $self->{parse_filter} = $make_NESTED_PARENS_PARSE->();
        $self->{deparse_filter} = $NESTED_PARENS_DEPARSE;
        $self->{deparse_filter_cleanup} = $NESTED_PARENS_CLEANUP;
    }
}

## manual filters
## ----------------------------------------------
# a filter is a subroutine reference 
# which gets executed upon each line
# and it must return two values:
# 	- the depth of the node
# 	- the value of the node (which can 
#	  be anything; string, array ref, 
# 	  object instanace, you name it)
# NOTE:
# if a filter is not specified, then
# the parsers iterator is expected to
# return the dual values.

sub setParseFilter {
	my ($self, $filter) = @_;
	(defined($filter) && ref($filter) eq "CODE") 
        || die "Insufficient Arguments : parse filter must be a code reference";
	$self->{parse_filter} = $filter;
}

sub setDeparseFilter {
	my ($self, $filter) = @_;
	(defined($filter) && ref($filter) eq "CODE") 
        || die "Insufficient Arguments : parse filter must be a code reference";
	$self->{deparse_filter} = $filter;
}

## ----------------------------------------------------------------------------

sub getTree {
	my ($self) = @_;
	return $self->{tree};
}

# deparse creates either:
# 	- an array of lines
# 	- or one large string
# which contains the values
# created by the sub ref 
# (unfilter) passed as an argument
sub deparse {
	my ($self) = @_;
	(defined($self->{deparse_filter})) 
        || die "Parse Error : no deparse filter is specified";
	(!$self->{tree}->isLeaf()) 
        || die "Parse Error : Tree is a leaf node, cannot de-parse a tree that has not be created yet";
    return $self->_deparse();
}

# parser front end
sub parse {
	my ($self) = @_;
    (defined($self->{parse_filter})) 
        || die "Parse Error : No parse filter is specified to parse with";
	(defined($self->{iterator})) 
        || die "Parse Error : no input has yet been defined, there is nothing to parse";        
	return $self->_parse();
}

## private methods

sub _deparse {
    my ($self) = @_;
	my @lines;
	$self->{tree}->traverse(sub {
		my ($tree) = @_;
		push @lines => $self->{deparse_filter}->($tree);
		});
    @lines = $self->{deparse_filter_cleanup}->(@lines) if defined $self->{deparse_filter_cleanup};        
	return wantarray ?
				@lines
				:
				join("\n" => @lines);
}

# private method which parses given
# an iterator and a tree
sub _parse {
	my ($self) = @_;
    my $tree_type = ref($self->{tree});
    my ($i, $current_tree) = ($self->{iterator}, $self->{tree});
	while ($i->hasNext()) {
        my ($depth, $node) = $self->{parse_filter}->($i);
        # if we get nothing back and the iterator
        # is exhausted, then we now it is time to 
        # stop parsing the input.
        last if !$depth && !$node && !$i->hasNext();
		# depth must be defined ...
		(defined($depth) 
			&& 
			# and a digit (int or float)
			($depth =~ /^\d+(\.\d*)?$/o) 
			# otherwise we throw and exception
			) || die "Parse Error : Incorrect Value for depth (" . ((defined $depth) ? $depth : "undef") . ")";
		# and node is fine as long as it is defined	
		(defined($node)) || die "Parse Error : node is not defined";
        
        my $new_tree;
        # if we get back a tree of the same type, 
        # or even of a different type, but still
        # a Tree::Simple, then we use that ....
        if (blessed($node) && ($node->isa($tree_type) || $node->isa('Tree::Simple'))) {
            $new_tree = $node;
        }
        # othewise, we assume it is intended to be
        # the node of the tree
        else {
            $new_tree = $tree_type->new($node);
        }
            	
		if ($current_tree->isRoot()) {
			$current_tree->addChild($new_tree);
			$current_tree = $new_tree;
			next;
		}
		my $tree_depth = $current_tree->getDepth();		
		if ($depth == $tree_depth) {	
			$current_tree->addSibling($new_tree);
			$current_tree = $new_tree;
		} 
		elsif ($depth > $tree_depth) {
			(($depth - $tree_depth) <= 1) 
                || die "Parse Error : the difference between the depth ($depth) and the tree depth ($tree_depth) is too much (" . ($depth - $tree_depth) . ") at '$node'";
			$current_tree->addChild($new_tree);
			$current_tree = $new_tree;
		} 
		elsif ($depth < $tree_depth) {
			$current_tree = $current_tree->getParent() while ($depth < $current_tree->getDepth());
			$current_tree->addSibling($new_tree);
			$current_tree = $new_tree;	
		}		
		
	}
	return $self->{tree};
}

1;

__END__

=pod

=head1 NAME

Tree::Parser - Module to parse formatted files into tree structures

=head1 SYNOPSIS

  use Tree::Parser;
  
  # create a new parser object with some input
  my $tp = Tree::Parser->new($input);
  
  # use the built in tab indent filters
  $tp->useTabIndentedFilters();
  
  # use the built in space indent filters
  $tp->useSpaceIndentedFilters(4); 
  
  # use the built in dot-seperated numbers filters
  $tp->useDotSeperatedLevelFilters();
  
  # use the nested parens filter
  $tp->useNestedParensFilters();
  
  # create your own filter
  $tp->setParseFilter(sub {
      my ($line_iterator) = @_;
      my $line = $line_iterator->next();
      my ($id, $tabs, $desc) = $line =~ /(\d+)(\t*)(.*)/;
      my $depth = length $tabs;
      return ($depth, { id => $id, desc => $desc } );
  });
  
  # parse our input and get back a tree
  my $tree = $tp->parse();
  
  # create your own deparse filter
  # (which is in the inverse of our
  # custom filter above)
  $tp->setDeparseFilter(sub { 
      my ($tree) = @_;
      my $info = $tree->getNodeValue();
      return ($info->{id} . ("\t" x $tree->getDepth()) . $info->{desc});
  });
  
  # deparse our tree and get back a string
  my $tree_string = $tp->deparse();

=head1 DESCRIPTION

This module can parse various types of input (formatted and containing 
hierarchal information) into a tree structures. It can also deparse the 
same tree structures back into a string. It accepts various types of 
input, such as; strings, filenames, array references. The tree structure 
is a hierarchy of B<Tree::Simple> objects. 

The parsing is controlled through a parse filter, which is used to process 
each "line" in the input (see C<setParseFilter> below for more information 
about parse filters). 

The deparseing as well is controlled by a deparse filter, which is used to 
covert each tree node into a string representation.

This module can be viewed (somewhat simplistically) as a serialization tool 
for B<Tree::Simple> objects. Properly written parse and deparse filters can 
be used to do "round-trip" tree handling.

=head1 METHODS

=head2 Constructor

=over 5

=item B<new ($tree | $input)>

The constructor is used primarily for creating an object instance. Initializing 
the object is done by the C<_init> method (see below).

=back

=head2 Input Processing

=over 4

=item B<setInput ($input)>

This method will take varios types of input, and pre-process them through the 
C<prepareInput> method below.

=item B<prepareInput ($input)>

The C<prepareInput> method is used to pre-process certain types of C<$input>. 
It accepts any of the follow types of arguments:

=over 4

=item * I<an B<Array::Iterator> object>

This just gets passed on through.

=item * I<an array reference containing the lines to be parsed>

This type of argument is used to construct an B<Array::Iterator> instance.

=item * I<a filename>

The file is opened, its contents slurped into an array, which is then used to 
construct an B<Array::Iterator> instance. 

B<NOTE>: we used to only handle files with the C<.tree> extension, however that 
was annoying, so now we accept any file name.

=item * I<a string>

The string is expected to have at least one embedded newline or be in the nested 
parens format.

=back

It then returns an B<Array::Iterator> object ready for the parser.

=item B<setFileEncoding($encoding)>

This allows you to specify the C<$encoding> that the file should be read using. 
This is only only applicable when your input is a file.

=back

=head2 Filter Methods

=over 5

=item B<useTabIndentedFilters>

This will set the parse and deparse filters to handle tab indented content. This 
is for true tabs C<\t> only. The parse and deparse filters this uses are compatible 
with one another so round-triping is possible.

Example:

  1.0
      1.1
      1.2
          1.2.1
  2.0
      2.1
  3.0
      3.1
          3.1.1

=item B<useSpaceIndentedFilters ($num_spaces)>

This will set the parse and deparse filters to handle space indented content. The 
optional C<$num_spaces> argument allows you to specify how many spaces are to be 
treated as a single indent, if this argument is not specified it will default to a 
4 space indent. The parse and deparse filters this uses are compatible with one 
another so round-triping is possible.

Example:

  1.0
    1.1
    1.2
      1.2.1
  2.0
    2.1
  3.0
    3.1
      3.1.1

=item B<useDotSeparatedLevelFilters (@level_identifiers)>

This will set the parse and deparse filters to handle trees which are described in 
the following format:

  1 First Child
  1.1 First Grandchild
  1.2 Second Grandchild
  1.2.1 First Child of the Second Grandchild
  1.3 Third Grandchild
  2 Second Child 

There must be at least one space seperating the level identifier from the level 
name, all other spaces will be considered part of the name itself.

The parse and deparse filters this uses are compatible with one another so 
round-triping is possible.

The labels used are those specified in the C<@level_identifiers> argument. The 
above code uses the default level identifiers (C<1 .. 100>). But by passing the 
following as a set of level identifiers: C<'a' .. 'z'>, you can successfully 
parse a format like this:

  a First Child
  a.a First Grandchild
  a.b Second Grandchild
  a.b.a First Child of the Second Grandchild
  a.c Third Grandchild
  b Second Child

Currently, you are restricted to only one set of level identifiers. Future plans 
include allowing each depth to have its own set of identifiers, therefore allowing 
formats like this: C<1.a> or other such variations (see L<TO DO> section for more 
info).

=item B<useDotSeperatedLevelFilters>

This old mispelled method name is kept for backwards compat.

=item B<useNestedParensFilters>

This will set the parse and deparse filters to handle trees which are described 
in the following format:

  (1 (1.1 1.2 (1.2.1) 1.3) 2 (2.1))

The parser will count the parentheses to determine the depth of the current node. 
This filter can also handle double quoted strings as values as well. So this would 
be valid input:

  (root ("tree 1" ("tree 1 1" "tree 1 2") "tree 2"))

This format is currently somewhat limited in that the input must all be on one 
line and not contain a trailing newline. It also does not handle embedded escaped 
double quotes. Further refinement and improvement of this filter format is to come 
(and patches are always welcome).

It should be noted that this filter also cannot perform a roundtrip operation 
where the deparsed output is the exact same as the parsed input because it does 
not treat whitespace as signifigant (unless it is within a double quoted string). 

=item B<setParseFilter ($filter)>

A parse filter is a subroutine reference which is used to process each element 
in the input. As the main parse loop runs, it calls this filter routine and 
passes it the B<Array::Iterator> instance which represents the input. To get 
the next element/line/token in the iterator, the filter must call C<next>, the 
element should then be processed by the filter. A filter can if it wants advance 
the iterator further by calling C<next> more than once if nessecary, there are 
no restrictions as to what it can do. However, the filter B<must> return these 
two values in order to correctly construct the tree:

=over 4

=item I<the depth of the node within the tree>

=item Followed by either of the following items:

=over 4

=item I<the value of the node>

This value will be used as the node value when constructing the new tree. This 
can basically be any scalar value.

=item I<an instance of either a Tree::Simple object, or some derivative of Tree::Simple>

If you need to perform special operations on the tree instance before it get's 
added to the larger hierarchy, then you can construct it within the parse filter 
and return it. An example of why you might want to do this would be if you 
wanted to set the UID of the tree instance from something in the parse filter.

=back

=back

The following is an example of a very basic filter which simply counts the 
number of tab characters to determine the node depth and then captures any 
remaining character on the line.

  $tree_parser->setParseFilter(sub {
      my ($iterator) = @_;
      my $line = $iterator->next();
      # match the tables and all that follows it
      my ($tabs, $node) = ($line =~ /(\t*)(.*)/);
      # calculate the depth by seeing how long
      # the tab string is.
      my $depth = length $tabs;
      # return the depth and the node value
      return ($depth, $node);
  }); 

=item B<setDeparseFilter ($filter)>

The deparse filter is the opposite of the parse filter, it takes each element 
of the tree and returns a string representation of it. The filter routine gets 
passed a B<Tree::Simple> instance and is expected to return a single string. 
However, this is not enforced we actually will gobble up all the filter returns, 
but keep in mind that each element returned is considered to be a single line 
in the output, so multiple elements will be treated as mutiple lines. 

Here is an example of a deparse filter. This can be viewed as the inverse of 
the parse filter example above.

  $tp->setDeparseFilter(sub { 
      my ($tree) = @_;
      return ("\t" x $tree->getDepth()) . $tree->getNodeValue();
  });

=back

=head2 Accessors

=over 4

=item B<getTree>

This method returns the tree held by the parser or set through the constructor.

=back

=head2 Parse/Deparse

=over 4

=item B<parse>

Parsing is pretty automatic once everthing is set up. This routine will check 
to be sure you have all you need to proceed, and throw an execption if not. 
Once the parsing is complete, the tree will be stored interally as well as 
returned from this method.

=item B<deparse>

This method too is pretty automatic, it verifies that it has all its needs, 
throwing an exception if it does not. It will return an array of lines in list 
context, or in scalar context it will join the array into a single string 
seperated by newlines.

=back

=head2 Private Methods

=over 4

=item B<_init ($tree | $input)>

This will initialize the slots of the object. If given a C<$tree> object, it 
will store it. This is currently the prefered way in which to use subclasses 
of B<Tree::Simple> to build your tree with, as this object will be used to 
build any other trees (see L<TO DO> for more information). If given some other
kind of input, it will process this through the C<prepareInput> method.

=item B<_parse>

This is where all the parsing work is done. If you are truely interested in the 
inner workings of this method, I suggest you refer to the source. It is a very 
simple algorithm and should be easy to understand.

=item B<_deparse>

This is where all the deparsing work is done. As with the C<_parse> method, if 
you are interested in the inner workings, I suggest you refer to the source. 

=back

=head1 TO DO

=over 4

=item Enhance the Nested Parens filter

This filter is somewhat limited in its handling of embedded newlines as well as 
embedded double quotes (even if they are escaped). I would like to improve this 
filter more when time allows. 

=item Enhance the Dot Seperated Level filter

I would like to enhance this built in filter to handle multi-level level-identifiers, 
basically allowing formats like this:

  1 First Child
  1.a First Grandchild
  1.b Second Grandchild
  1.b.I First Child of the Second Grandchild
  1.b.II Second Child of the Second Grandchild
  1.c Third Grandchild
  2 Second Child

=item Make Tree::Simple subclasses more easy to handle

Currently in order to have Tree::Parser use a subclass of Tree::Simple to build 
the heirarchy with, you must pass a tree into the constructor, and then set the 
input manually. This could be handled better I think, but right now I am not 100% 
how best to go about it.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be 
sure to fix it. This module, in an earlier form, has been and is being used in 
production for approx. 1 year now without incident. This version has been improved 
and the test suite added.

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> 
report on this module's test suite.

 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 File                           stmt branch   cond    sub    pod   time  total
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 Tree/Parser.pm                100.0   87.9   81.2  100.0  100.0  100.0   94.6
 ---------------------------- ------ ------ ------ ------ ------ ------ ------
 Total                         100.0   87.9   81.2  100.0  100.0  100.0   94.6
 ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

This module is not an attempt at a general purpose parser by any stretch of the 
imagination. It is basically a very flexible special purpose parser, it only 
builds Tree::Simple heirarchies, but your parse filters can be as complex as nessecary. 
If this is not what you are looking for, then you might want to consider one of 
the following modules:

=over 4

=item B<Parse::RecDescent>

This is a general purpose Recursive Descent parser generator written by Damian 
Conway. If your parsing needs lean towards the more complex, this is good module 
for you. Recursive Descent parsing is known to be slower than other parsing styles, 
but it tends to be easier to write grammers for, so there is a trade off. If speed 
is a concern, then you may just want to skip perl and go straight to C and use 
C<yacc>.

=item B<Parse::Yapp>

As an alternative to Recursive Descent parsing, you can do LALR parsing. It is 
faster and does not have some of the well known (and avoidable) problems of 
Recursive Descent parsing. I have never actually used this module, but I have 
heard good things about it. 

=item B<Parse::FixedLength>

If all you really need to do is process a file with fixed length fields in it, 
you can use this module.

=item B<Parse::Tokens>

This class will help you parse text with embedded tokens in it. I am not very 
familiar with this module, but it looks interesting.

=back

There are also a number of specific parsers out here, such as B<HTML::Parser> 
and B<XML::Parser>, which do one thing and do it well. If you are looking to 
parse HTML or XML, don't use my module, use these ones, it just makes sense. 
Use the right tool for the job basically.

=head1 DEPENDENCIES

This module uses two other modules I have written: 

=over 5

=item B<Tree::Simple>

=item B<Array::Iterator>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item Thanks to Chad Ullman for reporting RT Bug #12244 and providing code and test case for it.

=item Thanks to Gerd for reporting RT Bug #13041 and providing code to fix it.

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2007 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
