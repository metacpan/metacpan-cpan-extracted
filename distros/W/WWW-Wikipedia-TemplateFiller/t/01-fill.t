#!perl -T
use Test::More tests => 23;

BEGIN {
  use_ok( 'WWW::Wikipedia::TemplateFiller' );
}

use HTML::Entities;

my $ndash = decode_entities('&ndash;');
my $access_key = $ENV{ISBNDB_ACCESS_KEY};

my $filler = new WWW::Wikipedia::TemplateFiller( isbndb_access_key => $access_key || 'No access key provided' );

my $source;

eval {
  $source = $filler->get( pubmedcentral_id => '1247673' );
};
ok( $@ =~ /no pubmed_id given/, '(bug #41053) get() dies if id not provided' );

$source = $filler->get( URL => 'http://news.bbc.co.uk/2/hi/business/7732733.stm' );
is( $source->fill->output( add_accessdate => 0 ), "{{cite web |url=http://news.bbc.co.uk/2/hi/business/7732733.stm |title=BBC NEWS &#124; Business &#124; Japanese economy now in recession |format= |work= |accessdate=}}", '(bug #41005) vertical pipes in HTML page titles' );

$source = $filler->get( pubmed_id => '18535242' );
is( $source->fill->output( add_accessdate => 0 ), "{{cite journal |author=Schermelleh L, Carlton PM, Haase S, ''et al.'' |title=Subdiffraction multicolor imaging of the nuclear periphery with 3D structured illumination microscopy |journal=Science |volume=320 |issue=5881 |pages=1332${ndash}6 |year=2008 |month=June |pmid=18535242 |doi=10.1126/science.1156947 |url=}}", 'dont_use_etal is off' );

is( $source->fill->output( add_accessdate => 0, dont_use_etal => 1 ), "{{cite journal |author=Schermelleh L, Carlton PM, Haase S, Shao L, Winoto L, Kner P, Burke B, Cardoso MC, Agard DA, Gustafsson MG, Leonhardt H, Sedat JW |title=Subdiffraction multicolor imaging of the nuclear periphery with 3D structured illumination microscopy |journal=Science |volume=320 |issue=5881 |pages=1332${ndash}6 |year=2008 |month=June |pmid=18535242 |doi=10.1126/science.1156947 |url=}}", 'dont_use_etal is on' );

$source = $filler->get( URL => 'http://diberri.dyndns.org/perl/test/no-title.html' );
is( $source->{title}, 'diberri.dyndns.org', 'title based on domain' );

# (bug #40960) workaround in case NCBI error 803 rears its head during 'make test'
$source = $filler->get( pubmedcentral_id => '137841' );
if( $source->{pmc_id} ) {
  is( $source->fill->output( add_accessdate => 0 ), "{{cite journal |author=Dworkin J, Losick R |title=Does RNA polymerase help drive chromosome segregation in bacteria? |journal=Proc. Natl. Acad. Sci. U.S.A. |volume=99 |issue=22 |pages=14089${ndash}94 |year=2002 |month=October |pmid=12384568 |pmc=137841 |doi=10.1073/pnas.182539899 |url=}}", 'get from pubmedcentral_id' );
} else {
  $source->{pmc_id} = '';
  is( $source->fill->output( add_accessdate => 0 ), "{{cite journal |author=Dworkin J, Losick R |title=Does RNA polymerase help drive chromosome segregation in bacteria? |journal=Proc. Natl. Acad. Sci. U.S.A. |volume=99 |issue=22 |pages=14089${ndash}94 |year=2002 |month=October |pmid=12384568 |pmc= |doi=10.1073/pnas.182539899 |url=}}", 'get from pubmedcentral_id' );
}

$source = $filler->get( pubmed_id => '12345' );
is( $source->fill->output( add_accessdate => 0 ), '{{cite journal |author=Rubinstein MH |title=A new granulation method for compressed tablets [proceedings] |journal=J. Pharm. Pharmacol. |volume=28 Suppl |issue= |pages=67P |year=1976 |month=December |pmid=12345 |doi= |url=}}', 'expand month' );

is( $source->fill( full_journal_title => 1 )->output( add_accessdate => 0 ), '{{cite journal |author=Rubinstein MH |title=A new granulation method for compressed tablets [proceedings] |journal=The Journal of Pharmacy and Pharmacology |volume=28 Suppl |issue= |pages=67P |year=1976 |month=December |pmid=12345 |doi= |url=}}', 'expand month' );

$source = $filler->get( pubmed_id => '15841477' );
is( $source->fill->output( link_journal => 1, add_accessdate => 0 ), "{{cite journal |author=Xu L, Liu SL, Zhang JT |title=(-)-Clausenamide potentiates synaptic transmission in the dentate gyrus of rats |journal=[[Chirality]] |volume=17 |issue=5 |pages=239${ndash}44 |year=2005 |month=May |pmid=15841477 |doi=10.1002/chir.20150 |url=}}", 'cite journal output part 1' );
is( $source->{journal}, 'Chirality', 'journal' );
is( $source->{pmid}, '15841477', 'pmid' );

is( $source->fill->output( add_accessdate => 0, add_text_url => 1, omit_url_if_doi_filled => 0 ), "{{cite journal |author=Xu L, Liu SL, Zhang JT |title=(-)-Clausenamide potentiates synaptic transmission in the dentate gyrus of rats |journal=Chirality |volume=17 |issue=5 |pages=239${ndash}44 |year=2005 |month=May |pmid=15841477 |doi=10.1002/chir.20150 |url=http://dx.doi.org/10.1002/chir.20150}}", 'cite journal output part 2' );

is( $source->fill->output( vertical => 1, add_accessdate => 0 ), "{{cite journal
|author=Xu L, Liu SL, Zhang JT
|title=(-)-Clausenamide potentiates synaptic transmission in the dentate gyrus of rats
|journal=Chirality
|volume=17
|issue=5
|pages=239${ndash}44
|year=2005
|month=May
|pmid=15841477
|doi=10.1002/chir.20150
|url=
}}", 'cite journal vertical output' );

$source = $filler->get( URL => 'http://diberri.dyndns.org/uvm/tools/' );
is( $source->{title}, 'UVM stuff', 'title' );

is( $filler->get( URL => 'http://diberri.dyndns.org/uvm/tools/' )->fill->output( add_accessdate => 1 ), '{{cite web |url=http://diberri.dyndns.org/uvm/tools/ |title=UVM stuff |format= |work= |accessdate='.WWW::Wikipedia::TemplateFiller::Source->__today_and_now.'}}', 'cite web template' );

$source = $filler->get( pubchem_id => 12345 );
is( $source->{iupac_name}, 'acetic acid acetoxymethyl ester', 'IUPACName match' );

is( $filler->get( pubchem_id => 12345 )->fill( add_iupac_name => 1 )->output( vertical => 1 ), '{{chembox
|ImageFile=
|ImageSize=
|IUPACName=acetic acid acetoxymethyl ester
|OtherNames=
|Section1={{Chembox Identifiers
|  CASNo=
|  PubChem=12345
|  SMILES=CC(=O)OCOC(=O)C
  }}
|Section2={{Chembox Properties
|  Formula=C<sub>5</sub>H<sub>8</sub>O<sub>4</sub>
|  MolarMass=132.11462
|  Appearance=
|  Density=
|  MeltingPt=
|  BoilingPt=
|  Solubility=
  }}
|Section3={{Chembox Hazards
|  MainHazards=
|  FlashPt=
|  Autoignition=
  }}
}}', 'chembox template' );

$source = $filler->get( hgnc_id => 'HGNC:1582' );
is( $source->{approved_symbol}, 'CCND1', 'Symbol match' );

is( $filler->get( hgnc_id => 'HGNC:1582' )->fill->output, '{{protein |name=cyclin D1 |caption= |image= |width= |HGNCid=1582 |Symbol=CCND1 |AltSymbols=BCL1, D11S287E, PRAD1 |EntrezGene=595 |OMIM= |RefSeq=NM_053056 |UniProt= |PDB= |ECnumber= |Chromosome=11 |Arm=q |Band=13 |LocusSupplementaryData=}}', 'protein template' );

is( $filler->get( drugbank_id => 'DB00338' )->fill->output, '{{drugbox |IUPAC_name=6-methoxy-2-[(4-methoxy-3,5-dimethylpyridin-2-yl)methylsulfinyl]-1H-benzimidazole |image={{PAGENAME}}.png |CAS_number=73590-58-6 |ATC_prefix= |ATC_suffix= |ATC_supplemental= |PubChem= |DrugBank=DB00338 |chemical_formula=C<sub>17</sub>H<sub>19</sub>N<sub>3</sub>O<sub>3</sub>S |molecular_weight= |bioavailability= |protein_bound=95% |metabolism= |elimination_half-life=0.5-1 hour |excretion= |pregnancy_AU=<!-- A / B1 / B2 / B3 / C / D / X --> |pregnancy_US=<!-- A / B / C / D / X --> |pregnancy_category= |legal_AU=<!-- Unscheduled / S2 / S4 / S8 --> |legal_UK=<!-- GSL / P / POM / CD --> |legal_US=<!-- OTC / Rx-only --> |legal_status= |routes_of_administration=}}' );

$source = $filler->get( drugbank_id => 'DB00700' );
is( $source->{cas_registry_number}, '107724-20-9', 'CAS_number match' );

SKIP: {
  skip "no isbndb access key provided in the ISBNDB_ACCESS_KEY environment variable" => 1 unless $access_key;
  $source = $filler->get( ISBN => '0805372989' );
  is( $source->{location}, 'San Francisco', 'isbn location match' );
}
