
package WWW::Kickstarter::Data::Category;

use strict;
use warnings;
no autovivification;


use WWW::Kickstarter::Data  qw( );
use WWW::Kickstarter::Error qw( my_croak );


our @ISA = 'WWW::Kickstarter::Data';


sub _new {
   my_croak(400, "Incorrect usage") if @_ < 3;
   my ($class, $ks, $data, %opts) = @_;

   if (my @unrecognized = keys(%opts)) {
      my_croak(400, "Unrecognized parameters @unrecognized");
   }

   my $self = $class->SUPER::_new($ks, $data);
   $self->{_}{subcategories} = undef;

   return $self;
}


sub _set_subcategories { my $self = shift; $self->{_}{subcategories} = [ @_ ]; }


sub id   { $_[0]{id} }
sub slug { $_[0]{slug} }
sub name { $_[0]{name} }


sub subcategories {
   my ($self) = @_;
   my $subcategories = $self->{_}{subcategories}
      or my_croak(400, "The list of subcategories is only avaiable for Category objects created by \$ks->categories()");

   return @$subcategories;
}


sub refetch              { my $self = shift;  return $self->ks->category($self->id, @_); }
sub projects             { my $self = shift;  return $self->ks->category_projects($self->id, @_); }
sub projects_recommended { my $self = shift;  return $self->ks->category_projects_recommended($self->id, @_); }


1;


__END__

=head1 NAME

WWW::Kickstarter::Data::Category - Kickstarter category data


=head1 SYNOPSIS

   use WWW::Kickstarter;

   my $email    = '...';  # Your Kickstarter login credentials
   my $password = '...';

   my $ks = WWW::Kickstarter->new();
   $ks->login($email, $password);

   my $categories = $ks->categories();

   $categories->visit(sub{
      my ($category, $depth, $visit_next) = @_;
      say "   " x $depth, $category->name;
      1 while $visit_next->();
   });


=head1 ACCESSORS

=head2 id

   my $category_id = $category->id;

Returns the numerical id of the category.


=head2 slug

   my $category_slug = $category->slug;

Returns the keyword id of the category.


=head2 name

   my $category_name = $category->name;

Returns the category's name.


=head2 subcategories

   my @categories = $category->subcategories;

Returns the subcategories of this category as L<WWW::Kickstarter::Data::Category> objects.

This information is only evailable if this object was obtained (directly or indirectly)
from a L<WWW::Kickstarter::Data::Categories> object. An exception will be thrown otherwise.


=head1 API CALLS

=head2 refetch

   $category = $category->refetch();

Refetches the category from Kickstarter.

This ensures the data is up to date, and it will populate fields that may not be provided by objects created by some API calls.


=head2 projects

   my $projects_iter = $category->projects(%opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns projects in the specified category as L<WWW::Kickstarter::Data::Project> objects.

It accepts the same options as L<WWW::Kickstarter's C<projects>|WWW::Kickstarter/projects>.


=head2 projects_recommended

   my $projects_iter = $category->projects_recommended(%opts);

Returns an L<iterator|WWW::Kickstarter::Iterator> that fetches and returns the recommended projects in the specified category as L<WWW::Kickstarter::Data::Project> objects.

It accepts the same options as L<WWW::Kickstarter's C<projects>|WWW::Kickstarter/projects>.


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
