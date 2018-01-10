package XBRL::JPFR::Taxonomy;

our $VERSION = '0.01';

use strict;
#use warnings;
use Carp;
use XML::LibXML;
use XML::LibXML::XPathContext;
use XML::LibXML::NodeList;
use XBRL::JPFR::Element;
use XBRL::JPFR::Label;
use XBRL::JPFR::Branch;
use Hash::Merge qw(merge);
use File::Basename qw(basename);
use Data::Dumper;

use base qw(XBRL::Taxonomy);

my @fields = qw(ref labelhash namespaces prohibiteds);
XBRL::JPFR::Taxonomy->mk_accessors(@fields);


my %default = (
	'lang'	=> 'ja',
);


sub new() {
	my ($class, $args) = @_;
	$args = {} if !$args;
	my $main_schema = delete $$args{'main_schema'};
	my $self = merge($args, \%default);
	bless $self, $class;

	$$self{'namespaces'} = [];
	if ($main_schema) {
		$self->add_schema($main_schema);
		$$self{'main_schema'} = $main_schema->namespace();
	}

	return $self;
}

sub set {
	my ($self, $key) = splice @_, 0, 2;
	if ($key eq 'def' || $key eq 'pre' || $key eq 'cal' || $key eq 'lab' || $key eq 'ref') {
		$$self{$key} = {} if !$$self{$key};
		$$self{$key} = merge($$self{$key}, $_[0]);
	}
	elsif ($key eq 'prohibiteds') {
		my ($type, $uri, $shorts) = @_;
		my $proh = exists $$self{'prohibiteds'}{$type}{$uri} ?
			$$self{'prohibiteds'}{$type}{$uri} : ($$self{'prohibiteds'}{$type}{$uri} = []);
		push @$proh, @$shorts;
	}
	else {
		$self->SUPER::set($key, @_);
	}
}

sub get_lb_files() {
	my ($self) = @_;
	my @out_array;
	my $schemas = $$self{'schemas'};
	foreach my $ns (@{$$self{'namespaces'}}) {
		my $main_xpath = $$schemas{$ns}->xpath();
		my $lbs = $main_xpath->findnodes("//*[local-name() = 'linkbaseRef']"  );
		foreach my $lb (@$lbs) {
			my $lb_file = $lb->getAttribute('xlink:href');
			if ($lb_file !~ /^http|^\//) {
				my $namespace = $lb->getAttribute('namespace');
				$namespace = $$schemas{$ns}->namespace() if !$namespace;
				$lb_file = "$namespace/$lb_file";
			}
			trans_old_location(\$lb_file, $lb);
			push(@out_array, $lb_file);
		}
	}
	return \@out_array;
}

sub get_other_schemas() {
	my ($self, $ns) = @_;
	my @out_array;
	$ns = $$self{'main_schema'} if !$ns;
 	my $main_xpath = $$self{'schemas'}{$ns}->xpath();
	#print STDERR "XML_XPATH=".Dumper($main_xpath);
	my $other_schemas = $main_xpath->findnodes("//*[local-name() = 'import']");
	foreach my $other (@$other_schemas) {
		my $location_url  = $other->getAttribute('schemaLocation');
		if ($location_url !~ /^http|^\//) {
			my $namespace = $other->getAttribute('namespace');
			my $fn = basename $location_url;
			$location_url  = "$namespace/$fn";
		}
		trans_old_location(\$location_url, $other);
		push(@out_array, $location_url) if $location_url;
	}
	return \@out_array;
}

sub trans_old_location {
	my ($loc, $node) = @_;
	if ($$loc eq 'http://disclosure.edinet-fsa.go.jp/taxonomy/jppfs/2012/jppfs_pe/jppfs_pe_2012.xsd') {
		$$loc = 'http://disclosure.edinet-fsa.go.jp/taxonomy/jppfs/2013-08-31/jppfs_pe_2012.xsd';
		$node->setAttribute('xlink:href', $$loc);
	}
	if ($$loc eq 'http://www.w3.org/1999/xlink/xlink-2003-12-31.xsd') {
		$$loc = 'http://www.xbrl.org/2003/xlink-2003-12-31.xsd';
		$node->setAttribute('xlink:href', $$loc);
	}
	if ($$loc eq 'http://www.xbrl.org/2003/XLink/xl-2003-12-31.xsd') {
		$$loc = 'http://www.xbrl.org/2003/xl-2003-12-31.xsd';
		$node->setAttribute('xlink:href', $$loc);
	}
	if ($$loc eq 'http://www.xbrl.org/2003/linkbase/xbrl-linkbase-2003-12-31.xsd') {
		$$loc = 'http://www.xbrl.org/2003/xbrl-linkbase-2003-12-31.xsd';
		$node->setAttribute('xlink:href', $$loc);
	}
	if ($$loc =~ s/xbrl\.iasb\.org\/taxonomy\/ifrs_/xbrl.iasb.org\/taxonomy\//) {
		$node->setAttribute('xlink:href', $$loc);
	}
	if ($$loc =~ s/http:\/\/info.edinet-fsa.go.jp\/ifrs\/gaap\/E.*?ifrs-/ifrs-/) {
		$node->setAttribute('xlink:href', $$loc);
	}
}

sub has_schema {
	my ($self, $file) = @_;
	my $schemas = $$self{'schemas'};
	foreach my $ns (keys %$schemas) {
		my $s_file = $$schemas{$ns}->file();
		return 1 if $file eq $s_file;
	}
	return 0;
}

sub add_schema() {
	my ($self, $schema) = @_;
		my $ns = $schema->namespace();	
		push @{$$self{'namespaces'}}, $ns;
		$$self{'schemas'}{$ns} = $schema;	
		my $element_nodes = $schema->xpath()->findnodes("//*[local-name() = 'element']");
		foreach my $el_xml (@$element_nodes) {
			my $e = XBRL::JPFR::Element->new($el_xml);
			my $id = $e->id();
			next if !$id;
			my $id_full = "$ns/". $e->name();
			$$self{'elements'}{$id} = $e;	
			$$schema{'elements'}{$id_full} = $e;	
		}
}

# XBRL2.1: 3.5.3.9.7.4 and 3.5.3.9.7.5
sub select_arcs() {
	my ($self) = @_;
	foreach my $type ('pre', 'def', 'cal', 'lab', 'ref') {
		my $all_arcs = $self->$type();
		next unless $all_arcs;
		foreach my $uri (keys %$all_arcs) {
			my $arcs = $$all_arcs{$uri};
			my (%pu, @dels);
			for (my $i = 0 ; $i < @$arcs ; $i++) {
				my $arc = $$arcs[$i];
				my ($from, $to) = @$arc{'from_short', 'to_short'};
				my ($arcrole, $pref) = @$arc{'arcrole', 'prefLabel'};
				my ($ord, $pri, $use) = @$arc{'order', 'priority', 'use'};
				$ord = sprintf "%g", $ord; # to delete trailing zero(s)
				if (exists $pu{$from}{$to}{$arcrole}{$pref}{$ord}) {
					my $pv = $pu{$from}{$to}{$arcrole}{$pref}{$ord};
					if ($$pv{'pri'} > $pri) {
						push @dels, $i;
						next;
					}
					elsif ($$pv{'pri'} < $pri) {
						push @dels, @{$$pv{'idx'}};
						$$pv{'pri'} = $pri;
						$$pv{'use'} = $use;
						$$pv{'idx'} = [$i];
					}
					else {
						$$pv{'use'} = $$pv{'use'} eq 'prohibited' || $use eq 'prohibited' ?
							'prohibited' : 'optional';
						$$pv{'pri'} = $pri;
						push @{$$pv{'idx'}}, $i;
					}
				}
				else {
					$pu{$from}{$to}{$arcrole}{$pref}{$ord}{'pri'} = $pri;
					$pu{$from}{$to}{$arcrole}{$pref}{$ord}{'use'} = $use;
					$pu{$from}{$to}{$arcrole}{$pref}{$ord}{'idx'} = [$i];
				}
			}
			my ($proh, $over) = prohibited_idxs(\%pu, $type);
			if (@$proh) {
				my @to_shorts = map {$$arcs[$_]->to_short()} @$proh;
				$self->prohibiteds($type, $uri, \@to_shorts);
			}
			push @dels, @$proh, @$over;
			my @deleteds = delete @$arcs[@dels] if @dels;
		}
	}
}

sub prohibited_idxs {
	my ($pu, $type) = @_;
	my @dels;
	my (@proh, @over);
	foreach my $from (keys %$pu) {
		my $pv = $$pu{$from};
		foreach my $to (keys %$pv) {
			my $pw = $$pv{$to};
			foreach my $role (keys %$pw) {
				my $px = $$pw{$role};
				foreach my $pref (keys %$px) {
					my $py = $$px{$pref};
					foreach my $ord (keys %$py) {
						if ($$py{$ord}{'use'} eq 'prohibited') {
							push @proh, @{$$py{$ord}{'idx'}};
						}
						else {
							my $pz = $$py{$ord}{'idx'};
							if (@$pz > 1 && $type ne 'lab') {
								push @over, @$pz[1..$#$pz];
							}
						}
					}
				}
			}
		}
	}
	return (\@proh, \@over);
}

sub set_labels() {
	my ($self) = @_;
	my $all_arcs = $self->lab();
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
			push @{$$self{'labels'}}, $xbrllabel;
		}
	}
}


sub discard_prohibiteds {
	my ($self, $trees, $type, $uri) = @_;
	my @ret;
	foreach my $tree (@$trees) {
		my $id_short = $tree->id_short();
		if (grep {/^${id_short}$/} @{$$self{'prohibiteds'}{$type}{$uri}}) {
			next;
		}
		push @ret, $tree;
	}
	return @ret;
}



=head1 XBRL::JPFR::Taxonomy

XBRL::JPFR::Taxonomy - OO Module for Parsing XBRL::JPFR Taxonomies

=head1 SYNOPSIS

  use XBRL::JPFR::Taxonomy;

  my $taxonomy = XBRL::JPFR::Taxonomy->new( {main_schema => $schema} );

=head1 DESCRIPTION

This module is part of the XBRL::JPFR modules group and is intended for use with XBRL::JPFR.

=over 4

=item new

	my $taxonomy = XBRL::JPFR::Taxonomy->new( { main_schema => <schema object here> })

=back

=head1 AUTHOR

Mark Gannon <mark@truenorth.nu>

=head1 MODIFIER

Tetsuya Yamamoto <yonjouhan@gmail.com>

=head1 SEE ALSO

Modules: XBRL XBRL::JPFR XBRL::Taxonomy

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Mark Gannon

Copyright (C) 2015 by Tetsuya Yamamoto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.


=cut


1;

