# $Id: vCard.pm,v 1.28 2004/12/28 23:31:29 asc Exp $
use strict;

package XML::Generator::vCard;
use base qw (XML::Generator::vCard::Base);

$XML::Generator::vCard::VERSION = '1.3';

=head1 NAME

XML::Generator::vCard - generate SAX2 events for vCard 3.0

=head1 SYNOPSIS

 use XML::SAX::Writer;
 use XML::Generator::vCard;

 my $writer = XML::SAX::Writer->new();
 my $driver = XML::Generator::vCard->new(Handler=>$writer);

 $driver->parse_files("test.vcf");

=head1 DESCRIPTION

Generate SAX2 events for vCard 3.0.

This package supersedes I<XML::SAXDriver::vCard>.

=head1 DOCUMENT FORMAT

SAX2 events map to the I<vCard 3.0 XML DTD> draft:

 http://xml.coverpages.org/draft-dawson-vcard-xml-dtd-00.txt

The draft itself has since expired but it still seems like a
perfectly good place to start from.

=cut

use Encode;
use MIME::Base64;
use Text::vCard::Addressbook;

use constant NS => {"vCard" => "x-urn:cpan:ascope:xml-generator-vcard#",
		    "foaf"  => "http://xmlns.com/foaf/0.1/"};

use constant VCARD_VERSION => "3.0";
use constant VCARD_CLASS   => "PUBLIC";

sub import {
    my $pkg = shift;
    $pkg->SUPER::import(@_);

    my $ns = $pkg->namespaces();
    $ns->{ vCard } = "x-urn:cpan:ascope:xml-generator-vcard#";
    
    no strict "refs";
    * { join("::",$pkg,"namespaces") } = sub { return $ns; };

    return 1;
}

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(%args)

This method inherits from I<XML::SAX::Base>.

Returns a I<XML::Generator::vCard> object.

=cut

=head1 OBJECT METHODS

=cut

=head2 $pkg->parse_files(@files)

Generate SAX2 events for one, or more, vCard files.

Returns true or false.

=cut

sub parse_files {
  my $self  = shift;
  my @files = @_;

  my $book  = ();
  
  eval {
      $book = Text::vCard::Addressbook->load(\@files);
  };

  if ($@) {
      warn $@;
      return 0;
  }

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

    if (scalar(@$cards) > 1) {
	
	$self->start_element({Name => "vCard:vCardSet"});
	
	foreach my $vcard (@$cards) {
	    $self->_render_card($vcard);
	}
	
	$self->end_element({Name => "vCard:vCardSet"});
    }
    
    else {
	$self->_render_card($cards->[0]);
    }
    
    #
    
    $self->end_document();
    return 1;
}

=head2 $obj->_render_card(Text::vCard)

=cut

sub _render_card {
  my $self  = shift;
  my $vcard = shift;
  
  my $attrs = {
      "{}version" => {Name  => "vCard:version",
		      Value => ($vcard->version() || VCARD_VERSION)},
      "{}class"   => {Name  => "vCard:class",
		      Value => ($vcard->class()   || VCARD_CLASS)},
  };

  #

  foreach my $prop ("uid","rev","prodid") {
      if (my $value = $vcard->$prop()) {
	  $attrs->{"{}$prop"} = {Name  => "vCard:$prop",
				 Value => $value};
      }
  }

  $self->start_element({Name       => "vCard:vCard",
			Attributes => $attrs});

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

  $self->end_element({Name=>"vCard:vCard"});

  return 1;
}

=head2 $obj->_render_fn(Text::vCard)

=cut

sub _render_fn {
    my $self = shift;
    my $vcard = shift;

    $self->_pcdata({Name  => "vCard:fn",
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

	$self->start_element({Name=>"vCard:n"});
	
	$self->_pcdata({Name  => "vCard:family",
			Value => $n->family()});
	
	    $self->_pcdata({Name  => "vCard:given",
			    Value => $n->given()});
	
	if (my $o = $n->middle()) {
	    $self->_pcdata({Name  => "vCard:other",
			    Value => $o});
	}
	
	if (my $p = $n->prefixes()) {
	    $self->_pcdata({Name  => "vCard:prefix",
			    Value => $p});
	}
	
	if (my $s = $n->suffixes()) {
	    $self->_pcdata({Name  => "vCard:suffix",
			    Value => $s});
	}
	
	$self->end_element({Name => "vCard:n"});
    }     
    
    return 1;
}

=head2 $obj->_render_nickname(Text::vCard)

=cut

sub _render_nickname {
    my $self  = shift;
    my $vcard = shift;

    if (my $nick = $vcard->nickname()) {
	$self->_pcdata({Name  => "vCard:nickname",
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

    if (! $photos) {
	return 1;
    }
  
    foreach my $p (@$photos) {
	$self->_media({name   => "vCard:photo",
		       media  => $p});
    }
    
    return 1;
}


=head2 $obj->_render_bday(Text::vCard)

=cut

sub _render_bday {
    my $self  = shift;
    my $vcard = shift;

    if (my $bday = $vcard->bday()) {
	$self->_pcdata({Name  => "vCard:bday",
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

    if (! $addresses) {
	return 1;
    }

    #

    foreach my $adr (@$addresses) {
		
	my $types = join(";",$adr->types());
	
	$self->start_element({Name       => "vCard:adr",
			      Attributes => {"{}del.type" => {Name  => "vCard:del.type",
							      Value => $types}}
			  });
	
	if (my $p = $adr->po_box()) {
	    $self->_pcdata({Name  => "vCard:pobox",
			    Value => $p});
	}
	
	if (my $e = $adr->extended()) {
	    $self->_pcdata({Name  => "vCard:extadr",
			    Value => $e});
	}
	
	if (my $s = $adr->street()) {
	    $self->_pcdata({Name  => "vCard:street",
			    Value => $s});
	}
	
	if (my $c = $adr->city()) {
	    $self->_pcdata({Name  => "vCard:locality",
			    Value => $c});
	}
	
	if (my $r = $adr->region()) {
	    $self->_pcdata({Name  => "vCard:region",
			    Value => $r});
	}
	
	if (my $p = $adr->post_code()) {
	    $self->_pcdata({Name  => "vCard:pcode",
			    Value => $p});
	}
	
	if (my $c = $adr->country()) {
	    $self->_pcdata({Name  => "vCard:country",
			    Value => $c});
	}
	
	$self->end_element({Name=>"vCard:adr"});
    }
    
    return 1;
}


=head2 $obj->_render_labels(Text::vCard)

=cut

sub _render_labels {
    my $self  = shift;
    my $vcard = shift;

    my $labels = $vcard->get({"node_type" => "labels"});
    
    if (! $labels) {
	return 1;
    }

    #

    foreach my $l (@$labels) {
	
	my $types = join(";",$l->types());
	
	$self->_pcdata({Name  => "vCard:label",
			Value => $l->value(),
			Attributes => {"{}del.type" => {Name  => "vCard:del.type",
							Value => $types}}
		    });
    }
    
    return 1;
}

=head2 $obj->_render_tels(Text::vCard)

=cut

sub _render_tels {
    my $self  = shift;
    my $vcard = shift;

    my $numbers = $vcard->get({"node_type" => "phone"});

    if (! $numbers) {
	return 1;
    }

    #

    foreach my $tel (@$numbers) {
	
	my $types = join(";",$tel->types());
	
	$self->_pcdata({Name  => "vCard:tel",
			Value => $tel->value(),
			Attributes => {"{}tel.type" => {Name  => "vCard:tel.type",
							Value => $types}}
		    });
    }
    
    return 1;
}

=head2 $obj->_render_emails(Text::vCard)

=cut

sub _render_emails {
    my $self  = shift;
    my $vcard = shift;

    my $addresses = $vcard->get({"node_type" => "email"});

    if (! $addresses) {
	return 1;
    }

    #

    foreach my $e (@$addresses) {

	my $types = join(";",$e->types());
	
	$self->_pcdata({Name  => "vCard:email",
			Value => $e->value(),
			Attributes => {"{}email.type" => {Name  => "vCard:email.type",
							  Value => $types}}
		    });
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
	
	if (! $addresses) {
	    next;
	}

	foreach my $im (@$addresses) {
	
	    my $types = join(";",$im->types());
	
	    $self->_pcdata({Name       => $im_list->{$service},
			    Value      => $im->value(),
			    Attributes => {"{}im.type"=> {Name  => "vCard:im.type",
							  Value => $types}}
			});
	}
    }

    return 1;
}

=head2 $obj->_render_mailer(Text::vCard)

=cut

sub _render_mailer {
    my $self  = shift;
    my $vcard = shift;

    if (my $m = $vcard->mailer()) {

	$self->_pcdata({Name  => "vCard:mailer",
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

	$self->_pcdata({Name  => "vCard:tz",
			Value => $tz});
    }

    return 1;
}

=head2 $obj->_render_geo(Text::vCard)

=cut

sub _render_geo {
    my $self  = shift;
    my $vcard = shift;

    my $geo = $vcard->get({"node_type" => "geo"});

    if (! $geo) {
	return 1;
    }

    $geo = $geo->[0];

    #

    $self->start_element({Name => "vCard:geo"});

    $self->_pcdata({Name  => "vCard:lat",
		    Value => $geo->lat()});

    $self->_pcdata({Name  => "vCard:lon",
		    Value => $geo->long()});

    $self->end_element({Name => "vCard:geo"});
    return 1;
}

=head2 $obj->_render_org(Text::vCard)

=cut

sub _render_org {
    my $self = shift;
    my $vcard = shift;

    my $orgs = $vcard->get({"node_type" => "org"});

    if (! $orgs) {
	return 1;
    }

    #

    foreach my $o (@$orgs) {
	$self->start_element({Name => "vCard:org"});

	if (my $name = $o->name()) {

	    $self->_pcdata({Name  => "vCard:orgnam",
			    Value => $name});
	} 

	if (my $units = $o->unit()) {

	    foreach my $u (grep { /\w/ } @$units) {
		$self->_pcdata({Name  => "vCard:orgunit",
				Value => $u});
	    }
	}

	$self->end_element({Name => "vCard:org"});
    }

    return 1;
}

=head2 $obj->_render_title(Text::vCard)

=cut

sub _render_title {
    my $self  = shift;
    my $vcard = shift;

    if (my $t = $vcard->title()) {

	$self->_pcdata({Name  => "vCard:title",
			Value => $t});
    }

    return 1;
}

=head2 $obj->_render_role(Text::vCard)

=cut

sub _render_role {
    my $self = shift;
    my $vcard = shift;

    if (my $r = $vcard->role()) {

	$self->_pcdata({Name  => "vCard:role",
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

    if (! $logos) {
	return 1;
    }

    foreach my $l (@$logos) {

	$self->_media({name  => "vCard:logo",
		       media => $l});
    }

    return 1;
}

=head2 $obj->_render_categories(Text::vCard)

=cut

sub _render_categories {
    my $self = shift;
    my $vcard = shift;

    my $cats = $vcard->get({"node_type" => 'categories'}) ||
	       $vcard->get({"node_type" => 'category'});

    if (! $cats) {
	return 1;
    }

    #

    $self->start_element({Name => "vCard:categories"});
	
    foreach (split(",",$cats->[0]->value())) {
	
	$self->_pcdata({Name  => "vCard:item",
			Value => $_});
    }
    
    $self->end_element({Name => "vCard:categories"});
    return 1;
}

=head2 $obj->_render_note(Text::vCard)

=cut

sub _render_note {
    my $self  = shift;
    my $vcard = shift;

    my $n = $vcard->get({"node_type" => "note"});

    if (! $n) {
	return 1;
    }

    if (my $n = $vcard->note()) {
	$self->_pcdata({Name  => "vCard:note",
			CDATA => 1,
			Value => $n});	
    }
    
    return 1;
}

=head2 $self->_render_sound(Text::vCard)

=cut

sub _render_sound {
    my $self  = shift;
    my $vcard = shift;

    my $snds = $vcard->get({"node_type" => "sound"});

    if (! $snds) {
	return 1;
    }

    foreach my $s (@$snds) {
	$self->_media({name  => "vCard:sound",
		       media => $s});
    }

    return 1;
}

=head2 $self->_render_url(Text::vCard)

=cut

sub _render_url {
    my $self  = shift;
    my $vcard = shift;

    if (my $url = $vcard->url()) {
	$self->_pcdata({Name  => "vCard:url",
			Attributes => {"{}uri" => {Name  => "vCard:uri",
						   Value => $url}}});
    }
    
    return 1;
}

=head2 $obj->_render_key(Text::vCard)

=cut

sub _render_key {
    my $self  = shift;
    my $vcard = shift;

    my $keys = $vcard->get({"node_type" => "key"});

    if (! $keys) {
	return 1;
    }

    foreach my $k (@$keys) {
	$self->_media({name  => "vCard:key",
		       media => $k});
    }

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
  my $data = shift;

  my $attrs = {};

  # as in not 'key' and not something pointing to an 'uri'

  if (($data->{name} !~ /^k/) && ($data->{type})) {

      # as in 'photo' or 'logo' 
      # and not 'sound'
      
      my $mime = ($data->{name} =~ /^[pl]/i) ? "img" : "aud";
      
      $attrs = {"{}$mime.type"=>{Name  => "vCard:$mime.type",
				 Value => $data->{type}}};
  }

  #

  my $obj = $data->{media};

  $self->start_element({Name       => $data->{name},
			Attributes => $attrs});

  if ($obj->is_type("base64")) {
      $self->_pcdata({Name  => "vCard:b64bin",
		      Value => encode_base64($obj->value()),
		      CDATA => 1});
  }

  else {
      $self->_pcdata({Name       => "extref",
		      Attributes => {"{}uri" => {Name  => "vCard:uri",
						 Value => $obj->value()}}
		  });
  }

  $self->end_element({Name => $data->{name}});
  return 1;
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

sub DESTROY {}

=head1 NAMESPACES

This package generates SAX events using the following XML
namespaces :

=over 4

=item * B<vCard>

 x-urn:cpan:ascope:xml-generator-vcard#

=item * B<foaf:>

 http://xmlns.com/foaf/0.1/

=back

=head1 HOW TO

=head2 Filter cards by category 

 package MyGenerator;
 use base qw (XML::Generator::vCard);

 sub _render_card {
     my $self = shift;
     my $card = shift;

     my $cats = $vcard->get({"node_type" => 'categories'}) ||
	        $vcard->get({"node_type" => 'category'});

     if (! $cats) {
	 return 1;
     }
     
     if (! grep { $_->value() eq "foo" } split(",",$cats->[0])) {
	 return 1;
     }

     return $self->SUPER::_render_card($vcard);
 }

 package main;

 my $writer = XML::SAX::Writer->new();
 my $parser = MyGenerator->new(Handler=>$writer);

 $parser->parse_files(@ARGV);

=head2 Generate SAX events for a custom 'X-*' field

 package MyGenerator;
 use base qw (XML::Generator::vCard);

 sub _render_custom {
   my $self  = shift;
   my $vcard = shift;

   my $custom = $vcard->get({"node_type" => "x-foobar"});
	
   if (! $addresses) {
      next;
   }

   foreach my $foo (@$custom) {
	
      my $types = join(";",$foo->types());

      $self->_pcdata({Name       => "foo:bar",
	   	      Value      => $foo->value(),
		      Attributes => {"{}type"=> {Name  => "type",
						 Value => $types}}
		      });
   }

   return 1;
 }
 
 package main;

 my $writer = XML::SAX::Writer->new();
 my $parser = MyGenerator->new(Handler=>$writer);

 $parser->parse_files(@ARGV);

=head2 Add custom namespaces

 package MyGenerator;
 use base qw (XML::Generator::vCard);

 sub namespaces {
     my $self = shift;
     
     my $ns = $self->SUPER::namespaces();
     $ns->{ "foo" } = "x-urn:foo:bar#";

     return $ns;
 }

 package main;

 my $writer = XML::SAX::Writer->new();
 my $parser = MyGenerator->new(Handler=>$writer);

 $parser->parse_files(@ARGV);

=head1 VERSION

1.3

=head1 DATE

$Date: 2004/12/28 23:31:29 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<Text::vCard>

L<XML::Generator::vCard::Base>

http://www.ietf.org/rfc/rfc2426.txt

http://www.ietf.org/rfc/rfc2425.txt

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

return 1
