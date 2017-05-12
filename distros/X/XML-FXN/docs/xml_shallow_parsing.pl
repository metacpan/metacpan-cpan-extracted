# From: http://www.cs.sfu.ca/~cameron/REX.html
# REX/Perl 1.0 
# Robert D. Cameron "REX: XML Shallow Parsing with Regular Expressions",
# Technical Report TR 1998-17, School of Computing Science, Simon Fraser 
# University, November, 1998.
# Copyright (c) 1998, Robert D. Cameron. 
# The following code may be freely used and distributed provided that
# this copyright and citation notice remains intact and that modifications
# or additions are clearly identified.
# XML standard: http://www.w3.org/TR/REC-xml


$TextSE = "[^<]+";
$UntilHyphen = "[^-]*-";
$Until2Hyphens = "$UntilHyphen(?:[^-]$UntilHyphen)*-";
$CommentCE = "$Until2Hyphens>?";
$UntilRSBs = "[^\\]]*](?:[^\\]]+])*]+";
$CDATA_CE = "$UntilRSBs(?:[^\\]>]$UntilRSBs)*>";
$S = "[ \\n\\t\\r]+";
$NameStrt = "[A-Za-z_:]|[^\\x00-\\x7F]";
$NameChar = "[A-Za-z0-9_:.-]|[^\\x00-\\x7F]";
$Name = "(?:$NameStrt)(?:$NameChar)*";
$QuoteSE = "\"[^\"]*\"|'[^']*'";
$DT_IdentSE = "$S$Name(?:$S(?:$Name|$QuoteSE))*";
$MarkupDeclCE = "(?:[^\\]\"'><]+|$QuoteSE)*>";
$S1 = "[\\n\\r\\t ]";
$UntilQMs = "[^?]*\\?+";
$PI_Tail = "\\?>|$S1$UntilQMs(?:[^>?]$UntilQMs)*>";
$DT_ItemSE = "<(?:!(?:--$Until2Hyphens>|[^-]$MarkupDeclCE)|\\?$Name(?:$PI_Tail))|%$Name;|$S";
$DocTypeCE = "$DT_IdentSE(?:$S)?(?:\\[(?:$DT_ItemSE)*](?:$S)?)?>?";
$DeclCE = "--(?:$CommentCE)?|\\[CDATA\\[(?:$CDATA_CE)?|DOCTYPE(?:$DocTypeCE)?";
$PI_CE = "$Name(?:$PI_Tail)?";
$EndTagCE = "$Name(?:$S)?>?";
$AttValSE = "\"[^<\"]*\"|'[^<']*'";
$ElemTagCE = "$Name(?:$S$Name(?:$S)?=(?:$S)?(?:$AttValSE))*(?:$S)?/?>?";
$MarkupSPE = "<(?:!(?:$DeclCE)?|\\?(?:$PI_CE)?|/(?:$EndTagCE)?|(?:$ElemTagCE)?)";
$XML_SPE = "$TextSE|$MarkupSPE";


sub ShallowParse { 
  my($XML_document) = @_;
  return $XML_document =~ /$XML_SPE/g;
}
