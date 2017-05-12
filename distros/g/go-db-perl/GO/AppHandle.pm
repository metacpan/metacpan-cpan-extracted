# $Id: AppHandle.pm,v 1.19 2008/03/12 20:50:55 benhitz Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

package GO::AppHandle;
$VERSION='0.01';

=head1 NAME

  GO::AppHandle     - Gene Ontology Data API handle

=head1 SYNOPSIS

  use GO::AppHandle;
  my $dbname = "go";
  # connect to a database on a specific host
  $apph = GO::AppHandle->connect(-dbname=>$dbname, -dbhost=>$mysqlhost);

  # EXAMPLE 1
  # fetching a GO term from the datasource
  $term = $apph->get_term({acc=>"GO:0003677"});
  printf 
    "GO term; name=%s GO ID=%s\n",
    $term->name(), $term->public_acc();

  # EXAMPLE 2
  # fetching a list of associations to the ER
  # (and all the GO terms that are subtypes of the ER, or 
  #  located within the ER)
  # for which there is reasonably good evidence
  # (traceable author / direct assay)
  $assocs = $apph->get_associations({name=>"endoplasmic reticulum"},
				    {evcodes=>["TAS", "IDA"]});
  foreach my $assoc (@$assocs) {
    printf
      "Gene: %s evidence for association: %s %s",
       $assoc->gene_product->symbol,
       $assoc->evidence->code(),
       $assoc->evidence->xref->xref_key();
  }                                                                               
  # EXAMPLE 3
  # fetching a subgraph of GO
  $graph = $apph->get_graph(-acc=>3677, -depth=>3);
  foreach my $term (@ {$graph->get_all_nodes}) {
    printf 
      "GO term; name=%s GO ID=%s\n",
      $term->name(), $term->public_acc();
  }

  # EXAMPLE 4
  # fetching a subgraph of GO,
  # and using a graph iterator to 
  # display the graph
  $graph = $apph->get_graph_by_search("DNA helicase*");
  $it = $graph->create_iterator;

  while (my $ni = $it->next_node_instance) {
    $depth = $ni->depth;
    $term = $ni->term;
    printf 
      "%s Term = %s (%s)  // n_assocs=%s // depth=%d\n",
          "----" x $depth,
	  $term->name,
	  $term->public_acc,
	  $term->n_associations || 0,
          $depth;
  }

  # EXAMPLE 5
  # fetching a subgraph of GO,
  # constraining by gene products

  # get all terms that were used to annotate these two SGD genes
  $terms = $apph->get_terms({products=>["Eip63F-1", "Krt1-13"]});

  # build a graph all the way to the leaf nodes
  # from the above terms
  $graph = $apph->get_graph_by_terms($terms, -1);

  # create an iterator on the graph
  $it = $graph->create_iterator;

  # iterate through every node in graph
  while (my $ni = $it->next_node_instance) {
    $depth = $ni->depth;
    $term = $ni->term;
    printf 
      "%s Term = %s (%s)  // ASSOCS=%s\n",
          "----" x $depth,
	  $term->name,
	  $term->public_acc,
	  join("; ",
               map {$_->gene_product->acc} @{$term->association_list});
  }


=cut



=head1 DESCRIPTION

This is a module for accessing Gene Ontology data sources, e.g the GO
relational database. It defines a set of methods that provide a
consistent interface independent of the way the GO data is stored.

For an explanation of the GO project, please visit
hþtp://www.geneontology.org

If you are developing GO applications in perl, this is your main way
into the data. You only need to read this page, and possibly the
perldocs for GO::Model::Term, GO::Model::Association,
GO::Model::Graph, etc

e.g. 

  perldoc GO/Model/Term.pm
  perldoc GO/Model/Relationship.pm
  perldoc GO/Model/Graph.pm

Or, if you reading this from the web

L<GO::Model::Term>

L<GO::Model::Graph>

L<GO::Model::Relationship>

L<GO::Model::Association>

L<GO::Model::GeneProduct>

L<GO::Model::Evidence>

You can view the object model diagram at
http://www.godatabase.org/dev/go-perl/doc/go-perl-doc.html

if you have installed the GO perl modules, you should have manpages
already - e.g. try "man GO::Model::Graph"

=head1 PUBLIC METHODS - AppHandle


=cut


use strict;
use Carp;
use base qw(GO::ObjFactory);

=head2 connect

  Usage   - $apph = AppHandle->connect(-dbname=>"go");
  Usage   - $apph = AppHandle->connect(-ior_url=>$url);
  Usage   - $apph = AppHandle->connect(-dbname=>"go", 
				       -dbiproxy=>"hostname=blahblah.geneontology.org;port=3335");
  Usage   - $apph = AppHandle->connect(\@my_args);
  Returns - an object implementing GO::AppHandle
  Args    - either array or reference to an array

This is the call you make to receive an API handle. 


The argument array should be passed as alternate key/value pairs, with
keys preceeded by a hyphen.  if an array *reference* is passed as an
argument, all the key/value pairs that are recognised will be
processed and removed from the array. This means you can write unix
command line scripts like this:

  # usage: myscript.pl [-dbname db] [-ior_url url] [etc] ACCESSION
  $apph=AppHandle->connect(\@ARGV);
  my $go_id = shift @ARGV;
  print $apph->get_term($go_id)->description();

and defer the decision as to how to connect to the user.

You can also specify default settings in a file $HOME/.geneontologyrc
e.g.

  dbname go
  dbhost gomysql.geneontology.org

=head2 connection parameters

These are the parameters that are currently recognised:

=over

=item -dbname [or -d]

name of database; usually "go" but you may want point at a test/dvlp database

=item -dbuser 

name of user to connect to database as; optional

=item -dbauth

password to connect to database with; optional

=item -dbh

if you like, you can pass in your own DBI handle object; it is
recommended you dont and instead let the connect() method create this
for you

=item -dbhost [or -h]

name of server where the database server lives; see
http://www.godatabase.org/dev/database for details of which servers
are active. or you can just specify "localhost" if you have go-mysql
installed locally

=item -dbiproxy

address of proxy server; if you wish to connect remotely, and there is
a go proxy server running you can use this in combination with -dbname.

[in order to use this, you will need DBI installed]

currently there is no stable proxy server running

=item -ior_url

url serving the IOR (internet orb reference) for a GO corba server

[in order to use this, you will need an orb, such as orbit, installed]

=item -impl

API Handle implementation; currently either "sql" or "corba". This
parameter is optional, as the implementation is inferred by the
presence of the parameters above

=back

=cut

sub connect {

    my $class = shift;

    my $init_h = $class->parse_connect_args(@_);

    my $is_corba = 0;
    my $is_sqlimpl = 0;
    my $is_cwrapper = 0;

    if ($init_h->{dbname} || $init_h->{dbiproxy} || $init_h->{dbh}) {
	$is_sqlimpl = 1;
    }

    if ($init_h->{ior_url}) {
	$is_corba = 1;
    }
    if ($init_h->{ior_file}) {
	$is_corba = 1;
    }
    if ($init_h->{files}) {
	$is_cwrapper = 1;
    }

    if ($init_h->{impl}) {
	if (lc($init_h->{impl}) eq 'corba') {
	    $is_corba = 1;
	}
	elsif (lc($init_h->{impl}) eq 'sql') {
	    $is_sqlimpl = 1;
	}
	else {
	    # default to sql
	    $is_sqlimpl = 1;
	}
    }

    my $schema = $init_h->{schema} || 'godb';

    my $app_handle;

    if ($is_corba + $is_sqlimpl + $is_cwrapper < 1) {
	confess("implementation not specified; ".$class->usage);
    }
    elsif ($is_corba + $is_sqlimpl + $is_cwrapper > 1) {
	confess("cant mix corba and sql context; ".$class->usage);
    }
    else {
	if ($is_corba) {
	    require GO::CorbaClient::Session;
	    $app_handle =
	      GO::CorbaClient::Session->new($init_h);
	}
	elsif ($is_sqlimpl) {
            if ($schema && $schema eq 'chado') {
                require "GO/AppHandles/AppHandleChadoSqlImpl.pm";
                $app_handle =
                  GO::AppHandles::AppHandleChadoSqlImpl->new($init_h);
            }
            else {
                require "GO/AppHandles/AppHandleSqlImpl.pm";
                $app_handle =
                  GO::AppHandles::AppHandleSqlImpl->new($init_h);
            }
	}
	elsif ($is_cwrapper) {
	    require "GO/AppHandles/AppHandleCWrapper.pm";
	    $app_handle =
	      GO::AppHandles::AppHandleCWrapper->new($init_h);
	}
	else {
	    confess("Assertion error");
	}
    }
    $app_handle->user($init_h->{user});
    
    return $app_handle;
}

sub parse_connect_args {
    my $class = shift;

    my $init_h = {};
    my $done = 0;
    my @args = @_;
    my @unused = ();
    my $argref;
    if (ref($args[0])) {
	$argref = $args[0];
	@args = @$argref;
    }
    while (@args && !$done) {
	my $switch = shift @args;
	if ($switch =~ /^\-/) {
	    $switch =~ s/^\-//;
	    if (grep {$_ eq "$switch"} $class->switches ) {
		$init_h->{$switch} = 
		  shift @args || confess("-$switch must be followed by value;".
					 $class->usage);
	    }
	    else {
		push(@unused, "-$switch");
		push(@unused, shift @args) if @args;
	    }
	}
	else {
	    $done = 1;
	    @args = ($switch, @args);
#	    confess("$switch not preceeded by '-' ".$class->usage);
	}
    }
    if ($argref) {
	@$argref = (@unused, @args);
    }

    if ($init_h->{d}) {
	$init_h->{dbname} = $init_h->{d};
    }
    if ($init_h->{h}) {
	$init_h->{dbhost} = $init_h->{h};
    }
    if ($init_h->{u}) {
	$init_h->{dbuser} = $init_h->{u};
    }
    if ($init_h->{p}) {
	$init_h->{dbauth} = $init_h->{p};
    }
    return $init_h;
}

sub switches {
    qw(dbms schema impl d dbname h dbhost dsn port ior_url ior_file dbiproxy dbi_search_path objcache_on files dbuser u dbauth p dbh dbport dbsocket local-infile);
}

sub usage {
    my $class = shift;
    return $class.'->new(-argA=>$valA, -argB=>$valB, ...)'; 
}

sub user {
    my $self = shift;
    $self->{user} = shift if @_;
    return $self->{user};
}

=head1 DATA SOURCE QUERYING METHODS

=head2 timestamp

  Usage   - my $time = $apph->timestamp;
  Usage   - my $pp_time = localtime($apph->timestamp);

returns the timestamp for the data; eg if the datasource is an sql
database loaded from the flatfiles, this returns the time at which the
load was initiated

=head2 get_term

  Usage   - my $term = $apph->get_term({acc=>3677})
  Usage   - my $term = $apph->get_term({search=>"apoptos*"})
  Returns - GO::Model::Term
  Args    - constraints [hashref], attributes [array ref], template

See L<GO::Model::Term>

=head2 get_terms

  Usage   - my $term_l = $apph->get_terms({search=>"apoptos*"})
  Usage   - my $term_l = $apph->get_terms({product=>"ninaA"})
  Returns - arrayref of GO::Model::Term
  Args    - constraints [hashref], attributes [array ref], template


fetches a term or list of terms from the database

See L<GO::Model::Term>

specify the term by the constraints hashref; the keys can be any of:

=over

=item name

  my $term = $apph->get_term({name=>"DNA binding"})

fetches a term by it's name/description

=item type

  my $terms = $apph->get_terms({type=>"biological_process"})

constrains search by ontology

=item synonym

  my $term = $apph->get_term({synonym=>"RNAi"})

fetches a term by it's synonym

=item subset

  my $term = $apph->get_term({subset=>"goslim_plant"})

Finds all terms in goslim_plant.

The goslims themsleves can be retrieved as terms, like this:

  my $goslim_plant = $apph->get_term({acc=>"goslim_plant"})

You can get all slims like this:

  my $slims = $apph->get_terms({term_type=>"subset"})

=item acc

  my $term = $apph->get_term({acc=>3677})

fetches a term by its GO ID/accession
(expressed as an integer, without the GO: prefix)

You can specify multiple accs as an arrayref

=item search

  my $term_l = $apph->get_terms({search=>"apoptos*"})

fetches a term or terms by doing a search on name/description,
synonyms, definition, xrefs (eg swissprot keywords), comments,
obsoletes

search can have "*" as wildcards

ADVANCED SEARCH OPTIONS:
you can also specify a list of fields to search, eg:

  # all terms with carbohydrate in name or synonym field
  my $term_l = 
    $apph->get_terms({search=>"carbohydrate*",
		      search_fields=>"name,synonym"});

  # search all fields except definition
  my $term_l = 
    $apph->get_terms({search=>"carbohydrate*",
		      search_fields=>"!definition"});

  # equivalent to the above
  my $term_l = 
    $apph->get_terms({search=>"carbohydrate*",
		      search_fields=>"name,synonym,dbxrefs,comments"});

(NOTE: dont leave spaces between commas)

=item product

  my $term_l = $apph->get_terms({product=>"ninaA"})

fetches terms for which there is an association to
the specified gene product.

product can either be expressed as a gene product symbol,
or a GO::Model::GeneProduct object or hashreference

  my $term_l = 
    $apph->get_terms({product=>{full_name=>"heat shock protein, DNAJ-like 3"}})

fetches all terms for which there is associations for products
with this full_name

=item product_accs

  my $term_l = 
    $apph->get_terms({products_accs=>["S0004660", "S0004661"]})

=item products

  my $term_l = $apph->get_terms({products=>["mygene1", "mygene2", ....]})

fetches terms for which there is an association to
one of the specified gene products.

product can either be expressed as a list of gene product symbols,
or a list of GO::Model::GeneProduct object or hashreference

  my $term_l = 
    $apph->get_terms({products=>[{acc=>"FBgn0000001"}, {acc=>"FBgn0000002"}]})

fetches all terms for which there is associations for products
with these gene product accessions

  my $term_l = 
    $apph->get_terms({products=>{full_name=>"endothelial cell-selective adhesion molecule"}});

finds the gene product with full_name "endothelial cell-selective
adhesion molecule" and finds the GO terms used to annotate that
product

  my $term_l = 
    $apph->get_terms({products=>{synonym=>"HUF*"}, is_not=>0});

this finds all terms that have products with a synonym matching the
wildcard HUF*. negative annotations are filtered out.

NOTE: when you constrain the list of terms using a product or list of
products, the resulting terms will be adorned with these products,
they can be accessed via 

  $term->selected_association_list 

Rationale: say we have a bunch of proteins that we have clustered eg
via expression data or by sequence analysis; we want to see how that
cluster jives with the GO categorizations.  we can just query terms by
the product list and show how the products are adorned on the tree

=back


note: constraints can also be passed in as an array of name/value pairs

=head2 get_terms_with_associations

  Usage   - my $term_l = $apph->get_terms_with_associations({acc=>3677})
  Returns - arrayref of GO::Model::Term
  Args    - constraints [hashref], attributes [array ref], template

See L<GO::Model::Term>

This will fetch a list of terms, including all the ones specified by
the constraints hash, and also including any child terms of these
terms. It will also populate $term->association_list for each of
these. Any terms that do not have any associations are filtered out.

Rationale: often we want to fetch a list of gene products for any
particular term, and also fetch gene products beneath this term. We
could use $term->deep_products() but we would lose information on how
each term is associated to each product.

The following piece of code illustrates how this may be used:

  # fetch all terms with associations that are DNA Binding (GO:0003677)
  # fetches all subtypes of DNA binding, so long as they have
  # associations attached
  my $tl = $apph->get_terms_with_associations({acc=>3677});
  foreach my $t (@$tl) {
    my $al = $t->association_list;
    foreach my $a (@$al) {
        printf(
               "%s %20s %s %s %s\n",
               $t->public_acc,
               $t->name,
               $a->gene_product->symbol,
              );
    }
  }

filters: $apph->filters will be respected in constructing this query

developes note: see test t290 for specification of this behaviour

TEMPLATES (optional):

the term object is attached to other objects like this:

  GO::Model::Term --->[n] GO::Model::Association --->[1] GO::Model::Product
                                 |
                                 |
                                 ------------------->[n] GO::Model::Evidence

you can specify that only a subset of this info is retrieved via
templates, like this:

  # this just gets the GO::Model::Term object, no associations
  $term = $apph->get_term({acc=>3677}, "shallow");

  # this just gets the accession and definition fields
  $term = $apph->get_term({acc=>3677}, {acc=>1, definition=>1});





=head2 get_term_by_acc

  Usage   - my $term = $apph->get_term_by_acc(3677)
    Or    - my $term = $apph->get_term_by_acc("GO:0003677")
  Returns - GO::Model::Term
  Args    - accession (GO ID) + same args as get_term


See L<GO::Model::Term>


=head2 get_terms_by_search

  Usage   - my $term = $apph->get_term_by_search("*membrane*")
  Returns - GO::Model::Term
  Args    - search term + same args as get_term

use asterisk as the wildcard

See L<GO::Model::Term>

=head2 get_root_term

  Usage   - my $term = $apph->get_root_term;

  returns GO::Model::Term for top node in entire complete ontology
  (ie Gene_Ontology)

See L<GO::Model::Term>

=head2 get_ontology_root_terms

  Usage   - my $terms = $apph->get_ontology_root_terms;

  returns GO::Model::Term list for top nodes in individual ontologies
  (ie process, function, compinent)

See L<GO::Model::Term>

=head2 get_relationships

  Usage   - my $rel_l = $apph->get_relationships({parent_acc=>3677});
  Returns - list reference of GO::Model::Relationship objects
  Args    - constraints hashref

constraints:
  parent_acc (integer) GO ID of parent term
                       (ie will return all arcs pointing down)
  child_acc  (integer) GO ID of child term
                       (ie will return all arcs pointing up)
  parent     (GO::Model::Term) all rels for which this is a parent
  child      (GO::Model::Term) all rels for which this is a child

TODO: constrain by type

See L<GO::Model::Term>

=head2 get_parent_terms

  Usage   - my $term_lref = $apph->get_parent_terms($term);
  Returns -
  Args    -

See L<GO::Model::Term>

=head2 get_child_terms

  Usage   - my $term_lref = $apph->get_child_terms($term);
  Returns -
  Args    -

See L<GO::Model::Term>

=head2 get_associations

  Usage   - $assocs = $apph->get_associations(-term=>{acc=>3677}, 
                                              -options=>{direct=>1});
    Or    - $assocs = $apph->get_associations({name=>"DNA supercoiling"});
    Or    - $assocs = $apph->get_associations({name=>"DNA supercoiling"},
                                              {evcodes=>["IEA", "ISS"]});
  Returns - listref of GO::Model::Association
  Args    - -term => term constraints (or GO::Model::Term object)
            -constraints => other constraints hashref
            -template => template
            -options => hashref

See L<GO::Model::Association>

this will fetch a list of associations for any term. it will also get
associations for subtypes of this term. for instance

  my $apph = GO::AppHandle->connect($connect_params);
  my $term = $apph->get_term({name=>"DNA binding"});
  my $assocs = $apph->get_associations(-term=>$term,
                                       -options=>{direct=>1});
  foreach my $assoc (@$assocs) {
    printf " gene product:%s %s:%s\n", 
            $assoc->gene_product->symbol,
            $assoc->gene_product->speciesdb,
            $assoc->gene_product->acc;
  }

will fetch and print all genes associated with DNA binding *plus* all
genes associated with different kinds of DNA binding (eg DNA
supercoiling)

the default is to descend the GO graph; if direct=>1 is specified then
only gene associations *specifically with that term* are fetched. (Or
you can also use one of the methods below)

=head2 get_all_associations

  Usage   - $assocs = $apph->get_associations({acc=>3677});
    Or    - $assocs = $apph->get_associations({name=>"DNA supercoiling"});

same as get_associations() 

ie this fetches all associations directly attached to a term plus all
descendants of that term. (for example if the term is "receptor",
associations attached to "trasmembrane receptor" *WILL* be
fetched.

See L<GO::Model::Association>

=head2 get_direct_associations

  Usage   - $assocs = $apph->get_associations({acc=>3677});
    Or    - $assocs = $apph->get_associations({name=>"DNA supercoiling"});

same as get_associations() with direct=>1

ie this fetches all associations directly attached to a term (for
example, if the term is "receptor", associations attached to
"trasmembrane receptor" will *NOT* be fetched.

See L<GO::Model::Association>

=head2 get_product

  Usage   - $product = $apph->get_product({symbol=>"Cyp1a1"});
     Or   - $product = $apph->get_product({synonym=>"HUF*"});
     Or   - $product = $apph->get_product({acc=>"FBgn0002936"});
     Or   - $products = $apph->get_products({speciesdb=>"MGI"});
     Or   - $products = $apph->get_products({taxid=>[7227]});
     Or   - $products = $apph->get_products({qualifier_taxid=>[7227]});
     Or   - $product = $apph->get_product({term=>3677});
     Or   - $products = $apph->get_products({terms=>[@terms]});
  Returns - GO::Model::GeneProduct
  Args    - constraints attributes
            constraints: symbol, acc, speciesdb, taxid, term, terms

See L<GO::Model::GeneProduct>

give the constraint 'deep' if you want to fetch all the products for a
term an its subterms

eg

  # fetch all products attached to this node
  # and all children of this node; exclude NOT associations
  $prods = 
    $apph->get_products({deep=>1,
                         is_not=>0,
                         term=>{name=>"carbohydrate metabolism"}});

bear in mind that the above search is constrained by the evidence
codes filter (which is !IEA by default). to get all products attached
to carbohydrate metabolism or its children for which the association
is IDA or IPI do this first:

  $apph->filters({evcodes=>["IDA", "IPI"]});

MULTIPLE TERMS

by default, "or" is used to combine terms; eg

  $prods = $apph->get_products({terms=>[6955, 5887]})

gets all products that are annotated to immune response OR integral membrane protein

if you want all products that are annotated to
immune response AND integral membrane protein, then do this:

  $prods = $apph->get_products({terms=>[6955, 5887], operator=>"and"})

=head2 get_products

  Usage   - as get_product
  Returns - array ref of GO::Model::Product
  Args    - as get_product

See L<GO::Model::GeneProduct>

=head2 get_deep_products

  Usage   - as get_product
     e.g    $apph->get_deep_products({term=>"transmembrane receptor"});
  Returns - array ref of GO::Model::Product
  Args    - as get_product

fetches all products attached to a term *and any of its children*

this is exactly the same as calling get_products() with the deep=>1
constraint

for example, the above queries gets gene products that are any kind of
transmembrane receptor - e.g. GPCR

if you have set the filters in using the filters() method then these
filters will be used in the query, unless you override them

See L<GO::Model::GeneProduct>

=head2 get_product_count

  Usage   - $apph->get_product_count({term=>$term});
  Usage   - $apph->get_product_count({term=>$term,
                                      evcodes=>["!IEA"],
                                      speciesdbs=>["SGD", "MGI", "WormBase"]});
  Usage   - $apph->get_product_count({term=>$term,
                                      taxids=>[7227, 9606]});
  Usage   - $apph->get_product_count({term=>$term,
                                      taxids=>[5691], # parasite
                                      qualifier_taxids=>[9606,9313], # hosts
                                      });
  Returns - int
  Args    - constraints

gets the count for the number of gene products annotated at BUT NOT
BELOW this level. if you have set the filters in using the filters()
method then these filters will be used in determining the count,
unless they are overridden by consteraints you pass in

term should be a L<GO::Model::Term> object, or a term constraint, for example:

  $apph->get_product_count({term=>{name=>"compound eye morphogenesis"}})

=head2 get_deep_product_count

  Usage   - $apph->get_deep_product_count({term=>$term});
  Usage   - $apph->get_deep_product_count({term=>$term,
                                           evcodes=>["!IEA"],
                                           speciesdbs=>["SGD", "MGI", "WormBase"]});
  Returns - int
  Args    - constraints

gets the count for the number of gene products annotated at OR BELOW
this level. if you have set the filters using the filters() method
then these filters will be used in determining the count, unless they
are overridden by consteraints you pass in


=head2 get_node_graph

  Usage   - my $graph = $apph->get_node_graph($acc, $depth)
        or  my $graph = $apph->get_node_graph(-acc=>$acc, -depth=>$depth)
        or  my $graph = $apph->get_node_graph(-acc=>$acc, 
					      -depth=>$depth,
					      -template=>{terms=>$ttmpl})
  Returns - GO::Model::Graph object
  Args    - acc, depth, template

See L<GO::Model::Graph>

use this whenever you want to get a subgraph of the whole GO graph to
a particular depth

the default action is to populate the graph up to 2 down,
and all the way to the top.

=head2 get_graph

 synonym for get_node_graph

=head2 get_graph_by_acc

 synonym for get_node_graph

=head2 get_graph_by_search

  Usage   - $graph = $apph->get_graph_by_search("*binding*", 3)
  Returns - GO::Model::Graph
  Args    - search term, depth [optional - 2 if omitted], template

finds all the terms that satisfy the search constraints, builds a
subgraph of the whole GO graph that contains all these terms, then
populates the graph downwards to the specified depth, and populates
the graph with all paths from the terms up to the root term.

See L<GO::Model::Graph>

=head2 get_graph_by_terms

  Usage   - $graph = $apph->get_graph_by_terms(\@terms, 3)
  Usage   - $graph = $apph->get_graph_by_terms(-terms=>\@terms, 
                                               -depth=>3,
                                               -template=>{traverse_up=>0,
                                                           traverse_down=>1})
  Returns - GO::Model::Graph
  Args    - GO::Model::Term list, depth [optional - 2 if omitted], template


Builds a subgraph of the whole GO graph that contains all the input
terms, then populates the graph downwards to the specified depth, and
populates the graph with all paths from the terms up to the root term.

See L<GO::Model::Graph>


=head2 extend_graph

  Usage   - $apph->extend_graph($graph, $acc, $depth)
  Returns -
  Args    - GO::Model::Graph, acc, depth, template

See L<GO::Model::Graph>

=head2 get_paths_to_top

  Usage   - $path_l = $apph->get_paths_to_top({acc=>'GO:0003677'})
  Returns - array ref of GO::Model::Path
  Args    - same constraints as get_term(...)

returns all the different paths to the root of the GO graph from any
point

See L<GO::Model::Path>

=head2 get_species_list

  Usage   - $list = $apph->get_species_list
  Returns - arrayref of GO::Model::Species
  Args    -

returns a list of species for which there is at least one annotation

See L<GO::Model::Species>

=head2 get_speciesdbs

  Usage   - $list = $apph->get_speciesdb_dict
  Returns - arrayref of speciesdbs
  Args    - [optional constraints hashref]

Returns a list of speciesdbs. A speciesdb is a database that
contributes associations; eg MGD, FB etc.

Speciesdb to species is often not one-to-one; eg SWISS-PROT may in
future contribute associations for all species

See L<GO::Model::Species>

=head2 get_speciesdb_dict

  Usage   - $sd = $apph->get_speciesdb_dict
  Returns - dictionary/hashref of speciesdb->species objects
  Args    - [optional constraints hashref]

returns a lookup table keyed by species database name that point to
Bio::Species objects (this is a bioperl object, you will need bioperl
installed to make this call - see http://www.bioperl.org)

it is important to make the distinction between species and the
speciesdb/datasource. associations are grouped in GO according to
their source (eg SGD, FlyBase, MGI, Compugen). Currently there is a
1<->1 mapping between the source and species but this need not always
be the case.

If you just want a list of sources/contributing databases, do this:

   $sd = $apph->get_speciesdb_dict;
   @sources = keys %$sd;

or you can get the database and the species like this:

   $sd = $apph->get_speciesdb_dict;
   foreach my $src (keys %$sd) {
      my $species = $sd->{$src};
      printf "source:%s common_name:%s\n",
      $src, $species->common_name
   }

see the bioperl docs for the Bio::Species object

(not all attributes are currently filled)

=head2 get_seq

  Usage   - $list = $apph->get_seq({display_id=>"Q9XHP0"})
  Returns -  GO::Model::Seq
  Args    -

=head2 get_dbs

  Usage   - $dbs = $apph->get_dbs({name=>"ZFIN"});
  Returns - arrayref of L<GO::Model::DB>
  Args    - [optional constraints hashref]

Must have dbs loaded into database; this is typically sourced from
L<http://www.geneontology.org/doc/GO.xrf_abbs>

Any column from the db table can be used as a constraint

=head2 acc2name_h

  Usage   - $n = $apph->acc2name_h->{$go_id}
  Returns - string
  Args    - acc string

returns a hash mapping between term IDs and term names derived from db

=head2 get_statistics

  Usage   -
  Returns - GO::Stats object
  Args    -

=cut




=head2 filters

  Usage   - $apph->filters({evcodes=>["!IEA"]});
  Returns -
  Args    - hashref of filter types, each value is an arrayref
            filter types: speciesdb, evcodes

gets/sets default filters for querying data; when an AppHandle is
initialized, the default filter should be ["!IEA"] (this is because
there are so many IEAs it makes things disproportionately slower, and
this will also discourage circular annotations)

Any value can be negated with the exclamation mark

  # only get associations that are direct assays or
  # traceable author statements
  $apph->filters({evcodes=>["IDA", "TAS"]});
  $graph = $apph->get_graph(5054);
  $graph->to_text_output(1);

  # only get associations that are 
  # in FB (flybase) or MGD (mouse)
  # default ev code filter !IEA will be used
  $apph->filters({filters=>["FB", "MGD"]});
  $graph = $apph->get_graph(5054);
  $graph->to_text_output(1);

It is very important to understand GO evidence codes. See
http://www.geneontology.org for details

See L<GO::Model::Evidence> and L<GO::Model::Association>

=cut

sub filters {
    my $self = shift;
    $self->{_filters} = shift if @_;
    return $self->{_filters};
}


=head2 evidence_codes

  Usage   - @codes = $apph->evidence_codes;
  Returns -
  Args    -

See L<GO::Model::Evidence>

=cut

sub evidence_codes {
    my $self = shift;
    use GO::Model::Evidence;
    return GO::Model::Evidence->valid_codes;
}


=head1 ANALYSIS METHODS

=head2 get_enriched_term_hash

  Usage   - $eh = $apph->get_enriched_term_hash( $products )
  Returns - hash
  Args    - listref of L<GO::Model::Product> OR listref of product constraint hashes

NOT YET FULLY TESTED

Requires L<GO::TermFinder> (separate CPAN distribution)

Performs a term enrichment analysis. Uses hypergeometric distribution,
takes entire DAG into account.

First the database will be queried for matching gene products. Any
filters in place will be applied (or you can pass in a list of gene
products previously fetched, eg using $apph->get_products).

The matching products count as the *sample*. This is compared against
the gene products in the database that match any pre-set filters
(statistics may be more meaningful when a filter is set to a
particular taxon or speciesdb-source).

We then examine terms that have been used to annotate these gene
products. Filters are taken into account (ie if !IEA is set, then no
IEA associations will count). The DAG is also taken into account - so
anything annotated to a process will count as being annotated to
biological_process. This means the fake root "all" will always have
p-val=1. Currently the entire DAG is traversed, relationship types are
ignored (in future it may be possible to specify deduction rules -
this will be useful when the number of relations in GO progresses
beyond 2, or when this code is used with other ontologies)

Results are returned as a hash-of-hashes, outer hash keyed by term
acc, inner hash specifying the fields:

=over

=item term

a L<GO::Model::Term> object

=item n_gps_in_sample_annotated

number of the initial product list that was fed in that are annotated
(by transitivity, including filters) to this term

=item n_gps_in_sample

number in the initial product list

=item n_gps_in_database_annotated

number of products in database that are annotated (by transitivity) to this term

filters are applied

=item n_gps_in_database

number of products in database (after filters are applied)

=item gps_in_sample_annotated

a listref that is a subset of the original L<GO::Model::GeneProduct>
list; the ones that are annotated (by transitivity, including filters)
to this term

=item p_value

probability that this term occurs by chance

See
L<http://genome-www5.stanford.edu/help/GO-TermFinder/GO_TermFinder_help.shtml>

for a full explanation

=back

=item 

  $apph->filters({speciesdb=>"SGD",evcodes=>["!IEA"]});
  my @pqs = map { {synonym=>$_} } qw(YNL116W YNL030W YNL126W);
  my $eh = $apph->get_enriched_term_hash(\@pqs);
  my @erows =
    sort {
      $a->{p_value} <=> $b->{p_value}
    } values %$eh;
  foreach (@erows) {
    next unless $_->{p_value} <= 0.1;
    next if $_->{n_gps_in_sample_annotated} < 2;
    
    printf("%s sample:%d/%d database:%d/%d P-value:%s \"%s\" Genes: %s\n",
           $_->{term}->acc,
           $_->{n_gps_in_sample_annotated},
           $_->{n_gps_in_sample},
           $_->{n_gps_in_database_annotated},
           $_->{n_gps_in_database},
           $_->{p_value},
           $_->{term}->name,
           join('; ',map {sprintf("%s[%s]", $_->symbol, $_->acc)} @{$_->{gps_in_sample_annotated}}))
  }
  

Use L<GO::TermFinder> - you must have this installed to use this
method (you can still use the rest of this module without
GO::TermFinder)

See also
L<http://genome-www5.stanford.edu/help/GO-TermFinder/GO_TermFinder_help.shtml>

=head3 Not implemented

Bonferroni method 

=head1 AUDIT METHODS


=head2 source_audit

  Usage   -
  Returns -
  Args    -

returns a listref of hashes

  [
   {source_type => 'file',
    source_path => 'function.ontology',
    source_mtime => 1233456787
   },
   {source_type => 'file',
    source_path => 'process.ontology',
    source_mtime => 1233456999
   },
  ]

times are unixtimes

=cut


=head2 instance_data

  Usage   -
  Returns -
  Args    -

returns a hash

  {release_name => 'go_200212',
   release_type => 'seqdb',
   release_notes => ''
  }

=cut


=head2 get_term_loadtime

  Usage   -
  Returns -
  Args    - acc

returns unixtime for when the term was loaded into the db

=cut

=head1 DATA SOURCE SPECIFIC METHODS

These only work on the SQL implementation. You only need to call these
if you are populating a GO database with your own data.

=head2 add_root

  Usage   - $apph->add_root
  Returns -
  Args    - name of root node [optional]

GO::AppHandle assumes that there is exactly one global root node

The OBO file format allows unrooted terms - after loading an ontology,
this method should be called. It creates a new global root (default
name "all"), and de-roots the existing root nodes and places them
under this node

=head2 fill_path_table

  Usage   - $apph->fill_path_table
  Returns -
  Args    -

Builds the transitive closure table; see also
L<http://www.godatabase.org/dev> for docs

Once you have finished loading all your *terms* and their
relationships into your GO database instance, you can call this method
to populate the *path* table. the SQL implementation of AppHandle
recognises when the path table is populated, and will use it to make
queries (involving graphs, etc) more efficient.

Note: normally you dont have to worry about using this call yourself,
if you use the L<scripts::load-go-into-db> script this will get called for you.

=head3 CURRENT LOGIC

We express the current implementation using horn clause logical rules:

Rule 1 - reflexivity; every term is reflexively related to itself with distance 0

  graph_path(Term,Term,0).

Rule 2 - direct relationships; every term is linked to its parent with distance 1

  graph_path(Term,Parent,1) <- term2term(Term,Parent)

Rule 2 - transitive relationships; note recursive definition.

  graph_path(Term,Ancestor,D+1) <- term2term(Term,Parent), graph_path(Parent,Ancestor,D)

To see the actual implementation, look at the source. See also L<GO::Model::GraphIterator>

=head3 FUTURE PLANS

The current implementation builds a transitive closure over ALL relations indiscriminitely

In future we will want to build a deductive closure on a per-relation
basis (use case: when querying for gene expression results, the user
may want to see genes that are expressed in subtypes or parts, but NOT
following the develops_from relation)


=cut


=head2 fill_count_table

  Usage   - $apph->fill_count_table
  Returns -
  Args    - evcode array (optional), reltype array (optional)

Once you have finished loading all your *associations* into your GO
database instance, you can call this method to populate the
*gene_product_count* table. The SQL implementation of AppHandle
recognises when the gene_product_count table is populated, and will
use it to make GO::Model::Term->n_deep_product() calls more efficient.

Note: normally you dont have to worry about using this call yourself,
if you use the load-assocs.pl script this will get called for you.

Currently the default is to give recursive product counts for non-IEA
evidence codes; if you want to get the count for ALL annotations, do this:

  $apph->fill_count_table([""]);

which is a little abstruse

Currently the default is to give recursive product counts for all
relationship types.

To get recursive product counts for only is_a and part_of and non_IEA
evidence codes, do this:
   $apph->fill_count_table(undef, ['is_a', 'part_of']);

In the future it may be desirable to have seperate recursive product
counts for different evidence codes. the time/space tradeoff becomes
more expensive here, ie you would have to wait a long time for the
table to fill, and it would take up a lot of space. Currently this is
not an option, but the code could easily be modified to do this, if
desired. One difficulty is that the counts divided by evidence code
are *not* additive, unlike the counts divided by speciesdb (this is
because a single product cannot exist in >1 speciesdb, but a single
product can be annotated with multiple associations with differing
evidence codes)

once this has completed, you will be able to do this

 $term = $apph->get_term({acc=>"GO:0003677"});
 $recursive_product_count = $term->n_deep_products();

[this will be *very* slow unless you have filled the count table]

=cut

=head1 INHERITANCE

This class inherits from L<GO::ObjFactory>, in the go-perl
package. This class inherits all the methods of this class, but you
should not need to use them directly

=head1 HOW IT WORKS

  GO::AppHandle 'dispatches' the method calls to an actual
  implementation object for actual execution. The GO::AppHandle object
  is also responsible for the dynamic loading of implementations,
  checking/handling and other duties. (Users of the DBI database access
  module should find this familiar).


                         .-.   .---------------------------.
         .-------.       | |---| AppHandleSqlImpl          |--- DBI
         | Perl  |       | |   `---------------------------'
         | script|  |A|  |A|   .---------------------------.
         | using |--|P|--|p|---| CorbaClient::Session      |--- IIOP
         |       |  |I|  |p|   `---------------------------'
         | API   |       |H|...
         |methods|       |d|... Other implementations
          -------'       |l|... (e.g C language wrapper)
                         `-'            `  

GO::AppHandle hides the implementation specific details, and provides
a robust, consistent interface which should be reasonably constant in
the face of changes in relational tables, distribution mechanism etc.

If you write tools in perl that use AppHandle, the exact same code
will (in theory) work, whether the tool is deployed as a server-side
application with direct database connectivity, or as a client-side
application using corba as a distribution mechanism.

It also allows us to plug in different implementations (e.g. object
database, xml database, prolog predicate list or lisp knowledge base,
...)

=head1 TEMPLATES (optional)

whenever you ask for an object from the database, this API will return
that object and some other associated objects. for instance, if you
ask for a GO::Model::Term object, you will receive attached to that
object a list of GO::Model::Xrefs, definitions, synonyms etc.

This behaviour may not always be desirable. if you are doing a search
purely for GO accessions, for instance, you dont want the extra SQL
overhead of fetching synonyms etc.

You can ask for only a subset of possible data to be returned by
specifying an object "template".

  # this just gets the GO::Model::Term object, no associations
  $term = $apph->get_term({acc=>3677}, "shallow");

  # this just gets the accession and definition fields
  $term = $apph->get_term({acc=>3677}, {acc=>1, definition=>1});

  # no template specified; the current default behaviour
  # is to fetch everything except the full association list
  # note that the association count is prefetched, so you can
  # say $term->n_associations()
  $term = $apph->get_term({acc=>3677});

not all implementations respect the templates; the default will
generally be in favour of getting too much data.

as of April 2001, this API has been implemented such that some data
such as associations are fetched on-demand.

this means you can ignore templates and just use the default, eg

  $term = $apph->get_term({acc=>3677});

then when you enquire about the associations attribute like this

  foreach my $assoc (@{$term->association_list}) {
    ....
  }

the associations will be fetched;

you can still ask for all the associations up-front; in some
circumstances this will be faster. generally you can choose to ignore
this.

=head1 FEEDBACK

Email cjm AT fruitfly.berkeley.edu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself

=cut


1;


