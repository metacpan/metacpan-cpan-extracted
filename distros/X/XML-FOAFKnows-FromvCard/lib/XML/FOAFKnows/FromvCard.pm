package XML::FOAFKnows::FromvCard;

use 5.007;
use strict;
use warnings;
use Carp;

use Text::vCard::Addressbook;
use Text::vCard;
use Digest::SHA1 qw(sha1_hex);
use IDNA::Punycode;

use base qw( Text::vCard );

our $VERSION = '0.6';

sub format {
  my $that  = shift;
  my $class = ref($that) || $that;
  my ($text,%config) = @_;
  my $address_book = Text::vCard::Addressbook->new({
      'source_text' => $text,
  });

  my $privstatattrib = $config{attribute} || 'CLASS';
  # Parse and build the fragment
  my $records = '';
  my @urls = ();
  my $counts = 0;
  foreach my $vcard ($address_book->vcards()) {
    my $privacystat = 'PRIVATE'; # The default privacy option if nothing else is set
    if (defined($config{privacy})) {
      $privacystat = uc($config{privacy});
    } elsif (($vcard->get($privstatattrib))[0]) {
      $privacystat = ($vcard->get($privstatattrib))[0]->value; # Check the status and generate full records only for public records
    }
    next if ($privacystat eq 'CONFIDENTIAL');
    my @email = ($vcard->get('EMAIL'));
    my $url = ($vcard->get('URL'))[0];
    next unless ($url || $email[0]); # We need at least an URL or an email to continue
    $counts++;
    $records .= "<foaf:knows>\n\t<foaf:Person";
    # TODO: nodeIDs, but how to generate...?
    if (($vcard->get('NICKNAME'))[0]) { # a nodeID on the Person record can be useful
      my $punynick = encode_punycode(($vcard->get('NICKNAME'))[0]->value); # puny-encode any nicks,
      $punynick =~ s/\s/_/gs; # and replace any whitespace with underscores
      $records .= ' rdf:nodeID="' . $punynick . '">'.
	"\n\t\t<foaf:nick>" . ($vcard->get('NICKNAME'))[0]->value . '</foaf:nick>';
    } else {
      $records .= ' rdf:nodeID="person'.$counts.'">';
    }

    foreach (@email) {
      next unless (defined($_));
      $records .= "\n\t\t<foaf:mbox_sha1sum>" . sha1_hex('mailto:' . $_->value) . '</foaf:mbox_sha1sum>';
    }
    if ($url) {
      my $tmp = $url->value;
      $tmp =~ s/\\:/:/g; # Some files seem to have colons in URLs escaped
      $records .= "\n\t\t".'<foaf:homepage rdf:resource="'.$tmp.'"/>';
    }
    my $fullname = '';
    if ($privacystat eq 'PUBLIC') {
      my $name = ($vcard->get('N'))[0];
      if ($name) {
	$records .= "\n\t\t<foaf:family_name>".$name->family.'</foaf:family_name>';
	$fullname = $name->family;
	if ($name->given()) {
	  $records .= "\n\t\t<foaf:givenname>".$name->given.'</foaf:givenname>'.
	    "\n\t\t<foaf:name>".$name->given.' '.$name->family.'</foaf:name>';
	  $fullname = $name->given.' '.$name->family;
	}
      }
      elsif (($vcard->get('FN'))[0]->fullname()) {
	$records .= "\n\t\t<foaf:name>".($vcard->get('FN'))[0]->fullname.'</foaf:name>';
	$fullname = ($vcard->get('FN'))[0]->fullname;
      }
    }
    # Now we build the URL to be returned by the links method
    if ($vcard->get('URL')) {
      foreach my $url2 ($vcard->get('URL')) {
	my $tmp = $url2->value;
	$tmp =~ s/\\:/:/g;
	push(@urls, {url => $tmp, title => $fullname});
      }
    }
    $records .= "\n\t</foaf:Person>\n</foaf:knows>\n";
  }

  my $self = {
	      _out => $records,
	      _urls => \@urls,
	      _config => \%config,
	     };
  bless($self, $class);
  return $self;
}


sub title { return undef }

sub links { return shift->{_urls}; }

sub fragment { return shift->{_out}; }

sub document { 
  my ($self,$encoding) = @_;

  my $out = '<?xml version="1.0"';
  if ($encoding) {
    $out .= ' encoding="'.$encoding.'"';
  }
  $out .= '?>';
  $out .= "\n<rdf:RDF\n".
   'xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" '.
   'xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" '.
   'xmlns:foaf="http://xmlns.com/foaf/0.1/">'.
   "\n<foaf:Person";

  if ($self->{_config}->{uri}) {
    $out .= ' rdf:about="'.$self->{_config}->{uri}.'">';
  } else {
    $out .= ">\n\n";
  }
  if ($self->{_config}->{email}) {
    $out .= "\n\t<foaf:mbox_sha1sum>" . sha1_hex('mailto:' . $self->{_config}->{email}) . '</foaf:mbox_sha1sum>';
  }
  if ($self->{_config}->{seeAlso}) {
    $out .= "\n\t".'<rdfs:seeAlso rdf:resource="'.$self->{_config}->{seeAlso}.'"/>'."\n\n";
  }
  return $out . $self->{_out} . "\n</foaf:Person>\n</rdf:RDF>\n";
}




1;
__END__

=head1 NAME

XML::FOAFKnows::FromvCard - Perl module to create simple foaf:knows records from vCards

=head1 SYNOPSIS

  use XML::FOAFKnows::FromvCard;
  # read a vCard file into $data
  my $formatter = XML::FOAFKnows::FromvCard->format($data);
  print $formatter->fragment;

The C<foafvcard> script in the distribution is also a good and more
elaborate usage example.


=head1 DESCRIPTION

This module takes a vCard string parses it using L<Text::vCard> and
attempts to make C<foaf:knows> records from it. It's scope is limited
to that, it is not intended to be a full vCard to RDF conversion
module, it just wants to make reasonable knows records of your
contacts.


=head1 METHODS

This module conforms with the L<Formatter> API specification, version
0.95. It is not in the Formatter namespace, however, because it
doesn't what Formatters generally do, namely reformat all data from
one format to another. Since it does conform, it can be used in most
of the same contexts as a formatter.

=over

=item C<format($string, [(seeAlso => $seeAlsoUri, uri => $myUri, email => $myEmail, attribute => 'CLASS', privacy => 'PRIVATE|PUBLIC') )>

The format function that you call to initialise the converter. It
takes the plain text as a string argument and returns an object of
this class. In the present implementation, it does pretty much all the
parsing and building of the output, so this is the only really
expensive call of this module.

In addition to the string, it can take a hash containing C<seeAlso>,
C<uri> and C<email> keys. If you want to build a full document, you
might want to specify C<seeAlso> to an URL to the rest of your FOAF
and you should specify one of C<uri> or C<email> to identify you as a
person. The former should be your canonical URI, the latter the email
address you want to use to identify yourself.

C<privacy> and C<attribute> are privacy options, and they can
optionally be set to indicate what level of details should be included
in the output. See the discussion in L</"Privacy Settings"> for further
details.

You should ensure that the data passed is UTF-8, and has the UTF-8
flag set, as invalid RDF C<nodeID>s may result if you don't.

=item C<document([$charset])>

This will return a full RDF document. The FOAF knows records will be
wrapped in a Person element, which has to represent you somehow, see
above.

=item C<fragment>

This will return the FOAF knows records.

=item C<links>

Will return all links found the input plain text string as an
arrayref. The arrayref will for each element contain keys url and
title, the former containing the URL, the latter the full name of the
person if it exists.

=item C<title>

Is meaningless for vCards, so will return C<undef>.

=back

=head2 Privacy Settings

By default, this module is conservative in what it outputs. FOAF is a
very powerful and will give us many interesting applications when we
compile data about people. However, people may also feel that their
privacy is compromised by having even their name so readily
available. You will have to be concerned about the privacy of your
friends.

vCards commonly contain an attribute that indicate a privacy level of
the vCard. The name of this attribute can be set using the
C<attribute> parameter to C<format> and defaults to C<CLASS>.

If this attribute contains a "CONFIDENTIAL" value, this module will
write nothing, and unless a there is a "PUBLIC" class, it will only
output the SHA1-hashed mailbox, a nick if it exists and a homepage if
it exists.

You may also set a C<privacy> parameter to C<format>. If set, it will
override the above attribute for all vCards in the input. It may be
set to C<PRIVATE> or C<PUBLIC>. In the first case, it will make sure
only the above minimal information is included, in the latter, it will
include many more properties (not defined, as it may change).

If neither the privacy C<attribute> can be found, nor the C<privacy>
parameter, it will default to C<PRIVATE>.

Finally, note that even though we are hashing the e-mail addresses,
they are not impossible to crack. It is, for many purposes, not
infeasible to recover the plaintext e-mail addresses by a dictionary
attack, i.e. combine common ISP domains with common names, and compare
them with the hash. Hashing is therefore not a 100% guarantee that
your friend's cleartext addresses will remain a secret if a determined
attacker seeks them.


=head1 BUGS/TODO

This is presently a beta release. It should do most things OK, but
it has only been tested on vCards from three different sources.

Also, it is problematic to produce a full FOAF document, since the
vCard has no concept at all of who knows all these folks. I have tried
to approach this by allowing the URI of the person to be entered, but
I don't know if this is workable.

Feedback is very much appreciated. One may also report bugs at
https://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-FOAFKnows-FromvCard


=head1 SEE ALSO

L<Text::vCard>, L<Formatter>, http://www.foaf-project.org/

=head1 SUBVERSION REPOSITORY

This module is currently maintained in a Subversion repository. The
trunk can be checked out anonymously using e.g.:

  svn checkout http://svn.kjernsmo.net/XML-FOAFKnows-FromvCard/trunk/ FOAFKnows


=head1 AUTHOR

Kjetil Kjernsmo, E<lt>kjetilk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kjetil Kjernsmo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
