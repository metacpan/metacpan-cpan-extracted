
package WWW::Kickstarter::Data::Categories;

use strict;
use warnings;
no autovivification;


use WWW::Kickstarter::Data  qw( );
use WWW::Kickstarter::Error qw( my_croak );


our @ISA = 'WWW::Kickstarter::Data';


sub _new {
   my_croak(400, "Incorrect usage") if @_ < 3;
   my ($class, $ks, $categories, %opts) = @_;

   if (my @unrecognized = keys(%opts)) {
      my_croak(400, "Unrecognized parameters @unrecognized");
   }

   my @tree;
   for my $category (@$categories) {
      my $parent_info = $category->{parent};
      my $parent_id   = $parent_info ? $parent_info->{id} : 0;
      my $position    = $category->{position};
      $tree[$parent_id][$position] = $category;
   }

   for my $category (@$categories) {
      my $subcategories = $tree[ $category->{id} ];
      $category->_set_subcategories( $subcategories ? grep defined, @$subcategories : () );
   }

   my $data = {
      categories => $categories,
      top_level  => [ grep defined, @{ $tree[0] } ],
   };

   return $class->SUPER::_new($ks, $data);
}


sub categories           { @{ $_[0]{categories} } }
sub top_level_categories { @{ $_[0]{top_level} } }


sub refetch { my $self = shift;  return $self->ks->categories(@_); }


sub _visit {
   my $self     = shift;
   my $visitor  = shift;
   my $category = shift;
   my $depth    = shift;

   my @subcategories =
      sort { $a->name() cmp $b->name() }
         $category ? $category->subcategories() : @{ $self->{top_level} };

   my $visit_next = sub {
      return 0 if !@subcategories;
      $self->_visit($visitor, shift(@subcategories), $depth+1, @_);
      return 1;
   };

   $visitor->($category, $depth, $visit_next, 0+@subcategories, @_);
}


sub visit {
   my_croak(400, "Incorrect usage") if @_ < 2;
   my $self = shift;
   my $opts = shift;

   my $visitor;
   if (ref($opts) eq 'CODE') {
      $visitor = $opts;
      $opts = undef;
   } else {
      $visitor = $opts->{visitor};
   }

   if ($opts->{root}) {
      $self->_visit($visitor, undef, 0, @_);
   } else {
      for my $category (
         sort { $a->name() cmp $b->name() }
            @{ $self->{top_level} }
      ) {
         $self->_visit($visitor, $category, 0, @_);
      }
   }
}


1;


__END__

=head1 NAME

WWW::Kickstarter::Data::Categories - Kickstarter categories


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

=head2 C<< my @categories = $categories->categories; >>

Returns a L<WWW::Kickstarter::Data::Category> object for each Kickstarter category.


=head2 C<< my @categories = $categories->top_level_categories; >>

Returns a L<WWW::Kickstarter::Data::Category> object for each top-level Kickstarter category.


=head1 API CALLS

=head2 refetch

   $categories = $categories->refetch();

Refetches the categories from Kickstarter.

This ensures the data is up to date, and it will populate fields that may not be provided by objects created by some API calls.


=head1 METHODS

=head2 visit

   sub visitor {
      my ($category, $depth, $visit_next, $num_subcategories, @args) = @_;
      ...
   }

   $categories->visit(\&visitor, @args);

   $categories->visit({ visitor => \&visitor, %opts }, @args);

Traverses the category hiearchy in a depth-first, alphabetical manner.

The visitor is called with the following arguments:

=over

=item * C<$category>

A category as an L<WWW::Kickstarter::Data::Category> object.

=item * C<$depth>

The depth of the category in the hierarchy, zero for top-level categories.

=item * C<$visit_next>

A code reference that visits one subcategory each time it's called.
Unless you want to avoid visiting a category's subcategories,
it should be called until it returns false.

=item * C<$num_subcategories>

The number of subcategories this category has. The following are basically equivalent:

=over

=item * C<< 1 while $visit_next->(); >>
=item * C<< $visit_next->() for 1..$num_subcategories; >>

=back

=item * C<@args>

The values passed to C<visit> or C<&$visit_next>.

=back


Options:

=over

=item * C<< root => 1 >>

The visitor will be called one extra time for the root of the tree.
C<$category> will be undefined in the visitor for this call.
The root will have a depth of zero, so the top-level categories
will have a depth of one.

=back


=head3 Examples

=over

=item * Simple Example

   $categories->visit(sub{
      my ($category, $depth, $visit_next) = @_;
      say "   " x $depth, $category->name;
      1 while $visit_next->();
   });

Output:

   Art
      Crafts
      Digital Art
      ...
      Sculpture
   Comics
   Dance
   Design
      Graphic Design
      Product Design
   ...


=item * Passing data down to subcategories.

   $categories->visit(sub{
      my ($category, $depth, $visit_next, undef, $parent) = @_;
      say $parent . $category->name;
      1 while $visit_next->($parent . $category->name . '/');
   }, '');

Output:

   Art
   Art/Crafts
   Art/Digital Art
   ...
   Art/Sculpture
   Comics
   Dance
   Design
   Design/Graphic Design
   Design/Product Design
   ...


=item * Complex example

   $categories->visit({
      root    => 1,
      visitor => sub{
         my ($category, $depth, $visit_next, $num_subcategories, $subcategory_idx) = @_;

         if ($category) {
            my $class = $subcategory_idx % 2 ? 'odd' : 'even';
            print qq{<li class="$class">} . $category->name;
         }

         if ($num_subcategories) {
            say "<ul>";
            for my $subcategory_idx (1..$num_subcategories) {
               $visit_next->($subcategory_idx);
            }
            say "</ul>";
         }

         if ($category) {
            say "</li>"
         }
      },
   });

Output:

   <ul>
   <li class="odd">Art<ul>
   <li class="odd">Crafts</li>
   <li class="even">Digital Art</li>
   ...
   <li class="even">Sculpture</li>
   </ul>
   </li>
   <li class="even">Comics</li>
   <li class="odd">Dance</li>
   <li class="even">Design<ul>
   <li class="odd">Graphic Design</li>
   <li class="even">Product Design</li>
   </ul>
   </li>
   ...
   </ul>


=back


=head1 VERSION, BUGS, KNOWN ISSUES, DOCUMENTATION, SUPPORT, AUTHOR, COPYRIGHT AND LICENSE

See L<WWW::Kickstarter>


=cut
