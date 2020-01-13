package urpm::xml_info;

use strict;
use XML::LibXML::Reader;

=head1 NAME

urpm::xml_info - XML data manipulation related routines for urpmi

=head1 SYNOPSIS

=head1 DESCRIPTION

=over

=cut 

# throw an exception on error
sub get_nodes {
    my ($xml_info, $xml_info_file, $fullnames) = @_;

    my $get_one_node = _get_one_node($xml_info);
    _get_xml_info_nodes($xml_info_file, $get_one_node, $fullnames);
}

# throw an exception on error
sub do_something_with_nodes {
    my ($xml_info, $xml_info_file, $do, $o_wanted_attributes) = @_;

    my $get_one_node = _get_one_node($xml_info, $o_wanted_attributes);
    _do_something_with_xml_info_nodes($xml_info_file, $get_one_node, $do);
}


sub open_lzma {
    my ($xml_info_file) = @_;

    $xml_info_file =~ s/'/'\\''/g;
    open(my $F, "xz -dc '$xml_info_file' |");
    $F;    
}

################################################################################
sub _open_xml_reader {
    my ($xml_info_file) = @_;

    my $reader = new XML::LibXML::Reader(IO => open_lzma($xml_info_file), huge => 1) or die "cannot read $xml_info_file\n";

    $reader->read;
    $reader->name eq 'media_info' or die "global <media_info> tag not found\n";

    $reader->read; # first tag

    $reader;
}

sub _get_all_attributes {
    my ($reader) = @_;
    my %entry;

    $reader->moveToFirstAttribute;

    do { 
	$entry{$reader->name} = $reader->value;
    } while $reader->moveToNextAttribute == 1;
    
    \%entry;
}

sub _get_attributes {
    my ($reader, $o_wanted_attributes) = @_;

    if ($o_wanted_attributes) {
	my %entry = map { $_ => $reader->getAttribute($_) } @$o_wanted_attributes;
	\%entry;
    } else {
	_get_all_attributes($reader);
    }
}

sub _get_simple_value_node {
    my ($value_name, $o_wanted_attributes) = @_;

    sub {
	my ($reader) = @_;
	my $entry = _get_attributes($reader, $o_wanted_attributes);

	$reader->read; # get value
	$entry->{$value_name} = $reader->value;
	$entry->{$value_name} =~ s/^\n//;

	$reader->read; # close tag
	$reader->read; # open next tag

	$entry;
    };
}

sub _get_changelog_node {
    my ($reader, $fn) = @_;
	
    $reader->nextElement('log'); # get first <log>

    my @changelogs;
    my $time;
    while ($time = $reader->getAttribute('time')) {
	push @changelogs, my $e = { time => $time };

	$reader->nextElement('log_name'); $reader->read;
	$e->{name} = $reader->value;

	$reader->nextElement('log_text'); $reader->read;
	$e->{text} = $reader->value;
	
	$reader->read; # </log_text>
	$reader->read; # </log>
	$reader->read; # <log>
	$reader->read if $reader->readState != 0; # there may be SIGNIFICANT_WHITESPACE between </log_text> and </log>
    }

    { fn => $fn, changelogs => \@changelogs };
}

sub _get_one_node {
    my ($xml_info, $o_wanted_attributes) = @_;

    if ($xml_info eq 'changelog') {
	\&_get_changelog_node;
    } elsif ($xml_info eq 'info') {
	_get_simple_value_node('description', $o_wanted_attributes);
    } else {
	_get_simple_value_node('files', $o_wanted_attributes);
    }
}

sub _get_xml_info_nodes {
    my ($xml_info_file, $get_node, $fullnames) = @_;

    my $fullnames_re = '^(' . join('|', map { quotemeta $_ } @$fullnames) . ')$';

    my %todo = map { $_ => 1 } @$fullnames;
    my %nodes;
    _iterate_on_nodes($xml_info_file,
		      sub {
			  my ($reader, $fn) = @_;
			  if ($fn =~ /$fullnames_re/) {
			      $nodes{$fn} = $get_node->($reader);
			      delete $todo{$fn};
			      keys(%todo) == 0;
			  } else {
			      $reader->next;
			      0;
			  }
		      });

    %todo and die "could not find " . join(', ', keys %todo) . " in $xml_info_file\n";

    %nodes;
}

sub _do_something_with_xml_info_nodes {
    my ($xml_info_file, $get_node, $do) = @_;

    _iterate_on_nodes($xml_info_file,
		      sub {
			  my ($reader, $fn) = @_;
			  my $h = $get_node->($reader, $fn); # will read until closing tag
			  $do->($h);
			  0;
		      });
}

sub _iterate_on_nodes {
    my ($xml_info_file, $do) = @_;

    my $reader = _open_xml_reader($xml_info_file);

    my $fn;
    while ($fn = $reader->getAttribute('fn')) {
	$do->($reader, $fn) and return; # $do must go to next node otherwise it loops!
    }

    $reader->readState == 3 || $reader->name eq 'media_info' 
      or die qq(missing attribute "fn" in tag ") . $reader->name . qq("\n);
}

1;


=back

=head1 COPYRIGHT

Copyright (C) 2005 MandrakeSoft SA

Copyright (C) 2005-2010 Mandriva SA

Copyright (C) 2011-2020 Mageia

=cut
