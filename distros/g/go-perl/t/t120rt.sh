#!/bin/sh
go2oboxml ~/cvs/go/ontology/gene_ontology.obo | go2obo -p obo_xml - > go.obo
diff  ~/cvs/go/ontology/gene_ontology.obo go.obo
