package XML::miniXQL;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use XML::miniXQL::Parser;
use XML::Parser;

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
);

$VERSION = '0.04';


sub queryXML {
	my $param = shift;
	my $xml;
	if (ref $param eq 'HASH') {
		$xml = shift;

	}
	else {
		$xml = $param;
		$param = {Style => 'List'};
	}

	my @queries = @_;

#	print "Queries:\n", join "\n", @queries;
#	print "\n\n";

	my @Requests;

	my $req = new XML::miniXQL::Parser();
	do {
		$req = new XML::miniXQL::Parser(shift @queries, $req);
		push @Requests, $req;
	} while @queries;

	my $currenttree = new XML::miniXQL::Parser();

	my $p = new XML::Parser(Style => 'Stream',
		_parseresults => {},
		_currenttree => $currenttree,
		_requests => \@Requests,
		_style => $param->{Style},
		);

	my $results;

	# Using exceptions for a more fine-grained control. Not completely necessary ATM though.
	eval {
		$results = $p->parse($xml);
#		warn "Parse returned ", @{$results}, "\n";
	};
	if ($@) {
		die $@;
	}
	else {
		return $results;
	}
}

sub StartTag {
	my $expat = shift;
	return $expat->finish() if $expat->{_done};
	my $element = shift;
#	my %attribs = %_;

#warn "Start: $element\n";
	$expat->{_currenttree}->Append($element, %_);
	my $current = $expat->{_currenttree};

#warn "Path now: ", $expat->{_currenttree}->Path, "\n";

	my $removed = 0;

	foreach (0..$#{$expat->{_requests}}) {
		next unless defined $expat->{_requests}->[$_]->Attrib;
# warn "Looking for attrib: ", $expat->{_requests}->[$_]->Attrib, "\n";
		if (defined $_{$expat->{_requests}->[$_]->Attrib}) {
			# Looking for attrib
			if ($expat->{_requests}->[$_]->isEqual($current)) {
				# We have equality!
#				print "Found\n";
				found($expat, $expat->{_requests}->[$_], $_{$expat->{_requests}->[$_]->Attrib});
				splice(@{$expat->{_requests}}, $_ - $removed, 1) unless $expat->{_requests}->[$_]->isRepeat;
				$expat->{_done} = 1 if (@{$expat->{_requests}} == 0);
				$removed++;
				# return;
			}
		}
	}
}

sub EndTag {
	my $expat = shift;
	return $expat->finish() if $expat->{_done};
# warn "End: $_\n";

	$expat->{_currenttree}->Pop();
}

sub Text {
	my $expat = shift;
	my $text = $_;

	return $expat->finish() if $expat->{_done};

	my @Requests = @{$expat->{_requests}};
	my $current = $expat->{_currenttree};
	my $removed = 0;

	foreach (0..$#Requests) {
#		print "(",$expat->current_element, ")Searching for: ",
#		$Requests[$_]->Path, ($Requests[$_]->isRepeat ? "*" : ''), "\n";
		if (!$Requests[$_]->Attrib) {
			# Not looking for an attrib
#			warn "Comparing : ", $Requests[$_]->Path, " : ", $expat->{_currenttree}->Path, "\n";
			if ($Requests[$_]->isEqual($current)) {
#				print "Found\n";
				found($expat, $Requests[$_], $text);
				splice(@{$expat->{_requests}}, $_ - $removed, 1) unless $Requests[$_]->isRepeat;
				$expat->{_done} = 1 if (@Requests == 0);
				$removed++;
				# return;
			}
		}
	}
}

sub found {
	my $expat = shift;
	my ($request, $found) = @_;

# warn "Found: ", $request->Path, " : $found\n";

	if ($request->Path =~ /\.\*/) {
		# Request path contains a regexp
		my $match = $request->Path;
		$match =~ s/\[(.*?)\]/\\\[$1\\\]/g;

#		warn "Regexp: ", $expat->{_currenttree}->Path, " =~ |$match|\n";
		$expat->{_currenttree}->Path =~ /$match/;
		if ($expat->{_style} eq 'List') {
			push @{$expat->{_parseresults}}, $&, $found;
		}
		elsif ($expat->{_style} eq 'Hash') {
			push @{$expat->{_parseresults}->{$&}}, $found;
		}
	}
	else {
		if ($expat->{_style} eq 'List') {
			push @{$expat->{_parseresults}}, $request->Path, $found;
		}
		elsif ($expat->{_style} eq 'Hash') {
			push @{$expat->{_parseresults}->{$request->Path}}, $found;
		}
	}

}

sub EndDocument {
	my $expat = shift;
	delete $expat->{_done};
	delete $expat->{_currenttree};
	delete $expat->{_requests};
	return $expat->{_parseresults};
}

1;
__END__

=head1 NAME

XML::miniXQL - Module for doing stream based XML queries

=head1 SYNOPSIS

  use XML::miniXQL;

  my $results = XML::miniXQL::queryXML({Style => 'Hash'}, $xml, @searches);

=head1 DESCRIPTION

This module provides a simplistic XQL like search engine for XML files. It only supports
a subset of XQL, because it does all it's searching on streams, not on the document as
a whole (unlike XML::XQL). For this reason, only ancestor relationships are supported,
not sibling or child relationships. XML::miniXQL also doesn't return nodes, it only returns
the value (text) found as the result of the query. As a result, you can't use this module for
node manipulation, however it's faster than XML::XQL, so it can be used on a web backend
or some such environment. Xmerge is provided as an example of usage.

The queries are passed in as an array of queries, and the results passed out as either
a simple tuple list (each alternate value is either the query or the result respectively), or
as a hash with the values being an array. See xmerge.pl as an example of the Hash style.
The List style is the default.

=head1 AUTHOR

Matt Sergeant matt@sergeant.org

=head1 SEE ALSO

perl(1).

=cut
