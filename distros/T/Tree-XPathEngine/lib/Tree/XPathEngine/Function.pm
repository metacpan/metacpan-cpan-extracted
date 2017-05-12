# $Id: /tree-xpathengine/trunk/lib/Tree/XPathEngine/Function.pm 26 2006-02-15T15:46:06.515200Z mrodrigu  $

package Tree::XPathEngine::Function;
use Tree::XPathEngine::Number;
use Tree::XPathEngine::Literal;
use Tree::XPathEngine::Boolean;
use Tree::XPathEngine::NodeSet;
use strict;

sub new {
    my $class = shift;
    my ($pp, $name, $params) = @_;
    bless { 
        pp => $pp, 
        name => $name, 
        params => $params 
        }, $class;
}

sub as_string {
    my $self = shift;
    my $string = $self->{name} . "(";
    my $second;
    foreach (@{$self->{params}}) {
        $string .= "," if $second++;
        $string .= $_->as_string;
    }
    $string .= ")";
    return $string;
}

sub evaluate {
    my $self = shift;
    my $node = shift;
    if ($node->isa('Tree::XPathEngine::NodeSet')) {
        $node = $node->get_node(1);
    }
    my @params;
    foreach my $param (@{$self->{params}}) {
        my $results = $param->evaluate($node);
        push @params, $results;
    }
    $self->_execute($self->{name}, $node, @params);
}

sub _execute {
    my $self = shift;
    my ($name, $node, @params) = @_;
    $name =~ s/-/_/g;
    no strict 'refs';
    $self->$name($node, @params);
}

# All functions should return one of:
# Tree::XPathEngine::Number
# Tree::XPathEngine::Literal (string)
# Tree::XPathEngine::NodeSet
# Tree::XPathEngine::Boolean

### NODESET FUNCTIONS ###

sub last {
    my $self = shift;
    my ($node, @params) = @_;
    die "last: function doesn't take parameters\n" if (@params);
    return Tree::XPathEngine::Number->new($self->{pp}->_get_context_size);
}

sub position {
    my $self = shift;
    my ($node, @params) = @_;
    if (@params) {
        die "position: function doesn't take parameters [ ", @params, " ]\n";
    }
    # return pos relative to axis direction
    return Tree::XPathEngine::Number->new($self->{pp}->_get_context_pos);
}

sub count {
    my $self = shift;
    my ($node, @params) = @_;
    die "count: Parameter must be a NodeSet\n" unless $params[0]->isa('Tree::XPathEngine::NodeSet');
    return Tree::XPathEngine::Number->new($params[0]->size);
}

sub id {
    my $self = shift;
    my ($node, @params) = @_;
    die "id: Function takes 1 parameter\n" unless @params == 1;
    my $results = Tree::XPathEngine::NodeSet->new();
    if ($params[0]->isa('Tree::XPathEngine::NodeSet')) {
        # result is the union of applying id() to the
        # string value of each node in the nodeset.
        foreach my $node ($params[0]->get_nodelist) {
            my $string = $node->xpath_string_value;
            $results->append($self->id($node, Tree::XPathEngine::Literal->new($string)));
        }
    }
    else { # The actual id() function...
        my $string = $self->string($node, $params[0]);
        $_ = $string->value; # get perl scalar
        my @ids = split; # splits $_
        foreach my $id (@ids) {
            if (my $found = $node->get_element_by_id($id)) {
                $results->push($found);
            }
        }
    }
    return $results;
}

sub name {
    my $self = shift;
    my ($node, @params) = @_;
    if (@params > 1) {
        die "name() function takes one or no parameters\n";
    }
    elsif (@params) {
        my $nodeset = shift(@params);
        $node = $nodeset->get_node(1);
    }
    
    return Tree::XPathEngine::Literal->new($node->xpath_get_name);
}

### STRING FUNCTIONS ###

sub string {
    my $self = shift;
    my ($node, @params) = @_;
    die "string: Too many parameters\n" if @params > 1;
    if (@params) {
        return Tree::XPathEngine::Literal->new($params[0]->xpath_string_value);
    }
    
    # TODO - this MUST be wrong! - not sure now. -matt
    return Tree::XPathEngine::Literal->new($node->xpath_string_value);
    # default to nodeset with just $node in.
}

sub concat {
    my $self = shift;
    my ($node, @params) = @_;
    die "concat: Too few parameters\n" if @params < 2;
    my $string = join('', map {$_->xpath_string_value} @params);
    return Tree::XPathEngine::Literal->new($string);
}

sub starts_with {
    my $self = shift;
    my ($node, @params) = @_;
    die "starts-with: incorrect number of params\n" unless @params == 2;
    my ($string1, $string2) = ($params[0]->xpath_string_value, $params[1]->xpath_string_value);
    if (substr($string1, 0, length($string2)) eq $string2) {
        return Tree::XPathEngine::Boolean->_true;
    }
    return Tree::XPathEngine::Boolean->_false;
}

sub contains {
    my $self = shift;
    my ($node, @params) = @_;
    die "starts-with: incorrect number of params\n" unless @params == 2;
    my $value = $params[1]->xpath_string_value;
    if ($params[0]->xpath_string_value =~ /\Q$value\E/) {
        return Tree::XPathEngine::Boolean->_true;
    }
    return Tree::XPathEngine::Boolean->_false;
}

sub substring_before {
    my $self = shift;
    my ($node, @params) = @_;
    die "starts-with: incorrect number of params\n" unless @params == 2;
    my $long = $params[0]->xpath_string_value;
    my $short= $params[1]->xpath_string_value;
    if( $long=~ m{^(.*?)\Q$short})  {
        return Tree::XPathEngine::Literal->new($1); 
    }
    else {
        return Tree::XPathEngine::Literal->new('');
    }
}

sub substring_after {
    my $self = shift;
    my ($node, @params) = @_;
    die "starts-with: incorrect number of params\n" unless @params == 2;
    my $long = $params[0]->xpath_string_value;
    my $short= $params[1]->xpath_string_value;
    if( $long=~ m{\Q$short\E(.*)$}) {
        return Tree::XPathEngine::Literal->new($1);
    }
    else {
        return Tree::XPathEngine::Literal->new('');
    }
}


sub substring {
    my $self = shift;
    my ($node, @params) = @_;
    die "substring: Wrong number of parameters\n" if (@params < 2 || @params > 3);
    my ($str, $offset, $len);
    $str = $params[0]->xpath_string_value;
    $offset = $params[1]->value;
    $offset--; # uses 1 based offsets
    if (@params == 3) {
        $len = $params[2]->value;
        return Tree::XPathEngine::Literal->new(substr($str, $offset, $len));
    }
    else {
        return Tree::XPathEngine::Literal->new(substr($str, $offset));
    }
}

sub string_length {
    my $self = shift;
    my ($node, @params) = @_;
    die "string-length: Wrong number of params\n" if @params > 1;
    if (@params) {
        return Tree::XPathEngine::Number->new(length($params[0]->xpath_string_value));
    }
    else {
        return Tree::XPathEngine::Number->new(
                length($node->xpath_string_value)
                );
    }
}

sub normalize_space {
    my $self = shift;
    my ($node, @params) = @_;
    die "normalize-space: Wrong number of params\n" if @params > 1;
    my $str;
    if (@params) {
        $str = $params[0]->xpath_string_value;
    }
    else {
        $str = $node->xpath_string_value;
    }
    $str =~ s/^\s*//;
    $str =~ s/\s*$//;
    $str =~ s/\s+/ /g;
    return Tree::XPathEngine::Literal->new($str);
}

sub translate {
    my $self = shift;
    my ($node, @params) = @_;
    die "translate: Wrong number of params\n" if @params != 3;
    local $_ = $params[0]->xpath_string_value;
    my $find = $params[1]->xpath_string_value;
    my $repl = $params[2]->xpath_string_value;
    $repl= substr( $repl, 0, length( $find));
    my %repl;
    @repl{split //, $find}= split( //, $repl);
    s{(.)}{exists $repl{$1} ? defined $repl{$1} ? $repl{$1} : '' : $1 }ges;
    return Tree::XPathEngine::Literal->new($_);
}

### BOOLEAN FUNCTIONS ###

sub boolean {
    my $self = shift;
    my ($node, @params) = @_;
    die "boolean: Incorrect number of parameters\n" if @params != 1;
    return $params[0]->xpath_to_boolean;
}

sub not {
    my $self = shift;
    my ($node, @params) = @_;
    $params[0] = $params[0]->xpath_to_boolean unless $params[0]->isa('Tree::XPathEngine::Boolean');
    $params[0]->value ? Tree::XPathEngine::Boolean->_false : Tree::XPathEngine::Boolean->_true;
}

sub true {
    my $self = shift;
    my ($node, @params) = @_;
    die "true: function takes no parameters\n" if @params > 0;
    Tree::XPathEngine::Boolean->_true;
}

sub false {
    my $self = shift;
    my ($node, @params) = @_;
    die "true: function takes no parameters\n" if @params > 0;
    Tree::XPathEngine::Boolean->_false;
}

sub lang {
    my $self = shift;
    my ($node, @params) = @_;
    die "lang: function takes 1 parameter\n" if @params != 1;
    my $lang = $node->findvalue('(ancestor-or-self::*[@xml:lang]/@xml:lang)[last()]');
    my $lclang = lc($params[0]->xpath_string_value);
    # warn("Looking for lang($lclang) in $lang\n");
    if (substr(lc($lang), 0, length($lclang)) eq $lclang) {
        return Tree::XPathEngine::Boolean->_true;
    }
    else {
        return Tree::XPathEngine::Boolean->_false;
    }
}

### NUMBER FUNCTIONS ###

sub number {
    my $self = shift;
    my ($node, @params) = @_;
    die "number: Too many parameters\n" if @params > 1;
    if (@params) {
        if ($params[0]->isa('Tree::XPathEngine::Node')) {
            return Tree::XPathEngine::Number->new(
                    $params[0]->xpath_string_value
                    );
        }
        return $params[0]->xpath_to_number;
    }
    
    return Tree::XPathEngine::Number->new( $node->xpath_string_value );
}

sub sum {
    my $self = shift;
    my ($node, @params) = @_;
    die "sum: Parameter must be a NodeSet\n" unless $params[0]->isa('Tree::XPathEngine::NodeSet');
    my $sum = 0;
    foreach my $node ($params[0]->get_nodelist) {
        $sum += $self->number($node)->value;
    }
    return Tree::XPathEngine::Number->new($sum);
}

sub floor {
    my $self = shift;
    my ($node, @params) = @_;
    require POSIX;
    my $num = $self->number($node, @params);
    return Tree::XPathEngine::Number->new(
            POSIX::floor($num->value));
}

sub ceiling {
    my $self = shift;
    my ($node, @params) = @_;
    require POSIX;
    my $num = $self->number($node, @params);
    return Tree::XPathEngine::Number->new(
            POSIX::ceil($num->value));
}

sub round {
    my $self = shift;
    my ($node, @params) = @_;
    my $num = $self->number($node, @params);
    require POSIX;
    return Tree::XPathEngine::Number->new(
            POSIX::floor($num->value + 0.5)); # Yes, I know the spec says don't do this...
}

1;

__END__
=head1 NAME

Tree::XPathEngine::Function - evaluates XPath functions

=head1 METHODS

=head2 new 

=head2 evaluate 

evaluate the function on a nodeset

=head2 _execute

evaluate the function on a nodeset

=head2 as_string 

dump the function call as a string

=head2 as_xml 

dump the function call as xml

=head2 XPath methods

See the specs for details

=over 4

=item last 
=item position 
=item count 
=item id 
=item name 
=item string 

=item concat 
=item starts_with 
=item contains 
=item substring
=item substring_after
=item substring_before
=item string_length 
=item normalize_space 
=item translate 
=item boolean 
=item not 
=item true 
=item false 
=item lang 
=item number 
=item sum 
=item floor 
=item ceiling 
=item round 

=back
