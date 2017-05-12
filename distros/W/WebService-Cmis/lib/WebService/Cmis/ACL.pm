package WebService::Cmis::ACL;

=head1 NAME

WebService::Cmis::ACL

Representation of a cmis ACL object

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use strict;
use warnings;
use WebService::Cmis qw(:namespaces);
use WebService::Cmis::ACE ();
use XML::LibXML qw(:libxml);
use Error qw(:try);

=head1 METHODS

=over 4

=item new(%params)

=cut

sub new {
  my $class = shift;

  my $this = bless({ @_ }, $class);

  if (defined $this->{xmlDoc}) {
    $this->{entries} = $this->_getEntriesFromXml();
  }
  $this->{entries} = [] unless defined $this->{entries};
  
  return $this;
}

sub DESTROY {
  my $this = shift;

  undef $this->{xmlDoc};
  undef $this->{entries};
}

=item toString()

return a string representation of this object

=cut

sub toString {
  my $this = shift;

  my @result = ();
  foreach my $ace ($this->getEntries) {
    push @result, $ace->toString;
  }

  return join("; ", @result);
}

=item getSize() -> $number

returns the number of ACE objects part of this list

=cut

sub getSize {
  my $this = shift;

  return scalar(@{$this->{entries}});
}

=item addEntry($ace) -> L<WebService::Cmis::ACL>

adds an ACE entry to the ACL. returns $this object.

=cut

sub addEntry {
  my ($this, $ace) = @_;

  push @{$this->{entries}}, $ace;

  return $this;
}

=item removeEntry($idOrAce) -> L<WebService::Cmis::ACL>

removes all specified entries. C<$idOrAce> can either be a principalId or an
ACE object. In the first case all ACEs for the principalId will be removed.
When an ACE object is specified, all equivalent ACEs in the ACL will be
removed. returns $this object.

=cut

sub removeEntry {
  my ($this, $idOrAce) = @_;

  return unless $this->{entries};
  
  my @newEntries = ();

  if (ref($idOrAce)) {
    my $testAce = $idOrAce;
    my $testAceString = $testAce->toString;

    foreach my $ace (@{$this->{entries}}) {
      push @newEntries, $ace unless $ace->toString eq $testAceString;
    }

  } else {
    my $principalId = $idOrAce;

    foreach my $ace (@{$this->{entries}}) {
      push @newEntries, $ace unless $ace->{principalId} eq $principalId;
    }
  }

  $this->{entries} = \@newEntries;

  return $this;
}

=item getEntries -> @aces

returns a list of ACE objects for each access control
entry in the ACL. 

=cut

sub getEntries {
  my $this = shift;

  unless (defined $this->{entries}) {
    $this->{entries} = $this->_getEntriesFromXml();
  }

  return @{$this->{entries}};
}

# private helper to for getting all ACEs for the XML representation of this ACL
sub _getEntriesFromXml {
  my $this = shift;

  throw Error::Simple("no xmldoc for ACL object") unless defined $this->{xmlDoc};

  my $xcp = XML::LibXML::XPathContext->new($this->{xmlDoc});
  $xcp->registerNs('cmis', CMIS_NS);

  my @result = ();
  my $permNodes = $xcp->find("cmis:acl/cmis:permission");

  foreach my $node ($permNodes->get_nodelist) {
    #print STDERR "node=".$node->toString(2)."\n";

    my $principalId = $xcp->findvalue('./cmis:principal/cmis:principalId', $node);
    my $direct = $xcp->findvalue('./cmis:direct', $node);
    my @perms = map {$_->textContent()} $xcp->findnodes('./cmis:permission', $node);
    next unless @perms;

    #print STDERR "principalId=$principalId, direct=$direct, perms='".join(', ', @perms)."'\n";

    # create an ACE
    push @result, new WebService::Cmis::ACE(
      principalId => $principalId, 
      permissions => \@perms, 
      direct => $direct
    );
  }

  return \@result;
}

=item getXmlDoc -> $xmlDoc

This method rebuilds the local XML representation of the ACL based on
the ACE objects in the entries list and returns the resulting
XML Document.

=cut

sub getXmlDoc {
  my $this = shift;

  return unless defined $this->{entries} && $this->getSize;

  my $xmlDoc = new XML::LibXML::Document('1.0', 'UTF-8');
  my $aclNode = $xmlDoc->createElementNS(CMIS_NS, 'acl');
  $xmlDoc->setDocumentElement($aclNode);

  foreach my $ace ($this->getEntries) {
    my $permNode = $xmlDoc->createElement('permission');

    # principalId
    $permNode->addNewChild(CMIS_NS, 'principal')
      ->appendTextChild('principalId', $ace->{principalId});

    # direct
    $permNode->appendTextChild('direct', $ace->{direct});

    # permissions
    foreach my $perm (@{$ace->{permissions}}) {
      next unless $perm;
      $permNode->appendTextChild('permission', $perm);
    }

    $aclNode->appendChild($permNode);
  }
  
  return $this->{xmlDoc} = $xmlDoc;
}

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 Michael Daum

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.  See F<http://dev.perl.org/licenses/artistic.html>.

=cut

1;
