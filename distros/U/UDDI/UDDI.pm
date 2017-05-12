package UDDI;

# Copyright 2000 ActiveState Tool Corp.

use strict;

our $VERSION = "0.03";

our $registry ||= "http://test.uddi.microsoft.com/inquire";
#our $registry = "http://uddi.microsoft.com/inquire";
our $TRACE;
our %err;

require Exporter;
our @EXPORT_OK = qw(find_binding find_business find_service find_tModel
		    get_bindingDetail get_businessDetail get_businessDetailExt
		    get_serviceDetail get_tModelDetail
                   );

my %findQualifier = map {$_ => 1}
   qw(exactNameMatch caseSensitiveMatch
      sortByNameAsc sortByNameDesc
      sortByDateAsc sortByDateDesc
     );

sub _esc_q {
    for (@_) {
	s/&/&amp;/g;
	s/\"/&quot;/g;
	s/</&lt;/g;
    }
}

sub _esc {
    for (@_) {
	s/&/&amp;/g;
	s/</&lt;/g;
    }
}

sub _rows_and_fq
{
    my $arg = shift;
    my $msg = "";
    if (defined(my $maxRows = delete $arg->{maxRows})) {
	$msg .= qq( maxRows="$maxRows");
    }
    $msg .= qq( xmlns="urn:uddi-org:api">);
    if (my $findQ = delete $arg->{findQualifiers}) {
	unless (ref($findQ)) {
	    $findQ = [split(' ', $findQ)];
	}
	if ($^W) {
	    for (@$findQ) {
		warn "Unknown findQualifier '$_'\n" unless $findQualifier{$_};
	    }
	}
	$msg .= "<findQualifiers>" .
                   join("", map "<findQualifier>$_</findQualifier>", @$findQ) .
                "</findQualifiers>";
    }
    return $msg;
}

sub _tbag
{
    my $arg = shift;
    my $msg = "";
    if (my $tBag = delete $arg->{tModelBag}) {
	unless (ref($tBag)) {
	    $tBag = [split(' ', $tBag)];
	}
	$msg .= "<tModelBag>" .
                   join("", map "<tModelKey>$_</tModelKey>", @$tBag) .
                "</tModelBag>";
    }
    return $msg;
}

sub _key_ref
{
    my($arg, $bag) = @_;
    my $msg = "";
    if (my $refs = delete $arg->{$bag}) {
	# XXX using a hash to implement a keyedReference bag is problematic
	# because there is no obvous place to put tModelKey if wanted...
	if (ref($refs) eq "HASH") {
	    my @kref;
	    for my $k (sort keys %$refs) {
		my $v = $refs->{$k};
		for ($k, $v) {
		    _esc_q($_);
		}
		push(@kref, qq(<keyedReference keyName="$k" keyValue="$v"/>));
	    }
	    $msg = "<$bag>" . join("", @kref) . "</$bag>";
	}
	else {
	    die "Unknown $bag argument type(must be hash)";
	}
    }
    $msg;
}

sub find_binding
{
    my %arg = @_;
    my $serviceKey = delete $arg{serviceKey};
    die "Missing serviceKey" unless $serviceKey;
    my $msg = qq(<find_binding serviceKey="$serviceKey" generic="1.0");
    $msg .= _rows_and_fq(\%arg);
    $msg .= _tbag(\%arg);
    $msg .= qq(</find_binding>);
    if (%arg) {
	my $a = join(", ", keys %arg);
	warn "Unrecongized parameters: $a";
    }

    return _request($msg);
}

sub find_business
{
    my %arg = @_;
    my $msg = qq(<find_business generic="1.0");
    $msg .= _rows_and_fq(\%arg);

    if (my $n = delete $arg{name}) {
	_esc($n);
	$msg .= qq(<name>$n</name>);
    }
    $msg .= _key_ref(\%arg, "identifierBag");
    $msg .= _key_ref(\%arg, "categoryBag");
    $msg .= _tbag(\%arg);

    if (my $discU = delete $arg{discoveryURLs}) {
	unless (ref($discU)) {
	    $discU = [split(' ', $discU)];
	}
	$msg .= "<discoveryURLs>" .
                   join("", map "<discoveryURL>$_</discoveryURL>", @$discU) .
                "</discoveryURLs>";
    }

    $msg .= qq(</find_business>);
    if (%arg) {
	my $a = join(", ", keys %arg);
	warn "Unrecongized parameters: $a";
    }

    return _request($msg);
}

sub find_service
{
    my %arg = @_;
    my $businessKey = delete $arg{businessKey};
    die "Missing businessKey" unless $businessKey;
    my $msg = qq(<find_service businessKey="$businessKey" generic="1.0");
    $msg .= _rows_and_fq(\%arg);
    if (my $n = delete $arg{name}) {
	_esc($n);
	$msg .= qq(<name>$n</name>);
    }
    $msg .= _key_ref(\%arg, "categoryBag");
    $msg .= _tbag(\%arg);
    $msg .= qq(</find_binding>);
    if (%arg) {
	my $a = join(", ", keys %arg);
	warn "Unrecongized parameters: $a";
    }

    return _request($msg);
}

sub find_tModel
{
    my %arg = @_;
    my $msg = qq(<find_tModel generic="1.0");
    $msg .= _rows_and_fq(\%arg);
    if (my $n = delete $arg{name}) {
	_esc($n);
	$msg .= qq(<name>$n</name>);
    }
    $msg .= _key_ref(\%arg, "identifierBag");
    $msg .= _key_ref(\%arg, "categoryBag");
    $msg .= _tbag(\%arg);
    $msg .= qq(</find_tModel>);
    if (%arg) {
	my $a = join(", ", keys %arg);
	warn "Unrecongized parameters: $a";
    }

    return _request($msg);
}

sub get_bindingDetail
{
    my $msg = qq(<get_bindingDetail generic="1.0" xmlns="urn:uddi-org:api">);
    for (@_) {
	$msg .= "<bindingKey>$_</bindingKey>";
    }
    $msg .= "</get_bindingDetail>";

    return _request($msg);
}

sub _get_businessDetail
{
    my $ext = (shift) ? "Ext" : "";
    my $msg = qq(<get_businessDetail$ext generic="1.0" xmlns="urn:uddi-org:api">);
    for (@_) {
	$msg .= "<businessKey>$_</businessKey>";
    }
    $msg .= "</get_businessDetail$ext>";

    return _request($msg);
}

sub get_businessDetail
{
    unshift(@_, 0);
    goto &_get_businessDetail;
}

sub get_businessDetailExt
{
    unshift(@_, 1);
    goto &_get_businessDetail;
}

sub get_serviceDetail
{
    my $msg = qq(<get_serviceDetail generic="1.0" xmlns="urn:uddi-org:api">);
    for (@_) {
	$msg .= "<serviceKey>$_</serviceKey>";
    }
    $msg .= "</get_serviceDetail>";

    return _request($msg);
}

sub get_tModelDetail
{
    my $msg = qq(<get_tModelDetail generic="1.0" xmlns="urn:uddi-org:api">);
    for (@_) {
	$msg .= "<tModelKey>$_</tModelKey>";
    }
    $msg .= "</get_tModelDetail>";

    return _request($msg);
}



# ----------------------------------

my $ua;

sub _request {
    my $msg = shift;

    if (!$ua) {
	require LWP::UserAgent;
	$ua = LWP::UserAgent->new;
	$ua->agent("UDDI.pm/$VERSION " . $ua->agent);
	$ua->env_proxy;
    }

    undef(%UDDI::err);

    my $req = HTTP::Request->new(POST => $registry);
    $req->date(time) if $TRACE;
    $req->header("SOAPAction", '""');
    $req->content_type("text/xml");
    $req->content(qq(<?xml version="1.0" encoding="UTF-8"?><Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/"><Body>$msg</Body></Envelope>\n));

    print $TRACE "\n\n", ("=" x 50), "\n", $req->as_string if $TRACE;

    my $res = $ua->request($req);

    print $TRACE $res->as_string if $TRACE;

    if ($res->content_type eq "text/xml" && $res->header("SOAPAction")) {
	#warn $res->content;

	require UDDI::SOAP;
	my $envelope = UDDI::SOAP::parse($res->content);
	if ($envelope->must_understand_headers) {
	    %UDDI::err = ( type => "SOAP",
			   code => "MustUnderstand",
			   message => "UDDI response contained SOAP headers that ".
			              "the client libarary did not understand",
			   detail => $envelope,
			 );
	    return undef;
	}

	my $obj = $envelope->body_content;

	if (ref($obj) eq "UDDI::SOAP::Fault") {
	    %UDDI::err = ( type    => "SOAP",
			   code    => $obj->code,
			   message => $obj->message,
			   detail  => $obj,
			 );
	    return undef;
	}

	return $obj;
    }

    %UDDI::err = (
		  type    => "HTTP",
		  code    => $res->code,
		  message => $res->status_line,
		  detail  => $res,
		 );
    return undef;
}

# The following table is auto-generated from:
# "UDDI API schema.  Version 1.0, revision 0.  Last change 2000-09-06"

# urn:uddi-org:api elements

sub TEXT_CONTENT () { 0x01 }
sub ELEM_CONTENT () { 0x02 }

our %elementContent = (
    'UDDI::addressLine'           => 0x01,
    'UDDI::bindingKey'            => 0x01,
    'UDDI::businessKey'           => 0x01,
    'UDDI::description'           => 0x01,
    'UDDI::keyValue'              => 0x01,
    'UDDI::name'                  => 0x01,
    'UDDI::overviewURL'           => 0x01,
    'UDDI::personName'            => 0x01,
    'UDDI::serviceKey'            => 0x01,
    'UDDI::tModelKey'             => 0x01,
    'UDDI::uploadRegister'        => 0x01,
    'UDDI::address'               => 0x02,
    'UDDI::contacts'              => 0x02,
    'UDDI::contact'               => 0x02,
    'UDDI::discoveryURL'          => 0x01,
    'UDDI::discoveryURLs'         => 0x02,
    'UDDI::phone'                 => 0x01,
    'UDDI::email'                 => 0x01,
    'UDDI::businessEntity'        => 0x02,
    'UDDI::businessServices'      => 0x02,
    'UDDI::businessService'       => 0x02,
    'UDDI::bindingTemplates'      => 0x02,
    'UDDI::identifierBag'         => 0x02,
    'UDDI::keyedReference'        => 0000,
    'UDDI::categoryBag'           => 0x02,
    'UDDI::bindingTemplate'       => 0x02,
    'UDDI::accessPoint'           => 0x01,
    'UDDI::hostingRedirector'     => 0000,
    'UDDI::tModelInstanceDetails' => 0x02,
    'UDDI::tModelInstanceInfo'    => 0x02,
    'UDDI::instanceDetails'       => 0x02,
    'UDDI::instanceParms'         => 0x01,
    'UDDI::tModel'                => 0x02,
    'UDDI::tModelBag'             => 0x02,
    'UDDI::overviewDoc'           => 0x02,
    'UDDI::authInfo'              => 0x01,
    'UDDI::get_authToken'         => 0000,
    'UDDI::authToken'             => 0x02,
    'UDDI::discard_authToken'     => 0x02,
    'UDDI::save_tModel'           => 0x02,
    'UDDI::delete_tModel'         => 0x02,
    'UDDI::save_business'         => 0x02,
    'UDDI::delete_business'       => 0x02,
    'UDDI::save_service'          => 0x02,
    'UDDI::delete_service'        => 0x02,
    'UDDI::save_binding'          => 0x02,
    'UDDI::delete_binding'        => 0x02,
    'UDDI::dispositionReport'     => 0x02,
    'UDDI::result'                => 0x02,
    'UDDI::errInfo'               => 0x01,
    'UDDI::findQualifiers'        => 0x02,
    'UDDI::findQualifier'         => 0x01,
    'UDDI::find_tModel'           => 0x02,
    'UDDI::find_business'         => 0x02,
    'UDDI::find_binding'          => 0x02,
    'UDDI::find_service'          => 0x02,
    'UDDI::serviceList'           => 0x02,
    'UDDI::businessList'          => 0x02,
    'UDDI::tModelList'            => 0x02,
    'UDDI::businessInfo'          => 0x02,
    'UDDI::businessInfos'         => 0x02,
    'UDDI::serviceInfo'           => 0x02,
    'UDDI::serviceInfos'          => 0x02,
    'UDDI::get_businessDetail'    => 0x02,
    'UDDI::businessDetail'        => 0x02,
    'UDDI::get_serviceDetail'     => 0x02,
    'UDDI::serviceDetail'         => 0x02,
    'UDDI::get_registeredInfo'    => 0x02,
    'UDDI::registeredInfo'        => 0x02,
    'UDDI::tModelInfo'            => 0x02,
    'UDDI::tModelInfos'           => 0x02,
    'UDDI::get_tModelDetail'      => 0x02,
    'UDDI::tModelDetail'          => 0x02,
    'UDDI::businessEntityExt'     => 0x02,
    'UDDI::get_businessDetailExt' => 0x02,
    'UDDI::businessDetailExt'     => 0x02,
    'UDDI::get_bindingDetail'     => 0x02,
    'UDDI::bindingDetail'         => 0x02,
    'UDDI::validate_categorization' => 0x02,
);


package UDDI::Object;

use overload '""' => \&as_string;

our $AUTOLOAD;

sub AUTOLOAD
{
    my $self = shift;
    my $method = substr($AUTOLOAD, rindex($AUTOLOAD, '::')+2);
    return if $method eq "DESTROY";

    my $k = "urn:uddi-org:api\0$method";
    if (exists $self->[0]{$k}) {
	return $self->[0]{$k};
    }

    my @res = grep ref($_) eq "UDDI::$method", @$self;
    return wantarray ? @res : $res[0];
}

sub xml_lang
{
    my $self = shift;
    return $self->[0]{"xml\0lang"};
}

sub as_string
{
    my($self, $elem) = @_;
    my $class = ref($self);

    unless ($class) {
	# plain string
	UDDI::_esc($self) if $elem;
	return $self;
    }

    return $self->[1]
	if $UDDI::elementContent{$class} == UDDI::TEXT_CONTENT && !$elem;

    (my $tag = $class) =~ s/^UDDI:://;

    my @e = @$self;
    my $attr = shift @e;
    if (%$attr) {
	my @attr;
	for my $k (sort keys %$attr) {
	    my $v = $attr->{$k};
	    $k =~ s/^[^\0]*\0//; # kill namespace qualifier
	    UDDI::_esc_q($v);
	    @attr = qq($k="$v");
	}
	$attr = join(" ", "", @attr);
    }
    else {
	$attr = "";
    }

    return "<$tag$attr/>" unless @e;

    return join("", "<$tag$attr>", (map as_string($_, 1), @e), "</$tag>");
}

1;

__END__

=head1 NAME

UDDI - UDDI client interface

=head1 SYNOPSIS

 use UDDI;

 my $list = UDDI::find_business(name => "a");
 my $bis = $list->businessInfos;
 for my $b ($bis->businessInfo) {
     print $b->name, "\n";
 }

=head1 DESCRIPTION

This module provide functions to interact with UDDI registry servers.
UDDI (I<Universal Description, Discovery and Integration>) is the name
of a group of web-based registries that expose information about
businesses and their technical interfaces (APIs).  Learn more about
UDDI at I<www.uddi.org>.

The interface exposed comply with the "UDDI Programmer's API
Specification". Currently only the UDDI inquiry interface is provided.

=head1 FUNCTIONS

The following functions are provided.  None of them are exported by
default.  A successful invocation will return some UDDI object.  On
error C<undef> is returned and the global variable %UDDI::err is set.

All the find_xxx() functions take key/value pairs as arguments.  All
they get_xxx() functions simply take one or more keys as argument.

=over

=item find_binding( serviceKey => $key, ... )

This function will find binding details for a specific service.  On
success a UDDI::bindingDetails object is returned.  Optional
arguments are C<maxRows>, C<findQualifiers> and C<tModelBag>.

=item find_business( ... )

This function will return businesses that fullfil the search criteria
given.  On success a UDDI::businessList object is returned.  The returned
businessList might be empty.  Arguments are C<maxRows>,
C<findQualifiers>, C<name>, C<identiferBag>, C<categoryBag>,
C<tModelBag> are C<discoveryURLs>.

=item find_service( businessKey => $key, ... )

This function will find services for a specific business.  On success
a UDDI::serviceList object is returned.  Optional arguments are
C<maxRows>, C<findQualifiers>, C<name>, C<categoryBag> and
C<tModelBag>.

=item find_tModel( ... )

This function will return tModels that fullfil the search criteria
given.  On success a UDDI::tModelList object is returned.  The returned
tModelList might be empty.  Arguments are C<maxRows>,
C<findQualifiers>, C<name>, C<identiferBag> and C<categoryBag>.

=item get_bindingDetail( $bindingKey, ... )

This function will return a UDDI::bindingDetail object containing a
UDDI::bindingTemplate for each binding key given as argument.

=item get_businessDetail( $businessKey, ... )

This function will return a UDDI::businessDetail object containing a
UDDI::businessEntity for each business key given as argument.

=item get_businessDetailExt( $businessKey, ... )

This function will return a UDDI::businessDetailExt object containing a
UDDI::businessEntityExt for each business key given as argument.

=item get_serviceDetail( $serviceKey, ... )

This function will return a UDDI::serviceDetail object containing a
UDDI::businessService for each service key given as argument.


=item get_tModelDetail( $tModelKey, ... )

This function will return a UDDI::tModelDetail object containing a
UDDI::tModel for each tModel key given as argument.

=back

=head1 GLOBALS

=head2 %UDDI::err

In case of errors the functions above will return undef and the
%UDDI::err hash will be filled with the following values:

=over

=item type

A short string giving the overall type of the failure.  It can be
either "HTTP" or "SOAP".

=item code

Error code.  For HTTP it is a 3 digit number.  For UDDI failures it is
some string prefixed with "E_".  For general SOAP failures it is a
short string like "VersionMismatch", "MustUnderstand", "Client",
"Server" (defined in section 4.4.1 in the SOAP spec.)

=item message

A short human readable (English) message describing the error.

=item detail

A reference to the corresponing error object.

=back

The hash will be empty after a successful function call.

=head2 $UDDI::registry

The $UDDI::registry variable contains the URL to the registry server
to use for the calls.  Currently it defaults to Microsoft's test
server.

=head2 $UDDI::TRACE

For debugging you might assign a file handle to the
$UDDI::TRACE variable.  Trace logs of the SOAP messages are then
written to this file.

=head1 SEE ALSO

http://www.uddi.org, L<SOAP>, L<SOAP::Lite>

=head1 AUTHOR

Gisle Aas <gisle@ActiveState.com>

Copyright 2000 ActiveState Tool Corp.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
