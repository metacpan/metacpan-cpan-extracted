package XBRL::JPFR;

use base XBRL;

use Carp;
use XML::LibXML;
use XML::LibXML::XPathContext;
use XBRL::JPFR::Arc;
use XBRL::JPFR::Context;
use XBRL::JPFR::Unit;
use XBRL::JPFR::Item;
use XBRL::JPFR::Schema;
use XBRL::JPFR::Taxonomy;
use XBRL::JPFR::Dimension;
use XBRL::JPFR::Branch;

use LWP::UserAgent;
use File::Spec;
use Cwd;
use Data::Dumper;
use Encode;
use URI;
use Hash::Merge qw(merge);

our $VERSION = '0.06';

my %default = (
	main_schema => undef,
	schema_dir => undef,
	taxonomy => undef,
	contexts => {},
	units => {},
	items => [],
	itemhash => {},
	labelhash => {},
	trees => {},
	item_index => undef,
	file => undef,
	base => undef,
	lang => 'ja',
	only_ja => 1,
	prefix => '',
	schema_files => [],
	linkbase_files => [],
	only_items => 0,
	std_labels => 0,
	rolelinks_edinet => {},
);

sub new() {
	my ($class, $args) = @_;
	my $self = merge($args, \%default);
	bless $self, $class;

	$$self{'schema_dir'} = $$args{'schema_dir'};
	$$self{'file'} = $$args{'file'};
	#Check the schema dir
	if ($$self{'schema_dir'}) {
		if (-d $$self{'schema_dir'})  {
			if (!-w $$self{'schema_dir'}) {
			#the directory exists but isn't writeable
			croak "$$self{'schema_dir'} exists but isn't writeable by this user\n";
			}
		}
		else {
			#try and create the directory
			mkdir($$self{'schema_dir'}, 777) or croak "$$self{'schema_dir'} can't be created because: $!\n";
		}
	}
	else {
		#the schema_dir parameter wasn't there, use tmp
		$$self{'schema_dir'} = File::Temp->newdir(cleanup => 1);
	}

	if ($$self{'file'}) {
		my ($volume, $dir, $filename) = File::Spec->splitpath($$self{'file'});
		if (!$dir) {
			my $curdir = getcwd();
			my $full_path = File::Spec->catpath(undef, $curdir, $$self{'file'});
			if (-e $full_path) {
				$$self{'base'} = $curdir;
				$$self{'fullpath'} = $full_path;
			}
			else {
				croak "can't find $full_path to start processing\n";
			}
		}
		else {
			$$self{'fullpath'} = $self->{'file'};
			$$self{'file'} = $filename;
			$$self{'base'} = $dir;
		}
	}
 	else {
		croak "XBRL::JPFR requires an existing file to begin processing\n";
	}

	# We can overwrite parse_file if it is invoked as '$self->parse_file()', but cannot if '&parse_file($self)'
	$self->parse_file();

	return $self;
}

sub parse_file {
	my ($self) = @_;

	if (!$$self{'fullpath'}) {
		croak "full path not set in parse file but file is set to: $$self{'file'}\n";
	}

	my $xc 	= $self->make_xpath($$self{'fullpath'}, \$$self{'prefix'});

	#load the schemas
	# XBRL2.1: 3.2
	# DTS rules of discovery: ONLY the followings are referenced.
	#   1. referenced directly from an XBRL Instance using the <schemaRef> element.
	#   2. referenced from a discovered taxonomy schema via an XML Schema import element.
	#   3. referenced from a discovered Linkbase document via a <loc> element.
	#   6. referenced from a discovered taxonomy schema via a <linkbaseRef> element.
	my $s_ref = $xc->findnodes("//*[local-name() = 'schemaRef']");
	if (!$s_ref || !@$s_ref) {
		warn "No schemaRef($$self{'file'})";
		#return;
	}
	elsif (!$$self{'only_items'}) {
		my $schema_file = $$s_ref[0]->getAttribute('xlink:href');
		push @{$$self{'schema_files'}}, $schema_file;
		my $schema_path = File::Spec->catpath(undef, $$self{'base'}, $schema_file);
		my $schema_xpath = $self->make_xpath($schema_path);
		my $main_schema = XBRL::JPFR::Schema->new({file => $schema_file, xpath => $schema_xpath});
		$$self{'taxonomy'} = XBRL::JPFR::Taxonomy->new({
			main_schema => $main_schema,
			lang => $$self{'lang'},
		});
	}

	if (!$$self{'only_items'}) {
		$self->add_schemas();
		$self->load_lb_files();
		$$self{'taxonomy'}->select_arcs();
		$self->set_labels();
		$self->load_contexts($xc);
		$self->load_units($xc);
	}
	$self->load_items($xc);
	$self->create_trees();
}

sub add_schemas {
	my ($self, $other_schema_files) = @_;
	$other_schema_files = $$self{'taxonomy'}->get_other_schemas() if !$other_schema_files;
	while (my $other = shift @{$other_schema_files}) {
		#Get the file
		next if $other =~ /-rt-|_rt_/; # role type
		my $s_file = $self->get_file($other, $$self{'schema_dir'});
		next if !defined $s_file;
		next if $$self{'taxonomy'}->has_schema($s_file);
		push @{$$self{'schema_files'}}, $s_file;
		#make the xpath
		my $s_xpath = $self->make_xpath($s_file);
		#add the schema
		my $schema = XBRL::JPFR::Schema->new({file => $s_file, xpath => $s_xpath});
		$$self{'taxonomy'}->add_schema($schema);
		my $ns = $schema->namespace();
		my $more_schema_files = $$self{'taxonomy'}->get_other_schemas($ns);
		push @$other_schema_files, @$more_schema_files if @$more_schema_files;
	}
}

sub load_lb_files {
	my ($self) = @_;
	my $lb_files = $$self{'taxonomy'}->get_lb_files();
	# branches from CorrectionOfConsolidatedFinancialForecastInThisQuarter is out of the main tree.
	# this is corrected in tse-qcedjpsm-2011-06-30-presentation.xml
	if (grep {/tse-qcedjpsm-2007-06-30-presentation\.xml/} @$lb_files) {
		push @$lb_files, "$$self{'schema_dir'}/tse-qcedjpsm-2007-06-30-presentation-correction.xml";
	}
	my (@remotes, @locals);
	for my $file_name (@$lb_files) {
		my $file = $self->get_file($file_name, $$self{'base'});
		if (!$file) {
			warn "The basedir is: $$self{'base'}\nunable to get $file_name";
			next;
		}
		next if $file_name =~ /_gla\.xml|reference\.xml|_ref\.xml|gla_ias|gre_ias/;
		next if $file_name =~ /-en\.xml$|-en-/ && $$self{'only_ja'};
		if ($file =~ /^$$self{'base'}/) {
			push @locals, $file;
		}
		else {
			push @remotes, $file;
		}
	}

	for my $file (@remotes, @locals) {
		next if grep (/^$file$/, @{$$self{'linkbase_files'}});
		push @{$$self{'linkbase_files'}}, $file;

		my $lb_xpath = $self->make_xpath($file);
		my @link_types = (
			'presentationLink', 'definitionLink', 'calculationLink', 'labelLink',
			#'referenceLink',
		);
		foreach my $link_type (@link_types) {
			next unless $lb_xpath->exists("//*[local-name() = '$link_type']");
			# there can be no link if not extended.
			my %arcs = ();
			my $rolerefs = $lb_xpath->findnodes("//*[local-name() = 'roleRef']");
			my @uris = $rolerefs ? map {$_->getAttribute('roleURI')} @$rolerefs : ();
			push @uris, 'http://www.xbrl.org/2003/role/link';
			foreach my $uri (@uris) {
				next if !$uri;
				my $arcs = $self->collect_arcs($link_type, $uri, $lb_xpath);
				$arcs{$uri} = $arcs if $arcs && @$arcs;
			}
			my $type = substr $link_type, 0, 3;
			$$self{'taxonomy'}->$type(\%arcs);
		}

	}
}

sub set_labels {
	my ($self) = @_;
	my $all_arcs = $$self{'taxonomy'}->lab();
	my $hash = exists $$self{'labelhash'} ? $$self{'labelhash'} : ($$self{'labelhash'} = {});
	foreach my $rolelink (keys %$all_arcs) {
		my $arcs = $$all_arcs{$rolelink};
		foreach my $arc (@$arcs) {
			next unless $arc;
			my ($lang, $rolelabel, $text, $from_short) = @$arc{'lang', 'role', 'text', 'from_short'};
			my $xbrllabel = XBRL::JPFR::Label->new();
			$xbrllabel->name($$arc{'from_full'});
			$xbrllabel->role($rolelabel);
			$xbrllabel->lang($lang);
			$xbrllabel->value($text);
			$xbrllabel->id($$arc{'id'});
			$xbrllabel->label($$arc{'to_name'});
			$$hash{$lang}{$from_short}{$rolelink}{$rolelabel} = $text;
			push @{$$self{'taxonomy'}{'labels'}}, $xbrllabel;
		}
	}
}

sub load_contexts {
	my ($self, $xc) = @_;
	my $cons = $xc->findnodes("//*[local-name() = 'context']");
	for (@$cons) {
		my $cont = XBRL::JPFR::Context->new(
			$_, $$self{'labelhash'}, $$self{'prefix'},
			{lang => $$self{'lang'}},
		);
		$$self{'contexts'}{$cont->id()} = $cont;
	}
}

sub load_units {
	my ($self, $xc) = @_;
	my $units = $xc->findnodes("//*[local-name() = 'unit']");
	for (@$units) {
		my $unit = XBRL::JPFR::Unit->new($_);
		$$self{'units'}{$unit->id()} = $unit;
	}
}

sub load_items {
	my ($self, $xc) = @_;
	my $encoding = $xc->getContextNode()->encoding();
	$encoding = 'UTF-8' if !$encoding;
	my $raw_items = $xc->findnodes('//*[@contextRef]');
	my @items = ();
	for my $instance_xml (@$raw_items) {
		my $item = XBRL::JPFR::Item->new($instance_xml, $encoding);
		my $id_short = $item->name();
		my $context = $item->contextRef();
		$id_short =~ s/:/_/;
		if (!$$self{'only_items'}) {
			$self->add_element_fields($item);
			if ($$self{'lang'} eq 'ja') {
				if ($item->localname() =~ /ExtendedLinkRoleLabel/) {
					# for EDINET or TDnet(edjpfr)
					$self->add_rolelink_edinet($item->localname(), $item->value());
				}
			}
		}
		push(@items, $item);
		if (exists $$self{'itemhash'}{$id_short}{$context}) {
			# When contextRef="CG", we can have multi items
			my $ref = ref $$self{'itemhash'}{$id_short}{$context};
			if ($ref =~ /ARRAY/) {
				push @{$$self{'itemhash'}{$id_short}{$context}}, $item;
			}
			else {
				$$self{'itemhash'}{$id_short}{$context} =
					[$$self{'itemhash'}{$id_short}{$context}, $item];
			}
		}
		else {
			$$self{'itemhash'}{$id_short}{$context} = $item;
		}
	}
	$$self{'items'} = \@items;

	#create the item lookup index
	# CAVEAT: the name and the contextRef will not definitely decide it's item, mentioned above.
	my %index = ();
	for (my $j = 0; $j < @items; $j++) {
		$index{$items[$j]->name()}{$items[$j]->contextRef()} = $j;
	}
	$$self{'item_index'} = \%index;
}

sub add_element_fields {
	my ($self, $item) = @_;
	my $id_short = $item->prefix(). "_". $item->localname();
	if (exists $$self{'taxonomy'}{'elements'}{$id_short}) {
		my $ele = $$self{'taxonomy'}{'elements'}{$id_short};
		add_fields_to_item($item, $ele);
		return;
	}
	else {
		my $item_ns = $item->namespace();
		my $schema = $$self{'taxonomy'}{'schemas'}{$item_ns};
		my $id = "$item_ns/". $item->localname();
		if (exists $$schema{'elements'}{$id}) {
			my $ele = $$schema{'elements'}{$id};
			add_fields_to_item($item, $ele);
			return;
		}
	}
	croak "No element($id_short)\n".Dumper($item);
}

sub add_fields_to_item {
	my ($item, $ele) = @_;
	foreach (qw(type nillable periodType subGroup substitutionGroup)) {
		$item->$_($ele->$_());
	}
	#
	# grep 'type=".*percent.*' *.xsd | sed -e 's/.*\(type="[^ ]*"\).*/\1/' |sort |uniq
	#
	# TDnet
	#   type="tse-cm-cg:percentageOfSharesHeldByForeignInvestorsItemType"
	#   type="tse-ed-types:percentage1ItemType"
	#   type="tse-ed-types:percentage2ItemType"
	#   type="tse-types-ed:percentage1ItemType"
	#   type="tse-types-ed:percentage2ItemType"
	#	tse-t-cg_OwnershipInterest -- type="xbrli:pureItemType"
	# EDINET
	#   type="num:percentItemType"
	#	jpcrp_cor_PriceEarningsRatioSummaryOfBusinessResults -- type="xbrli:decimalItemType"
	#   jpcrp_cor_AverageNumberOfTemporaryWorkers -- type="xbrli:decimalItemType"
	#   jpcrp_cor_PriceEarningsRatioUSGAAPSummaryOfBusinessResults -- type="num:percentItemType"
	#
	my $name = $item->name();
	if ($ele->type() =~ /percent/ && $name !~ /PriceEarningsRatio/) {
		if (!defined $item->scale()) {
			$item->adjust_percent();
		}
	}
	if ($name eq 'tse-t-cg:OwnershipInterest') {
		if (!defined $item->scale()) {
			$item->adjust_percent();
		}
	}
}

sub collect_arcs {
	my ($self, $type, $uri, $xpath) = @_;
	my $encoding = $xpath->getContextNode()->encoding();
	$encoding = 'UTF-8' if !$encoding;
	my $section = $xpath->findnodes("//*[local-name() = '$type'][\@xlink:role = '$uri']");
	return undef unless $section;

	my (@loc_links, @lab_links, @arc_links);
	$type =~ s/Link$/Arc/g;
	for my $node (@{$section}) {
		push(@lab_links, $node->getChildrenByLocalName('label')) if $type =~ /^lab/;
		push(@loc_links, $node->getChildrenByLocalName('loc'));
		push(@arc_links, $node->getChildrenByLocalName($type));
	}

	my (%locs, %labs);
	foreach my $link (@loc_links) {
		my $label = $link->getAttribute('xlink:label');
		push @{$locs{$label}}, $link;
	}
	foreach my $link (@lab_links) {
		my $label = $link->getAttribute('xlink:label');
		# same labels and different roles
		#   2009/S0005C0M/jpfr-asr-E00351-000-2009-12-31-01-2010-03-30-label.xml
		# XBRL2.1: 3.5.3.8.2
		#   Several resources in an extended link MAY have the same label.
		push @{$labs{$label}}, $link;
	}

	my @arcs;
	for my $link (@arc_links) {
		my $arcs = make_arcs($link, \%locs, \%labs, $encoding);
		next if !$arcs || !@$arcs;
		$self->check_arc_elements($arcs, \%labs);
		push @arcs, @$arcs;
	}
	return \@arcs;
}

sub make_arcs {
	my ($link, $locs, $labs, $encoding) = @_;
	my $to_locs = %$labs ? $labs : $locs;
	my $from_locs = $locs;
	my $to_name = $link->getAttribute('xlink:to');
	my $from_name = $link->getAttribute('xlink:from');
	return undef if !exists $$to_locs{$to_name};
	return undef if !exists $$from_locs{$from_name};
	my $to_locs2 = $$to_locs{$to_name};
	my $from_locs2 = $$from_locs{$from_name};
	my @arcs;
	foreach my $from_loc (@$from_locs2) {
		foreach my $to_loc (@$to_locs2) {
			my $arc = make_arc($link, $from_loc, $from_name, $to_loc, $to_name, $labs, $encoding);
			push @arcs, $arc;
		}
	}
	return \@arcs;
}

sub make_arc {
	my ($link, $from_loc, $from_name, $to_loc, $to_name, $labs, $encoding) = @_;
	my $arc = XBRL::JPFR::Arc->new();
	$arc->to_name($to_name);
	$arc->from_name($from_name);
	if (%$labs) {
		my $to_short = $to_name;
		my ($to_prefix) = $to_short =~ /(.*)_/;
		$arc->to_short($to_short);
		$arc->to_prefix($to_prefix);
		$arc->text(Encode::encode($encoding, $to_loc->textContent()));
		$arc->role($to_loc->getAttribute('xlink:role'));
		$arc->lang($to_loc->getAttribute('xml:lang'));
		$arc->id($to_loc->getAttribute('id'));
	}
	else {
		my $href = $to_loc->getAttribute('xlink:href');
		$arc->to_full($href);
		my ($to_short) = $href =~ m/\#([A-Za-z0-9_-].+)$/;
		my ($to_prefix) = $to_short =~ /(.*)_/;
		$arc->to_short($to_short);
		$arc->to_prefix($to_prefix);
	}
	$href = $from_loc->getAttribute('xlink:href');
	$arc->from_full($href);
	my ($from_short) = $href =~ m/\#([A-Za-z0-9_-].+)$/;
	my ($from_prefix) = $from_short =~ /(.*)_/;
	$arc->from_short($from_short);
	$arc->from_prefix($from_prefix);

	my $order = $link->hasAttribute('order') ? $link->getAttribute('order') : 1;
	my $priority = $link->hasAttribute('priority') ? $link->getAttribute('priority') : 0;
	my $use = $link->hasAttribute('use') ? $link->getAttribute('use') : 'optional';
	my $pref = $link->hasAttribute('preferredLabel') ?
		$link->getAttribute('preferredLabel') : 'http://www.xbrl.org/2003/role/label';
	$arc->order($order);
	$arc->arcrole($link->getAttribute('xlink:arcrole'));
	$arc->closed($link->getAttribute('xbrldt:closed'));
	$arc->usable($link->getAttribute('xbrldt:usable'));
	$arc->contextElement($link->getAttribute('xbrldt:contextElement'));
	$arc->prefLabel($pref);
	$arc->use($use);
	$arc->priority($priority);
	$arc->weight($link->getAttribute('weight'));
	return $arc;
}

# DTS rules of discovery:
#   3. referenced from a discovered Linkbase document via a <loc> element.
#   Every taxonomy schema that is referenced by an @xlink:href attribute
#   on a <loc> element in a discovered linkbase MUST be discovered.
sub check_arc_elements {
	my ($self, $arcs, $labs) = @_;
	my $elements = $$self{'taxonomy'}{'elements'};
	foreach my $arc (@$arcs) {
		my ($from_short, $to_short) = @$arc{'from_short', 'to_short'};
		if (!exists $$elements{$from_short}) {
			my $from_full = $$arc{'from_full'};
			(my $file = $from_full) =~ s/#.*$//;
			$self->add_schemas([$file]);
		}
		if (!exists $$elements{$to_short} && !%$labs) {
			my $to_full = $$arc{'to_full'};
			(my $file = $to_full) =~ s/#.*$//;
			$self->add_schemas([$file]);
		}
	}
}

sub get_trees {
	my ($self, $type, $uri) = @_;
	my $trees = $$self{'trees'};
	$trees = $$trees{$type} if $type;
	$trees = $$trees{$uri} if $uri;
	return $trees;
}

sub get_file {
	my ($self, $in_file, $dest_dir) = @_;

	if ($in_file =~ m/^http\:\/\//) {
		$in_file =~ m/^http\:\/\/[a-zA-Z0-9\/].+\/(.*)$/;
		my $full_path = File::Spec->catpath(undef, $dest_dir, $1);
		if (-e $full_path) {
			return $full_path;
		}

		$full_path = File::Spec->catpath(undef, $self->{'schema_dir'}, $1);

		if (-e $full_path) {
			return $full_path;
		}
		else {
			my $ua = LWP::UserAgent->new();
			$ua->agent($agent_string);
			my $response = $ua->get($in_file);
			if ($response->is_success) {
				my $fh;
				open($fh, ">$full_path") or croak "can't open $full_path because: $! \n";
				my $cont = $response->content;
				$cont =~ s/href="(\.\.\/.*?)"/absuri($in_file,$1)/eg;
				$cont =~ s/href="(\.\/.*?)"/absuri($in_file,$1)/eg;
				print $fh $cont;
				close $fh;
				return $full_path;
			}
			else {
				warn "Unable to retrieve $in_file because: " . $response->status_line . "\n";
				return undef;
			}
		}
	}
	else {
		#process regular file
		my ($volume, $dir, $filename) = File::Spec->splitpath($in_file);

		if ($dir && -e $in_file) {
			return $in_file;
		}

		my $test_path = File::Spec->catpath(undef, $$self{'base'}, $filename);

		if (-e $test_path) {
			return $test_path;
		}

		$test_path = File::Spec->catpath(undef, $$self{'schema_dir'}, $filename);
		if (-e $test_path) {
			return $test_path;
		}

# 6779/S0007PA3/ifrs-q3r-E01807-000-2010-12-31-01-2011-02-10.xsd
#   schemaLocation="../NDK1Q%e3%82%92%e3%82%b3%e3%83%94%e3%81%a3%e3%81%a62Q%e4%bd%9c%e3%82%8b%ef%bc%88IFRS%e3%81%aeXBRL%ef%bc%89/S00073Z6/ifrs-q2r-E01807-000-2010-09-30-01-2010-11-11-entrypoint.xsd
		if ($filename =~ /entrypoint.xsd/) {
			my @files = <$$self{'base'}/*-entrypoint.xsd>;
			return $files[0] if @files;
		}
	}
}

sub absuri {
	my ($base, $rel) = @_;
	$base = URI->new($base);
	my $uri = URI->new($rel);
	my $abs = $uri->abs($base);
	return "href=\"$abs\"";
}

sub make_xpath {
	#take a file path and return an xpath context
	my ($self, $in_file, $prefix) = @_;

	my $xml_doc =XML::LibXML->load_xml( location => $in_file);
	my $ns = $self->extract_namespaces($xml_doc);

	my $xml_xpath = XML::LibXML::XPathContext->new($xml_doc);

	my @prefixes = keys %$ns;
	for (@prefixes) {
		$xml_xpath->registerNs($_, $ns->{$_});
		if ($prefix) {
			if (/-E\d{5}-\d{3}/ || /(tse|tdnet).*-\d{5}$/) {
				$$prefix = $_;
			}
		}
	}

	#p3xbrl.com leaves out the link namespace in its schemas
	$xml_xpath->registerNs('link', 'http://www.xbrl.org/2003/linkbase');

	return $xml_xpath;
}

sub extract_namespaces {
	my ($self, $doc) = @_;
	my %out_hash = ();

	my $root = $doc->documentElement();

	my @ns = $root->getNamespaces();
	for (@ns) {
		my $localname = $_->getLocalName();
		if (!$localname) {
			$out_hash{'default'} = $_->getData();
		}
		else {
			$out_hash{$localname} = $_->getData();
		}
	}
	return \%out_hash;
}

sub create_trees {
	my ($self) = @_;
	return if !$$self{'taxonomy'};
	foreach my $type ('pre', 'def', 'cal') {
		my $all_arcs = $$self{'taxonomy'}->$type();
		next if !$all_arcs;
		foreach my $roleuri (keys %$all_arcs) {
			my $arcs = $$all_arcs{$roleuri};
			next if !$arcs;
			create_trees_from_arcs($self, $type, $roleuri, $arcs);
		}
	}
}

# 2901/S000DTDB/jpfr-asr-E00471-000-2013-03-31-01-2013-06-27.xbrl
#   Multi trees(pre,http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedStatementsOfChangesInNetAssets)
#   jpfr-cai-an-2013-03-01-presentation.xml
#   no arc xlink:from="ValuationAndTranslationAdjustmentsSSAbstract" xlink:to="ForeignCurrencyTranslationAdjustmentSSAbstract"
# 6891/S000DUXL/jpfr-asr-E01860-000-2013-03-31-01-2013-04-01.xbrl
#   Multi trees(pre,http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedStatementsOfChangesInNetAssets)
# These errors can occur maybe when either NonConsolidated or Consolidated have no data.
# 
sub create_trees_from_arcs {
	my ($self, $type, $roleuri, $arcs) = @_;
	my %all;
	my $elements = $$self{'taxonomy'}{'elements'};
	my $labels = $$self{'labelhash'};
	foreach my $arc (@$arcs) {
		next unless $arc;
		my ($from_short, $to_short) = @$arc{'from_short', 'to_short'};
		my ($from_ele, $to_ele) = @$elements{$from_short, $to_short};
		croak "No element($from_short)".Dumper($arc) if !$from_ele;
		croak "No element($to_short)".Dumper($arc) if !$to_ele;
		my $role = $$arc{'arcrole'};
		my $from_branch = find_branch_by_id_short(\%all, $role, $from_short, $from_ele);
		my $to_branch = find_branch_by_id_short(\%all, $role, $to_short, $to_ele);
		$from_branch->connect_to($to_branch, $arc);
	}
	my @trees = grep (!$_->from_full(), @{$all{'branches'}});
	@trees = $$self{'taxonomy'}->discard_prohibiteds(\@trees, $type, $roleuri);
	warn "Multi trees($type,$roleuri)" if @trees > 1 && $type eq 'pre';
	warn "No trees($type,$roleuri)" if !@trees;
	foreach my $tree (@trees) {
		calc_depth($tree, 0, $type, $roleuri);
		$tree->splice_undefs();
		$self->set_tree_labels($roleuri, $tree, $tree);
	}
	warn "Trees already exist($type,$roleuri)" if exists $self->{'trees'}{$type}{$roleuri};
	$$self{'trees'}{$type}{$roleuri} = \@trees;
}

sub set_tree_labels {
	my ($self, $roleuri, $tree, $root) = @_;
	my $id_short = $tree->id_short();
	my $pref = $tree->prefLabel();
	my $label = $self->get_label($$self{'lang'}, $id_short, $roleuri, $pref, undef, $root);
	$tree->label($label);
	foreach my $to (@{$$tree{'tos'}}) {
		$self->set_tree_labels($roleuri, $to, $root);
	}
}

sub find_branch_by_id_short {
	my ($all, $role, $short, $ele) = @_;
	if (exists $$all{$role}{$short}) {
		return $$all{$role}{$short};
	}
	else {
		my $branch = $$all{$role}{$short} = XBRL::JPFR::Branch->new($ele);
		push @{$$all{'branches'}}, $branch;
		return $branch;
	}
}

sub calc_depth {
	my ($tree, $count, $type, $roleuri) = @_;
	$tree->depth($count);
	$count++;
	for (my $i = 0 ; $i < @{$$tree{'tos'}} ; $i++) {
		my $to = $$tree{'tos'}[$i];
		my $id_short = $to->id_short();
		if (defined $to->depth()) {
			warn "Circular tree. Deleting $id_short from ".$tree->id_short(). "($type,$roleuri).";
			delete $$tree{'tos'}[$i];
			next;
		}
		calc_depth($to, $count, $type, $roleuri);
	}
}

# to decide presentation label in ja, we need XBRL-instance values(XBRL::JPFR::Item).
sub get_label {
	my ($self, $lang, $id_short, $roleuri, $rolelabel, $rolelink, $root) = @_;
	if ($lang eq 'ja') {
		return $self->get_label_ja($lang, $id_short, $roleuri, $rolelabel, $rolelink, $root);
	}
	else {
		return $self->get_label_std($lang, $id_short, $rolelabel, $rolelink);
	}
}

sub get_label_std {
	my ($self, $lang, $id_short, $rolelabel, $rolelink) = @_;
	$rolelabel = 'http://www.xbrl.org/2003/role/label' if !defined $rolelabel;
	$rolelink = 'http://www.xbrl.org/2003/role/link' if !defined $rolelink;
	if (!exists $$self{'labelhash'}{$lang}{$id_short}{$rolelink}{$rolelabel}) {
	 	warn "No label($lang,$id_short,$rolelink,$rolelabel)";
		return '';
	}
	return $$self{'labelhash'}{$lang}{$id_short}{$rolelink}{$rolelabel};
}

sub get_label_ja {
	my ($self, $lang, $id_short, $roleuri, $rolelabel, $rolelink, $root) = @_;
	$rolelabel = 'http://www.xbrl.org/2003/role/label' if !defined $rolelabel;
	if ($$self{'std_labels'}) {
		$rolelink = 'http://www.xbrl.org/2003/role/link';
		if ($rolelabel =~ /negative/i) {
			$rolelabel = 'http://www.xbrl.org/2003/role/label';
		}
	}
	else {
		if (exists $$self{'rolelinks_edinet'}{$roleuri}) {
			$rolelink = $$self{'rolelinks_edinet'}{$roleuri};
		}
		elsif ($rolelink = $self->get_tdnet_rolelink($roleuri, $root)) {
		}
		else {
			$rolelink = 'http://www.xbrl.org/2003/role/link';
		}
	}
	if (exists $$self{'labelhash'}{$lang}{$id_short}{$rolelink}{$rolelabel}) {
		return $$self{'labelhash'}{$lang}{$id_short}{$rolelink}{$rolelabel};
	}
	#warn "Search other label($lang,$id_short,$roleuri,$rolelink,$rolelabel)";

	if ($$self{'std_labels'}) {
		if (exists $$self{'rolelinks_edinet'}{$roleuri}) {
			$rolelink = $$self{'rolelinks_edinet'}{$roleuri};
		}
		elsif ($rolelink = $self->get_tdnet_rolelink($roleuri, $root)) {
		}
		else {
			$rolelink = 'http://www.xbrl.org/2003/role/link';
		}
	}
	else {
		$rolelink = 'http://www.xbrl.org/2003/role/link';
		if ($rolelabel =~ /negative/i) {
			$rolelabel = 'http://www.xbrl.org/2003/role/label';
		}
	}
	if (exists $$self{'labelhash'}{$lang}{$id_short}{$rolelink}{$rolelabel}) {
		return $$self{'labelhash'}{$lang}{$id_short}{$rolelink}{$rolelabel};
	}

	#warn "Search other label($lang,$id_short,$roleuri,$rolelink,$rolelabel)";
	$rolelink = 'http://www.xbrl.org/2003/role/link';
	my (undef, $base) = File::Spec->splitpath($roleuri);
	my $pref = (split /\//, $rolelabel)[-1];
	my @rolelabels = (
		"http://www.xbrl.org/2003/role/$pref",
		"$base$pref",
		"http://www.xbrl.org/2003/role/label",
		"${base}label",
	);
	foreach $rolelabel (@rolelabels) {
		if (exists $$self{'labelhash'}{$lang}{$id_short}{$rolelink}{$rolelabel}) {
			return $$self{'labelhash'}{$lang}{$id_short}{$rolelink}{$rolelabel};
		}
	}

	warn "Search existing label($lang,$id_short,$roleuri,$rolelink,$rolelabel)";
	if (exists $$self{'labelhash'}{$lang}{$id_short}) {
		my $labels = $$self{'labelhash'}{$lang}{$id_short};
		foreach my $rolelink (sort {length($a) <=> length($b)} keys %$labels) {
			foreach my $rolelabel (sort  {length($a) <=> length($b)}keys %{$$labels{$rolelink}}) {
				return $$labels{$rolelink}{$rolelabel};
			}
		}
	}

	warn "No label($lang,$id_short,$roleuri,$rolelink,$rolelabel)";
	print STDERR Dumper($$self{'labelhash'}{$lang}{$id_short});
	return '';
}

sub get_tdnet_rolelink {
	my ($self, $roleuri, $root) = @_;
	return undef if $roleuri !~ /^http:\/\/www.xbrl.tdnet.info\/jp\/br\/tdnet\/role\//;
	my $rolelink;
	if ($roleuri =~ /Quarterly|Q1|Q2|Q3/) { # neither Q4 nor Q5 doesnot exist.
		$rolelink = 'http://www.xbrl.tdnet.info/jp/br/tdnet/role/Quarterly';
	}
	if ($self->specific_business_tdnet() && $self->semi_annual_tdnet($roleuri, $root)) {
		$rolelink = 'http://www.xbrl.tdnet.info/jp/br/tdnet/role/QuarterlyForSpecificBusiness2Q';
	}
	return $rolelink;
}

sub specific_business_tdnet {
	my ($self) = @_;
	return 0 if !exists $$self{'itemhash'}{'tse-t-ed_SpecificBusiness'};
	my ($context) = grep {/Current.*Instant/} keys %{$$self{'itemhash'}{'tse-t-ed_SpecificBusiness'}};
	my $value = $$self{'itemhash'}{'tse-t-ed_SpecificBusiness'}{$context}{'value'};
	if ($value =~ /true/i) {
		return 1;
	}
	elsif ($value =~ /false/i) {
		return 0;
	}
	else {
		croak "No specific business value";
	}
}

sub semi_annual_tdnet {
	my ($self, $roleuri, $root) = @_;
	if (exists $$self{'itemhash'}{'tse-t-hi_QuarterlyPeriod'}) {
		my @contexts = keys %{$$self{'itemhash'}{'tse-t-hi_QuarterlyPeriod'}};
		my ($context) = grep {/Current.*Instant/} @contexts;
		my $value = $$self{'itemhash'}{'tse-t-hi_QuarterlyPeriod'}{$context}{'value'};
		if ($value == 2) {
			return 1;
		}
		elsif ($value =~ /[1345]{1}/) {
			return 0;
		}
		else {
			croak "No quarterly period";
		}
	}
	if ($roleuri =~ /Quarterly/) {
		my $name = 'ForecastCorrectionOfQuarterlyConsolidatedFinancialResults6MonthsYTDAbstract';
		my $branch = $root->find_branch_by_name($name);
		return 1 if $branch;
		$name = 'ForecastCorrectionOfQuarterlyNonConsolidatedFinancialResults6MonthsYTDAbstract';
		$branch = $root->find_branch_by_name($name);
		return $branch ? 1 : 0;
	}
	return 0;
}

BEGIN {

my %edinet_2013_03_01_rolelinks = (
	'ExtendedLinkRoleLabelConsolidatedBS' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedBalanceSheets',
	'ExtendedLinkRoleLabelConsolidatedCF' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedStatementsOfCashFlowsDirect&http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedStatementsOfCashFlowsIndirect',
	'ExtendedLinkRoleLabelConsolidatedCI' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedStatementsOfComprehensiveIncome',
	'ExtendedLinkRoleLabelConsolidatedPL' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedStatementsOfIncome',
	'ExtendedLinkRoleLabelConsolidatedSS' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedStatementsOfChangesInNetAssets',
	#
	'ExtendedLinkRoleLabelConsolidatedInterimBS' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedInterimBalanceSheets',
	'ExtendedLinkRoleLabelConsolidatedInterimCF' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedInterimStatementsOfCashFlowsDirect&http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedInterimStatementsOfCashFlowsIndirect',
	'ExtendedLinkRoleLabelConsolidatedInterimCI' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedInterimStatementsOfComprehensiveIncome',
	'ExtendedLinkRoleLabelConsolidatedInterimPL' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedInterimStatementsOfIncome',
	'ExtendedLinkRoleLabelConsolidatedInterimSS' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedInterimStatementsOfChangesInNetAssets',
	#
	'ExtendedLinkRoleLabelConsolidatedQuarterlyBS' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedQuarterlyBalanceSheets',
	'ExtendedLinkRoleLabelConsolidatedQuarterlyCF' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedQuarterlyStatementsOfCashFlowsDirect&http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedQuarterlyStatementsOfCashFlowsIndirect',
	'ExtendedLinkRoleLabelConsolidatedQuarterlyCIQuarter' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedQuarterlyStatementsOfComprehensiveIncomeQuarter',
	'ExtendedLinkRoleLabelConsolidatedQuarterlyCIYTD' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedQuarterlyStatementsOfComprehensiveIncomeYTD',
	'ExtendedLinkRoleLabelConsolidatedQuarterlyPLQuarter' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedQuarterlyStatementsOfIncomeQuarter',
	'ExtendedLinkRoleLabelConsolidatedQuarterlyPLYTD' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/ConsolidatedQuarterlyStatementsOfIncomeYTD',
	#
	'ExtendedLinkRoleLabelNonconsolidatedBS' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedBalanceSheets',
	'ExtendedLinkRoleLabelNonconsolidatedCF' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedStatementsOfCashFlowsDirect&http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedStatementsOfCashFlowsIndirect',
	'ExtendedLinkRoleLabelNonconsolidatedCI' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedStatementsOfComprehensiveIncome',
	'ExtendedLinkRoleLabelNonconsolidatedPL' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedStatementsOfIncome',
	'ExtendedLinkRoleLabelNonconsolidatedSS' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedStatementsOfChangesInNetAssets',
	#
	'ExtendedLinkRoleLabelNonconsolidatedInterimBS' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedInterimBalanceSheets',
	'ExtendedLinkRoleLabelNonconsolidatedInterimCF' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedInterimStatementsOfCashFlowsDirect&http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedInterimStatementsOfCashFlowsIndirect',
	'ExtendedLinkRoleLabelNonconsolidatedInterimCI' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedInterimStatementsOfComprehensiveIncome',
	'ExtendedLinkRoleLabelNonconsolidatedInterimPL' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedInterimStatementsOfIncome',
	'ExtendedLinkRoleLabelNonconsolidatedInterimSS' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedInterimStatementsOfChangesInNetAssets',
	#
	'ExtendedLinkRoleLabelNonconsolidatedQuarterlyBS' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedQuarterlyBalanceSheets',
	'ExtendedLinkRoleLabelNonconsolidatedQuarterlyCF' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedQuarterlyStatementsOfCashFlowsDirect&http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedQuarterlyStatementsOfCashFlowsIndirect',
	'ExtendedLinkRoleLabelNonconsolidatedQuarterlyCIQuarter' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedQuarterlyStatementsOfComprehensiveIncomeQuarter',
	'ExtendedLinkRoleLabelNonconsolidatedQuarterlyCIYTD' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedQuarterlyStatementsOfComprehensiveIncomeYTD',
	'ExtendedLinkRoleLabelNonconsolidatedQuarterlyPLQuarter' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedQuarterlyStatementsOfIncomeQuarter',
	'ExtendedLinkRoleLabelNonconsolidatedQuarterlyPLYTD' =>
		'http://info.edinet-fsa.go.jp/jp/fr/gaap/role/NonConsolidatedQuarterlyStatementsOfIncomeYTD',
);

sub add_rolelink_edinet {
	my ($self, $localname, $role) = @_;
	croak "No EDINET rolelink($localname)" if !exists $edinet_2013_03_01_rolelinks{$localname};
	foreach my $roleuri (split /&/, $edinet_2013_03_01_rolelinks{$localname}) {
		$$self{'rolelinks_edinet'}{$roleuri} = $role;
	}
}

} # BEGIN


1;

__END__

=head1 NAME

XBRL::JPFR - Perl extension for reading XBRL instance documents which are disclosed at
Tokyo Stock Exchange(TSE,TDnet) and Japan Financial Service Agancy(FSA,EDINET).
JPFR means Japan Financial Reporting.

=head1 SYNOPSIS

use XBRL::JPFR;

my $xbrl_doc = XBRL::JPFR->new( {file=>"foo.xbrl", schema_dir="/dir/to/schema/files"});

=head1 DESCRIPTION

XBRL::JPFR provides an OO interface for reading XBRL instance documents which are disclosed at
Tokyo Stock Exchange(TSE,TDnet) and Japan Financial Service Agancy(FSA,EDINET).

XBRL::JPFR inherits XBRL.

=over 4

=item get_trees

	my $type = undef; # or 'def', 'pre', 'cal'
	my $uri = undef; # or uri
	my $trees = $xbrl_doc->get_trees($type, $uri)

Returns trees which represent definition, presentation and/or calculation hierarchies.

=back

=head1 SEE ALSO

XBRL

bin/{dumpxbrl,timeseries} as an example

EDINET

	https://disclosure.edinet-fsa.go.jp/EKW0EZ0015.html, and its link to old standards.
	http://disclosure.edinet-fsa.go.jp/

TDnet

	http://www.tse.or.jp/rules/td/xbrl/data/
	https://www.release.tdnet.info/index.html

=head1 AUTHOR

Mark Gannon <mark@truenorth.nu>

=head1 MODIFIER

Tetsuya Yamamoto <yonjouhan@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Mark Gannon

Copyright (C) 2015 by Tetsuya Yamamoto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.


=cut
