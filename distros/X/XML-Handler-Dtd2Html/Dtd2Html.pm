
package XML::Handler::Dtd2Html::Document;

use strict;
use warnings;

use Parse::RecDescent;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
			xml_decl                => undef,
			dtd                     => undef,
			root_name               => undef,
			list_decl               => [],
			hash_notation           => {},
			hash_entity             => {},
			hash_element            => {},
			hash_attr               => {},
			hlink                   => 1,
			preformatted            => "pre",
			emphasis                => "em",
			width                   => 80,
	};
	bless($self, $class);
	$self->{cm_parser} = Parse::RecDescent->new(<<'EndGrammar');
		<autotree>

		contentspec: 'EMPTY' | 'ANY' | Mixed | children

		children: ( choice | seq ) ( '?' | '*' | '+' )(?)

		cp: ( Name | choice | seq ) ( '?' | '*' | '+' )(?)

		choice: '(' cp ( '|' cp )(s)  ')'

		seq: '(' cp ( ',' cp )(s?) ')'

		Mixed: '(' '#PCDATA' ( '|' Name )(s?) ')*' | '(' '#PCDATA' ')'

		Name: /[\w_:][\w\d\.\-_:]*/

EndGrammar
	return $self;
}

###############################################################################

package XML::Handler::Dtd2Html;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION="0.42";

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
			doc         => XML::Handler::Dtd2Html::Document->new(),
			comments    => []
	};
	bless($self, $class);
	return $self;
}

# Content Events (Basic)

sub start_document {
	my $self = shift;
	my ($decl) = @_;
	$self->{doc}->{xml_decl} = $decl if (%{$decl});
	return;
}

sub end_document {
	my $self = shift;
	return $self->{doc};
}

# Declarations Events

sub element_decl {
	my $self = shift;
	my ($decl) = @_;
	if (scalar @{$self->{comments}}) {
		$decl->{comments} = [@{$self->{comments}}];
		$self->{comments} = [];
	}
	$decl->{type} = "element";
	$decl->{used_by} = {};
	$decl->{uses} = {};
	my $name = $decl->{Name};
	$self->{doc}->{hash_element}->{$name} = $decl;
	push @{$self->{doc}->{list_decl}}, $decl;
	return;
}

sub attribute_decl {
	my $self = shift;
	my ($decl) = @_;
	if (scalar @{$self->{comments}}) {
		$decl->{comments} = [@{$self->{comments}}];
		$self->{comments} = [];
	}
	my $elt_name = $decl->{eName};
	$self->{doc}->{hash_attr}->{$elt_name} = []
			unless (exists $self->{doc}->{hash_attr}->{$elt_name});
	push @{$self->{doc}->{hash_attr}->{$elt_name}}, $decl;
	return;
}

sub internal_entity_decl {
	my $self = shift;
	my ($decl) = @_;
	if (scalar @{$self->{comments}}) {
		$decl->{comments} = [@{$self->{comments}}];
		$self->{comments} = [];
	}
	$decl->{type} = "internal_entity";
	my $name = $decl->{Name};
	unless ($name =~ /^%/) {
		$self->{doc}->{hash_entity}->{$name} = $decl;
		push @{$self->{doc}->{list_decl}}, $decl;
	}
	return;
}

sub external_entity_decl {
	my $self = shift;
	my ($decl) = @_;
	if (scalar @{$self->{comments}}) {
		$decl->{comments} = [@{$self->{comments}}];
		$self->{comments} = [];
	}
	$decl->{type} = "external_entity";
	my $name = $decl->{Name};
	unless ($name =~ /^%/) {
		$self->{doc}->{hash_entity}->{$name} = $decl;
		push @{$self->{doc}->{list_decl}}, $decl;
	}
	return;
}

# DTD Events

sub notation_decl {
	my $self = shift;
	my ($decl) = @_;
	if (scalar @{$self->{comments}}) {
		$decl->{comments} = [@{$self->{comments}}];
		$self->{comments} = [];
	}
	$decl->{type} = "notation";
	my $name = $decl->{Name};
	$self->{doc}->{hash_notation}->{$name} = $decl;
	push @{$self->{doc}->{list_decl}}, $decl;
	return;
}

sub unparsed_entity_decl {
	my $self = shift;
	my ($decl) = @_;
	$self->{comments} = [];
	warn "unparsed entity $decl->{Name}.\n";
	return;
}

# Lexical Events

sub start_dtd {
	my $self = shift;
	my ($dtd) = @_;
	if (scalar @{$self->{comments}}) {
		$dtd->{comments} = [@{$self->{comments}}];
		$self->{comments} = [];
	}
	$dtd->{type} = "doctype";
	$self->{doc}->{dtd} = $dtd;
	$self->{doc}->{root_name} = $dtd->{Name};
	return;
}

sub comment {
	my $self = shift;
	my ($comment) = @_;
	push @{$self->{comments}}, $comment;
	return;
}

# SAX1 Events

# deprecated in favour of start_document (see XML::SAX::Expat 0.36)
#sub xml_decl {
#	my $self = shift;
#	my ($decl) = @_;
#	$self->{doc}->{xml_decl} = $decl;
#}

###############################################################################

package XML::Handler::Dtd2Html::ContentModelVisitor;

use strict;
use warnings;

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my ($doc) = @_;
	my $self = {
			doc		=> $doc,
			str		=> "",
			raw		=> "",
			tab		=> "",
			max		=> $doc->{width},
			need	=> 0,
	};
	bless($self, $class);
	return $self;
}

sub _inc_tab {
	my $self = shift;
	$self->{tab} .= "  ";
	return;
}

sub _dec_tab {
	my $self = shift;
	$self->{tab} =~ s/  $//;
	return;
}

sub _add {
	my $self = shift;
	my ($raw, $str) = @_;
	$str = $raw unless (defined $str);
	$self->{raw} .= $raw;
	$self->{str} .= $str;
	return;
}

sub _add_name {
	my $self = shift;
	my ($raw, $str) = @_;
	$str = $raw unless (defined $str);
	$self->_break()
			if (length($self->{tab} . $self->{raw} . $raw) > $self->{max});
	$self->{raw} .= $raw;
	$self->{str} .= $str;
	return;
}

sub _break {
	my $self = shift;
	$self->{need} = 0;
	if ($self->{raw} !~ /^\s*$/) {
		$self->{raw} = "";
		$self->{str} .= "\n" . $self->{tab};
	}
	return;
}

sub _visit {
	my $self = shift;
	my $node = shift;

	my $func = "visit_" . ref $node;
	if($self->can($func)) {
		$self->$func($node, @_);
	} else {
		warn "Please implement a function '$func' in '",ref $self,"'.\n";
	}
	return;
}

#		contentspec: 'EMPTY' | 'ANY' | Mixed | children
sub visit_contentspec {
	my $self = shift;
	my ($node) = @_;

	if      (exists $node->{__VALUE__}) {
		$self->{str} .= $self->{doc}->_mk_value($node->{__VALUE__});
	} elsif (exists $node->{Mixed}) {
		$self->_visit($node->{Mixed});
	} elsif (exists $node->{children}) {
		$self->_visit($node->{children});
	}
	return;
}

#		children: ( choice | seq ) ( '?' | '*' | '+' )(?)
sub visit_children {
	my $self = shift;
	my ($node) = @_;

	my $altern1 = $node->{_alternation_1_of_production_1_of_rule_children};
	if      (exists $altern1->{choice}) {
		$self->_visit($altern1->{choice});
	} elsif (exists $altern1->{seq}) {
		$self->_visit($altern1->{seq});
	}
	my $altern2 = shift @{$node->{'_alternation_2_of_production_1_of_rule_children(?)'}};
	if (defined $altern2) {
		$self->_add($altern2->{__VALUE__});				# '?' or '*' or '+'
	}
	return;
}

#		cp: ( Name | choice | seq ) ( '?' | '*' | '+' )(?)
sub visit_cp  {
	my $self = shift;
	my ($node, $first) = @_;

	my $altern1 = $node->{_alternation_1_of_production_1_of_rule_cp};
	if      (exists $altern1->{Name}) {
		$self->_break() if ($self->{need});
		$self->_visit($altern1->{Name});
	} elsif (exists $altern1->{choice}) {
		$self->_break() unless ($first);
		$self->_visit($altern1->{choice});
		$self->{need} = 1;
	} elsif (exists $altern1->{seq}) {
		$self->_break() unless ($first);
		$self->_visit($altern1->{seq});
		$self->{need} = 1;
	}
	my $altern2 = shift @{$node->{'_alternation_2_of_production_1_of_rule_cp(?)'}};
	if (defined $altern2) {
		$self->_add($altern2->{__VALUE__});				# '?' or '*' or '+'
	}
	return;
}

#		choice: '(' cp ( '|' cp )(s)  ')'
sub visit_choice {
	my $self = shift;
	my ($node) = @_;

	$self->_add($node->{__STRING1__} . " ");				# '('
	$self->_inc_tab();
	$self->_visit($node->{cp}, 1);
	foreach (@{$node->{'_alternation_1_of_production_1_of_rule_choice(s)'}}) {
		$self->_add(" " . $_->{__STRING1__} . " ");			# '|'
		$self->_visit($_->{cp}, 0);
	}
	$self->_dec_tab();
	$self->_add(" " . $node->{__STRING2__});				# ')'
	return;
}

#		seq: '(' cp ( ',' cp )(s?) ')'
sub visit_seq {
	my $self = shift;
	my ($node) = @_;

	$self->_add($node->{__STRING1__} . " ");				# '('
	$self->_inc_tab();
	$self->_visit($node->{cp}, 1);
	foreach (@{$node->{'_alternation_1_of_production_1_of_rule_seq(s?)'}}) {
		$self->_add(" " . $_->{__STRING1__} . " ");			# ','
		$self->_visit($_->{cp}, 0);
	}
	$self->_dec_tab();
	$self->_add(" " . $node->{__STRING2__});				# ')'
	return;
}

#		Mixed: '(' '#PCDATA' ( '|' Name )(s?) ')*' | '(' '#PCDATA' ')'
sub visit_Mixed {
	my $self = shift;
	my ($node) = @_;

	$self->_add($node->{__STRING1__} . " ");				# '('
	my $value = $self->{doc}->_mk_value($node->{__STRING2__});
	$self->_inc_tab();
	$self->_add_name($node->{__STRING2__}, $value);			# '#PCDATA'
	foreach (@{$node->{'_alternation_1_of_production_1_of_rule_Mixed(s?)'}}) {
		$self->_add(" " . $_->{__STRING1__} . " ");			# '|'
		$self->_visit($_->{Name});
	}
	$self->_dec_tab();
	$self->_add(" " . $node->{__STRING3__});				# ')*' or ')'
	return;
}

#		Name: /[\w_:][\w\d\.\-_:]*/
sub visit_Name {
	my $self = shift;
	my ($node) = @_;

	my $anchor = $self->{doc}->_mk_text_anchor("elt", $node->{__VALUE__});
	$self->_add_name($node->{__VALUE__}, $anchor);
	return;
}

###############################################################################

package XML::Handler::Dtd2Html::Document;

use strict;
use warnings;

use HTML::Template;
use File::Basename;

sub _process_args {
	my $self = shift;
	my %hash = @_;

	$self->{outfile} = $hash{outfile};

	if (defined $hash{title}) {
		$self->{title} = $hash{title};
	} else {
		foreach my $comment (@{$self->{dtd}->{comments}}) {
			my ($doc, $r_tags) = $self->_extract_doc($comment);
			foreach (@{$r_tags}) {
				my ($href, $entry, $data) = @{$_};
				if (uc($entry) eq "TITLE") {
					$self->{title} = $data;
				}
			}
		}
		$self->{title} = "DTD " . $self->{root_name}
				unless ($self->{title});
	}

	$self->{css} = $hash{css};
	$self->{examples} = $hash{examples};
	$self->{dirname} = dirname($hash{outfile});
	$self->{basename} = basename($hash{outfile});
	$self->{filebase} = $hash{outfile};
	$self->{filebase} =~ s/^([^\/]+\/)+//;
	$self->{flag_comment} = $hash{flag_comment};
	$self->{flag_href} = $hash{flag_href};

	$self->{now} = $hash{flag_date} ? localtime() : "";
	$self->{generator} = "dtd2html " . $XML::Handler::Dtd2Html::VERSION . " (Perl " . $] . ")";

	if (defined $hash{path_tmpl}) {
		$self->{path_tmpl} = [ $hash{path_tmpl} ];
	} else {
		my $language = $hash{language} || 'en';
		my $path = $INC{'XML/Handler/Dtd2Html.pm'};
		$path =~ s/\.pm$//i;
		$self->{path_tmpl} = [ $path . '/' . $language, $path ];
	}

	$self->_cross_ref($hash{flag_zombi});

	if ($hash{flag_multi}) {
		foreach my $decl (@{$self->{list_decl}}) {
			my $type = $decl->{type};
			my $name = $decl->{Name};
			if (exists $decl->{comments}) {
				$decl->{comments} = [ ${$decl->{comments}}[-1] ];
			}
			if ($type eq "element" and exists $self->{hash_attr}->{$name}) {
				foreach my $attr (@{$self->{hash_attr}->{$name}}) {
					if (exists $attr->{comments}) {
						$attr->{comments} = [ ${$attr->{comments}}[-1] ];
					}
				}
			}
		}
	}
	return;
}

sub _cross_ref {
	my $self = shift;
	my($flag_zombi) = @_;

	while (my($name, $decl) = each %{$self->{hash_element}}) {
		my $model = $decl->{Model};
		while ($model) {
			for ($model) {
				s/^[ \n\r\t\f\013]+//;							# whitespaces

				s/^[\?\*\+\(\),\|]//
						and last;
				s/^EMPTY//
						and last;
				s/^ANY//
						and last;
				s/^#PCDATA//
						and last;
				s/^([A-Za-z_:][0-9A-Za-z\.\-_:]*)//
						and $self->{hash_element}->{$name}->{uses}->{$1} = 1,
						and $self->{hash_element}->{$1}->{used_by}->{$name} = 1,
						    last;
				s/^([\S]+)//
						and warn __PACKAGE__,":_cross_ref INTERNAL_ERROR $1\n",
						    last;
			}
		}
	}

	if ($flag_zombi) {
		my $one_more_time = 1;
		while ($one_more_time) {
			$one_more_time = 0;
			while (my($elt_name, $elt_decl) = each %{$self->{hash_element}}) {
				next if ($elt_name eq $self->{root_name});
				unless (scalar keys %{$elt_decl->{used_by}}) {
					delete $self->{hash_element}->{$elt_name};
					foreach my $child (keys %{$elt_decl->{uses}}) {
						my $decl = $self->{hash_element}->{$child};
						delete $decl->{used_by}->{$elt_name};
						$one_more_time = 1;
					}
				}
			}
		}
	}
	return;
}

sub _format_content_model {
	my $self = shift;
	my ($model) = @_;
	my $visitor = XML::Handler::Dtd2Html::ContentModelVisitor->new($self);
	$visitor->_visit($self->{cm_parser}->contentspec($model));
	my $str = $visitor->{str};
	return $str;
}

sub _include_doc {
	my $self = shift;
	my($filename) = @_;
	my $doc = "";

	open my $IN, '<', $filename
			or warn "can't open $filename ($!).\n",
			return $doc;

	while (<$IN>) {
		$doc .= $_;
	}
	close $IN;
	return $doc;
}

sub _extract_doc {
	my $self = shift;
	my($comment) = @_;
	my $doc = undef;
	my @tags = ();
	my @lines = split /\n/, $comment->{Data};
	foreach (@lines) {
		if      (/^\s*@(@?)\s*([\s0-9A-Z_a-z]+):\s*(.*)/) {
			my $href = $1;
			my $tag = $2;
			my $value = $3;
			$tag =~ s/\s*$//;
			if (uc($tag) eq "INCLUDE") {
				$doc .= $self->_include_doc($value);
			} else {
				push @tags, [$href, $tag, $value];
			}
		} elsif (/^\s*@(@?)\s*([A-Z_a-z][0-9A-Z_a-z]*)\s+(.*)/) {
			my $href = $1;
			my $tag = $2;
			my $value = $3;
			if (uc($tag) eq "INCLUDE") {
				$doc .= $self->_include_doc($value);
			} else {
				push @tags, [$href, $tag, $value];
			}
		} else {
			$doc .= $_;
			$doc .= "\n";
		}
	}
	return ($doc, \@tags);
}

sub _process_text {
	my $self = shift;
	my($text, $current, $href) = @_;

	# keep track of leading and trailing white-space
	my $lead  = ($text =~ s/\A(\s+)//s ? $1 : "");
	my $trail = ($text =~ s/(\s+)\Z//s ? $1 : "");

	# split at space/non-space boundaries
	my @words = split( /(?<=\s)(?=\S)|(?<=\S)(?=\s)/, $text );

	# process each word individually
	foreach my $word (@words) {
		# skip space runs
		next if ($word =~ /^\s*$/);
		next if ($word eq $current);
		if ($word =~ /^[A-Za-z_:][0-9A-Za-z\.\-_:]*$/) {
			next if ($self->{flag_href} and !$href);
			# looks like a DTD name
			if (exists $self->{hash_notation}->{$word}) {
				$word = $self->_mk_text_anchor("not", $word);
			}
			elsif (exists $self->{hash_entity}->{$word}) {
				$word = $self->_mk_text_anchor("ent", $word);
			}
			elsif (exists $self->{hash_element}->{$word}) {
				$word = $self->_mk_text_anchor("elt", $word);
			}
		} elsif ($word =~ /^\w+:\/\/\w/) {
			# looks like a URL
			# Don't relativize it: leave it as the author intended
			$word = "<a href='" . $word . "'>" . $word . "</a>"
					if ($self->{hlink});
		} elsif ($word =~ /^[\w.-]+\@[\w.-]+/) {
			# looks like an e-mail address
			$word = "<a href='mailto:" . $word . "'>" . $word . "</a>"
					if ($self->{hlink});
		}
	}

	# put everything back together
	return $lead . join('', @words) . $trail;
}

sub _mk_value {
	my $self = shift;
	my($value) = @_;

	return "<span class='keyword1'>" . $value . "</span> ";
}

sub _mk_index_anchor {
	my $self = shift;
	my($type, $name) = @_;

	my $href = $self->_mk_index_href($type, $name);
	return "<a class='index' href='" . $href . "'>" . $name ."</a>";
}

sub _mk_text_anchor {
	my $self = shift;
	my($type, $name) = @_;

	my $href = $self->_mk_index_href($type, $name);
	return "<a href='" . $href . "'>" . $name . "</a>";
}

sub _mk_index_href {
	my $self = shift;
	my($type, $name) = @_;

	return "#" . $type . "_" . $name;
}

sub generateAlphaElement {
	my $self = shift;
	my ($nb, $a_link, $flg_brief) = @_;

	$nb = 'nb_element' unless (defined $nb);
	$a_link = 'a_elements' unless (defined $a_link);

	my @elements = sort keys %{$self->{hash_element}};
	my @a_link = ();
	foreach (@elements) {
		my $a = $self->_mk_index_anchor("elt", $_);
		if ($flg_brief) {
			my $brief = $self->_get_brief($self->{hash_element}->{$_});
			push @a_link, {
					a			=> $a,
					brief		=> $brief,
					root		=> ($_ eq $self->{root_name}),
			};
		} else {
			push @a_link, {
					a			=> $a,
			};
		}
	}
	$self->{template}->param(
			$nb			=> scalar @elements,
			$a_link		=> \@a_link,
	);
	return;
}

sub generateAlphaEntity {
	my $self = shift;
	my ($nb, $a_link, $flg_brief) = @_;

	$nb = 'nb_entity' unless (defined $nb);
	$a_link = 'a_entities' unless (defined $a_link);

	my @entities = sort keys %{$self->{hash_entity}};
	my @a_link = ();
	foreach (@entities) {
		my $a = $self->_mk_index_anchor("ent", $_);
		if ($flg_brief) {
			my $brief = $self->_get_brief($self->{hash_element}->{$_});
			push @a_link, {
					a			=> $a,
					brief		=> $brief,
					root		=> undef,
			};
		} else {
			push @a_link, {
					a			=> $a,
			};
		}
	}
	$self->{template}->param(
			$nb			=> scalar @entities,
			$a_link		=> \@a_link,
	);
	return;
}

sub generateAlphaNotation {
	my $self = shift;
	my ($nb, $a_link, $flg_brief) = @_;

	$nb = 'nb_notation' unless (defined $nb);
	$a_link = 'a_notations' unless (defined $a_link);

	my @notations = sort keys %{$self->{hash_notation}};
	my @a_link = ();
	foreach (@notations) {
		my $a = $self->_mk_index_anchor("not", $_);
		if ($flg_brief) {
			my $brief = $self->_get_brief($self->{hash_element}->{$_});
			push @a_link, {
					a			=> $a,
					brief		=> $brief,
					root		=> undef,
			};
		} else {
			push @a_link, {
					a			=> $a,
			};
		}
	}
	$self->{template}->param(
			$nb			=> scalar @notations,
			$a_link		=> \@a_link,
	);
	return;
}

sub generateExampleIndex {
	my $self = shift;
	my ($nb, $a_link) = @_;

	$nb = 'nb_example' unless (defined $nb);
	$a_link = 'a_examples' unless (defined $a_link);

	my @examples = @{$self->{examples}};
	my @a_link = ();
	foreach (@examples) {
		my $a = $self->_mk_index_anchor("ex", $_);
		push @a_link, {
				a			=> $a,
		};
	}
	$self->{template}->param(
			$nb			=> scalar @examples,
			$a_link		=> \@a_link,
	);
	return;
}

sub _mk_tree {
	my $self = shift;
	my ($name, $depth) = @_;

	return if ($self->{hash_element}->{$name}->{done});
	$self->{hash_element}->{$name}->{done} = 1;
	die __PACKAGE__,"_mk_tree: INTERNAL ERROR ($name).\n"
			unless (defined $self->{hash_element}->{$name}->{uses});
	return unless (scalar keys %{$self->{hash_element}->{$name}->{uses}});

	my %done = ();
	$self->{_tree_depth} = $depth if ($depth > $self->{_tree_depth});
	$self->{_tree} .= "<ul class='tree'>\n";
	foreach (keys %{$self->{hash_element}->{$name}->{uses}}) {
		next if ($_ eq $name);
		next if (exists $done{$_});
		$done{$_} = 1;
		$self->{_tree} .= "  <li class='tree'>" . $self->_mk_index_anchor("elt", $_) . "\n";
		$self->_mk_tree($_, $depth+1);
		$self->{_tree} .= "  </li>\n";
	}
	$self->{_tree} .= "</ul>\n";
	return;
}

sub generateTree {
	my $self = shift;

	$self->{_tree_depth} = 1;
	$self->{_tree} = "<ul class='tree'>\n";
	$self->{_tree} .= "  <li class='tree'>" . $self->_mk_index_anchor("elt", $self->{root_name}) . "\n";
	if (exists $self->{hash_element}->{$self->{root_name}}) {
		$self->_mk_tree($self->{root_name}, $self->{_tree_depth});
	} else {
		warn "$self->{root_name} declared in DOCTYPE is an unknown element.\n";
	}
	$self->{_tree} .= "  </li>\n";
	$self->{_tree} .= "</ul>\n";
	$self->{_tree} = "" if ($self->{_tree_depth} > 7);
	$self->{template}->param(
			tree		=> $self->{_tree},
	);
	delete $self->{_tree};
	return;
}

sub _get_doc {
	my $self = shift;
	my ($decl) = @_;

	my $name = $decl->{Name};
	my @doc = ();
	my @tag = ();
	if ($self->{flag_comment} and exists $decl->{comments}) {
		foreach my $comment (@{$decl->{comments}}) {
			my ($doc, $r_tags) = $self->_extract_doc($comment);
			if (defined $doc) {
				my $data = $self->_process_text($doc, $name);
				push @doc, { data => $data };
			}
			foreach (@{$r_tags}) {
				my ($href, $entry, $data) = @{$_};
				unless (   uc($entry) eq "BRIEF"
						or uc($entry) eq "HIDDEN"
						or (uc($entry) eq "TITLE" and $decl->{type} eq "doctype") ) {
					if ($entry =~ /^SAMPLE($|\s)/i) {
						$entry =~ s/^SAMPLE\s*//i;
						$data = "<$self->{preformatted}>" . $self->_mk_example($data) . "</$self->{preformatted}>";
						push @tag, {
								entry	=> $entry,
								data	=> $data,
						};
					} else {
						$data = $self->_process_text($data, $name, $href);
						push @tag, {
								entry	=> $entry,
								data	=> $data,
						};
					}
				}
			}
		}
	}

	return (\@doc, \@tag);
}

sub _get_doc_attrs {
	my $self = shift;
	my ($name) = @_;

	my @doc_attrs = ();
	if ($self->{flag_comment} and exists $self->{hash_attr}->{$name}) {
		foreach my $attr (@{$self->{hash_attr}->{$name}}) {
			if (exists $attr->{comments}) {
				my @doc = ();
				my @tag = ();
				foreach my $comment (@{$attr->{comments}}) {
					my ($doc, $r_tags) = $self->_extract_doc($comment);
					if (defined $doc) {
						my $data = $self->_process_text($doc, $name);
						push @doc, { data => $data };
					}
					foreach (@{$r_tags}) {
						my ($href, $entry, $data) = @{$_};
						unless (   uc($entry) eq "BRIEF"
								or uc($entry) eq "HIDDEN" ) {
							if ($entry =~ /^SAMPLE($|\s)/i) {
								$entry =~ s/^SAMPLE\s*//i;
								$data = "<$self->{preformatted}>" . $self->_mk_example($data) . "</$self->{preformatted}>";
								push @tag, {
										entry	=> $entry,
										data	=> $data,
								};
							} else {
								$data = $self->_process_text($data, $name, $href);
								push @tag, {
										entry	=> $entry,
										data	=> $data,
								};
							}
						}
					}
				}
				push @doc_attrs, {
						name		=> $attr->{aName},
						doc			=> [ @doc ],
						tag			=> [ @tag ],
				}
			}
		}
	}

	return \@doc_attrs;
}

sub _get_style {
	my $self = shift;
	my ($name) = @_;

	my $style = "";
	my $path = ${$self->{path_tmpl}}[-1];
	open my $IN, '<', "$path/$name"
			or warn "can't open $path/$name ($!)",
			return $style;

	while (<$IN>) {
		$style .= $_;
	}
	close $IN;
	return $style;
}

sub generateMain {
	my $self = shift;

	my $standalone = "";
	my $version;
	my $encoding;
	if (defined $self->{xml_decl}) {
		$standalone = $self->{xml_decl}->{Standalone};
		$version = $self->{xml_decl}->{Version};
		$encoding = $self->{xml_decl}->{Encoding};
	}
	my $decl = $self->{dtd};
	my $name = $decl->{Name};
	my ($r_doc, $r_tag) = $self->_get_doc($decl);
	$self->{template}->param(
			dtd			=> "<a href='#elt_" . $name . "'>" . $name . "</a>",
			standalone	=> ($standalone eq "yes"),
			version		=> $version,
			encoding	=> $encoding,
			publicId	=> $decl->{PublicId},
			systemId	=> $decl->{SystemId},
			doc			=> $r_doc,
			tag			=> $r_tag,
	);

	my  @decls = ();
	foreach my $decl (@{$self->{list_decl}}) {
		my $type = $decl->{type};
		my $name = $decl->{Name};
		($r_doc, $r_tag) = $self->_get_doc($decl);
		if      ($type eq "notation") {
			push @decls, {
					is_notation			=> 1,
					is_internal_entity	=> 0,
					is_external_entity	=> 0,
					is_element			=> 0,
					name				=> $name,
					a					=> "<a id='not_" . $name . "' name='not_" . $name . "'/>",
					publicId			=> $decl->{PublicId},
					systemId			=> $decl->{SystemId},
					both_id				=> defined($decl->{PublicId}) && defined($decl->{SystemId}),
					doc					=> $r_doc,
					tag					=> $r_tag,
			};
		} elsif ($type eq "internal_entity") {
			push @decls, {
					is_notation			=> 0,
					is_internal_entity	=> 1,
					is_external_entity	=> 0,
					is_element			=> 0,
					name				=> $name,
					a					=> "<a id='ent_" . $name . "' name='ent_" . $name . "'/>",
					value				=> "&amp;#" . ord $decl->{Value} . ";",
					doc					=> $r_doc,
					tag					=> $r_tag,
			};
		} elsif ($type eq "external_entity") {
			push @decls, {
					is_notation			=> 0,
					is_internal_entity	=> 0,
					is_external_entity	=> 1,
					is_element			=> 0,
					name				=> $name,
					a					=> "<a id='ent_" . $name . "' name='ent_" . $name . "'/>",
					publicId			=> $decl->{PublicId},
					systemId			=> $decl->{SystemId},
					doc					=> $r_doc,
					tag					=> $r_tag,
			};
		} elsif ($type eq "element") {
			my $model = $decl->{Model};
			my @attrs = ();
			if (exists $self->{hash_attr}->{$name}) {
				foreach my $attr (@{$self->{hash_attr}->{$name}}) {
					my $type = $attr->{Type};
					my $tokenized_type =  $type eq "CDATA"
					                   || $type eq "ID"
					                   || $type eq "IDREF"
					                   || $type eq "IDREFS"
					                   || $type eq "ENTITY"
					                   || $type eq "ENTITIES"
					                   || $type eq "NMTOKEN"
					                   || $type eq "NMTOKENS";
					unless ($tokenized_type) {
						$type =~ s/\(/\( /;
						$type =~ s/\)/ \)/;
						$type =~ s/\|/ \| /g;
					}
					my $value = $attr->{Value};
					$value = "\"$attr->{Value}\"" if ($value);
					push @attrs, {
							name				=> $name,
							attr_name			=> $attr->{aName},
							type				=> $type,
							tokenized_type		=> $tokenized_type,
							value_default		=> $attr->{ValueDefault},
							value				=> $value,
					};
				}
			}
			push @decls, {
					is_notation			=> 0,
					is_internal_entity	=> 0,
					is_external_entity	=> 0,
					is_element			=> 1,
					name				=> $name,
					a					=> "<a id='elt_" . $name . "' name='elt_" . $name . "'/>",
					model				=> $self->_format_content_model($model),
					attrs				=> \@attrs,
					doc					=> $r_doc,
					tag					=> $r_tag,
					doc_attrs			=> $self->_get_doc_attrs($name),
			};
		} else {
			warn __PACKAGE__,":generateMain INTERNAL_ERROR (type:$type)\n";
		}
	}
	$self->{template}->param(
			decls		=> \@decls,
	);
	return;
}

sub _process_example {
	my $self = shift;
	my($text) = @_;

	# keep track of leading and trailing white-space
	my $lead  = ($text =~ s/\A(\s+)//s ? $1 : "");
	my $trail = ($text =~ s/(\s+)\Z//s ? $1 : "");

	# split at space/non-space boundaries
	my @words = split( /(?<=\s)(?=\S)|(?<=\S)(?=\s)/, $text );

	# process each word individually
	foreach my $word (@words) {
		# skip space runs
		next if $word =~ /^\s*$/;
		if ($word =~ /^&lt;([A-Za-z_:][0-9A-Za-z\.\-_:]*)(&gt;[\S]*)?$/) {
			# looks like a DTD name, in example file
			if (exists $self->{hash_notation}->{$1}) {
				$word = "&lt;" . $self->_mk_text_anchor("not", $1);
				$word .= $2 if (defined $2);
			}
			elsif (exists $self->{hash_entity}->{$1}) {
				$word = "&lt;" . $self->_mk_text_anchor("ent", $1);
				$word .= $2 if (defined $2);
			}
			elsif (exists $self->{hash_element}->{$1}) {
				$word = "&lt;" . $self->_mk_text_anchor("elt", $1);
				$word .= $2 if (defined $2);
			}
		}
	}

	# put everything back together
	return $lead . join('', @words) . $trail;
}

sub _mk_example {
	my $self = shift;
	my ($example, $emphasis) = @_;

	open my $IN, '<', $example
			or warn "can't open $example ($!)",
			next;
	my $data;
	while (<$IN>) {
		s/&/&amp;/g;
		s/</&lt;/g;
		s/>/&gt;/g;
		s/'/&apos;/g;
		s/\"/&quot;/g;
		s/&lt;!--/<$self->{emphasis}>&lt;!--/g;
		s/--&gt;/--&gt;<\/$self->{emphasis}>/g;
		$data .= $self->_process_example($_);
	}
	close $IN;

	return $data;
}

sub generateExample {
	my $self = shift;

	my @examples = ();
	foreach my $ex (@{$self->{examples}}) {
		push @examples, {
				filename	=> $ex,
				a			=> "<a id='ex_" . $ex . "' name='ex_" . $ex . "'/>",
				text		=> $self->_mk_example($ex),
		};
	}
	$self->{template}->param(
			nb_example	=> scalar @{$self->{examples}},
			examples	=> \@examples,
	);
	return;
}

sub generateCSS {
	my $self = shift;
	my ($style) = @_;

	my $outfile = $self->{dirname} . "/" . $self->{css} . ".css";

	unless ( -e $outfile) {
		open my $OUT, '>', $outfile
				or die "can't open $outfile ($!)\n";
		print $OUT $style;
		close $OUT;
	}
	return;
}

sub GenerateHTML {
	my $self = shift;

	warn "No element declaration captured.\n"
			unless (scalar keys %{$self->{hash_element}});

	$self->_process_args(@_);

	my $style = $self->_get_style("simple.css");

	$self->generateCSS($style) if ($self->{css});

	my $template = "simple.tmpl";
	$self->{template} = HTML::Template->new(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
			title		=> $self->{title},
	);
	$self->generateAlphaElement();
	$self->generateAlphaEntity();
	$self->generateAlphaNotation();
	$self->generateExampleIndex();
	$self->generateTree();
	$self->generateMain();
	$self->generateExample();

	my $filename = $self->{outfile} . ".html";
	open my $OUT, '>', $filename
			or die "can't open $filename ($!)\n";
	print $OUT $self->{template}->output();
	close $OUT;
	return;
}

###############################################################################

package XML::Handler::Dtd2Html::DocumentFrame;

use strict;
use warnings;

use base qw(XML::Handler::Dtd2Html::Document);

sub _mk_index_href {
	my $self = shift;
	my($type, $name) = @_;

	return $self->{filebase} . ".main.html#" . $type . "_" . $name;
}

sub GenerateHTML {
	my $self = shift;

	warn "No element declaration captured.\n"
			unless (scalar keys %{$self->{hash_element}});

	$self->_process_args(@_);

	my $style = $self->_get_style("frame.css");

	$self->generateCSS($style) if ($self->{css});

	my $template = "frame.tmpl";
	$self->{template} = HTML::Template->new(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
			title		=> $self->{title},
			file		=> $self->{filebase},
	);

	my $filename = $self->{outfile} . ".html";
	open my $OUT, '>', $filename
			or die "can't open $filename ($!)\n";
	print $OUT $self->{template}->output();
	close $OUT;

	$template = "alpha.tmpl";
	$self->{template} = HTML::Template->new(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
			css			=> $self->{css},
			title_page	=> $self->{title} . " (Alpha)",
	);
	$self->generateAlphaElement();
	$self->generateAlphaEntity();
	$self->generateAlphaNotation();
	$self->generateExampleIndex();

	$filename = $self->{outfile} . ".alpha.html";
	open $OUT, '>', $filename
			or die "can't open $filename ($!)\n";
	print $OUT $self->{template}->output();
	close $OUT;

	$template = "tree.tmpl";
	$self->{template} = HTML::Template->new(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
			css			=> $self->{css},
			title_page	=> $self->{title} . " (Tree)",
	);
	$self->generateTree();

	$filename = $self->{outfile} . ".tree.html";
	open $OUT, '>', $filename
			or die "can't open $filename ($!)\n";
	print $OUT $self->{template}->output();
	close $OUT;

	$template = "main.tmpl";
	$self->{template} = HTML::Template->new(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
			css			=> $self->{css},
			title		=> $self->{title},
			title_page	=> $self->{title} . " (Main)",
	);
	$self->generateMain();
	$self->generateExample();

	$filename = $self->{outfile} . ".main.html";
	open $OUT, '>', $filename
			or die "can't open $filename ($!)\n";
	print $OUT $self->{template}->output();
	close $OUT;
	return;
}

###############################################################################

package XML::Handler::Dtd2Html::DocumentBook;

use strict;
use warnings;

use base qw(XML::Handler::Dtd2Html::Document);

sub _get_brief {
	my $self = shift;
	my ($decl) = @_;

	if ($self->{flag_comment} and exists $decl->{comments}) {
		foreach my $comment (@{$decl->{comments}}) {
			my ($doc, $r_tags) = $self->_extract_doc($comment);
			foreach my $tag (@{$r_tags}) {
				my $entry = ${$tag}[1];
				my $data  = ${$tag}[2];
				if (uc($entry) eq "BRIEF") {
					return $data;
				}
			}
		}
	}
	return undef;
}

sub _get_parents {
	my $self = shift;
	my ($decl) = @_;

	my @parents = ();
	foreach (sort keys %{$decl->{used_by}}) {
		push @parents, { a => $self->_mk_text_anchor("elt", $_) };
	}

	return \@parents;
}

sub _get_childs {
	my $self = shift;
	my ($decl) = @_;

	my @childs = ();
	foreach (sort keys %{$decl->{uses}}) {
		push @childs, { a => $self->_mk_text_anchor("elt", $_) };
	}

	return \@childs;
}

sub _get_attributes {
	my $self = shift;
	my ($name) = @_;

	my @attrs = ();
	if (exists $self->{hash_attr}->{$name}) {
		foreach my $attr (@{$self->{hash_attr}->{$name}}) {
			my @enum = ();
			my $is_enum;
			my $is_notation;
			my $type = $attr->{Type};
			if (        $type ne "CDATA"
					and $type ne "ID"
					and $type ne "IDREF"
					and $type ne "IDREFS"
					and $type ne "ENTITY"
					and $type ne "ENTITIES"
					and $type ne "NMTOKEN"
					and $type ne "NMTOKENS" ) {
				if ($type =~ /^NOTATION/) {
					$is_notation = 1;
					$type =~ s/^NOTATION\s*\(//;
					$type =~ s/\)$//;
					foreach (split /\|/, $type) {
						push @enum, {
								val		=> $_,
						};
					}
				} else {
					$is_enum = 1;
					$type =~ s/^\(//;
					$type =~ s/\)$//;
					foreach (split /\|/, $type) {
						push @enum, {
								val		=> $_,
						};
					}
				}
			}
			my $value_default = $attr->{ValueDefault};
			my $value = $attr->{Value};
			if ($value) {
				$value_default .= " \"" . $value . "\"";
			}
			$value_default = "&#160;" unless ($value_default);
			push @attrs, {
					attr_name	=> $attr->{aName},
					is_enum		=> $is_enum,
					is_notation	=> $is_notation,
					enum		=> \@enum,
					type		=> $type,
					value_default	=> $value_default,
			};
		}
	}

	return \@attrs;
}

sub _mk_value {
	my $self = shift;
	my($value) = @_;

	return $value;
}

sub _mk_index_href {
	my $self = shift;
	my($type, $name) = @_;

	my $uri_name = $name;
	$uri_name =~ s/[ :]/_/g;
	$uri_name = $self->_mk_filename($uri_name);

	return $self->{filebase} . "." . $type . "." . $uri_name . ".html";
}

sub _mk_nav_href {
	my $self = shift;
	my($type, $name) = @_;

	return undef unless ($name);

	return $self->_mk_index_href($type, $name);
}

sub _mk_outfile {
	my $self = shift;
	my($type, $name) = @_;

	my $uri_name = $name;
	$uri_name =~ s/[ :]/_/g;
	$uri_name = $self->_mk_filename($uri_name);

	return $self->{outfile} . "." . $type . "." . $uri_name . ".html";
}

sub _test_sensitive {
	my $self = shift;
	use File::Temp qw(tempfile);

	my ($fh, $filename) = tempfile("caseXXXX");
	close $fh;
	if (-e $filename and -e uc $filename) {
		$self->{not_sensitive} = 1;
	}
	unlink $filename;
	return;
}

sub _mk_filename {
	my $self = shift;
	my ($name) = @_;
	return $name unless (exists $self->{not_sensitive});
	$name =~ s/([A-Z])/$1_/g;
	$name =~ s/([a-z])/_$1/g;
	return $name;
}

sub copyPNG {
	my $self = shift;
	use File::Copy;

	my $path = ${$self->{path_tmpl}}[-1];
	foreach my $img (qw(next up home prev)) {
		my $infile = $path . "/" . $img .".png";
		my $outfile = $self->{dirname} . "/" . $img . ".png";
		unless ( -e $infile) {
			warn "can't find $infile.\n";
			next;
		}
		copy($infile, $outfile);
		unless ( -e $outfile) {
			warn "$outfile is not copied.\n";
		}
	}
	return;
}

sub GenerateHTML {
	my $self = shift;

	warn "No element declaration captured.\n"
			unless (scalar keys %{$self->{hash_element}});

	$self->_process_args(@_);

	$self->_test_sensitive();

	my $style = $self->_get_style("book.css");

	$self->generateCSS($style) if ($self->{css});
	$self->copyPNG();

	my $template = "book.tmpl";
	$self->{template} = HTML::Template->new(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
			css			=> $self->{css},
			book_title	=> $self->{title},
	);
	$self->{template}->param(
			page_title	=> $self->{title},
			href_next	=> $self->_mk_nav_href("", ""),
			href_prev	=> $self->_mk_nav_href("", ""),
			href_home	=> $self->_mk_nav_href("book", "home"),
			href_up		=> $self->_mk_nav_href("", ""),
			lbl_next	=> "&nbsp;",
			lbl_prev	=> "&nbsp;",
	);
	$self->{template}->param(
			href_prolog	=> $self->{filebase} . ".book." . $self->_mk_filename("prolog") . ".html",
			href_elt	=> $self->{filebase} . ".book." . $self->_mk_filename("elements_index") . ".html",
			href_ent	=> $self->{filebase} . ".book." . $self->_mk_filename("entities_index") . ".html",
			href_not	=> $self->{filebase} . ".book." . $self->_mk_filename("notations_index") . ".html",
			href_ex		=> $self->{filebase} . ".book." . $self->_mk_filename("examples_list") . ".html",
	);
	$self->generateTree();

	my $filename = $self->_mk_outfile("book", "home");
	open my $OUT, '>', $filename
			or die "can't open $filename ($!)\n";
	print $OUT $self->{template}->output();
	close $OUT;

	$template = "prolog.tmpl";
	$self->{template} = HTML::Template->new(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
			css			=> $self->{css},
			book_title	=> $self->{title},
	);
	$self->{template}->param(
			page_title	=> $self->{title},
			href_next	=> $self->_mk_nav_href("book", "elements index"),
			href_prev	=> $self->_mk_nav_href("book", "home"),
			href_home	=> $self->_mk_nav_href("book", "home"),
			href_up		=> $self->_mk_nav_href("book", "home"),
			lbl_next	=> "elements index",
			lbl_prev	=> "home",
	);
	my ($r_doc, $r_tag) = $self->_get_doc($self->{dtd});
	$self->{template}->param(
			name		=> $self->{dtd}->{Name},
			brief		=> $self->_get_brief($self->{dtd}),
			publicId	=> $self->{dtd}->{PublicId},
			systemId	=> $self->{dtd}->{SystemId},
			doc			=> $r_doc,
			tag			=> $r_tag,
	);

	$filename = $self->_mk_outfile("book", "prolog");
	open $OUT, '>', $filename
			or die "can't open $filename ($!)\n";
	print $OUT $self->{template}->output();
	close $OUT;

	$template = "index.tmpl";
	$self->{template} = HTML::Template->new(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
			css			=> $self->{css},
			book_title	=> $self->{title},
	);
	$self->{template}->param(
			page_title	=> "Elements Index.",
			href_next	=> $self->_mk_nav_href("book", "entities index"),
			href_prev	=> $self->_mk_nav_href("book", "prolog"),
			href_home	=> $self->_mk_nav_href("book", "home"),
			href_up		=> $self->_mk_nav_href("book", "home"),
			lbl_next	=> "entities index",
			lbl_prev	=> "prolog",
	);
	$self->{template}->param(
			idx_elt		=> 1,
			idx_ent		=> 0,
			idx_not		=> 0,
			lst_ex		=> 0,
	);
	$self->generateAlphaElement("nb", "a_link", 1);
	my @elements = sort keys %{$self->{hash_element}};

	$filename = $self->_mk_outfile("book", "elements_index");
	open $OUT, '>', $filename
			or die "can't open $filename ($!)\n";
	print $OUT $self->{template}->output();
	close $OUT;

	if (scalar @elements) {
		$template = "element.tmpl";
		$self->{template} = HTML::Template->new(
				filename	=> $template,
				path		=> $self->{path_tmpl},
				loop_context_vars	=> 1,
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		$self->{template}->param(
				generator	=> $self->{generator},
				date		=> $self->{now},
				css			=> $self->{css},
				book_title	=> $self->{title},
		);

		my @prevs = @elements;
		my @nexts = @elements;
		pop @prevs;
		unshift @prevs, "elements index";
		shift @nexts;
		push @nexts, "";
		my $first = 1;
		foreach my $name (@elements) {
			my $decl = $self->{hash_element}->{$name};
			my $type_p = $first ? "book" : "elt";
			my $type_n = "elt";
			my $prev = shift @prevs;
			my $next = shift @nexts;

			$self->{template}->param(
					page_title	=> "Element " . $name,
					href_next	=> $self->_mk_nav_href($type_n, $next),
					href_prev	=> $self->_mk_nav_href($type_p, $prev),
					href_home	=> $self->_mk_nav_href("book", "home"),
					href_up		=> $self->_mk_nav_href("book", "elements index"),
					lbl_next	=> ($next ? $next : "&nbsp;"),
					lbl_prev	=> ($prev ? $prev : "&nbsp;"),
			);
			my $model = $decl->{Model};
			($r_doc, $r_tag) = $self->_get_doc($decl);
			$self->{template}->param(
					name		=> $name,
					brief		=> $self->_get_brief($decl),
					f_model		=> $self->_format_content_model($model),
					attrs		=> $self->_get_attributes($name),
					parents		=> $self->_get_parents($decl),
					childs		=> $self->_get_childs($decl),
					doc			=> $r_doc,
					tag			=> $r_tag,
					doc_attrs	=> $self->_get_doc_attrs($name),
					is_mixed	=> ($model =~ /#PCDATA/) ? 1 : 0,
					is_element	=> ($model !~ /(ANY|EMPTY)/) ? 1 : 0,
			);

			$filename = $self->_mk_outfile($type_n, $name);
			open $OUT, '>', $filename
					or die "can't open $filename ($!)\n";
			print $OUT $self->{template}->output();
			close $OUT;
			$first = 0;
		}
	}

	$template = "index.tmpl";
	$self->{template} = HTML::Template->new(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
			css			=> $self->{css},
			book_title	=> $self->{title},
	);
	$self->{template}->param(
			page_title	=> "Entities Index.",
			href_next	=> $self->_mk_nav_href("book", "notations index"),
			href_prev	=> $self->_mk_nav_href("book", "elements index"),
			href_home	=> $self->_mk_nav_href("book", "home"),
			href_up		=> $self->_mk_nav_href("book", "home"),
			lbl_next	=> "notations index",
			lbl_prev	=> "elements index",
	);
	$self->{template}->param(
			idx_elt		=> 0,
			idx_ent		=> 1,
			idx_not		=> 0,
			lst_ex		=> 0,
	);
	my @entities = sort keys %{$self->{hash_entity}};
	$self->generateAlphaEntity("nb", "a_link", 1);

	$filename = $self->_mk_outfile("book","entities_index");
	open $OUT, '>', $filename
			or die "can't open $filename ($!)\n";
	print $OUT $self->{template}->output();
	close $OUT;

	if (scalar @entities) {
		$template = "entity.tmpl";
		$self->{template} = HTML::Template->new(
				filename	=> $template,
				path		=> $self->{path_tmpl},
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		$self->{template}->param(
				generator	=> $self->{generator},
				date		=> $self->{now},
				css			=> $self->{css},
				book_title	=> $self->{title},
		);

		my @prevs = @entities;
		my @nexts = @entities;
		pop @prevs;
		unshift @prevs, "entities index";
		shift @nexts;
		push @nexts, "";
		my $first = 1;
		foreach (@entities) {
			my $decl = $self->{hash_entity}->{$_};
			my $type_p = $first ? "book" : "ent";
			my $type_n = "ent";
			my $prev = shift @prevs;
			my $next = shift @nexts;

			$self->{template}->param(
					page_title	=> "Entity " . $_,
					href_next	=> $self->_mk_nav_href($type_n, $next),
					href_prev	=> $self->_mk_nav_href($type_p, $prev),
					href_home	=> $self->_mk_nav_href("book", "home"),
					href_up		=> $self->_mk_nav_href("book", "entities index"),
					lbl_next	=> ($next ? $next : "&nbsp;"),
					lbl_prev	=> ($prev ? $prev : "&nbsp;"),
			);
			($r_doc, $r_tag) = $self->_get_doc($decl);
			$self->{template}->param(
					name		=> $_,
					brief		=> $self->_get_brief($decl),
					value		=> (exists $decl->{Value}) ? ord($decl->{Value}) : undef,
					publicId	=> $decl->{PublicId},
					systemId	=> $decl->{SystemId},
					doc			=> $r_doc,
					tag			=> $r_tag,
			);

			$filename = $self->_mk_outfile($type_n, $_);
			open $OUT, '>', $filename
					or die "can't open $filename ($!)\n";
			print $OUT $self->{template}->output();
			close $OUT;
			$first = 0;
		}
	}

	$template = "index.tmpl";
	$self->{template} = HTML::Template->new(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
			css			=> $self->{css},
			book_title	=> $self->{title},
	);
	$self->{template}->param(
			page_title	=> "Notations Index.",
			href_next	=> $self->_mk_nav_href("book", "examples list"),
			href_prev	=> $self->_mk_nav_href("book", "entities index"),
			href_home	=> $self->_mk_nav_href("book", "home"),
			href_up		=> $self->_mk_nav_href("book", "home"),
			lbl_next	=> "examples list",
			lbl_prev	=> "entities index",
	);
	$self->{template}->param(
			idx_elt		=> 0,
			idx_ent		=> 0,
			idx_not		=> 1,
			lst_ex		=> 0,
	);
	my @notations = sort keys %{$self->{hash_notation}};
	$self->generateAlphaNotation("nb", "a_link", 1);

	$filename = $self->_mk_outfile("book", "notations_index");
	open $OUT, '>', $filename
			or die "can't open $filename ($!)\n";
	print $OUT $self->{template}->output();
	close $OUT;

	if (scalar @notations) {
		$template = "notation.tmpl";
		$self->{template} = HTML::Template->new(
				filename	=> $template,
				path		=> $self->{path_tmpl},
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		$self->{template}->param(
				generator	=> $self->{generator},
				date		=> $self->{now},
				css			=> $self->{css},
				book_title	=> $self->{title},
		);

		my @prevs = @notations;
		my @nexts = @notations;
		pop @prevs;
		unshift @prevs, "notations_index";
		shift @nexts;
		push @nexts, "";
		my $first = 1;
		foreach (@notations) {
			my $decl = $self->{hash_notation}->{$_};
			my $type_p = $first ? "book" : "not";
			my $type_n = "not";
			my $prev = shift @prevs;
			my $next = shift @nexts;

			$self->{template}->param(
					page_title	=> "Notation " . $_,
					href_next	=> $self->_mk_nav_href($type_n, $next),
					href_prev	=> $self->_mk_nav_href($type_p, $prev),
					href_home	=> $self->_mk_nav_href("book", "home"),
					href_up		=> $self->_mk_nav_href("book", "notations index"),
					lbl_next	=> ($next ? $next : "&nbsp;"),
					lbl_prev	=> ($prev ? $prev : "&nbsp;"),
			);
			($r_doc, $r_tag) = $self->_get_doc($decl);
			$self->{template}->param(
					name		=> $_,
					brief		=> $self->_get_brief($decl),
					publicId	=> $decl->{PublicId},
					systemId	=> $decl->{SystemId},
					doc			=> $r_doc,
					tag			=> $r_tag,
			);

			$filename = $self->_mk_outfile($type_n, $_);
			open $OUT, '>', $filename
					or die "can't open $filename ($!)\n";
			print $OUT $self->{template}->output();
			close $OUT;
			$first = 0;
		}
	}

	$template = "index.tmpl";
	$self->{template} = HTML::Template->new(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
			css			=> $self->{css},
			book_title	=> $self->{title},
	);
	$self->{template}->param(
			page_title	=> "Examples List.",
			href_next	=> $self->_mk_nav_href("", ""),
			href_prev	=> $self->_mk_nav_href("book", "notations index"),
			href_home	=> $self->_mk_nav_href("book", "home"),
			href_up		=> $self->_mk_nav_href("book", "home"),
			lbl_next	=> "&nbsp;",
			lbl_prev	=> "notations index",
	);
	$self->{template}->param(
			idx_elt		=> 0,
			idx_ent		=> 0,
			idx_not		=> 0,
			lst_ex		=> 1,
	);
	my @examples = @{$self->{examples}};
	$self->generateExampleIndex("nb", "a_link");

	$filename = $self->_mk_outfile("book", "examples_list");
	open $OUT, '>', $filename
			or die "can't open $filename ($!)\n";
	print $OUT $self->{template}->output();
	close $OUT;

	if (scalar @examples) {
		$template = "example.tmpl";
		$self->{template} = HTML::Template->new(
				filename	=> $template,
				path		=> $self->{path_tmpl},
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		$self->{template}->param(
				generator	=> $self->{generator},
				date		=> $self->{now},
				css			=> $self->{css},
				book_title	=> $self->{title},
		);

		my @prevs = @examples;
		my @nexts = @examples;
		pop @prevs;
		unshift @prevs, "examples list";
		shift @nexts;
		push @nexts, "";
		my $first = 1;
		foreach my $example (@examples) {
			my $type_p = $first ? "book" : "ex";
			my $type_n = "ex";
			my $prev = shift @prevs;
			my $next = shift @nexts;

			$self->{template}->param(
					page_title	=> "Example " . $example,
					href_next	=> $self->_mk_nav_href($type_n, $next),
					href_prev	=> $self->_mk_nav_href($type_p, $prev),
					href_home	=> $self->_mk_nav_href("book", "home"),
					href_up		=> $self->_mk_nav_href("book", "examples list"),
					lbl_next	=> ($next ? $next : "&nbsp;"),
					lbl_prev	=> ($prev ? $prev : "&nbsp;"),
			);
			$self->{template}->param(
					example		=> $self->_mk_example($example),
			);

			$filename = $self->_mk_outfile($type_n, $example);
			open $OUT, '>', $filename
					or die "can't open $filename ($!)\n";
			print $OUT $self->{template}->output();
			close $OUT;
			$first = 0;
		}
	}
	return;
}

1;

__END__

=head1 NAME

XML::Handler::Dtd2Html - SAX2 handler for generate a HTML documentation from a DTD

=head1 SYNOPSIS

  use XML::SAX::Expat;
  use XML::Handler::Dtd2Html;

  $handler = XML::Handler::Dtd2Html->new();

  $parser = XML::SAX::Expat->new(Handler => $handler);
  $parser->set_feature("http://xml.org/sax/features/external-general-entities", 1);
  $doc = $parser->parse( [OPTIONS] );

  $doc->GenerateHTML( [PARAMS] );

=head1 DESCRIPTION

All comments before a declaration are captured.

All entity references inside attribute values are expanded.

=head1 AUTHOR

Francois Perrad, francois.perrad@gadz.org

=head1 SEE ALSO

dtd2html.pl

=head1 COPYRIGHT

(c) 2002-2003 Francois PERRAD, France. All rights reserved.

This program is distributed under the Artistic License.

=cut

