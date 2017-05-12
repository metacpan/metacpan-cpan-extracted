# $Id: RDF.pm,v 1.24 2004/12/28 21:50:27 asc Exp $
use strict;

package XML::Generator::vCard::RDF;
use base qw (XML::Generator::vCard::Base);

$XML::Generator::vCard::RDF::VERSION = '1.4';

=head1 NAME

XML::Generator::vCard::RDF - generate RDF/XML SAX2 events for vCard 3.0

=head1 SYNOPSIS

 use XML::SAX::Writer;
 use XML::Generator::vCard::RDF;

 my $writer = XML::SAX::Writer->new();
 my $driver = XML::Generator::vCard::RDF->new(Handler=>$writer);

 $driver->parse_files("test.vcf");

=head1 DESCRIPTION

Generate RDF/XML SAX2 events for vCard 3.0

=head1 DOCUMENT FORMAT

SAX2 events map to the I<Representing vCard Objects in RDF/XML>
W3C note:

 http://www.w3.org/TR/2001/NOTE-vcard-rdf-20010222/

Additionally, an extra description will be added for each unique
email address. Each description will be identified by the value of
SHA1 digest of the address and simply point back to the vCard
description.

For example, the test file for this package contains the email
address I<senzala@example.com> which will cause the following
description to be added to the final output :

 <rdf:RDF>
  <rdf:Description rdf:about = 't/Senzala.vcf'>
   <!-- vcard data here -->
  </rdf:Description>

  <!-- c0e0c54660f33a3ec7f22f902d0e5ead8bd4e4f4 == SHA1(senzala@example.com) -->

  <rdf:Description rdf:about='http://xmlns.com/foaf/0.1/mbox_sha1sum#c0e0c54660f33a3ec7f22f902d0e5ead8bd4e4f4'>
   <rdfs:seeAlso rdf:resource='t/Senzala.vcf' /></rdf:Description>
  </rdf:Description>
 </rdf:RDF>

This is done to facilitate merging vCard data with RDF representations
of email messages, using XML::Generator::RFC822::RDF. For example :

 <rdf:RDF>

  <rdf:Description rdf:about='x-urn:ietf:params:rfc822#5b0c8c9f9b2b782375f515a0b24b3a821a59a34a'>
   <rfc822:To rdf:resource='http://xmlns.com/foaf/0.1/mbox_sha1sum#c0e0c54660f33a3ec7f22f902d0e5ead8bd4e4f4' />
   <!-- ... -->
  </rdf:Description>

  <rdf:Description rdf:about='http://xmlns.com/foaf/0.1/mbox_sha1sum#c0e0c54660f33a3ec7f22f902d0e5ead8bd4e4f4'>
   <vCard:FN>Senzala Restaurant</vCard:FN>
   <vCard:EMAIL>senzala@example.com</vCard:EMAIL>
  </rdf:Description>

 </rdf:RDF>

=cut

use Encode;
use MIME::Base64;
use Text::vCard::Addressbook;
use Memoize;
use Digest::SHA1 qw (sha1_hex);

sub import {
    my $pkg = shift;
    $pkg->SUPER::import(@_);

    &memoize("_prepare_mbox");
    return 1;
}

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(%args)

This method inherits from I<XML::SAX::Base>

=cut

sub new {
    my $pkg  = shift;
    my $self = $pkg->SUPER::new(@_);

    if (! $self) {
	return undef;
    }

    $self->{'__uri'}    = "#";
    $self->{'__current'} = 0;

    $self->{'__files'}  = [];
    $self->{'__mboxes'} = {};

    return bless $self, $pkg;
}

=head1 OBJECT METHODS

=cut

=head1 OBJECT METHODS

=cut

sub base {
    my $self = shift;
    my $uri  = shift;

    if ($uri) {
	$self->{'__uri'} = $self->prepare_uri($uri);
    }

    return ($self->{'__uri'} || "#");
}

=head2 $pkg->parse_files(@files)

Generate SAX2 events for one, or more, vCard files.

Returns true or false.

=cut

=head2 $pkg->parse_files(@files)

=cut

sub parse_files {
  my $self  = shift;
  my @files = @_;

  my $book = undef;

  eval {
      $book = Text::vCard::Addressbook->load(\@files);
  };

  if ($@) {
      warn $@;
      return 0;
  }

  $self->{'__files'}   = \@files;
  $self->{'__current'} = 0;

  return $self->_render_doc([ $book->vcards() ]);
}

=head1 PRIVATE METHODS

Private methods are documented below in case you need to subclass
this package to tweak its output.

=cut

=head2 $obj->_render_doc(\@vcards)

=cut

sub _render_doc {
    my $self  = shift;
    my $cards = shift;

    $self->start_document();

    $self->start_element({Name => "rdf:RDF"});
	
    foreach my $vcard (@$cards) {

	$self->base($self->{'__files'}->[$self->{'__current'} ++]);
	$self->_render_card($vcard);
    }

    # Now render rdf:Description blocks for all
    # the email addresses we've collected that
    # point back to the current document using
    # rdf:seeAlso

    $self->_render_foaf_mboxes();
	
    $self->end_element({Name => "rdf:RDF"});
    
    $self->end_document();
    return 1;
}

=head2 $obj->_render_card(Text::vCard)

=cut

sub _render_card {
  my $self  = shift;
  my $vcard = shift;

  $self->start_element({Name       => "rdf:Description",
			Attributes => {"{}about" => {Name  => "rdf:about",
						     Value => $self->base()}}});
  
  # 

  $self->_pcdata({Name  => "vCard:CLASS",
		  Value => ($vcard->class() || "PUBLIC")});

  foreach my $prop ("uid", "rev", "prodid") {

      if (my $value = $vcard->$prop()) {
	  $self->_pcdata({Name  => sprintf("vCard:%s",uc($prop)),
			  Value => $value});
      }
  }

  #

  $self->_render_fn($vcard);
  $self->_render_n($vcard);
  $self->_render_nickname($vcard);
  $self->_render_photo($vcard);
  $self->_render_bday($vcard);
  $self->_render_adrs($vcard);
  $self->_render_labels($vcard);
  $self->_render_tels($vcard);
  $self->_render_emails($vcard);
  $self->_render_instantmessaging($vcard);
  $self->_render_mailer($vcard);
  $self->_render_tz($vcard);
  $self->_render_geo($vcard);
  $self->_render_org($vcard);
  $self->_render_title($vcard);
  $self->_render_role($vcard);
  $self->_render_logo($vcard);
  # AGENT
  $self->_render_categories($vcard);
  $self->_render_note($vcard);
  # SORT
  $self->_render_sound($vcard);
  $self->_render_url($vcard);
  $self->_render_key($vcard);
  $self->_render_custom($vcard);

  $self->end_element({Name=>"rdf:Description"});

  return 1;
}

=head2 $obj->_render_fn(Text::vCard)

=cut

sub _render_fn {
    my $self  = shift;
    my $vcard = shift;

    $self->_pcdata({Name  => "vCard:FN",
		    Value => $vcard->fn()});
    
    return 1;
}

=head2 $obj->_render_n(Text::vCard)

=cut

sub _render_n {
    my $self  = shift;
    my $vcard = shift;

    my $n = $vcard->get({"node_type" => "name"});

    if (! $n) {
	return 1;
    }

    $n = $n->[0];

    #

    if (($n->family()) || ($n->given())) {

	$self->start_element({Name       => "vCard:N",
			      Attributes => {"{}parseType"=>{Name  => "rdf:parseType",
							     Value => "Resource"}},});
	
	if (my $f = $n->family()) {
	    $self->_pcdata({Name  => "vCard:Family",
			    Value => $n->family()});
	}

	if (my $g = $n->given()) {
	    $self->_pcdata({Name  => "vCard:Given",
			    Value => $n->given()});
	}
	
	if (my $o = $n->middle()) {
	    $self->_pcdata({Name  => "vCard:Other",
			    Value => $o});
	}
	
	if (my $p = $n->prefixes()) {
	    $self->_pcdata({Name  => "vCard:Prefix",
			    Value => $p});
	}
	
	if (my $s = $n->suffixes()) {
	    $self->_pcdata({Name  => "vCard:Suffix",
			    Value => $s});
	}
	
	$self->end_element({Name => "vCard:N"});
    }
    
    return 1;
}

=head2 $obj->_render_nickname(Text::vCard)

=cut

sub _render_nickname {
    my $self = shift;
    my $vcard = shift;

    if (my $nick = $vcard->nickname()) {
	$self->_pcdata({Name  => "vCard:NICKNAME",
			Value => $nick});
    }

    return 1;
}

=head2 $obj->_render_photo(Text::vCard)

=cut

sub _render_photo {
    my $self  = shift;
    my $vcard = shift;

    my $photos = $vcard->get({"node_type" => "photo"});

    $self->_renderlist_mediaitems("vCard:PHOTO",
				  $photos);
    return 1;
}


=head2 $obj->_render_bday(Text::vCard)

=cut

sub _render_bday {
    my $self = shift;
    my $vcard = shift;

    if (my $bday = $vcard->bday()) {
	$self->_pcdata({Name  => "vCard:BDAY",
			Value => $bday});
    }

    return 1;
}

=head2 $obj->_render_adrs(Text::vCard)

=cut

sub _render_adrs {
    my $self  = shift;
    my $vcard = shift;

    my $addresses = $vcard->get({"node_type" => "addresses"});

    #

    $self->_renderlist("vCard:ADR",
		       $addresses,
		       sub {
			   my $self = shift;
			   my $adr  = shift;
	  
			   if (my $p = $adr->po_box()) {
			       $self->_pcdata({Name  => "vCard:pobox",
					       Value => $p});
			   }
			   
			   if (my $e = $adr->extended()) {
			       $self->_pcdata({Name  => "vCard:extadr",
					       Value => $e});
			   }
			   
			   if (my $s = $adr->street()) {
			       $self->_pcdata({Name  => "vCard:Street",
					       Value => $s});
			   }
			   
			   if (my $c = $adr->city()) {
			       $self->_pcdata({Name  => "vCard:Locality",
					       Value => $c});
			   }
			   
			   if (my $r = $adr->region()) {
			       $self->_pcdata({Name  => "vCard:Region",
					       Value => $r});
			   }
			   
			   if (my $p = $adr->post_code()) {
			       $self->_pcdata({Name  => "vCard:Pcode",
					       Value => $p});
			   }
			   
			   if (my $c = $adr->country()) {
			       $self->_pcdata({Name  => "vCard:Country",
					       Value => $c});
			   }
		       });
    return 1;
}

=head2 $obj->_render_labels(Text::vCard)

=cut

sub _render_labels {
    my $self  = shift;
    my $vcard = shift;

    my $labels = $vcard->get({"node_type" => "labels"});

    #

    $self->_renderlist("vCard:LABEL",
		       $labels,
		       sub {
			   my $self  = shift;
			   my $label = shift;

			   $self->_pcdata({Name       => "rdf:value",
					   Value      => $label->value(),
					   Attributes => {$self->_parsetype("Literal")},
					   CDATA      => 1,});
		       });
    return 1;
}

=head2 $obj->_render_tels(Text::vCard)

=cut

sub _render_tels {
    my $self  = shift;
    my $vcard = shift;

    my $tels = $vcard->get({'node_type' => 'tel'});

    $self->_renderlist("vCard:TEL",
		       $tels,
		       sub {
			   my $self = shift;
			   my $tel  = shift;

			   $self->_pcdata({Name  => "rdf:value",
					   Value => $tel->value()});
		       });
    return 1;
}

=head2 $obj->_render_emails(Text::vCard)

=cut

sub _render_emails {
    my $self  = shift;
    my $vcard = shift;

    my $addresses = $vcard->get({"node_type" => "email"});

    $self->_renderlist("vCard:EMAIL",
		       $addresses,
		       sub {
			   my $self  = shift;
			   my $email = shift;

			   $self->_pcdata({Name  => "rdf:value",
					   Value => $email->value()});
		       });

    # Keep track of email addresses for
    # dumping by '_render_foaf_mboxes'

    my $base = $self->base();

    foreach my $email (@$addresses) {
	my $mbox = &_prepare_mbox($email->value());
	
	$self->{'__mboxes'}->{$mbox} ||= [];
	push @{$self->{'__mboxes'}->{$mbox}}, $base;
    }

    return 1;
}

=head2 $obj->_render_instantmessaging(Text::vCard)

=cut

sub _render_instantmessaging {
    my $self  = shift;
    my $vcard = shift;

    my $im_list = $self->_im_services();

    foreach my $service (sort {$a cmp $b} keys %$im_list) {

	my $addresses = $vcard->get({"node_type" => "x-$service"});
	
	$self->_render_im_service($im_list->{$service},
				  $addresses);
    }
 
    return 1;
}

sub _render_im_service {
    my $self     = shift;
    my $service  = shift;
    my $accounts = shift;

    if (! $accounts) {
	return 1;
    }

    $self->_renderlist($service,
		       $accounts,
		       sub {
			   my $self = shift;
			   my $im   = shift;

			   $self->_pcdata({Name  => "rdf:value",
					   Value => $im->value()});
		       });

    return 1;
}

=head2 $obj->_render_mailer(Text::vCard)

=cut

sub _render_mailer {
    my $self  = shift;
    my $vcard = shift;

    if (my $m = $vcard->mailer()) {
	$self->_pcdata({Name  => "vCard:MAILER",
			Value => $m});
    }

    return 1;
}

=head2 $obj->_render_tz(Text::vCard)

=cut

sub _render_tz {
    my $self  = shift;
    my $vcard = shift;

    if (my $tz = $vcard->tz()) {
	$self->_pcdata({Name  => "vCard:TZ",
			Value => $tz});
    }

    return 1;
}

=head2 $obj->_render_geo(Text::vCard)

=cut

sub _render_geo {
    my $self  = shift;
    my $vcard = shift;

    my $geo = $vcard->get({'node_type' => "geo"});

    if (! $geo) {
	return 1;
    }

    $geo = $geo->[0];

    #

    $self->start_element({Name       => "vCard:GEO",
			  Attributes => {"{}parseType"=>{Name  => "rdf:parseType",
							 Value => "Resource"}},});
    
    $self->_pcdata({Name  => "geo:lat",
		    Value => $geo->lat()});

    $self->_pcdata({Name  => "geo:lon",
		    Value => $geo->long()});
    
    $self->end_element({Name=>"vCard:GEO"});

    return 1;
}

=head2 $obj->_render_org(Text::vCard)

=cut

sub _render_org {
    my $self = shift;
    my $vcard = shift;

    my $orgs = $vcard->get({'node_type' => "org"});

    if (! $orgs) {
	return 1;
    }

    my $org = $orgs->[0];

    if ((! $org->name()) && ((! $org->unit()))) {
	return 1;
    }

    my %parsetype = $self->_parsetype("Resource");

    $self->start_element({Name       => "vCard:ORG",
			  Attributes => \%parsetype});
    
    if (my $n = $org->name()) {
	$self->_pcdata({Name  => "vCard:Orgnam",
			Value => $n});
    }

    if (my $u = $org->unit()) {

	my @units = grep { /\w/ } @$u;
	my $count = scalar(@units);

	if ($count == 1) {
	    $self->_pcdata({Name  => "vCard:Orgunit",
			    Value => $units[0]});
	}

	elsif ($count) {
	    $self->start_element({Name => "vCard:Orgunit"});
	    $self->start_element({Name => "rdf:Seq"});

	    map {
		$self->_pcdata({Name  => "rdf:li",
				Value => $_});
	    } @units;

	    $self->end_element({Name => "rdf:Seq"});
	    $self->end_element({Name => "vCard:Orgunit"});
	}

	else {}
    }

    $self->end_element({Name=>"vCard:ORG"});
    return 1;
}

=head2 $obj->_render_title(Text::vCard)

=cut

sub _render_title {
    my $self  = shift;
    my $vcard = shift;

    if (my $t = $vcard->title()) {
	$self->_pcdata({Name  => "vCard:TITLE",
			Value => $t});
    }

    return 1;
}

=head2 $obj->_render_role(Text::vCard)

=cut

sub _render_role {
    my $self  = shift;
    my $vcard = shift;

    if (my $r = $vcard->role()) {
	$self->_pcdata({Name  => "vCard:ROLE",
			Value => $r});
    }

    return 1;
}

=head2 $obj->_render_logo(Text::vCard)

=cut

sub _render_logo {
    my $self  = shift;
    my $vcard = shift;

    my $logos = $vcard->get({"node_type" => "logo"});

    $self->_renderlist_mediaitems("vcard:LOGO",
				  $logos);

    return 1;
}

=head2 $obj->_render_categories(Text::vCard)

=cut

sub _render_categories {
    my $self  = shift;
    my $vcard = shift;

    my $cats = $vcard->get({'node_type' => 'categories'}) ||
	       $vcard->get({'node_type' => 'category'});

    if (! $cats) {
	return 1;
    }

    # we don't call '_renderlist' since it
    # generates rdf:Bags and we need a 'Seq'
    # here

    $self->start_element({Name => "vCard:CATEGORIES"});
    $self->start_element({Name => "rdf:Seq"});

    foreach my $c (@$cats) {
	$self->_pcdata({Name  => "rdf:li",
			Value => $c->value()});
    }
    
    $self->end_element({Name => "rdf:Seq"});	
    $self->end_element({Name => "vCard:CATEGORIES"});

    return 1;
}

=head2 $obj->_render_note(Text::vCard)

=cut

sub _render_note {
    my $self  = shift;
    my $vcard = shift;

    my $notes = $vcard->get({"node_type" => "note"});
    
    if (! $notes) {
	return 1;
    }
    
    $self->_pcdata({Name       => "vCard:NOTE",
		    Attributes => {$self->_parsetype("Literal")},
		    CDATA      => 1,
		    Value      => $notes->[0]->value()});
    return 1;
}

=head2 $self->_render_sound(Text::vCard)

=cut

sub _render_sound {
    my $self = shift;
    my $vcard = shift;

    my $snds = $vcard->get({'node_type' => 'sound'});

    $self->_renderlist_mediaitems("vCard:SOUND",
				  $snds);
    return 1;
}

=head2 $self->_render_url(Text::vCard)

=cut

sub _render_url {
    my $self  = shift;
    my $vcard = shift;

    if (my $url = $vcard->url()) {
	$self->_pcdata({Name       => "vCard:URL",
			Attributes => {"{}resource" => {Name  => "rdf:resource",
							Value => $url}}});
    }
    
    return 1;
}

=head2 $obj->_render_key(Text::vCard)

=cut

sub _render_key {
    my $self  = shift;
    my $vcard = shift;

    my $keys = $vcard->get({'node_type' => 'key'});

    $self->_renderlist_mediaitems("vCard:KEY",
				  $keys);
    return 1;
}

=head2 $obj->_render_custom(Text::vCard)

By default this method does nothing. It is here to
be subclassed.

=cut

sub _render_custom { }

=head2 $obj->_im_services()

Returns a hash ref mapping an instant messaging service
type to an XML element. Default is :

 {"aim"    => "foaf:aimChatID",
  "yahoo"  => "foaf:yahooChatID",
  "msn"    => "foaf:msnChatID",
  "jabber" => "foaf:JabberID",
  "icq"    => "foaf:icqChatId"}

This is called by the I<_render_instantmessaging> method.

=cut

sub _im_services {
    return {"aim"    => "foaf:aimChatID",
	    "yahoo"  => "foaf:yahooChatID",
	    "msn"    => "foaf:msnChatID",
	    "jabber" => "foaf:JabberID",
	    "icq"    => "foaf:icqChatID"};
}

sub _pcdata {
  my $self = shift;
  my $data = shift;

  $self->start_element($data);

  if ($data->{CDATA}) {
      $self->start_cdata();
  }

  if ($data->{Value}) {
      $self->characters({Data => encode_utf8($data->{Value})});
  }

  if ($data->{CDATA}) {
      $self->end_cdata();
  }

  $self->end_element($data);
  return 1;
}

sub _media {
  my $self = shift;
  my $obj  = shift;


  return 1;
}

sub _types {
    my $self = shift;
    
    my $ns = $self->namespaces();

    foreach my $type (grep { defined($_) && $_ =~ m/\w/ } @_) {
	
	$self->start_element({Name       => "rdf:type",
			      Attributes => {"{}resource" => {Name  => "rdf:resource",
							      Value => $ns->{vCard}.$type}}
			  });
	$self->end_element({Name => "rdf:type"});
    }

    return 1;
}

sub _parsetype {
    my $self     = shift;
    my $resource = shift;

    return ("{}parseType" => {Name  => "rdf:parseType",
			      Value => $resource});
}

sub start_document {
    my $self = shift;

    $self->SUPER::start_document();

    $self->xml_decl({Version  => "1.0",
		     Encoding => "UTF-8"});

    my $ns = $self->namespaces();

    foreach my $prefix (keys %$ns) {
	$self->start_prefix_mapping({Prefix       => $prefix,
				     NamespaceURI => $ns->{$prefix}});
    }
    
    return 1;
}

sub end_document {
    my $self = shift;

    foreach my $prefix (keys %{$self->namespaces()}) {
	$self->end_prefix_mapping({Prefix => $prefix});
    }

    $self->SUPER::end_document();
    return 1;
}

sub start_element {
  my $self = shift;
  my $data = shift;

  my $name  = $self->prepare_qname($data->{Name});
  my $attrs = $self->prepare_attrs($data->{Attributes});

  $self->SUPER::start_element({ %$name, %$attrs });
}

sub end_element {
  my $self = shift;
  my $data = shift;

  my $name = $self->prepare_qname($data->{Name});

  $self->SUPER::end_element($name);
}

sub _renderlist {
    my $self  = shift;
    my $el    = shift;
    my $list  = shift;
    my $sub   = shift;

    if (! $list) {
	return 1;
    }

    my $bag = (scalar(@$list) > 1) ? 1 : 0;

    #

    my %parsetype = $self->_parsetype("Resource");
    my %attrs     = ($bag) ? (): %parsetype;

    $self->start_element({Name       => $el,
			  Attributes => \%attrs}); 
    
    if ($bag) {
	$self->start_element({Name => "rdf:Bag"});
    }

    foreach my $obj (@$list) {

	if ($bag) {
	    $self->start_element({Name       => "rdf:li",
				  Attributes => {%parsetype}});
	}

	$self->_types($obj->types());

	&$sub($self,$obj);

	if ($bag) {
	    $self->end_element({Name=>"rdf:li"});
	}
    }

    if ($bag) {
	$self->end_element({Name => "rdf:Bag"});
    }

    $self->end_element({Name => $el});
    return 1;
}

sub _renderlist_mediaitems {
    my $self = shift;
    my $el   = shift;
    my $list = shift;

    if (! $list) {
	return 1;
    }

    my $bag = (scalar(@$list) > 1) ? 1 : 0;

    #

    my %parsetype = $self->_parsetype("Resource");
    my %attrs     = ($bag) ? (): %parsetype;

    # aside from the normal hoop jumping
    # involved in bags/single items we 
    # also need to contend with whether an
    # item has data or is simply a reference
    # to another resource

    if (! $bag) {

	my $obj = $list->[0];

	if (! $obj->is_type("base64")) {
	    $self->_mediaref($el,$obj);
	}

	else {
	    $self->start_element({Name       => $el,
				  Attributes => {$self->_parsetype("Resource")}});
	    $self->_mediaobj($obj);
	    $self->end_element({Name => $el});
	}

	return 1;
    }

    # bag

    $self->start_element({Name       => $el,
			  Attributes => \%attrs}); 
    
    $self->start_element({Name => "rdf:Bag"});
    
    foreach my $obj (@$list) {
	
	if (! $obj->is_type("base64")) {
	    %attrs = ("{}resource" => {Name  => "rdf:resource",
				       Value => $obj->value()});
	}
	
	else {
	    %attrs = %parsetype;
	}

	#
	
	$self->start_element({Name       => "rdf:li",
			      Attributes => \%attrs});
	
	if ($obj->is_type("base64")) {	    
	    $self->_mediaobj($obj);
	}
	
	$self->end_element({Name => "rdf:li"});
    }

    #

    $self->end_element({Name => "rdf:Bag"});
    $self->end_element({Name => $el});

    return 1;
}

sub _mediaref {
    my $self = shift;
    my $el   = shift;
    my $obj  = shift;

    $self->_pcdata({Name       => $el,
		    Attributes => {"{}resource" => {Name  => "rdf:resource",
						    Value => $obj->value()}}});
}

sub _mediaobj {
    my $self = shift;
    my $obj  = shift;

    $self->_types($obj->types());

    $self->_pcdata({Name  => "vCard:ENCODING",
		    Value => "b"});

    $self->_pcdata({Name       => "rdf:value",
		    Attributes => {$self->_parsetype("Literal")},
		    Value      => encode_base64($obj->value()),
		    CDATA      => 1});

    return 1;
}

# memoized

sub _prepare_mbox {
    my $email_addr = shift;
    return encode_utf8(sprintf("%smbox_sha1sum#%s",
			       __PACKAGE__->namespaces()->{foaf},
			       sha1_hex($email_addr)));
}

sub _render_foaf_mboxes {
    my $self = shift;

    foreach my $mbox (keys %{$self->{'__mboxes'}}) {

	$self->start_element({Name       => "rdf:Description",
			      Attributes => {"{}rdf:about" => {Name  => "rdf:about",
							       Value => $mbox}}});
	foreach my $uri (@{$self->{'__mboxes'}->{$mbox}}) {

	    $self->start_element({Name       => "rdfs:seeAlso",
				  Attributes => {"{}rdf:resource" => {Name  => "rdf:resource",
								      Value => $uri}}});
	    $self->end_element({Name => "rdfs:seeAlso"});	    
	}

	$self->end_element({Name => "rdf:Description"});
    }

    return 1;
}

sub DESTROY {}

=head1 NAMESPACES

This package generates SAX events using the following XML
namespaces :

=over 4

=item * B<vCard>

 http://www.w3.org/2001/vcard-rdf/3.0#

=item * B<rdf>

 http://www.w3.org/1999/02/22-rdf-syntax-ns#

=item * B<foaf:>

 http://xmlns.com/foaf/0.1/

=item * B<geo>

 http://www.w3.org/2003/01/geo/wgs84_pos#

=back

=cut

=head1 VERSION

1.4

=head1 DATE

$Date: 2004/12/28 21:50:27 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<Text::vCard>

L<XML::Generator::vCard>

L<XML::Generator::RFC822::RDF>

=head1 BUGS

vCards containg binary PHOTO images may cause Perl to segfault on
Mac OSX and come flavours of Linux (but not FreeBSD.) The source of
this problem has been traced, I think, to a regular expression issue
in the Perl Text::ParseWords library. A bug report has been filed.

Please report all other bugs via http://rt.cpan.org

=head1 LICENSE

Copyright (c) 2004, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it 
under the same terms as Perl itself.

=cut

return 1;
