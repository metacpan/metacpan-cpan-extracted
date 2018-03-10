# vi:syntax=perl

use strict;
use warnings;
use lib qw(lib);
use local::lib qw(local);

use Test::More;
use WorldCat::API;
use XML::Simple qw(XMLin);

subtest 'Test parsing of a valid FedDoc XML record' => sub {
  my $record = MARC::Record->new_from_marc21xml(
    XMLin("t/fixtures/829428.xml")->{content}{response}{record}
  );

  is $record->oclc_number, 829428,
    "Correctly parsed the OCLC Number"
    or diag explain $record;

  is $record->leader, "00000cam a2200000   4500",
    "Correctly parsed the leader"
    or diag explain $record;

  is $record->subfield("856", "u"), "http://hdl.loc.gov/loc.law/llconghear.00184032764",
    "Correctly parsed an isolated subfield"
    or diag explain $record;

  my @mv_fields = $record->field("651");
  is @mv_fields, 2,
    "Handles a field that appears more than once"
    or diag explain $record;

  is $mv_fields[1]->subfield("z"), "Panama Canal.",
    "Correctly parsed a subfield from a tag appearing multiple times"
    or diag explain $record;
};

done_testing;
