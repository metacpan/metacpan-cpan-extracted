package WebService::IdoitAPI::Object;

# vim: set sw=4 ts=4 et ai si:

use warnings;
use strict;
use Carp;

use WebService::IdoitAPI;

use version; our $VERSION = qv('v0.3.1');

sub new {
    my ($class, $api, $id) = @_;
    my $self = {
        api => $api,
    };
    $self->{id} = $id if ( $id );
    bless($self, $class);
    return $self;
} # new()

sub get_data {
    my ($self,$id) = @_;

    my ($data,$obj_data);

    $obj_data = $self->get_information($id);
    $data = {
        obj => $obj_data->{obj},
    };
    for my $c (qw{ catg cats }) {
        my $hc = $obj_data->{$c};
        $data->{$c} = {};
        for my $cc (keys %$hc) {
            next if ('C__CATG__LOGBOOK' eq $cc);
            my @acc = ();
            for my $accr (@{$hc->{$cc}}) {
                my $record = {};
                for my $accrk (keys %$accr) {
                    my $type = ref($accr->{$accrk});
                    if ('' eq $type) {
                        if ($accr->{$accrk}) {
                            $record->{$accrk} = $accr->{$accrk};
                        }
                    }
                    elsif ('HASH' eq $type) {
                        if (exists $accr->{$accrk}->{title}) {
                            $record->{$accrk} = $accr->{$accrk}->{title};
                        }
                        else {
                            $record->{$accrk} = $accr->{$accrk};
                        }
                    }
                    elsif ('ARRAY' eq $type) {
                        if (0 < scalar @{$accr->{$accrk}}) {
                            $record->{$accrk} = $accr->{$accrk};
                        }
                    }
                    else {
                        warn "get_data(): can't handle type '$type'";
                    }
                    next;
                }
                push(@acc, $record);
            }
            if (0 < scalar @acc) {
                $data->{$c}->{$cc} = \@acc;
            }
        }
    }
    return $data;
} # get_data();

sub get_information {
    my ($self, $id) = @_;
    my ($api,$info,$obj,$res,$tcat);
    $api = $self->{api};
    if (exists $self->{info} and
        (not defined $id or
         $self->{id} == $id)) {

        $info = $self->{info};
    }
    else {
        $info = {};
        $res = _cmdb_object_read($api,$id);
        # TODO: check for errors
        $obj = $res->{content}->{result};
        $info->{obj} = $obj;
        $res = _cmdb_object_type_categories_read($api, $obj->{objecttype});
        # TODO: check for errors
        $tcat = $res->{content}->{result};
        #        $info->{catg} = [ map { { $_->{const} => {}, } } @{$tcat->{catg}} ];
        #        $info->{cats} = [ map { { $_->{const} => {}, } } @{$tcat->{cats}} ];
        for my $ct ( qw( catg cats ) ) {
            for my $c (@{$tcat->{$ct}}) {
                $res = _cmdb_category_read($api, $obj->{id}, $c->{const});
                if ( $res->{is_success} ) {
                    $info->{$ct}->{$c->{const}} = $res->{content}->{result};
                }
                else {
                    my $error = $res->{content}->{error};
                    if ( $error->{code} eq '-32099' ) {
                         # ignore 'Virtual category ... cannot be handled by the API.
                    }
                    else {
                        die "Error: code: $error->{code}, $error->{message}";
                    }
                }
            }
        }
        if (exists $self->{id}) {
            $self->{info} = $info;
        }
        else {
            $self->{info} = $info;
            $self->{id} = $id;
        }
    }
    return $info;
} # get_information()

sub _cmdb_category_read {
    my ($api, $objID, $category) = @_;
    my $res = $api->request( {
        method => 'cmdb.category.read',
        params => {
            objID => $objID,
            category => $category,
        },
    });
    return $res;
} # _cmdb_category_read()

sub _cmdb_object_read {
    my ($api, $id) = @_;
    my $res = $api->request( {
        method => 'cmdb.object.read',
        params => { id => $id },
    });
    return $res;
} # _cmdb_object_read()

sub _cmdb_object_type_categories_read {
    my ($api, $type) = @_;
    my $res = $api->request( {
        method => 'cmdb.object_type_categories.read',
        params => { type => $type },
    });
    return $res;
} # _cmdb_object_type_categories_read()

1; # Magic true value required at end of module
__END__

=head1 NAME

WebService::IdoitAPI::Object - handle i-doit objects


=head1 VERSION

This document describes WebService::IdoitAPI::Object version v0.3.1


=head1 SYNOPSIS

    use WebService::IdoitAPI::Object;

    $api = WebService::IdoitAPI->new( $config );
    $object = WebService::IdoitAPI::Object->new($api, $id)

    $info = $object->get_information();

=head1 DESCRIPTION

=head1 INTERFACE 

=head2 new

    $api = WebService::IdoitAPI->new( $config );

    $object = WebService::IdoitAPI::Object->new($api, $id)

Create a new object and provide it with an WebService::IdoitAPI object
that is used for communication with i-doit
and optionally with an object ID.

The API object should be configured and ready to use.

=head2 get_data

    $data = $object->get_data();

or

    $data = $object->get_data($id);

This function returns a subset of the data retrieved by C<get_information()>
in a form that is more suitable to be copied to other objects.

The basic data structure returned by this function
is the same as by C<get_information()>.

Data from C<C__CATG__LOGBOOK> is left out
and the attributes in the other categories are changed
to values that can be used with the JSON-RPC-API call C<cmdb.category.save>.

One use case for this function
is to amend an object with data from a template.

=head2 get_information

    $info = $object->get_information();

or

    $info = $object->get_information($id);

This function collects all information about an object from i-doit
and returns it in a hash with the following structure:

    $info = {
        catg => {
            # ...
        },
        cats => {
            # ...
        },
        obj => {
            'cmdb_status' => $cmdb_status,
            'id' => $id,
            'objecttype' => $type,
            'status' => $status,
            'sysid' => $sysid,
            'title' => $title,
            'type_icon' => $path_to_file,
            'type_title' => $type_title,
        },
    }

The values at the C<catg> and C<cats> keys are themselves hashes
with the categories of the object as keys.
Which categories are actually there depends on the objecttype,
which is accessible at C<< $info->{'obj'}->{'objtype'} >>

When this function is called with a value for C<$id>,
it returns the information for the object with that ID.

Is the function is called without C<$id>,
the ID that was used when creating the object with C<new()> is used.

If the option C<$id> is provided and is equal to the ID assigned
to the object when created with C<new()>,
the retrieved information is cached with the object.
Further calls with the same ID or without C<$id> get the cached information.

If the option C<$id> is provided and differs from the internal ID
of the object, the information is always retrieved from i-doit.

=head1 CONFIGURATION AND ENVIRONMENT

WebService::IdoitAPI::Object requires no configuration files or environment variables
but it depends on an already initialized WebService::IdoitAPI object.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-new@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Mathias Weidner C<< <mamawe@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2023, Mathias Weidner C<< <mamawe@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
