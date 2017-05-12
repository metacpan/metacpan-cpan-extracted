######################### -*- Mode: Perl -*- #########################
##
## File             : Makefile.PL
##
## Description      : Wais - access to freeWAIS-sf libraries
##
## Author           : Ulrich Pfeifer
## Created On       : Tue Dec 12 08:55:26 1995
##
## Last Modified By : Norbert Goevert
## Last Modified On : Tue Apr  7 16:30:25 1998
##
## $Id: Wais.pm 1.6 Tue, 07 Apr 1998 16:34:24 +0200 goevert $
##
## $ProjectHeader: Wais 23.11 Mon, 03 Aug 1998 18:56:40 +0200 goevert $
######################################################################


use strict;


## ###################################################################
## package Wais
## ###################################################################

package Wais;


require DynaLoader;
use IO::Socket;
use IO::Select;
use Carp;


use vars qw(@ISA $CHARS_PER_PAGE $VERSION $timeout $maxnumfd);
@ISA = qw(DynaLoader);


'$ProjectVersion: 23.11 $ ' =~ /(\d+)\.(\d+)/; $VERSION = $1/10 + $2/1000;

$timeout  = 120;
$maxnumfd = 10;

bootstrap Wais $VERSION;


## ###################################################################
## subs
## ###################################################################

sub Search {
  
  my(@requests) = @_;
  my $missing = 0;                        # number of answers missing
  my $header  = '';                       # last read message header
  my $message = '';                       # last read message
  my $request;                            # current request
  my $select = IO::Select->new();         # open sockets 
  my $result;                             # references to results
  my ($timeleft) = $Wais::timeout;
  my %known_tags;                         # tags -> 1
  my %local;                              # local requests
  my %pending;                            # requests still to send
  my %fh;                                 # tag -> filehandle
  my %tag;                                # filehandle -> tag
  
  if ($#requests > $Wais::maxnumfd - 1) {
    # We assume worst case here. We may need less fds since local
    # searches do not count and some databases may be reached with
    # the same fd.
    
    $result    = Search($requests[$Wais::maxnumfd .. $#requests]);
    $#requests = $Wais::maxnumfd-1;
  } else {
    $result = new Wais::Result;  
  }
  
  foreach $request (@requests) {
    if (ref($request)) {
      my $query    = $request->{'query'};
      my $database = $request->{'database'};
      my $host     = $request->{'host'} || 'localhost';
      my $port     = $request->{'port'} || 210;
      my $tag      = $request->{'tag'}  || $request->{'database'};
      my $docids   = $request->{'relevant'};
      my $apdu;
      my $fh;
      # make sure that tag is unique
      $tag++ while defined($known_tags{$tag}); $known_tags{$tag} = 1;
      
      if (ref($docids)) {
        $apdu = generate_search_apdu($query, $database, $docids);
      } else {
        $apdu = generate_search_apdu($query, $database);
      }
      
      if (($host eq 'localhost') && (-e "$database.src")) {
        # We will handle local searches when as many as possible
        # remote requests have been send.
        $local{$tag} = $apdu;
      } else {
        if ($fh{$host.':'.$port}) { 
          # We have a connection already.
          # Postpone sending until answer for first request is arived
          $pending{$fh{$host.':'.$port}}->{$tag} = $apdu;
        } else {
          # Open a connection to peer
          $fh = new IO::Socket::INET(PeerAddr => $host,
                                     PeerPort => $port,
                                     Proto    => 'tcp',
                                     Type     => SOCK_STREAM);
          # croak "Could not connect to $host:$port" unless $fh;
          if ($fh) {
            $fh->autoflush(1);
            $fh{$host.':'.$port} = $fh;
            # remember $tag for $fh
            $tag{$fh} = $tag;
            $fh->print($apdu);              # send the request
            $select->add($fh);
            $missing++;
          } else {
            $result->add_diag($tag, '', "Could not connect to $host:$port");
          }
        }
      }
    } else {
      croak "Usage: Wais::Search([query, database, host, port], ....)";
    }
  }

  # Answer local requests to give the remote servers time to process
  # requests.
  foreach (keys %local) {
    $message = local_answer($local{$_});
    if ($message) {
      $result->add($_, Wais::Search::new($message));
    }
  }

  while ($missing > 0 and $timeleft > 0) {
    my $time = time;
    my @ready = $select->can_read($timeleft);
    my $fh;
    
    $timeleft -= (time - $time);          # adjust timeleft
    foreach $fh (@ready) {
      my $tag = $tag{$fh};
      my $header = '';
      
      $fh->read($header, 25);
      my $length = substr($header,0,10);
      $fh->read($message, $length);
      $missing--;
      $result->add($tag, Wais::Search::new($message));

      # check if we have pending requests for this $fh
      if (defined $pending{$fh}) {
        my($tag, @tags) = keys %{$pending{$fh}};
        $fh->print($pending{$fh}->{$tag});
        $tag{$fh} = $tag;
        $missing++;
        delete $pending{$fh}->{$tag};
        undef $pending{$fh} unless @tags;
      } else {
        # we are done with this guy
        $select->remove($fh);
        $fh->close;
      }
      last unless $missing;
    }
  }
  
  return($result);
}


sub Retrieve {
  
  my %par = @_;
  my $database = $par{'database'};
  my $host     = $par{'host'}  || 'localhost';
  my $port     = $par{'port'}  || 210;
  my $chunk    = $par{'chunk'} || 0;
  my $docid    = $par{'docid'};
  my $type     = $par{'type'}  || 'TEXT';
  my $message  = '';
  my $header   = '';
  my ($fh, $length);
  my $apdu; 
  my $result   = new Wais::Result('type' => $type);
  my $presult;
  
  if (($host eq 'localhost') && (-e "$database.src")) {
    while (1) {
      $apdu = &generate_retrieval_apdu($database, $docid, $type, $chunk++);
      $message = local_answer($apdu);
      last unless $message;
      $presult = &Wais::Search::new($message);
      $result->add('document', $presult);
      last if length($presult->text) != $Wais::CHARS_PER_PAGE;
    }
  } else {
    $fh = new IO::Socket::INET(PeerAddr => $host,
                               PeerPort => $port,
                               Proto    => 'tcp',
                               Type     => SOCK_STREAM);
    croak "Could not connect to $host:$port" unless $fh;
    $fh->autoflush(1);
    
    while (1) {
      $apdu = &generate_retrieval_apdu($database, $docid, $type, $chunk++);
      $fh->print($apdu);                  # send the request
      $fh->read($header, 25);
      $length = substr($header,0,10);
      $fh->read($message, $length);
      $presult = &Wais::Search::new($message);
      $result->add('document', $presult);
      last if length($presult->text) != $Wais::CHARS_PER_PAGE;
    }
    $fh->close;
  }
  $result;
}


## ###################################################################
## package Wais::Result
## ###################################################################

package Wais::Result;


## public ############################################################

sub new {

  my $type = shift;
  my %par  = @_;
  my $self = {'header' => [], 'diagnostics' => [], 'text' => '', 
              'type'   => $par{'type'}};
  
  bless $self, $type;
}


sub add {

  my $self = shift;
  my ($tag, $result)  = @_;
  
  if ($result) {
    if (ref($result)) {
      my @result;
      my @left  = @{$self->{'header'}};
      my @right = $result->header;
      while (($#left >= $[) or ($#right >= $[)) {
        if ($#left < $[) {
          for (@right) {
            push @result, [$tag, @{$_}];
          }
          last;
        }
        if ($#right < $[) {
          push @result, @left;
          last;
        }
        if ($left[0]->[1] > $right[0]->[0]) {
          push @result, shift @left;
        } else {
          push @result, [$tag, @{shift @right}];
        }
      }
      $self->{'header'} = \@result;
      my %diag = $result->diagnostics;
      for (keys %diag) {
        push(@{$self->{'diagnostics'}}, [$tag, $_, $diag{$_}]);
      }
      if ($result->text) {
        $self->{'text'} .= $result->text;
      }
    } else {
      push(@{$self->{'diagnostics'}}, [$tag, 'Wais::Result::add No reference']);
    }
  } else {
    push(@{$self->{'diagnostics'}}, [$tag, 'Wais::Result::add No result']);
  }
  $self;
}


sub diagnostics {

  my $self = shift;
  
  @{$self->{'diagnostics'}};
}


sub add_diag {
  
  my $self = shift;
  my($tag, $code, $message) = @_;
  push(@{$self->{'diagnostics'}}, [$tag, $code, $message])
}


sub header {

  my $self = shift;
  
  @{$self->{'header'}};
}


sub text {

  my $self = shift;
  
  $self->{'text'};
}


1;
__END__
## ###################################################################
## pod
## ###################################################################

=head1 NAME

Wais - access to freeWAIS-sf libraries

=head1 SYNOPSIS

C<require Wais;>

=head1 DESCRIPTION

The interface is divided in four major parts.

=over 10

=item B<SFgate 4.0>

For backward compatibility the functions used in SFgate up to version
4 are still present. Their use is deprecated and they are not
documented here. These functions may no be supported in following
versions of this module.

=item B<Protocol>

XS functions which provide a low-level access to the WAIS
protocol. E.g. C<generate_search_apdu()> constructs a request
message.

=item B<SFgate 5>

Perl functions that implement high-level access to WAIS
servers. E. g. parallel searching is supported.

=item B<dictionary>

A bunch of XS functions useful for inspecting local databases.

=back

We will start with the B<SFgate 5> functions.

=head1 USAGE

The main high-level interface are the functions C<Wais::Search> and
C<Wais::Retrieve>. Both return a reference to an object of the class
C<Wais::Result>.

=head2 Wais::Search

Arguments of C<Wais::Search> are hash references, one for each
database to search. The keys of the hashes should be:

=over 10

=item B<query>

The query to submit.

=item B<database>

The database which should be searched.

=item B<host>

B<host> is optional. It defaults to C<'localhost'>.

=item B<port>

B<port> is optional. It defaults to C<210>.

=item B<tag>

A tag by which individual results can be associated to a
database/host/port triple. If omitted defaults to the database name.

=item B<relevant>

If present must be a reference to an array containing alternating
document id's and types. Document id's must be of type C<Wais:Docid>.

Here is a complete example:

     $result = Wais::Search({'query'    => 'pfeifer', 
                             'database' => $db1, 
                             'host'     => 'ls6',
                             'relevant' => [$id, 'TEXT']},
                            {'query'    => 'pfeifer', 
                             'database' => $db2});

If I<host> is C<'localhost'> and I<database>C<.src> exists, local
search is performed instead of connecting a server.

C<Wais::Search> will open C<$Wais::maxnumfd> connections in parallel
at most.

=head2 Wais::Retrieve

C<Wais::Retrieve> should be called with named parameters (i.e. a
hash).  Valid parameters are B<database>, B<host>, B<port>, B<docid>,
and B<type>.

        $result = Wais::Retrieve('database' => $db,
                                 'docid'    => $id, 
                                 'host'     => 'ls6',
                                 'type'     => 'TEXT');

Defaults are the same as for C<Wais::Search>. In addition B<type>
defaults to C<'TEXT'>.

=head2 C<Wais:Result>

The functions C<Wais::Search> and C<Wais::Retrieve> return references
to objects blessed into C<Wais:Result>. The following methods are
available:

=over 10

=item B<diagnostics>

Returns and array of diagnostic messages. Each element (if any) is a
reference to an array consisting of 

=over 15

=item F<     tag>

The tag of the corresponding search request or C<'document'> if the
request was a retrieve request.

=item F<     code>

The WAIS diagnostic code.

=item F<     message>

A textual diagnostic message.

=back

=item B<header>

Returns and array of WAIS document headers. Each element (if any) is a
reference to an array consisting of 

=over 15

=item F<     tag>

The tag of the corresponding search request or C<'document'> if the
request was a retrieve request.


=item F<     score>

=item F<     lines>

Length of the corresponding dcoument in lines.

=item F<     length>

Length of the corresponding document in bytes.

=item F<     headline>

=item F<     types>

A reference to an array of types valid for B<docid>.

=item F<     docid>

A reference to the WAIS identifier blessed into C<Wais::Docid>.

=back

=item B<text>

Returns the text fetched by C<Wais::Retrieve>.

=back

=head1 Dictionary

There are a couple of functions to inspect local databases. See the
B<inspect> script in the distribution. You need the B<Curses> module
to run it. Also adapt the directory settings in the top part.

=head2 Wais::dictionary

       %frequency = Wais::dictionary($database);
       %frequency = Wais::dictionary($database, $field);
       %frequency = Wais::dictionary($database, 'foo*');
       %frequency = Wais::dictionary($database,  $field, 'foo*');

The function returns an array containing alternating the matching
words in the global or field dictionary matching the prefix if given
and the freqence of the preceding word. In a sclar context, the number
of matching word is returned.

=head2 Wais::list_offset

The function takes the same arguments as Wais::dictionary. It returns
the same array rsp. wordcount with the word frequencies replaced by
the offset of the postinglist in the inverted file.

=head2 Wais::postings

       %postings = Wais::postings($database, 'foo');
       %postings = Wais::postings($database, $field, 'foo');

Returns and an array containing alternating numeric document id's and
a reference to an array whichs first element is the internal weight if
the word with respect to the document. The other elements are the
word/character positions of the occurances of the word in the
document. If freeWAIS-sf is compiled with C<-DPROXIMITY>, word
positions are returned otherwise character postitions.

In an scalar context the number of occurances of the word is returned.

=head2 Wais::headline

       $headline = Wais::headline($database, $docid);

The function retrieves the headline (only the text!) of the document
numbered C<$docid>.

=head2 Wais::document

       $text = &Wais::document($database, $docid);

The function retrieves the text of the document numbered C<$docid>.

=head1 Protocol

=head2 Wais::generate_search_apdu


       $apdu = Wais::generate_search_apdu($query,$database);
       $relevant = [$id1, 'TEXT', $id2, 'HTML'];
       $apdu = Wais::generate_search_apdu($query,$database,$relevant);

Document id's must be of type C<WAIS::Docid> as returned by
C<Wais::Result::header> or Wais::Search::header. $WAIS::maxdoc may be
set to modify the number of documents to retrieve.

=head2 Wais::generate_retrieval_apdu

       $apdu = Wais::generate_retrieval_apdu($database, $docid, $type);
       $apdu = Wais::generate_retrieval_apdu($database, $docid, 
                                             $type, $chunk);

Request to send the C<$chunk>'s chunk of the document whichs id is
C<$docid> (must be of type C<WAIS::Docid>). $chunk defaults to C<0>.
$Wais::CHARS_PER_PAGE may be set to influence the chunk size.

=head2 Wais::local_answer

       $answer = Wais::local_answer($apdu);

Answer the request by local search/retrieval. The message header is
stripped from the result for convenience (see the code of
C<Wais::Search> rsp. documentaion of Wais::Search::new below).

=head2 Wais::Search::new

       $result = Wais::Search::new($message);

Turn the result message in an object of type C<Wais::Search>.
The following methods are available: B<diagnostics>, B<header>, and
B<text>. Result of the message is pretty the same as for
C<Wais::Result>. Just the tags are missing.

=head2 Wais::Docid::new

       $result = new Wais::Docid($distserver, $distdb, $distid,
                     $copyright,  $origserver, $origdb, $origid);

Only the first four arguments are manatory.

=head2 Wais::Docid::split

       ($distserver, $distdb, $distid, $copyright, $origserver, 
        $origdb, $origid) = Wais::Docid::split($result);
       ($distserver, $distdb, $distid) = Wais::Docid::split($result);
       ($distserver, $distdb, $distid) = $result->split;

The inverse of C<Wais::Docid::new>
       
=over 10

=item  B<diagnostics>

Return an array of references to C<[$code, $message]>

=item B<header>

Return an array of references to C<[$score, $lines, $length,
$headline, $types, $docid]>.

=item B<text>

Returns the chunk of the document requested. For documents larger than
$Wais::CHARS_PER_PAGE more than one request must be send.

=back

=head2 Wais::Search::DESTROY

The objects will be destroyed by Perl.

=head1 VARIABLES

=over 10

=item $Wais::version

Generated by: C<sprintf(buf, "Wais %3.1f%d", VERSION, PATCHLEVEL);>

=item $Wais:errmsg

Set to an verbose error message if something went wrong. Most
functions return C<undef> on failure after setting C<$Wais:errmsg>.

=item $Wais::maxdoc

Maximum number of hits to return when searching. Defaults to C<40>.

=item $Wais::CHARS_PER_PAGE

Maximum number of bytes to retrieve in a single retrieve request.
C<Wais:Retrieve> sends multiple requests if necessary to retrieve a
document. C<CHARS_PER_PAGE> defaults to C<4096>.

=item $Wais::timeout

Number of seconds to wait for an answer from remote servers. Defaults
to 120.

=item $Wais::maxnumfd

Maximum number of file descriptors to use simultaneously in C<Wais::Search>.
Defaults to C<10>.

=back

=head1 Access to the basic freeWAIS-sf reduction functions

=item B<Wais::Type::stemmer>(I<word>)

reduces I<word> using the well know Porter algorithm.

  AU: Porter, M.F.
  TI: An Algorithm for Suffix Stripping
  JT: Program
  VO: 14
  PP: 130-137
  PY: 1980
  PM: JUL

=item B<Wais::Type::soundex>(I<word>)


computes the 4 byte B<Soundex> code for I<word>.

  AU: Gadd, T.N.
  TI: 'Fisching for Werds'. Phonetic Retrieval of written text in
      Information Retrieval Systems
  JT: Program
  VO: 22
  NO: 3
  PP: 222-237
  PY: 1988


=item B<Wais::Type::phonix>(I<word>)

computes the 8 byte B<Phonix> code for I<word>.

  AU: Gadd, T.N.
  TI: PHONIX: The Algorithm
  JT: Program
  VO: 24
  NO: 4
  PP: 363-366
  PY: 1990
  PM: OCT


=head1 BUGS

C<Wais::Search> currently splits the request in groups of
C<$Wais::maxnumfd> requests. Since some requests of the group might be
local and/or some might refer to the same host/port, groups may not
use all C<$Wais::maxnumfd> possible file descriptors. Therefore some
performance my be lost when more than C<$Wais::maxnumfd> requests are
processed.

=head1 AUTHORS

Ulrich Pfeifer F<E<lt>pfeifer@ls6.cs.uni-dortmund.deE<gt>>,
Norbert Goevert F<E<lt>goevert@ls6.cs.uni-dortmund.deE<gt>>
