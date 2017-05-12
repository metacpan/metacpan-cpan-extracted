package Thrift::Parser;

=head1 NAME

Thrift::Parser - A Thrift message (de)serialization OO representation

=head1 SYNOPSIS

  use Thrift;
  use Thrift::Parser;
  use Thrift::IDL;

  my $parser = Thrift::Parser->new(
      idl => Thrift::IDL->parse_thrift_file('tutorial.thrift'),
      service => 'Calculator',
  );

  ## Parse a payload

  # Obtain a Thrift::Protocol subclass somehow with a loaded buffer
  my $buffer   = ...;
  my $protocol = Thrift::BinaryProtocol->new($buffer);

  my $message = $parser->parse_message($protocol);

  print "Received method call " . $message->method->name . "\n";

  ## Use the auto-generated classes to create request/responses

  my $request = tutorial::Calculator::add->compose_message_call(
    num1 => 15,
    num2 => 33,
  );

  my $response = $request->compose_reply(48);

=head1 DESCRIPTION

This module provides strict typing and full object orientation of all the Thrift types.  It allows you, with a L<Thrift::IDL> object, to create a parser which can parse any L<Thrift::Protocol> object into a message object, and creates dynamic classes according to the IDL specification, allowing you to create method calls, objects, and responses.

=cut

use strict;
use warnings;
use Thrift;
use Params::Validate;
use Data::Dumper;
use File::Path; # mkpath, for full_docs_to_dir
use base qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw(idl service built_classes));
use Carp;

use Thrift::Parser::Types;
use Thrift::Parser::Method;
use Thrift::Parser::Exceptions;
use Thrift::Parser::Message;
use Thrift::Parser::Field;
use Thrift::Parser::FieldSet;

our $VERSION = '0.06';

=head1 METHODS

=head2 new

  my $parser = Thrift::Parser->new(
    idl => Thrift::IDL->parse_thrift_file('..'),
    service => 'myServiceName',
  )

Creates the Parser object and dynamic classes from the IDL file.

=cut

sub new {
    my $class = shift;

    my %self = validate(@_, {
        idl => 1,
        service => 1,
    });

    my $self = bless \%self, $class;

    $self->_load_service($self->{service});
    $self->_build_classes();

    return $self;
}

sub _load_service {
    my ($self, $service_name, $basename, $service_extended) = @_;

    #print "_load_service($service_name, ".($basename || 'undef').")\n";

    ## Find the Service object that I'll be implementing

    my ($service, $found_service);
    foreach $service (@{ $self->idl->services }) {
        next if $service->name ne $service_name;
        if ($basename) {
            next if $service->{header}{basename} ne $basename;
        }
        $found_service = $service;
        last;
    }

    if (! $found_service) {
        my $full_name = ($basename ? $basename . '.' : '') . $service_name;
        die "The service named '$full_name' is not implemented in the IDL document passed ("
            .join(', ', map { ($_->{header}{basename} ? $_->{header}{basename} . '.' : '') . $_->name } @{ $self->idl->services }).")";
    }
    $service = $found_service;

    # Copy all the methods into a lookup hash by name
    foreach my $method (@{ $service->methods }) {
        my $namespace = $service->{header}->namespace('perl');
        my $message_class = ($namespace ? $namespace . '::' : '')
            . ($service_extended || $service->name) . '::' . $method->name;

        $self->{methods}{ $method->name } = {
            idl => $method,
            class => $message_class,
        };
    }

    # If this service extends another service, load that too
    if ($service->extends) {
        my ($extends_namespace, $extends_service_name) = $service->extends =~ m{^([^.]+) \. ([^.]+)$}x;
        $extends_service_name ||= $service->extends;
        $self->_load_service($extends_service_name, $extends_namespace, ($service_extended || $service_name));
    }
}

sub _build_classes {
    my $self = shift;

    my @build;

    foreach my $method_name (keys %{ $self->{methods} }) {
        my $details = $self->{methods}{$method_name};
        push @build, {
            class => $details->{class},
            base  => 'Thrift::Parser::Method',
            idl   => $details->{idl},
            name  => $method_name,
            accessors => {
                return_class => $self->idl_type_class($details->{idl}->returns),
                throw_classes => {
                    map { $_->name => $self->idl_type_class($_->type) }
                    @{ $details->{idl}->throws }
                },
            },
        };
    }

    foreach my $struct (@{ $self->idl->structs }) {
        my $namespace = $struct->{header}->namespace('perl');
        push @build, {
            class => join ('::', (defined $namespace ? ($namespace) : ()), $struct->name),
            base  => $struct->isa('Thrift::IDL::Exception') ? 'Thrift::Parser::Type::Exception' : 'Thrift::Parser::Type::Struct',
            idl   => $struct,
            name  => $struct->name,
        };
    }

    foreach my $enum (@{ $self->idl->enums }) {
        my $namespace = $enum->{header}->namespace('perl');
        push @build, {
            class => join ('::', (defined $namespace ? ($namespace) : ()), $enum->name),
            base  => 'Thrift::Parser::Type::Enum',
            idl   => $enum,
            name  => $enum->name,
        };
    }

    foreach my $typedef (@{ $self->idl->typedefs }) {
        my $namespace = $typedef->{header}->namespace('perl');
        push @build, {
            class => join ('::', (defined $namespace ? ($namespace) : ()), $typedef->name),
            base  => 'Thrift::Parser::Type::' . lc $typedef->type->name,
            idl   => $typedef,
            name  => $typedef->name,
        };
    }

    foreach my $build (@build) {
        #print STDERR "Building $$build{class} (base $$build{base})\n";

        eval <<EOF;
package $$build{class};

use strict;
use warnings;
use base qw($$build{base});
EOF
        die $@ if $@;

        $build->{class}->idl($build->{idl});
        $build->{class}->idl_doc($self->idl);
        $build->{class}->name($build->{name});
        
        $build->{accessors} ||= {};
        while (my ($key, $value) = each %{ $build->{accessors} }) {
            $build->{class}->$key($value);
        }
    }

    $self->built_classes(\@build);
}

=head2 parse_message

  my $message = $parser->parse_message($transport);

Given a L<Thrift::Transport> object, the parser will create a L<Thrift::Parser::Message> object.

=cut

sub parse_message {
    my ($self, $input) = @_;

    my %meta;
    $input->readMessageBegin(\$meta{method}, \$meta{type}, \$meta{seqid});

    my $method_details = $self->{methods}{$meta{method}};
    my $idl = $method_details->{idl};
    if (! $idl) {
        die "No way to process unknown method '$meta{method}'"; # TODO
    }

    my $idl_fields = [];
    if ($meta{type} == TMessageType::CALL || $meta{type} == TMessageType::ONEWAY) {
        $idl_fields = $idl->arguments;
    }
    elsif ($meta{type} == TMessageType::REPLY) {
        $idl_fields = [
            Thrift::IDL::Field->new({ id => 0, type => $idl->returns, name => '_return_value' }),
            @{ $idl->throws }
        ];
    }
    elsif ($meta{type} == TMessageType::EXCEPTION) {
        $idl_fields = [
            Thrift::IDL::Field->new({ id => 1, name => 'message', type => Thrift::IDL::Type::Base->new({ name => 'string' }) }),
            Thrift::IDL::Field->new({ id => 2, name => 'code',    type => Thrift::IDL::Type::Base->new({ name => 'i32' }) }),
        ];
    }

    my $arguments = $self->parse_structure($input, $idl_fields);

    # Finish reading the message
    $input->readMessageEnd();

    my $message = Thrift::Parser::Message->new({
        method    => $method_details->{class},
        type      => $meta{type},
        seqid     => $meta{seqid},
        arguments => $arguments,
    });

    return $message;
}

=head2 full_docs_to_dir

  $parser->full_docs_to_dir($dir, $format);

Using the dynamically generated classes, this will create 'pod' or 'pm' files in the target directory in the following format:

  $dir/tutorial::Calculator::testVars.pod
  (or with format 'pm')
  $dir/tutorial/Calculator/testVars.pm

The directory will be created if it doesn't exist.

=cut

sub full_docs_to_dir {
    my ($self, $dir, $format, $ignore_existing) = @_;
    my $class = ref $self;
    $format ||= 'pod';

    foreach my $built (@{ $self->built_classes }) {
        my $filename;

        if ($format eq 'pod') {
            $filename = $dir . '/' . $built->{class} . '.pod';
        }
        elsif ($format eq 'pm') {
            $filename = $dir . '/' . $built->{class} . '.pm';
            $filename =~ s{::}{/}g;
        }

        if ($ignore_existing && -f $filename) {
            next;
        }

        my $pod = $built->{class}->docs_as_pod( $built->{base} );

        my ($base_path) = $filename =~ m{^(.+)/[^/]+$};
        -d $base_path || mkpath($base_path) || die "Can't mkpath $base_path: $!";

        open my $podfh, '>', $filename or die "Can't open '$filename' for writing: $!";
        print $podfh $pod;
        close $podfh;
    }
}

=head1 INTERNAL METHODS

=head2 parse_structure

  my $fieldset = $parser->parse_structure($transport, $thrift_idl_method->arguments);

Returns a L<Thrift::Parser::FieldSet>.  Attempts to read a structure off the transport, using an array of L<Thrift::IDL::Field> objects to define the specification of the structure.

=cut

sub parse_structure {
    my ($self, $input, $idl_fields) = @_;

    # Preprocess the list of IDL fields
    my %idl_fields_by_id;
    $idl_fields ||= [];
    foreach my $field (@$idl_fields) {
        $idl_fields_by_id{ $field->id } = $field;
    }

    my @fields;

    $input->readStructBegin();
    while (1) {
        my %meta;

        $input->readFieldBegin(\$meta{name}, \$meta{type}, \$meta{id});

        last if $meta{type} == TType::STOP;

        # Reference the Thrift::IDL::Field if present
        $meta{idl} = $idl_fields_by_id{$meta{id}};

        # Read the value of the field from the input
        my $value = $self->parse_type($input, \%meta);
        push @fields, Thrift::Parser::Field->new({
            id => $meta{id},
            value => $value,
            name => ($meta{idl} ? $meta{idl}{name} : undef),
        });

        $input->readFieldEnd();
    }
    $input->readStructEnd();

    return Thrift::Parser::FieldSet->new({ fields => \@fields });
}

=head2 parse_type

  my $typed_value = $parser->parse_type($transport, { idl => $thrift_idl_type_object || type => 4 });

Reads a single value off the transport and returns it as an object in a L<Thrift::Parser::Type> subclass.

=cut

sub parse_type {
    my ($self, $input, $meta) = @_;

    my $type_class;
    if ($meta->{idl}) {
        $type_class = $self->idl_type_class($meta->{idl}{type});
    }
    else {
        # Field didn't correspond with an expected field from the IDL
        my $type_name = Thrift::Parser::Types->to_name($meta->{type});
        if (! defined $type_name) {
            die "Failed to find type name from type id $$meta{type}; " . Dumper($meta);
        }
        $type_class = 'Thrift::Parser::Type::' . lc $type_name;
    }

    my $typed_value = $type_class->new();
    if ($typed_value->can('read')) {
        $typed_value->read($self, $input, $meta);
        return $typed_value;
    }

    my $read_method = Thrift::Parser::Types->read_method($meta->{type});
    if ($input->can($read_method)) {
        $input->$read_method(\$meta->{value});
        $typed_value->value($meta->{value});
    }
    else {
        my $type = Thrift::Parser::Types->to_name($meta->{type});
        die "Don't know how to read $type; tried $read_method";
    }

    return $typed_value;
}

=head2 idl_type_class

  my $parser_type_class = $parser->idl_type_class($thrift_idl_type_object);

Maps the given L<Thrift::IDL::Type> object to one in my parser namespace.  If it's a custom type, it'll map into a dynamic class.

=cut

sub idl_type_class {
    my ($self, $type) = @_;
    if ($type->isa('Thrift::IDL::Type::Custom')) {
        my $referenced_type = $self->idl->object_full_named($type->full_name);
        if (! $referenced_type) {
            die "Couldn't find definition of custom type '".$type->full_name."'";#; ".Dumper($self->idl);
        }
        my $namespace = $referenced_type->{header}->namespace('perl');
        return join '::', (defined $namespace ? ($namespace) : ()), $type->local_name;
    }
    else {
        return 'Thrift::Parser::Type::' . $type->name;
    }
}

=head2 resolve_idl_type

  my $thrift_idl_type_object = $parser->resolve_idl_type($thrift_idl_custom_type_object);

Returns the base L<Thrift::IDL::Type> object from the given L<Thrift::IDL::Type::Custom> object

=cut

# FIXME: Shouldn't this be in L<Thrift::IDL>?

sub resolve_idl_type {
    my ($self, $type) = @_;
    while ($type->isa('Thrift::IDL::Type::Custom')) {
        $type = $self->idl->object_named($type->name)->type;
    }
    return $type;
}

=head1 SEE ALSO

L<Thrift>, L<Thrift::IDL>

=head1 DEVELOPMENT

This module is being developed via a git repository publicly available at L<http://github.com/ewaters/thrift-parser>.  I encourage anyone who is interested to fork my code and contribute bug fixes or new features, or just have fun and be creative.

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
