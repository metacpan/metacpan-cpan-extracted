package XML::Debian::ENetInterfaces;

use warnings;
use strict;
require 5.10.0;

=head1 NAME

XML::Debian::ENetInterfaces - Work with Debian's /etc/network/interfaces in XML.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

use feature 'switch';
#use Data::Dumper;
use XML::LibXML;
use XML::Parser::PerlSAX;
use Fcntl qw(O_RDONLY O_WRONLY O_CREAT O_APPEND :flock);
use Carp;

sub read();
sub write;
sub lock;
sub relock;
sub unlock();
my @locked;
my $S;
my $dom;

=head1 SYNOPSIS

Import/Export Debian /etc/network/interfaces from/to XML.

    use XML::Debian::ENetInterfaces;
    XML::Debian::ENetInterfaces::lock(); # Optionally takes a Fcntl/flock
	# constant like LOCK_SH
    my $xmlstr = XML::Debian::ENetInterfaces::read();
    XML::Debian::ENetInterfaces::write('XML String'||
	IO::Handle->new('file','r'));
    XML::Debian::ENetInterfaces::unlock();

=head1 SUBROUTINES/METHODS

=head2 new

Just returns an object.

=cut

sub new {
  my ($class) = @_;
  return bless {}, $class;
}

=head2 lock

By default, no arguments, creates an exclusive semaphoric lock on at least the two files written to by this application.  Can be used to create a shared semaphoric lock, like so:

    use Fcntl qw(:flock);
    XML::Debian::ENetInterfaces::lock(LOCK_SH);
    
=cut

sub lock {
  my ($lvl)=@_;
  $lvl||=LOCK_EX;
  relock($lvl) if ( @locked );
  my $file=$ENV{INTERFACES}||'/etc/network/interfaces';
  my $SEMAPHORE=$file.'.lck';
  sysopen($S,$SEMAPHORE,
    ($lvl==LOCK_SH?O_RDONLY:O_WRONLY)|O_CREAT|O_APPEND) or
    die "$SEMAPHORE: $!";
  flock($S,$lvl) or die "flock() failed for $SEMAPHORE: $!";
  @locked=($file,$lvl);
}

=head2 relock

Used internally to detect in proper Round Trip locking.  May also be useful to you.  Takes the same arguments as lock above.

=cut

sub relock {
  carp "Re-locking, sounds like an issue with Round Trip.";
  my ($lvl)=@_;
  $lvl||=LOCK_EX;
  my $file = $ENV{INTERFACES}||'/etc/network/interfaces';
  carp "Re-locking wrong file: $file" unless ( $file eq $locked[0] );
  croak "Semaphore not open." unless (defined $S);
  flock($S, $lvl) or die "flock() failed for $file.lck: $!";
  $locked[1] = $lvl;
}

=head2 unlock

Close the existing lock.

=cut

sub unlock() {
  my $file = $ENV{INTERFACES}||'/etc/network/interfaces';
  carp "Unlocking wrong file: $file" unless ( $file eq $locked[0] );
  croak "Semaphore not open." unless (defined $S);
  close $S;
  $S=undef;
  @locked=();
}

sub __identattr
{
  my ($attr, $str)= @_;
  $attr = $dom->createAttribute($attr); # Scary.
  while ($str =~ m/(.)/g) {
    given ($1){
      when (" ") { $attr->appendChild($dom->createEntityReference('#32')); }
      when ("\t") { $attr->appendChild($dom->createEntityReference('#9')); }
      default { warn $1; $attr->appendChild($dom->createTextNode($1)); }
    }
  }
  return $attr;
}

=head2 read

Takes no arguments and returns a string containing XML.

=cut

sub read() {
  my $RootName='etc_network_interfaces';
  # NOTE: The example file uses 8 space indents, the DTD specifies
  #       4 spaces as the default.
  # This cheat is used because DTD creation is not yet implemented.
  $dom = XML::LibXML->load_xml(string => <<END."<$RootName/>");
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE $RootName [
  <!ELEMENT $RootName	(COMMENT|auto|iface|mapping|br)*>
  <!ELEMENT COMMENT	(#PCDATA)>
  <!ELEMENT auto	(#PCDATA)>
  <!ATTLIST auto
	_indent CDATA   ""
	_alias CDATA   #IMPLIED
  >
  <!ELEMENT iface	(up|down|pre-up|post-down|br|COMMENT)*>
  <!ATTLIST iface
	name CDATA   #REQUIRED
	opts CDATA   #REQUIRED
	_indent CDATA   ""
	_childindent CDATA   "&#32;&#32;&#32;&#32;"
	_alias CDATA   #IMPLIED
	address CDATA #IMPLIED
	network CDATA #IMPLIED
	broadcast CDATA #IMPLIED
	gateway CDATA #IMPLIED
	dns-nameservers CDATA #IMPLIED
	netmask CDATA #IMPLIED
	ttl CDATA #IMPLIED
	local CDATA #IMPLIED
	remote CDATA #IMPLIED
	mtu CDATA #IMPLIED
	endpoint CDATA #IMPLIED
  >
  <!ELEMENT mapping	(map|br|COMMENT)*>
  <!ATTLIST mapping
	name CDATA   #REQUIRED
	opts CDATA   #REQUIRED
	script CDATA   #REQUIRED
	_indent CDATA   ""
	_alias CDATA   #IMPLIED
	_childindent CDATA   "&#32;&#32;&#32;&#32;"
  >
  <!ELEMENT map		(#PCDATA)>
  <!ATTLIST map
	_indent CDATA   "&#32;&#32;&#32;&#32;"
  >
  <!ELEMENT up		(#PCDATA)>
  <!ATTLIST up
	_indent CDATA   "&#32;&#32;&#32;&#32;"
	_alias CDATA   #IMPLIED
  >
  <!ELEMENT pre-up	(#PCDATA)>
  <!ATTLIST pre-up
	_indent CDATA   "&#32;&#32;&#32;&#32;"
  >
  <!ELEMENT down	(#PCDATA)>
  <!ATTLIST down
	_indent CDATA   "&#32;&#32;&#32;&#32;"
	_alias CDATA   #IMPLIED
  >
  <!ELEMENT post-down	(#PCDATA)>
  <!ATTLIST post-down
	_indent CDATA   "&#32;&#32;&#32;&#32;"
  >
  <!ELEMENT br		EMPTY>
]>
END

  my $root = $dom->documentElement();

  # Any lock will do.
  my $waslocked = @locked;
  lock(LOCK_SH) unless ($waslocked);
  my $file = $ENV{INTERFACES}||'/etc/network/interfaces';
  open (my $INTER, '<', $file) or croak "Can't read $file: $!";

  my $domptr;
  LINE: while (my $ln=<$INTER>) {
    chomp $ln;
    # A line may be extended across multiple lines by making the
    # last character a backslash.
    while ($ln =~ /\\$/) {
      # Removes/joins extended lines.
      # TODO: Fix case where result has no whitespace.
      chop $ln; chomp($ln.=<$INTER>); last if (eof $INTER);
    }
    # warn $ln;
    # White space around comments is written out.
    if ($ln =~ /^\s*#/ ) {
      my $element = $dom->createElement('COMMENT');
      $element->appendChild($dom->createTextNode($ln));
      if (defined $domptr) {
	$domptr->appendChild($element);
      } else {
	$root->appendChild($element);
      }
      next LINE;
    }
    # Removes white space on blank lines.
    if ($ln eq '' or $ln =~ /^\s*$/) {
      if (defined $domptr) {
	$domptr->appendChild($dom->createElement('br'));
      } else {
	$root->appendChild($dom->createElement('br'));
      }
      next LINE;
    }
    # This loop could be done within the regex,
    # though I originally wrote it this way...  no particular reason.
    foreach my $rx (qr(auto),qr(allow-auto),qr(allow-[^ ]*),
	qr(mapping),qr(iface)) {
      if ($ln =~ /^(\s*)($rx)\s+(\S*)\s*(.*)$/) {
	my ($ind,$ele,$nam,$opt) = ($1,$2,$3,$4);
	$domptr = undef;
	my $element = $dom->createElement($ele);
	given ($ele){
	  when('mapping') {
	    $element->addChild($dom->createAttribute('name', $nam));
	    $element->addChild($dom->createAttribute('opts', $opt));
	    $element->addChild(__identattr('_indent',$ind));
	    $domptr = $element;
	  }
	  when('iface') {
	    $element->addChild($dom->createAttribute('name', $nam));
	    $element->addChild($dom->createAttribute('opts', $opt));
	    $element->addChild(__identattr('_indent',$ind));
	    $domptr = $element;
	  }
	  when('allow-auto') {
	    $element = $dom->createElement('auto');
	    $element->addChild(__identattr('_alias',$ele));
	    $element->addChild(__identattr('_indent',$ind));
	    $element->appendChild($dom->createTextNode(join ' ', grep /./, $nam, $opt));
	  }
	  default {
	    $element->addChild(__identattr('_indent',$ind));
	    $element->appendChild($dom->createTextNode(join ' ', grep /./, $nam, $opt));
	  }
	}
	$root->appendChild($element);
	next LINE;
      }
    }
    if ($ln =~ /^(\s*)(\S*)\s(.*)$/) {
      my ($ind,$ele,$dat) = ($1,$2,$3);
      if (defined $domptr) {
	given ($ele){
	  when(['post-up', 'pre-down']) {
	    carp unless ($domptr->tagName eq 'iface');
	    my $aele = $ele;
	    $aele=~s/^.*(up|down)/$1/;
	    my $element = $dom->createElement($aele);
	    $element->addChild(__identattr('_alias',$ele));
	    $element->addChild(__identattr('_indent',$ind));
	    $element->appendChild($dom->createTextNode($dat));
	    $domptr->appendChild($element);
	  }
	  when('map') {
	    carp unless ($domptr->tagName eq 'mapping');
	    my $element = $dom->createElement($ele);
	    $element->addChild(__identattr('_indent',$ind));
	    $element->appendChild($dom->createTextNode($dat));
	    $domptr->appendChild($element);
	  }
	  when(['up','down','pre-up','post-down']) {
	    carp unless ($domptr->tagName eq 'iface');
	    my $element = $dom->createElement($ele);
	    $element->addChild(__identattr('_indent',$ind));
	    $element->appendChild($dom->createTextNode($dat));
	    $domptr->appendChild($element);
	  }
	  default {
	    $domptr->addChild(__identattr('_childindent',$ind))
	      unless (defined $domptr->getAttributeNode('_childindent') );
	    $domptr->addChild($dom->createAttribute($ele,$dat));
	  }
	}
	next LINE;
      }
      warn $ln;
      next LINE;
    }
    warn $ln;
  }
  close $INTER;
# Should not hurt and is useful for Round Trip detection.
#  unlock() unless ($waslocked);

  my $out = $dom->toString(1);
  $dom=undef;
  return $out;
}

=head2 write

Takes either a string or a file handle, per IO::Handle understanding of what a file handle is, and passes this to XML::Parser::PerlSAX as a string.  Current versions of XML::Parser::PerlSAX treat this identically to an IO::Handle, though I guess one couldn't count on that continually being the case.

Passed to XML-Parser-2.41(XML::Parser->parse($parse_options->{Source}{String})), libxml-perl-0.08(XML::Parser::PerlSAX->new({Source=>{String=>$_[0]}}))'s back-end.

=cut

sub write {
  my ($inp) = @_;
  # Make sure the lock is exclusive.
  my $waslocked = (@locked and $locked[1]||-1==LOCK_EX);
  lock(LOCK_EX) unless ($waslocked);
  my $file = $ENV{INTERFACES}||'/etc/network/interfaces';
  open (my $INTER, '>', "$file.tmp") or die "Can't write $file.tmp: $!";
  my $handler = XML::Debian::ENetInterfaces::Handler->new($INTER);
  my $parser = XML::Parser::PerlSAX->new(
    Handler=>$handler,
    UseAttributeOrder=>1,
    Source=>{String=>$inp}
  );
  $parser->parse();

  close $INTER;
  rename("$file.tmp", $file);
  unlock() unless ($waslocked);

}

1;
package XML::Debian::ENetInterfaces::Handler;
use warnings;
use strict;
require 5.10.0;
use feature 'switch';
#use Data::Dumper;

sub new {
  my ($class,$outp) = @_;
  return bless {INTER=>$outp}, $class;
}

my $last_element;
my $last_alias;
my $childindent;
my $indent;
sub start_element {
  my ($self, $element) = @_;
  my $fh = $self->{INTER};
  $last_element=$element->{Name};
  $last_alias=$element->{Attributes}->{_alias}||$last_element;
  given ($last_element){
    when(undef) { warn; }
    when('br') { print $fh "\n"; }
    when(['iface','mapping']) {
      print $fh join(' ', grep /./, 
	"$element->{Attributes}->{_indent}$last_alias",
	$element->{Attributes}->{name},
	$element->{Attributes}->{opts}),"\n";
      $childindent=$element->{Attributes}->{'_childindent'};
      delete $element->{Attributes}->{name};
      delete $element->{Attributes}->{opts};
      delete $element->{Attributes}->{_alias};
      delete $element->{Attributes}->{_indent};
      delete $element->{Attributes}->{_childindent};
      for (@{$element->{AttributeOrder}}) {
	my $tmp = $_;
	print $fh "$childindent$tmp $element->{Attributes}->{$tmp}\n"
	  unless ($tmp =~ /^_/ or !defined $element->{Attributes}->{$tmp});
      }
    }
    default { $indent=$element->{Attributes}->{'_indent'}; }
  }
}

sub end_element {
  my ($self, $element) = @_;
  given ($last_element||'nomatch'){
    when(['iface','mapping']) {
      $childindent=undef;
      continue;
    }
    when($element->{Name}) {
      $last_element=undef;
      $last_alias=undef;
      $indent=undef;
    }
  }
}

sub characters {
  my ($self, $characters) = @_;
  my $fh = $self->{INTER};
#  warn Dumper(\$characters);
  my $hack='__NEVERMATCH';
  given ($last_element){
    when(undef) {}
    when(['etc_network_interfaces','iface','mapping']) {}
    when('COMMENT') { print $fh "$characters->{Data}\n"; }
    when(/allow-[^ ]*/) { $hack=$last_element; continue; }
    when(['up','down','post-up','pre-down','auto',$hack]) {
      print $fh "$indent$last_alias $characters->{Data}\n"; }
    default { print $fh "$indent$last_alias $characters->{Data}\n"; }
  }
}

1;
__END__

=head1 EXAMPLE

  #!perl
  use XML::Debian::ENetInterfaces;
  if ($writing) {
    $ENV{INTERFACES} = $outputfile;
    XML::Debian::ENetInterfaces::lock();
  }
  $ENV{INTERFACES} = $inputfile;
  my $xmlstr = XML::Debian::ENetInterfaces::read();
  # Cool XML reading/mangling code here.

  # Only if writing code run above should you call write after a read.
  $ENV{INTERFACES} = $outputfile;
  XML::Debian::ENetInterfaces::write(SOURCE);

The SOURCE parameter should either be a string containing the whole XML document, or it should be an open IO::Handle.

=head1 XML

The XML produced/expected is of a schema developed and designed by me specifically for this purpose.  IT MAY CHANGE in the future, though I wouldn't expect any changes to be significant if not drastic.

Comments on the schema are most welcome, I'd rather make changes sooner then later.

=head1 LOCKING

Locking in some cases is automatic, however in the Round Trip case (read/modify/write) that I needed when I wrote this and therefore might be the most common use of this module, the locking is not automatic.  See usage for help and see Round Trip for an explanation.

Only does advisory locks on a semaphore file.  This lock is intended to protect the interfaces file and the temporary file used on writes.  A temp file is used to avoid problems where ifup/down might try and read the file while it's being written out, remember these locks do nothing to prevent ifup/down or any other program from accessing/changing the interfaces file directly.  You must ensure that, other then the ifup/down applications, any other user of the interfaces file makes use of the semaphore used by this module, you can use this modules API or duplicate the concept in your own way.


=head1 ROUND TRIP

For this module this has two distinct meanings.  Firstly it's a goal of this module to round trip with no change to the file, in most cases the file will be identical(have the same md5/sha1) as the original.  The inode number is changed as a result of using a temporary file.

The second meaning is read/modify/write.  In this case the contents will not be identical.  You should make sure to lock the interfaces file exclusivity(just call this module's lock function with no parameters) prior to the read, this is because there is a race condition during changing the lock type where another writer can get over written.

=head1 XML::Debian::ENetInterfaces::Handler

Document this?  meh, it's a lot of complicated code for taking XML and turning it into a file that represents the idea expressed in the XML as a /etc/network/interfaces file.

...In other words if you have to ask you can read it for yourself, other wise leave this alone.

=head1 AUTHOR

Michael Mestnik, C<< <cheako+cpan at mikemestnik.net> >>

=head1 BUGS

I had put together a short list of these in my head, but I believe I've corrected most of them ;)

One note is that the source code remarks several locations where white-space could be altered during a round trip.  Most notably the "non-repeating" child options share a single indentation whitespace, the first non-repeating child's indentation is authoritative.

The DTD is not complete with regard to add-on modules, like wireless, bridges, ect.  I'm unsure of how modular a DTD can be, but I suspect the best way is for each add-on extend the DTD on there own...  However I will take additions to the module included DTD for most if not all the add-on modules that submit to me there DTD.

Please report any bugs or feature requests to C<bug-xml-debian-enetinterfaces at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Debian-ENetInterfaces>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Debian::ENetInterfaces


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Debian-ENetInterfaces>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Debian-ENetInterfaces>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Debian-ENetInterfaces>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Debian-ENetInterfaces/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Michael Mestnik.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of XML::Debian::ENetInterfaces
