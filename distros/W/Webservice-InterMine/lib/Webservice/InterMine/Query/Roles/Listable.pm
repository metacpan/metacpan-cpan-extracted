package Webservice::InterMine::Query::Roles::Listable;

=head1 NAME

Webservice::InterMine::Query::Roles::Listable - Trait for queries that are Listable

=head1 SYNOPSIS

  my $query = get_service->select("Gene.*");
  my $list = $service->new_list(content => $query);

=head1 DESCRIPTION

This role provides an implementation of the required C<get_list_request_parameters> 
method of the more general Listable role for queries. It also provides a mechanism
for creating a valid list query from a multi-noded query by indicating the appropriate
path.

=cut

use Moose::Role;

requires "clone";

use List::MoreUtils qw/uniq/;

=head2 get_list_request_parameters

Get the parameters to pass to the service for list requests.

=cut

use constant NO_SINGLE_NODE =>
    "Cannot generate a valid list request - more than one class is selected";


sub get_list_request_parameters {
    my $self = shift;
    my $clone = $self->clone;
    my @views = $clone->views;
    if (@views == 0 && $clone->has_root_path) {
        $clone->select("id");
    } elsif (@views > 1 || $views[0] !~ /\.id$/) {
        my %froms = map {$clone->path($_)->prefix() => 1} @views;
        my @froms = keys %froms;
        if (@froms > 1) {
            confess NO_SINGLE_NODE;
        } else {
            $clone->select($froms[0] . ".id");
        }
    } 
        
    my %params = $clone->get_request_parameters;
    return %params;
}

=head2 make_list_query($path): Listable

Make a listable query from a multi-node query, by selecting the path whose
values should be included in the new list.

The path need not be in the current select list.

This method deals with ensuring the result set does not change due to changes in
the select list.

Returns a L<Listable> L<Webservice::InterMine::Query>.

=cut

sub make_list_query {
    my $self = shift;
    my $path = shift or confess "No path passed to make_list_query";
    my $clone = $self->clone;
    $clone->clear_sort_order; # Sort order is meaningless for list-queries
    $path = $clone->path($path); # promote to Path
    $path = $path->prefix() if $path->end_is_attribute;

    my @unconstrained = grep {
        my $view = $_;
        my $predicate = sub {
            my $cpath = $_->path;
            ($view eq $cpath) || ($view eq $clone->path($cpath)->prefix());
        };
        my @matching = $clone->find_constraints($predicate);
        @matching == 0;
    } uniq map { $clone->path($_)->prefix() } $clone->views;

    for my $needs_con (@unconstrained) {
        $clone->add_constraint(path => $needs_con->append('id'), op => 'IS NOT NULL');
    }
    $clone->select($path->append('id'));
    return $clone;
}

1;
