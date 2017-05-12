package TipJar::Template::fill;

use vars qw/$VERSION/;

$VERSION = '0.01';

sub import{
	shift; # lose package name
	my %args = @_;

	$args{fill} ||= 'fill';
	$args{hashref} ||= \%{caller().'::'.$args{fill}};
	$args{regex} ||= qr{\[(\w+)\]};

	if($args{_args}){
	   *{caller().'::'.$args{fill}.'_args'} = \%args;
	   *{caller().'::'.$args{fill}} =
	       sub($;$){
		my $result = $_[0];
		$result =~ s/$args{regex}/$args{hashref}->{$1}/g;
		$result;
	       };
	   return;
	};

	*{caller().'::'.$args{fill}} =
	   makesub(@args{qw/regex hashref/});
};

sub makesub{
	my ($regex, $default_hr) = @_;
	   sub($;$){
		my ($result, $hr) = @_;
		$hr ||= $default_hr;
		$result =~ s/$regex/$hr->{$1}/g;
		$result;
	   };
};




1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

TipJar::Template::fill - interpolate data into templates with a minimum of fuss

=head1 EXAMPLES

Define a function that fills templates from a hash in our scope

  use strict; # optional
  our %fill; 
  use TipJar::Template::fill 
  ;
  %fill = ... # some code to load variables into %fill
  print fill( <<EOTEM);
  Dear [HONORIFIC] [FIRSTNAME] [LASTNAME],

        About your issue numbered [ISSUENUMBER] in our tracking system,

  [ISSUEDESCR]

       We have reached the following conclusion:

  [RESOLUTIONTEXT]

        Thanks for choosing [COMPANYNAME]

        Have a [DAYTYPE] day.
  EOTEM

Some templates use a different syntax for their variables,
and keep them in hashes with names different than you want
for the filling function.

  my %Tvar;
  use TipJar::Template::fill 
       fill => fillXML,   
       hashref => \%Tvar, # this will be the default data source for fillXML(),
       			  # instead of %fillXML
       regex => qr{<tvar name="([^"]*)"\s*/>};   

And some of our templates take their data from alternate sources

  use TipJar::Template::fill;
  $fill{musicCDlist} =
       join '</li><li>',
            map {
	          fill($CDlist_item_template, $_)
	    }
	    @{
	       $dbh->selectall_arrayref(
	         'SELECT * FROM music',
	         {Slice => {}}
	       )
	    };

=head1 DESCRIPTION

TipJar::Template::fill provides an interface to substitution-based
filling of templates.  That's all it does.  Find and replace.  No
conditionals or looping constructs are provided.

=head2 ARGUMENTS

TipJar::Template::fill takes all its configuration on its C<use> line.

=head3 fill

the C<fill> argument specifies the name of the subroutine to export.
This argument defaults to 'fill'.

=head3 hashref

the C<hashref> argument specifies the hash to find the data to interpolate
into the templates.  When not specified, it defaults to a named package hash
in the calling package, with the name provided by the C<fill> argument.

=head3 regex

the C<regex> argument is either a string or a precompiled regular expression
that identifes the variable in the template and captures the variables name.

The default is suitable for interpolating variables appearing in templates in
square brackets with names composed of [a-zA-Z0-9_].

=head3 _args

by specifying a true C<_args> argument, the behavior of a fill subroutine
can be changed on-the-fly, by modifying the %fill_args (or whatever you have
fill set to) hash in your package. There is a slight performance penalty for
using this feature.

=head2 EXPORT

=head3 the fill subroutine

TipJar::Template::fill exports one subroutine, called C<fill> by
default, that takes one or two arguments.  The first argument
is the template to be filled, and the second, when provided, is
a reference to a hash from which to pull the replacement variables.

The name can be set by specifying
a C<fill> use-time argument.  It is thus possible to
associate different target regular expressions and different
variable sources with differently named fill subroutines.

=head3 %fill_args

when a use-time argument called '_args' is provided
a true value, the resulting fill subroutine will respond to
changes made in a %fill_args hash that is exported to the
caller's name space, with 'fill' replaced with whatever the
fill argument was set to,
in case you want to change your interpolation regex on-the-fly,
or change the default data source on-the-fly without creating
a new fill subroutine.

By default, the regex and the default data source do not change.

=head2 INTERNALS

There's a TipJar::Template::fill::makesub subroutine, that
takes two arguments, a regular expression and a hash reference,
and provides an anonymous fill subroutine.  If you are of
an object-oriented bent, you could consider it the constructor.

=head1 SEE ALSO

A very nice article comparing popular templating systems
is available at
http://perl.apache.org/docs/tutorials/tmpl/comparison/comparison.html

=head1 Why bother?

Beginners to Perl may not be comfortable with regular expression
writing.  Perrin Harkins throws away writing a substitution expression
at the beginning of his article as something that authors of
templating systems start with, yet novice Perl coders who just
want data interpolation but are not comfortable with the nuances of
Perl's substitution operator are at this time presented with an
abundance of object-oriented systems that do far more than
they need.

TipJar::Template::fill abstracts repeated similar
and visually busy substitution
commands into a one-word subroutine.  So you don't have to.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by David L. Nicol

This library is free software; you may redistribute and/or modify
it under the same terms as Perl.

=head2 why TipJar::

TipJar is a service mark of TipJar LLC, a limited liability
corporation registered in Missouri, USA, that has been providing
practical infrastructure since 1996.

=cut

