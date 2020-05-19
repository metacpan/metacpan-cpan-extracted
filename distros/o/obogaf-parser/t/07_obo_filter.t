use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Files;
use obogaf::parser qw(obo_filter);

## input files
my $obofile = "t/data/test_go.obo";
my $fakeobo = "t/data/test_GO.obo";
my $fakeext = "t/data/test_go.OBO";

my $termsfile= "t/data/test_goterms.txt";
my $faketerms= "t/data/test_GOterms.txt";

## test read or die
lives_ok( sub { my $file = obo_filter($obofile, $termsfile) }, 'files opened' );
dies_ok ( sub { my $file = obo_filter($fakeobo, $faketerms) }, 'die: wrong files name');
dies_ok ( sub { my $file = obo_filter($fakeext, $termsfile) }, 'die: no obo extension');

## define arguments
my ($res, $fh);

## test obo filtered 
$res= obo_filter($obofile, $termsfile);
my $newobo= "t/data/test_gofiltered.obo"; 
open $fh, ">", $newobo; 
print $fh "${$res}";
close $fh;
file_ok($newobo, "format-version: 1.2\ndata-version: releases/2020-03-23\nsubsetdef: gocheck_do_not_annotate \"Term not to be used for direct annotation\"\nsubsetdef: gocheck_do_not_manually_annotate \"Term not to be used for direct manual annotation\"\nsubsetdef: goslim_agr \"AGR slim\"\nsubsetdef: goslim_aspergillus \"Aspergillus GO slim\"\nsubsetdef: goslim_candida \"Candida GO slim\"\nsubsetdef: goslim_chembl \"ChEMBL protein targets summary\"\nsubsetdef: goslim_drosophila \"Drosophila GO slim\"\nsubsetdef: goslim_flybase_ribbon \"FlyBase Drosophila GO ribbon slim\"\nsubsetdef: goslim_generic \"Generic GO slim\"\nsubsetdef: goslim_metagenomics \"Metagenomics GO slim\"\nsubsetdef: goslim_mouse \"Mouse GO slim\"\nsubsetdef: goslim_pir \"PIR GO slim\"\nsubsetdef: goslim_plant \"Plant GO slim\"\nsubsetdef: goslim_pombe \"Fission yeast GO slim\"\nsubsetdef: goslim_synapse \"synapse GO slim\"\nsubsetdef: goslim_yeast \"Yeast GO slim\"\nsynonymtypedef: syngo_official_label \"label approved by the SynGO project\"\nsynonymtypedef: systematic_synonym \"Systematic synonym\" EXACT\ndefault-namespace: gene_ontology\nremark: cvs version: \$Revision: 38972\$\nremark: Includes Ontology(OntologyID(OntologyIRI(<http://purl.obolibrary.org/obo/go/never_in_taxon.owl>))) [Axioms: 18 Logical Axioms: 0]\nontology: go\nproperty_value: http://purl.org/dc/terms/license http://creativecommons.org/licenses/by/4.0/\n\n[Term]\nid: GO:0000002\nname: mitochondrial genome maintenance\nnamespace: biological_process\ndef: \"The maintenance of the structure and integrity of the mitochondrial genome; includes replication and segregation of the mitochondrial chromosome.\" [GOC:ai, GOC:vw]\nis_a: GO:0007005 ! mitochondrion organization\n\n[Term]\nid: GO:0000006\nname: high-affinity zinc transmembrane transporter activity\nnamespace: molecular_function\ndef: \"Enables the transfer of zinc ions (Zn2+) from one side of a membrane to the other, probably powered by proton motive force. In high-affinity transport the transporter is able to bind the solute even if it is only present at very low concentrations.\" [TC:2.A.5.1.1]\nsynonym: \"high affinity zinc uptake transmembrane transporter activity\" EXACT []\nsynonym: \"high-affinity zinc uptake transmembrane transporter activity\" RELATED []\nis_a: GO:0005385 ! zinc ion transmembrane transporter activity\n\n[Term]\nid: GO:0000007\nname: low-affinity zinc ion transmembrane transporter activity\nnamespace: molecular_function\ndef: \"Enables the transfer of a solute or solutes from one side of a membrane to the other according to the reaction: Zn2+ = Zn2+, probably powered by proton motive force. In low-affinity transport the transporter is able to bind the solute only if it is present at very high concentrations.\" [GOC:mtg_transport, ISBN:0815340729]\nis_a: GO:0005385 ! zinc ion transmembrane transporter activity\n\n\n");

## test fake go terms list and extra new line at eof
my $faketermsfile= "t/data/test_fake_goterms.txt"; 
open $fh, ">", $faketermsfile; 
print $fh "FAKEGO:0001\nFAKEGO:0002\nFAKEGO:0001\n\n\n";
close $fh;
dies_ok ( sub { my $file = obo_filter($obofile, $faketermsfile) }, 'die: fake obo terms');

done_testing();

