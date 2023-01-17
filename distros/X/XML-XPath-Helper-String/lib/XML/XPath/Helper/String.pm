package XML::XPath::Helper::String;

use 5.008;
use strict;
use warnings;

use Exporter 'import';

our $VERSION = '1.03';

our @EXPORT_OK = qw(quoted_string one_of_quoted not_one_of_quoted);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

use Carp;



sub quoted_string {
  @_ == 1 or croak("Wrong number of arguments");
  my $arg = shift;
  my $arg_scalar;
  if (ref($arg)) {
    croak("Argument must be a string or a reference to an array") unless ref($arg) eq 'ARRAY';
  } else {
    $arg_scalar = 1;
    $arg = "" if !defined($arg);
    $arg = [$arg];
  }
  my @result;
  foreach my $string (@{$arg}) {
    if (index($string, "'") >= 0) {
      my @array;
      foreach my $substr (grep{length($_)} split(/('+)/, $string)) {
        my $q = substr($substr, 0, 1) eq "'" ? '"' : "'";
        push(@array, "${q}${substr}${q}");
      }
      push(@result, 'concat(' . join(',', @array) . ')');
    } else {
      push(@result, "'$string'");
    }
  }
  return ($arg_scalar ? $result[0] : \@result);
}


sub one_of_quoted {
  @_ > 0 or croak("Too few arguments");
  my ($array, $name) = @_;
  ref($array) eq 'ARRAY' or croak("Argument 1 must be an ARRAY ref");
  if (defined($name)) {
    ref($name) and croak("Argument 2 must be a scalar");
    return "$name=" . join(" or $name=", @{quoted_string($array)});
  } else {
    my $values = quoted_string($array);
    return sub { return "$_[0]=" . join(" or $_[0]=", @{$values}); };
  }
}


sub not_one_of_quoted {
  @_ > 0 or croak("Too few arguments");
  my ($array, $name) = @_;
  ref($array) eq 'ARRAY' or croak("Argument 1 must be an ARRAY ref");
  if (defined($name)) {
    ref($name) and croak("Argument 2 must be a scalar");
    return "$name!=" . join(" and $name!=", @{quoted_string($array)});
  } else {
    my $values = quoted_string($array);
    return sub { return "$_[0]!=" . join(" and $_[0]!=", @{$values}); };
  }
}



1; # End of XML::XPath::Helper::String



__END__


=pod



=head1 NAME

XML::XPath::Helper::String - Helper functions for xpath expression.


=head1 VERSION

Version 1.03

=head1 SYNOPSIS

    use XML::LibXML;
    use XML::XPath::Helper::String qw(quoted_string one_of_quoted);

    my @nodes = $myXML->findnodes('subnode=' .
                                  quoted_string("value with '"));


    my @other_nodes =
      $myXML->findnodes('foo_node[' . one_of_quoted("bar_node",
                                                    "x'''y",
                                                    "z")
                                ']');



=head1 DESCRIPTION

This modules provides functions that helps building xpath expressions. The
functions are exported on demand, you can use the C<:all> tag to export all
functions.


=head2 FUNCTIONS

=over

=item C<quoted_string(I<ARG>)>

This function makes it easier to create xpath expressions seaching for values
that contains single quotes. The problem with xpath is that it does not
support an escape character, so you have to use a C<concat(...)> in such
cases. This function creates a C<concat(...)> expression if needed.

I<C<ARG>> must be a string or a reference to an array of strings. If it is a
string, the the function returns a string. If it is an array reference, then
the function returns an array reference.

For each string in I<C<ARG>> the function does the following: if the string
does not contain any single quote, then the result is the string enclosed in
single quotes. So this

   print(quoted_string("hello"), "\n");


prints:

   'hello'

But this

   print(quoted_string("'this' that \"x\" '''"), "\n");

prints:

   concat("'",'this',"'",' that "x" ',"'''")


=item C<one_of_quoted(I<VALUES>, I<NAME>)>

=item C<one_of_quoted(I<VALUES>)>

This function creates an xpath expressions checking if I<C<NAME>> contains one
of the values in I<C<VALUES>>. It calls C<quoted_string> to handle single
quotes correctly. Example:

This

   print(one_of_quoted(["'a'", "b'''cd", "e"], "foo"), "\n");

prints

   foo=concat("'",'a',"'") or foo=concat('b',"'''",'cd') or foo='e'

If I<C<NAME>> is not specified, then the function returns a closure that takes
one argument and produces the expression when called. Example:

This

   my $closure = one_of_quoted(["'a'", "b'''cd", "e"]);
   print($closure->("foo"), "\n",
         $closure->("bar"), "\n");

prints

   foo=concat("'",'a',"'") or foo=concat('b',"'''",'cd') or foo='e'
   bar=concat("'",'a',"'") or bar=concat('b',"'''",'cd') or bar='e'


=item C<not_one_of_quoted(I<VALUES>, I<NAME>)>

=item C<not_one_of_quoted(I<VALUES>)>

Like C<one_of_quoted> but creates an xpath expressions checking if
I<C<NAME>> contains B<none> of the values in I<C<VALUES>>. Example:

This:

   print(not_one_of_quoted("foo", "'a'", "b'''cd", "e"), "\n");

prints:

   foo!=concat("'",'a',"'") and foo!=concat('b',"'''",'cd') and foo!='e'

=back


=head1 SEE ALSO

L<XML::LibXML>,
L<XML::XPath::Helper::Const>


=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xml-xpath-helper-string at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-XPath-Helper-String>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::XPath::Helper::String


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-XPath-Helper-String>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/XML-XPath-Helper-String>

=item * Search CPAN

L<https://metacpan.org/release/XML-XPath-Helper-String>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Abdul al Hazred.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

