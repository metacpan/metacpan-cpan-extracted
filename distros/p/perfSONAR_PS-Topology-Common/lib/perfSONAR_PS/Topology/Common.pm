package perfSONAR_PS::Topology::Common;

use strict;
use warnings;
use Log::Log4perl qw(get_logger :levels);
use base 'Exporter';

use perfSONAR_PS::Topology::ID;
use perfSONAR_PS::Common;

our $VERSION = 0.09;

our @EXPORT = ('topologyNormalize', 'validateDomain', 'validateNode', 'validatePort', 'validateLink', 'domainReplaceChild', 'nodeReplaceChild', 'portReplaceChild', 'getTopologyNamespaces', 'mergeNodes_general');

my %topology_namespaces = (
        ctrlplane => "http://ogf.org/schema/network/topology/ctrlPlane/20070828/",
        ethernet => "http://ogf.org/schema/network/topology/ethernet/20070828/",
        ipv4 => "http://ogf.org/schema/network/topology/ipv4/20070828/",
        ipv6 => "http://ogf.org/schema/network/topology/ipv6/20070828/",
        nmtb => "http://ogf.org/schema/network/topology/base/20070828/",
        nmtl2 => "http://ogf.org/schema/network/topology/l2/20070828/",
        nmtl3 => "http://ogf.org/schema/network/topology/l3/20070828/",
        nmtl4 => "http://ogf.org/schema/network/topology/l4/20070828/",
        nmtopo => "http://ogf.org/schema/network/topology/base/20070828/",
        sonet => "http://ogf.org/schema/network/topology/sonet/20070828/",
        transport => "http://ogf.org/schema/network/topology/transport/20070828/",
        );

sub getTopologyNamespaces {
    return %topology_namespaces;
}

sub replaceChild {
    my ($parent, $type, $new_child, $fqid) = @_;
    my $logger = get_logger("perfSONAR_PS::Topology::Common");

    foreach my $child ($parent->getChildrenByTagNameNS("*", $type)) {
        my $id = $child->getAttribute($type."IdRef"); 
        next if (not defined $id or $id eq "");

        $logger->debug("comparing $id to $fqid");
        if ($id eq $fqid) {
            $parent->removeChild($child);
        }
    }

    $parent->addChild($new_child);

    return;
}

sub topologyNormalize_links {
    my ($root, $topology, $uri, $top_level) = @_;
    my $logger = get_logger("perfSONAR_PS::Topology::Common");

    $logger->debug("Normalizing links");

    my $find_res;

    $find_res = find($root, "./*[local-name()='domain']", 0);
    if ($find_res) {
        foreach my $domain ($find_res->get_nodelist) {
            my $id = $domain->getAttribute("id");

            my ($status, $res) = topologyNormalize_links($domain, $topology, $id, $top_level);
            if ($status != 0) {
                return ($status, $res);
            }
        }
    }

    $find_res = find($root, "./*[local-name()='node']", 0);
    if ($find_res) {
        foreach my $node ($find_res->get_nodelist) {
            my $id = $node->getAttribute("id");

            my ($status, $res) = topologyNormalize_links($node, $topology, $id, $top_level);
            if ($status != 0) {
                return ($status, $res);
            }
        }
    }

    $find_res = find($root, "./*[local-name()='port']", 0);
    if ($find_res) {
        foreach my $port ($find_res->get_nodelist) {
            my $id = $port->getAttribute("id");

            my ($status, $res) = topologyNormalize_links($port, $topology, $id, $top_level);
            if ($status != 0) {
                return ($status, $res);
            }
        }
    }

    $find_res = find($root, "./*[local-name()='link']", 0);
    if ($find_res) {
        foreach my $link ($find_res->get_nodelist) {
            my $id = $link->getAttribute("id");
            my $type = $link->getAttribute("type");
            my $fqid;

            $logger->debug("Handling link $id");

            if (not defined $id) {
                if (not defined $link->getAttribute("link") and defined $link->getAttribute("linkIdRef")) {
                    $logger->debug("Link appears to be a pointer, skipping");
                    next;
                } else {
                    my $msg = "Link has no id";
                    $logger->error($msg);
                    return (-1, $msg);
                }
            }

            if (not defined $type or $type eq "") {
                $type = "unidirectional";
                $link->setAttribute("type", $type);
            }

            if ($type ne "unidirectional" and $type ne "bidirectional") {
                my $msg = "Link $id has an invalid type: $type";
                $logger->error($msg);
                return (-1, $msg);
            }

            my $n = idIsFQ($id, "link");
            if ($n == -1) {
                my $msg = "Link $id has an invalid fully-qualified id";
                $logger->error($msg);
                return (-1, $msg);
            } elsif ($n == 0) {
                $logger->debug("$id not qualified: ".$root->localname."");

                if ($root->localname eq "port" and $type eq "bidirectional") {
                    my $msg = "Link $id is bidirectional, but is not fully qualified and is located beneath a port";
                    $logger->error($msg);
                    return (-1, $msg);
                } elsif ($root->localname eq "domain" and $type eq "unidirectional") {
                    my $msg = "Link $id is unidirectional, but is not fully qualified and is located beneath a domain";
                    $logger->error($msg);
                    return (-1, $msg);
                } elsif ($root->localname ne "domain" and $root->localname ne "port") {
                    my $msg = "Link $id is not fully qualified, but is located beneath something that is not a port or a domain";
                    $logger->error($msg);
                    return (-1, $msg);
                }

                my $parent_id = $root->getAttribute("id");
                $fqid = idAddLevel($parent_id, "link", $id);
                $link->setAttribute("id", $fqid);
            } else {
                my $type;

                $fqid = $id;

                my $parent_id = idRemoveLevel($fqid, \$type);
                my $parent;

                if ($type eq "domain") {
                    $parent = $topology->{"domains"}->{$parent_id};
                } elsif ($type eq "port") {
                    $parent = $topology->{"ports"}->{$parent_id};
                } else {
                    my $msg = "Link $id has an invalid parent type: $type";
                    $logger->error($msg);
                    return (-1, $msg);
                }

                if (not defined $parent) {
                    my $msg = "Link $fqid references non-existent element $parent_id, moving to top-level";
                    $logger->debug($msg);

# move it to the top level
                    $root->removeChild($link);
                    $top_level->appendChild($link);
                } else {
                    my $msg = "Moving link $fqid under element $parent_id";
                    $logger->debug($msg);

# remove the link from $root and add it to the parent
                    $root->removeChild($link);
                    replaceChild($parent, $type, $link, $fqid);
                }

                $logger->debug("Adding $fqid");
            }

            $topology->{"links"}->{$fqid} = $link;
            $link->setAttribute("id", $fqid);
        }
    }

    return (0, "");
}

sub topologyNormalize_ports {
    my ($root, $topology, $uri, $top_level) = @_;
    my $logger = get_logger("perfSONAR_PS::Topology::Common");

    $logger->debug("Normalizing ports");

    my $find_res;

    $find_res = find($root, "./*[local-name()='domain']", 0);
    if ($find_res) {
        foreach my $domain ($find_res->get_nodelist) {
            my $fqid = $domain->getAttribute("id");

            my ($status, $res) = topologyNormalize_ports($domain, $topology, $fqid, $top_level);
            if ($status != 0) {
                return ($status, $res);
            }
        }
    }

    $find_res = find($root, "./*[local-name()='node']", 0);
    if ($find_res) {
        foreach my $node ($find_res->get_nodelist) {
            my $fqid = $node->getAttribute("id");

            my ($status, $res) = topologyNormalize_ports($node, $topology, $fqid, $top_level);
            if ($status != 0) {
                return ($status, $res);
            }
        }
    }

    $find_res = find($root, "./*[local-name()='port']", 0);
    if ($find_res) {
        foreach my $port ($find_res->get_nodelist) {
            my $id = $port->getAttribute("id");
            my $fqid;

            if (not defined $id) {
                if (defined $port->getAttribute("portIdRef")) {
                    next;
                } else {
                    my $msg = "Port has no id";
                    $logger->error($msg);
                    return (-1, $msg);
                }
            }

            my $n = idIsFQ($id, "port");
            if ($n == 0) {
                if ($uri eq "") {
                    my $msg = "Port $id has no parent and is not fully qualified";
                    $logger->error($msg);
                    return (-1, $msg);
                }

                if ($root->localname ne "node") {
                    my $msg = "Port $id is contained in something that is not a node: ".$root->localname;
                    $logger->error($msg);
                    return (-1, $msg);
                }

                $fqid = idAddLevel($uri, "port", $id);
            } elsif ($n == -1) {
                my $msg = "Port $id has an invalid fully-qualified id";
                $logger->error($msg);
                return (-1, $msg);
            } else {
                $fqid = $id;

                my $node_id = idRemoveLevel($fqid, "");
                my $node = $topology->{"nodes"}->{$node_id};

                if (not defined $node) {
# move it to the top level
                    $root->removeChild($port);
                    $top_level->appendChild($port);
                } else {
# remove the port from $root and add it to the node
                    $root->removeChild($port);
                    replaceChild($node, "node", $port, $fqid);
                }
            }

            $logger->debug("Adding $fqid");
            $topology->{"ports"}->{$fqid} = $port;
            $port->setAttribute("id", $fqid);
        }
    }

    return (0, "");
}

sub topologyNormalize_nodes {
    my ($root, $topology, $uri, $top_level) = @_;
    my $logger = get_logger("perfSONAR_PS::Topology::Common");

    $logger->debug("Normalizing nodes");

    my $find_res;

    $find_res = find($root, "./*[local-name()='domain']", 0);
    if ($find_res) {
        foreach my $domain ($find_res->get_nodelist) {
            my $fqid = $domain->getAttribute("id");

            my ($status, $res) = topologyNormalize_nodes($domain, $topology, $fqid, $top_level);
            if ($status != 0) {
                return ($status, $res);
            }
        }
    }

    $find_res = find($root, "./*[local-name()='node']", 0);
    if ($find_res) {
        foreach my $node ($find_res->get_nodelist) {
            my $id = $node->getAttribute("id");
            my $fqid;

            if (not defined $id) {
                if (defined $node->getAttribute("nodeIdRef")) {
                    next;
                } else {
                    my $msg = "Node has no id";
                    $logger->error($msg);
                    return (-1, $msg);
                }
            }

            $logger->debug("Found node: $id");

            my $n = idIsFQ($id, "node");
            if ($n == 0) {
                if ($uri eq "") {
                    my $msg = "Node $id has no parent and is not fully qualified";
                    $logger->error($msg);
                    return (-1, $msg);
                }

                if ($root->localname ne "domain") {
                    my $msg = "Node $id is contained in something that is not a domain: ".$root->localname;
                    $logger->error($msg);
                    return (-1, $msg);
                }

                $fqid = idAddLevel($uri, "node", $id);
            } elsif ($n == -1) {
                my $msg = "Node $id has an invalid fully-qualified id";
                $logger->error($msg);
                return (-1, $msg);
            } else {
                $fqid = $id;

                my $domain_id = idRemoveLevel($fqid, "");
                my $domain = $topology->{"domains"}->{$domain_id};

                if (not defined $domain) {
                    my $msg = "Node $fqid references non-existent domain $domain_id, moving to top-level";
                    $logger->debug($msg);

                    $root->removeChild($node);
                    $top_level->appendChild($node);
                } else {
                    $logger->debug("Moving $fqid to $domain_id");

# remove the node from $root and add it to the domain
                    $root->removeChild($node);
                    replaceChild($domain, "domain", $node, $fqid);

                    $logger->debug("Done moving $fqid to $domain_id");
                }
            }

            $node->setAttribute("id", $fqid);
            $logger->debug("Adding $fqid");
            $topology->{"nodes"}->{$fqid} = $node;
        }
    }

    return (0, "");
}

sub topologyNormalize_paths {
    my ($root, $topology, $uri, $top_level) = @_;
    my $logger = get_logger("perfSONAR_PS::Topology::Common");

    $logger->debug("Normalizing paths");

    my $find_res;

    $find_res = find($root, "./*[local-name()='domain']", 0);
    if ($find_res) {
        foreach my $domain ($find_res->get_nodelist) {
            my $fqid = $domain->getAttribute("id");
            $logger->debug("Found domain: $fqid");
            my ($status, $res) = topologyNormalize_paths($domain, $topology, $fqid, $top_level);
            if ($status != 0) {
                return ($status, $res);
            }
        }
    }

    $find_res = find($root, "./*[local-name()='path']", 0);
    if ($find_res) {
        foreach my $path ($find_res->get_nodelist) {
            my $id = $path->getAttribute("id");
            my $fqid;

            if (not defined $id) {
                if (defined $path->getAttribute("pathIdRef")) {
                    next;
                } else {
                    my $msg = "Path has no id";
                    $logger->error($msg);
                    return (-1, $msg);
                }
            }

            $logger->debug("Found path: $id");

            my $n = idIsFQ($id, "path");
            if ($n == 0) {
                if ($uri eq "") {
                    my $msg = "Path $id has no parent and is not fully qualified";
                    $logger->error($msg);
                    return (-1, $msg);
                }

                if ($root->localname ne "domain") {
                    my $msg = "Path $id is contained in something that is not a domain: ".$root->localname;
                    $logger->error($msg);
                    return (-1, $msg);
                }

                $fqid = idAddLevel($uri, "path", $id);
            } elsif ($n == -1) {
                my $msg = "Path $id has an invalid fully-qualified id";
                $logger->error($msg);
                return (-1, $msg);
            } else {
                $fqid = $id;

                my $domain_id = idRemoveLevel($fqid, "");
                my $domain = $topology->{"domains"}->{$domain_id};
                if ($domain_id eq "" or not defined $domain) {
                    if ($domain_id ne "") {
                        my $msg = "Path $fqid references non-existent domain $domain_id, moving to top-level";
                        $logger->debug($msg);
                    }

                    if ($root != $top_level) {
                        $root->removeChild($path);
                        $top_level->appendChild($path);
                    }
                } else {
                    $logger->debug("Moving $fqid to $domain_id");

# remove the path from $root and add it to the domain
                    $root->removeChild($path);
                    replaceChild($domain, "domain", $path, $fqid);
                }
            }

            $path->setAttribute("id", $fqid);
            $logger->debug("Adding $fqid");
            $topology->{"paths"}->{$fqid} = $path;
        }
    }

    return (0, "");
}

sub topologyNormalize_networks {
    my ($root, $topology, $uri, $top_level) = @_;
    my $logger = get_logger("perfSONAR_PS::Topology::Common");

    $logger->debug("Normalizing networks");

    my $find_res;

    $find_res = find($root, "./*[local-name()='domain']", 0);
    if ($find_res) {
        foreach my $domain ($find_res->get_nodelist) {
            my $fqid = $domain->getAttribute("id");
            $logger->debug("Found domain: $fqid");
            my ($status, $res) = topologyNormalize_networks($domain, $topology, $fqid, $top_level);
            if ($status != 0) {
                return ($status, $res);
            }
        }
    }

    $find_res = find($root, "./*[local-name()='network']", 0);
    if ($find_res) {
        foreach my $network ($find_res->get_nodelist) {
            my $id = $network->getAttribute("id");
            my $fqid;

            if (not defined $id) {
                if (defined $network->getAttribute("networkIdRef")) {
                    next;
                } else {
                    my $msg = "Network has no id";
                    $logger->error($msg);
                    return (-1, $msg);
                }
            }

            $logger->debug("Found network: $id");

            my $n = idIsFQ($id, "network");
            if ($n == 0) {
                if ($uri eq "") {
                    my $msg = "Network $id has no parent and is not fully qualified";
                    $logger->error($msg);
                    return (-1, $msg);
                }

                if ($root->localname ne "domain") {
                    my $msg = "Network $id is contained in something that is not a domain: ".$root->localname;
                    $logger->error($msg);
                    return (-1, $msg);
                }

                $fqid = idAddLevel($uri, "network", $id);
            } elsif ($n == -1) {
                my $msg = "Network $id has an invalid fully-qualified id";
                $logger->error($msg);
                return (-1, $msg);
            } else {
                $fqid = $id;

                my $domain_id = idRemoveLevel($fqid, "");
                my $domain = $topology->{"domains"}->{$domain_id};
                if ($domain_id eq "" or not defined $domain) {
                    if ($domain_id ne "") {
                        my $msg = "Network $fqid references non-existent domain $domain_id, moving to top-level";
                        $logger->debug($msg);
                    }

                    if ($root != $top_level) {
                        $root->removeChild($network);
                        $top_level->appendChild($network);
                    }
                } else {
                    $logger->debug("Moving $fqid to $domain_id");

# remove the network from $root and add it to the domain
                    $root->removeChild($network);
                    replaceChild($domain, "domain", $network, $fqid);
                }
            }

            $network->setAttribute("id", $fqid);
            $logger->debug("Adding $fqid");
            $topology->{"networks"}->{$fqid} = $network;
        }
    }

    return (0, "");
}

sub topologyNormalize_domains {
    my ($root, $topology) = @_;
    my $logger = get_logger("perfSONAR_PS::Topology::Common");

    $logger->debug("Normalizing domains");

    my $find_res;

    $find_res = find($root, "./*[local-name()='domain']", 0);
    if ($find_res) {
        foreach my $domain ($find_res->get_nodelist) {
            my $id = $domain->getAttribute("id");
            my $fqid;

            if (not defined $id) {
                my $msg = "No id for specified domain";
                $logger->error($msg);
                return (-1, $msg);
            }

            my $n = idIsFQ($id, "domain");
            if ($n == -1) {
                my $msg = "Domain $id has an invalid fully-qualified id";
                $logger->error($msg);
                return (-1, $msg);
            } elsif ($n == 0) {
                $id = idConstruct("domain", $id, "", "", "", "", "", "");

                $domain->setAttribute("id", $id);
            }

            $logger->debug("Adding $id");

            $topology->{"domains"}->{$id} = $domain;
        }
    }

    return (0, "");
}

sub topologyNormalize {
    my ($root) = @_;
    my $logger = get_logger("perfSONAR_PS::Topology::Common");

    $logger->debug("Normalizing topology");

    my %ns = ();

    reMap(\%ns, \%topology_namespaces, $root, 1);

    my %topology = ();
    $topology{"domains"} = ();
    $topology{"paths"} = ();
    $topology{"networks"} = ();
    $topology{"nodes"} = ();
    $topology{"ports"} = ();
    $topology{"links"} = ();

    my ($status, $res);

    ($status, $res) = topologyNormalize_domains($root, \%topology);
    if ($status != 0) {
        return ($status, $res);
    }

    ($status, $res) = topologyNormalize_paths($root, \%topology, "", $root);
    if ($status != 0) {
        return ($status, $res);
    }

    ($status, $res) = topologyNormalize_networks($root, \%topology, "", $root);
    if ($status != 0) {
        return ($status, $res);
    }

    ($status, $res) = topologyNormalize_nodes($root, \%topology, "", $root);
    if ($status != 0) {
        return ($status, $res);
    }

    ($status, $res) = topologyNormalize_ports($root, \%topology, "", $root);
    if ($status != 0) {
        return ($status, $res);
    }

    ($status, $res) = topologyNormalize_links($root, \%topology, "", $root);
    if ($status != 0) {
        return ($status, $res);
    }

    return (0, "");
}

sub validateDomain {
    my ($domain, $domain_ids) = @_;
    my $logger = get_logger("perfSONAR_PS::Topology::Common");

    $logger->debug("Validating domain");

    my $id = $domain->getAttribute("id");
    if (not defined $id or $id eq "") {
        my $msg = "Domain has no id";
        $logger->error($msg);
        return (-1, $msg);
    }

    if (idIsFQ($id, "domain") != 1) {
        my $msg = "Domain has non-properly qualified id: $id";
        $logger->error($msg);
        return (-1, $msg);
    }

    if (defined $domain_ids->{$id}) {
        my $msg = "There exist multiple domains with the same id: $id";
        $logger->error($msg);
        return (-1, $msg);
    }

    $domain_ids->{$id} = "";

    my %node_ids = ();
    my $find_res;

    $find_res = find($domain, "./*[local-name()='node']", 0);
    if ($find_res) {
        foreach my $node ($find_res->get_nodelist) {
            my ($status, $res) = validateNode($node, \%node_ids, $id);
            if ($status != 0) {
                return ($status, $res);
            }
        }
    }

    foreach my $other_domain($domain->getChildrenByTagNameNS("*", "domain")) {
        my $msg = "Found domain with domain in it";
        $logger->error($msg);
        return (-1, $msg);
    }

    $find_res = find($domain, "./*[local-name()='link']", 0);
    if ($find_res) {
        foreach my $link ($find_res->get_nodelist) {
            my $type = $link->getAttribute("type");

            if (not defined $type or $type eq "unidirectional") {
                my $msg = "Found domain with unidirectional link in it";
                $logger->error($msg);
                return (-1, $msg);
            }
        }
    }

    return (0, "");
}

sub validateNode {
    my ($node, $node_ids, $parent_id) = @_;
    my $logger = get_logger("perfSONAR_PS::Topology::Common");

    $logger->debug("Validating node");

    my $id = $node->getAttribute("id");
    if (not defined $id or $id eq "") {
        my $msg = "Node has no id";
        $logger->error($msg);
        return (-1, $msg);
    }

    if (idIsFQ($id, "node") != 1) {
        my $msg = "Node has non-properly qualified id: $id";
        $logger->error($msg);
        return (-1, $msg);
    }

    if ($parent_id ne "") {
        my ($status, $res) = idCompare($parent_id, $id, "domain");
        if ($status != 0) {
            my $msg = "Node $id does not belong in domain $parent_id: $res";
            return (-1, $msg);
        }
    }

    if (defined $node_ids->{$id}) {
        my $msg = "There exist multiple nodes with the same id: $id";
        $logger->error($msg);
        return (-1, $msg);
    }

    $node_ids->{$id} = "";

    my %port_ids = ();

    my $find_res;

    $find_res = find($node, "./*[local-name()='port']", 0);
    if ($find_res) {
        foreach my $port ($find_res->get_nodelist) {
            my ($status, $res) = validatePort($port, \%port_ids, $id);
            if ($status != 0) {
                return ($status, $res);
            }
        }
    }

    $find_res = find($node, "./*[local-name()='node']", 0);
    if ($find_res) {
        foreach my $other_node ($find_res->get_nodelist) {
            my $msg = "Found node with node in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $find_res = find($node, "./*[local-name()='link']", 0);
    if ($find_res) {
        foreach my $link ($find_res->get_nodelist) {
            my $msg = "Found node with link in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $find_res = find($node, "./*[local-name()='path']", 0);
    if ($find_res) {
        foreach my $path ($find_res->get_nodelist) {
            my $msg = "Found node with path in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $find_res = find($node, "./*[local-name()='network']", 0);
    if ($find_res) {
        foreach my $network ($find_res->get_nodelist) {
            my $msg = "Found node with network in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $find_res = find($node, "./*[local-name()='domain']", 0);
    if ($find_res) {
        foreach my $domain ($find_res->get_nodelist) {
            my $msg = "Found node with domain in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    return (0, "");
}

sub validatePort {
    my ($port, $port_ids, $parent_id) = @_;
    my $logger = get_logger("perfSONAR_PS::Topology::Common");

    $logger->debug("Validating port");

    my $id = $port->getAttribute("id");
    if (not defined $id or $id eq "") {
        my $msg = "Port has no id";
        $logger->error($msg);
        return (-1, $msg);
    }

    if (idIsFQ($id, "port") != 1) {
        my $msg = "Port has non-properly qualified id: $id";
        $logger->error($msg);
        return (-1, $msg);
    }

    if ($parent_id ne "") {
        my ($status, $res) = idCompare($parent_id, $id, "node");
        if ($status != 0) {
            my $msg = "Port $id does not belong in node $parent_id: $res";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    if (defined $port_ids->{$id}) {
        my $msg = "There exist multiple ports with the same id: $id";
        $logger->error($msg);
        return (-1, $msg);
    }

    $port_ids->{$id} = "";

    my %link_ids = ();

    my $find_res;

    $find_res = find($port, "./*[local-name()='link']", 0);
    if ($find_res) {
        foreach my $link ($find_res->get_nodelist) {
            my ($status, $res) = validateLink($link, \%link_ids, $id);
            if ($status != 0) {
                return ($status, $res);
            }
        }
    }

    $find_res = find($port, "./*[local-name()='port']", 0);
    if ($find_res) {
        foreach my $other_port ($find_res->get_nodelist) {
            my $msg = "Found port with port in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $find_res = find($port, "./*[local-name()='node']", 0);
    if ($find_res) {
        foreach my $node ($find_res->get_nodelist) {
            my $msg = "Found port with node in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $find_res = find($port, "./*[local-name()='path']", 0);
    if ($find_res) {
        foreach my $path ($find_res->get_nodelist) {
            my $msg = "Found port with path in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $find_res = find($port, "./*[local-name()='network']", 0);
    if ($find_res) {
        foreach my $network ($find_res->get_nodelist) {
            my $msg = "Found port with network in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $find_res = find($port, "./*[local-name()='domain']", 0);
    if ($find_res) {
        foreach my $domain ($find_res->get_nodelist) {
            my $msg = "Found port with domain in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    return (0, "");
}

sub validateLink {
    my ($link, $link_ids, $parent_id) = @_;
    my $logger = get_logger("perfSONAR_PS::Topology::Common");

    $logger->debug("Validating link");

    my $id = $link->getAttribute("id");
    if (not defined $id or $id eq "") {
        my $msg = "Link has no id";
        $logger->error($msg);
        return (-1, $msg);
    }

    if (idIsFQ($id, "link") != 1) {
        my $msg = "Link has non-properly qualified id: $id";
        $logger->error($msg);
        return (-1, $msg);
    }

    if ($parent_id ne "") {
        my ($status, $res) = idCompare($parent_id, $id, "port");
        if ($status != 0) {
            my $msg = "Link $id does not belong in port $parent_id: $res";
            return (-1, $msg);
        }
    }

    if (defined $link_ids->{$id}) {
        my $msg = "There exist multiple links with the same id: $id";
        $logger->error($msg);
        return (-1, $msg);
    }

    $link_ids->{$id} = "";

    my $find_res;

    $find_res = find($link, "./*[local-name()='link']", 0);
    if ($find_res) {
        foreach my $other_link ($find_res->get_nodelist) {
            my $msg = "Found link with link in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $find_res = find($link, "./*[local-name()='node']", 0);
    if ($find_res) {
        foreach my $node ($find_res->get_nodelist) {
            my $msg = "Found link with node in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $find_res = find($link, "./*[local-name()='path']", 0);
    if ($find_res) {
        foreach my $path ($find_res->get_nodelist) {
            my $msg = "Found link with path in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $find_res = find($link, "./*[local-name()='network']", 0);
    if ($find_res) {
        foreach my $network ($find_res->get_nodelist) {
            my $msg = "Found link with network in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $find_res = find($link, "./*[local-name()='domain']", 0);
    if ($find_res) {
        foreach my $domain ($find_res->get_nodelist) {
            my $msg = "Found link with domain in it";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    return (0, "");
}

1;

__END__
=head1 NAME

perfSONAR_PS::Topology::Common - A module that provides various utility functions for Topology structures.

=head1 DESCRIPTION

This module contains a set of utility functions that are used to interact with
Topology structures.

=head1 SYNOPSIS

=head1 DETAILS

=head1 API

=head2 mergeNodes_general($old_node, $new_node, $attrs)

    Takes two LibXML nodes containing structures and merges them together.
    The $attrs variable is a pointer to a hash describing which attributes
    on a node should be compared to define equality.

    To have links compared based on their 'id' attribute, you would specify $attrs as such:

    my %attrs = (
            link => ( id => '' );
            );

=head2 domainReplaceChild($domain, $new_node, $id)

    Take a domain, a node and its fqid and replaces any children that are
    "IdRef'd" to the node with the actual node.

=head2 nodeReplaceChild($node, $new_port, $id)

    Take a node, a port and its fqid and replaces any children that are
    "IdRef'd" to the port with the actual port.

=head2 portReplaceChild($port, $new_link, $id)

    Take a port, a link and its fqid and replaces any children that are
    "IdRef'd" to the link with the actual link.

=head2 topologyNormalize($topology)

    Takes a topology structure and normalizes it into
    "domain/node/port/link" format. If a stray node/port/link is found, it
    is moved up to the top-level if it's not already there.

=head2 getTopologyNamespaces()

    Returns the set of prefix/uri mappings for Topology in a hash table.

=head2 validateDomain($domain, $domain_ids)

    Does some basic validation of the specified domain.$domain_ids is a
    pointer to a hash containing the set of domain ids. The function will
    add an entry for this domain to the hash. 

=head2 validateNode($node, $node_ids, $parent)

    Does some basic validation of the specified node. $node_ids is a
    pointer to a hash containing the set of node ids. The function will add
    an entry for this node to the hash. $parent is the FQ ID of the parent
    of this element. If the element has no parent, it is simply "".

=head2 validatePort($port, $port_ids, $parent)

    Does some basic validation of the specified port. $port_ids is a
    pointer to a hash containing the set of port ids. The function will add
    an entry for this port to the hash. $parent is the FQ ID of the parent
    of this element. If the element has no parent, it is simply "".

=head2 validateLink($link, $link_ids, $parent)

    Does some basic validation of the specified link. $link_ids is a
    pointer to a hash containing the set of link ids. The function will add
    an entry for this link to the hash. $parent is the FQ ID of the parent of this
    element. If the element has no parent, it is simply "".

    =head1 SEE ALSO

    To join the 'perfSONAR-PS' mailing list, please visit:

    https://mail.internet2.edu/wws/info/i2-perfsonar

    The perfSONAR-PS subversion repository is located at:

    https://svn.internet2.edu/svn/perfSONAR-PS

    Questions and comments can be directed to the author, or the mailing list.

    =head1 VERSION

    $Id$

    =head1 AUTHOR

    Aaron Brown, E<lt>aaron@internet2.eduE<gt>

    =head1 LICENSE

    You should have received a copy of the Internet2 Intellectual Property Framework along
    with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

    =head1 COPYRIGHT

    Copyright (c) 2004-2007, Internet2 and the University of Delaware

    All rights reserved.

    =cut
# vim: expandtab shiftwidth=4 tabstop=4
