package Yukki::Web::Response;
{
  $Yukki::Web::Response::VERSION = '0.140290';
}
use Moose;

use Yukki::Types qw( BreadcrumbLinks NavigationMenuMap );

use Plack::Response;

# ABSTRACT: the response to the client


has response => (
    is          => 'ro',
    isa         => 'Plack::Response',
    required    => 1,
    lazy_build  => 1,
    handles     => [ qw(
        status headers body header content_type content_length content_encoding
        redirect location cookies finalize
    ) ],
);

sub _build_response {
    my $self = shift;
    return Plack::Response->new(200, [ 'Content-type' => 'text/html; charset=utf-8' ]);
}


has page_title => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_page_title',
);


has navigation => (
    is          => 'rw',
    isa         => NavigationMenuMap,
    required    => 1,
    default     => sub { +{} },
    traits      => [ 'Hash' ],
    handles     => {
        navigation_menu_names => 'keys',
    },
);


has breadcrumb => (
    is          => 'rw',
    isa         => BreadcrumbLinks,
    required    => 1,
    default     => sub { [] },
    traits      => [ 'Array' ],
    handles     => {
        breadcrumb_links => 'elements',
    },
);


sub navigation_menu {
    my ($self, $name) = @_;
    return sort { ($a->{sort}//50) <=> ($b->{sort}//50) } 
               @{ $self->navigation->{$name} // [] };
}


sub add_navigation_item { shift->add_navigation_items(@_) }

sub add_navigation_items {
    my $self = shift;
    my $name_or_names = shift;

    my @names = ref $name_or_names ? @$name_or_names : ($name_or_names);

    for my $name (@names) {
        $self->navigation->{$name} //= [];
        push @{ $self->navigation->{$name} }, @_;
    }
}

1;

__END__

=pod

=head1 NAME

Yukki::Web::Response - the response to the client

=head1 VERSION

version 0.140290

=head1 DESCRIPTION

An abstraction around the HTTP response that is astonishingly similar to L<Plack::Response>. Call C<finalize> to get the final PSGI response.

=head1 ATTRIBUTES

=head2 response

This is the internal L<Plack::Response> object. Do not use.

Use the delegated methods instead:

  status headers body header content_type content_length content_encoding
  redirect location cookies finalize

=head2 page_title

This is the title to give the page in the HTML.

=head2 navigation 

This is the navigation menu to place in the page. This is an array of hashes. Each entry should look like:

  {
      label => 'Label',
      href  => '/link/to/somewhere',
      sort  => 50,
  }

A sorted list of items is retrieved using L</navigation_menu>. New items can be added with the L</add_navigation_item> and L</add_navigation_items> methods.

=head2 breadcrumb

This is the breadcrumb to display. It is an empty array by default (meaning no breadcrumb). Each element of the breadcrumb is formatted like navigation, except that C<sort> is not used here.

=head1 METHODS

=head2 navigation_menu

  my @items = $response->navigation_menu('repository');

Returns a sorted list of navigation items  for the named menu.

=head2 add_navigation_item

=head2 add_navigation_items

  $response->add_navigation_item(menu_name => {
      label => 'Link Title',
      url   => '/path/to/some/place',
      sort  => 50,
  });

Add one or more items to the named menu. The first argument is always the name or names of the menu. Mutliple names may be given in an array reference. If multiple names are given, the menu items given will be added to each menu named. The remaining arguments are hash references that must have a C<label> and a C<url>. The C<sort> is optional.

L</add_navigation_item> is a synonym for L</add_navigation_items>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
