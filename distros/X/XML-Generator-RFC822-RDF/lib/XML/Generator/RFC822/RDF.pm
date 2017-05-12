# $Id: RDF.pm,v 1.11 2004/12/22 23:21:21 asc Exp $
use strict;

package XML::Generator::RFC822::RDF;
use base qw (XML::SAX::Base);

$XML::Generator::RFC822::RDF::VERSION = '1.1';

=head1 NAME

XML::Generator::RFC822::RDF - generate RDF/XML SAX2 events for RFC822 messages

=head1 SYNOPSIS

  my $folder = Email::Folder->new($path_mbox);

  while (my $msg = $folder->next_message()) {

      my $writer    = XML::SAX::Writer->new();
      my $filter    = XML::Filter::DataIndenter->new(Handler=>$writer);
      my $generator = XML::Generator::RFC822::RDF->new(Handler=>$filter);

      $generator->parse($msg);
  }

=head1 DESCRIPTION

Generate RDF/XML SAX2 events for RFC822 messages.

Messages are keyed using SHA1 digests of Message-IDs and email addresses. In
the case of the latter this makes it easier to merge messages with contact data
that has been serialized using XML::Generator::vCard::RDF (version 1.3+)

=head1 DOCUMENT FORMAT

 + rdf:RDF

   + rdf:Description
     @rdf:about = x-urn:ietf:params:rfc822#SHA1([MESSAGEID])
    - rfc822:To 
      @rdf:resource = http://http://xmlns.com/foaf/0.1/mbox_sha1sum#SHA1([EMAILADDRESS])
    - rfc822:From
      @rdf:resource = http://http://xmlns.com/foaf/0.1/mbox_sha1sum#SHA1([EMAILADDRESS])
    - rfc822:Cc
      @rdf:resource = http://http://xmlns.com/foaf/0.1/mbox_sha1sum#SHA1([EMAILADDRESS])
    - rfc822:Return-Path
      @rdf:resource = http://http://xmlns.com/foaf/0.1/mbox_sha1sum#SHA1([EMAILADDRESS])
    - rfc822:Delivered-To
      @rdf:resource = http://http://xmlns.com/foaf/0.1/mbox_sha1sum#SHA1([EMAILADDRESS])
    - rfc822:Reply-To
      @rdf:resource = http://http://xmlns.com/foaf/0.1/mbox_sha1sum#SHA1([EMAILADDRESS])
    - rfc822:In-Reply-To
      @rdf:resource x-urn:ietf:params:rfc822#SHA1([INREPLYTO])
    - rfc8822:References
      @rdf:resource x-urn:ietf:params:rfc822#SHA1([REFERENCES])   
    - rfc822:Date [REFORMATTED AS W3CDTF]
    - rfc822:[ALLOTHERHEADERS]    
    + rfc822:Body
      + rdf:Seq
        - rdf:li
          @rdf:resource = x-urn:ietf:params:rfc822:Body#SHA1([MESSAGEID])_[n]

   # Body/MIME parts
   # (1) or more

   + rdf:Description   
     @rdf:aboout = x-urn:ietf:params:rfc822:Body#SHA1([MESSAGEID])_[n]
     - rfc822:content-type
     - rdf:value

   # To, From, Cc, Return-Path, Delivered-To, Reply-To
   # (1) or more

   + rdf:Descripion
     @rdf:about = http://xmlns.com/foaf/0.1/mbox_sha1sum#SHA1([EMAILADDRESS])
     - vCard:FN
     - vCard:EMAIL

   # In-Reply-To, References
   # (1) or more

   + rdf:Description
     @rdf:about = x-urn:ietf:params:rfc822#SHA1([MESSAGEID]) 
     - rfc822:Message-ID

All MIME values are decoded and everything is encoded as UTF-8.

=cut

use Email::Address;
use Email::MIME;

use Digest::SHA1 qw (sha1_hex);
use Encode;
use MIME::Words qw (decode_mimewords);

use Date::Parse;
use Date::Format;

use Memoize;

sub import {
    my $pkg = shift;
    $pkg->SUPER::import(@_);

    memoize("_prepare_text","_prepare_mbox");
}

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(%args)

This method is inherited from I<XML::SAX::Base> and returns a
I<XML::Generator::RFC822::RDF> object. Additionally, the following
parameters are allowed :

=over 4

=item * B<Brief>

Boolean.

If true, the parser will ignore a message's body and all headers 
except : To, From, Cc, Return-Path, Delivered-To, Reply-To, Date, 
Subject

Default is false.

=back

=cut

sub new {
    my $pkg  = shift;
    my %args = @_;

    my $self = $pkg->SUPER::new(%args);

    if (! $self) {
	return undef;
    }

    $self->{'__addrs'}     = {};
    $self->{'__relations'} = {};
    $self->{'__parts'}     = [];
    $self->{'__brief'}     = ($args{'Brief'}) ? 1 : 0;

    return bless $self,$pkg;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->parse(@messages)

Where I<@messages> is one or more I<Email::Simple> objects.

=cut

sub parse {
    my $self     = shift;
    my @messages = @_;

    #

    $self->start_document();

    $self->xml_decl({Version => "1.0",Encoding => "UTF-8"});

    my $ns = $self->_namespaces();

    foreach my $prefix (keys %$ns) {
	$self->start_prefix_mapping({Prefix       => $prefix,
				     NamespaceURI => $ns->{$prefix}});
    }

    $self->start_element({Name=>"rdf:RDF"});

    #
    
    foreach my $msg (@messages) {
	$self->_parse($msg);
    }

    #
    
    $self->end_element({Name=>"rdf:RDF"});
    
    foreach my $prefix (keys %$ns) {
	$self->end_prefix_mapping({Prefix=>$prefix});
    }
    
    $self->end_document();
    return 1;
}

sub _parse {
    my $self     = shift;
    my $msg      = shift;

    my $sha1_msgid = sha1_hex($msg->header("Message-ID"));
    my $about      = sprintf("x-urn:ietf:params:rfc822#%s",$sha1_msgid);

    $self->start_element({Name       => "rdf:Description",
			  Attributes => {"{}rdf:about" => {Name  => "rdf:about",
							   Value => $about}}});

    foreach my $header (keys %{$msg->{head}}) {

	my $utf8_header = $header;

	$utf8_header =~ s/^\s+//;
	$utf8_header =~ s/\s+$//;
	$utf8_header =~ s/:$//;

	$utf8_header = encode_utf8($utf8_header);
	
	#

	if ($utf8_header =~ /^(?:from|to|cc|return-path|(?:delivered|reply)-to)$/i) {
	    $self->_email_address($utf8_header,$msg->header($utf8_header));
	}
	
	elsif ($utf8_header =~ /^(?:in-reply-to|references)$/i) {

	    my $resource = sprintf("x-urn:ietf:params:rfc822#%s",
				   sha1_hex($msg->header($header)));

	    $self->start_element({Name       => "rfc822:$utf8_header",
				  Attributes => {"{}rdf:resource" => {Name  => "rdf:resource",
								      Value => encode_utf8($resource)}}});
	    $self->end_element({Name => "rfc822:$utf8_header"});

	    $self->{'__relations'}->{$resource} ||= [ $msg->header($header), $resource ];
	}
	
	elsif ($utf8_header eq "Date") {

	    my $time = str2time($msg->header($header));
	    my $dt   = time2str("%Y-%m-%dT%H:%M:%S%z",$time);

	    $self->start_element({Name => "rfc822:$utf8_header"});
	    $self->characters({Data=>encode_utf8($dt)});
	    $self->end_element({Name => "rfc822:$utf8_header"});
	}

	elsif (($utf8_header eq "Subject") || (! $self->{'__brief'})) {
	    $self->start_element({Name=>"rfc822:$utf8_header"});
	    $self->characters({Data=>&_prepare_text($msg->header($header))});
	    $self->end_element({Name=>"rfc822:$utf8_header"});
	}

	else {}
    }

    $self->_body($msg);
    $self->end_element({Name=>"rdf:Description"});

    $self->_dump_body_parts($msg);
    $self->_dump_emails();
    $self->_dump_relations();

    return 1;
}

sub _body {
    my $self = shift;
    my $msg  = shift;

    if ($self->{'__brief'}) {
	return 1;
    }

    my $count = 1;
    
    my $parsed = Email::MIME->new($msg->as_string());
    my @parts  = $parsed->parts();
    
    $self->start_element({Name => "rfc822:Body"});      
    $self->start_element({Name => "rdf:Seq"});
    
    my $sha1_msgid = sha1_hex($msg->header("Message-ID"));
    my $body       = sprintf("x-urn:ietf:params:rfc822:Body#%s",$sha1_msgid);
    
    foreach (@parts) {
	
	my $mpart = sprintf("%s_%s",$body,$count++);
	
	$self->start_element({Name       => "rdf:li",
			      Attributes => {"{}rdf:resource" => {Name  => "rdf:resource",
								  Value => encode_utf8($mpart)}}});
	$self->end_element({Name => "rdf:li"});
    }
    
    $self->end_element({Name => "rdf:Seq"});    
    $self->end_element({Name=>"rfc822:Body"});

    $self->{'__parts'} = \@parts;
    return 1;
}

sub _dump_body_parts {
    my $self  = shift;
    my $msg   = shift;

    if ($self->{'__brief'}) {
	return 1;
    }

    my $count = 1;
    
    foreach my $part (@{$self->{'__parts'}}) {
	
	my $mpart = sprintf("x-urn:ietf:params:rfc822:Body#%s_%s",
			    sha1_hex($msg->header("Message-ID")),
			    $count++);
	
	$self->start_element({Name=>"rdf:Description",
			      Attributes=>{ "{}rdf:about" => {Name  => "rdf:about",
							      Value => encode_utf8($mpart)}}});
	
	$self->start_element({Name=>"rfc822:content-type"});
	$self->characters({Data=>&_prepare_text($self->{'__parts'}->[0]->content_type())});
	$self->end_element({Name=>"rfc822:content-type"});
	
	$self->start_element({Name=>"rdf:value"});
	$self->start_cdata();
	# Oof - do I need to mime_decode all this too?
	$self->characters({Data=>&_prepare_text($self->{'__parts'}->[0]->body_raw())});
	$self->end_cdata();
	$self->end_element({Name=>"rdf:value"});
	$self->end_element({Name=>"rdf:Description"});
    }

    return 1;
}

sub _dump_emails {
    my $self = shift;

    foreach my $email (keys %{$self->{'__addrs'}}) {
	$self->start_element({Name=>"rdf:Description",
			      Attributes=>{"{}rdf:about" => {Name  => "rdf:about",
							     Value => &_prepare_mbox($email)}}});

	#

	my $fn = $self->{'__addrs'}->{$email};

	$self->start_element({Name => "vCard:FN"});

	my @keys = grep { /^\w/ } keys %$fn;

	if (scalar(@keys) > 1) {
	    $self->start_element({Name => "rdf:Bag"});

	    foreach my $name (@keys) {
		$self->start_element({Name=>"rdf:li"});
		$self->characters({Data => &_prepare_text($name)});
		$self->end_element({Name=>"rdf:li"});
	    }

	    $self->end_element({Name => "rdf:Bag"});
	}

	else {
	    $self->characters({Data => &_prepare_text($keys[0]) });
	}

	$self->end_element({Name => "vCard:FN"});
	
	#

	$self->start_element({Name => "vCard:EMAIL"});
	$self->characters({Data => $email});
	$self->end_element({Name => "vCard:EMAIL"});
	
	$self->end_element({Name => "rdf:Description"});
    }

    return 1;
}

sub _dump_relations {
    my $self = shift;

    if (! exists($self->{'__relations'})) {
	return 1;
    }

    foreach my $rel (keys %{$self->{'__relations'}}) {

	if (! exists($self->{'__relations'}->{$rel})) {
	    next;
	}

	$self->_dump_relation($self->{'__relations'}->{$rel});
    }

    return 1;
}

sub _dump_relation {
    my $self = shift;
    my $data = shift;

    $self->start_element({Name=>"rdf:Description",
			  Attributes=>{"{}rdf:about" => {Name  => "rdf:about",
							 Value => $data->[1]}}});
    $self->start_element({Name => "rfc822:Message-ID"});
    $self->characters({Data=>&_prepare_text($data->[0])});
    $self->end_element({Name => "rfc822:Message-ID"});
    
    $self->end_element({Name=>"rdf:Description"});	
    
    return 1;
}

sub _email_address {
    my $self   = shift;
    my $header = shift;

    my @addrs  = Email::Address->parse(join(" ",@_));

    if (scalar(@addrs) > 1) {
	$self->start_element({Name => "rfc822:$header"});
	$self->start_element({Name => "rdf:Bag"});       

	foreach my $addr (@addrs) {

	    my ($email,$fn) = &_parse_address($addr);

	    $self->start_element({Name       => "rdf:li",
				  Attributes => {"{}rdf:parseType" => {Name  => "rdf:resource",
								       Value => &_prepare_mbox($email)}}});
	    $self->end_element({Name => "rdf:li"});
	    $self->{'__addrs'}->{$email}->{$fn} ++;
	}
	
	$self->end_element({Name => "rdf:Bag"});		  
	$self->end_element({Name => "rfc822:$header"});
    }
    
    else {

	my ($email,$fn) = &_parse_address($addrs[0]);

	$self->start_element({Name       => "rfc822:$header",
			      Attributes => {"{}rdf:parseType" => {Name  => "rdf:resource",
								   Value => &_prepare_mbox($email)}}});
	$self->end_element({Name => "rfc822:$header"});

	$self->{'__addrs'}->{$email}->{$fn} ++;
    }

    return 1;
}

sub _parse_address {
    my $addr = shift;

    if (! UNIVERSAL::isa($addr,"Email::Address")) {
	return ("","");
    }

    my $email = $addr->address();
    my $fn    = $addr->phrase();

    if ($fn) {
	$fn =~ s/^["']//;
        $fn =~ s/["']$//;
    }

    return ($email,($fn || ""));
}

# memoized

sub _prepare_text {
    my $txt = shift;

    my @decoded = decode_mimewords($txt);
    return encode_utf8(join("", map{ $_->[0] }@decoded));
}

# memoized

sub _prepare_mbox {
    my $email_addr = shift;
    return encode_utf8(sprintf("%smbox_sha1sum#%s",
			       __PACKAGE__->_namespaces()->{foaf},
			       sha1_hex($email_addr)));
}

sub _namespaces {
    return {
	"rdf"    => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
	"rfc822" => "x-urn:ietf:params:rfc822#",
	"foaf"   => "http://xmlns.com/foaf/0.1/",
	"vCard"  => "http://www.w3.org/2001/vcard-rdf/3.0#",
    }
}

=head1 VERSION

1.1

=head1 DATE

$Date: 2004/12/22 23:21:21 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<XML::Generator::vCard::RDF>

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it 
under the same terms as Perl itself.

=cut

return 1;

__END__
