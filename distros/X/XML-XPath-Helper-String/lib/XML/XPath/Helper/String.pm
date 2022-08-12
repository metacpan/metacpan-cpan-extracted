package XML::XPath::Helper::String;

use 5.008;
use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.01';

our @EXPORT_OK = qw(quoted_string one_of_quoted not_one_of_quoted);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

use Carp;

sub quoted_string {
  my ($string) = @_;
  croak("Argument must be a scalar") if ref($string);
  $string = "" if !defined($string);
  my $result;
  if (index($string, "'") >= 0) {
    my @array;
    foreach my $substr (grep{length($_)} split(/('+)/, $string)) {
      my $q = substr($substr, 0, 1) eq "'" ? '"' : "'";
      push(@array, "${q}${substr}${q}");
    }
    $result = 'concat(' . join(',', @array) . ')';
  } else {
    $result = "'$string'";
  }
  return $result;
}


sub one_of_quoted {
  @_ > 1 or croak("Too few arguments");
  my $name = shift;
  my @valArray;
  foreach my $val (@_) {
    # Just for performance: call quoted_string() only if really needed.
    push(@valArray, index($val, "'") >= 0 ? quoted_string($val) : "'$val'");
  }
  return "$name=" . join(" or $name=", @valArray);
}


sub not_one_of_quoted {
  @_ > 1 or croak("Too few arguments");
  my $name = shift;
  my @valArray;
  foreach my $val (@_) {
    # Just for performance: call quoted_string() only if really needed.
    push(@valArray, index($val, "'") >= 0 ? quoted_string($val) : "'$val'");
  }
  return "$name!=" . join(" and $name!=", @valArray);
}



1; # End of XML::XPath::Helper::String



__END__


=pod



=head1 NAME

XML::XPath::Helper::String - Helper functions for xpath expression


=head1 VERSION

Version 0.01

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

=head3 C<quoted_string(I<STRING>)>

This function makes it easier to create xpath expressions seaching for values
that contains single quotes. The problem with xpath is that it does not
support an escape character, so you have to use a C<concat(...)> in such
cases. This function creates a C<concat(...)> expression if needed.

If I<C<STRING>> does not contain any single quote, then the function returns
I<C<STRING>> enclosed in single quotes. So this

   print(quoted_string("hello"), "\n");


prints:

   'hello'

But this

   print(quoted_string("'this' that \"x\" '''"), "\n");

prints:

   concat("'",'this',"'",' that "x" ',"'''")


=head3 C<one_of_quoted(I<NAME>, I<VALUES>)>

This functions takes two or more string arguments. I<C<NAME>> should be the
name of an XML node. The function creates an xpath expressions checking if
I<C<NAME>> contains one of the values in I<C<VALUES>>. It calls
C<quoted_string> if needed. Example:

This

   print(one_of_quoted("foo", "'a'", "b'''cd", "e"), "\n");

prints

   foo=concat("'",'a',"'") or foo=concat('b',"'''",'cd') or foo='e'


=head3 C<not_one_of_quoted(I<NAME>, I<VALUES>)>

Like C<one_of_quoted> but creates an xpath expressions checking if
I<C<NAME>> contains B<none> of the values in I<C<VALUES>>. Example:

This:

   print(not_one_of_quoted("foo", "'a'", "b'''cd", "e"), "\n");

prints:

   foo!=concat("'",'a',"'") and foo!=concat('b',"'''",'cd') and foo!='e'


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

