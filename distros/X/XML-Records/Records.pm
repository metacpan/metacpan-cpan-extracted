package XML::Records;
use strict;
use vars qw($VERSION);
$VERSION = '0.12';

use base 'XML::TokeParser';

sub new {
  my $class=shift;
  $class=ref $class || $class;
  my $self=$class->SUPER::new(@_);
  $self->{rectypes}=[{}];
  bless $self,$class;
}

sub set_records {
  my $self=shift;
  $self->{rectypes}[-1]={map {$_=>1} @_};
}

sub get_record {
  my $self=shift;
  my ($rec,$rectype);
  if ($self->skip_to(@_)) {
    my $token=$self->get_token();
    $rectype=$token->[1];
    my $t=$self->{noempty};
    $self->{noempty}=1;
    $rec=$self->get_hash($token);
    $self->{noempty}=$t;
  }
  ($rectype,$rec);
}

sub get_hash {
  my ($self,$token)=@_;
  my ($field,$buf,$field_token);
  my $rectype=$token->[1];
  my $nest=0;
  my $h={};
  # treat attributes of record or subrecord as fields
  foreach (keys %{$token->[2]}) {
    $h->{$_}=$token->[2]{$_};
  }
  while ($token=$self->get_token()) {
    my $t=$token->[0];
    if ($t eq 'S') {
      if ($self->{rectypes}[-1]{"-$token->[1]"}) { # record ended by start
        $self->unget_token($token);
        last;
      }
      if ($nest++) { # start tag inside field, get subrecord
        $self->unget_token($token);
        add_hash($h,$field,$self->get_hash($field_token));
        $nest-=2; # we won't see sub-field's or field's end tag
      }
      else {
        $buf="";
        $field=$token->[1];
        $field_token=$token;
      }
    }
    elsif ($t eq 'T') {
      $buf=$token->[1] unless $token->[1] =~ /^\s*$/;
    }
    elsif ($t eq 'E') {
      last if $token->[1] eq $rectype;
      add_hash($h,$field,$buf);
      if (--$nest==0 && keys %{$field_token->[2]}) {
        add_hash($h,$field,{%{$field_token->[2]}});
      }
    }
  }
  $h;
}

sub add_hash {
  my ($h,$field,$val)=@_;
  if (defined $h->{$field}) { # duplicate fields become arrays
    my $t=$h->{$field};
    $t=[$t] unless ref $t eq 'ARRAY';
    push @$t,$val;
    $val=$t;
  }
  $h->{$field}=$val;
}

sub get_simple_tree {
  my $self=shift;
  return undef unless ($self->skip_to(@_));
  my $lists=[];
  my $tree=[];
  my $curlist=$tree;
  my $ecount=0;
  while (my $token=$self->get_token()) {
    my $type=$token->[0];
    if ($type eq 'S') {
      my $newlist=[];
      my $newnode={type=>'e',attrib=>$token->[2],name=>$token->[1],content=>$newlist};
      push @$lists, $curlist;
      push @$curlist,$newnode;
      $curlist=$newlist;
      ++$ecount;
    }
    elsif ($type eq 'E') {
      $curlist=pop @$lists;
      last if --$ecount==0;
    }
    elsif ($type eq 'T') {
      push @$curlist,{type=>'t',content=>$token->[1]};
    }
    elsif ($type eq 'PI') {
      push @$curlist,{type=>'p',target=>$token->[1],content=>$token->[2]};
    }
  }
 $tree->[0];
}

sub drive_SAX {
  my $self=shift;
  my $handler=shift;
  my $wrap=1;
  if (@_ && ref($_[0]) eq 'HASH' && defined $_[0]->{wrap}) {
    $wrap=$_[0]->{wrap};
  }
  return undef unless ($self->skip_to(@_));
  my $ecount=0;
  $handler->start_document({}) if $wrap;
  while (my $token=$self->get_token()) {
    my $type=$token->[0];
    if ($type eq 'S') {
      $handler->start_element({Attributes=>$token->[2],Name=>$token->[1]});
      ++$ecount;
    }
    elsif ($type eq 'E') {
      $handler->end_element({Name=>$token->[1]});
      last if --$ecount==0;
    }
    elsif ($type eq 'T') {
      $handler->characters({Data=>$token->[1]});
    }
    elsif ($type eq 'PI') {
      $handler->processing_instruction({Target=>$token->[1],Data=>$token->[2]});
    }
  }
  $wrap? $handler->end_document({}): 1;
}

sub skip_to {
  my $self=shift;
  my $here=0;
  if (@_ && ref($_[0]) eq 'HASH') {
    my $opts=shift;
    $here ||= $opts->{here};
  }
  my $token;
  push @{$self->{rectypes}},{%{$self->{rectypes}[-1]}};
  $self->set_records(@_) if @_;

  if ($here) { # next non-comment token must be start of record
    my $found=0;
    while (($token=$self->get_token()) && $token->[0] eq 'C') {
      ;
    }
    $found=($token && $token->[0] eq 'S'
            && (!keys(%{$self->{rectypes}[-1]})
                || $self->{rectypes}[-1]{$token->[1]})
           );
    $self->unget_token($token) if $token;
    $token=$found;
  }
  else { # skip to start of record
    while ($token=$self->get_token()) {
      next unless $token->[0] eq 'S';
      next unless !keys(%{$self->{rectypes}[-1]}) || $self->{rectypes}[-1]{$token->[1]};
      $self->unget_token($token);
      last;
    }
  } 
  pop @{$self->{rectypes}};
  $token;
}

1;
__END__

=head1 NAME

XML::Records - Perlish record-oriented interface to XML

=head1 SYNOPSIS

  use XML::Records;
  my $p=XML::Records->new('data.lst');
  $p->set_records('credit','debit');
  my ($t,$r)
  while ( (($t,$r)=$p->get_record()) && $t) {
    my $amt=$r->{Amount};
    if ($t eq 'debit') {
      ...
    }
  }

=head1 DESCRIPTION

XML::Records provides a single interface for processing XML data on a 
stream-oriented, tree-oriented, or record-oriented basis.  A subclass of 
XML::TokeParser, it adds methods to read "records" and tree fragments from 
XML documents.

In many documents, the immediate children of the root element form a 
sequence of identically-named and independent elements such as log entries, 
transactions, etc., each of which consists of "field" child elements or 
attributes.  You can access each such "record" as a simple Perl hash.

You can also read any element and its children into a lightweight tree 
implemented as a Perl hash, or feed the contents of any element and its
children into a SAX handler (making it possible to process "records" with
modules like XML::DOM or XML::XPath).

=head1 METHODS

=over 4

=item $parser=XML::Records->new(source, [options]);

Creates a new parser object

I<source> and I<options> are the same as for XML::TokeParser. I<source> is 
either a reference to a string containing the XML, the name of a file 
containing the XML, or an open IO::Handle or filehandle glob reference from 
which the XML can be read.

=item $parser->set_records(name [,name]*);

Specifies what XML element-type names enclose records.  If a name is
prefixed with '-' then the reader will treat a start-tag for that name as
indicating the end of a record.

=item ($type,$record)=$parser->get_record([{options}] [name [,name]*]);

Retrieves the next record from the input, skipping through the XML input 
until it encounters a start tag for one of the elements that enclose 
records.  If the first argument is a hash reference and the value of the 
key 'here' is set to a non-zero value, then non-comment tokens will not be 
skipped and the method will return (undef,undef) if the next token is not a 
start tag for a record-enclosing element (the token will be pushed back in 
this case).  If arguments are given, they will temporarily replace the set 
of record-enclosing elements.  The method will return a list consisting of 
the name of the record's enclosing element and a reference to a hash whose 
keys are the names of the record's child elements ("fields") and whose 
values are the fields' contents (if called in scalar context, the return 
value will be the hash reference).  Both elements of the list will be undef 
if no record can be found.

If a field's content is plain text, its value will be that text.  If a field element
has attributes, its value will be a reference to an array whose first element is the
field's (possibly empty) text value and whose second element is a reference to a hash
of the attributes and their values.

If a field's content contains another element (e.g. a <customer> record 
contains an <address> field that in turn contains other fields), its value 
will be a reference to another hash containing the "sub-record"'s fields.

If a record includes repeated fields, the hash entry for that field's 
name will be a reference to an array of field values.

Attributes of record or sub-record elements are treated as if they were 
fields.  Mixed content (fields with both non-whitespace text and sub-elements)
will lead to unpredictable results.

Records do not actually need to be immediately below the document 
root.  If a <customers> document consists of a sequence of <customer> 
elements which in turn contain <address> elements that include further 
elements, then calling get_record with the record type set to "address" 
will return the contents of each <address> element.

=item $tree=$parser->get_simple_tree([{options}] [name [,name]*]);

Returns a lightweight tree rooted at the next element whose name is listed 
in the arguments, or at the next start-tag token if no arguments are given, 
skipping over any intermediate tokens unless the 'here' option is set as in 
get_record().

The return value is a hash reference to the root node of the tree.  Each 
node is a hash with a 'type' key whose value is the node's type: 'e' for 
elements, 't' for text, and 'p' for processing instructions; and a 
'content' key whose value is a reference to an array of the element's 
child nodes for element nodes, the string value for text nodes, and the 
data value for processing instruction nodes.  Element nodes also have an 
'attrib' key whose value is a reference to a hash of attribute names and 
values.  Processing instructions also have a 'target' key whose value is 
the PI's target.

This method is deprecated; future code should instantiate an XML::Handler::EasyTree
object from the XML::Handler::Trees module and call drive_SAX (see below) on it.

=item $result=$parser->drive_SAX(handler, [{options},[name [,name]*]);

Skips to the next element whose names is listed in the arguments, or the 
next element if no arguments are given, and generates PerlSAX events which 
are sent to the SAX handler object in handler as if the element were an 
entire document. The return value is whatever the handler returned in 
response to the end_document event.  If the 'here' option is set, returns 
undef without generating any SAX events if the next non-comment token is 
not a start tag for a record-enclosing element.  If the 'wrap' option is 
set to 0, does not generate start_document or end_document events and 
returns 1.

At the present time, only SAX1 is supported.

=back

=head1 EXAMPLES

=head2 Print a list of package names from a (rather out-of-date) list of XML modules:

 #!perl -w
 use strict;
 use XML::Records;
 
 my $p=XML::Records->new('modules.xml') or die "$!";
 $p->set_records('module');
 while (my $record=$p->get_record()) {
   my $pkg=$record->{package};
   if (ref $pkg eq 'ARRAY') {
     for my $subpkg (@$pkg) {
       print $subpkg->{name},"\n";
     }
   }
   else {
     print $pkg->{name},"\n";
   }
 }

=head2 Extract interesting items from an RSS 0.91 file

 #!perl -w
 use strict;
 use XML::Records;
 use XML::Handler::YAWriter;

 my $r=XML::Records->new('messages.rss');
 $r->set_records('item');
 my $h=XML::Handler::YAWriter->new(AsString=>1);
 $h->start_document({});
 $h->start_element({Name=>'items'});
 while (my $t=$r->get_tag('item')) {
   $r->unget_token($t);
   $r->begin_saving();
   my $text=$r->get_text('/item');
   if ($text=~/perl/i) {
     $r->restore_saved();
     $r->drive_SAX($h,{wrap=>0,here=>1});
   }
 }
 $h->end_element({Name=>'items'});
 print $h->end_document({});

=head1 RATIONALE

XML::RAX, which implements the proposed RAX standard for record-oriented 
XML access, does much of what XML::Records does but its interface is not 
very Perlish (due to the fact that RAX is a language-independent 
interface), it cannot cope with fields that have sub-structure (because RAX 
itself doesn't address the issue), and it doesn't allow mixing record- 
oriented and non-record-oriented operations.

XML::Twig allows access to tree fragments, but only on a "push" (callback- 
driven) basis, and does not allow mixed tree- and token-level access.

=head1 PREREQUISITES

XML::TokeParser (version 0.03 or higher), XML::Parser.

=head1 AUTHOR

Eric Bohlman (ebohlman@earthlink.net, ebohlman@omsdev.com)

=head1 COPYRIGHT

Copyright 2001 Eric Bohlman.  All rights reserved.

This program is free software; you can use/modify/redistribute it under the
same terms as Perl itself.

=head1 SEE ALSO

  XML::TokeParser
  XML::RAX
  XML::Twig
  XML::Parser::PerlSAX
  perl(1).

=cut
