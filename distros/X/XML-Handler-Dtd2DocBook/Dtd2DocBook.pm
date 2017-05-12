
package XML::Handler::Dtd2DocBook;

use base qw(XML::Handler::Dtd2Html);

use vars qw($VERSION);

$VERSION="0.41";

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
			doc         => new XML::Handler::Dtd2DocBook::Document(),
			comments    => []
	};
	bless($self, $class);
	return $self;
}

###############################################################################

package XML::Handler::Dtd2DocBook::Document;

use HTML::Template;
use File::Basename;

use base qw(XML::Handler::Dtd2Html::DocumentBook);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new();
	$self->{hlink} = 0;
	$self->{preformatted} = "programlisting";
	$self->{emphasis} = "emphasis";
	$self->{width} = 65;
	bless($self, $class);
	return $self;
}

sub _process_args {
	my $self = shift;
	my %hash = @_;

	$self->SUPER::_process_args(@_);

	$self->{generator} = "dtd2db " . $XML::Handler::Dtd2DocBook::VERSION . " (Perl " . $] . ")";

	if (defined $hash{path_tmpl}) {
		$self->{path_tmpl} = [ $hash{path_tmpl} ];
	} else {
		my $language = $hash{language} || 'en';
		my $path = $INC{'XML/Handler/Dtd2DocBook.pm'};
		$path =~ s/\.pm$//i;
		$self->{path_tmpl} = [ $path . '/' . $language, $path ];
	}
}

sub _mk_text_anchor {
	my $self = shift;
	my($type, $name) = @_;

	my $linkend = $type . "." . $name;
	return "<link linkend='" . $linkend . "'><sgmltag>" . $name . "</sgmltag></link>";
}

sub _mk_index_anchor {
	my $self = shift;
	my($type, $name) = @_;

	return $name;
}

sub _mk_outfile {
	my $self = shift;
	my($type, $name) = @_;

	my $uri_name = $name;
	$uri_name =~ s/[ :]/_/g;
	$uri_name = $self->_mk_filename($uri_name);

	return $self->{outfile} . "." . $type . "." . $uri_name . ".gen";
}

sub _mk_system {
	my $self = shift;
	my($type, $name) = @_;

	my $uri_name = $name;
	$uri_name =~ s/[ :]/_/g;
	$uri_name = $self->_mk_filename($uri_name);

	return $self->{basename} . "." . $type . "." . $uri_name . ".gen";
}

sub _get_doc_attrs {
	my $self = shift;
	my ($name) = @_;

	my @doc_attrs = ();
	my @attrs = ();
	if (exists $self->{hash_attr}->{$name}) {
		foreach my $attr (@{$self->{hash_attr}->{$name}}) {
			my @doc = ();
			my @tag = ();
			if ($self->{flag_comment} and exists $attr->{comments}) {
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
			}
			push @doc_attrs, {
					name_ent	=> "elt." . $name . "." . $attr->{aName},
					name		=> $attr->{aName},
					doc			=> [ @doc ],
					tag			=> [ @tag ],
			};
			push @attrs, {
					name_ent	=> "elt." . $name . "." . $attr->{aName},
			};
		}
	}

	return (\@doc_attrs, \@attrs);
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
	$self->{_tree} .= "<itemizedlist spacing='compact'>\n";
	foreach (keys %{$self->{hash_element}->{$name}->{uses}}) {
		next if ($_ eq $name);
		next if (exists $done{$_});
		$done{$_} = 1;
		$self->{_tree} .= "  <listitem><para>" . $self->_mk_text_anchor("elt", $_) . "</para>\n";
		$self->_mk_tree($_, $depth+1);
		$self->{_tree} .= "  </listitem>\n";
	}
	$self->{_tree} .= "</itemizedlist>\n";
}

sub generateTree {
	my $self = shift;

	$self->{_tree_depth} = 1;
	$self->{_tree} = "<itemizedlist spacing='compact'>\n";
	$self->{_tree} .= "  <listitem><para>" . $self->_mk_text_anchor("elt", $self->{root_name}) . "</para>\n";
	if (exists $self->{hash_element}->{$self->{root_name}}) {
		$self->_mk_tree($self->{root_name}, $self->{_tree_depth});
	} else {
		warn "$self->{root_name} declared in DOCTYPE is an unknown element.\n";
	}
	$self->{_tree} .= "  </listitem>\n";
	$self->{_tree} .= "</itemizedlist>\n";
	$self->{_tree} = "" if ($self->{_tree_depth} > 7);
	$self->{template}->param(
			tree		=> $self->{_tree},
	);
	delete $self->{_tree};
}

sub generateEntity {
	my $self = shift;
	my ($prefix, $r_list) = @_;

	my @ent = ();
	foreach (@{$r_list}) {
		push @ent, {
				name			=> "&${prefix}.$_;",
		};
	}
	$self->{template}->param(
			ent		=> \@ent,
	);
}

sub GenerateDocBook {
	my $self = shift;

	warn "No element declaration captured.\n"
			unless (scalar keys %{$self->{hash_element}});

	$self->_process_args(@_);

	$self->_test_sensitive();

	my @elements = sort keys %{$self->{hash_element}};
	my @entities = sort keys %{$self->{hash_entity}};
	my @notations = sort keys %{$self->{hash_notation}};
	my @examples = @{$self->{examples}};

	my $template = "book.tmpl";
	$self->{template} = new HTML::Template(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
	);
	$self->{template}->param(
			name		=> $self->{basename},
			title		=> $self->{title},
			nb_elt		=> scalar @elements,
			nb_ent		=> scalar @entities,
			nb_not		=> scalar @notations,
			nb_ex		=> scalar @examples,
	);

	my $filename = $self->{outfile} . ".xml";
	open OUT, "> $filename"
			or die "can't open $filename ($!)\n";
	print OUT $self->{template}->output();
	close OUT;

	$template = "prolog.tmpl";
	$self->{template} = new HTML::Template(
			filename	=> $template,
			path		=> $self->{path_tmpl},
	);
	die "can't create template with $template ($!).\n"
			unless (defined $self->{template});

	$self->{template}->param(
			generator	=> $self->{generator},
			date		=> $self->{now},
	);
	$self->{template}->param(
			name		=> $self->{dtd}->{Name},
			publicId	=> $self->{dtd}->{PublicId},
			systemId	=> $self->{dtd}->{SystemId},
	);

	$filename = $self->{outfile} . ".prolog.gen";
	open OUT, "> $filename"
			or die "can't open $filename ($!)\n";
	print OUT $self->{template}->output();
	close OUT;

	if (scalar @elements) {
		$template = "index.tmpl";
		$self->{template} = new HTML::Template(
				filename	=> $template,
				path		=> $self->{path_tmpl},
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		$self->{template}->param(
				generator	=> $self->{generator},
				date		=> $self->{now},
		);
		$self->{template}->param(
				idx_elt		=> 1,
				idx_ent		=> 0,
				idx_not		=> 0,
				lst_ex		=> 0,
		);
		$self->generateEntity("elt", \@elements);
		$self->generateTree();

		$filename = $self->{outfile} . ".elements.gen";
		open OUT, "> $filename"
				or die "can't open $filename ($!)\n";
		print OUT $self->{template}->output();
		close OUT;

		$template = "element.tmpl";
		$self->{template} = new HTML::Template(
				filename	=> $template,
				path		=> $self->{path_tmpl},
				loop_context_vars => 1,
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		$self->{template}->param(
				generator	=> $self->{generator},
				date		=> $self->{now},
		);

		$filename = $self->{outfile} . ".elements.ent";
		open ENT, "> $filename"
				or die "can't open $filename ($!)\n";

		foreach my $name (@elements) {
			my $decl = $self->{hash_element}->{$name};

			my $model = $decl->{Model};
			$self->{template}->param(
					name		=> $name,
					fname		=> $self->_mk_filename($name),
					f_model		=> $self->_format_content_model($model),
					attrs		=> $self->_get_attributes($name),
					parents		=> $self->_get_parents($decl),
					childs		=> $self->_get_childs($decl),
					is_mixed	=> ($model =~ /#PCDATA/) ? 1 : 0,
					is_element	=> ($model !~ /(ANY|EMPTY)/) ? 1 : 0,
			);

			$filename = $self->_mk_outfile("elt", $name);
			open OUT, "> $filename"
					or die "can't open $filename ($!)\n";
			print OUT $self->{template}->output();
			close OUT;
			my $sys = $self->_mk_system("elt", $name);
			print ENT "<!ENTITY elt.",$name," SYSTEM '",$sys,"'>\n";
		}
		close ENT;
	}

	if (scalar @entities) {
		$template = "index.tmpl";
		$self->{template} = new HTML::Template(
				filename	=> $template,
				path		=> $self->{path_tmpl},
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		$self->{template}->param(
				generator	=> $self->{generator},
				date		=> $self->{now},
		);
		$self->{template}->param(
				idx_elt		=> 0,
				idx_ent		=> 1,
				idx_not		=> 0,
				lst_ex		=> 0,
		);
		$self->generateEntity("ent", \@entities);

		$filename = $self->{outfile} . ".entities.gen";
		open OUT, "> $filename"
				or die "can't open $filename ($!)\n";
		print OUT $self->{template}->output();
		close OUT;

		$template = "entity.tmpl";
		$self->{template} = new HTML::Template(
				filename	=> $template,
				path		=> $self->{path_tmpl},
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		$self->{template}->param(
				generator	=> $self->{generator},
				date		=> $self->{now},
		);

		$filename = $self->{outfile} . ".entities.ent";
		open ENT, "> $filename"
				or die "can't open $filename ($!)\n";

		foreach my $name (@entities) {
			my $decl = $self->{hash_entity}->{$name};

			$self->{template}->param(
					name		=> $name,
					fname		=> $self->_mk_filename($name),
					value		=> (exists $decl->{Value}) ? ord($decl->{Value}) : undef,
					publicId	=> $decl->{PublicId},
					systemId	=> $decl->{SystemId},
			);

			$filename = $self->_mk_outfile("ent", $name);
			open OUT, "> $filename"
					or die "can't open $filename ($!)\n";
			print OUT $self->{template}->output();
			close OUT;
			my $sys = $self->_mk_system("ent", $name);
			print ENT "<!ENTITY ent.",$name," SYSTEM '",$sys,"'>\n";
		}
		close ENT;
	}

	if (scalar @notations) {
		$template = "index.tmpl";
		$self->{template} = new HTML::Template(
				filename	=> $template,
				path		=> $self->{path_tmpl},
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		$self->{template}->param(
				generator	=> $self->{generator},
				date		=> $self->{now},
		);
		$self->{template}->param(
				idx_elt		=> 0,
				idx_ent		=> 0,
				idx_not		=> 1,
				lst_ex		=> 0,
		);
		$self->generateEntity("not", \@notations);

		$filename = $self->{outfile} . ".notations.gen";
		open OUT, "> $filename"
				or die "can't open $filename ($!)\n";
		print OUT $self->{template}->output();
		close OUT;

		$template = "notation.tmpl";
		$self->{template} = new HTML::Template(
				filename	=> $template,
				path		=> $self->{path_tmpl},
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		$self->{template}->param(
				generator	=> $self->{generator},
				date		=> $self->{now},
		);

		$filename = $self->{outfile} . ".notations.ent";
		open ENT, "> $filename"
				or die "can't open $filename ($!)\n";

		foreach my $name (@notations) {
			my $decl = $self->{hash_notation}->{$name};

			$self->{template}->param(
					name		=> $name,
					fname		=> $self->_mk_filename($name),
					publicId	=> $decl->{PublicId},
					systemId	=> $decl->{SystemId},
			);

			$filename = $self->_mk_outfile("not", $name);
			open OUT, "> $filename"
					or die "can't open $filename ($!)\n";
			print OUT $self->{template}->output();
			close OUT;
			my $sys = $self->_mk_system("not", $name);
			print ENT "<!ENTITY not.",$name," SYSTEM '",$sys,"'>\n";
		}
		close ENT;
	}

	if (scalar @examples) {
		$template = "index.tmpl";
		$self->{template} = new HTML::Template(
				filename	=> $template,
				path		=> $self->{path_tmpl},
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		$self->{template}->param(
				generator	=> $self->{generator},
				date		=> $self->{now},
		);
		$self->{template}->param(
				idx_elt		=> 0,
				idx_ent		=> 0,
				idx_not		=> 0,
				lst_ex		=> 1,
		);
		$self->generateEntity("ex", \@examples);

		$filename = $self->{outfile} . ".examples.gen";
		open OUT, "> $filename"
				or die "can't open $filename ($!)\n";
		print OUT $self->{template}->output();
		close OUT;

		$template = "example.tmpl";
		$self->{template} = new HTML::Template(
				filename	=> $template,
				path		=> $self->{path_tmpl},
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		$self->{template}->param(
				generator	=> $self->{generator},
				date		=> $self->{now},
		);

		$filename = $self->{outfile} . ".examples.ent";
		open ENT, "> $filename"
				or die "can't open $filename ($!)\n";

		foreach my $example (@examples) {
			$self->{template}->param(
					name		=> $example,
					fname		=> $self->_mk_filename($example),
					page_title	=> "Example " . $example,
					example		=> $self->_mk_example($example),
			);

			$filename = $self->_mk_outfile("ex", $example);
			open OUT, "> $filename"
					or die "can't open $filename ($!)\n";
			print OUT $self->{template}->output();
			close OUT;
			my $sys = $self->_mk_system("ex", $example);
			print ENT "<!ENTITY ex.",$example," SYSTEM '",$sys,"'>\n";
		}
		close ENT;
	}

	$filename = $self->{outfile} . ".customs.ent";
	unless ( -e $filename) {
		$template = "custom.tmpl";
		$self->{template} = new HTML::Template(
				filename	=> $template,
				path		=> $self->{path_tmpl},
		);
		die "can't create template with $template ($!).\n"
				unless (defined $self->{template});

		my @ent = ();

		my ($r_doc, $r_tag) = $self->_get_doc($self->{dtd});
		push @ent, {
				name		=> "prolog." . $self->{dtd}->{Name},
				brief		=> $self->_get_brief($self->{dtd}),
				doc			=> $r_doc,
				tag			=> $r_tag,
		};

		foreach my $name (@elements) {
			my $decl = $self->{hash_element}->{$name};

			($r_doc, $r_tag) = $self->_get_doc($decl);
			my ($r_doc_attrs, $r_attrs) = $self->_get_doc_attrs($name);
			push @ent, {
					name		=> "elt." . $name,
					brief		=> $self->_get_brief($decl),
					doc			=> $r_doc,
					tag			=> $r_tag,
					attrs		=> $r_attrs,
					doc_attrs	=> $r_doc_attrs,
			};
		}

		foreach my $name (@entities) {
			my $decl = $self->{hash_entity}->{$name};

			($r_doc, $r_tag) = $self->_get_doc($decl);
			push @ent, {
					name		=> "ent." . $name,
					brief		=> $self->_get_brief($decl),
					doc			=> $r_doc,
					tag			=> $r_tag,
			};
		}

		foreach my $name (@notations) {
			my $decl = $self->{hash_notation}->{$name};

			($r_doc, $r_tag) = $self->_get_doc($decl);
			push @ent, {
					name		=> "not." . $name,
					brief		=> $self->_get_brief($decl),
					doc			=> $r_doc,
					tag			=> $r_tag,
			};
		}

		$self->{template}->param(
				ent		=> \@ent,
		);

		open OUT, "> $filename"
				or die "can't open $filename ($!)\n";
		print OUT $self->{template}->output();
		close OUT;
	}
}

1;

__END__

=head1 NAME

XML::Handler::Dtd2DocBook - SAX2 handler for generate a DocBook documentation from a DTD

=head1 SYNOPSIS

  use XML::SAX::Expat;
  use XML::Handler::Dtd2DocBook;

  $handler = new XML::Handler::Dtd2DocBook;

  $parser = new XML::SAX::Expat(Handler => $handler);
  $parser->set_feature("http://xml.org/sax/features/external-general-entities", 1);
  $doc = $parser->parse( [OPTIONS] );

  $doc->GenerateDocBook( [PARAMS] );

=head1 DESCRIPTION

All comments before a declaration are captured.

All entity references inside attribute values are expanded.

=head1 AUTHOR

Francois Perrad, francois.perrad@gadz.org

=head1 SEE ALSO

dtd2db.pl

=head1 COPYRIGHT

(c) 2003 Francois PERRAD, France. All rights reserved.

This program is distributed under the Artistic License.

=cut

