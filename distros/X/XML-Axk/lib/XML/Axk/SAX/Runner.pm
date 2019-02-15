#!/usr/bin/env perl
# XML::Axk::SAX::Runner - Process an XML file using SAX.
# Copyright (c) 2018 cxw42.  All rights reserved.  Artistic 2.

package XML::Axk::SAX::Runner;
use XML::Axk::Base;
use XML::Axk::SAX::Handler;

use XML::SAX::ParserFactory;
use Object::Tiny qw(axkcore handler parser);

sub run {
    my ($self, $fh, $infn) = @_ or croak("Need a filehandle and filename");

    eval { $self->parser->parse_file($fh); };
    die $@ if $@ and ($@ !~ /^Empty Stream/);   # Empty streams are not an error

    #say "--- Got XML:\n", $self->handler->{Document}->toString, "\n---\n";
} #run()

sub new
{
    my ($class, $core, @args) = @_;
    croak "Need an XML::Axk::Core" unless ref $core eq "XML::Axk::Core";

    my $handler = XML::Axk::SAX::Handler->new($core);
    my $parser = XML::SAX::ParserFactory->parser( Handler => $handler );

    my $self = $class->SUPER::new(
        axkcore => $core, handler => $handler, parser => $parser,
        @args
    );

    return $self;
} #new()

1;
# vi: set ts=4 sts=4 sw=4 et ai fo-=ro foldmethod=marker foldlevel=2: #
