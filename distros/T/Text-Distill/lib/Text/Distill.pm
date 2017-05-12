package Text::Distill;

use 5.006001;
use strict;
use warnings;
use Digest::JHash;
use XML::LibXML;
use XML::LibXSLT;
use Text::Extract::Word;
use HTML::TreeBuilder;
use OLE::Storage_Lite;
use Text::Unidecode v1.27;
use Unicode::Normalize v1.25;
use Encode::Detect;
use Encode;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Carp;
use LWP::UserAgent;
use JSON::XS;
use File::Temp;

Archive::Zip::setErrorHandler(sub{});

our (@ISA, @EXPORT_OK);
BEGIN {
  require Exporter;
  @ISA = qw(Exporter);
  @EXPORT_OK = qw(
    Distill
    LikeSoundex
    TextToGems
    DetectBookFormat
    ExtractSingleZipFile
    CheckIfTXT
    CheckIfFB2
    CheckIfFB3
    CheckIfDocx
    CheckIfEPub
    CheckIfDoc
    CheckIfTXTZip
    CheckIfFB2Zip
    CheckIfDocxZip
    CheckIfEPubZip
    CheckIfDocZip
    ExtractTextFromEPUBFile
    ExtractTextFromDOCXFile
    ExtractTextFromDocFile
    ExtractTextFromTXTFile
    ExtractTextFromFB2File
    ExtractTextFromFB3File
    GetFB2GemsFromFile
    GemsValidate
  );  # symbols to export on request
}

my $XSL_FB2_2_String = q{
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:fb="http://www.gribuser.ru/xml/fictionbook/2.0">
  <xsl:strip-space elements="*"/>
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:variable name="linebr"><xsl:text>&#010;</xsl:text></xsl:variable>
  <xsl:template match="/fb:FictionBook">
    <xsl:apply-templates select="fb:body"/>
  </xsl:template>
  <xsl:template match="fb:section|
                      fb:title|
                      fb:subtitle|
                      fb:p|
                      fb:epigraph|
                      fb:cite|
                      fb:text-author|
                      fb:date|
                      fb:poem|
                      fb:stanza|
                      fb:v|
                      fb:image[parent::fb:body]|
                      fb:code">
    <xsl:apply-templates/>
    <xsl:value-of select="$linebr"/>
  </xsl:template>
</xsl:stylesheet>};

my $XSL_FB3_2_String = q{
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:fb="http://www.fictionbook.org/FictionBook3/body"
  xmlns:fbd="http://www.fictionbook.org/FictionBook3/description">

  <xsl:strip-space elements="*"/>
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:variable name="linebr"><xsl:text>&#010;</xsl:text></xsl:variable>

  <xsl:template match="fb:subtitle|
                      fb:p|
                      fb:li|
                      fb:page-break-type">
    <xsl:apply-templates/>
    <xsl:value-of select="$linebr"/>
  </xsl:template>

  <xsl:template match="fbd:fb3-relations|fbd:fb3-classification" />

  <xsl:template match="fb:li">- <xsl:apply-templates/><xsl:value-of select="$linebr"/></xsl:template>
</xsl:stylesheet>};

my $XSL_Docx_2_Txt = q{
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <xsl:output method="text" />
  <xsl:template match="/">
    <xsl:apply-templates select="//w:body" />
  </xsl:template>
  <xsl:template match="w:body">
    <xsl:apply-templates />
  </xsl:template>
  <xsl:template match="w:p">
    <xsl:if test="w:pPr/w:spacing/@w:after=0"><xsl:text>&#13;&#10;</xsl:text></xsl:if>
    <xsl:apply-templates/><xsl:if test="position()!=last()"><xsl:text>&#13;&#10;</xsl:text></xsl:if>
  </xsl:template>
  <xsl:template match="w:r">
    <xsl:for-each select="w:t">
      <xsl:value-of select="." />
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
};

our $MinPartSize = 150;

# Гласные и прочие буквы \w, которые нас, тем не менее, не волнуют
my $SoundexExpendable = qr/уеёыаоэяиюьъaehiouwy/i;

# Статистически подобранные "буквосочетания", бьющие тексты на на куски по ~20к
# отбиралось по языкам: ru  en  it  de  fr  es  pl  be  cs  sp  lv
# в теории этот набор должен более-менее ровно нарезать любой текст на куски по ~2к
our @SplitChars = qw(3856 6542 4562 6383 4136 2856 4585 5512
  2483 5426 2654 3286 5856 4245 4135 4515 4534 8312 5822 5316 1255 8316 5842);


my @DetectionOrder = qw /epub.zip epub docx.zip docx doc.zip doc fb2.zip fb2 fb3 txt.zip txt/;

my $Detectors = {
  'fb2.zip'  => \&CheckIfFB2Zip,
  'fb2'      => \&CheckIfFB2,
  'fb3'      => \&CheckIfFB3,
  'doc.zip'  => \&CheckIfDocZip,
  'doc'      => \&CheckIfDoc,
  'docx.zip' => \&CheckIfDocxZip,
  'docx'     => \&CheckIfDocx,
  'epub.zip' => \&CheckIfEPubZip,
  'epub'     => \&CheckIfEPub,
  'txt.zip'  => \&CheckIfTXTZip,
  'txt'      => \&CheckIfTXT
};

our $Extractors = {
  'fb2'  => \&ExtractTextFromFB2File,
  'fb3'  => \&ExtractTextFromFB3File,
  'txt'  => \&ExtractTextFromTXTFile,
  'doc'  => \&ExtractTextFromDocFile,
  'docx' => \&ExtractTextFromDOCXFile,
  'epub' => \&ExtractTextFromEPUBFile,
};

our $rxFormats = join '|', keys %$Detectors;
$rxFormats =~ s/\./\\./g;

use constant FB3_META_REL => 'http://www.fictionbook.org/FictionBook3/relationships/Book';
use constant FB3_BODY_REL => 'http://www.fictionbook.org/FictionBook3/relationships/body';


=head1 NAME

Text::Distill - Quick texts compare, plagiarism and common parts detection

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';


=head1 SYNOPSIS

 use Text::Distill qw(Distill);

 my $DistilledText1 = Distill($text1);
 my $DistilledText2 = Distill($text2);

 $DistilledText1 eq $DistilledText2 ? print("Equal") : print("Not equal");

or

 use Text::Distill;

 my $FileFormat = Text::Distill::DetectBookFormat($FilePath);
 die "Not a fb2.zip file" if $FileFormat ne 'fb2.zip';

 my $Text = Text::Distill::ExtractTextFromFB2File($FilePath);
 my $Gems = TextToGems($Text);

 my $VURL = 'http://partnersdnld.litres.ru/copyright_check_by_gems/';
 my $TextInfo = Text::Distill::GemsValidate($Gems,$VURL);

 die "Copyright-protected content" if $TextInfo->{verdict} eq 'protected';

=head1 Distilling gems from text

=head2 TextToGems($UTF8TextString)

Transforms a text (valid UTF8 expected) into an array of 32-bit hash-summs
(Jenkins's Hash). Text is at first flattened the hard
way (something like soundex, see Distill below), than splitted into fragments by statistically
choosen sequences. First and the last fragments are rejected, short fragments are
rejected as well, from remaining strings calc hashes and
returns reference to them in the array.

What you really need to know is that TextToGem's from exactly the same texts are
eqlal, texts with small changes have similar "gems" as well. And
if two texts have 3+ common gems - they share some text parts, for sure. This is somewhat
close to "Edit distance", but fast on calc and indexable. So you can effectively
search for citings or plagiarism. Choosen split-method makes average detection
segment about 2k of text (1-2 paper pages), so this package will not normally detect
a single equal paragraph. If you need more precise match extended
@Text::Distill::SplitChars with some
sequences from SeqNumStats.xlsx on GitHub, I guiess you can get down to parts of
about 300 chars without problems. Just don't forget to lower
$Text::Distill::MinPartSize as well and keep in mind GemsValidate will break
if you play with $MinPartSize and @SplitChars.

Should return about one 32-bit jHash from every 2kb of source text
(may vary depending on the text thou).

 my $Gems = TextToGems($String);
 print join(',',@$Gems);


=pod

=head2 Distill($UTF8TextString)

Transforming the text (valid UTF8 expected) into a sequence of 1-8 numbers
(string as well). Internally used by TextToGems, but you may use it's output
with standart "edit distance" algorithm, like L<Text::Levenshtein|Text::Levenshtein>. Distilled string
is shorter, so you math will go much faster.

At the end works somewhat close to 'soundex' with addition of some basic rules
for cyrillic chars, pre- and post-cleanup and utf normalization. Drops strange
sequences, drops short words as well (how are you going to make you plagiarism
without copying the long words, huh?)

 $Distilled = Distill($Text);  # $Distilled should be ~60% shorter than $Text

=head1 Remote validation

There is at least one open service to check your text against
known text database, docs are here: L<https://goo.gl/xmFMdr>.

=head2 GemsValidate(\@Gems, $Url)

Checks your gems against remote database, returns overall verdict
and a structure with info on found titles

=cut

sub GemsValidate {
	my $Gems = shift;
	my $Url = shift;

	my $ua = new LWP::UserAgent;
	$ua->timeout(5);
	my $Response = $ua->post( $Url, {gems => join ",",@$Gems});

	my $Result;
	if ($Response->is_success) {
		return decode_json( $Response->decoded_content );
	} else {
		die $Response->status_line;
	}

}

# EXTRACT BLOCK

=head1 Service functions

=head2 ExtractTextFromFB2File($FilePath)

Function receives a path to the fb2-file and returns all significant text from the file as a string

=cut

sub ExtractTextFromFB2File {
  my $FN = shift;

  my $parser = XML::LibXML->new();
  my $xslt = XML::LibXSLT->new();
  my $source = $parser->parse_file($FN);
  my $style_doc = $parser->load_xml(string => $XSL_FB2_2_String);
  my $stylesheet = $xslt->parse_stylesheet($style_doc);
  my $results = $stylesheet->transform($source);
  my $Out = $stylesheet->output_string($results);

  return $Out;
}

=head2 ExtractTextFromFB2File($FilePath)

Function receives a path to the fb3-file and returns all significant text from the file as a string

=cut

sub ExtractTextFromFB3File {
  my $FN = shift;

  unless( -e $FN ) {
    Carp::confess( "$FN doesn't exist" );
  }

  # Prepare XML parser, XSLT stylesheet and XPath Context beforehand
  my $XML = XML::LibXML->new;
  my $StyleDoc = $XML->load_xml( string => $XSL_FB3_2_String );
  my $Stylesheet = XML::LibXSLT->new->parse_stylesheet( $StyleDoc );
  my $XC = XML::LibXML::XPathContext->new;
  $XC->registerNs( opcr => 'http://schemas.openxmlformats.org/package/2006/relationships' );

  # FB3 is ZIP archive following Open Packaging Conventions. Let's find FB3 Body in it
  my $Zip = Archive::Zip->new();
  my $ReadStatus = $Zip->read( $FN );
  unless( $ReadStatus == AZ_OK ) {
    Carp::confess "[Archive::Zip error] $!";
  }
  # First we must find package Rels file
  my $PackageRelsXML = $Zip->contents( '_rels/.rels' )
    or do{ $! = 11; Carp::confess 'Broken OPC package, no package Rels file (/_rels/.rels)' };

  # Next find FB3 meta relation(s)
  my $PackageRelsDoc = eval{ XML::LibXML->load_xml( string => $PackageRelsXML ) }
    or do{ $! = 11; Carp::confess "Invalid XML: $@" };

  my @RelationNodes = $XC->findnodes(
    '/opcr:Relationships/opcr:Relationship[@Type="'.FB3_META_REL.'"]',
    $PackageRelsDoc
  );
  unless( @RelationNodes ) {
    $! = 11;
    Carp::confess 'No relation to FB3 meta';
  }

  # There could be more than one book packed in FB3, so continue by parsing all the books found
  my $Result = '';
  for my $RelationNode ( @RelationNodes ) {
    # Get FB3 meta name from relation
    my $MetaName = OPCPartAbsoluteNameFromRelative( $RelationNode->getAttribute('Target'), '/' );
    # Name in zip has no leading slash and name in OPC has it. Remove leading slash from OPC name
    $MetaName =~ s:^/::;

    # Get FB3 meta Rels file name
    my $MetaRelsName = $MetaName;
    $MetaRelsName =~ s:^(.*/)?([^/]*)$:${1}_rels/${2}.rels:;

    my $MetaRelsXML = $Zip->contents( $MetaRelsName )
      or do{ $! = 11; Carp::confess "No FB3 meta Rels file (expecting $MetaRelsName)" };

    # Next we get relation to FB3 body from FB3 meta Rels file
    my $MetaRelsDoc = eval{ $XML->load_xml( string => $MetaRelsXML ) }
      or do{ $! = 11; Carp::confess "Invalid XML: $@" };

    my( $BodyRelation ) = $XC->findnodes(
      '/opcr:Relationships/opcr:Relationship[@Type="'.FB3_BODY_REL.'"]',
      $MetaRelsDoc
    );
    unless( $BodyRelation ) {
      $! = 11;
      Carp::confess "No relation to FB3 body in $MetaRelsName";
    }

    # Get FB3 body name from relation
    my $CurrentDir = $MetaName;
    $CurrentDir =~ s:/?[^/]*$::;
    my $BodyName = OPCPartAbsoluteNameFromRelative(
      $BodyRelation->getAttribute('Target'),
      "/$CurrentDir" # add leading slash (zip name to opc)
    );
    $BodyName =~ s:^/::; # remove leading slash (opc name to zip)

    # Get FB3 body text
    my $BodyXML = $Zip->contents( $BodyName )
      or do{ $! = 11; Carp::confess "No FB3 body (expecting $BodyName)" };

    # Transform it into plain text
    my $BodyDoc = $XML->load_xml( string => $BodyXML );
    my $TransformResults = $Stylesheet->transform( $BodyDoc );
    $Result .= $Stylesheet->output_string( $TransformResults );
  }

  return $Result;
}

=head2 ExtractTextFromTXTFile($FilePath)

Function receives a path to the text-file and returns all significant text from the file as a string

=cut

sub ExtractTextFromTXTFile {
  my $FN = shift;
  open(TEXTFILE, "<$FN");
  my $String = join('', <TEXTFILE>);
  close TEXTFILE;

  require Encode::Detect;
  return Encode::decode('Detect', $String);
}


=head2 ExtractTextFromDocFile($FilePath)

Function receives a path to the doc-file and returns all significant text from the file as a string

=cut

sub ExtractTextFromDocFile {
  my $FilePath = shift;

  my $File = Text::Extract::Word->new($FilePath);
  my $Text = $File->get_text();

  return $Text;
}

=head2 ExtractTextFromDOCXFile($FilePath)

Function receives a path to the docx-file and returns all significant text from the file as a string

=cut

sub ExtractTextFromDOCXFile {
  my $FN = shift;

  my $Result;
  my $arch = Archive::Zip->new();
  if ( $arch->read($FN) == AZ_OK ) {
    if (my $DocumentMember = $arch->memberNamed( 'word/document.xml' )) {
      my $XMLDocument = $DocumentMember->contents();

      my $xml  = XML::LibXML->new();
      my $xslt = XML::LibXSLT->new();

      my $Document;
      eval { $Document = $xml->parse_string($XMLDocument); };
      if ($@) {
        $! = 11;
        Carp::confess("[libxml2 error ". $@->code() ."] ". $@->message());
      }

      my $StyleDoc   = $xml->load_xml(string => $XSL_Docx_2_Txt);

      my $StyleSheet = $xslt->parse_stylesheet($StyleDoc);

      my $TransformResult = $StyleSheet->transform($Document);

      $Result = $StyleSheet->output_string($TransformResult);
    }
  } else {
    Carp::confess("[Archive::Zip error] $!");
  }

  return $Result;
}

=head2 ExtractTextFromEPUBFile($FilePath)

Function receives a path to the epub-file and returns all significant text from the file as a string

=cut

sub ExtractTextFromEPUBFile {
  my $FN = shift;

  my $Result;
  my $arch = Archive::Zip->new();
  if ( $arch->read($FN) == AZ_OK ) {
    my $requiredMember = 'META-INF/container.xml';
    if (my $ContainerMember = $arch->memberNamed( $requiredMember )) {
      my $XMLContainer = $ContainerMember->contents();

      my $xml = XML::LibXML->new;
      my $xpc = XML::LibXML::XPathContext->new();
      $xpc->registerNs('opf', 'urn:oasis:names:tc:opendocument:xmlns:container');

      my $Container;
      eval { $Container = $xml->parse_string($XMLContainer); };
      if ($@) {
        $! = 11;
        Carp::confess("[libxml2 error ". $@->code() ."] ". $@->message());
      }

      my ($ContainerNode) = $xpc->findnodes('//opf:container/opf:rootfiles/opf:rootfile', $Container);
      my $ContentPath = $ContainerNode->getAttributeNode('full-path')->string_value;
      if (my $ContentMember = $arch->memberNamed( $ContentPath )) {
        my $XMLContent = $ContentMember->contents();

        $xpc->unregisterNs('opf');
        $xpc->registerNs('opf', 'http://www.idpf.org/2007/opf');

        my $Content;
        eval { $Content = $xml->parse_string($XMLContent); };
        if ($@) {
          $! = 11;
          Carp::confess("[libxml2 error ". $@->code() ."] ". $@->message());
        }
        my @ContentNodes = $xpc->findnodes('//opf:package/opf:manifest/opf:item[
            @media-type="application/xhtml+xml"
          and
            starts-with(@id, "content")
          ]',
          $Content
        );
        my $HTMLTree = HTML::TreeBuilder->new();
        foreach my $ContentNode (@ContentNodes) {
          my $HTMLContentPath = $ContentNode->getAttributeNode('href')->string_value;

          if (my $HTMLContentMember = $arch->memberNamed( $HTMLContentPath )) {
            my $HTMLContent = $HTMLContentMember->contents();

            $HTMLTree->parse_content($HTMLContent);
          } else {
            Carp::confess("[Archive::Zip error] $HTMLContentPath not found in ePub ZIP container");
          }
        }
        $Result = DecodeUtf8($HTMLTree->as_text);
      } else {
        Carp::confess("[Archive::Zip error] $ContentPath not found in ePub ZIP container");
      }
    } else {
      Carp::confess("[Archive::Zip error] $requiredMember not found in ePub ZIP container");
    }
  } else {
    Carp::confess("[Archive::Zip error] $!");
  }

  return $Result;
}

sub OPCPartAbsoluteNameFromRelative {
  my $Name = shift;
  my $Dir = shift;
  $Dir =~ s:/$::; # remove trailing slash

  my $FullName = ( $Name =~ m:^/: ) ? $Name :       # $Name has absolute path
                                      "$Dir/$Name"; # $Name has relative path
  $FullName = do{
    use bytes; # A-Za-z are case insensitive
    lc $FullName;
  };

  # parse all . and .. in name
  my @CleanedSegments;
  my @OriginalSegments = split m:/:, $FullName;
  for my $Part ( @OriginalSegments ) {
    if( $Part eq '.' ) {
      # just skip
    } elsif( $Part eq '..' ) {
      pop @CleanedSegments;
    } else {
      push @CleanedSegments, $Part;
    }
  }

  return join '/', @CleanedSegments;
}


sub ExtractSingleZipFile {
  my $FN = shift;
  my $Ext = shift;
  my $Zip = Archive::Zip->new();

  return unless ( $Zip->read( $FN ) == Archive::Zip::AZ_OK );

  my @Files = $Zip->members();
  return unless (scalar @Files == 1 && $Files[0]->{fileName} =~ /(\.$Ext)$/);

  my $TmpDir = File::Temp::tempdir(cleanup=>1);

  my $OutFile = $TmpDir.'/check_' . $$ . '_' . $Files[0]->{fileName};

  return $Zip->extractMember( $Files[0], $OutFile ) == Archive::Zip::AZ_OK ? $OutFile : undef;
}

=head2 DetectBookFormat($FilePath, $Format)

Function detects format of an e-book and returns it. You
may suggest the format to start with, this wiil speed up the process a bit
(not required).

$Format can be 'fb2.zip', 'fb2', 'doc.zip', 'doc', 'docx.zip',
'docx', 'epub.zip', 'epub', 'txt.zip', 'txt', 'fb3', 'fb3'

=cut

sub DetectBookFormat {
  my $File = shift;
  my $Format = shift;
  if (defined $Format && $Format =~/^($rxFormats)$/) {
    $Format = $1;
  } else {
    $Format = '';
  }

  #$Format первым пойдет
  my @Formats = ($Format || (),  grep{ $_ ne $Format } @DetectionOrder);

  foreach( @Formats ) {
    return $_ if $Detectors->{$_}->($File);
  }
  return;
}


our $SplitRegexp = join ('|',@SplitChars);

$SplitRegexp = qr/$SplitRegexp/o;

# Кластеризация согласных - глухие к глухим, звонкие к звонким
#my %SoundexClusters = (
# '1' => 'бпфвbfpv',
# '2' => 'сцзкгхcgjkqsxz',
# '3' => 'тдdt',
# '4' => 'лйl',
# '5' => 'мнmn',
# '6' => 'рr',
# '7' => 'жшщч'
#);
#my $SoundexTranslatorFrom;
#my $SoundexTranslatorTo;
#for (keys %SoundexClusters){
# $SoundexTranslatorFrom .= $SoundexClusters{$_};
# $SoundexTranslatorTo .= $_ x length($SoundexClusters{$_});
#}

sub TextToGems{
  my $SrcText = Distill(shift) || return;

  my @DistilledParts = split /$SplitRegexp/, $SrcText;

  # Началу и концу верить всё равно нельзя
  shift @DistilledParts;
  pop @DistilledParts;
  my @Hashes;
  my %SeingHashes;
  for (@DistilledParts){
    # Если отрывок текста короткий - мы его проигнорируем
    next if length($_)< $MinPartSize;

    # Используется Хеш-функция Дженкинса, хорошо распределенный хэш на 32 бита
    my $Hash = Digest::JHash::jhash($_);

    # Если один хэш дважды - нам второго не нужно
    push @Hashes, $Hash unless $SeingHashes{$Hash}++;
  }
  return \@Hashes;
}

# Безжалостная мужланская функция, но в нашем случае чем топорней - тем лучше
sub LikeSoundex {
  my $S = shift;

  # Гласные долой, в них вечно очепятки
  $S =~ s/[$SoundexExpendable]+//gi;

  # Заменяем согласные на их кластер
  # eval "\$String =~ tr/$SoundexTranslatorFrom/$SoundexTranslatorTo/";
  $S =~ tr/рrлйlбпфвbfpvтдdtжшщчсцзкгхcgjkqsxzмнmn/664441111111133337777222222222222225555/;

  return $S;
}


sub Distill {
  my $String = shift;

  #Нормализация юникода
  $String = Unicode::Normalize::NFKC($String);

  #Переводим в lowercase
  $String = lc($String);

  #Конструкции вида слово.слово разбиваем пробелом
  $String =~ s/(\w[.,;:&?!*#%+\^\\\/])(\w)/$1 $2/g;

  # Понятные нам знаки причешем до упрощенного вида
  $String =~ tr/ЁёÉÓÁéóáĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏŐőŒœŔŕŖŗŘřŚŜśŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžſƒǺǻǼǽǾǿђѓєѕіїјљњћќўџҐґẀẁẂẃẄẅỲỳ/ЕеЕОАеоаAaAaAaCcCcCcCcDdDdEeEeEeEeEeGgGgGgGgHhHhIiIiIiIiIiiiJjKkкLlLlLlLlLlNnNnNnnNnOoOoOoCCRrRrRrSSssSsŠšTtTtTtUuUuUuUuUuUuWwYyYZzZzZzffAaAaOohгеsiijлнhкyuГгWWWWWWYy/;

  # в словах вида папа-ёж глотаем тире (и любой другой мусор)
  $String =~ s/(\w)([^\w\s]|_)+(\w)/$1$3/;

  # Короткие слова долой
  # Короткие русские слова долой (у нас в русском и 6 знаков короткое)
  $String =~ s/(\s|^)(\S{1,5}|[а-я]{6})\b/$1/g;

  # странные конструкции вида -=[мусорсрач]=- долой, ими легко засорить
  # текст - глаз заигнорит, а робот будет думать что текст о другом. Не будем
  # облегчать атакующим жизнь
  $String =~ s/(^|\s)[^\w\s]+\s?\w+\s*[^\w\s]+($|\s)/$1$2/g;

  $String =~ s/([^\w\s]|_)+//g;

  return '' if $String !~ /\w/;

  $String = LikeSoundex($String);

  # Все буквы, которых мы не знаем - перегоняем в транслит, говорят оно даж китайщину жрёт
  if ($String =~ /[^\d\s]/){
    $String = lc Text::Unidecode::unidecode($String);

    # Уборка - II, уже для транслитерированной строки
    $String = LikeSoundex($String);
  }

  # Убираем повторы
  $String =~ s/(\w)\1+/$1/gi;

  # слишком длинные слова подрежем (оставив меточку 8, что поработали ножницами)
  $String =~ s/(\s|^)(\S{4})\S+\b/${2}8/g;

  # Всё, мы закончили, теперь пробелы убираем, да и до кучи что там еще было
  $String =~ s/\D//g;

  return $String;
}

# CHECK BLOCK

=head1 Internals:

Receives a path to the file and checks whether this file is ...

B<CheckIfDocZip()> - MS Word .doc in zip-archive

B<CheckIfEPubZip()> - Electronic Publication .epub in zip-archive

B<CheckIfDocxZip()> - MS Word 2007 .docx  in zip-archive

B<CheckIfFB2Zip()> - FictionBook2  (FB2)  in zip-archive

B<CheckIfTXT2Zip()> - text-file in zip-archive

B<CheckIfEPub()> - Electronic Publication .epub

B<CheckIfDocx()> - MS Word 2007 .docx

B<CheckIfDoc()> - MS Word .doc

B<CheckIfFB2()> - FictionBook2 (FB2)

B<CheckIfFB3()> - FictionBook3 (FB3)

B<CheckIfTXT()> - text-file

=cut

sub CheckIfDocZip {
  my $FN = shift;
  my $IntFile = ExtractSingleZipFile( $FN, 'doc' ) || return;
  my $Result = CheckIfDoc( $IntFile );
  return $Result;
}

sub CheckIfEPubZip {
  my $FN = shift;
  my $IntFile = ExtractSingleZipFile( $FN, 'epub' ) || return;
  my $Result = CheckIfEPub( $IntFile );
  return $Result;
}

sub CheckIfDocxZip {
  my $FN = shift;
  my $IntFile = ExtractSingleZipFile( $FN, 'docx' ) || return;
  my $Result = CheckIfDocx( $IntFile );
  return $Result;
}

sub CheckIfFB2Zip {
  my $FN = shift;
  my $IntFile = ExtractSingleZipFile( $FN, 'fb2' ) || return;
  my $Result = CheckIfFB2( $IntFile );
  return $Result;
}

sub CheckIfTXTZip {
  my $FN = shift;
  my $IntFile = ExtractSingleZipFile( $FN, 'txt' ) || return;
  my $Result = CheckIfTXT( $IntFile );
  return $Result;
}

sub CheckIfEPub {
  my $FN = shift;

  my $arch = Archive::Zip->new();

  if ( $arch->read($FN) == AZ_OK ) {
    if (my $ContainerMember = $arch->memberNamed( 'META-INF/container.xml' )) {
      my $XMLContainer = $ContainerMember->contents();

      my $xml = XML::LibXML->new;
      my $xpc = XML::LibXML::XPathContext->new();
      $xpc->registerNs('opf', 'urn:oasis:names:tc:opendocument:xmlns:container');

      my $Container;
      eval { $Container = $xml->parse_string($XMLContainer); };
      return if ($@ || !$Container);

      my ($ContainerNode) = $xpc->findnodes('//opf:container/opf:rootfiles/opf:rootfile', $Container);
      my $ContentPath = $ContainerNode->getAttributeNode('full-path')->string_value;

      if (my $ContentMember = $arch->memberNamed( $ContentPath )) {
        my $XMLContent = $ContentMember->contents();

        $xpc->unregisterNs('opf');
        $xpc->registerNs('opf', 'http://www.idpf.org/2007/opf');

        my $Content;
        eval { $Content = $xml->parse_string($XMLContent); };
        return if ($@ || !$Content);

        my @ContentNodes = $xpc->findnodes('//opf:package/opf:manifest/opf:item[
            @media-type="application/xhtml+xml"
          and
            starts-with(@id, "content")
          and
            "content" = translate(@id, "0123456789", "")
          ]',
          $Content
        );

        my $existedContentMembers = 0;
        foreach my $ContentNode (@ContentNodes) {
          my $HTMLContentPath = $ContentNode->getAttributeNode('href')->string_value;
          $existedContentMembers++ if $arch->memberNamed( $HTMLContentPath );
        }

        return 1 if (@ContentNodes == $existedContentMembers);
      }
    }
  }
  return;
}

sub CheckIfDocx {
  my $FN = shift;

  my $arch = Archive::Zip->new();

  return unless ( $arch->read($FN) == AZ_OK );
  return 1 if $arch->memberNamed( 'word/document.xml' );
}

sub CheckIfDoc {
  my $FilePath = shift;

  my $ofs = OLE::Storage_Lite->new($FilePath);
  my $name = Encode::encode("UCS-2LE", "WordDocument");
  return $ofs->getPpsSearch([$name], 1, 1);
}

sub CheckIfFB2 {
  my $FN = shift;
  my $parser = XML::LibXML->new;
  my $XML = eval{ $parser->parse_file($FN) };
  return if( $@ || !$XML );
  return 1;
}

sub CheckIfFB3 {
  my $FN = shift;

  my $Zip = Archive::Zip->new();
  my $XC = XML::LibXML::XPathContext->new;
  $XC->registerNs( opcr => 'http://schemas.openxmlformats.org/package/2006/relationships' );

  my( $RelsXML, $RelsDoc );
  if( $Zip->read($FN) == AZ_OK
    and $RelsXML = $Zip->contents( '_rels/.rels' )
    and $RelsDoc = eval{ XML::LibXML->load_xml( string => $RelsXML ) }
    and $XC->exists( '/opcr:Relationships/opcr:Relationship[@Type="'.FB3_META_REL.'"]', $RelsDoc )) {

    return 1;

  } else {
    return 0;
  }
}

sub CheckIfTXT {
  my $FN = shift;
  my $String = ExtractTextFromTXTFile($FN);
  return $String !~ /[\x00-\x08\x0B\x0C\x0E-\x1F]/g; #всякие непечатные Control characters говорят, что у нас тут бинарник
}

sub DecodeUtf8 {
  my $Out = shift;
  if ($Out && !Encode::is_utf8($Out)) {
    $Out = Encode::decode_utf8($Out);
  }
  return $Out;
}

=head1 REQUIRED MODULES

 Digest::JHash;
 XML::LibXML;
 XML::LibXSLT;
 Encode::Detect;
 Text::Extract::Word;
 HTML::TreeBuilder;
 OLE::Storage_Lite;
 Text::Unidecode (v1.27 or later);
 Unicode::Normalize (v1.25 or later);
 Archive::Zip
 Encode;
 Carp;
 LWP::UserAgent;
 JSON::XS;
 File::Temp;

=head1 SCRIPTS

=head2 plagiarism_check.pl - checks your ebook againts known texts database

Script uses check_by_gems API (L<https://goo.gl/xmFMdr>). You can
select any "check service" provider with CHECKURL (see below),
by default text checked with LitRes copyright-check service:
L<http://partnersdnld.litres.ru/copyright_check_by_gems/>

B<USAGE>

 > plagiarism_check.pl FILEPATH [CHECKURL] [--full-info] [--help]

B<EXAMPLE>

 > plagiarism_check.pl /home/file.epub --full-info

B<PARAMS>

B<I<FILEPATH>>    path to file for check

B<I<CHECKURL>>    url of validating API to check file with. By default:
            http://partnersdnld.litres.ru/copyright_check_by_gems/

B<I<--full-info>>  show full info of checked

B<I<--help>>      show this information

B<OUTPUT>

Ebook statuses explained:

B<I<protected>> there are either copyrights on this book or it is
forbidden for distribution by some other reason (racist content, etc)

B<I<free>> ebook content owner distributes it for free (but
content may still be protected from certan kind use)

B<I<public_domain>> this it public domain, no restrictions at all

B<I<unknown>> service have has no valid info on this text


=head1 AUTHOR

Litres.ru, C<< <gu at litres.ru> >>
Get the latest code from L<https://github.com/Litres/TextDistill>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/Litres/TextDistill/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::Distill


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-Distill>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-Distill>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-Distill>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-Distill/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016 Litres.ru

The GNU Lesser General Public License version 3.0

Text::Distill is free software: you can redistribute it and/or modify it
under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3.0 of the License.

Text::Distill is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
License for more details.

Full text of License L<http://www.gnu.org/licenses/lgpl-3.0.en.html>.

=cut

1; # End of Text::Distill
