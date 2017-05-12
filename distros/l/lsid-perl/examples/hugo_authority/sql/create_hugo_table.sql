DROP TABLE hugo;

CREATE TABLE hugo (
	hgncID			INT,
	status			VARCHAR(255),
	approved_gene_name	VARCHAR(255),
	approved_gene_symbol	VARCHAR(255),
	prev_symbol		VARCHAR(255),
	enzymeID		VARCHAR(255),
	location		VARCHAR(255),
	aliases			VARCHAR(255),
	MGI			VARCHAR(255),
	PMID1			VARCHAR(255),
	PMID2			VARCHAR(255),
	seq_accessionID		VARCHAR(255),
	prev_gene_name		VARCHAR(255),
	gdbID			VARCHAR(255),
	LocusLinkID		VARCHAR(255),
	OMIM			VARCHAR(255),
	Ref_Seq			VARCHAR(255),
	SwissProtID		VARCHAR(255)
);
