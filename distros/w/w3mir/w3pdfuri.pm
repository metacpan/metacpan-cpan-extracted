# -*- perl -*-
#
# w3pdfuri.pm -- extract uris from a adobe acrobat pdf file.
#     version 0.1
$VERSION=0.1;
#
# Assumptions:
# - File starts with %PDF
# - All URLS match this RE: ^\/URI\s+\(([^)]*)\)\s*$  (found by inspection of
#   one (1) pdf file (the reader.pdf in the acrobat distribution).
# - pdf files are potentially very large, so we read it from disk
#   record by record.
# - Record separator is ^M
#
# History:
# - 19/02/97 janl: Version 0.1, seems to work with PDF-1.2
#

package w3pdfuri;

use strict;

sub list ($) {
  my ($file) = @_;

  my @urls=();
  local($/)="\r";

  unless (open(PDF,"< $file")) {
    warn "Could not open $file for input: $!\n";
    return;
  }

  $_ = <PDF>;
  unless (/^%PDF-/) {
    warn "$file is not a PDF file.\n";
    close(PDF);
    return;
  }
  
  while (<PDF>) {
    chomp;
    push(@urls,$1) if (m~^/URI\s+\(([^)]*)\)\s*$~);
  }

  close(PDF);

  return @urls;
}

1;

__END__

# Test code
print "reader.pdf: ",
  join(",",list("/local/lib/acrobat/Reader/help/reader.pdf")),"\n";
print "Acrobat.pdf: ",
  join(",",list("/local/lib/acrobat/Reader/Acrobat.pdf")),"\n";
print "License.pdf: ",
  join(",",list("/local/lib/acrobat/Reader/License.pdf")),"\n";
print "MapTypes.pdf: ",
  join(",",list("/local/lib/acrobat/Reader/MapTypes.pdf")),"\n";
list("/etc/services");
