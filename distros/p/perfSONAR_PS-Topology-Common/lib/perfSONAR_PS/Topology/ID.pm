package perfSONAR_PS::Topology::ID;

use strict;
use warnings;
use base 'Exporter';

our $VERSION = 0.09;

our @EXPORT = ('idConstruct', 'idIsFQ', 'idAddLevel', 'idRemoveLevel', 'idBaseLevel', 'idEncode', 'idDecode', 'idSplit', 'idCompare', 'idMatch', 'idIsAmbiguous');

sub idConstruct {
    my ($type1, $field1, $type2, $field2, $type3, $field3, $type4, $field4) = @_;

    my $id = "";

    $id .= "urn:ogf:network";

    return $id if ($type1 eq "" or $field1 eq "");

    $id .= ":".$type1."=".idEncode($field1);

    return $id if ($type2 eq "" or $field2 eq "");

    $id .= ":".$type2."=".idEncode($field2);

    return $id if ($type3 eq "" or $field3 eq "");

    $id .= ":".$type3."=".idEncode($field3);

    return $id if ($type4 eq "" or $field4 eq "");

    $id .= ":".$type4."=".idEncode($field4);

    return $id;
}

sub idIsFQ {
    my ($id, $type) = @_;

    my ($new_type, $value);

    return 0 if (!($id =~ /^urn:ogf:network:(.*)$/));

    return 1 if ($type eq "");

    my @fields = split(':', $id);

    if ($type eq "domain") {
        ($new_type, $value) = split("=", $fields[3]);

        return -1 if ($new_type ne "domain" or not defined $value);

        return 1;
    } elsif ($type eq "path" or $type eq "network") {
        if ($#fields == 3) {
            ($new_type, $value) = split("=", $fields[3]);

            return -1 if ($new_type ne $type or not defined $value);

            return 1;
        } elsif ($#fields == 4) {
            ($new_type, $value) = split("=", $fields[3]);

            return -1 if ($new_type ne "domain" or not defined $value);

            ($new_type, $value) = split("=", $fields[4]);

            return -1 if ($new_type ne $type or not defined $value);

            return 1;
        } else {
            return -1;
        }
    } elsif ($type eq "node") {
        return -1 if ($#fields != 4);

        ($type, $value) = split("=", $fields[3]);

        return -1 if ($type ne "domain" or not defined $value);

        ($type, $value) = split("=", $fields[4]);

        return -1 if ($type ne "node" or not defined $value);

        return 1;
    } elsif ($type eq "port") {
        return -1 if ($#fields != 5);

        ($type, $value) = split("=", $fields[3]);

        return -1 if ($type ne "domain" or not defined $value);

        ($type, $value) = split("=", $fields[4]);

        return -1 if ($type ne "node" or not defined $value);

        ($type, $value) = split("=", $fields[5]);

        return -1 if ($type ne "port" or not defined $value);

        return 1;
    } elsif ($type eq "link") {
        if ($#fields == 4) {
            ($type, $value) = split("=", $fields[3]);

            return -1 if ($type ne "domain" or not defined $value);

            ($type, $value) = split("=", $fields[4]);

            return -1 if ($type ne "link" or not defined $value);

            return 1;
        } elsif ($#fields == 6) {
            ($type, $value) = split("=", $fields[3]);

            return -1 if ($type ne "domain" or not defined $value);

            ($type, $value) = split("=", $fields[4]);

            return -1 if ($type ne "node" or not defined $value);

            ($type, $value) = split("=", $fields[5]);

            return -1 if ($type ne "port" or not defined $value);

            ($type, $value) = split("=", $fields[6]);

            return -1 if ($type ne "link" or not defined $value);

            return 1;
        } else {
            return -1;
        }
    } else {
        return -1;
    }
}

sub idAddLevel {
    my ($id, $new_type, $new_level) = @_;

    $new_level = idEncode($new_level);

    if ($id =~ /^urn:ogf:network:$/) {
        $id .= $new_type."=".$new_level;
    } else {
        $id .= ":".$new_type."=".$new_level;
    }

    return $id;
}

sub idRemoveLevel {
    my ($id, $ret_type) = @_;

    my $ret_id;

    if ($id =~ /(^urn:ogf:network.*):[^:]+$/) {
        if ($1 eq "urn:ogf:network") {
            $ret_id = "";
        } else {
            $ret_id = $1;
        }
    } else {
        $ret_id = $id;
    }

    if (defined $ret_type and $ret_type ne "") {
        if ($ret_id ne "") {
            my $type;

            my $value = idBaseLevel($ret_id, \$type);

            $$ret_type = $type;
        } else {
            $$ret_type = "";
        }
    }

    return $ret_id;
}

sub idBaseLevel {
    my ($id, $ret_type) = @_;

    my $ret_id;

    if (!($id =~ /^urn:ogf:network/)) {
        $$ret_type = "" if (defined $ret_type and $ret_type ne "");
        return $id;
    }

    if ($id =~ /^urn:ogf:network$/) {
        $$ret_type = "" if (defined $ret_type and $ret_type ne "");
        return "";
    };

    if ($id =~ /^urn:ogf:network.*:([^:]+)$/) {
        $ret_id = $1;
    }

    my ($type, $value) = split('=', $ret_id);

    if (defined $ret_type and $ret_type ne "") {
        $$ret_type = $type;
    }

    return idDecode($value);
}

sub idEncode {
    my ($id) = @_;

    $id =~ s/%/%25/g;
    $id =~ s/:/%3A/g;
    $id =~ s/#/%23/g;
    $id =~ s/\//%2F/g;
    $id =~ s/\?/%3F/g;

    return $id;
}

sub idDecode {
    my ($id) = @_;

    $id =~ s/%3A/:/g;
    $id =~ s/%23/#/g;
    $id =~ s/%2F/\//g;
    $id =~ s/%3F/?/g;
    $id =~ s/%25/%/g;

    return $id;
}

sub idCompare {
    my ($id1, $id2, $compare_to) = @_;

    my @results_id1 = idSplit($id1, 0, 1);
    if ($results_id1[0] == -1) {
        my $msg = "ID \"$id1\" is not properly qualified";
        return (-1, $msg);
    }

    my @results_id2 = idSplit($id2, 0, 1);
    if ($results_id2[0] == -1) {
        my $msg = "ID \"$id2\" is not properly qualified";
        return (-1, $msg);
    }

    for(my $i = 2; $i <= $#results_id1; $i += 2) {
        if (not defined $results_id2[$i]) {
            return (-1, "ID element $compare_to not found");
        }

        if ($results_id1[$i] ne $results_id2[$i] or $results_id1[$i + 1] ne $results_id2[$i + 1]) {
            return (-1, $results_id1[$i]."=".$results_id1[$i + 1] . " != " . $results_id2[$i] . "=" . $results_id2[$i + 1]);
        }

        return (0, "") if ($results_id1[$i] eq $compare_to);
    }

    return (-1, "ID element $compare_to not found");
}

sub idIsAmbiguous {
    my ($id) = @_;

    return ($id =~ /(=\*:|:\*$|=\*$)/);
}

sub idMatch {
    my ($ids, $idExp) = @_;

    my @idExpFields = split(/:/, $idExp);

    my @fields = ();
    my $finished = 0;
    for(my $i = 0; $i <= $#idExpFields; $i++) {
        if ($finished) {
            return;
        }

        if ($idExpFields[$i] =~ /([^=]*)=(.*)/) {
            $fields[$i][0] = $1;
            $fields[$i][1] = $2;
        } elsif ($idExpFields[$i] eq "*") {
            $fields[$i][0] = '*';
            $finished = 1;
        }
    }

    my @matchingIds = ();
    foreach my $id (@{ $ids }) {
        my @idFields = split(/:/, $id);
        for(my $i = 3; $i <= $#idFields; $i++) {
            # if we get here, we're being asked to match a value,
            # we haven't encountered a ":*" and we've hit the end
            # of the id expression so we've got a mismatch.
            last if ($i > $#fields);

            if ($idFields[$i] =~ /([^=]*)=(.*)/) {
                # if we've hit a :* portion of the id, then the
                # rest of the id matches.
                if ($fields[$i][0] eq "*") {
                    push @matchingIds, $id;
                    last;
                }

                # if the field name of the id doesn't match the
                # field name in the id expression.
                if ($fields[$i][0] ne $1) {
                    last;
                }

                # if the expression field value isn't the 'any
                # value' and it's not what the user specified,
                # quit checking.
                if ($fields[$i][1] ne "*" and $fields[$i][1] ne $2) {
                    last;
                }

                # if we've hit the end of both sets of fields
                # and we haven't had an error, its a match.
                if ($i == $#idFields and $i == $#fields) {
                    push @matchingIds, $id;
                }
            }
        }
    }

    return \@matchingIds;
}

sub idSplit {
    my ($id, $fq, $top_down) = @_;

    if (idIsFQ($id, "") == 0) {
        my $msg = "ID \"$id\" is not fully qualified";
        return (-1, $msg);
    }

    my @fields = split(':', $id);

    if ($#fields > 6 or $#fields < 3) {
        my $msg = "ID \"$id\" has an invalid number of fields: $#fields";
        return (-1, $msg);
    }

    my ($type1, $field1);
    my ($type2, $field2);
    my ($type3, $field3);
    my ($type4, $field4);

    ($type1, $field1) = split('=', $fields[3]) if defined $fields[3];
    ($type2, $field2) = split('=', $fields[4]) if defined $fields[4];
    ($type3, $field3) = split('=', $fields[5]) if defined $fields[5];
    ($type4, $field4) = split('=', $fields[6]) if defined $fields[6];

    my $id_type;

    if (defined $type4) {
        if ($type4 eq "link") {
            $id_type = $type4;
        } else {
            my $msg = "Fourth field of ID is of unknown type \"$type4\"";
            return (-1, $msg);
        }
    } elsif (defined $type3) {
        if ($type3 eq "port") {
            $id_type = $type3;
        } else {
            my $msg = "Third field of ID is of unknown type \"$type3\"";
            return (-1, $msg);
        }
    } elsif (defined $type2) {
        if ($type2 eq "node" or $type2 eq "link" or $type2 eq "path" or $type2 eq "network") {
            $id_type = $type2;
        } else {
            my $msg = "Second field of ID is of unknown type \"$type2\"";
            return (-1, $msg);
        }
    } elsif (defined $type1) {
        if ($type1 eq "domain" or $type1 eq "path" or $type1 eq "network") {
            $id_type = $type1;
        } else {
            my $msg = "First field of ID is of unknown type \"$type1\"";
            return (-1, $msg);
        }
    } else {
        $id_type = "";
    }

    if ($fq) {
        $field1 = "urn:ogf:network:".$fields[3] if defined $fields[3];
        $field2 = $field1.":".$fields[4] if defined $fields[4];
        $field3 = $field2.":".$fields[5] if defined $fields[5];
        $field4 = $field3.":".$fields[6] if defined $fields[6];
    } else {
        $field1 = idDecode($field1) if defined $field1;
        $field2 = idDecode($field2) if defined $field2;
        $field3 = idDecode($field3) if defined $field3;
        $field4 = idDecode($field4) if defined $field4;
    }

    my @res;
    push @res, 0;
    push @res, $id_type;
    if ($top_down) {
        push @res, $type1 if defined $type1;
        push @res, $field1 if defined $field1;
        push @res, $type2 if defined $type2;
        push @res, $field2 if defined $field2;
        push @res, $type3 if defined $type3;
        push @res, $field3 if defined $field3;
        push @res, $type4 if defined $type4;
        push @res, $field4 if defined $field4;
    } else {
        push @res, $type4 if defined $type4;
        push @res, $field4 if defined $field4;
        push @res, $type3 if defined $type3;
        push @res, $field3 if defined $field3;
        push @res, $type2 if defined $type2;
        push @res, $field2 if defined $field2;
        push @res, $type1 if defined $type1;
        push @res, $field1 if defined $field1;
    }

    return @res;
}

1;

__END__
=head1 NAME

perfSONAR_PS::Topology::ID - A module that provides various utility functions for Topology IDs.

=head1 DESCRIPTION

This module contains a set of utility functions that are used to interact with
Topology IDs.

=head1 SYNOPSIS

=head1 DETAILS

=head1 API

=head2 idConstruct($type1, $field1, $type2, $field2, $type3, $field3, $type4, $field4)

    Constructs an a fully-qualified id based on the specified fields. No
    sanity checking is performed to verify that the created ID makes sense.
    The $type parameters are values like 'domain', 'node', etc whereas the
    $field parameter is the ID for that element like "I2" or "HOPI". All
    values past the first blank ("") type or field are ignored.

=head2 idIsFQ($id, $type)

    Checks if the specified ID is a fully-qualified ID of the specified
    type. If it is not a fully-qualified id, the function returns 0. If it
    is an incorrect fully-qualified id(e.g. too many elements), it returns
    -1. If it is a correctly specified fully-qualified id, it returns 1.

=head2 idAddLevel($id, $new_type, $new_level)

    Takes a fully-qualified id and adds a new level onto it. No sanity
    checking is done, it simply returns the ID created from the values
    requested.

=head2 idRemoveLevel($id, $ret_type)

    Takes a fully-qualified id and returns the parent level for the id. If
    you'd like to know the type of the parent, you can add a reference to a
    variable for $ret_type and the function will fill it in with the type
    of the returned id.

    e.g. urn:ogf:network:domain=hopi:node=losa would return
    'urn:ogf:network:domain=hopi' and $ret_type would be filled in with
    'domain'

=head2 idBaseLevel($id, $ret_type)

    Returns the base level of the specified id. If you want to be informed
    fo the type of the base element, you can add a reference to a variable
    for $ret_type and the function will fill it in with the type of the
    element.

    e.g. urn:ogf:network:domain=hopi:node=losa would return 'losa' and
    $ret_type would be filled in with 'node'

=head2 idEncode($element)

    Performs any necessary encoding of the specified element for inclusion
    in a fully-qualified id.

=head2 idDecode($element)

    Decodes the specified element from a fully-qualified id.

=head2 idCompare($id1, $id2, $compare_to)

    Compares the given ids to see if they match up to the specified field.
    $compare_to can be any ID element type that the IDs have in common. It
    returns an array containing two values. The first is either 0 or -1 and
    tells whether the function failed or succeeded. If the function failed,
    the next element in the array is the error message.

=head2 idSplit($id, $fq, $top_down)

    Splits the specified fully-qualified id into its component elements. If
    $fq is 1, the returns components are all fully-qualified. The components are returned in an array. The
    first value of the array is the 0 or -1 specifying whether the function
    succeeded or failed. The next element is a string for the type of the
    ID. Each subsequent pair of elements corresponds to the type of the
    element followed by the element itself. If $top_down is 0, the order is
    the most specific element to least specific element. If $top_down is 1,
    however, the order is reversed.

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
