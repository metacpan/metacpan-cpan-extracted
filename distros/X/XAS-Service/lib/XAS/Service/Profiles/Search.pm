package XAS::Service::Profiles::Search;

our $VERSION = '0.01';

use XAS::Utils ':validation';
use XAS::Constants 'ARRAYREF';
use Data::FormValidator::Constraints::MethodsFactory ':set';

#use Data::Dumper;

# -----------------------------------------------------------------
# Public Methods
# -----------------------------------------------------------------

# -----------------------------------------------------------------
# Private Methods
# -----------------------------------------------------------------

sub new {
    my $class = shift;
    my ($fields) = validate_params(\@_, [
        { type => ARRAYREF },
    ]);

    my $pager = {
        filters => ['trim'],
        required => [qw( start limit )],
        constraint_methods => {
            start => qr/^\d+$/,
            limit => qr/^\d+$/,
        },
        msgs => {
            constraints => {
                start => 'must be a number',
                limit => 'must be a number',
            }
        }
    };

    my $filter = {
        filters => ['trim'],
        required => ['type', 'field', 'value'],
        optional => ['comparison'],
        constraint_methods => {
            type       => FV_set(1, qw( string date list boolean deleted )),
            comparison => FV_set(1, qw( lt le gt ge eq lk be)),
            field      => FV_set(1, @$fields),
        },
        msgs => {
            constraints => {
                type       => 'must be either "boolean", "string", "date" or "list"',
                comparison => 'must be either "lt", "le", "gt", "ge", "eq", "lk" or "be"',
                field      => 'must be a single word',
            }
        }
    };

    my $sort = {
        filters => ['trim'],
        required => ['field', 'direction'],
        constraint_methods => {
            field  => FV_set(1, @$fields ),
            direction => FV_set(1, qw( ASC DESC )),
        },
        msgs => {
            constraints => {
                field     => 'sort fields are invalid',
                direction => 'sort directions must be either ASC or DESC'
            }
        }
    };

    my $group = {
        filters => ['trim'],
        required => ['field'],
        optional => ['direction'],
        constraint_methods => {
            field  => FV_set(1, @$fields ),
            direction => FV_set(1, qw( ASC DESC )),
        },
        msgs => {
            constraints => {
                field     => 'group fields are invalid',
                direction => 'group directions must be either ASC or DESC'
            }
        }
    };

    my $profiles = {
        sort   => $sort,
        group  => $group,
        pager  => $pager,
        filter => $filter,
    };

    return $profiles;

}

1;

=head1 NAME

XAS::Service::Profiles::Search - A class for creating standard validation profiles.

=head1 SYNOPSIS

 my $params = {
     start => 0,
     limit => 25,
 };

 my $fields = qw(id server queue requestor typeofrequest status startdatetime);
 my $search = XAS::Service::Profiles::Search->new($fields);
 my $validate = XAS::Service::Validate->new($search);
 my $results = $validate->check($params, 'pager');

 if ($results->has_invalid) {

     my @invalids = $results->invalid;

     foreach $invalid (@invalids) {

         printf("%s: %s\n", $invalid, $results->msgs->{$invalide});

     }

 }

=head1 DESCRIPTION

This module creates a standardized
L<Data::FormValidator|https://metacpan.org/pod/Data::FormValidator> validation
profile for searches.

=head1 METHODS

=head2 new($fields)

Initializes the vaildation profile.

=over 4

=item B<$field>

An array ref of field names that may appear in search requests.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Service|XAS::Service>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
