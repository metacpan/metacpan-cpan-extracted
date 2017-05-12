package VS::RuleEngine::Loader::XML;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed);
use XML::LibXML;

use VS::RuleEngine::Engine;
use VS::RuleEngine::Util qw(is_existing_package);

use Object::Tiny qw(_ruleset);

our $VERSION = "0.05";

sub _new {
    my ($pkg) = @_;
    my $self = bless { 
        _ruleset => {},
    }, $pkg;
    return $self;
}

sub load_file {
    my ($self, $path) = @_;
    
    my $parser  = XML::LibXML->new();
    my $doc     = $parser->parse_file($path);
    my $engine  = $self->_process_document($doc);
        
    return $engine;
}

sub load_string {
    my ($self, $xml) = @_;
    
    my $parser  = XML::LibXML->new();
    my $doc     = $parser->parse_string($xml);
    my $engine  = $self->_process_document($doc);
        
    return $engine;
}

{
    my %Node_Handler = (
        action      => "_process_action",
        defaults    => "_process_defaults",
        input       => "_process_input",
        output      => "_process_output",
        posthook    => "_process_posthook",
        prehook     => "_process_prehook",
        rule        => "_process_rule",
        ruleset     => "_process_ruleset",
        run         => "_process_run",
    );
    
    sub _process_document {
        my ($self, $doc) = @_;
    
        $self = __PACKAGE__->_new() unless blessed $self;

        # Clear rulesets
        $self->{_ruleset} = {};
    
        my $root = $doc->documentElement();
        croak ("Expected root node 'engine' but found '", $root->nodeName, "'") if $root->nodeName ne "engine";
    
        my $engine_class = "VS::RuleEngine::Engine";
        if ($root->hasAttribute("instanceOf")) {
            my $class = $root->getAttribute("instanceOf");
            if (!is_existing_package($class)) {
                eval "require ${class};";
                croak $@ if $@;
            }            
            
            $engine_class = $class;
        }

        my $engine = $engine_class->new();
    
        # Iterate over child nodes
        for my $child ($root->childNodes) {        
            # Skip stuff that's not elements
            next unless $child->isa("XML::LibXML::Element");
        
            my $name = $child->nodeName;
            my $handler = $Node_Handler{$name};
            croak "Don't know how to handle '${name}'" if !$handler;

            $self->$handler($child, $engine);
        }
    
        return $engine;
    }
}

sub _process_action {
    my ($self, $action, $engine) = @_;
    my ($name, $class, $defaults, @args) = $self->_process_std_element($action);
    $engine->add_action($name => $class, $defaults, @args);        
};

sub _process_input {
    my ($self, $input, $engine) = @_;
    my ($name, $class, $defaults, @args) = $self->_process_std_element($input);
    $engine->add_input($name => $class, $defaults, @args);
};

sub _process_output {
    my ($self, $output, $engine) = @_;
    my ($name, $class, $defaults, @args) = $self->_process_std_element($output);
    $engine->add_output($name => $class, $defaults, @args);
};

sub _process_prehook { 
    my ($self, $hook, $engine) = @_;
    my ($name, $class, $defaults, @args) = $self->_process_std_element($hook);
    $engine->add_hook($name => $class, $defaults, @args);
    $engine->add_pre_hook($name);
};

sub _process_posthook { 
    my ($self, $hook, $engine) = @_;
    my ($name, $class, $defaults, @args) = $self->_process_std_element($hook);
    $engine->add_hook($name => $class, $defaults, @args);
    $engine->add_post_hook($name);
};

sub _process_rule {
    my ($self, $rule, $engine) = @_;
    my ($name, $class, $defaults, @args) = $self->_process_std_element($rule);
    $engine->add_rule($name => $class, $defaults, @args);        
};

sub _process_defaults {
    my ($self, $defaults, $engine) = @_;
    
    my $name = $defaults->getAttribute("name");

    my @args;
    for my $arg ($defaults->childNodes) {
        next unless $arg->isa("XML::LibXML::Element");
        my $name = $arg->nodeName;
        my $value = $arg->hasChildNodes ? $arg->textContent : undef;
        push @args, $name => $value;
    }
    
    my $data = { @args };
    
    $engine->add_defaults($name, $data);
}

sub _process_ruleset {
    my ($self, $ruleset, $engine) = @_;
    
    my $name = $ruleset->getAttribute("name");
    
    croak "Ruleset '${name}' is already defined" if exists $self->_ruleset->{$name};
    
    # This does not apply to all rules in the engine
    # but rather to the ones we've added so far when
    # parsing
    my @rules;
    
    if ($ruleset->hasAttribute("rulesMatchingName")) {
        my $s   = $ruleset->getAttribute("rulesMatchingName");
        my $re  = qr/$s/;        
        
        my @matching_rules = sort grep { $_ =~ $re } $engine->rules;
        push @rules, @matching_rules;
    }

    if ($ruleset->hasAttribute("rulesOfClass")) {
        my $c = $ruleset->getAttribute("rulesOfClass");
        my @matching_rules = sort grep { 
            my $rule = $engine->_get_rule($_);
            UNIVERSAL::isa($rule->_pkg, $c) 
        } $engine->rules;
        
        push @rules, @matching_rules;
    }
    
    push @rules, $self->_process_rules($ruleset, $engine);
    
    @rules = sort keys %{+{ map { $_ => 1 } @rules }};
    
    $self->_ruleset->{$name} = \@rules;
}

sub _process_run {
    my ($self, $run, $engine) = @_;
    
    croak "Missing attribute 'action' for element 'run'" unless $run->hasAttribute("action");
    my $action = $run->getAttribute("action");
    croak "No action named '${action}' exists" unless $engine->has_action($action);
    
    my @rules = $self->_process_rules($run, $engine);
    
    for my $rule (@rules) {
        $engine->add_rule_action($rule => $action);
    }
}

sub _process_std_element {
    my ($self, $element) = @_;

    if (!$element->hasAttribute("name")) {
        croak $element->nodeName, " is missing mandatory attribute 'name'";
    }
    my $name = $element->getAttribute("name");

    if (!$element->hasAttribute("instanceOf")) {
        croak $element->nodeName, " is missing mandatory attribute 'instanceOf'";
    }
    my $class = $element->getAttribute("instanceOf");
    
    my $defaults = $element->getAttribute("defaults");
    $defaults = "" if !defined $defaults;
    $defaults = [split/,\s*|\s+/, $defaults];

    my @args = $self->_process_args($element, $class);    

    return ($name, $class, $defaults, @args);
}

sub _process_rules {
    my ($self, $element, $engine) = @_;
   
    my @rules;
    
    for my $rule ($element->childNodes) {
        next unless $rule->isa("XML::LibXML::Element");
        my $name = $rule->textContent;
        my $type = $rule->nodeName;
        
        ($name) = $name =~ /^\s*(.*?)\s*$/;
        croak "Empty '${type}' name" if $name eq '';
        
        if ($type eq 'rule') {    
            croak "No rule named '${name}' exists" unless $engine->has_rule($name);
            push @rules, $name;
        }
        elsif ($type eq 'ruleset') {
            croak "No ruleset named '${name}' exists" if !exists $self->_ruleset->{$name};
            push @rules, @{$self->_ruleset->{$name}};
        }
        else {
            croak "Expected rule or ruleset element but got '${type}'";
        }   
    }
    
    @rules = sort keys %{+{ map { $_ => 1 } @rules }};
    
    return @rules;
}

sub _process_args {
    my ($self, $element, $class) = @_;

    if (!is_existing_package($class)) {
        eval "require ${class};";
        croak $@ if $@;
    }
    
    if ($class->can("process_xml_loader_args")) {
        return $class->process_xml_loader_args($element);
    }
    
    my @args;
    for my $arg ($element->childNodes) {
        next unless $arg->isa("XML::LibXML::Element");
        my $name = $arg->nodeName;
        my $value = $arg->hasChildNodes ? $arg->textContent : undef;
        push @args, $name => $value;
    }
    
    return @args;
}

1;
__END__

=head1 NAME

VS::RuleEngine::Loader::XML - Load VS::RuleEngine engine declarations in XML

=head1 SYNOPSIS

  use VS::RuleEngine::Loader::XML;
  
  my $engine = VS::RuleEngine::Loader::XML->load_file("my_engine.xml");
  $engine->run();
  
  my $other_engine = VS::RuleEngine::Loader::XML->load_string($xml);
  $other_engine->run();
  
=head1 DESCRIPTION

This module provides a mean to load VS::RuleEngine engine declarations from XML.

=head1 INTERFACE
    
=head2 CLASS METHODS

=over 4

=item load_file ( PATH )

Loads the engine declaration from I<PATH>.

=item load_string ( XML )

Loads the engine declaration from I<XML>.

=back

=head1 XML Document structure

The document root element must be B<< <engine> >>. Valid children are:

=over

=item *

B<< <action> >> - Declares an action.

=item *

B<< <defaults> >> - Defines a default argument set

=item *

B<< <input> >> - Declares an input.

=item *

B<< <output> >> - Declares an output.

=item *

B<< <rule> >> - Declares a rule.

=item *

B<< <ruleset> >> - Groups a set of rules under a common name.

=item *

B<< <run> >> - Connects a set of rules to an action.

=back

=head2 Action, Input, Output and Rule elements

The elements B<< <action> >>, B<< <input> >>, B<< <output> >> and B<< <rule> >> all have 
the following mandatory attributes:

=over 4

=item name

The name of the entity to define in the engine.

=item instanceOf

The class that implements the entity and that'll be instansiated when the engine is runned.

=item defaults

The default arguments to the entity as defined by a previously declared B<< <defaults> >>. 
Separate multiple defaults with comma and/or whitespace.

=back

If the class defined by I<instanceOf> implements the method C<process_xml_loader_args> it will be 
called as a class method with the C<XML::LibXML::Element>-element as only argument. This method 
must return a list of arguments that will be passed to the constructor for the class when 
the entity is instansiated.

If no C<process_xml_loader_args> method is available the loader will interpret all children as a hash
where the elements name is the key and its text content its value. If a child is an empty element, 
that is has no children (as in C<< <foo/> >>) its value will be undef. This hash will be passed 
to the constructor as a hash reference.

=head2 Defaults

By using the tag B<< <defaults> >> t is possible to declare common arguments that can be 
reused by multiple entities. Its children will be interpreted as key/value pairs. The required 
attribute 'name' defines the name for the defaults.

=head2 Rulesets

By using the tag B<< <ruleset> >> it is possible to give a set of rules a shared name that can later be 
used when binding together rules and actions. 

The attribute I<name> is always expected and is used to give the ruleset its name which can be referenced 
later on by other rulesets or ruleE<lt>-E<gt>action mappings.

To specify what rules to include it expects B<< <rule>name of rule</rule >> and/or B<< <ruleset>name of ruleset</ruleset> >> elements 
as children. Any other element will result in an error.

In addition to specifying specific rules or contens of other rulesets it is also possible to 
include the rules that matches the criteria specified by the attributes:

=over 4

=item rulesMatchingName

Include all rules that matches the name by the given Perl5 regular expression.

=item rulesOfClass

Include all rules which inherits from the given class.

=back

Note, if both attributes above are present it does not create a ruleset with the rule that 
matches both (i.e a union).

=head2 Connecting rules and actions

To connect an action to a rule use the B<< <run> >> element. It expects the attribute 
I<action> which must be the name of an already defined action. Which rules to invoke the 
action on is specified with children of type B<< <rule>name of rule</rule >> and/or 
B<< <ruleset>name of ruleset</ruleset> >>. Any other element will result in an error.

=head1 SEE ALSO

L<VS::RuleEngine>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-vs-ruleengine-loader-xml@rt.cpan.org>, 
or through the web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Claes Jakobsson C<< <claesjac@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 - 2008, Versed Solutions C<< <info@versed.se> >>. All rights reserved.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
