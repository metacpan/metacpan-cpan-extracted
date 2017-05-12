package perfSONAR_PS::RequestHandler;

=head1 NAME

perfSONAR_PS::RequestHandler - A module that provides an object to register event
and message handlers for a perfSONAR Service.

=head1 DESCRIPTION

This module is used by the daemon in the pS-PS Daemon architecture. The daemon
creates a Handler object and passes it to each of the modules who, in turn,
register which message types or event types they are interested in.

=cut

use fields 'EV_HANDLERS', 'EV_REGEX_HANDLERS', 'MSG_HANDLERS', 'FULL_MSG_HANDLERS', 'MERGE_HANDLERS', 'EVENTEQUIVALENCECHECKERS', 'LOGGER';

use strict;
use warnings;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use perfSONAR_PS::Common;
use perfSONAR_PS::XML::Document_file;
use perfSONAR_PS::Messages;
use perfSONAR_PS::Error_compat qw/:try/;
use perfSONAR_PS::EventTypeEquivalenceHandler;
use perfSONAR_PS::ParameterValidation;

our $VERSION = 0.09;

=head1 API
=cut

=head2 new
    This function allocates a new Handler object.
=cut
sub new {
    my ($package) = @_;

    my $self = fields::new($package);

    $self->{LOGGER} = get_logger("perfSONAR_PS::RequestHandler");

    $self->{EV_HANDLERS} = ();
    $self->{EV_REGEX_HANDLERS} = ();
    $self->{MSG_HANDLERS} = ();
    $self->{FULL_MSG_HANDLERS} = ();
    $self->{MERGE_HANDLERS} = ();
    #$self->{EVENTEQUIVALENCECHECKER} = perfSONAR_PS::EventTypeEquivalenceHandler->new();
    $self->{EVENTEQUIVALENCECHECKERS} = ();

    return $self;
}

=head2 registerMergeHandler ($self, $messageType, \@eventTypes, $service)
    Registers a handler that will be used to merge two metadata where at least
    one of the metadata contains one of the event types specified in the passed
    in eventTypes array. The service element must implement the 'mergeMetadata'
    function.
=cut
sub registerMergeHandler {
    my ($self, $messageType, $eventTypes, $service) = validateParamsPos(@_,
            1,
            { type => SCALAR },
            { type => ARRAYREF },
            { can => 'mergeMetadata' },
        );

    if (not exists $self->{MERGE_HANDLERS}->{$messageType}) {
        $self->{MERGE_HANDLERS}->{$messageType} = ();
    }

    foreach my $ev (@{ $eventTypes }) {
        $self->{MERGE_HANDLERS}->{$messageType}->{$ev} = $service;
    }

    return 0;
}

=head2 registerEventEquivalence 
    Allows registration of equivalent eventTypes. This is a necessary step in
    merging to find out whether two metadata elements with differing eventTypes
    can be merged.
=cut
sub registerEventEquivalence {
    my ($self, $messageType, $eventType1, $eventType2) = @_;

    if (not defined $self->{EVENTEQUIVALENCECHECKERS}->{$messageType}) {
        $self->{EVENTEQUIVALENCECHECKERS}->{$messageType} = perfSONAR_PS::EventTypeEquivalenceHandler->new();
    }

    $self->{EVENTEQUIVALENCECHECKERS}->{$messageType}->addEquivalence($eventType1, $eventType2);

    return 0;
}

=head2 registerFullMessageHandler($self, $messageType, $service)
    This function is used by a pS service to specify that it would like to
    handle the complete processing for messages of the specified type. If
    called, the service must have a handleMessage function. This function
    will be called when a message of the specified type is received. The
    handleMessage function is then responsible for all handling of the
    message.
=cut
sub registerFullMessageHandler {
    my ($self, $messageType, $service) = validateParamsPos(@_,
                1,
                { type => SCALAR },
                { can => 'handleMessage'},
            );

    $self->{LOGGER}->debug("Adding message handler for $messageType");

    if (defined $self->{FULL_MSG_HANDLERS}->{$messageType}) {
        $self->{LOGGER}->error("There already exists a handler for message $messageType");
        return -1;
    }

    $self->{FULL_MSG_HANDLERS}->{$messageType} = $service;

    return 0;
}

=head2 registerMessageHandler($self, $messageType, $service)
    This function is used by a pS service to specify that it would like to
    be informed of all the metadata/data pairs for a given message. The
    handler will also inform the module when a new message of the specified
    type is received as well as when it has finished processing for the
    message. If a message handler is registered, the following functions
    must be defined in the $service specified: handleMessageBegin,
    handleMessageEnd and handleEvent. handleMessageBegin will be called
    when a new message of the specified type is received. handleEvent will
    be called each time a metadata/data pair is found in the message.
    handleMessageEnd will be called when all the metadata/data pairs have
    been handled.
=cut
sub registerMessageHandler {
    my ($self, $messageType, $service) = validateParamsPos(@_,
                1,
                { type => SCALAR },
                { can => [ 'handleMessageBegin', 'handleMessageEnd', 'handleEvent' ]}
            );

    $self->{LOGGER}->debug("Adding message handler for $messageType");

    if (defined $self->{MSG_HANDLERS}->{$messageType}) {
        $self->{LOGGER}->error("There already exists a handler for message $messageType");
        return -1;
    }

    $self->{MSG_HANDLERS}->{$messageType} = $service;

    return 0;
}

=head2 registerEventHandler($self, $messageType, $eventType, $service)
    This function is used to tell which events a pS service is interested
    in. If added, there must be a 'handleEvent' function defined in the
    service module. The 'handleEvent' function in the specified service
    will be called for each metadata/data pair with an event type of the
    specified type found in a message of the specified type.
=cut
sub registerEventHandler {
    my ($self, $messageType, $eventType, $service) = validateParamsPos(@_,
                1,
                { type => SCALAR },
                { type => SCALAR },
                { can => [ 'handleEvent' ]}
            );

    $self->{LOGGER}->debug("Adding event handler for events of type $eventType on messages of $messageType");

    if (not defined $self->{EV_HANDLERS}->{$messageType}) {
        $self->{EV_HANDLERS}->{$messageType} = ();
    }

    if (defined $self->{EV_HANDLERS}->{$messageType}->{$eventType}) {
        $self->{LOGGER}->error("There already exists a handler for events of type $eventType on messages of type $messageType");
        return -1;
    }

    $self->{EV_HANDLERS}->{$messageType}->{$eventType} = $service;

    return 0;
}

=head2 registerEventHandler_Regex($self, $messageType, $eventRegex, $service)
    This function is used to tell which events a pS service is interested
    in. If added, there must be a 'handleEvent' function defined in the
    service module. The 'handleEvent' function in the specified service
    will be called for each metadata/data pair with an event type matching
    the specified regular expression found in a message of the specified
    type.
=cut
sub registerEventHandler_Regex {
    my ($self, $messageType, $eventRegex, $service) = validateParamsPos(@_,
                1,
                { type => SCALAR },
                { type => SCALAR },
                { can => [ 'handleEvent' ]}
            );

    $self->{LOGGER}->debug("Adding event handler for events matching $eventRegex on messages of $messageType");

    if (not defined $self->{EV_REGEX_HANDLERS}->{$messageType}) {
        $self->{EV_REGEX_HANDLERS}->{$messageType} = ();
    }

    if (defined $self->{EV_REGEX_HANDLERS}->{$messageType}->{$eventRegex}) {
        $self->{LOGGER}->error("There already exists a handler for events of the form /$eventRegex\/ on messages of type $messageType");
        return -1;
    }

    $self->{EV_REGEX_HANDLERS}->{$messageType}->{$eventRegex} = $service;

    return 0;
}

=head2 __handleMessage ($self, $doc, $messageType, $message, $request);
    The __handleMessage function is called when a message is encountered that
    has a full message handler.
=cut
sub __handleMessage {
    my ($self, @args) = @_;
    my $args = validateParams(@args, 
            {
                output => { type => ARRAYREF, isa => "perfSONAR_PS::XML::Document_file" },
                messageId => { type => SCALAR },
                messageType => { type => SCALAR },
                message => { type => SCALARREF },
                rawRequest => { type => ARRAYREF },
            });

    my $messageType = $args->{"messageType"};

    if (defined $self->{FULL_MSG_HANDLERS}->{$messageType}) {
        return $self->{FULL_MSG_HANDLERS}->{$messageType}->handleMessage($args);
    }

    return;
}


=head2 __handleMessageBegin ($self, $ret_message, $messageId, $messageType, $msgParams, $request);
    The __handleMessageBegin function is called when a new message is encountered
    that has a message handler.
=cut
sub __handleMessageBegin {
    my ($self, @args) = @_;
    my $args = validateParams(@args, 
            {
                output => { type => ARRAYREF, isa => "perfSONAR_PS::XML::Document_file" },
                messageId => { type => SCALAR | UNDEF },
                messageType => { type => SCALAR },
                messageParameters => { type => HASHREF | UNDEF },
                message => { type => SCALARREF },
                rawRequest => { type => ARRAYREF },
                doOutputMessageHeader => { type => SCALARREF },
                doOutputMetadata => { type => SCALARREF },
                outputMessageType => { type => SCALARREF },
                outputNamespaces => { type => HASHREF },
                outputMessageId => { type => SCALARREF },
            });

    my $messageType = $args->{"messageType"};

    if (not defined $self->{MSG_HANDLERS}->{$messageType}) {
        return (0, undef, undef);
    }

    return $self->{MSG_HANDLERS}->{$messageType}->handleMessageBegin($args);
}

=head2 __handleMessageEnd ($self, $ret_message, $messageId, $messageType);
    The __handleMessageEnd function is called when all the metadata/data pairs in a
    message have been handled.
=cut
sub __handleMessageEnd {
    my ($self, @args) = @_;
    my $args = validateParams(@args, 
            {
                output => { type => ARRAYREF, isa => "perfSONAR_PS::XML::Document_file" },
                messageId => { type => SCALAR | UNDEF },
                messageType => { type => SCALAR },
                message => { type => SCALARREF },
                doOutputMessageFooter => { type => SCALARREF },
            });

    my $messageType = $args->{"messageType"};

    if (not defined $self->{MSG_HANDLERS}->{$messageType}) {
        return 0;
    }

    return $self->{MSG_HANDLERS}->{$messageType}->handleMessageEnd($args);
}

=head2 handleEvent ($self, $doc, $messageId, $messageType, $message_parameters, $eventType, $md, $d, $raw_request);
    The handleEvent function is called when a metadata/data pair is found
    in a message. $doc contains the response document that being
    constructed. $messageId contains the identifier for the message.
    $messageType contains the type of the message. $message_parameters is
    a reference to a hash containing the message parameters. $eventType
    contains the event type (if it exists). $md contains the metadata. $d
    contains the data. $raw_request contains the raw request element.
=cut
sub __handleEvent {
    my ($self, @args) = @_;
    my $args = validateParams(@args, 
            {
                output => { type => ARRAYREF, isa => "perfSONAR_PS::XML::Document_file" },
                messageId => { type => SCALAR | UNDEF },
                messageType => { type => SCALAR },
                messageParameters => { type => HASHREF | UNDEF },
                eventType => { type => SCALAR | UNDEF },
                subject => { type => ARRAYREF },
                filterChain => { type => ARRAYREF },
                data => { type => SCALARREF },
                rawRequest => { type => ARRAYREF },
                doOutputMetadata => { type => SCALARREF },
            });

    my $messageType = $args->{"messageType"};
    my $eventType = $args->{"eventType"};

    if (defined $eventType and $eventType ne "") {
        $self->{LOGGER}->debug("Handling event: $messageType, $eventType");
    } else {
        $self->{LOGGER}->debug("Handling metadata/data pair: $messageType");
    }

    if (defined $self->{EV_HANDLERS}->{$messageType} and defined $self->{EV_HANDLERS}->{$messageType}->{$eventType}) {
        return $self->{EV_HANDLERS}->{$messageType}->{$eventType}->handleEvent($args);
    }

    if (defined $self->{EV_REGEX_HANDLERS}->{$messageType}) {
        $self->{LOGGER}->debug("There exists regex's for this message type");
        foreach my $regex (keys %{$self->{EV_REGEX_HANDLERS}->{$messageType}}) {
            $self->{LOGGER}->debug("Checking $eventType against $regex");
            if ($eventType =~ /$regex/) {
                return $self->{EV_REGEX_HANDLERS}->{$messageType}->{$regex}->handleEvent($args);
            }
        }
    }

    if (defined $self->{MSG_HANDLERS}->{$messageType}) {
        return $self->{MSG_HANDLERS}->{$messageType}->handleEvent($args);
    }

    throw perfSONAR_PS::Error_compat("error.common.event_type_not_supported", "Event type \"$eventType\" is not yet supported for messages with type \"$messageType\"");
}

=head2 isValidMessageType($self, $messageType);
    The isValidMessageType function can be used to check if a specific
    message type can be handled by either a full message handler, a message
    handler or an event type handler for events in that type of message. It
    returns 0 if it's invalid and non-zero if it's valid.
=cut
sub isValidMessageType {
    my ($self, $messageType) = @_;

    $self->{LOGGER}->debug("Checking if messages of type $messageType are valid");

    if (defined $self->{EV_HANDLERS}->{$messageType} or defined $self->{EV_REGEX_HANDLERS}->{$messageType}
            or defined $self->{MSG_HANDLERS}->{$messageType} or defined $self->{FULL_MSG_HANDLERS}->{$messageType}) {
        return 1;
    }

    return 0;
}

=head2 isValidEventType($self, $messageType, $eventType);
    The isValidEventType function can be used to check if a specific
    event type found in a specific message type can be handled. It returns
    0 if it's invalid and non-zero if it's valid.
=cut
sub isValidEventType {
    my ($self, $messageType, $eventType) = @_;

    $self->{LOGGER}->debug("Checking if $eventType is valid on messages of type $messageType");

    if (defined $self->{EV_HANDLERS}->{$messageType} and defined $self->{EV_HANDLERS}->{$messageType}->{$eventType}) {
        return 1;
    }

    if (defined $self->{EV_REGEX_HANDLERS}->{$messageType}) {
        foreach my $regex (keys %{$self->{EV_REGEX_HANDLERS}->{$messageType}}) {
            if ($eventType =~ /$regex/) {
                return 1;
            }
        }
    }

    if (defined $self->{MSG_HANDLERS}->{$messageType}) {
        return 1;
    }

    return 0;
}

=head2 hasFullMessageHandler($self, $messageType);
    The hasFullMessageHandler checks if there is a full message handler for
    the specified message type.
=cut
sub hasFullMessageHandler {
    my ($self, $messageType) = @_;

    if (defined $self->{FULL_MSG_HANDLERS}->{$messageType}) {
        return 1;
    }

    return 0;
}

=head2 hasMessageHandler($self, $messageType);
    The hasMessageHandler checks if there is a message handler for
    the specified message type.
=cut
sub hasMessageHandler {
    my ($self, $messageType) = @_;

    if (defined $self->{MSG_HANDLERS}->{$messageType}) {
        return 1;
    }

    return 0;
}

=head2 handleRequest($self, $raw_request);
    The handleRequest function takes a perfSONAR_PS::Request element
    containing an incoming SOAP request and handles that request by parsing
    it, checking the message type, and either calling a full message
    handler, or iterating through the message calling the handler for each
    event type. This function sets the response for the request.
=cut
sub handleMessage {
    my ($self, $message, $raw_request) = @_;

    my $messageId = $message->getAttribute("id");
    my $messageType = $message->getAttribute("type");

    if (not defined $messageType or $messageType eq "") {
        throw perfSONAR_PS::Error_compat("error.common.action_not_supported", "No message type specified");
    } elsif ($self->isValidMessageType($messageType) == 0) {
        throw perfSONAR_PS::Error_compat("error.common.action_not_supported", "Messages of type $messageType are unsupported");
    }

    # The module will handle everything for this message type
    if ($self->hasFullMessageHandler($messageType)) {
        my ($errorEventType, $errorMessage);

        try {
            my $ret_message = new perfSONAR_PS::XML::Document_file();
            $self->__handleMessage({ output => $ret_message, messageId => $messageId, messageType => $messageType, message => $message, rawRequest => $raw_request });
            $raw_request->setResponse($ret_message->getValue());
        }
        catch perfSONAR_PS::Error_compat with {
            my $ex = shift;

            $errorEventType = $ex->eventType;
            $errorMessage = $ex->errorMessage;
        }
        catch perfSONAR_PS::Error with {
            my $ex = shift;

            $errorEventType = $ex->eventType;
            $errorMessage = $ex->errorMessage;
        }
        otherwise {
            my $ex = shift;

            $self->{LOGGER}->error("Error handling message block: $ex");

            $errorEventType = "error.common.internal_error";
            $errorMessage = "An internal error occurred while servicing this metadata/data block";
        };

        if (defined $errorEventType) {
            my $ret_message = new perfSONAR_PS::XML::Document_file();
            my $retMessageId = "message.".genuid();

            # we weren't given a return message type, so try to construct
            # one by replacing Request with Response or sticking the term
            # "Response" on the end of the type.
            my $retMessageType = $messageType;
            $retMessageType =~ s/Request/Response/;
            if (!($retMessageType =~ /Response/)) {
                $retMessageType .= "Response";
            }

            $self->{LOGGER}->error("Description: \'$errorMessage\'");
            getResultCodeMessage($ret_message, $retMessageId, $messageId, "", $retMessageType, $errorEventType, $errorMessage, undef, 1);

            $raw_request->setResponse($ret_message->getValue());
        }

        return;
    }

    # Otherwise, since the message is valid, there must be some event types
    # it accepts. We'll try those.
    my %message_parameters = ();

    my $msgParams = find($message, "./*[local-name()='parameters' and namespace-uri()='http://ggf.org/ns/nmwg/base/2.0/']", 1);
    if (defined $msgParams) {
        my $find_res = find($msgParams, "./*[local-name()='parameter']", 0);
        if ($find_res) {
        foreach my $p ($find_res->get_nodelist) {
            my ($name, $value);

            $name = $p->getAttribute("name");
            $value = extract($p, 0);

            if (not defined $name or $name eq "") {
                next;
            }

            $message_parameters{$name} = $value;
        }
        }
    }

    my $ret_message = perfSONAR_PS::XML::Document_file->new();

    my $doOutputMessageHeader = 1;
    my $doOutputMetadata = 0;
    my %outputNamespaces = ();
    my $outputMessageType;
    my $outputMessageId = "message.".genuid();

    $outputMessageType = $messageType;
    $outputMessageType =~ s/Request/Response/;
    if (!($outputMessageType =~ /Response/)) {
        $outputMessageType .= "Response";
    }

    $self->__handleMessageBegin({
                output => $ret_message, messageId => $messageId,
                messageType => $messageType, messageParameters => $msgParams,
                rawRequest => $raw_request, message => $message,
                doOutputMessageHeader => \$doOutputMessageHeader, doOutputMetadata => \$doOutputMetadata,
                outputMessageType => \$outputMessageType, outputNamespaces => \%outputNamespaces,
                outputMessageId => \$outputMessageId
            });

    if ($doOutputMessageHeader) {
        startMessage($ret_message, $outputMessageId, $messageId, $outputMessageType, "", \%outputNamespaces);
    }

    my $chains = $self->parseChains($ret_message, $message);

    my %outputMetadata = ();

    if ($doOutputMetadata) {
        foreach my $request (@{ $chains }) {
            my $filter_chain = $request->{"filter"};
            my $merge_chain = $request->{"merge"};

            foreach my $md (@{ $merge_chain }) {
                if (not defined $outputMetadata{$md->getAttribute("id")}) {
                    $ret_message->addExistingXMLElement($md);
                    $outputMetadata{$md->getAttribute("id")} = 1;
                }
            }

            foreach my $mds (@{ $filter_chain }) {
                foreach my $md (@{ $mds }) {
                    if (not defined $outputMetadata{$md->getAttribute("id")}) {
                        $ret_message->addExistingXMLElement($md);
                        $outputMetadata{$md->getAttribute("id")} = 1;
                    }
                }
            }
        }
    }

    foreach my $request (@{ $chains }) {

        my $filter_chain = $request->{"filter"};
        my $merge_chain = $request->{"merge"};
        my $data = $request->{"data"};

        my $eventType;
        my $found_event_type = 0;
        foreach my $md (@{ $merge_chain }) {
            my $key = find($md, "./*[local-name()='key' and namespace-uri()='http://ggf.org/ns/nmwg/base/2.0/']", 1);
            if ($key) {
                $self->{LOGGER}->debug("Found a key");
                my $key_params = find($key, "./*[local-name()='parameters']", 0);
                foreach my $params_list ($key_params->get_nodelist) {
                    $self->{LOGGER}->debug("Found a parameters block: ".$params_list->toString);
                    my $keyEventType = findvalue($params_list, "./*[local-name()='parameter' and namespace-uri()='http://ggf.org/ns/nmwg/base/2.0/' and \@name='eventType']");
                    if ($keyEventType) {
                        $keyEventType =~ s/^\s*//;
                        $keyEventType =~ s/\s*$//;

                        $found_event_type = 1;

                        $self->{LOGGER}->debug("Found event type: $keyEventType");

                        if ($self->isValidEventType($messageType, $keyEventType)) {
                            $eventType = $keyEventType;
                            last;
                        } else {
                            throw perfSONAR_PS::Error_compat("error.common.event_type_not_supported", "Event type $keyEventType not supported for message of type \"$messageType\"");
                        }
                    }
                }
            }

            if (not $eventType) {
                my $eventTypes = find($md, "./*[local-name()='eventType' and namespace-uri()='http://ggf.org/ns/nmwg/base/2.0/']", 0);
                foreach my $e ($eventTypes->get_nodelist) {
                    $found_event_type = 1;
                    my $value = extract($e, 1);
                    if ($self->isValidEventType($messageType, $value)) {
                        $eventType = $value;
                        last;
                    }
                }
            }
        }

        my $errorEventType;
        my $errorMessage;
        my $doOutputMetadata = 1;
        if (($found_event_type and not defined $eventType) or (not $self->isValidMessageType($messageType))) {
            $errorEventType = "error.common.event_type_not_supported";
            $errorMessage = "No supported event types for message of type \"$messageType\"";
        } else {

            try {
                $self->__handleEvent({
                                        output => $ret_message, messageId => $messageId, messageType => $messageType,
                                        messageParameters => \%message_parameters, eventType => $eventType,
                                        subject => $merge_chain, filterChain => $filter_chain, data => $data,
                                        rawRequest => $raw_request, doOutputMetadata => \$doOutputMetadata
                                        });
            }
            catch perfSONAR_PS::Error_compat with {
                my $ex = shift;

                $errorEventType = $ex->eventType;
                $errorMessage = $ex->errorMessage;
            }
            catch perfSONAR_PS::Error with {
                my $ex = shift;

                $errorEventType = $ex->eventType;
                $errorMessage = $ex->errorMessage;
            }
            otherwise {
                my $ex = shift;

                $self->{LOGGER}->error("Error handling metadata/data block: $ex");

                $errorEventType = "error.common.internal_error";
                $errorMessage = "An internal error occurred while servicing this metadata/data block";
            }
        }

        if ($doOutputMetadata) {
            foreach my $md (@{ $merge_chain }) {
                if (not defined $outputMetadata{$md->getAttribute("id")}) {
                    $ret_message->addExistingXMLElement($md);
                    $outputMetadata{$md->getAttribute("id")} = 1;
                }
            }

            foreach my $mds (@{ $filter_chain }) {
                foreach my $md (@{ $mds }) {
                    if (not defined $outputMetadata{$md->getAttribute("id")}) {
                        $ret_message->addExistingXMLElement($md);
                        $outputMetadata{$md->getAttribute("id")} = 1;
                    }
                }
            }
        }

        if (defined $errorEventType and $errorEventType ne "") {
            $self->{LOGGER}->error("Couldn't handle requested metadata: $errorMessage");
            my $mdID = "metadata.".genuid();
            getResultCodeMetadata($ret_message, $mdID, $data->getAttribute("metadataIdRef"), $errorEventType);
            getResultCodeData($ret_message, "data.".genuid(), $mdID, $errorMessage, 1);
        }
    }

    my $doOutputMessageFooter = 1;
    $self->__handleMessageEnd({ output => $ret_message, messageId => $messageId, messageType => $messageType, message => $message, doOutputMessageFooter => \$doOutputMessageFooter  });
    if ($doOutputMessageFooter) {
        endMessage($ret_message);
    }

    $raw_request->setResponse($ret_message->getValue());
    $raw_request->finish();

    return;
}

=head2 parseChains ($self, $output, $message)
    This function parses the message and constructs an array containing a list
    of chains. If a chain cannot be resolved, an error message is added to the
    output document for that metadata/data pair. If no chains are found, an
    error is thrown.
=cut
sub parseChains {
    my ($self, $output, $message) = @_;

    my $messageType = $message->getAttribute("type");

    my %message_metadata = ();
    foreach my $m ($message->getChildrenByTagNameNS("http://ggf.org/ns/nmwg/base/2.0/", "metadata")) {
        my $md_id = $m->getAttribute("id");

        if (not defined $md_id  or $md_id eq "") {
            $self->{LOGGER}->error("Metadata has no identifier");
            next;
        }

        if (exists $message_metadata{$md_id}) {
            $self->{LOGGER}->error("Duplicate metadata: ".$md_id);
            next;
        }

        $message_metadata{$md_id} = $m;
    }

    my @chains = ();

    my $found_pair = 0;

    # construct the set of chains
    foreach my $d ($message->getChildrenByTagNameNS("http://ggf.org/ns/nmwg/base/2.0/", "data")) {
        my $d_idRef = $d->getAttribute("metadataIdRef");

        my $errorEventType;
        my $errorMessage;

        if (not defined $d_idRef or $d_idRef eq "") {
            $errorEventType = "error.common.structure";
            $errorMessage = "Data trigger with id \"".$d_idRef."\" has no metadataIdRef";
        } elsif (not exists $message_metadata{$d_idRef}) {
            $errorEventType = "error.common.structure";
            $errorMessage = "Data trigger with id \"".$d_idRef."\" has no matching metadata";
        } else {
            $found_pair = 1;

            try {
                my ($mergeChain, $filterChain) = $self->parseChain($messageType, \%message_metadata, $d_idRef);

                my %mdChains = ();

                $mdChains{"filter"} = $filterChain;
                $mdChains{"merge"} = $mergeChain;
                $mdChains{"data"} = $d;

                push @chains, \%mdChains;
            }
            catch perfSONAR_PS::Error_compat with {
                my $ex = shift;

                $errorEventType = $ex->eventType;
                $errorMessage = $ex->errorMessage;
            }
            catch perfSONAR_PS::Error with {
                my $ex = shift;

                $errorEventType = $ex->eventType;
                $errorMessage = $ex->errorMessage;
            }
            otherwise {
                my $ex = shift;

                $self->{LOGGER}->error("Error parsing metadata/data block: $ex");

                $errorEventType = "error.common.internal_error";
                $errorMessage = "An internal error occurred while parsing this metadata/data block";
            }
        }

        if ($errorEventType) {
            my $mdId = "metadata.".genuid();
            my $dId = "data.".genuid();
            $self->{LOGGER}->error($errorMessage);
            getResultCodeMetadata($output, $mdId, $d_idRef, $errorEventType);
            getResultCodeData($output, $dId, $mdId, $errorMessage, 1);
        }
    }

    if (not $found_pair) {
        throw perfSONAR_PS::Error_compat("error.common.no_metadata_data_pair", "There were no metadata/data pairs found in the message");
    }

    return \@chains;
}

# mergeMetadataChain ($self, $message_type, \%message_metadata, $baseId)
#    This function, when given a hash containing metadata identifiers as keys
#    and the metaadata elements as the value along with the identifier to begin
#    with, will construct attempt to merge the metadata elements and will
#    return the merged metadata. If the chain has a loop or a missing metadata,
#    an error will be thrown.
sub mergeMetadataChain {
    my ($self, $message_type, $message_metadata, $baseId) = @_;

    my %used_mds = ();
    my @mds = ();
    my $nextMdId = $baseId;

    do {
        if (not exists $message_metadata->{$nextMdId}) {
            throw perfSONAR_PS::Error_compat("error.common.merge", "Metadata $nextMdId does not exist");
        } elsif (exists $used_mds{$nextMdId}) {
            throw perfSONAR_PS::Error_compat("error.common.merge", "Metadata $nextMdId appears multiple times in the chain");
        }

        $used_mds{$nextMdId} = 1;

        my $m = $message_metadata->{$nextMdId};

        push @mds, $m;

        $nextMdId = $m->getAttribute("metadataIdRef");
    } while(defined $nextMdId);

    my @ret_mds = ();

    my $prev_md;
    foreach my $curr_md (reverse @mds) {
        if (not defined $prev_md) {
            $prev_md = $curr_md;
            next;
        }

        $self->__mergeMetadata($message_type, $prev_md, $curr_md);

        $curr_md->removeAttribute("metadataIdRef");
        $prev_md = $curr_md;
    }

    push @ret_mds, $prev_md;

    return \@ret_mds;
}

sub __mergeMetadata {
    my ($self, $message_type, $prev_md, $curr_md) = @_;
    my %eventTypes = ();

    foreach my $md (( $prev_md, $curr_md )) {
        foreach my $ev ($md->getChildrenByTagNameNS("http://ggf.org/ns/nmwg/base/2.0/", "eventType")) {
            my $eventType = $ev->textContent;
            $eventType =~ s/^\s+//;
            $eventType =~ s/\s+$//;

            if (exists $self->{MERGE_HANDLERS}->{$message_type} and
                exists $self->{MERGE_HANDLERS}->{$message_type}->{$eventType}) {
                return $self->{MERGE_HANDLERS}->{$message_type}->{$eventType}->mergeMetadata({ messageType => $message_type, eventType => $eventType, parentMd => $prev_md, childMd => $curr_md });
            }
        }
    }

    my $ev_handler;
    if (defined $self->{EVENTEQUIVALENCECHECKERS}->{$message_type}) {
        $ev_handler = $self->{EVENTEQUIVALENCECHECKERS}->{$message_type};
    } elsif (defined $self->{EVENTEQUIVALENCECHECKERS}->{'*'}) {
        $ev_handler = $self->{EVENTEQUIVALENCECHECKERS}->{'*'};
    }

    return defaultMergeMetadata($prev_md, $curr_md, $ev_handler);
}

# parseChain ($self, \%message_metadata, $baseId)
#    This function, when given a hash containing metadata identifiers as keys
#    and the metaadata elements as the value along with the identifier to begin
#    with, will construct the filter/merge chain from the metadata elements.
#    If the chain has a loop or a missing metadata, an error will be thrown.
#    Each element in the chain will be merged. 
sub parseChain {
    my ($self, $message_type, $message_metadata, $baseId) = @_;

    my $chained_mds;
    my @filter_mds = ();
    my %used_mds = ();

    my $nextMdId = $baseId;

    # populate the arrays with the filters/chain metadata
    do {
        if (not exists $message_metadata->{$nextMdId}) {
            throw perfSONAR_PS::Error_compat("error.common.merge", "Metadata $nextMdId does not exist");
        } elsif (exists $used_mds{$nextMdId}) {
            throw perfSONAR_PS::Error_compat("error.common.merge", "Metadata $nextMdId appears multiple times in the chain");
        }

        # fill in a hash to see which metadata are in the chain so far
        $used_mds{$nextMdId} = 1;

        my $m = $message_metadata->{$nextMdId};

        my $md_idRef = $m->getAttribute("metadataIdRef");

        my $mergeChain_currMd;

        if ($md_idRef) {
            $mergeChain_currMd = $self->mergeMetadataChain($message_type, $message_metadata, $nextMdId);
        } else {
            my @mergeChain_currMd = ();
            push @mergeChain_currMd, $message_metadata->{$nextMdId};
            $mergeChain_currMd = \@mergeChain_currMd;
        }

        my $subject_idRef;
        foreach my $md ( @{ $mergeChain_currMd } ) {
            my $curr_subject_idRef = findvalue($m, './*[local-name()=\'subject\']/@metadataIdRef');

            next if (not defined $curr_subject_idRef);

            $subject_idRef = $curr_subject_idRef if (not defined $subject_idRef);

            if ($curr_subject_idRef ne $subject_idRef) {
                thrown perfSONAR_PS::Error_compat("error.common.merge", "Merged metadata from chain beginning at $baseId have multiple, inconsistent subject metadataIdRefs");
            }
        }

        if ($subject_idRef) {
            unshift @filter_mds, $mergeChain_currMd;
            $nextMdId = $subject_idRef;
        } else {
            $chained_mds = $mergeChain_currMd;
        }
    } while(not defined $chained_mds);

    return ($chained_mds, \@filter_mds);
}


1;

__END__

=head1 SEE ALSO

L<Log::Log4perl>, L<perfSONAR_PS::XML::Document_file>
L<perfSONAR_PS::Common>, L<perfSONAR_PS::Messages>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.  Bugs,
feature requests, and improvements can be directed here:

https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id:$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu, Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
