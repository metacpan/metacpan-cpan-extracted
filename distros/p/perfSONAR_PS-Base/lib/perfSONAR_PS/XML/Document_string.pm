package perfSONAR_PS::XML::Document_string;

=head1 NAME

perfSONAR_PS::XML::Document_string - This module is used to provide a more
abstract method for constructing XML documents that can be implemented using
string construction, outputting to a file or even DOM construction without
tying the code creating the XML to any particular construction method..

=cut

use strict;
use warnings;
use Log::Log4perl qw(get_logger :nowarn);
use Params::Validate qw(:all);
use perfSONAR_PS::ParameterValidation;

our $VERSION = 0.09;

use fields 'OPEN_TAGS', 'DEFINED_PREFIXES', 'STRING';

my $pretty_print = 0;

=head2 new ($package)
    Allocate a new XML Document
=cut
sub new {
	my ($package) = @_;

	my $self = fields::new($package);

	$self->{OPEN_TAGS} = ();
	$self->{DEFINED_PREFIXES} = ();
	$self->{STRING} = "";

	return $self;
}

=head2 getNormalizedURI ($uri)
    This function ensures the URI has no whitespace and ends in a '/'.
=cut
sub getNormalizedURI {
	my ($uri) = @_;

	# trim whitespace
	$uri =~ s/^\s+//;
	$uri =~ s/\s+$//;

	if ($uri =~ /[^\/]$/) {
		$uri .= "/";
	}

	return $uri;
}

=head2 startElement ($self, { prefix, namespace, tag, attributes, extra_namespaces, content })
    This function starts a new element 'tag' with the prefix 'prefix' and
    namespace 'namespace'. Those elements are the only ones that are required.
    The attributes parameter can point at a hash whose keys will become
    attributes of the element with the value of the attribute being the value
    corresponding to that key in the hash. The extra_namespaces parameter can
    be specified to add namespace declarations to this element. The keys of the
    hash will be the new prefixes and the values those keys point to will be
    the new namespace URIs. The content parameter can be specified to give the
    content of the element in which case more elements can still be added, but
    initally the content will be added. Once started, the element must be
    closed before the document can be retrieved. This function returns -1 if an
    error occurs and 0 if the element was successfully created.
=cut
sub startElement {
	#my ($self, @params) = shift;
    my $self = shift;
	my $args = validateParams(@_, 
			{
				prefix => { type => SCALAR, regex => qr/^[a-z0-9]/ },
				namespace => { type => SCALAR, regex => qr/^http/ },
				tag => { type => SCALAR, regex => qr/^[a-z0-9]/ },
				attributes => { type => HASHREF | UNDEF, optional => 1 },
				extra_namespaces => { type => HASHREF | UNDEF, optional => 1 },
				content => { type => SCALAR | UNDEF, optional => 1}
			});

	my $logger = get_logger("perfSONAR_PS::XML::Document_string");

	my $prefix = $args->{"prefix"};
	my $namespace = $args->{"namespace"};
	my $tag = $args->{"tag"};
	my $attributes = $args->{"attributes"};
	my $extra_namespaces = $args->{"extra_namespaces"};
	my $content = $args->{"content"};

	$logger->debug("Starting tag: $tag");

	$namespace = getNormalizedURI($namespace);

	my %namespaces = ();
	$namespaces{$prefix} = $namespace;

	if (defined $extra_namespaces and $extra_namespaces ne "") {
		foreach my $curr_prefix (keys %{ $extra_namespaces }) {
			my $new_namespace = getNormalizedURI($extra_namespaces->{$curr_prefix});

			if (defined $namespaces{$curr_prefix} and $namespaces{$curr_prefix} ne $new_namespace) {
				$logger->error("Tried to redefine prefix $curr_prefix from ".$namespaces{$curr_prefix}." to ".$new_namespace);
				return -1;
			}

			$namespaces{$curr_prefix} = $new_namespace;
		}
	}

	my %node_info = ();
	$node_info{"tag"} = $tag;
	$node_info{"prefix"} = $prefix;
	$node_info{"namespace"} = $namespace;
	$node_info{"defined_prefixes"} = ();

	if ($pretty_print) {
		foreach my $node (@{ $self->{OPEN_TAGS} }) {
			$self->{STRING} .= "  ";
		}
	}

	$self->{STRING} .= "<$prefix:$tag";

	foreach my $prefix (keys %namespaces) {
		my $require_defintion = 0;

		if (not defined $self->{DEFINED_PREFIXES}->{$prefix}) {
			# it's the first time we've seen a prefix like this
			$self->{DEFINED_PREFIXES}->{$prefix} = ();
			push @{ $self->{DEFINED_PREFIXES}->{$prefix} }, $namespaces{$prefix};
			$require_defintion = 1;
		} else {
			my @namespaces = @{ $self->{DEFINED_PREFIXES}->{$prefix} };

			# if it's a new namespace for an existing prefix, write the definition (though we should probably complain)
			if ($#namespaces == -1 or $namespaces[-1] ne $namespace) {
				push @{ $self->{DEFINED_PREFIXES}->{$prefix} }, $namespaces{$prefix};

				$require_defintion = 1;
			}
		}

		if ($require_defintion) {
			push @{ $node_info{"defined_prefixes"} }, $prefix;
			$self->{STRING} .= " xmlns:$prefix=\"".$namespaces{$prefix}."\"";
		}
	}

	if (defined $attributes) {
		for my $attr (keys %{ $attributes }) {
			$self->{STRING} .= " ".$attr."=\"".$attributes->{$attr}."\"";
		}
	}

	$self->{STRING} .= ">";

	if ($pretty_print) {
		$self->{STRING} .= "\n";
	}

	if (defined $content and $content ne "") {
		$self->{STRING} .= $content;
		$self->{STRING} .= "\n" if ($pretty_print);
	}


	push @{ $self->{OPEN_TAGS} }, \%node_info;

	return 0;
}

=head2 createElement ($self, { prefix, namespace, tag, attributes, extra_namespaces, content })
    This function has identical parameters to the startElement function.
    However, it closes the element immediately. This function returns -1 if an
    error occurs and 0 if the element was successfully created.
=cut
sub createElement {
	my $self = shift;
	my $args = validateParams(@_, 
			{
				prefix => { type => SCALAR, regex => qr/^[a-z0-9]/ },
				namespace => { type => SCALAR, regex => qr/^http/ },
				tag => { type => SCALAR, regex => qr/^[a-z0-9]/ },
				attributes => { type => HASHREF | UNDEF, optional => 1 },
				extra_namespaces => { type => HASHREF | UNDEF, optional => 1 },
				content => { type => SCALAR | UNDEF, optional => 1}
			});

	my $logger = get_logger("perfSONAR_PS::XML::Document_string");

	my $prefix = $args->{"prefix"};
	my $namespace = $args->{"namespace"};
	my $tag = $args->{"tag"};
	my $attributes = $args->{"attributes"};
	my $extra_namespaces = $args->{"extra_namespaces"};
	my $content = $args->{"content"};

	$namespace = getNormalizedURI($namespace);

	my %namespaces = ();
	$namespaces{$prefix} = $namespace;

	if (defined $extra_namespaces and $extra_namespaces ne "") {
		foreach my $curr_prefix (keys %{ $extra_namespaces }) {
			my $new_namespace = getNormalizedURI($extra_namespaces->{$curr_prefix});

			if (defined $namespaces{$curr_prefix} and $namespaces{$curr_prefix} ne $new_namespace) {
				$logger->error("Tried to redefine prefix $curr_prefix from ".$namespaces{$curr_prefix}." to ".$new_namespace);
				return -1;
			}

			$namespaces{$curr_prefix} = $new_namespace;
		}
	}

	if ($pretty_print) {
		foreach my $node (@{ $self->{OPEN_TAGS} }) {
			$self->{STRING} .= "  ";
		}
	}

	$self->{STRING} .= "<$prefix:$tag";

	foreach my $prefix (keys %namespaces) {
		my $require_defintion = 0;

		if (not defined $self->{DEFINED_PREFIXES}->{$prefix}) {
			# it's the first time we've seen a prefix like this
			$self->{DEFINED_PREFIXES}->{$prefix} = ();
			$require_defintion = 1;
		} else {
			my @namespaces = @{ $self->{DEFINED_PREFIXES}->{$prefix} };

			# if it's a new namespace for an existing prefix, write the definition (though we should probably complain)
			if ($#namespaces == -1 or $namespaces[-1] ne $namespace) {
				$require_defintion = 1;
			}
		}

		if ($require_defintion) {
			$self->{STRING} .= " xmlns:$prefix=\"".$namespaces{$prefix}."\"";
		}
	}

	if (defined $attributes) {
		for my $attr (keys %{ $attributes }) {
			$self->{STRING} .= " ".$attr."=\"".$attributes->{$attr}."\"";
		}
	}

	if (not defined $content or $content eq "") {
		$self->{STRING} .= " />";
	} else {
		$self->{STRING} .= ">";

		if ($pretty_print) {
			$self->{STRING} .= "\n" if ($content =~ /\n/);
		}

		$self->{STRING} .= $content;

		if ($pretty_print) {
			if ($content =~ /\n/) {
				$self->{STRING} .= "\n";
				foreach my $node (@{ $self->{OPEN_TAGS} }) {
					$self->{STRING} .= "  ";
				}
			}
		}

		$self->{STRING} .= "</".$prefix.":".$tag.">";
	}

	if ($pretty_print) {
		$self->{STRING} .= "\n";
	}

	return 0;
}

=head2 endElement ($self, $tag)
    This function is used to end the most recently opened element. The tag
    being closed is specified to sanity check the output. If the element is
    properly closed, 0 is returned. -1 otherwise.
=cut
sub endElement {
	my ($self, $tag) = @_;
	my $logger = get_logger("perfSONAR_PS::XML::Document_string");

	$logger->debug("Ending tag: $tag");

	my @tags = @{ $self->{OPEN_TAGS} };

    if ($#tags == -1) {
        $logger->error("Tried to close tag $tag but no current open tags");
		return -1;
	} elsif ($tags[-1]->{"tag"} ne $tag) {
        $logger->error("Tried to close tag $tag, but current open tag is \"".$tags[-1]->{"tag"}."\n");
		return -1;
	}

	foreach my $prefix (@{ $tags[-1]->{"defined_prefixes"} }) {
		pop @{ $self->{DEFINED_PREFIXES}->{$prefix} };
	}

	pop @{ $self->{OPEN_TAGS} };

	if ($pretty_print) {
		foreach my $node (@{ $self->{OPEN_TAGS} }) {
			$self->{STRING} .= "  ";
		}
	}

	$self->{STRING} .= "</".$tags[-1]->{"prefix"}.":".$tag.">";

	if ($pretty_print) {
		$self->{STRING} .= "\n";
	}

	return 0;
}

=head2 addExistingXMLElement ($self, $element)
    This function adds a LibXML element to the current document.
=cut
sub addExistingXMLElement {
	my ($self, $element) = @_;
	my $logger = get_logger("perfSONAR_PS::XML::Document_string");

    my $elm = $element->cloneNode(1);
    $elm->unbindNode();

	$self->{STRING} .= $elm->toString();

	return 0;
}

=head2 addOpaque ($self, $element)
    This function adds arbitrary data to the current document.
=cut
sub addOpaque {
	my ($self, $data) = @_;
	my $logger = get_logger("perfSONAR_PS::XML::Document_string");

	$self->{STRING} .= $data;

	return 0;
}

=head2 getValue ($self)
    This function returns the current state of the document. It will warn if
    there are open tags still.
=cut
sub getValue {
	my ($self) = @_;
	my $logger = get_logger("perfSONAR_PS::XML::Document_string");

	if (defined $self->{OPEN_TAGS}) {
		my @open_tags = @{ $self->{OPEN_TAGS} };

		if (scalar(@open_tags) != 0) {
			my $msg = "Open tags still exist: ";

			for(my $x = $#open_tags; $x >= 0; $x--) {
				$msg .= " -> ".$open_tags[$x]->{tag};
			}

			$logger->warn($msg);
		}
	}

	$logger->debug("Construction Results: ".$self->{STRING});

	return $self->{STRING};
}

1;

__END__

=head1 SEE ALSO

L<Log::Log4perl>, L<Params::Validate>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id: perfSONARBOUY.pm 1059 2008-03-07 02:30:34Z zurawski $

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
