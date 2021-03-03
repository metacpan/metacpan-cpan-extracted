package Valiant::Filter;

use Moo::Role;

requires 'filter';

1;

=head1 NAME

Valiant::Filter - A role to define the Filter interface.

=head1 SYNOPSIS

    package MySpecialFilter;

    use Moo;
    with 'Valiant::Validator';

    sub filter {
      my ($self, $class, $attrs) = @_;
      # Do something with $attrs, possibly with $self
      return $attrs;
    }

=head1 DESCRIPTION

This is a base role for defining a filter.  This should be a class that
defines a C<filter> method. Here's a more detailed example that shows
using a custom filter with a filterable object:

    package Local::Test::Filter::Truncate;

    use Moo;
    with 'Valiant::Filters';

    has max_length => (is=>'ro', required=>1);

    sub filter {
      my ($self, $class, $attrs) = @_;
      foreach my $key (keys %{$attrs}) {
        my $current_value = $attrs->{$key};
        my $new_value = substr( $current_value, 0, $self->max_length );
        $attrs->{$key} = $new_value;
      }
      return $attrs;
    }

    package Local::Test::User;

    use Moo;
    use Valiant::Filters;

    has [qw(first_name last_nane)] => (is=>'ro', required=>1);

    filters_with 'Truncate', max_length=>25;

    my $user = Local::Test::User->new(
      first_name => 'averyveryveryveryverylooooooooonnngFIRSTname',
      last_name => 'averyveryveryveryverylooooooooonnngLASTname',
    );

    print $user->first_name; #averyveryveryveryverylooo
    print $user->last_name; #averyveryveryveryverylooo

A Filter receives all the arguments passed to C<new> and runs before the object is created. It gets
the following three arguments: C<$self>, which is the instance of the Filter which is associated with
the filterable class,  C<$class>, which is the name of the class upon which the filter is running and
C<$attrs> which is a hashref of the arguments passed to C<new>.   C<$attrs> is always a hashref and
has been normalized as such.  ALso C<$attrs> contains everything passed to C<new> even things that are
not valid for the C<$class>.  

A Filter is created once when the class uses it and exists for the full life cycle
of the filterable object.

Generally you would write a filter class like this when you want a filter that can be applied
to all the incoming arguments or when the filter itself is dependent on all the arguments.  For writing
filters that are applied to individual attributes you should create a subclass of L<Valiant::Filter::Each>.

=head1 PREPACKAGED FILTER CLASSES

The following attribute filter classes are shipped with L<Valiant>.  Please see the package POD for
usage details (this is only a sparse summary)

=head2 Collapse

Collapse all whitespace in a string to a single space.  See L<Valiant::Filter::Collapse> for details.

=head2 Flatten

Flatten an arrayref or hashref to a string.  See L<Valiant::Filter::Flatten> for details.

=head2 HtmlEscape

Basic HTML escaping on a string.  See L<Valiant::Filter::HtmlEscape> for details.

=head2 Lower

Lowercase a string.  See L<Valiant::Filter::Trim> for details.

=head2 Title

'title' cases a string (all first letters up cased).  See L<Valiant::Filter::Title> for details.

=head2 ToArray

Given a string force to a single element array (do nothing if its already an array. 
See L<Valiant::Filter::ToArray> for details.

=head2 Trim

Trims whitespace from the start and/or end of the attribute string.

See L<Valiant::Filter::Trim> for details.

=head2 UcFirst

Uppercases the first letter of a string

See L<Valiant::Filter::UcFirst> for details.

=head2 Upper

Upcase a string.  See L<Valiant::Filter::Upper> for details.

=head2 With

Use a subroutine reference to provide filtering.

See L<Valiant::Filter::With> for details.

=head2 Special Validators

The following validators are not considered for end users but have documentation you might
find useful in furthering your knowledge of L<Valiant>:  L<Valiant::Filter::Collection>,
L<Valiant::Filter::Each>.

=head1 SEE ALSO
 
L<Valiant>, L<Valiant::Filter::Each>.

=head1 AUTHOR
 
See L<Valiant>

=head1 COPYRIGHT & LICENSE
 
See L<Valiant>

=cut
