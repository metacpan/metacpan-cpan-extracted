package VS::RuleEngine::Writer::XML;

use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed);
use XML::LibXML;

use VS::RuleEngine::Engine;
use VS::RuleEngine::Util qw(is_existing_package);

our $VERSION = "0.03";

sub _new {
    my ($pkg) = @_;
    my $self = bless { 
    }, $pkg;
    return $self;
}

sub to_file {
    my ($self, $engine, $path) = @_;
    my $xml = $self->_engine_to_doc($engine);
    $xml->toFile($path);
}

our $XML_FORMAT = 1;
sub as_xml {
    my ($self, $engine) = @_;
    my $doc = $self->_engine_to_doc($engine);
    return $doc->serialize($XML_FORMAT);
}

sub _engine_to_doc {
    my ($self, $engine) = @_;
    
    croak "Engine is undefined" if !defined $engine;
    croak "Not a VS::RuleEngine::Engine instance" if !(blessed $engine && $engine->isa("VS::RuleEngine::Engine"));
    
    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElement("engine");
    $doc->setDocumentElement($root);

    if (ref $engine ne "VS::RuleEngine::Engine") {
        my $engine_class = ref $engine;
        $root->setAttribute(instanceOf => $engine_class);
    }
    # Defaults
    for my $defaults_name (sort $engine->defaults) {
        my $values = $engine->get_defaults($defaults_name);
        my $defaults = $doc->createElement("defaults");
        $defaults->setAttribute(name => $defaults_name);
        for my $key (sort keys %$values) {
            $defaults->appendTextChild($key, $values->{$key});
        }
        $root->addChild($defaults)
    }
    
    # Actions
    for my $action (sort $engine->actions) {
        my $decl = $engine->_get_action($action);
        my $entity = _decl_to_element("action", $action, $doc, $decl);
        $root->addChild($entity);
    }

    # Inputs
    for my $input (sort $engine->inputs) {
        my $decl = $engine->_get_input($input);
        my $entity = _decl_to_element("input", $input, $doc, $decl);
        $root->addChild($entity);
    }

    # Prehooks
    for my $hook (@{$engine->_pre_hooks}) {
        my $decl = $engine->_get_hook($hook);
        my $entity = _decl_to_element("prehook", $hook, $doc, $decl);
        $root->addChild($entity);        
    }
    
    my %actionmap;

    # Rule comes here
    for my $rule (@{$engine->_rule_order}) {
        my $decl = $engine->_get_rule($rule);
        my $entity = _decl_to_element("rule", $rule, $doc, $decl);
        $root->addChild($entity);
        
        for my $action (@{$engine->_get_rule_actions($rule)}) {
            push @{$actionmap{$action}}, $rule;
        }
        
    }
    
    # Rule -> Action mapping
    for my $action (sort keys %actionmap) {
        my $run = $doc->createElement("run");
        $run->setAttribute("action" => $action);
        for my $rule (@{$actionmap{$action}}) {
            my $rule_elem = $doc->createElement("rule");
            $rule_elem->appendText($rule);
            $run->addChild($rule_elem);
        }
        $root->addChild($run);
    }
    
    # Posthooks
    for my $hook (@{$engine->_post_hooks}) {
        my $decl = $engine->_get_hook($hook);
        my $entity = _decl_to_element("posthook", $hook, $doc, $decl);
        $root->addChild($entity);        
    }
    
    # Outputs
    for my $output (sort $engine->outputs) {
        my $decl = $engine->_get_output($output);
        my $entity = _decl_to_element("output", $output, $doc, $decl);
        $root->addChild($entity);
    }

    return $doc;
}

sub _decl_to_element {
    my ($type, $name, $doc, $decl) = @_;
    
    my $entity = $doc->createElement($type);

    $entity->setAttribute("name" => $name);
    $entity->setAttribute("instanceOf" => $decl->_pkg);
    
    my $defaults = $decl->_defaults;
    if ($defaults && @$defaults) {
        $entity->setAttribute("defaults" => join(", ", @$defaults));
    }
    
    _args_to_element($doc, $entity, $decl->_pkg, $decl->_args);
    
    return $entity;
}

sub _args_to_element {
    my ($doc, $parent, $pkg, $args) = @_;
    
    if (!is_existing_package($pkg)) {
        eval "require ${pkg};";
        croak $@ if $@;
    }
    
    if ($pkg->can("process_xml_writer_args")) {
        $pkg->process_xml_writer_args($doc, $parent, @$args);
        return;
    }
    
    if (!(@$args & 1)) {
        my %args = @$args;
        for my $key (sort keys %args) {
            $parent->appendTextChild($key, $args{$key});
        }
    }
}

1;
__END__

=head1 NAME

VS::RuleEngine::Writer::XML - Store VS::RuleEngine engine declarations as XML

=head1 SYNOPSIS

  use VS::RuleEngine::Writer::XML;
  
  my $xml = VS::RuleEngine::Writer::XML->as_xml($engine);
  
  VS::RuleEngine::Loader::XML->to_file($engine, "my_engine.xml");
  
=head1 DESCRIPTION

This module provides a mean to write VS::RuleEngine engine declarations to XML.

=head1 INTERFACE
    
=head2 CLASS METHODS

=over 4

=item as_xml ( ENGINE )

Returns a XML-representation of I<ENGINE>

=item to_file ( ENGINE, PATH )

Creates a XML-representation of I<ENGINE> and saves it at I<PATH>.

=back

=head1 XML Document structure

The structure of the XML created by this writer is described in 
L<VS::RuleEngine::Loader::XML/XML Document structure>. 

Arguments to entities (actions, inputs, hooks, outputs and rules) will be tested to see 
if it's a single hash reference and if so be written as such using the key as element name 
and the value as the elements text content.
 
However, if the implementing class of the entitiy implements the method 
C<process_xml_writers_args> this will be called as a class method and is responsible 
for adding children to the element. The arguments to the method are the document as 
a C<XML::LibXML::Document>-instance, the entity-element as C<XML::LibXML::Element>-instance 
which to add children to and a list of the arguments encapsulated by 
C<VS::RuleEngine::TypeDecl>-instance that represents the entity.

=head1 SEE ALSO

L<VS::RuleEngine>

L<VS::RuleEngine::Loader::XML>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-vs-ruleengine-writer-xml@rt.cpan.org>, 
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
