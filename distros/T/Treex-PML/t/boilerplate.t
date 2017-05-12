#!perl -T

use strict;
use warnings;
use Test::More tests => 49;

sub not_in_file_ok {
    my ($filename, %regex) = @_;
    open( my $fh, '<', $filename )
        or die "couldn't open $filename for reading: $!";

    my %violated;

    while (my $line = <$fh>) {
        while (my ($desc, $regex) = each %regex) {
            if ($line =~ $regex) {
                push @{$violated{$desc}||=[]}, $.;
            }
        }
    }

    if (%violated) {
        fail("$filename contains boilerplate text");
        diag "$_ appears on lines @{$violated{$_}}" for keys %violated;
    } else {
        pass("$filename contains no boilerplate text");
    }
}

sub module_boilerplate_ok {
    my ($module) = @_;
    not_in_file_ok($module =>
        'the great new $MODULENAME'   => qr/ - The great new /,
        'boilerplate description'     => qr/Quick summary of what the module/,
        'stub function definition'    => qr/function[12]/,
    );
}

{
  not_in_file_ok(README =>
    "The README is used..."       => qr/The README is used/,
    "'version information here'"  => qr/to provide version information/,
  );

  not_in_file_ok(Changes =>
    "placeholder date/time"       => qr(Date/time)
  );

  module_boilerplate_ok('lib/Treex/PML.pm');
  module_boilerplate_ok('lib/Treex/PML/Alt.pm');
  module_boilerplate_ok('lib/Treex/PML/Backend/CSTS.pm');
  module_boilerplate_ok('lib/Treex/PML/Backend/FS.pm');
  module_boilerplate_ok('lib/Treex/PML/Backend/NTRED.pm');
  module_boilerplate_ok('lib/Treex/PML/Backend/PML.pm');
  module_boilerplate_ok('lib/Treex/PML/Backend/PMLTransform.pm');
  module_boilerplate_ok('lib/Treex/PML/Backend/Storable.pm');
  module_boilerplate_ok('lib/Treex/PML/Backend/TEIXML.pm');
  module_boilerplate_ok('lib/Treex/PML/Backend/TrXML.pm');
  module_boilerplate_ok('lib/Treex/PML/Container.pm');
  module_boilerplate_ok('lib/Treex/PML/Document.pm');
  module_boilerplate_ok('lib/Treex/PML/FSFormat.pm');
  module_boilerplate_ok('lib/Treex/PML/Factory.pm');
  module_boilerplate_ok('lib/Treex/PML/IO.pm');
  module_boilerplate_ok('lib/Treex/PML/Instance.pm');
  module_boilerplate_ok('lib/Treex/PML/Instance/Common.pm');
  module_boilerplate_ok('lib/Treex/PML/Instance/Reader.pm');
  module_boilerplate_ok('lib/Treex/PML/Instance/Writer.pm');
  module_boilerplate_ok('lib/Treex/PML/List.pm');
  module_boilerplate_ok('lib/Treex/PML/Node.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Alt.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Attribute.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/CDATA.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Choice.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Constant.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Constants.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Container.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Copy.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Decl.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Derive.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Element.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Import.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/List.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Member.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Reader.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Root.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Seq.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Struct.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Template.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/Type.pm');
  module_boilerplate_ok('lib/Treex/PML/Schema/XMLNode.pm');
  module_boilerplate_ok('lib/Treex/PML/Seq.pm');
  module_boilerplate_ok('lib/Treex/PML/Seq/Element.pm');
  module_boilerplate_ok('lib/Treex/PML/StandardFactory.pm');
  module_boilerplate_ok('lib/Treex/PML/Struct.pm');
}

