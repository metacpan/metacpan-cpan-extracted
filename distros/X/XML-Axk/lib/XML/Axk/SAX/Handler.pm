#!/usr/bin/env perl
# XML::Axk::SAX::Handler - Process an XML file using SAX.
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.
# I am using SAX rather than XML::LibXML::Reader because I want full control
# over the DOM document throughout the processing.

package XML::Axk::SAX::Handler;
use XML::Axk::Base;
use XML::Axk::DOM;

use parent 'XML::Axk::SAX::BuildDOM2';
# General strategy: when encountering an element, call SUPER, then process.
# When leaving an element, process, call SUPER, then remove the node we just
# left from the DOM to keep the memory consumption down.

sub new
{
    my ($class, $core, @args) = @_;
    croak "Need an XML::Axk::Core" unless ref $core eq "XML::Axk::Core";

    my $self = $class->SUPER::new(@args);
    $self->{axkcore} = $core;
    return $self;
}

sub work {
    my ($self, $now) = @_;
    $self->{axkcore}->_run_worklist(
        $now,
        # The new core parameters (CPs)
        document => $self->{Document},
        record => $self->{Element}
    );
}

# Handlers ============================================================== {{{1

sub start_document {
    my $self = shift;
    $self->SUPER::start_document(@_);
    $self->work(HI);
} #start_document()

sub end_document {
    my $self = shift;
    $self->work(BYE);
    $self->SUPER::end_document(@_);
} #end_document()

#sub characters {
#    my $self = shift;
#    $self->SUPER::characters(@_);
#} #characters()

sub start_element {
    my $self = shift;
    $self->SUPER::start_element(@_);
    $self->work(HI);
} #start_element()

sub end_element {
    my $self = shift;
    $self->work(BYE);
    $self->SUPER::end_element(@_);
} #end_element()

#sub entity_reference {
#    my $self = shift;
#    $self->SUPER::entity_reference(@_);
#} #entity_reference()

sub comment {
    my $self = shift;
    $self->SUPER::comment(@_);
    $self->work(HI); # no BYE for comments
} #comment()

# }}}1
# Unimplemented routines ================================================ {{{3
# Ones we don't need to override
#start_cdata
#end_cdata

# Not doing these yet
#doctype_decl
#attlist_decl
#xml_decl
#entity_decl
#unparse_decl
#element_decl
#notation_decl
#processing_instruction

# }}}3
1;
__END__
# Documentation ========================================================= {{{3
# }}}3
# vi: set ts=4 sts=4 sw=4 et ai fo-=ro foldmethod=marker foldlevel=2 fo=cql: #
