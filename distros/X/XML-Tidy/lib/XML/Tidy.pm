# 4C3JHOH1:  XML::Tidy.pm by Pip Stuart <Pip@CPAN.Org> to tidy indenting of XML documents as parsed XML::XPath objects;
package      XML::Tidy;
use strict;use warnings;use utf8;
require                 Exporter;
require      XML::XPath;
use base qw( XML::XPath Exporter );
use vars qw( $AUTOLOAD @EXPORT   );
use          XML::XPath::XMLParser;
use Carp;
use Math::BaseCnv qw(:b64);
our $VERSION='1.20';our $d8VS='H79M9hU8';
@EXPORT = qw(
    UNKNOWN_NODE
    ELEMENT_NODE
    ATTRIBUTE_NODE
    TEXT_NODE
    CDATA_SECTION_NODE
    ENTITY_REFERENCE_NODE
    ENTITY_NODE
    PROCESSING_INSTRUCTION_NODE
    COMMENT_NODE
    DOCUMENT_NODE
    DOCUMENT_TYPE_NODE
    DOCUMENT_FRAGMENT_NODE
    NOTATION_NODE
    ELEMENT_DECL_NODE
    ATT_DEF_NODE
    XML_DECL_NODE
    ATTLIST_DECL_NODE
    NAMESPACE_NODE
    STANDARD_XML_DECL);
sub UNKNOWN_NODE                () { 0;}
sub ELEMENT_NODE                () { 1;}
sub ATTRIBUTE_NODE              () { 2;}
sub TEXT_NODE                   () { 3;}
sub CDATA_SECTION_NODE          () { 4;}
sub ENTITY_REFERENCE_NODE       () { 5;}
sub ENTITY_NODE                 () { 6;}
sub PROCESSING_INSTRUCTION_NODE () { 7;}
sub COMMENT_NODE                () { 8;}
sub DOCUMENT_NODE               () { 9;}
sub DOCUMENT_TYPE_NODE          () {10;}
sub DOCUMENT_FRAGMENT_NODE      () {11;}
sub NOTATION_NODE               () {12;}
sub ELEMENT_DECL_NODE           () {13;} # Non core DOM stuff here down
sub ATT_DEF_NODE                () {14;}
sub XML_DECL_NODE               () {15;}
sub ATTLIST_DECL_NODE           () {16;}
sub NAMESPACE_NODE              () {17;}
my  $xmld = qq(<?xml version="1.0" encoding="utf-8"?>\n); # Standard XML Declaration
sub STANDARD_XML_DECL           () {$xmld;}
sub new{my $clas = shift();my $xpob = undef;my $dtst=''; # try to also TeST Declar8ions
  if   (lc($_[0]) eq   'binary' && @_ > 1 && length($_[1]) && -r $_[1]){$xpob = bexpand($_[1]);}
  elsif(   $_[0] =~ /\.xtb$/i                                         ){$xpob = bexpand(@_   );}
  else                                                                 {$xpob = XML::XPath->new(@_);
    if    ($_[0]  eq 'filename'                                       ){shift(          @_   );}
    if    ($_[0] !~ /\n/ && -r "$_[0]"){ # special-case loading XML file with non-standard declaration (but doesn't handle inline XML data or IORef yet)
      open(my $xmlf,'<',$_[0]) or croak "!*EROR*! Cannot open  XML file $_[0]! $!\n";
      while( <$xmlf>){$dtst.= $_ if($dtst !~ /<\?xml\s+version=.+?\?>/i);} # try to load until decl formed (should almost always be just first line)
      close(  $xmlf)           or croak "!*EROR*! Cannot close XML file $_[0]! $!\n";$xmld =~ s/(\?>).*/$1\n/ if(defined($xmld));
    }elsif($_[0]  eq      'xml' && @_ > 1 && length($_[1]) ){$dtst=$1 if($_[1]=~ /(<\?xml\s+version=.+?\?>\s*?\n)/i);
    }elsif($_[0]  =~     /(<\?xml\s+version=.+?\?>\s*?\n)/i){$dtst=$1;
    } #else{} # maybe also try to handle ioref or context here by consulting above crE8d XPath obj?
    $xmld=$dtst      if($dtst =~ /^<\?xml\s+version="[^"]+"\s+encoding="[^"]+"(\s+standalone="(yes|no)")?\s*\?>\n$/i);
  } # if provided XML Declaration above doesn't seem well-formed, then just leave the default as a good standard
  my $self = bless($xpob, $clas); return($self);} # self just a new XPath obj blessed into Tidy class
sub reload{my $self = shift(); # dump XML text && re-parse object to re-index all nodes cleanly
  if(defined($self)){
    my($root)= $self->findnodes('/');
    my $data = $xmld;
       $data.= $_->toString() for($root->getChildNodes());
    $self->set_xml($data);
    my $prsr = XML::XPath::XMLParser->new('xml' => $data);
    $self->set_context($prsr->parse());}}
sub strip{my $self = shift(); # strips out all text nodes from any mixed content
  if(defined($self)){
    my  @nodz = $self->findnodes('//*');
    for(@nodz){
      if    (   $_->getNodeType() eq ELEMENT_NODE){my @kidz = $_->getChildNodes();
        for my $kidd (@kidz){
          if($kidd->getNodeType() eq TEXT_NODE && @kidz > 1 && $kidd->getValue() =~ /^\s*$/){
            $kidd->setValue('');}}}} # empty them all out
    $self->reload();}} # reload all XML as text to re-index nodes
sub tidy{ # tidy XML indenting with a specified indent string
  my $self = shift();my $ndnt = shift() || '  ';
  $ndnt = "\t" if($ndnt =~ /tab/i ); # allow some indent_type descriptions
  $ndnt = '  ' if($ndnt =~ /spac/i);
  if(defined($self)){
    $self->strip(); # strips all object's text nodes from mixed content
    my $dpth = 0; # keep track of element nest depth
    my $orte = 0 ;my $nrte = 0 ; # old && new  root elements
    my $prre = '';my $pore = ''; # pre && post root element text
    my($docu)= $self->findnodes('/');
    for($docu->getChildNodes()){
      if   ($_->getNodeType == ELEMENT_NODE){$orte  = $_;            }
      elsif(!$orte                         ){$prre .= $_->toString();}
      else                                  {$pore .= $_->toString();}}
    (  $orte)= $self->findnodes('/*') unless($orte);
    if($orte->getChildNodes()){ # recursively tidy children
      $nrte  = $self->_rectidy($orte, ($dpth + 1), $ndnt);}
    my $data = $xmld . $prre . $nrte->toString() . $pore;
    $self->set_xml($data);
    my $prsr = XML::XPath::XMLParser->new('xml' => $data);
    $self->set_context($prsr->parse());}}
sub _rectidy{ # recursively tidy up indent formatting of elements
  my $self = shift();my $node = shift();
  my $dpth = shift();my $ndnt = shift();
  my $tnod = undef; # temporary node which will get nodes surrounding children
  #$tnod = e($node->getName()); # create element
  $tnod = XML::XPath::Node::Element->new($node->getName()); # create element
  for($node->findnodes('@*')){ # copy all attributes
    $tnod->appendAttribute($_);}
  for($node->getNamespaces()){ # copy all namespaces
    $tnod->appendNamespace($_);}
  my @kidz = $node->getChildNodes();my $lkid;
  for my $kidd (@kidz){
    if($kidd->getNodeType() ne TEXT_NODE && (!$lkid ||
       $lkid->getNodeType() ne TEXT_NODE)){
      #$tnod->appendChild(t("\n" . ($ndnt x $dpth)));
      $tnod->appendChild(XML::XPath::Node::Text->new("\n" . ($ndnt x $dpth)));}
    if($kidd->getNodeType() eq ELEMENT_NODE){
      my @gkdz = $kidd->getChildNodes();
      if(@gkdz    && ($gkdz[0]->getNodeType() ne TEXT_NODE ||
        (@gkdz > 1 && $gkdz[1]->getNodeType() ne TEXT_NODE))){
        $kidd = $self->_rectidy($kidd, ($dpth + 1), $ndnt);}} # recursively tidy
    $tnod->appendChild($kidd);$lkid = $kidd;}
  #$tnod->appendChild(t("\n" . ($ndnt x ($dpth - 1))));
  $tnod->appendChild(XML::XPath::Node::Text->new("\n" . ($ndnt x ($dpth - 1))));
  return($tnod);}
sub compress{ # compress an XML::Tidy object into look-up tables
  my $self = shift();my $flgz = shift(); # options of node types to include
  my @elut =      ();my @alut =      (); # element && attribute look-up-tables
  my %efou =      ();my %afou =      (); # element && attribute found flags
  my @vlut =      ();my @tlut =      (); # attribute value && text
  my %vfou =      ();my %tfou =      ();
  my @nlut =      ();my @clut =      (); # namespace && comment
  my %nfou =      ();my %cfou =      ();
  my $cstr = "XML::Tidy::compress v$VERSION";
  my $ntok = qr/[\(\)\[\]\{\}\/\*\+\?]/; # non-token quoted regex
  $flgz = 'ea'     unless(defined($flgz)); # Default flags: just elemz && attrz
  $flgz = 'eatvnc' if($flgz eq 'all'); # AttValz && Text seem to work alright but beware of bugs in Comment I haven't been able to squash yet.
  $self->strip(); # remove non-data text nodes
  my($root)= $self->findnodes('/');
  for($root->findnodes('//comment()')){
    my $text = $_->getNodeValue();
    if($text =~ s/^XML::Tidy::compress v(\d+)\.(\d+)\.([0-9A-Za-z._]{7})//){
      croak "!*EROR*! compress() cannot be performed twice on the same object!\n";}}
  if($flgz =~ /e[^E]*$/){ # elements
    for($root->findnodes('//*')){
      my $name = $_->getName();
      unless(exists($efou{$name})){
        push(@elut, $name);$efou{$name} = $#elut;}
            # 5 below is the index of XML::XPath::Node::Element's node_name field
      ${$_}->[5] = 'e' . b64($efou{$name});} # $_->setName(...
    $cstr .= "\ne:@elut" if(@elut);}
  if($flgz =~ /(a[^A]*|v[^V]*)$/){ # attributes (keys or values)
    for($root->findnodes('//@*')){
      if($flgz =~ /a[^A]*$/){ # attribute keys
        my $name = $_->getName();
        if(exists($efou{$name})){ # reuse element keys matching attributes
                # 4 is the index of XML::XPath::Node::Attribute's node_key   field
          ${$_}->[4] = 'e' . b64($efou{$name});} # $_->setName(...
        else{
          unless(exists($afou{$name})){
            push(@alut, $name);$afou{$name} = $#alut;}
          ${$_}->[4] = 'a' . b64($afou{$name});}} # $_->setName(...
      if($flgz =~ /v[^V]*$/){ # attribute values
        my $wval = $_->getNodeValue(); $wval = '' unless(defined($wval));
        for my $valu (split(/\s+/, $wval)){
          my $repl = '';
          if    (exists($efou{$valu})){ # reuse elem keys matching attr valz
            $repl = 'e' . b64($efou{$valu});
          }elsif(exists($afou{$valu})){ # reuse attr keys matching attr valz
            $repl = 'a' . b64($afou{$valu});
          }elsif($valu !~ $ntok){
            unless(exists($vfou{$valu})){
              push(@vlut, $valu);$vfou{$valu} = $#vlut;}
            $repl = 'v' . b64($vfou{$valu});}
                # 5 is the index of XML::XPath::Node::Attribute's node_value field
          ${$_}->[5] =~ s/(^|\s+)$valu(\s+|$)/$1$repl$2/g if($valu !~ $ntok);}}}
    $cstr .= "\na:@alut" if(@alut);
    $cstr .= "\nv:@vlut" if(@vlut);}
  if($flgz =~ /t[^T]*$/){ # text
    for($root->findnodes('//text()')){
      my $wtxt = $_->getNodeValue();
      for my $text (split(/\s+/, $wtxt)){
        my $repl = '';
        if    (exists($efou{$text})){ # reuse elem keys matching text token
          $repl = 'e' . b64($efou{$text});
        }elsif(exists($afou{$text})){ # reuse attr keys matching text token
          $repl = 'a' . b64($afou{$text});
        }elsif(exists($afou{$text})){ # reuse attr valz matching text token
          $repl = 'v' . b64($vfou{$text});
        }elsif($text !~ $ntok){
          unless(exists($tfou{$text})){
            push(@tlut, $text);$tfou{$text} = $#tlut;}
          $repl = 't' . b64($tfou{$text});}
              # 3 is the index of XML::XPath::Node::Text's node_text field
        ${$_}->[3] =~ s/(^|\s+)$text(\s+|$)/$1$repl$2/g if($text !~ $ntok);}}
    $cstr .= "\nt:@tlut" if(@tlut);}
  if($flgz =~ /c[^C]*$/){ # comment
    for($root->findnodes('//comment()')){
      my $wcmt = $_->getNodeValue();
      for my $cmnt (split(/\s+/, $wcmt)){
        my $repl = '';
        if    (exists($efou{$cmnt})){ # reuse elem keys matching cmnt token
          $repl = 'e' . b64($efou{$cmnt});
        }elsif(exists($afou{$cmnt})){ # reuse attr keys matching cmnt token
          $repl = 'a' . b64($afou{$cmnt});
        }elsif(exists($afou{$cmnt})){ # reuse attr valz matching cmnt token
          $repl = 'v' . b64($vfou{$cmnt});
        }elsif(exists($tfou{$cmnt})){ # reuse text valz matching cmnt token
          $repl = 't' . b64($tfou{$cmnt});
        }elsif($cmnt !~ $ntok){
          unless(exists($cfou{$cmnt})){
            push(@clut, $cmnt);$cfou{$cmnt} = $#clut;}
          $repl = 'c' . b64($cfou{$cmnt});}
              # 3 is the index of XML::XPath::Node::Comment's node_comment field
        ${$_}->[3] =~ s/(^|\s+)$cmnt(\s+|$)/$1$repl$2/g if($cmnt !~ $ntok);}}
    $cstr .= "\nc:@clut" if(@clut);}
  $root->appendChild($self->c($cstr));
  $self->reload();}
sub expand{ # uncompress an XML::Tidy object from look-up tables
  my $self = shift();my $flgz = shift(); # options of node types to include
  my @elut =      ();my @alut =      (); # element && attribute look-up-tables
  my @vlut =      ();my @tlut =      (); # attribute value && text
  my @nlut =      ();my @clut =      (); # namespace && comment
  my $ntok = qr/[\(\)\[\]\{\}\/\*\+\?]/; # non-token quoted regex
  my($root)= $self->findnodes('/');
  for($root->findnodes('//comment()')){
    my $text = $_->getNodeValue();
    if($text =~ s/^XML::Tidy::compress v(\d+)\.(\d+)\.([0-9A-Za-z._]{7})//){ # may need to test $1, $2, $3 for versions later
      while($text =~ s/^\n([eatvnc]):([^\n]+)//){
        my $ntyp = $1;my $lutd = $2;
        if    ($ntyp eq 'e'){
          push(@elut, split(/\s+/, $lutd));
        }elsif($ntyp eq 'a'){
          push(@alut, split(/\s+/, $lutd));
        }elsif($ntyp eq 't'){
          push(@tlut, split(/\s+/, $lutd));
        }elsif($ntyp eq 'v'){
          push(@vlut, split(/\s+/, $lutd));
        }elsif($ntyp eq 'n'){
        # push(@nlut, split(/\s+/, $lutd));
        }elsif($ntyp eq 'c'){
          push(@clut, split(/\s+/, $lutd));}}
      $root->removeChild($_);}}
  if(@elut){
    for($root->findnodes('//*')){
      my $name = $_->getName();
      my $coun = $name;
      if($coun =~ s/^e// && b10($coun) < @elut){
        $coun = b10($coun);
              # 5 below is the index of XML::XPath::Node::Element's node_name field
        ${$_}->[5] = $elut[$coun];} # $_->setName($elut[$coun]);
      else{croak "!*EROR*! expand() cannot find look-up element:$name!\n";}}}
  if(@alut){
    for($root->findnodes('//@*')){
      my $name = $_->getName();
      my $coun = $name;
      if    ($coun =~ s/^e// && b10($coun) < @elut){
        $coun = b10($coun);
              # 4 below is the index of XML::XPath::Node::Attribute's node_key field
        ${$_}->[4] = $elut[$coun]; # $_->setName($elut[$coun]);
      }elsif($coun =~ s/^a// && b10($coun) < @alut){
        $coun = b10($coun);
        ${$_}->[4] = $alut[$coun]; # $_->setName($alut[$coun]);
      }else{croak "!*EROR*! expand() cannot find look-up attribute key:$name!\n";}
      if(@vlut){
        my $wval = $_->getNodeValue();
        for my $valu (split(/\s+/, $wval)){
          unless($valu =~ $ntok){
            $coun = $valu;
            if    ($coun =~ s/^e// && b10($coun) < @elut){
              $coun = b10($coun);
              # 5 is the index of XML::XPath::Node::Attribute's node_value field
              ${$_}->[5] =~ s/(^|\s+)$valu(\s+|$)/$1$elut[$coun]$2/g;
            }elsif($coun =~ s/^a// && b10($coun) < @alut){
              $coun = b10($coun);
              ${$_}->[5] =~ s/(^|\s+)$valu(\s+|$)/$1$alut[$coun]$2/g;
            }elsif($coun =~ s/^v// && b10($coun) < @vlut){
              $coun = b10($coun);
              ${$_}->[5] =~ s/(^|\s+)$valu(\s+|$)/$1$vlut[$coun]$2/g;
            }else{croak "!*EROR*! expand() cannot find look-up attribute value:$valu!\n";}}}}}}
  if(@tlut){
    for($root->findnodes('//text()')){
      my $wtxt = $_->getNodeValue();
      for my $text (split(/\s+/, $wtxt)){
        unless($text =~ $ntok){
          my $coun = $text;
          if    ($coun =~ s/^e// && b10($coun) < @elut){
            $coun = b10($coun);
                  # 3 is the index of XML::XPath::Node::Text's node_text field
            ${$_}->[3] =~ s/(^|\s+)$text(\s+|$)/$1$elut[$coun]$2/g;
          }elsif($coun =~ s/^a// && b10($coun) < @alut){
            $coun = b10($coun);
            ${$_}->[3] =~ s/(^|\s+)$text(\s+|$)/$1$alut[$coun]$2/g;
          }elsif($coun =~ s/^t// && b10($coun) < @tlut){
            $coun = b10($coun);
            ${$_}->[3] =~ s/(^|\s+)$text(\s+|$)/$1$tlut[$coun]$2/g;
          }elsif($coun =~ s/^v// && b10($coun) < @vlut){
            $coun = b10($coun);
            ${$_}->[3] =~ s/(^|\s+)$text(\s+|$)/$1$vlut[$coun]$2/g;
          }else{croak "!*EROR*! expand() cannot find look-up text token:$text!\n";}}}}}
  if(@clut){
    for($root->findnodes('//comment()')){
      my $wcmt = $_->getNodeValue();
      for my $cmnt (split(/\s+/, $wcmt)){
        unless($cmnt =~ $ntok){
          my $coun = $cmnt;
          if    ($coun =~ s/^e// && b10($coun) < @elut){
            $coun = b10($coun);
                  # 3 is the index of XML::XPath::Node::Comment's node_comment field
            ${$_}->[3] =~ s/(^|\s+)$cmnt(\s+|$)/$1$elut[$coun]$2/g;
          }elsif($coun =~ s/^a// && b10($coun) < @alut){
            $coun = b10($coun);
            ${$_}->[3] =~ s/(^|\s+)$cmnt(\s+|$)/$1$alut[$coun]$2/g;
          }elsif($coun =~ s/^v// && b10($coun) < @vlut){
            $coun = b10($coun);
            ${$_}->[3] =~ s/(^|\s+)$cmnt(\s+|$)/$1$vlut[$coun]$2/g;
          }elsif($coun =~ s/^t// && b10($coun) < @tlut){
            $coun = b10($coun);
            ${$_}->[3] =~ s/(^|\s+)$cmnt(\s+|$)/$1$tlut[$coun]$2/g;
          }elsif($coun =~ s/^c// && b10($coun) < @clut){
            $coun = b10($coun);
            ${$_}->[3] =~ s/(^|\s+)$cmnt(\s+|$)/$1$clut[$coun]$2/g;
          }else{croak "!*EROR*! expand() cannot find look-up comment token:$cmnt!\n";}}}}}
  $self->reload();
  $self->tidy();}
sub _append_node{ # place a node at the end of the proper array for bcompress
  my $strz = shift();my $flut = shift();
  my $intz = shift();my $fltz = shift();
  my $ndty = shift();my $node = shift();
  my $tokn =      '';my $aval = undef; # token key && attribute value strings
  if    (   ${$node}->getNodeType() ==                ELEMENT_NODE){
    $tokn = ${$node}->getName();
  }elsif(   ${$node}->getNodeType() ==              ATTRIBUTE_NODE){
    $tokn = ${$node}->getName();      # attribute keys
    $aval = ${$node}->getNodeValue(); # attribute values
    $aval = '' unless(defined($aval));
  }elsif(   ${$node}->getNodeType() ==              NAMESPACE_NODE){
    $tokn = ${$node}->toString();     # namespace prefix && expanded
  }elsif(   ${$node}->getNodeType() == PROCESSING_INSTRUCTION_NODE){
    $tokn = ${$node}->getTarget();    # PI target
    $aval = ${$node}->getData();      # PI data
    $aval = '' unless(defined($aval));
  }else{ # text, comment
    $tokn = ${$node}->getNodeValue();}
  if(defined($tokn) && length($tokn)){
    unless(exists($flut->{$tokn})){
      if    ($tokn =~ /^([+-]?\d+)$/ && # unsigned 4294967295
              -2147483648 <= $tokn && $tokn <= 2147483647){
        push(@{$intz}, $tokn);
        $flut->{$tokn} = 'l' . (scalar(@{$intz}) - 1);
      }elsif($tokn =~ /^[+-]?\d+\.\d+$/){ # [+-]1.7x10**-308..[+-]1.7x10**308
        push(@{$fltz}, $tokn);
        $flut->{$tokn} = 'd' . (scalar(@{$fltz}) - 1);
      }else{
        push(@{$strz}, $tokn);
        $flut->{$tokn} =       (scalar(@{$strz}) - 1);}}}
  if(defined($aval) && length($aval)){
    unless(exists($flut->{$aval})){
      if    ($aval =~ /^([+-]?\d+)$/ && # unsigned 4294967295
              -2147483648 <= $aval && $aval <= 2147483647){
        push(@{$intz}, $aval);
        $flut->{$aval} = 'l' . (scalar(@{$intz}) - 1);
      }elsif($aval =~ /^[+-]?\d+\.\d+$/){ # [+-]1.7x10**-308..[+-]1.7x10**308
        push(@{$fltz}, $aval);
        $flut->{$aval} = 'd' . (scalar(@{$fltz}) - 1);
      }else{
        push(@{$strz}, $aval);
        $flut->{$aval} =       (scalar(@{$strz}) - 1);}}}
  if( defined($tokn)){
    if(length($tokn)){
      push(@{$ndty}, $flut->{$tokn}, ${$node}->getNodeType());
    }else{
      push(@{$ndty}, 1             , ${$node}->getNodeType());}}
  if( defined($aval)){
    if(length($aval)){
      push(@{$ndty}, $flut->{$aval});
    }else{
      push(@{$ndty}, 1             );}}
  if(${$node}->getNodeType() == ELEMENT_NODE){
    for(${$node}->getNamespaces()){
      _append_node($strz, $flut, $intz, $fltz, $ndty, \$_);} # load namespaces...
    for(${$node}->getAttributes()){
      _append_node($strz, $flut, $intz, $fltz, $ndty, \$_);} #   ...attributes && then child elements recursively
    for(${$node}->getChildNodes()){
      _append_node($strz, $flut, $intz, $fltz, $ndty, \$_);} # before adding an element-close tag to the node order
    push(@{$ndty}, 0);}}
sub bcompress{ # compress an XML::Tidy object into a binary representation
  my $self = shift();
  my $dstf = shift() || 'default.xtb';    # destination binary filename
  my $bstr = "XML::Tidy::bcompress v$VERSION\0";
  my @strz = ('</>', ''); # array of strings
  my @intz = (         ); # array of ints
  my @fltz = (         ); # array of floats
  my @ndty = (); # list of @strz indices && node types
  my %flut = ('</>' => 0, '' => 1); # found string lookup-table
  $self->strip(); # remove non-data text nodes
  my $bsiz = 1; my $bpak = 'C';
  my($root)= $self->findnodes('/');
  for($root->getChildNodes()){
    _append_node(\@strz, \%flut, \@intz, \@fltz, \@ndty, \$_);}
  my $nndx = @ndty;
  while($nndx >= 256){$nndx /= 256.0;$bsiz++  ;}
  if   ($bsiz == 2  ){$bpak  =   'S';          }
  elsif($bsiz >  2  ){$bpak  =   'L';$bsiz = 4;} # assume default XML declaration
  open(   DSTF,'>',$dstf) or croak "!*EROR*! Cannot open binary DSTF: $dstf for writing! $!\n";
  binmode(DSTF);
  print   DSTF $bstr;
  shift(@strz);shift(@strz); # element-close && empty-string are implied
  print   DSTF pack("C$bpak", $bsiz, scalar(@strz));
  print   DSTF       "$_\0"             for(@strz) ;
  print   DSTF pack( "$bpak",        scalar(@intz));
  print   DSTF pack('l',$_)             for(@intz) ;
  print   DSTF pack( "$bpak",        scalar(@fltz));
  print   DSTF pack('d',$_)             for(@fltz) ;
  while(@ndty){
    my $indx = shift(@ndty);
    if(defined($indx) && $indx){
      my $type = shift(@ndty);
      if(defined($type) && $type){
        if    ($indx =~ s/^d//){
          print DSTF pack("$bpak", (scalar(@strz) + scalar(@intz) + $indx + 2));
        }elsif($indx =~ s/^l//){
          print DSTF pack("$bpak", (scalar(@strz) + $indx + 2));
        }else{
          print DSTF pack("$bpak", $indx);}
        print   DSTF pack('C', $type);
        if($type ==              ATTRIBUTE_NODE ||
           $type == PROCESSING_INSTRUCTION_NODE){
          $indx = shift(@ndty);
          if    ($indx =~ s/^d//){
            print DSTF pack("$bpak", (scalar(@strz) + scalar(@intz) + $indx + 2));
          }elsif($indx =~ s/^l//){
            print DSTF pack("$bpak", (scalar(@strz) + $indx + 2));
          }else{
            print DSTF pack("$bpak", $indx);}}}
    }else{
      print DSTF pack("$bpak", 0);}}
  close(    DSTF);}
sub bexpand{ # uncompress a binary file back into an XML::Tidy object
  my $self = shift();
  my $srcf = shift() || 'default.xtb';    # source binary filename
  my $srcd = undef;
  my $cstr = undef;
  my $bstr = "XML::Tidy::bcompress v$VERSION\0";
  my $gxml = ''; # generated XML for new object
  my @strz = ('</>', ''); # array of strings
  my @intz = (         ); # array of ints
  my @fltz = (         ); # array of floats
  my @ndty = (); # list of @strz indices && node types
  my @elst = (); # element stack to track tree reconstruction
  my $bsiz = 1; my $bpak = 'C'; my $rnam = ''; my $coun = 0;
  if(-r $srcf){
    open(   SRCF,'<',$srcf) or croak "!*EROR*! Cannot open binary SRCF: $srcf for reading! $!\n";
    binmode(SRCF);   $srcd = join('',<SRCF>);
    close(  SRCF);
    $cstr = substr($srcd, 0, length($bstr), '');
    $bsiz = unpack('C', substr($srcd, 0, 1, ''));
    if   ($bsiz == 2){$bpak = 'S';}
    elsif($bsiz >  2){$bpak = 'L';$bsiz = 4;}
    $coun = unpack("$bpak", substr($srcd, 0, $bsiz, ''));
    while($coun--){
      push(@strz, '');
      my $char = unpack('a', substr($srcd, 0, 1, ''));
      while($char ne "\0"){
        $strz[-1] .= $char;
        $char = unpack('a', substr($srcd, 0, 1, ''));}}
    $coun = unpack("$bpak", substr($srcd, 0, $bsiz, ''));
    while($coun--){
      push(@intz, unpack('l', substr($srcd, 0, 4, '')));}
    $coun = unpack("$bpak", substr($srcd, 0, $bsiz, ''));
    while($coun--){
      push(@fltz, unpack('d', substr($srcd, 0, 8, '')));} #$fltz[-1] .= '.0' if($fltz[-1] !~ /\./); # mk floats look like floats?
    while(length($srcd)){
      push(@ndty, unpack("$bpak", substr($srcd, 0, $bsiz, '')));
      if($ndty[-1]){
        push(@ndty, unpack('C'    , substr($srcd, 0, 1,     '')));
        $rnam = $strz[$ndty[-2]] if(!length($rnam) && $ndty[-1] == ELEMENT_NODE);
        if($ndty[-1] ==              ATTRIBUTE_NODE ||
           $ndty[-1] == PROCESSING_INSTRUCTION_NODE){
          push(@ndty, unpack("$bpak", substr($srcd, 0, $bsiz, '')));}}}
    my $opfl = 0;
    @elst = (); $gxml = $xmld;
    while(@ndty){
      my $indx = shift(@ndty);my $vndx;
      my $type = ELEMENT_NODE;   $type = shift(@ndty) if($indx);
      if    ($type ==                ELEMENT_NODE){
        $gxml .= '>' if($opfl);
        if($indx == 0){ # close element
          $gxml .= '</' . pop(@elst) . '>';
          $opfl = 0;
        }else{
          push(@elst, $strz[$indx]);
          $gxml .= '<' . $strz[$indx];
          $opfl = 1;}
      }elsif($type ==              ATTRIBUTE_NODE){
        $vndx = shift(@ndty);
        if($opfl){
          $gxml .= ' ';
          if    ($indx >= (scalar(@strz) + scalar(@intz))){
            $gxml .= $fltz[($indx - scalar(@strz) - scalar(@intz))];
          }elsif($indx >=  scalar(@strz)                 ){
            $gxml .= $intz[($indx - scalar(@strz))];
          }else                                           {
            $gxml .= $strz[$indx];}
          $gxml .= '="';
          if    ($vndx >= (scalar(@strz) + scalar(@intz))){
            $gxml .= $fltz[($vndx - scalar(@strz) - scalar(@intz))];
          }elsif($vndx >=  scalar(@strz)                 ){
            $gxml .= $intz[($vndx - scalar(@strz))];
          }else                                           {
            $gxml .= $strz[$vndx];}
          $gxml .= '"';}
      }elsif($type ==                   TEXT_NODE){
        if($opfl) { $gxml .= '>'; $opfl = 0; }
        if    ($indx >= (scalar(@strz) + scalar(@intz))){
          $gxml .= $fltz[($indx - scalar(@strz) - scalar(@intz))];
        }elsif($indx >=  scalar(@strz)                 ){
          $gxml .= $intz[($indx - scalar(@strz))];
        }else                                           {
          $gxml .= $strz[$indx];}
      }elsif($type ==                COMMENT_NODE){
        if($opfl){$gxml .= '>'; $opfl = 0;}
        $gxml .= '<!--';
        if    ($indx >= (scalar(@strz) + scalar(@intz))){
          $gxml .= $fltz[($indx - scalar(@strz) - scalar(@intz))];
        }elsif($indx >=  scalar(@strz)                 ){
          $gxml .= $intz[($indx - scalar(@strz))];
        }else                                           {
          $gxml .= $strz[$indx];}
        $gxml .= '-->';
      }elsif($type == PROCESSING_INSTRUCTION_NODE){
        if($opfl){$gxml .= '>'; $opfl = 0;}
        $gxml .= '<?';
        if    ($indx >= (scalar(@strz) + scalar(@intz))){
          $gxml .= $fltz[($indx - scalar(@strz) - scalar(@intz))];
        }elsif($indx >=  scalar(@strz)                 ){
          $gxml .= $intz[($indx - scalar(@strz))];
        }else                                           {
          $gxml .= $strz[$indx];}
        $gxml .= ' ';
        $vndx = shift(@ndty);
        if    ($vndx >= (scalar(@strz) + scalar(@intz))){
          $gxml .= $fltz[($vndx - scalar(@strz) - scalar(@intz))];
        }elsif($vndx >=  scalar(@strz)                 ){
          $gxml .= $intz[($vndx - scalar(@strz))];
        }else                                           {
          $gxml .= $strz[$vndx];}
        $gxml .= '?>';
      }elsif($type ==              NAMESPACE_NODE){
        $gxml .= ' ' . $strz[$indx] if($opfl);}}
    my $nslf = XML::Tidy->new('xml' => "$gxml");
    #  $nslf->tidy(); # don't force a tidy() even if it's most likely desired
    return($nslf);}}
sub prune{ # remove a section of the tree at the xpath location parameter
  my $self = shift(); my $xplc = shift() || return(); # can't prune root node
  if(defined($xplc) && $xplc && $xplc =~ /^[-_]?(xplc$|xpath_loc)/){
     $xplc = shift() || undef;}
  if(defined($self) && defined($xplc) && length($xplc) && $xplc ne '/'){
    $self->reload(); # update all nodes && internal XPath indexing before find
    for($self->findnodes($xplc)){
      my $prnt = $_->getParentNode();
      $prnt->removeChild($_) if(defined($prnt));}}}
sub write{ # write out an XML file to disk from a Tidy object
  my $self = shift(); my $root; my $xplc;
  my $flnm = shift() || $self->get_filename();
  if(  defined($flnm) && $flnm){
    if($flnm =~ /^[-_]?(xplc$|xpath_loc)/){
      $xplc = shift() || undef;
      $flnm = shift() || $self->get_filename();}
    if($flnm =~ /^[-_]?(flnm|filename)$/ ){
      $flnm = shift() || $self->get_filename();}}
  unless(defined($xplc) && $xplc){
    $xplc = shift() || undef;}
  if(  defined($xplc) && $xplc && $xplc =~ /^[-_]?(xplc$|xpath_loc)/){
    $xplc = shift() || undef;}
  if(  defined($self) && defined($flnm)){
    if(defined($xplc) && $xplc){
         $root = XML::XPath::Node::Element->new();
      my($rtnd)= $self->findnodes($xplc);
         $root->appendChild($rtnd);
    }else{
        ($root)= $self->findnodes('/');}
    open( FILE,'>:encoding(UTF-8)',$flnm) or croak "!*EROR*! Cannot open FILE: $flnm for writing! $!\n";
    print FILE $xmld;
    print FILE $_->toString() , "\n" for($root->getChildNodes());
    close(FILE);
  }else{
    croak("!*EROR*! No filename could be found to write() to!\n");}}
sub toString{ # return XML string from a Tidy object
  my $self = shift(); my $root;
  my $xplc = shift(); my $xmls = $xmld;
  if(  defined($xplc) && $xplc && $xplc =~ /^[-_]?(xplc$|xpath_loc)/){
    $xplc = shift() || undef;}
  if(  defined($self)){
    if(defined($xplc) && $xplc){
         $root = XML::XPath::Node::Element->new();
      my($rtnd)= $self->findnodes($xplc);
         $root->appendChild($rtnd);
    }else{
        ($root)= $self->findnodes('/'); # every call to this XPath findnodes('/') leaks memory! I think it's not my fault?
    }
    if(defined($root)){
      $xmls .= $_->toString() . "\n" for($root->getChildNodes());}
  }else{
    croak("!*EROR*! No XML::Tidy could be found for toString()!\n");}
  $xmls=~ s/\n$//; # strip final newline (maybe should check at load if there was a just newline text-node after root element close to leave it in?)
  return($xmls);}
sub AUTOLOAD{ # methods (created as necessary)
  no strict 'refs';
  my $self = shift();
  if($AUTOLOAD =~ /.*::(new|create)?([eactpn])/i){ # createNode Wrappers
    my $node = lc($2);
    *{$AUTOLOAD} = sub{ # add called sub to function table
      my $self = shift();
      if   ($node eq 'e'){return(XML::XPath::Node::Element  ->new(@_));}
      elsif($node eq 'a'){return(XML::XPath::Node::Attribute->new(@_));}
      elsif($node eq 'c'){return(XML::XPath::Node::Comment  ->new(@_));}
      elsif($node eq 't'){return(XML::XPath::Node::Text     ->new(@_));}
      elsif($node eq 'p'){return(XML::XPath::Node::PI       ->new(@_));}
      elsif($node eq 'n'){return(XML::XPath::Node::Namespace->new(@_));}
    };
    return($self->$AUTOLOAD(@_));
  }else{croak "No such method: $AUTOLOAD\n";}}
sub DESTROY{} # do nothing but define in case && to calm test warnings
8;

=encoding utf8

=head1 NAME

XML::Tidy - tidy indenting of XML documents

=head1 VERSION

This documentation refers to version 1.20 of XML::Tidy, which was released on
Sun Jul  9 09:43:30:08 -0500 2017.

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;use  warnings;
  use   utf8;use XML::Tidy;

  # create new   XML::Tidy object by loading:  MainFile.xml
  my $tidy_obj = XML::Tidy->new('filename' => 'MainFile.xml');

  #   tidy  up  the  indenting
     $tidy_obj->tidy();

  #             write out changes back     to  MainFile.xml
     $tidy_obj->write();

=head1 DESCRIPTION

This module creates XML document objects (with inheritance from
L<XML::XPath>) to tidy mixed-content (i.e., non-data) text node
indenting. There are also some other handy member functions to
compress and expand your XML document object (into either a
compact XML representation or a binary one).

=head1 USAGE

=head2 new()

This is the standard Tidy object constructor. Except for the added
'binary' option, it can take the same parameters as an L<XML::XPath>
object constructor to initialize the XML document object. These can
be any one of:

  'filename' => 'SomeFile.xml'
  'binary'   => 'SomeBinaryFile.xtb'
  'xml'      => $variable_which_holds_a_bunch_of_XML_data
  'ioref'    => $file_InputOutput_reference
  'context'  => $existing_node_at_specified_context_to_become_new_obj

=head2 reload()

The reload() member function causes the latest data contained in
a Tidy object to be re-parsed (which re-indexes all nodes).

This can be necessary after modifications have been made to nodes
which impact the tree node hierarchy because L<XML::XPath>'s find()
member preserves state information which can get out-of-sync.

reload() is probably rarely useful by itself but it is needed by
strip() and prune() so it is exposed as a method in case it comes in
handy for other uses.

=head2 strip()

The strip() member function searches the Tidy object for all
mixed-content (i.e., non-data) text nodes and empties them out.
This will basically unformat any markup indenting.

strip() is used by compress() and tidy() but it is exposed because it
is also worthwhile by itself.

=head2 tidy()

The tidy() member function can take a single optional parameter as
the string that should be inserted for each indent level. Some
examples:

  # Tidy up indenting with default two  (2) spaces per indent level
     $tidy_obj->tidy();

  # Tidy up indenting with         four (4) spaces per indent level
     $tidy_obj->tidy('    ');

  # Tidy up indenting with         one  (1) tab    per indent level
     $tidy_obj->tidy('tab' );

  # Tidy up indenting with         two  (2) tabs   per indent level
     $tidy_obj->tidy("\t\t");

The default behavior is to use two (2) spaces for each indent
level. The Tidy object gets all mixed-content (i.e., non-data)
text nodes reformatted to appropriate indent levels according to
tree nesting depth.

NOTE: tidy() disturbs some XML escapes in whatever ways L<XML::XPath>
does. It has been brought to my attention that these modules also strip
CDATA tags from XML files / data they operate on. Even though
CDATA tags don't seem very common, I would very much like for them to
work smoothly too. Hopefully the vast majority of files will work fine
and future support for any of the more rare types can be added later.

Additionally, please take notice that every call to tidy() (as well as
reload, strip, and most other XML::Tidy functions) leak some memory due
to their usage of XPath's findnodes command. This issue was described
helpfully at L<HTTPS://RT.CPAN.Org/Ticket/Display.html?id=120296>.
Thanks to Jozef!

=head2 compress()

The compress() member function calls strip() on the Tidy object
then creates an encoded comment which contains the names of elements
and attributes as they occurred in the original document. Their
respective element and attribute names are replaced with just the
appropriate index throughout the document.

compress() can accept a parameter describing which node types to
attempt to shrink down as abbreviations. This parameter should be
a string of just the first letters of each node type you wish to
include as in the following mapping:

  e = elements
  a = attribute   keys
  v = attribute values *EXPERIMENTAL*
  t = text       nodes *EXPERIMENTAL*
  c = comment    nodes *EXPERIMENTAL*
  n = namespace  nodes *not-yet-implemented*

Attribute values ('v') and text nodes ('t') both seem to work fine
with current tokenization. I've still labeled them EXPERIMENTAL
because they seem more likely to cause problems than valid element
or attribute key names. I have some bugs in the comment node
compression which I haven't been able to find yet so that one should
be avoided for now. Since these three node types ('vtc')
all require tokenization, they are not included in default compression
('ea'). An example call which includes values and text would be:

  $tidy_obj->compress('eavt');

The original document structure (i.e., node hierarchy) is preserved.
compress() significantly reduces the file size of most XML documents
for when size matters more than immediate human readability.
expand() performs the opposite conversion.

=head2 expand()

The expand() member function reads any XML::Tidy::compress comments
from the Tidy object and uses them to reconstruct the document
that was passed to compress().

=head2 bcompress('BinaryOutputFilename.xtb')

The bcompress() member function stores a binary representation of
any Tidy object. The format consists of:

  0) a null-terminated version string
  1) a byte specifying how many bytes later indices will be
  2) the number of bytes from 1 above to designate the total string  count
  3) the number of null-terminated          strings from 2 above
  4) the number of bytes from 1 above to designate the total integer count
  5) the number of 4-byte                  integers from 4 above
  6) the number of bytes from 1 above to designate the total float   count
  7) the number of 8-byte (double-precision) floats from 6 above
  8) node index sets until the end of the file

Normal node index sets consist of two values. The first is an index
(again the number of bytes long comes from 1) into the three lists as if
they were all linear. The second is a single-byte integer identifying the
node type (using standard DOM node type enumerations).

A few special cases exist in node index sets though. If the index is
null, it is interpreted as a close-element tag (so no accompanying type
value is read). On the other end, when the index is non-zero, the type
value is always read. In the event that the type corresponds to an
attribute or a processing instruction, the next index is read (without
another accompanying type value) in order to complete the data fields
required by those node types.

NOTE: Please bear in mind that the encoding of binary integers and floats
only works properly if the values are not surrounded by spaces or other
delimiters and each is contained in its own single node. This is
necessary to enable thorough reconstruction of whitespace from the
original document. I recommend storing every numerical value as an
isolated attribute value or text node without any surrounding whitespace.

  # Examples which encode all numbers as binary:
  <friend name="goodguy" category="15">
    <hitpoints>31.255</hitpoints>
    <location>
      <x>-15.65535</x>
      <y>16383.7</y>
      <z>-1023.63</z>
    </location>
  </friend>

  # Examples which encode all numbers as strings:
  <enemy name="badguy" category=" 666 ">
    <hitpoints> 2.0 </hitpoints>
    <location> 4.0 -2.0 4.0 </location>
  </enemy>

The default file extension is .xtb (for XML::Tidy Binary).

=head2 bexpand('BinaryInputFilename.xtb')

The bexpand() member function reads a binary file which was
previously written from bcompress(). bexpand() is an XML::Tidy
object constructor like new() so it can be called like:

  my $xtbo = XML::Tidy->bexpand('BinaryInputFilename.xtb');

=head2 prune()

The prune() member function takes an XPath location to remove (along
with all attributes and child nodes) from the Tidy object. For
example, to remove all comments:

  $tidy_obj->prune('//comment()');

or to remove the third baz (XPath indexing is 1-based):

  $tidy_obj->prune('/foo/bar/baz[3]');

Pruning your XML tree is a form of tidying too so it snuck in here. =)

=head2 write()

The write() member function can take an optional filename parameter
to write out any changes to the Tidy object. If no parameters
are given, write() overwrites the original XML document file (if
a 'filename' parameter was given to the constructor).

write() will croak() if no filename can be found to write to.

write() can also take a secondary parameter which specifies an XPath
location to be written out as the new root element instead of the
Tidy object's root. Only the first matching element is written.

=head2 toString()

The toString() member function is almost identical to write() except
that it takes no parameters and simply returns the equivalent XML
string as a scalar. It is a little weird because normally only
L<XML::XPath::Node> objects have a toString() member but I figure it
makes sense to extend the same syntax to the parent object as well,
since it is a useful option.

=head1 createNode Wrappers

The following are just aliases to Node constructors. They'll work with
just the unique portion of the node type as the member function name.

=head2 e() or el() or elem() or createElement()

wrapper for XML::XPath::Node::Element->new()

=head2 a() or at() or attr() or createAttribute()

wrapper for XML::XPath::Node::Attribute->new()

=head2 c() or cm() or cmnt() or createComment()

wrapper for XML::XPath::Node::Comment->new()

=head2 t() or tx() or text() or createTextNode()

wrapper for XML::XPath::Node::Text->new()

=head2 p() or pi() or proc() or createProcessingInstruction()

wrapper for XML::XPath::Node::PI->new()

=head2 n() or ns() or nspc() or createNamespace()

wrapper for XML::XPath::Node::Namespace->new()

=head1 EXPORTED CONSTANTS

Since they are sometimes needed to compare against, XML::Tidy also
exports the same node constants as L<XML::XPath::Node> (which
correspond to DOM values). These include:

=head2 UNKNOWN_NODE

=head2 ELEMENT_NODE

=head2 ATTRIBUTE_NODE

=head2 TEXT_NODE

=head2 CDATA_SECTION_NODE

=head2 ENTITY_REFERENCE_NODE

=head2 ENTITY_NODE

=head2 PROCESSING_INSTRUCTION_NODE

=head2 COMMENT_NODE

=head2 DOCUMENT_NODE

=head2 DOCUMENT_TYPE_NODE

=head2 DOCUMENT_FRAGMENT_NODE

=head2 NOTATION_NODE

=head2 ELEMENT_DECL_NODE

=head2 ATT_DEF_NODE

=head2 XML_DECL_NODE

=head2 ATTLIST_DECL_NODE

=head2 NAMESPACE_NODE

XML::Tidy also exports:

=head2 STANDARD_XML_DECL

which returns a reasonable default XML declaration string
(assuming typical "utf-8" encoding).

=head1 TODO

=over 2

=item - fix reload() from messing up Unicode escaped &XYZ; components like Copyright &#xA9; and Registered &#xAE; (probably needs pre and post processing)

=item - write many better UTF-8 tests

=item - support namespaces

=item - handle CDATA

=back

=head1 CHANGES

Revision history for Perl extension XML::Tidy:

=over 2

=item - 1.20 H79M9hU8  Sun Jul  9 09:43:30:08 -0500 2017

* removed broken Build.PL         to resolve L<HTTPS://RT.CPAN.Org/Ticket/Display.html?id=122406>. (Thank you,   Slaven.)

=item - 1.18 H78M5qm1  Sat Jul  8 05:52:48:01 -0500 2017

* fixed new() to check file or xml to detect standalone in declaration, from L<HTTPS://RT.CPAN.Org/Ticket/Display.html?id=122389> (Thanks Alex!)

* traced tidy() memory leak from L<HTTPS://RT.CPAN.Org/Ticket/Display.html?id=120296> (Thanks Jozef!) which seems to come from every XPath->findnodes() call

* aligned synopsis comments

* updated write() to use output encoding UTF-8 since that's what almost all XML should rely on (with thanks to RJBS for teaching me much from his great talk at
L<HTTPS://YouTube.Com/watch?v=TmTeXcEixEg>)

* collapsed trailing curly braces on code blocks

* added croak for any failed file open attempt

=item - 1.16 G6LM4EST  Tue Jun 21 04:14:28:29 -0500 2016

* stopped using my old fragile package generation and manually updated all distribution files (though L<Dist::Zilla> should let me generate much again)

* updated license to GPLv3+

* fixed 00pod.t and 01podc.t to eval the Test modules from issue and patch: L<HTTPS://RT.CPAN.Org/Public/Bug/Display.html?id=85592> (Thanks again MichielB.)

* replaced all old '&&' with 'and' in POD

=item - 1.14 G6JMERCY  Sun Jun 19 14:27:12:34 -0500 2016

* separated old PT from VERSION to fix non-numeric issue: L<HTTPS://RT.CPAN.Org/Public/Bug/Display.html?id=56073> (Thanks to Slaven.)

* removed Unicode from POD but added encoding utf8 anyway to pass tests and resolve issues: L<HTTPS://RT.CPAN.Org/Public/Bug/Display.html?id=92434> and
L<HTTPS://RT.CPAN.Org/Public/Bug/Display.html?id=85592> (Thanks to Sudhanshu and MichielB.)

=item - 1.12.B55J2qn  Thu May  5 19:02:52:49 2011

* made "1.0" float binarize as float again, rather than just "1" int

* cleaned up POD and fixed EXPORTED CONSTANTS heads blocking together

=item - 1.10.B52FpLx  Mon May  2 15:51:21:59 2011

* added tests for undefined non-standard XML declaration to suppress warnings

=item - 1.8.B2AMvdl  Thu Feb 10 22:57:39:47 2011

* aligned .t code

* added test for newline before -r to try to resolve: L<HTTPS://RT.CPAN.Org/Ticket/Display.html?id=65471> (Thanks, Leandro.)

* fixed off-by-one error when new gets a readable (non-newline) filename (that's not "filename" without a pre-'filename' param) to resolve:
L<HTTPS://RT.CPAN.Org/Ticket/Display.html?id=65151> (Thanks, Simone.)

=item - 1.6.A7RJKwl  Tue Jul 27 19:20:58:47 2010

* added head2 POD for EXPORTED CONSTANTS to try to pass t/00podc.t

=item - 1.4.A7QCvHw  Mon Jul 26 12:57:17:58 2010

* hacked a little test for non-UTF-8 decl str to resolve FrankGoss' need for ISO-8859-1 decl encoding to persist through tidying

* md sure META.yml is being generated correctly for the CPAN

* updated license to GPLv3

=item - 1.2.75BACCB  Fri May 11 10:12:12:11 2007

* made "1.0" float binarize as just "1" int

* made ints signed and bounds checked

* added new('binary' => 'BinFilename.xtb') option

=item - 1.2.54HJnFa  Sun Apr 17 19:49:15:36 2005

* fixed tidy() processing instruction stripping problem

* added support for binary ints and floats in bcompress()

* tightened up binary format and added pod

=item - 1.2.54HDR1G  Sun Apr 17 13:27:01:16 2005

* added bcompress() and bexpand()

* added  compress() and  expand()

* added toString()

=item - 1.2.4CKBHxt  Mon Dec 20 11:17:59:55 2004

* added exporting of XML::XPath::Node (DOM) constants

* added node object creation wrappers (like LibXML)

=item - 1.2.4CCJW4G  Sun Dec 12 19:32:04:16 2004

* added optional 'xpath_loc' => to prune()

=item - 1.0.4CAJna1  Fri Dec 10 19:49:36:01 2004

* added optional 'filename'  => to write()

=item - 1.0.4CAAf5B  Fri Dec 10 10:41:05:11 2004

* removed 2nd param from tidy() so that 1st param is just indent string

* fixed pod errors

=item - 1.0.4C9JpoP  Thu Dec  9 19:51:50:25 2004

* added xplc option to write()

* added prune()

=item - 1.0.4C8K1Ah  Wed Dec  8 20:01:10:43 2004

* inherited from XPath so that those methods can be called directly

* original version (separating Tidy.pm from Merge.pm)

=back

=head1 INSTALL

From the command shell, please run:

  `perl -MCPAN -e "install XML::Tidy"`

or uncompress the package and run the standard:

  `perl Makefile.PL; make; make test; make install`

=head1 FILES

XML::Tidy requires:

L<Carp>                  to allow errors to croak() from calling sub

L<XML::XPath>            to use XPath statements to query and update XML

L<XML::XPath::XMLParser> to parse XML documents into XPath objects

L<Math::BaseCnv>         to handle base-64 indexing for compress() and expand()

=head1 BUGS

Please report any bugs or feature requests to   bug-XML-Tidy          at RT.CPAN.Org, or through the web interface at
  L<HTTPS://RT.CPAN.Org/NoAuth/ReportBug.html?Queue=XML-Tidy>.          I will be notified, and then you can be updated of progress on your bug
  as I address fixes.

=head1 SUPPORT

You can find documentation for this module (after it is installed) with the perldoc command.

  `perldoc XML::Tidy`

You can also look for information at:

    RT: CPAN's Request Tracker

  HTTPS://RT.CPAN.Org/NoAuth/Bugs.html?Dist=XML-Tidy

    AnnoCPAN: Annotated CPAN documentation

  HTTP://AnnoCPAN.Org/dist/XML-Tidy

    CPAN Ratings

  HTTPS://CPANRatings.Perl.Org/d/XML-Tidy

    Search CPAN

  HTTP://Search.CPAN.Org/dist/XML-Tidy

=head1 LICENSE

Most source code should be Free! Code I have lawful authority over is and shall be!
Copyright: (c) 2004-2017, Pip Stuart.
Copyleft :  This software is licensed under the  GNU General Public License
  (version 3 or later). Please consult L<HTTPS://GNU.Org/licenses/gpl-3.0.txt>
  for important information about your freedom. This is Free Software: you
  are free to change and redistribute it. There is NO WARRANTY, to the
  extent permitted by law. See L<HTTPS://FSF.Org> for further information.

=head1 AUTHOR

Pip Stuart <Pip@CPAN.Org>

=cut
