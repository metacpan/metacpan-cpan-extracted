This module extracts pre-parsed compressed DNA from "Genbank" and "Refseq"
(soon more) databases without draining the NCBI web server resources.
Guaranteed to work faster than any module because of the features: Parse-free,
compression ensuring twice twice faster download and reading from local disk,
caching leading to instant load next time you use the data, and also mirroring.
The database works transparent and simple, and can be used in any language
that support http requests.

Looking for mirror site supporters.

If for some reason you want your script in one directory and have the DB
directory in another - just create file 'base_path' and enter the path there.

--- Required modules ---

LWP::Simple and Compress::Zlib

--- Install ---

To install just run 'perl Makefile.pl' and 'make install'

--- Examples ---

use mGen;

$|=1;

my $as="NZ_AAAG02000001.1",$gn="Rrub02000030";

#mGen_reload_gene($as); # Updates the cache file

#print mGet_set(); # DB varibles
#print mGet_desc($as); # GB Desciption & summary
#print mGet_list($as); # List of genes' descriptions
#print mGet_gene($as); # List of parsed genes
#print mGet_fasta($as); # GB fasta
#print mGet_gene($as,$gn); # If entered the gene name it will extract only the one, insted of the whole list

print mGet_list($as,$gn)."\n\n";

my $list=mGet_list($as,$gn);
my ($prot,$crc,$gene_index,$gn,$size,$range,$list,$pol,$desc,$xtra,)=split(/\|/,$list);
print "Gene: $gn, Size: $size, Polarity: $pol\nDescription: $desc\n\n";

print "PRI division => ".$gb_division{PRI}."\n";

print "ACTG inverted is ".mGen_invert_dna('ACTG')."\n";

my ($start,$stop,%aa)=mGen_translate_table(11);
print "Start/Stop codons: $start \/ $stop, GGG equals $aa{GGG}\n";
print "ATGGATTACTGA => ".mGen_codon2aa("ATGGATTACTGA",$start,%aa)."\n";


--- Formats ---

Gene:
Gene name|Gene itself - nucleotide sequence, reversed if in negative strand
...
...
...

List:
Protocol|CRC|Gene_Index|Name|Size|Range|List of exons|Polarity|Description|Extra|
...
...
...

FASTA:
Whole nucleotide sequence in one line

Desc:
AS|GI|DataBase|Source|Description|Size|CDS % usage|Division|Data type|Data shape|Last update|Taxonomy|Data content|Extra|

