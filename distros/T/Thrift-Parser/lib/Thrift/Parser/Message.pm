package Thrift::Parser::Message;

=head1 NAME

Thrift::Parser::Message - Message object

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use base qw(Class::Accessor::Grouped);
__PACKAGE__->mk_group_accessors(simple => qw(method type seqid arguments));

=head1 USAGE

=head2 method

Returns the L<Thrift::Parser::Method> class that is represented in this message.

=head2 type

Returns the L<Thrift> type id of this message.

=head2 seqid

A L<Thrift> sequence ID.

=head2 arguments

A L<Thrift::Parser::FieldSet> object representing the arguments of this message.

=cut

sub new {
    my ($class, $self) = @_;
    $self ||= {};
    return bless $self, $class;
}

=head2 compose_reply

  my $reply_message = $message->compose_reply($reply);

A helper method, use this to compose a new message which is a reply to another message.  Expects the type of the reply to correspond with the L<Thrift::Parser::Method/return_class>.  C<seqid> is inherited.

=cut

sub compose_reply {
    my ($self, $reply) = @_;
    my $class = ref $self;

    return $class->new({
        type => TMessageType::REPLY,
        arguments => Thrift::Parser::FieldSet->new({ fields => [
            Thrift::Parser::Field->new({
                id    => 0,
                name  => 'return_value',
                value => $self->method->return_class->compose_with_idl($self->method->idl->returns, $reply),
            }),
        ] }),
        seqid => $self->seqid,
        method => $self->method,
    });
}

=head2 compose_reply_exception

  my $reply_message = $message->compose_reply_exception($exception);

  my $reply_message = $message->compose_reply_exception({
      ouch => {
          message => 'you made a mistake,
      }
  });

A helper method, use this to compose a new message which is a reply to another message.  Expects the type of the reply to correspond with one of the L<Thrift::Parser::Method/throw_classes>.  C<seqid> is inherited.  You may pass it a blessed object or a hashref with one key (the name of the throw you're using).

=cut

sub compose_reply_exception {
    my ($self, $throw) = @_;
    my $class = ref $self;

    if (ref($throw) eq 'HASH') {
        my @keys = keys %$throw;
        Thrift::Parser::InvalidArgument->throw("compose_reply_exception() must be passed a hash with exactly one key")
            if int @keys != 1;

        my $throw_class = $self->method->throw_classes->{$keys[0]};
        Thrift::Parser::InvalidArgument->throw(
                error => "Method ".$self->method." doesn't have a throw named '$keys[0]'",
                key => $keys[0],
            ) if ! $throw_class;

        $throw = $throw_class->compose(%{ $throw->{$keys[0]} });
    }

    # Get the Thrift::IDL::Field that represents this named throw in the IDL::Method throws() array
    # TODO: This is not perfect; if the Method has more than one throw of the same type,
    # we won't know which to use (i.e., "throws (1: InvalidArguments ouch, 2: InvalidArguments pain)")
    my ($field) = grep { $_->type->name eq $throw->name } @{ $self->method->idl->throws };
    if (! $field) {
        die "Couldn't find a throw in method ".$self->method->idl->name." with the type ".$throw->name;
    }

    return $class->new({
        type => TMessageType::REPLY,
        arguments => Thrift::Parser::FieldSet->new({ fields => [
            Thrift::Parser::Field->new({
                id    => $field->id,
                name  => $field->name,
                value => $throw,
            }),
        ] }),
        seqid => $self->seqid,
        method => $self->method,
    });
}

=head2 compose_reply_application_exception

  my $reply_message = $message->compose_reply_application_exception($error, $code);

A helper method, use this to compose a new message which is a reply to another message.  Throws as L<TApplicationException> with the error message and code as passed.  seqid is inherited.

=cut

sub compose_reply_application_exception {
    my ($self, $error, $code) = @_;
    my $class = ref $self;

    $code ||= TApplicationException::UNKNOWN;

    return $class->new({
        type => TMessageType::EXCEPTION,
        arguments => Thrift::Parser::FieldSet->new({ fields => [
            Thrift::Parser::Field->new({
                id    => 1,
                name  => 'message',
                value => Thrift::Parser::Type::string->new({ value => $error }),
            }),
            Thrift::Parser::Field->new({
                id    => 2,
                name  => 'type',
                value => Thrift::Parser::Type::i32->new({ value => $code }),
            }),
        ] }),
        seqid => $self->seqid,
        method => $self->method,
    });
}

sub write {
    my ($self, $output) = @_;

    $output->writeMessageBegin($self->method->name, $self->type, $self->seqid);
    $self->arguments->write($output);
    $output->writeMessageEnd();
    $output->getTransport->flush();
}

=head1 COPYRIGHT

Copyright (c) 2009 Eric Waters and XMission LLC (http://www.xmission.com/).  All rights reserved.  This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 AUTHOR

Eric Waters <ewaters@gmail.com>

=cut

1;
