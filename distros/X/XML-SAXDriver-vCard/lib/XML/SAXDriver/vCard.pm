=head1 NAME

XML::SAXDriver::vCard - generate SAX2 events for vCard 3.0

=head1 SYNOPSIS

 use XML::SAX::Writer;
 use XML::SAXDriver::vCard;

 my $writer = XML::SAX::Writer->new();
 my $driver = XML::SAXDriver::vCard->new(Handler=>$writer);

 $driver->parse_file("test.vcd");

=head1 DESCRIPTION

Generate SAX2 events for vCard 3.0

=cut

use strict;

package XML::SAXDriver::vCard;
use base qw (XML::SAX::Base);

$XML::SAXDriver::vCard::VERSION = '0.05';

use constant NS => {
		    "VCARD" => "http://www.ietf.org/internet-drafts/draft-dawson-vCard-xml-dtd-04.txt",
		   };

use constant VCARD_VERSION => "3.0";

# Can someone please tell me how to derefence constants
# in regular expressions. You can't, can you....
my $regexp_type = qr/(?:;(TYPE=(?:(?:\\:|[^:])+)?)?)/i;

=head1 PACKAGE METHODS

=head2 __PACKAGE__->new(%args)

This method is inherited from I<XML::SAX::Base>

=cut

=head1 OBJECT METHODS

=head2 $pkg->parse($string)

=cut

sub parse {
  my $self = shift;
  my $str  = shift;

  if (! $str) {
    die "Nothing to parse.\n";
  }

  $self->start_document();
  $self->_parse_str($str);
  $self->end_document();

  return 1;
}

=head2 $pkg->parse_file($path)

=cut

sub parse_file {
  my $self  = shift;
  my $vcard = shift;

  $vcard =~ s/file:\/\///;

  require FileHandle;
  my $fh = FileHandle->new($vcard)
    || die "Can't open '$vcard', $!\n";

  $self->start_document();
  $self->_parse_file(\*$fh);
  $self->end_document();

  return 1;
}

=head2 $pkg->parse_uri($uri)

=cut

sub parse_uri {
  my $self = shift;
  my $uri  = shift;

  if ($uri =~ /^file:\/\//) {
    return $self->parse_file($uri);
  }

  require LWP::Simple;

  if (! LWP::Simple::head($uri)) {
    die "Unable to retreive remote vCard : ".getprint($uri)."\n";
  }

  return $self->parse(LWP::Simple::get($uri));
}

# Private methods

# Section 2.4.2 for discussion of chunks

sub _parse_str {
  my $self = shift;
  my $str  = shift;

  my %card = ();

  foreach (split("\n",$str)) {

    if (! $self->_parse_ln($_,\%card)) {
      %card = ();
    }
  }

  return 1;
}

sub _parse_file {
  my $self = shift;
  my $fh   = shift;

  my %card = ();

  while (! $fh->eof()) {
    my $ln = $fh->getline();
    chomp $ln;

    if (! $self->_parse_ln($ln,\%card)) {
      %card = ();
    }
  }

  return 1;
}

sub _parse_ln {
  my $self  = shift;
  my $ln    = shift;
  my $vcard = shift;

  # Danger, Will Robinson! Un-SAX like behaviour ahead.

  # Specifically, we are going tostore record data in a 
  # private hash ref belonging to the
  # object. I am not happy about this either, however we have to
  # do this because the vCard UID property is mapped to XML as
  # an attribute of the vcard element. Since we have no idea
  # where the UID property will be in the vCard -- it will probably
  # be near the bottom of the record -- we have to postpone any
  # writing until we get to it. There is always the possibility
  # that property won't be defined but... Anyway, there are other
  # properties that are mapped to vcard@foo so in an effort to keep
  # the code (relatively) small and clean I've opted for caching 
  # everything and writing it all out when the 'END:vCard thingy
  # is reached. It occured to me to write the (XML) data once, cache 
  # only a small set of properties and then add them at the end 
  # using XML::SAX::Merger. Ultimately, I decided that was crazy-talk.

  # These are the properties you are looking for.

  if ($ln =~ /^[DHIJQVWYZ]/i) {
    return 1;
  }

  # AGENT properties are parsed separately when the current vCard
  # is rendered. So we'll just keep track of the agent's vcard data
  # as a big ol' string.

  elsif ($vcard->{'__isagent'}) {
    $vcard->{agent}{vcard} .= $ln."\n";
    if ($ln =~ /^EN/i) { $vcard->{'__isagent'} = 0; }
    return 1;
  }

  else {}

  # SOURCE
  if ($ln =~ /^SOUR/i) {
    $ln =~ /^SOURCE:(.*)/i;
    $vcard->{source} = $1;
  }

  # FN
  elsif ($ln =~ /^F/i) {
    $ln =~ /^FN:(.*)$/i;
    $vcard->{fn} = $1;
  }

  # N
  elsif ($ln =~ /^N:/i) {
    # Family Name, Given Name, Additional Names, 
    # Honorific Prefixes, and Honorific Suffixes.
    $ln =~ /^N:([^;]+)?;([^;]+)?;([^;]+)?;([^;]+)?;([^;]+)?$/i;
    $vcard->{n} = {family=>$1,given=>$2,other=>$3,prefixes=>$4,suffixes=>$5};
  }

  # NICKNAME
  elsif ($ln =~ /^NI/i) {
    $ln =~ /^NICKNAME:(.*)$/i;
    $vcard->{nickname} = $1;
  }

  # PHOTO
  elsif ($ln =~ /^PHOT/i) {
    $ln =~ /^PHOTO;(?:VALUE=uri:(.*)|ENCODING=b;TYPE=([^:]+):(.*))$/i;
    $vcard->{photo} = ($2) ? {type=>$1,b64=>$2} : {url=>$1};
  }

  # BDAY
  elsif ($ln =~ /^BD/i) {
    $ln =~ /^BDAY:(.*)$/i;
    $vcard->{bday} = $1;
  }

  # ADR
  # Mulitple ADR 'TYPE's may be defined using either as
  # a parameter list or a value list.

  if ($ln =~ /^AD/i) {
    $ln =~ /^ADR$regexp_type:([^;]+)?;([^;]+)?;([^;]+)?;([^;]+)?;([^;]+)?;([^;]+)?;([^;]+)?$/i;
    push @{$vcard->{adr}} , {"type"=>$1,pobox=>$2,extadr=>$3,street=>$4,locality=>$5,region=>$6,pcode=>$7,country=>$8};
  }

  # LABEL
  elsif ($ln =~ /^L/i) {
  }

  # TEL
  elsif ($ln =~ /^TE/i) {
    $ln =~ /^TEL$regexp_type?:(.*)$/i;
    push @{$vcard->{tel}},{"type"=>$1,number=>$2};
  }

  # EMAIL
  elsif ($ln =~ /^EM/i) {
    $ln =~ /^EMAIL$regexp_type?:(.*)$/i;
    push @{$vcard->{email}},{"type"=>($1 || "internet"),address=>$2};
  }

  # MAILER
  elsif ($ln =~ /^M/i) {
    $ln =~ /^MAILER;(.*)$/i;
    $vcard->{mailer} = $1;
  }

  # TZ
  elsif ($ln =~ /^TZ/i) {
    $ln =~ /^TZ:(?:VALUE=([^:]+):)?(.*)$/i;
    $vcard->{tz} = $1;
  }

  # GEO
  elsif ($ln =~ /^G/i) {
    $ln =~ /^GEO:([^;]+);(.*)$/i;
    $vcard->{geo} = {lat=>$1,lon=>$2};
  }

  # TITLE
  elsif ($ln =~ /^TI/i) {
    $ln =~ /^TITLE:(.*)$/i;
    $vcard->{title} = $1;
  }

  # ROLE
  elsif ($ln =~ /^R/i) {
    $ln =~ /^ROLE:(.*)$/i;
    $vcard->{role} = $1;
  }

  # LOGO
  elsif ($ln =~ /^L/i) {
    $ln =~ /^LOGO;(?:VALUE=(.*)|ENCODING=b;TYPE=([^:]+):(.*))$/i;
    $vcard->{logo} = ($2) ? {type=>$1,b64=>$2} : {url=>$1};
  }

  # AGENT
  elsif ($ln =~ /^AG/i) {
    $ln =~ /^AGENT(;VALUE=uri)?:(.*)$/i;

    if ($1) {
      $vcard->{agent}{'uri'} = $2;
    }

    $vcard->{'__isagent'}   = 1;

    # Note the '.='
    # It is possible that we are dealing
    # with nested AGENT properties. Ugh.
    $vcard->{agent}{vcard} .= "$2\n";
  }

  # ORG
  elsif ($ln =~ /^O/i) {
    $ln =~ /^ORG:([^;]+);([^;]+);(.*)$/i;
    $vcard->{org} = {name=>$1,unit=>$2};
  }

  # CATEGORIES
  elsif ($ln =~ /^CA/i) {
    $ln =~ /^CATEGORIES:(.*)$/i;
    $vcard->{categories} = [split(",",$1)];
  }

  # NOTE
  elsif ($ln =~ /^NO/i) {
    $ln =~ /^NOTE:(.*)$/i;
    $vcard->{note} = $1;
  }

  # PRODID
  elsif ($ln =~ /^PR/i) {
    $ln =~ /^PRODID:(.*)$/i;
    $vcard->{prodid} = $1;
  }

  # REV
  elsif ($ln =~ /^RE/i) {
    $ln =~ /^REV:(.*)$/i;
    $vcard->{rev} = $1;
  }

  # SORT-STRING
  elsif ($ln =~ /^SOR/i) {
    $ln =~ /^SORT-STRING:(.*)/i;
    $vcard->{'sort'} = $1;
  }

  # SOUND
  elsif ($ln =~ /^SOUN/i) {
    $ln =~ /^SOUND:TYPE=BASIC;(VALUE|ENCODING)=([buri]):(.*)$/i;
    $vcard->{'sound'} = ($1 eq "VALUE") ? {uri=>$2} : {b64=>$2};
  }

  # UID
  elsif ($ln =~ /^UI/i) {
    $ln =~ /^UID:(.*)$/i;
    $vcard->{uid} = $1;
  }

  # URL
  elsif ($ln =~ /^UR/i) {
    $ln =~ /^URL:(.*)$/i;
    push @{$vcard->{url}},$1;
  }

  # CLASS
  elsif ($ln =~ /^CL/i) {
    $ln =~ /^CLASS:(.*)$/i;
    $vcard->{class} = $1;
  }

  # KEY
  elsif ($ln =~ /^K/i) {
    $ln =~ /^KEY;ENCODING=b:(.*)$/i;
    $vcard->{'key'} = $1;
  }

  # X-CUSTOM
  elsif ($ln =~ /^X/i) {
    $ln =~ /^X-CUSTOM;([^:]+):(.*)$/i;
    push @{$vcard->{'x-custom'}}, {$1=>$2};
  }

  # END:vCard
  elsif ($ln =~ /^EN/i) {
    $self->_saxify($vcard);

    # We return 0 explicitly since that
    # is the signal to the calling method
    # that %$vcard should be emptied.
    return 0;
  }

  return 1
}

sub start_document {
  my $self = shift;

  $self->SUPER::start_document();
  $self->SUPER::xml_decl({Version=>"1.0"});
  # Add DOCTYPE stuff for X-LABEL here
  $self->start_prefix_mapping({Prefix=>"",NamespaceURI=>NS->{VCARD}});
  $self->SUPER::start_element({Name=>"vCardSet"});
  return 1;
}

sub end_document {
  my $self = shift;

  $self->SUPER::end_element({Name=>"vCardSet"});
  $self->end_prefix_mapping({Prefix=>""});
  $self->SUPER::end_document();
  return 1;
}

sub _saxify {
  my $self  = shift;
  my $vcard = shift;

  # See also : comments in &_parse()

  my $attrs = {
	       "{}version" => {Name=>"version",
			       Value=>VCARD_VERSION},
	       "{}class"=>{Name=>"class",
			   Value=>($vcard->{class} || "PUBLIC")},
	      };

  foreach ("uid","lang","rev","prodid") {
    if (exists($vcard->{$_})) {
      $attrs->{"{}$_"} = {Name=>$_,
			  Value=>$vcard->{$_}};
    }
  }

  #

  $self->SUPER::start_element({Name=>"vCard",Attributes=>$attrs});

  #

  # FN:
  $self->_pcdata({name=>"fn",value=>$vcard->{'fn'}});

  # N:
  $self->SUPER::start_element({Name=>"n"});

  foreach ("family","given","other","prefix","suffix") {
    $self->_pcdata({name=>$_,value=>$vcard->{'n'}{$_}});
  }

  $self->SUPER::end_element({Name=>"n"});

  # NICKNAME:
  if (exists($vcard->{'nickname'})) {
    $self->_pcdata({name=>"nickname",value=>$vcard->{'nickname'}});
  }

  # PHOTO:
  if (exists($vcard->{'photo'})) {
    $self->_media({name=>"photo",%{$vcard->{photo}}});
  }

  # BDAY:
  if (exists($vcard->{'bday'})) {
    $self->_pcdata({name=>"bday",value=>$vcard->{'bday'}});
  }

  # ADR:
  if (ref($vcard->{'adr'}) eq "ARRAY") {
    foreach my $adr (@{$vcard->{'adr'}}) {

      &_munge_type(\$adr->{type});

      $self->SUPER::start_element({Name=>"adr",
				   Attributes=>{"{}del.type"=>{Name=>"del.type",Value=>$adr->{type}}}
				  });

      foreach ("pobox","extadr","street","locality","region","pcode","country") {
	$self->_pcdata({name=>$_,value=>$adr->{$_}});
      }

      $self->SUPER::end_element({Name=>"adr"});
    }
  }

  # LABEL
  # $self->label();

  if (ref($vcard->{'tel'}) eq "ARRAY") {

    foreach my $t (@{$vcard->{'tel'}}) {
      &_munge_type(\$t->{type});

      $self->_pcdata({name=>"tel",value=>$t->{number},
		      attrs=>{"{}tel.type"=>{Name=>"tel.type",Value=>$t->{type}}}
		     });
    }
  }

  # EMAIL:

  if (ref($vcard->{'email'}) eq "ARRAY") {

    foreach my $e (@{$vcard->{'email'}}) {
      &_munge_type(\$e->{type});

      $self->_pcdata({name=>"email",value=>$e->{address},
		      attrs=>{"{}email.type"=>{Name=>"email.type",Value=>$e->{type}}}
		     });
    }
  }

  # MAILER:
  if (exists($vcard->{'mailer'})) {
    $self->_pcdata({name=>"mailer",
		    value=>$vcard->{'mailer'}});
  }

  # TZ:
  if (exists($vcard->{'tz'})) {
    $self->_pcdata({name=>"tz",
		    value=>$vcard->{'tz'}});
  }

  # GEO:
  if (exists($vcard->{'geo'})) {
    $self->SUPER::start_element({Name=>"geo"});
    $self->_pcdata({name=>"lat",value=>$vcard->{'geo'}{'lat'}});
    $self->_pcdata({name=>"lon",value=>$vcard->{'geo'}{'lon'}});
    $self->SUPER::end_element({Name=>"geo"});
  }

  # TITLE:
  if (exists($vcard->{'title'})) {
    $self->_pcdata({name=>"title",value=>$vcard->{'title'}});
  }

  # ROLE
  if (exists($vcard->{'role'})) {
    $self->_pcdata({name=>"role",value=>$vcard->{'role'}});
  }

  # LOGO:
  if (exists($vcard->{'logo'})) {
    $self->_media({name=>"logo",%{$vcard->{'logo'}}});
  }

  # AGENT:
  if (exists($vcard->{agent})) {
    $self->SUPER::start_element({Name=>"agent"});

    if ($vcard->{agent}{uri}) {
      $self->_pcdata({name=>"extref",attrs=>{"{}uri"=>{Name=>"uri",
						       Value=>$vcard->{'agent'}{'uri'}}}
		     });
    }

    else {
      $self->_parse_str($vcard->{agent}{vcard});
    }

    $self->SUPER::end_element({Name=>"agent"});
  }

  # ORG:
  if (exists($vcard->{'org'})) {
    $self->SUPER::start_element({Name=>"org"});
    $self->_pcdata({name=>"orgnam",value=>$vcard->{'org'}{'name'}});
    $self->_pcdata({name=>"orgunit",value=>$vcard->{'org'}{'unit'}});
    $self->SUPER::end_element({Name=>"org"});
  }

  # CATEGORIES:
  if (ref($vcard->{'categories'}) eq "ARRAY") {
    $self->SUPER::start_element({Name=>"categories"});
    foreach (@{$vcard->{categories}}) {
      $self->_pcdata({name=>"item",value=>$_});
    }
    $self->SUPER::end_element({Name=>"categories"});
  }

  # NOTE:
  if (exists($vcard->{'note'})) {
    $self->_pcdata({name=>"note",value=>$vcard->{'note'}});
  }

  # SORT:
  if (exists($vcard->{'sort'})) {
    $self->_pcdata({name=>"sort",value=>$vcard->{'sort'}});
  }

  # SOUND:
  if (exists($vcard->{'sound'})) {
    $self->_media({name=>"sound",%{$vcard->{'sound'}}});
  }

  # URL:
  if (ref($vcard->{'url'}) eq "ARRAY") {
    foreach (@{$vcard->{'url'}}) {
      $self->_pcdata({name=>"url",
		      Attributes=>{"{}uri"=>{Name=>"uri",Value=>$_}}});
    }
  }

  # KEY:
  if (exists($vcard->{'key'})) {
    $self->_media($vcard->{key});
  }

  # $self->xcustom();

  $self->SUPER::end_element({Name=>"vCard"});

  return 1;
}

sub _pcdata {
  my $self = shift;
  my $data = shift;
  $self->SUPER::start_element({Name=>$data->{name},Attributes=>$data->{attrs}});
  $self->SUPER::start_cdata() if ($data->{cdata});
  $self->SUPER::characters({Data=>$data->{value}});
  $self->SUPER::end_cdata() if ($data->{cdata});
  $self->SUPER::end_element({Name=>$data->{name}});
  return 1;
}

sub _media {
  my $self = shift;
  my $data = shift;

  my $attrs = {};

  # as in not 'key' and not something pointing to an 'uri'
  if ((! $data->{name} =~ /^k/) && ($data->{type})) {

    # as in 'photo' or 'logo' and not 'sound'
    my $mime = ($data->{name} =~ /^[pl]/i) ? "img" : "aud";
    $attrs = {"{}$mime.type"=>{Name=>"$mime.type",Value=>$data->{type}}};
  }

  $self->SUPER::start_element({Name=>$data->{name},Attributes=>$attrs});

  if ($data->{url}) {
     $self->_pcdata({name=>"extref",attrs=>{"{}uri"=>{Name=>"uri",
						      Value=>$data->{url}}}
		    });
  }

  else {
    $self->_pcdata({name=>"b64bin",value=>$data->{b64},cdata=>1});
  }

  $self->SUPER::end_element({Name=>$data->{name}});
  return 1;
}

# Convert all type data into a value list

sub _munge_type {
  my $sr_str = shift;
  $$sr_str || return;

  # Remove the leading TYPE=
  # declaration: see also $regexp_type
  $$sr_str =~ s/^TYPE=//i;

  # Remove any subsequent TYPE=
  # thingies and replace them
  # with commas
  $$sr_str =~ s/;TYPE=/,/gi;
}

sub DESTROY {}

=head1 VERSION

0.05

=head1 DATE

February 18, 2003

=head1 AUTHOR

Aaron Straup Cope

=head1 NOTES

=head2 What about representing vCard objects in RDF/XML?

It's not going to happen here.

I might write a pair of vcard-rdfxml <-> vcard-xml filters in the
future. If you're chomping at the bit to do this yourself, please,
go nuts.

=head1 TO DO

=over 4

=item *

Better (proper) support for properties that span multiple lines. See also:

 section 5.8.1.  Line delimiting and folding (RFC 2425)
 section 2.6     Line Delimiting and Folding (RFC 2426)

I<This is planned for version 0.06>

=item *

Wrap lines at 75 chars for media thingies.

I<This is planned for version 0.06>

=item *

Better checks to prevent empty elements from being include in final
output.

=item *

Add support for I<LABEL> property

=item *

Add support for I<X-CUSTOM> properties. These are not actually defined 
in the vcard-xml DTD :-(

=item *

Add support for pronounciation attribute extension

=back

=head1 SEE ALSO

http://www.ietf.org/rfc/rfc2426.txt

http://www.ietf.org/rfc/rfc2425.txt

http://www.globecom.net/ietf/draft/draft-dawson-vcard-xml-dtd-03.html

http://www.imc.org/pdi/vcard-pronunciation.html

http://www.w3.org/TR/vcard-rdf

=head1 BUGS

Sadly, there are probably a few.

Please report all bugs via http://rt.cpan.org

=head1 LICENSE

Copyright (c) 2002-2003, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

