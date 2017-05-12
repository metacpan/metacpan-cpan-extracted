# 4AIJDCLW:  XML::Merge.pm by Pip Stuart <Pip@CPAN.Org> to intelligently merge XML documents as parsed XML::XPath objects.
package      XML::Merge;
use strict;use warnings;use utf8;
require      XML::Tidy  ;
use base qw( XML::Tidy );
use          XML::Tidy  ;
use Carp;
our $VERSION = '1.4';our $d8VS='G7NMEdxm';
sub new { my $clas = shift(); my @parm; my $cres = 'main';
  for(my $indx = 0; $indx < @_; $indx++) { if($_[$indx] =~ /^[-_]?(cres$|conflict_resolution)/ && ($indx + 1) < @_) { $cres =   $_[++$indx] ; }
                                           else                                                                     { push(@parm, $_[$indx]); } }
  my $tdob = XML::Tidy->new(@parm); my $self = bless($tdob, $clas); # self just a new Tidy (XPath) obj blessed into Merge class...
  $self->{'_object_to_merge'} = undef; $self->{'_conflict_resolution_method'} = $cres; # ... with a few new options
  #         Conflict RESolution method valid values:
  # 'main' = Main (primary) file wins
  # 'merg' = Merge file resolves (Last-In wins)
  # 'warn' = Croak warning about conflict && halt merge
  # 'test' = Test whether any conflict would occur if merge were performed (0 for no conflict)
  $self->{'_comment_join_method'} = 'none';
  #         CoMmenT Join        method valid values: (no joins are implemented yet)
  # 'none', 'separate'
  # 'join', 'combine'
  # 'jd8s', 'join_with_d8_stamp'
  # 'jlts', 'join_with_localtime_stamp'
  $self->{'_id_xpath_list'} = [ # unique ID elements or attributes
    '@id'    ,
    '@idx'   ,
    '@ndx'   ,
    '@index' ,
    '@name'  ,
    '@handle' ];
  return($self); }
sub merge {
  my $self = shift(); my @parm;
  my $cres = $self->get_conflict_resolution_method();
  my $cmtj = undef;#$self->get_comment_join_method();
  my $mdxp = undef;
  my $msxp = undef;
  my $mgob = undef;
  # setup local options
  for(my $indx = 0; $indx < @_; $indx++) {
    if     ($_[$indx] =~ /^[-_]?(cres$|conflict_resolution)/ && ($indx + 1) < @_) {
      $cres = $_[++$indx];
    } elsif($_[$indx] =~ /^[-_]?(cmtj$|comment_join)/        && ($indx + 1) < @_) {
      $cmtj = $_[++$indx];
    } elsif($_[$indx] =~ /^[-_]?(mdxp$|merge_destination)/   && ($indx + 1) < @_) {
      $mdxp = $_[++$indx];
    } elsif($_[$indx] =~ /^[-_]?(msxp$|merge_source)/        && ($indx + 1) < @_) {
      $msxp = $_[++$indx];
    } elsif(ref($_[$indx]) =~ /XML::(XPath|Tidy|Merge)/) {
      $self->set_object_to_merge($_[$indx]);
    } else {
      push(@parm, $_[$indx]);
    } }
  $self->set_object_to_merge( XML::Merge->new(@parm) ) if(@parm);
  $cres = 'merg' if($cres =~ /last/i);
  $mgob = $self->get_object_to_merge();
  if($mgob) { my $mnrn; my $mgrn; # traverse main Merge obj && merge w/ object_to_merge according to options
    # 0a. ck if root node elems have same LocalName but short-circuit root element loading if merge_source or merge_dest
    if(defined($mdxp) && length($mdxp)) { ($mnrn)= $self->findnodes($mdxp); } else { ($mnrn)= $self->findnodes('/*'); }
    if(defined($msxp) && length($msxp)) { ($mgrn)= $mgob->findnodes($msxp); } else { ($mgrn)= $mgob->findnodes('/*'); }
    if($mnrn->getLocalName() eq $mgrn->getLocalName()) { # 1a. ck if each merge root elem has attributes which main doesn't
      for($mgrn->findnodes('@*')) {
        my($mnat)= $mnrn->findnodes('@' . $_->getLocalName());
        # if both root elems have same attribute name with different values...
        if(defined($mnat)) {
          # must use Conflict RESolution method to know who's value wins
          if($mnat->getNodeValue() ne $_->getNodeValue()) {
            if     ($cres eq 'merg') {
              $mnat->setNodeValue($_->getNodeValue());
            } elsif($cres eq 'warn') {
              croak("!*WARN*! Found conflicting attribute:" .
                                     $_   ->getLocalName() .
                "\n  main value:" .  $mnat->getNodeValue() .
                "\n  merg value:" .  $_   ->getNodeValue() .
                "\n    Croaking... please resolve manually.\n");
            } elsif($cres eq 'test') {
              return(1); } }
        } else {
          $mnrn->appendAttribute($_) unless($cres eq 'test'); } }
      # 1b. loop through all merge child elems
      if   ($mgrn->findnodes('*')){
        for($mgrn->findnodes('*')){my $mnmt;
          my $mtch =  0; # flag to know if already matched
          my @mgms = (); # save multiple MerG MatcheS
          for my $idat (@{$self->get_id_xpath_list()}){ # test ID XPaths
            # if a child merge elem has a matching id, search main for same
#           my @idns = $_->findnodes($idat); # $mgmt MerG MaTch, $mnmt Merg Node MaTch, @idns ID NodeS, $mmas Merg Match Attr String
#           for my $mgmt (@idns){my $mmas=$mgmt->toString();$mmas=~ s/^\s+(.*)/$1/;push(@mgms, '@' . $mmas);}}
#         if(@mgms){
#           ($mnmt)= $mnrn->findnodes($_->getLocalName() . '[' . join(' and ', @mgms) . ']');
#           if(defined($mnmt)){ # id matched both main && merg...
#             $mtch = 1; # was trying to incorporate multiple ID attributes from Kevin here, but not sure how to proceed so just leaving original code for now
            my($mgmt)= $_->findnodes($idat);
            if(defined($mgmt)){
              if     ($idat =~ /^\@/) {
                ($mnmt)= $mnrn->findnodes($_->getLocalName() . '[' . $idat . '="' . $mgmt->getNodeValue() . '"]');
              } elsif($idat =~ /\[\@\w+\]/) {
                my $itmp = $idat; my $nval = $mgmt->getNodeValue();
                $itmp =~ s/(\[\@\w+)\]/$1="$nval"\]/;
                ($mnmt)= $mnrn->findnodes($itmp);
              } else {
                ($mnmt)= $mnrn->findnodes($idat); }
              if(defined($mnmt)) { # id matched both main && merg...
                $mtch = 1; # so recursively merge deeper...
                my $test = $self->_recmerge($mnmt, $_, $cres, $cmtj);
                return(1) if($cres eq 'test' && $test); } } }
          if(!$mtch && $mnrn->findnodes($_->getLocalName())) {
            my($mnmt)= $mnrn->findnodes($_->getLocalName());
            if(defined($mnmt)) { # plain elem matched both main && merg...
              my $fail = 0;
              for my $idat (@{$self->get_id_xpath_list()}) {
                my($mnat)= $mnmt->findnodes($idat); # MaiN ATtribute
                my($mgat)= $_   ->findnodes($idat); # MerG ATtribute
                $fail = 1 if(defined($mnat) || defined($mgat));
              }
              unless($fail) { # fail tests if any unique id paths were found
                $mtch = 1; # so recursively merge deeper...
                my $test = $self->_recmerge($mnmt, $_, $cres, $cmtj);
                return(1) if($cres eq 'test' && $test);
              } } }
          # if none above matched, append diff child to main root node
          $mnrn->appendChild($_) unless($mtch || $cres eq 'test'); }
      } elsif($mgrn->getChildNodes()) { # no kid elems but kid text data node
        my($mntx)= $mnrn->getChildNodes();
        my($mgtx)= $mgrn->getChildNodes();
        if(defined($mgtx) && $mgtx->getNodeType() == TEXT_NODE) {
          if     (!defined($mntx)) {
            $mnrn->appendChild($mgtx) unless($cres eq 'test');
          } elsif($cres eq 'merg') {
            $mntx->setNodeValue($mgtx->getNodeValue());
          } elsif($cres eq 'warn') {
            croak("!*WARN*! Found conflicting     Root text node:" .
                                   $mnrn->getLocalName() .
              "\n  main value:" .  $mntx->getNodeValue() .
              "\n  merg value:" .  $mgtx->getNodeValue() .
              "\n    Croaking... please resolve manually.\n");
          } elsif($cres eq 'test') {
            #return(1); # new text node value is not a merge prob?
          } } }
    # 0b. ck if merge root node elem exists somewhere in main
    } elsif($self->findnodes('//' . $mgrn->getLocalName())) {
      my($mnmt)= $self->findnodes('//' . $mgrn->getLocalName());
      # recursively merge main child with merg root
      my $test = $self->_recmerge($mnmt, $mgrn, $cres, $cmtj);
      return(1) if($cres eq 'test' && $test);
    # 0c. just append whole merge doc as last child of main root
    } elsif($cres ne 'test') {
      $mnrn->appendChild($mgrn);
      $mnrn->appendChild($self->Text("\n")); } }
  return(0); } # false zero 0 test _cres == no conflict, true 1 == conflict
sub _recmerge { # recursively merge XML elements
  my $self = shift(); # merge() already setup all needed _optn values
  my $mnnd = shift(); # MaiN NoDe
  my $mgnd = shift(); # MerG NoDe
  my $cres = shift() || $self->get_conflict_resolution_method();
  my $cmtj = shift(); # $self->get_comment_join_method();
  if($mnnd->getLocalName() eq $mgnd->getLocalName()) {
    for($mgnd->findnodes('@*')) {
      my($mnat)= $mnnd->findnodes('@' . $_->getLocalName());
      if(defined($mnat)) {
        if($mnat->getNodeValue() ne $_->getNodeValue()) {
          if     ($cres eq 'merg') {
            $mnat->setNodeValue($_->getNodeValue());
          } elsif($cres eq 'warn') {
            croak("!*WARN*! Found conflicting Non-Root attribute:" .
                                   $_   ->getLocalName() .
              "\n  main value:" .  $mnat->getNodeValue() .
              "\n  merg value:" .  $_   ->getNodeValue() .
              "\n    Croaking... please resolve manually.\n");
          } elsif($cres eq 'test') {
            return(1); } }
      } else {
        $mnnd->appendAttribute($_) unless($cres eq 'test'); } }
    if($mgnd->findnodes('*')) {
      for($mgnd->findnodes('*')) {
        my $mtch =  0; # flag to know if already matched
        for my $idat (@{$self->get_id_xpath_list()}) { # test ID XPaths
          # if a child merge elem has a matching id, search main for same
          my($mgmt)= $_->findnodes($idat); # MerG MaTch
          if(defined($mgmt)) {
            my $mnmt;
            if     ($idat =~ /^\@/) {
              ($mnmt)= $mnnd->findnodes($_->getLocalName() . '[' . $idat . '="' . $mgmt->getNodeValue() . '"]');
            } elsif($idat =~ /\[\@\w+\]/) {
              my $itmp = $idat; my $nval = $mgmt->getNodeValue();
              $itmp =~ s/(\[\@\w+)\]/$1="$nval"\]/;
              ($mnmt)= $mnnd->findnodes($itmp);
            } else {
              ($mnmt)= $mnnd->findnodes($idat); }
            if(defined($mnmt)) { # id matched both main && merg...
              $mtch = 1; # so recursively merge deeper...
              my $test = $self->_recmerge($mnmt, $_, $cres, $cmtj);
              return(1) if($cres eq 'test' && $test); } } }
        if(!$mtch && $mnnd->findnodes($_->getLocalName())) {
          my($mnmt)= $mnnd->findnodes($_->getLocalName());
          if(defined($mnmt)) { # plain elem matched both main && merg...
            my $fail = 0;
            for my $idat (@{$self->get_id_xpath_list()}) {
              my($mnat)= $mnmt->findnodes($idat); # MaiN ATtribute
              my($mgat)= $_   ->findnodes($idat); # MerG ATtribute
              $fail = 1 if(defined($mnat) || defined($mgat)); }
            unless($fail) { # fail tests if any unique id paths were found
              $mtch = 1; # so recursively merge deeper...
              my $test = $self->_recmerge($mnmt, $_, $cres, $cmtj);
              return(1) if($cres eq 'test' && $test); } } }
        # if none above matched, append diff child to main root node
        $mnnd->appendChild($_) unless($mtch || $cres eq 'test'); }
    } elsif($mgnd->getChildNodes()) { # no child elems but child text data node
      my($mntx)= $mnnd->getChildNodes();
      my($mgtx)= $mgnd->getChildNodes();
      if(defined($mgtx) && $mgtx->getNodeType() == TEXT_NODE) {
        if     (!defined($mntx) && $cres ne 'test') {
          $mnnd->appendChild($mgtx);
        } elsif($cres eq 'merg') {
          $mntx->setNodeValue($mgtx->getNodeValue());
        } elsif($cres eq 'warn') {
          croak("!*WARN*! Found conflicting Non-Root text node:" .
                                 $mnnd->getLocalName() .
            "\n  main value:" .  $mntx->getNodeValue() .
            "\n  merg value:" .  $mgtx->getNodeValue() .
            "\n    Croaking... please resolve manually.\n");
        } elsif($cres eq 'test') {
          #return(1); # new text node value is not a merge prob?
        } } }
  } elsif($cres ne 'test') { # append whole merge elem as last kid of main elem
    $mnnd->appendChild($mgnd);
    $mnnd->appendChild($self->Text("\n")); }
  return(0); } # return false for no conflict
sub unmerge { # short-hand for writing a certain xpath_loc out then pruning it
  my $self = shift(); my @parm; my $xplc = undef; my $flnm = undef;
  # setup local options
  for(my $indx = 0; $indx < @_; $indx++) {
    if     ($_[$indx] =~ /^[-_]?(flnm$|filename)/       && ($indx + 1) < @_) {
      $flnm = $_[++$indx];
    } elsif($_[$indx] =~ /^[-_]?(xplc$|xpath_location)/ && ($indx + 1) < @_) {
      $xplc = $_[++$indx];
    } else {
      push(@parm, $_[$indx]); } }
  if(@parm) {
    $flnm = shift(@parm) unless(defined($flnm));
    $xplc = shift(@parm) unless(defined($xplc)); }
  if(defined($flnm) && defined($xplc) &&
     length ($flnm) && length ($xplc)) {
    $self->write($flnm,
                 $xplc);
    $self->prune($xplc); } }
# Accessors
sub get_object_to_merge           {my $self=shift();                                                        return($self->{'_object_to_merge'           });}
sub set_object_to_merge           {my $self=shift();$self->{'_object_to_merge'           } = shift() if(@_);return($self->{'_object_to_merge'           });}
sub get_conflict_resolution_method{my $self=shift();                                                        return($self->{'_conflict_resolution_method'});}
sub set_conflict_resolution_method{my $self=shift();$self->{'_conflict_resolution_method'} = shift() if(@_);return($self->{'_conflict_resolution_method'});}
#ub get_comment_join_method       {my $self=shift();                                                        return($self->{'_comment_join_method'       });}
#ub set_comment_join_method       {my $self=shift();$self->{'_comment_join_method'       } = shift() if(@_);return($self->{'_comment_join_method'       });}
sub get_id_xpath_list             {my $self=shift();                                                        return($self->{'_id_xpath_list'             });}
sub set_id_xpath_list             {my $self=shift();
  if(@_) { if(@_ == 1 && ref($_[0]) eq 'ARRAY') { $self->{'_id_xpath_list'} = shift(); }
           else                                 { $self->{'_id_xpath_list'} =  [ @_ ]; } }                  return($self->{'_id_xpath_list'             });}
sub DESTROY { } # do nothing but define in case needed later and to calm test warnings
8;

=encoding utf8

=head1 NAME

XML::Merge - flexibly merge XML documents

=head1 VERSION

This documentation refers to version 1.4 of XML::Merge, which was released on Sat Jul 23 14:39:59:48 -0500 2016.

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;use   warnings;
  use   utf8;use XML::Merge;

  # create new   XML::Merge object from         MainFile.xml
  my $merge_obj= XML::Merge->new('filename' => 'MainFile.xml');

  # Merge File2Add.xml             into         MainFile.xml
     $merge_obj->merge(          'filename' => 'File2Add.xml');

  # Tidy up the indenting that resulted from the merge
     $merge_obj->tidy();

  # Write out changes back           to         MainFile.xml
     $merge_obj->write();

=head1 DESCRIPTION

This module inherits from L<XML::Tidy> which in turn inherits from
L<XML::XPath>. This ensures that Merge objects' indenting can be
tidied up after any merge operation since such modification usually
ruins indentation. Polymorphism allows Merge objects to be utilized
as normal XML::XPath objects as well.

The merging behavior is setup to combine separate XML documents
according to certain rules and configurable options. If both
documents have root nodes which are elements of the same name, the
documents are merged directly. Otherwise, one is merged as a child
of the other. An optional XPath location can be specified as the
place to perform the merge. If no location is specified, the merge
is attempted at the first matching element or is appended as the new
last child of the other root if no match is found.

=head1 USAGE

=head2 new()

This is the standard Merge object constructor. It can take the
same parameters as an L<XML::XPath> object constructor to initialize
the primary XML document object (the object which subsequent XML
documents will be merged into). These parameters can be any one of:

  'filename' => 'SomeFile.xml'
  'xml'      => $variable_which_holds_a_bunch_of_XML_data
  'ioref'    => $file_InputOutput_reference
  'context'  => $existing_node_at_specified_context_to_become_new_obj

Merge's new() can also accept merge-option parameters to
override the default merge behavior. These include:

  'conflict_resolution_method' => 'main', # main  file wins
  'conflict_resolution_method' => 'merg', # merge file wins
  # 'last-in_wins' is the same as 'merg'
  'conflict_resolution_method' => 'warn', # croak conflicts
  'conflict_resolution_method' => 'test', # just test, 1 if conflict

=head2 merge()

The merge() member function can accept the same L<XML::XPath>
constructor options as new() but this time they are for the
temporary file which will be merged into the main object.
Merge-options from new() can also be specified and they will only
impact one particular invokation of merge(). The specified document
will be merged into the primary XML document object according to
the following default merge rules:

1. If both documents share the same root element name, they are
merged directly.

2. If they don't share root elements but the temporary merge file's
root element is found anywhere within the main file, the merge
occurs at the match.

3. If no root element match is found, the merge document becomes the
new last child of the main file's root element.

4. Whenever a deeper level is found with an element of the same name
in both documents and either it does not contain any
distinguishing attributes or it has attributes which are
recognized as 'identifier' (id) attributes (by default, for any
element, these are attributes named: 'id', 'idx', 'ndx',
'index', 'name', and 'handle'), a corresponding element is
searched for to match and merge with.

5. Any remaining (non-id) nodes are merged in document order.

6. When a conflict arises as non-id attributes or other nodes merge,
the specified conflict_resolution_method merge-option is
applied (which by default has the main file data persist at the
expense of the merging file data).

Some of the above rules can be overridden first by the object's
merge-options and second by the particular method call's merge-options.
Thus, if the default merge-option for conflict resolution is to
have the main object win and you use the following constructor:

  my $merge_obj = XML::Merge->new(
    'filename'                   => 'MainFile.xml',
    'conflict_resolution_method' => 'last-in_wins');

... then any $merge_obj->merge() call would override the
default merge behavior by letting the document being merged have
priority over the main object's document. However, you could
supply additional merge-options in the parameter list of your
specific merge() call like:

  $merge_obj->merge(
    'filename'                   => 'File2Add.xml',
    'conflict_resolution_method' => 'warn');

... to have the latest option override further.

The 'test' conflict_resolution_method merge-option does not modify the
object at all. It solely returns zero (0) if no conflict was encountered
from a temporary attempted merge.

It should be used like:

  for(@files) {
    if($merge_obj->merge('cres' => 'test', $_)) {
      croak("Yipes! Conflict with file:$_!\n");
    } else {
      $merge_obj->merge($_); # only do it if there are no conflicts
    }
  }

merge() can also accept another XML::Merge object as a parameter
for what to be merged with the main object instead of a filename.
An example of this is:

  $merge_obj->merge($another_merge_obj);

Along with the merge options that can be specified in the object
constructor, merge() also accepts the following options to specify
where to perform the merge relative to:

  'merge_destination_path' => $main_obj_xpath_location,
  'merge_source_path'      => $merging_obj_xpath_location,

=head2 unmerge()

The unmerge() member function is a shorthand for calling both write()
and prune() on a certain XPath location which should be written out
to a disk file before being removed from the Merge object. Please
see L<XML::Tidy> for documentation of the inherited write() and prune()
member functions.

This unmerge() process could be the opposite of merge() if no original
elements or attributes overlapped and combined but if combining did
happen, this would remove original sections of your primary XML
document's data from your Merge object so please use this carefully.
It is meant to help separate a giant object (probably the result of
myriad merge() calls) back into separate useful well-formed XML
documents on disk.

unmerge() takes a filename and an xpath_location parameter.

=head1 Accessors

=head2 get_object_to_merge()

Returns the object which was last merged into the main object.

=head2 set_object_to_merge()

Assigns the object which was last merged into the main object.

=head2 get_conflict_resolution_method()

Returns the underlying merge-option conflict_resolution_method.

=head2 set_conflict_resolution_method()

A new value can be provided as a parameter to be assigned
as the XML::Merge object's merge-option.

=head2 get_id_xpath_list()

Returns the underlying id_xpath_list. This is normally just a list
of attributes (e.g., '@id', '@idx', '@ndx', '@index', '@name', '@handle')
which are unique identifiers for any XML element within merging instance
documents. When these attribute names are encountered during a merge(),
another element with the same name and attribute value are searched for
explicitly in order to align deeper merging and conflict resolution.

=head2 set_id_xpath_list()

A new list can assigned to the XML::Merge object's id_xpath_list.

Please note that this list normally contains XPath attributes so they
must be preceded by an at-symbol (@) like: '@example_new_id_attribute'.

=head1 CHANGES

Revision history for Perl extension XML::Merge:

=over 2

=item - 1.4 G7NMEdxm  Sat Jul 23 14:39:59:48 -0500 2016

* inverted conflict resolution 'test' value since true 1 for conflict makes more sense

* renumbered t/*.t

* updated Makefile.PL and Build.PL to hopefully fix issue L<HTTPS://RT.CPAN.Org/Public/Bug/Display.html?id=29898> (Thanks Kevin.)

* removed DBUG printing

* removed PT from VERSION to fix issue L<HTTPS://RT.CPAN.Org/Public/Bug/Display.html?id=106873> (Thanks ppisar.)

* updated license to GPLv3

=item - 1.2.75BAJNl  Fri May 11 10:19:23:47 2007

* added default id @s: idx, ndx, and index

=item - 1.2.565EgGd  Sun Jun  5 14:42:16:39 2005

* added use XML::Tidy to make sure exports are available

* removed 02prune.t and moved 03keep.t to 02keep.t ... passing tests is good

=item - 1.2.4CCJWiB  Sun Dec 12 19:32:44:11 2004

* guessing how to fix Darwin test failure @ t/02prune.t first prune() call

=item - 1.0.4CAL5IS  Fri Dec 10 21:05:18:28 2004

* fixed buggy _recmerge

=item - 1.0.4CAEU0I  Fri Dec 10 14:30:00:18 2004

* made accessors for _id_xpath_list

* made _id_xpath_list take XPath locations instead of elem names (old _idea)

* made test _cres (at Marc's request)

* made warn _cres croak

* made Merge inherit from Tidy (which inherits from XPath)

* separated reload(), strip(), tidy(), prune(), and write() into own
    XML::Tidy module

=item - 1.0.4C2Nf0R  Thu Dec  2 23:41:00:27 2004

* updated license and prep'd for release

=item - 1.0.4C2BcI2  Thu Dec  2 11:38:18:02 2004

* updated reload(), strip(), and tidy() to verify _xpob exists

=item - 1.0.4C1JHOl  Wed Dec  1 19:17:24:47 2004

* commented out override stuff since it's probably bad form and dumps crap
    warnings all over tests and causes them to fail... so I guess just
    uncomment that stuff if you care to preserve PI's and escapes

=item - 1.0.4C1J7gt  Wed Dec  1 19:07:42:55 2004

* made merge() accept merge_source_xpath and merge_destination_xpath params

* made merge() accept other Merge objects

* made reload() not clobber basic escapes (by overriding Text toString())

* made tidy() not kill processing-instructions (by overriding node_test())

* made tidy() not kill comments

=item - 1.0.4BOHGjm  Wed Nov 24 17:16:45:48 2004

* fixed merge() same elems with diff ids bug

=item - 1.0.4BNBCZL  Tue Nov 23 11:12:35:21 2004

* rewrote both merge() and _recmerge() _cres stuff since it was
    buggy before... so hopefully consistently good now

=item - 1.0.4BMJCPm  Mon Nov 22 19:12:25:48 2004

* fixed merge() for empty elem matching and _cres on text kids

=item - 1.0.4BMGTLF  Mon Nov 22 16:29:21:15 2004

* separated reload() from strip() so that prune() can call it too

=item - 1.0.4BM0B3x  Mon Nov 22 00:11:03:59 2004

* fixed tidy() empty elem bug and implemented prune() and unmerge()

=item - 1.0.4BJAZpM  Fri Nov 19 10:35:51:22 2004

* fixing e() ABSTRACT gen bug

=item - 1.0.4BJAMR6  Fri Nov 19 10:22:27:06 2004

* fleshed out POD and members

=item - 1.0.4AIDqmR  Mon Oct 18 13:52:48:27 2004

* original version

=back

=head1 TODO

=over 2

=item - add Kevin's multiple _idea option where several element attributes are an ID together, from: <HTTPS://RT.CPAN.Org/Public/Bug/Display.html?id=29897>

=item - make namespaces and attributes stay in order after merge()

=item - make text append merge option

=item - handle comment joins and stamping options

=item - support modification-time conflict resolution method

=item - add _ignr ignore list of merge XPath locations to not merge (pre-prune())

=back

=head1 INSTALL

From the command shell, please run:

  `perl -MCPAN -e "install XML::Merge"`

or uncompress the package and run the standard:

  `perl Makefile.PL;       make;       make test;       make install`
    or if you don't have  `make` but Module::Build is installed, try:
  `perl    Build.PL; perl Build; perl Build test; perl Build install`

=head1 FILES

XML::Merge requires:

L<Carp>                to allow errors to croak() from calling sub

L<XML::Tidy>           to use objects derived from XPath to update XML

=head1 LICENSE

Most source code should be Free! Code I have lawful authority over is and shall be!
Copyright: (c) 2004-2016, Pip Stuart.
Copyleft :  This software is licensed under the GNU General Public License
  (version 3 or later). Please consult L<HTTP://GNU.Org/licenses/gpl-3.0.txt>
  for important information about your freedom. This is Free Software: you
  are free to change and redistribute it. There is NO WARRANTY, to the
  extent permitted by law. See L<HTTP://FSF.Org> for further information.

=head1 AUTHOR

Pip Stuart <Pip@CPAN.Org>

=cut

# Please see CHANGES for why below remains commented out.
## To not kill Processing Instructions, used to need to fix node_test() test_nt_pi return in XML::XPath::Step.pm first...
#package XML::XPath::Step;
#use XML::XPath::Parser;
#use XML::XPath::Node;
#sub node_test {
#  my $self = shift; my $node = shift;
#  my $test = $self->{test}; # if node passes test, return true
#  return 1 if $test == test_nt_node;
#  if($test == test_any) {
#    return 1 if $node->isElementNode && defined $node->getName;
#  }
#  local $^W;
#  if($test == test_ncwild) {
#    return unless $node->isElementNode;
#    my $match_ns = $self->{pp}->get_namespace($self->{literal}, $node);
#    if(my $node_nsnode = $node->getNamespace()) {
#      return 1 if $match_ns eq $node_nsnode->getValue;
#    }
#  } elsif($test == test_qname) {
#    return unless $node->isElementNode;
#    if($self->{literal} =~ /:/) {
#      my($prefix, $name) = split(':', $self->{literal}, 2);
#      my $match_ns = $self->{pp}->get_namespace($prefix, $node);
#      if(my $node_nsnode = $node->getNamespace()) {
#        return 1 if($match_ns eq $node_nsnode->getValue && $name eq $node->getLocalName);
#      }
#    } else {
#      return 1 if $node->getName eq $self->{literal};
#    }
#  } elsif ($test == test_nt_text) {
#    return 1 if $node->isTextNode;
#  } elsif($test == test_nt_comment) {
#    return 1 if $node->isCommentNode;
#  } elsif($test == test_nt_pi) {
#    return unless $node->isPINode;
#    # EROR was here!  $self->{literal} is undefined so can't ->value!
#    #if(my $val = $self->{literal}->value) {
#    #  return 1 if $node->getTarget eq $val;
#    #} else {
#      return 1;
#    #}
#  }
#  return; # fallthrough returns false
#}
## ... also update Text nodes' toString() to escape both < && >! ...
#package XML::XPath::Node::TextImpl;
#sub toString {
#  my $self = shift; XML::XPath::Node::XMLescape($self->[node_text], '<&>');
#}
