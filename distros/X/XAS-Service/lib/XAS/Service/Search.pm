package XAS::Service::Search;

our $VERSION = '0.01';

use XAS::Service::Profiles;
use XAS::Service::Profiles::Search;
use XAS::Constants 'HASHREF ARRAYREF';

use XAS::Class
  version   => $VERSION,
  base      => 'XAS::Base',
  mixin     => 'XAS::Service::CheckParameters',
  accessors => 'profile',
  utils     => ':validation',
  codec     => 'JSON',
  vars => {
    PARAMS => {
      -columns => { type => ARRAYREF },
    }
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub build {
    my $self = shift;
    my ($multi) = validate_params(\@_, [
        { isa => 'Hash::MultiValue' },
    ]);

    my $opts;
    my $options = {};
    my $criteria = {};
    my $params = $multi->as_hashref;

    # internal routines

    my $comparison = sub {
        my $filter = shift;

        if ($filter->{'comparison'} eq 'lt') {

            $criteria->{$filter->{'field'}} = {'<', $filter->{'value'}};

        } elsif ($filter->{'comparison'} eq 'le') {

            $criteria->{$filter->{'field'}} = {'<=', $filter->{'value'}};

        } elsif ($filter->{'comparison'} eq 'gt') {

            $criteria->{$filter->{'field'}} = {'>', $filter->{'value'}};

        } elsif ($filter->{'comparison'} eq 'ge') {

            $criteria->{$filter->{'field'}} = {'>=', $filter->{'value'}};

        } elsif ($filter->{'comparison'} eq 'lk') {

            $criteria->{$filter->{'field'}} = {-like => [$filter->{'value'} . '%']};

        } elsif ($filter->{'comparison'} eq 'eq') {

            $criteria->{$filter->{'field'}} = $filter->{'value'};

        } elsif ($filter->{'comparison'} eq 'be') {

            my $begin = shift(@{$filter->{'value'}});
            my $end   = shift(@{$filter->{'value'}});

            $criteria->{$filter->{'field'}} = {-between => [$begin, $end]};

        }

    };

    # build the options

    if (defined($params->{'start'}) && defined($params->{'limit'})) {

        my $pager = $self->_dbpage($params->{'start'}, $params->{'limit'});

        $options->{'page'} = $pager->{'page'};
        $options->{'rows'} = $pager->{'rows'};

        delete $params->{'start'};
        delete $params->{'limit'};

    }

    if (defined($params->{'sort'})) {

        $params->{'sort'} = decode($params->{'sort'});
        $options->{'order_by'} = $self->_order_by($params->{'sort'});

        delete $params->{'sort'};

    }

    if (defined($params->{'group'})) {

        $params->{'group'} = decode($params->{'group'});
        $options->{'group_by'} = $self->_group_by($params->{'group'});

        delete $params->{'group'};

    }

    # user defined options

    if (defined($params->{'options'})) {

        my $hash = $params->{'options'};

        while (my ($key, $value) = each(%$hash)) {

            $options->{$key} = $value;

        }

    }

    # build the criteria

    if (defined($params->{'filter'})) {

        my $filters = decode($params->{'filter'});

        while (my $filter = shift(@$filters)) {

            $self->check_parameters($filter, 'filter');

            if ($filter->{'type'} eq 'string') {

                if (defined($filter->{'comparison'})) {

                    $comparison->($filter);

                } else {

                    $criteria->{$filter->{'field'}} = $filter->{'value'};

                }

            } elsif ($filter->{'type'} eq 'number') {

                if (defined($filter->{'comparison'})) {

                    $comparison->($filter);

                } else {

                    $criteria->{$filter->{'field'}} = $filter->{'value'};

                }

            } elsif ($filter->{'type'} eq 'list') {

                while (my $x = shift(@{$filter->{'value'}})) {

                    push(@{$criteria->{$filter->{'field'}}}, $x);

                }

            } elsif ($filter->{'type'} eq 'boolean') {

                my $b = sprintf("%s", $filter->{'value'});

                $criteria->{$filter->{'field'}} = 'f' if ($b eq '0');
                $criteria->{$filter->{'field'}} = 't' if ($b eq '1');

            } elsif ($filter->{'type'} eq 'date') {

                if (defined($filter->{'comparison'})) {

                    $comparison->($filter);

                } else {

                    $criteria->{$filter->{'field'}} = $filter->{'value'};

                }

            }

        }

    }

    return $criteria, $options;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    my $fields = $self->columns->[0];
    my $search = XAS::Service::Profiles::Search->new($fields);

    $self->{'profile'} = XAS::Service::Profiles->new($search);

    return $self;

}

#
# General purpose rounding function.
#
# To round a number to the nearest integer, use round($x). To round it to
# the nearest 10, use round($x, 1). Nearest 100 is round($x, 2) and so on.
# You can also round to the nearest tenth, hundredth, etc., by using a
# negative second argument: round(5.28, -1) == 5.3.
#
sub _roundup {
    my $self   = shift;
    my $n      = shift;
    my $places = shift;

    my $factor = 10 ** ($places || 0);
    return (int(($n * $factor) + ($n < 0 ? -1 : 1) * 0.5) / $factor);

}

#
# Find the "page" in a "paged" db retrieval
#
sub _dbpage {
    my $self  = shift;
    my $start = shift;
    my $limit = shift;

    my $params = {
        start => $start,
        limit => $limit
    };

    $self->check_parameters($params, 'pager');

    return {
        page => $self->_roundup(($start / $limit) + 1),
        rows => $limit
    }

}

sub _order_by {
    my $self = shift;
    my $ob   = shift;

    my @d;

    foreach my $x (@$ob) {

        my $y;
        my $z = $self->check_parameters($x, 'sort');

        $y->{'-asc'}  = $z->{'field'} if ($z->{'direction'} eq 'ASC');
        $y->{'-desc'} = $z->{'field'} if ($z->{'direction'} eq 'DESC');

        push(@d, $y);

    }

    return \@d;

}

sub _group_by {
    my ($self, $ob) = @_;

    my @d;
    my $columns = $self->columns->[0];

    foreach my $x (@$ob) {

        my $y = $self->check_parameters($x, 'group');
        my $z = $y->{'field'};

        push(@d, $z);

    }

    foreach my $x (@$columns) {

        push(@d, 'me.' . $x);

    };

    return \@d;

}

1;

__END__

=head1 NAME

XAS::Service::Search - A class to build database queries.

=head1 SYNOPSIS

 use XAS::Service::Search;
 use XAS::Model::Schema;
 use XAS::Model::Database
     schema => 'Database',
     tables => ':all'
 ;

 my @fields = ['one', 'two', 'three', 'four', 'five'];
 my $params = {
     start => 1,
     limit => 25,
     sort  => qq/[{"field": "one", "direction": "DESC"}]/,
 };

 my $schema = XAS::Model::Schema->opendb('database');
 my $search = XAS::Service::Search->new(-columns => \@fields);
 my ($criteria, $options) = $search->build($params);

 if (my $records = DataBase->search($schema, $criteria, $options)) {

     while ($my $rec = $records->next) {

     }

 }

=head1 DESCRIPTION

This module takes a set of parameters and builds search criteria and
optional actions for that criteria.

=head2 PAGING

Paging of the data source is implemented with these parameters.

=over 4

=item B<start>

The start of the offset within the data store. This is a positive integer.

=item B<limit>

The number of items to return from that offset. This is a positive integer.

=item B<Example>

 $params = {
     start => 0,
     limit => 25
 };

=back

=head2 SORTING

Sorting of the items in the data source is implemented with these parameters.

=over 4

=item B<sort>

This will be a serialized JSON data structure. This needs to be converted
into a Perl data structure. This data structure will be an array of hashs and
each hash has these fields defined:

 field     - the name of the field to sort on
 direction - the direction of the sort

Where "field" will be verified as a valid field name, and "direction" must be either
"ASC" or "DESC".

=item B<Example>

 $params = {
     sort => qq/[{"field":"email","direction":"DESC"}]/
 };

=back

=head2 GROUPING

Grouping of the items in the data source is implemented with these parameters.

=over 4

=item B<group>

This will be a serialized JSON data structure. This needs to be converted
into a Perl data structure. This data structure will be an array of hashs and
each hash has these fields defined:

 field     - the name of the field to sort on
 direction - the direction of the sort

Where "field" will be verified as a valid field name, and "direction" must be either
"ASC" or "DESC".

=item B<Example>

 $params = {
     group => qq/[{"field":"email","direction":"ASC"}]/
 };

=back

=head2 FILTERING

This allows for selecting specific items from the data source. This is
implemented with these parameters.

=over 4

=item B<filter>

This will be a serialized JSON data structure. This needs to be converted
into a Perl data structure. This data structure will be an array of hashs and
each hash has these fields defined:

 field      - the name of the field
 type       - the type of the field
 value      - the value for that field
 comparison - optional

Where "field" will be verified as a valid field name and "type" can be one
of the following:

 string, number, list, boolean, date

and "value" depends on the context of the type. So a basic filter would be
the following:

 $params = {
     filter => qq/[{"field":"email", "type": "string", "value": "kesteb@wsipc.org"}]/
 };

Here is an example were "value" can change from a simple string to something
else:

 $params = {
     filter => qq/[{"field":"email", "type": "list", "value": ["kesteb@wsipc.org","kevin@example.org"]}]/
 };

In this case since the "type" is "list", the "value" would be an array. The
optional "comparison" parameter can have the following values associated:

 lt - less then the value
 le - less then or equal to the value
 gt - greater then the value
 ge - greater then or equal to the value
 lk - like the value
 be - between two values
 eq - equal to the value

The "comparision" parameter is only meaningful with the "string", "number" and
"date" types. So now we can expand our filter with something like this:

 $params = {
     filter => qq/[{"field":"one", "type": "string", "comparison": "be", "value": ["0", "10"]}]/
 };

Which should return all the items where the field "one" is between 0
and 10. So you can build some fairly interesting filters. But remember that
if you have multiple filters for on field. The last one will be used. So
something like this:

 $params = {
     filter => qq/[{"field":"one", "type": "string", "comparison": "lt", "value": "2016-07-30"},
                   {"field":"one", "type": "string", "comparison": "gt", "value": "2016-07-24"}
                  ]/
 };

Which would only return items where the field "one" is greater then
"2016-07-24" and the cutoff of "2016-07-30" would be silently ignored.

So you can build some rather sophisticated search parameters:

=item B<Example>

 $params => {
     start  => 0,
     limit  => 25,
     sort   => qq/[{"field":"email", "direction":"ASC"}]/,
     filter => qq/[{"field":"email", "type": "string", "comparison": "lk", "value": "kesteb"}]/
 };

Which should return all items in a paged response where the field "email"
is like 'kesteb'.

=back

=head1 METHODS

=head2 new

This method initializes the module and takes the following parameter:

=over 4

=item B<-columns>

The colums from the database. This is used to verify the search parameters and
build the correct data structures for the database queries.

=back

=head2 build($params)

This method will build and return the criteria and options data structures for
a search query.

=over 4

=item B<$params>

A hashref of parameters used for building the search criteria and optional
actions for that criteria.

=back

=head1 SEE ALSO

=over 4

=item L<XAS::Service|XAS::Service>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

#  paging:    _search?start=0&limit=25
#  sorting:   _search?sort=[{"field":"email","direction":"DESC"},{"field":"last_name","direction":"ASC"} ...]
#  grouping:  _search?group=[{"field":"country","direction":"ASC"},{"field":"province","direction":"ASC"}, ...]
#  filtering: _search?filter=[{"field":"first_name","value":"Neil"},{"field":"city","value":"Vancouver"}, ...]
