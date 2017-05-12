#!/usr/local/bin/perl

# GOshell.pl
# cjm@fruitfly.org

use strict;
no strict "vars";
use Carp;
use Data::Dumper;
use GO;
use GO::AppHandle;
#use GO::Tango;
use GO::IO::XML;
use Getopt::Long;
my $h = {};

my $apph;
my $dbname;
my $dbms = "mysql";
my $dbhost = "localhost";

my $HISTFN = "$ENV{HOME}/.goshellhistory";
my @history = ();
my $histfh;
my $suppress;
if (-f $HISTDN) {
    $histfh = FileHandle->new("$HISTFN") || warn($HISTFN);
    @history = <$histfn>;
    $histfh->close;
}
$histfh = FileHandle->new(">$HISTFN");

my @orig = @ARGV;
while (!$apph) {
    getapph();
}
goconnect($apph);
shell($apph);

# ------ subs --------

sub getapph {
    my @conn = @orig;
    eval {
        $apph = GO::AppHandle->connect(\@conn);
    };
    if ($@) {
        print STDERR "Can't connect to @orig [$@]\n";
        print STDERR "Do you want to make this database?\n";
        my $yn = yesno();
        if ($yn) {
            while (my $p = shift @orig) {
                if ($p =~ /^\-dbms/) {
                    $dbms = shift @orig;
                }
                elsif ($p =~ /^\-d/) {
                    $dbname = shift @orig;
                }
                elsif ($p =~ /^\-h/) {
                    $dbhost = shift @orig;
                }
                else {
                }
            }
            gomakedb();
        }
        else {
            print "Goodbye!\n";
            exit 0;
        }
    }
    $species_hash = $apph->get_species_hash;
}


sub yesno {
    my $yn = <STDIN>;
    $yn =~ /^y/i;
}


my $stat_ob;

# prepare for some seriously hacky code....
sub shell {
    $apph = shift;
    my $loadfn = shift;
    my $prompt = $ENV{GO_SHELL} || "GO> ";
    my $quit = 0;
    my @lines = ();
    my $r;
    my $rv;
    my $node;
    my $nodes;
    my $graph;
    #my $gopts = {show_counts=>1};
    my $options = {assocs=>0, graphdepth=>2, echo=>0, chatty=>10, counts=>0,grouped=>0,
                   gopts=>{}};
    my $term_template = "";
    my $outfh;

    if ($loadfn) {
        @lines = ("load '$loadfn'");
    }

    sub hr {
	print "\n===============================\n";
    }

    sub nl {
	print "\n";
    }

    sub tango {
        $tango = GO::Tango->new;
        $tango->apph($apph);
        $tango;
    }

    sub demo {
        @lines = 
          split(/\n/,
                q[
                  $old_assocs = $options->{assocs}
                  +assocs 0
                  +echo 1
                  # GO SHELL DEMO
                  # this is a live show demonstrating
                  # how the various commands work
                  +wait 1
                  # this demo will go through some of
                  # the major commands, feeding you
                  # the commands as you go. all you have
                  # to do is hit <ENTER> every time
                  # you see the prompt $prompt
                  # you will then see the output of
                  # the command on standard out.
                  # type 'q' to end the tour
                  waitenter
                  # ---------------------------------
                  # FINDING GO TERMS
                  #
                  # search for term GO:0005783
                  # then display the basic details
                  ^/5783
                  waitenter
                  # ---------------------------------
                  # SUBGRAPHS
                  # the GO term for ER receptor
                  # is now stored in a register
                  # variable; we can build a graph
                  # displayed around the current term:
                  #
                  waitenter
                  ^graph 
                  #
                  #
                  waitenter
                  # ---------------------------------
                  # ASSOCIATIONS
                  #
                  # so far we haven't been showing
                  # associations; this is the default
                  # behaviour (for speed). we can change 
                  # this by setting the "assocs" option:
                  ^+assocs 1 
                  # assocs is =1
                  #
                  # let's also set the default graph depth
                  ^+graphdepth 0
                  #
                  # print current settings:
                  ^options
                  waitenter
                  #
                  # we can also filter the associations
                  # by the source database like this:
                  ^speciesdbs('sgd');
                  waitenter
                  #
                  # we can query by gene product too
                  ^/product=Mcm10
                  waitenter
                  #
                  # ---------------------------------
                  # MORE SEARCHING
                  # 
                  # to do a text search...
                  ^/endoplasmic*
                  waitenter
                  #
                  # now show the graph, centered
                  # around the terms we have found:
                  ^graph
                  # (we could have also done this by
                  #  typing "graph endoplasmic*")
                  waitenter
                  #
                  # we can make a nice picture like this
                  ^dotty 
                  #
                  #
                  +echo 0
                  $options->{assocs} = $old_assocs;
                 ]);

        @lines = 
          map {
              s/^ *//;
              $_;
          } @lines;
    }

    sub load {
        open(F, shift);
        @lines = map {chomp;$_} <F>;
        close(F);
    }

    sub waitenter {
        print "<hit ENTER to continue>";
        <STDIN>;
    }

    sub showintro {
        hr;
        print "This is a text-based commandline interface to GO;\n";
        print "it is also a perl interpreter and a SQL terminal\n";
        print "\n";
        print "mostly this is just a thin front end to to GO perl API -\n";
        print "see http://www.fruitfly.org/annot/go for details\n\n";
        print "most of the commands are just calls to GO::AppHandle methods\n";
        print "\n\nThis makes the GO shell interface very powerful,\n";
        print "but perhaps somewhat unintuitive to use.\n";
        print "Well, I find it useful. YMMV\n\n";
        
    }

    sub checkoptions {
#        if (!$options->{assocs}) {
#            $term_template = "no_assocs";
#        }
#	else {
#            $term_template = {association_list=>[]};
#	}
    }

    sub set {
        my ($k,$v) = @_;
        $options->{$k} = $v;
        checkoptions;
    }

    sub dotty {
        require "GO/Dotty/Dotty.pm";
        $graphviz =
          GO::Dotty::Dotty::go_graph_to_graphviz( $graph,
                                                  {node => {shape => 'box'},
                                                  });
        #        $graphviz->label_nodes_with_colour([]);
        GO::Dotty::Dotty::graphviz_to_dotty( $graphviz );
    }

    sub common {
        my $term = node();
        require "GO/Dotty/Dotty.pm";
        $prs = $apph->get_products({term=>$term});
        my $terms = $apph->get_terms({products=>$prs});
        $graph = $apph->get_graph_by_terms($terms, 0);
        $graphviz =
          GO::Dotty::Dotty::go_graph_to_graphviz( $graph,
                                                  {node => {shape => 'box'},
                                                   rankdir=>1,
                                                   epsilon=>3,
                                                   concentrate=>1},
                                                  {selected_assocs=>1});
        #        $graphviz->label_nodes_with_colour([]);
        GO::Dotty::Dotty::graphviz_to_dotty( $graphviz );
    }

    sub echo {
        my $e = shift;
        if (defined($e)) {
            set("echo", $e);
        }
        else {
            set("echo", !$options->{echo});
        }
    }

    sub options {
        map {print "$_ = $options->{$_}\n"} keys%$options;
    }

    sub showcommands {
        hr;
        print "GO Shell Commands:\n";
        
        print " !           - shell\n";
        print " /           - search GO for term\n";
        print " :           - SQL query\n";
        print " print       - Show value of variable\n";
        print " x           - Show value of variable (in detail)\n";
        print " +           - Set optional parametr\n";
        nl;
        print " stats       - Show GO DB statistics\n";
        print " tunnel      - SQL query\n";
        print " qgo         - search for GO term\n";
        print " graph       - search for GO term and get graph\n";
        print " showgraph   - show current graph\n";
        print " shownodelist   - show current nodes\n";
        print " options     - show options settings\n";
        print " set         - set options\n";
        print " load        - load file of commands\n";

        print "\n\n";
        print "in addition to the above commands, any perl command\n";
        print "can be used - see 'man perlfunc'\n\n";
    }

    sub showexamples {
        print "\nExamples:\n-------\n";
        
        print "\nquerying GO with '/'\n";
        print "$prompt /3677                 <-- gets term GO:0003677\n";
        print "$prompt /endoplasmic ret*     <-- free text search\n";

        print "\nquerying GO with 'qgo'\n";
        print "$prompt qgo 3677              <-- gets term GO:0003677\n";
        print "$prompt qgo \"endoplasmic ret*\" <-- free text search\n";

        print "\nsetting options using '+' ";
        print "(this turns association fetching ON)\n";
        print "$prompt +assocs 1";

        print "\ndisplaying options\n";
        print "$prompt options";

        print "\nsql queries using ':'\n";
        print "$prompt :select count(*) from term";

        print "\nsql tunneling using 'tunnel' (remember quotes)\n";
        print $prompt.'tunnel "select count(*) from gene_product"';

        print "\ngetting fasta files\n";
        print "$prompt /4888              <-- gets term GO:0004888\n";
        print "                           (gets children too)\n";
        print "$prompt fasta              <-- shows fasta\n";
        print "$prompt fasta 'my.fa'      <-- writes fasta to file\n";
        print "$prompt fasta('my.fa',-getheader=>1) <-- detailed headers\n";
        print "$prompt clustalw           <-- runs clustal on GO:0004888\n";
        print "$prompt dclustalw          <-- runs clustal on GO:0004888\n";
        print "                               and children\n";

    }

    sub showvariables {
        hr;
        print "Shell variables:\n";
        print q[
                $apph    : GO::Model::AppHandle object
                $node    : GO::Model::Term objects
                $nodes   : listref of GO::Model::Term objects
                $graph   : GO::Model::Graph object
                $r       : results of last SQL query
               ];
        nl;
    }

    sub welcome {
	print "Welcome to the Gene Ontology shell interface!\n";
        print "\nby Chris Mungall <cjm\@fruitfly.org>\n";
        print "\n\nType 'help' for instructions\n";
        print "\n\nType 'demo' for demonstration\n";
    }

    sub help {
        if (shift eq "advanced") {
            hr;
            print "\nGO Shell Advanced Options\n\n";
            print "The GO Shell is actually a perl interpreter,\n";
            print "and an SQL terminal with a few predefined methods\n";
            print "\n";
            print "If you're comfortable with perl or SQL, you\n";
            print "have a very powerful interface to the data\n";
            print "at your disposal\n";
            print "\n";
            print "This means that anything you do in perl you\n";
            print "can do here; for instance, try typing\n";
            print "\n";
            print "print 88+77\n";
            print "\n";
            print "You can make any API calls just\n";
            print "by using the preset variable \$apph\n";
            print " -- for instructions on the API, go to \n";
            print "        http://www.fruitfly.org/annot/go/database\n";
            print "\n";
            print "For instance\n";
            print "$prompt ".'$apph->filters({evcodes=>["!IEA"]})'."\n";
            print "$prompt ".'$graph = $apph->get_graph(3677, 3)'."\n";
            print "$prompt print \$graph->node_count\n";
            print "\n";
            print "You can also do queries on the GO database\n";
            print "directly in SQL, just by using the : operator\n";
            print "the results of the query will be put in the\n";
            print "variable \$r\n";
            print "\n";
            print "$prompt :select name, acc from term\n";
            print $prompt.' @accs = map {$_->[1]} @$r '."\n";
            print "\n";
            hr;
            nl;
        }
        else {
            hr;
            print "\nGO Shell Help\n\n";
            showintro;
            waitenter;
            showcommands;
            waitenter;
            showvariables;
            waitenter;
            showexamples;
            nl;
            nl;
            nl;
            print "Type \"demo\" for an interactive demo of commands\n\n";
            print "Type \"help advanced\" for advanced options\n\n";
            hr;
            nl;
        }
    }

    sub p {
	print shift;
	print "\n";
    }

    sub x {
	print Dumper shift;
	print "\n";
    }

    sub stats {
	$stat_ob = $apph->get_statistics($apph);
	$stat_ob->output;
    }

    sub speciesdbs {
        $apph->filters->{speciesdbs} = [@_];
    }
    sub showspeciesdbs {
        print join(", ", @{$apph->filters->{speciesdbs} || []});
    }

    sub taxa {
        $apph->filters->{taxids} = [@_];
    }
    sub showtaxa {
        print join(", ", @{$apph->filters->{taxids} || []});
    }

    sub shownodelist {
	foreach my $node (@$nodes) {
	    shownode($node);
	}
    }

    sub fasta {
      $file = shift;
      $fh = $file ? FileHandle->new(">$file") : \*STDOUT;

        @products = @{node()->deep_product_list};
        map {printf $fh "%s", $_->to_fasta(@_)} @products;
    }

    sub clustalw {
        if (@_) {
            qgo(@_);
        }
        @products = @{node()->product_list};
        use GO::IO::Analysis;
        $an = GO::IO::Analysis->new;
        print $an->clustalw(-products=>\@products);
    }

    sub dclustalw {
        if (@_) {
            qgo(@_);
        }
        @products = @{node()->deep_product_list};
        use GO::IO::Analysis;
        $an = GO::IO::Analysis->new;
        print $an->clustalw(-products=>\@products);
    }

    sub blastp {
        $fn = shift;
        use GO::IO::Analysis;
        $an = GO::IO::Analysis->new;
        $an->apph($apph);
        $blast = $an->blastp($fn);
        $blast->showgraph;
    }

    sub tunnel {
	$r = $apph->_tunnel(@_);
	map { print join(" ", @$_)."\n"} @$r;
    }

    sub xml {
      my $stuff = shift;
      my $output = shift;
      my $out;
      if (defined($output)) {
	  print "WHHEEEEEE";
	  return;
	      
	  $out = new FileHandle($output);  
      } else {
	  $out = new FileHandle(">-");
      }
      my $xml_out = new GO::IO::XML(-output=>$out);
      
      my $ass;
      if ($options->{assocs}) {
	$ass="yes";
      }
      
      $xml_out->start_document;

      if ($stuff->isa("GO::Model::Term")) {
	$xml_out->draw_term(-term=>$stuff,
			   -show_associations=>$ass);
      } elsif ($stuff->isa("GO::Model::Graph")){
	$xml_out->draw_node_graph(-graph=>$stuff,
				 -show_associations=>'no');
      } 
      $xml_out->end_document;
    }

    sub prdfs {
      my $stuff = shift || $graph;
      my $output = shift;
      require "GO/IO/ProtegeRDFS.pm";
      my $out;
      if (defined($output)) {
	      
	  $out = new FileHandle($output);  
      } else {
	  $out = new FileHandle(">-");
      }
      my $xml_out = new GO::IO::ProtegeRDFS(-output=>$out);
      
      my $ass;
      if ($options->{assocs}) {
	$ass="yes";
      }
      
      $xml_out->start_document;

      if ($stuff->isa("GO::Model::Term")) {
	$xml_out->draw_term(-term=>$stuff,
			   -show_associations=>$ass);
      } elsif ($stuff->isa("GO::Model::Graph")){
	$xml_out->draw_node_graph(-graph=>$stuff,
				 -show_associations=>'no');
      } 
      $xml_out->end_document;
    }

    sub qgo {
	my $t = shift;
        $t =~ s/ *$//;
        $t =~ s/^ *//;
        if ($t) {
            my $h = shift;
            if (!$h && $t =~ /(.*)=(.*)/) {
                $h = {$1=>$2};
            }
            if (!$h && $t =~ /^(\S+):(\d+)$/) {
                $h = {acc=>$t};
            }
            if (!$h && $t =~ /^\d+$/) {
                $h = {acc=>$t};
            }
            if (!$h && $t =~ /\*/) {
                $h = {search=>$t};
            }
            if (!$h) {
                $h = {name=>$t};
            }
            $nodes = $apph->get_terms($h, $term_template);
        }
	shownodelist;
    }

    sub node {
	if ($nodes && @$nodes){$nodes->[0]};
    }

    sub graph {
	my $t = shift;
        my $depth = shift;
        my $template = shift || {terms=>$term_template};
	if ($t) {
	    qgo($t);
	}
	if (!defined($depth)) {
	    $depth = $options->{graphdepth};
	}
	$graph = $apph->get_graph_by_terms($nodes, $depth, $template);
	showgraph();
        $graph;
    }

    sub descendants {
	my $t = shift;
        my $template = shift || {terms=>$term_template};
	if ($t) {
	    qgo($t);
	}
	$graph = $apph->get_graph_below($nodes->[0]->acc, -1, $template);
	$graph->iterate(sub {my $ni=shift;my $t=$ni->term;
			     printf "%8s %s\n",
			       $t->acc, $t->name});
        $graph;
    }

    sub showgraph {
#	my @top = @{$graph->get_top_nodes || []};
#	foreach my $n (@top) {
#	    my $parents = $apph->get_parent_terms({acc=>node->acc});
#	    map {
#		printf " ( %s has parent %s %s)\n", $n->name, $_->public_acc, $_->name;
#	    } @$parents;
#	}
	$graph->to_text_output(-fmt=>$fmt || "gotext",
                               -assocs=>$options->{assocs},
                               -fh=>$outfh,
                               -opts=>{%{$gopts || {}},species_hash=>$species_hash,show_counts=>$options->{counts},grouped_by_taxid=>$options->{grouped}},
			       -suppress=>$suppress);
    }

    sub prolog {
        print $graph->to_prolog(@_);
    }

    sub prologdir {
        "$ENV{GO_ROOT}/prolog";
    }

    sub xsbcmd {
        system("sh -c 'xsb -e [tmp]. -e [go].'");
    }

    sub xsb {
        my $prg = $graph->to_prolog(@_);
        my $pd = prologdir;
        chdir($pd);
        open(F, ">tmp.P") || warn("can't write");
        print F $prg;
        close(F);
        xsbcmd;
    }

    sub shownode {
	$node = shift || node();
	hr;
	printf "NAME  : %s\n", $node->name;
	printf "GO ID : %s\n", $node->public_acc;
	printf "ASPECT: %s\n", $node->type;
	printf "DESC  : %s\n", $node->definition;
	printf "CMNTS : %s\n", $node->comment || '';
	printf 
	  "DEFREFS: %s\n",
              join(", ", 
                   map {$_->xref_dbname.":".$_->xref_key." ".$_->xref_desc} 
		   @{$node->definition_dbxref_list || []});
	nl;
	printf 
	  "SYNONYMS : %s\n",
	  join(", ", @{$node->synonym_list || []});
	nl;
        if( $options->{dbxrefs} ){
          printf 
            "DBXREFS : %s\n",
              join(", ", 
                   map {$_->xref_dbname.":".$_->xref_key." ".$_->xref_desc} 
                   @{$node->dbxref_list || []});
          nl;
        }
        if ($options->{assocs}) {
            my @prods = keys %{$node->association_hash || {}};
            printf 
              "ASSOCIATIONS : (total %d)\n", $node->n_associations || 0;
            printf
              join("\n", 
                   map {
		       my $gp = $node->association_hash->{$_}->[0]->gene_product;
                       sprintf("  $_ : %s (%s) %s",
			       $gp->symbol,
			       $gp->species->common_name,
			       join("; ",
				    map {
					$_->evidence_as_str
				    } @{$node->association_hash->{$_}}))
			       
		   } @prods);
            nl;
        }
        nl;
    }

    # trick to allow barewords as keywords...
    sub advanced {"advanced"}

    sub product{
      my $product = shift;
      $nodes = $apph->get_terms({'product'=>$product});
      shownodelist;
    }

    sub function{
      aspect( "function" );
    }

    sub process{
      aspect( "process" );
    }

    sub component{
      aspect( "component" );
    }

    sub aspect{
      my $aspect = shift;
      my @result;
      foreach $node ( @$nodes ){
        if ( $node->type eq $aspect ){
          push @result, $node;
        }
      }
      $nodes = \@result;
      shownodelist;
    }

    sub showhist {
	map {
	    print $_,"\n";
	} @history;
    }

    sub show {
        if (@_) {
            qgo(@_);
        }
        if ($graph) {
            showgraph;
        }
        else {
            shownodelist;
        }
    }

    sub sh {
        my $cmd = shift;
        print `$cmd`;
    }

    sub parse {
        my @files = @_;
        $parser = new GO::Parser({handler=>'obj'});
        my $dtype;
        my @errors = ();
        while (@files) {
            my $fn = shift @files;
            if ($fn =~ /^\-datatype/) {
                $dtype = shift @files;
                next;
            }
            $parser->parse_file($fn, $dtype);
            $parser->show_messages;
        }
        $graph = $parser->handler->graph;
        return $graph;
    }

   sub splitg {
        $graph->split_graph_by_re(@_);
    }

    # db creation / loading


    welcome;
    require Term::ReadLine;
    require Shell;

    checkoptions;
    my $termline = shift || Term::ReadLine->new($prompt);

    my $rcfile = "$ENV{HOME}/.goshellrc";
    if (-f $rcfile) {
	open(F, $rcfile);
	@lines = <F>;
	close(F);
	
    }
    my $end_signal = "";
    while (!$quit) {
	if ($end_signal) {
	    @lines = ($lines);
	    while ($end_signal && ($line = $termline->readline("? "))) {
		hist($line);
		if($line !~ /$end_signal/) {
		    $lines[0].= "\n$line";
		}
		else {
		    $end_signal = "";
		}
	    }
	    next;
	}
	my $line = 
	  @lines ? shift @lines : $termline->readline($prompt);
	hist($line);
        if ($line =~ /^\^/) {
            $line =~ s/^\^//;
            print "$prompt$line";
            my $e = <STDIN>;
            if ($e =~ /^q/) {
                $line = "";
                @lines = ();
            }
        }
        if ($options->{echo} && $line !~ /\+?wait/) {
            if ($line =~ /^\#/) {
                print "$line\n";
            }
            else {
                print "$prompt$line\n";
            }
            if ($options->{sleep}) {
                sleep $options->{sleep};
            }
            if ($options->{wait}) {
                sleep $options->{wait};
            }
        }
	my ($cmd, @w) = split(' ',$line);
	my $rest = join(" ", @w);
	$_ = $cmd;

        $line =~ s/^select/:select/;
        
        # : - sql tunnel and escape everything after in quotes
        if ($line =~ /^:/) {
            $line =~ s/^:/ tunnel q\[/;
            $line .= ']';
        }
        # / - querygo and escape everything after in quotes
        if ($line =~ /^\//) {
            $line =~ s/^\//qgo q\[/;
            $line .= ']';
        }
        # ! - shell and escape everything after in quotes
        if ($line =~ /^\!/) {
            $line =~ s/^\!/sh q\[/;
            $line .= ']';
        }
        # ? - show
        if ($line =~ /^\?/) {
            $line =~ s/^\?/show /;
        }
        if ($line =~ /^h$/) {
            $line =~ s/h/showhist/;
        }
        # ? - show
        if ($line =~ /^\#/) {
            next;
        }
        # + is the set command
        if ($line =~ /^\+/) {
            $line =~ s/\+//;
            $line = "set ".join(",", map {"q[$_]"} split(' ', $line));
        }
	$rv = eval $line;
	if ($@) {
	    print STDERR $@;
	}
        if ($options->{sleep}) {
            sleep $options->{sleep};
        }
        if ($options->{wait}) {
            sleep $options->{wait};
            $options->{wait} = 0;
        }

    }
}


sub hist {
    my $line = shift;
    push(@history, $line);
    print $histfh "$line\n";
    return;
}

