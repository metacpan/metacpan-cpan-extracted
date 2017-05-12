package XML::Parser::Expat::Dispatched;
use strict;
# ABSTRACT: Automagically dispatches subs to XML::Parser::Expat handlers
use true;
use parent 'XML::Parser::Expat';
use Carp;

our $VERSION = 0.952;


sub new {
  my($package) = shift;
  my ($opts, %dispatch, $s);
  { $opts = 
      {Start         => 'Start',
       End           => 'End',
       handler       => 'handler',
       #transform_tag,
       #transform_suffix,
       #transform,
      };
    if ($package->can('config_dispatched')) {
      my $config_opts = $package->config_dispatched;
      $opts->{$_} = $config_opts->{$_} foreach keys %$config_opts;
      if (exists $opts->{transform}) {
	foreach (qw|transform_tag transform_suffix|) {
	  carp "both $_ and transform defined in config_dispatched, taking transform"
	    if exists $opts->{$_};
	  $opts->{$_} = $opts->{transform} unless defined $opts->{$_}; 
	  # since this is the only place where i would need 5.01 syntax i don't use it.
	}
      }
    }
  }

  {
    my %opt_reversed = (map {$opts->{$_}, $_} qw|Start End handler|);
    no strict 'refs';		# perlcritic doesn't like this
    while (my ($symbol_table_key, $val) = each %{ *{ "$package\::" } }) {
      local *ENTRY = $val;
      if (defined $val
	  and defined *ENTRY{ CODE }
	  and $symbol_table_key =~ /^(?:(?'what'$opts->{Start}|$opts->{End})_?(?'who'.*)
				    |(?'who'.*?)_?(?'what'$opts->{handler}))$/x) {
	my $what = $opt_reversed{$+{what}};
	carp "the sub $symbol_table_key overrides the handler for $dispatch{$what}{$+{who}}[1]"
	  if exists $dispatch{$what}{$+{who}};
	$dispatch{$what}{$+{who}}= [*ENTRY{ CODE }, $symbol_table_key];
      }
    }
  }
  $s = bless(XML::Parser::Expat->new(@_),$package);
  {# generating the dispatche from the methods
    my %real_dispatch;
    foreach my $se (qw|Start End|) {
      if (exists $dispatch{$se}){
	if (exists $opts->{transform_suffix}){
	  foreach (keys %{$dispatch{$se}}) {
	    my $new_key= $opts->{transform_suffix}($s, $_);
	    if ($_ ne $new_key) {
	      carp "$dispatch{$se}{$new_key}[1] and $dispatch{$se}{$_}[1] translate to the same handler"
		if exists $dispatch{$se}{$new_key};
	      $dispatch{$se}{$new_key} = $dispatch{$se}{$_};
	      delete $dispatch{$se}{$_};
	    }
	  }
	}
	if (exists $opts->{transform_tag}) {
	  $real_dispatch{$se} = sub {
	    my $new_tagname = $opts->{transform_tag}(@_[0,1]);
	    if ($dispatch{$se}{$new_tagname}) {
	      $dispatch{$se}{$new_tagname}[0](@_);
	    } elsif (exists $dispatch{$se}{''}) {
	      $dispatch{$se}{''}[0](@_);
	    }
	  };
	} else {
	  $real_dispatch{$se} = sub {
	    if ($dispatch{$se}{$_[1]}) {
	      $dispatch{$se}{$_[1]}[0](@_);
	    } elsif (exists $dispatch{$se}{''}) {
	      $dispatch{$se}{''}[0](@_);
	    }
	  };
	}
      }
    }

    foreach (keys %{$dispatch{handler}}) {
      $real_dispatch{$_} = $dispatch{handler}{$_}[0];
    }

    $s->setHandlers(%real_dispatch);
  }
  return $s;
}

__END__

=pod

=head1 NAME

XML::Parser::Expat::Dispatched - Automagically dispatches subs to XML::Parser::Expat handlers

=head1 VERSION

version 0.952

=head1 SYNOPSIS

    package MyParser;
    use parent XML::Parser::Expat::Dispatched;
    
    sub Start_tagname{
      my $self = shift;
      say $_[0], $self->original_tagname;
    }
    
    sub End_tagname{
      my $self=shift;
      say "$_[0] ended";
    }
    
    sub Char_handler{
      my ($self, $string) = @_;
      say $string;
    }

    sub config_dispatched{{
      transform => sub{lc $_[1]}
    }}

     package main;
     my $p = MyParser->new;
     $p->parse('<Tagname>tag</Tagname>');
     # prints
     # Tagname<Tagname>
     # tag
     # Tagname ended

=head1 DESCRIPTION

This package provides a C<new> method that produces some dispatch methods for  L<XML::Parser::Expat/set_handlers>.

If you were using XML::Parser::Expat for parsing your XML, you'd probably end up with something like this:

  use XML::Parser::Expat;
  my $p = XML::Parser::Expat->new();
  $p->set_handlers(Start => \&sh,
                   End   => \&eh,
                   Char => sub{print "in String"});

  sub sh{
    my $p = shift;
    given($_[0]){
      when('employer'){...}
      when('employee'){...}
      when('date'){...}
    }
  }

  sub eh{
    my $p = shift;
    given($_[0]){
      when('employer'){...}
      when('employee'){...}
      when('date'){...}
    }
  }

With this Module your dispatching will be done based on your methods:

  package myexpatparser;

  use parent 'XML::Parser::Expat::Dispatched';

  sub Start_employer{...}
  sub Start_employee{...}
  sub Start_date{...}

  sub End_employer{...}
  sub End_employee{...}
  sub End_date{...}

  sub Char_handler{print "in String"}

  package main;
  use myexpatparser;
  myexpatparser->new;

I wrote this module because i needed a quite low-level XML-Parsing library that had an C<original_string> method. So if you need some higher level library, I'd really suggest to look at the L</SEE ALSO> section.

Since your package will inherit L<XML::Parser::Expat|XML::Parser::Expat> be prepared to call it's C<release>-method if you write your own C<DESTROY>-method.

=head1 HANDLERS

Available handlers:

The underscore in the subroutine names is optional for all the handler methods.
The arguments your subroutine gets called with, are the same as those for the handlers from L<XML::Parser::Expat|XML::Parser::Expat>.

=head2 Start_I<tagname>

Will be called when a start-tag is encountered that matches I<tagname>.
If I<tagname> is not given (when your sub is called C<Start> or C<Start_>), it works like a default-handler for start tags.

=head2 End_I<tagname>

Will be called when a end-tag is encountered that matches I<tagname>.
If I<tagname> is not given (when your sub is called C<End> or C<End_>), it works like a default-handler for end tags.

=head2 I<Handler>_handler

Installs this subroutine as a handler for L<XML::Parser::Expat|XML::Parser::Expat>.
You can see the Handler names on L<XML::Parser::Expat/set_handlers>. Notice that if you try to define a handler for Start or End,
they will be interpreted as C<Start> or C<End> handlers for C<handler>-tags, use subs called C<Start> or C<End> instead.

=head2 config_dispatched

This handler is special: You can return a hashref with configuration options for config_dispatched.

Available options and default values are:

=over 4

=item *

I<Start>[Start]: Part of the sub name that marks a Start handler

=item *

I<End>[End]: Part of the sub name that marks an End handler

=item *

I<handler>[handler]: Part of the sub name that marks that this is a handler subroutine other than Start and End

=back

These options are for transforming the subroutine names and the tagnames.
They always get called with the parser and the string to transform as arguments.
(Think C<transform_tag($tagname) eq transform_suffix($subname =~ /Start_?(.*)/)>)

=over 4

=item *

I<transform_tag>: Will be called for each tag. The return value of this sub will be compared to the subname prefixes.

=item *

I<transform_suffix>: Will be called for each subroutine name. The retrun value of this sub will be compared to the tagnames.

=item *

I<transform>: Sets both C<transform_tag> and C<transform_suffix> to the given value.

=back

Some Examples:

   sub config_dispatched{{
     Start     => 'begin',
     End       => 'finish',
     transform => sub{lc $_[1]}, # now matching is case insensitive
   }}

   sub config_dispatched{{
     transform_tag => sub{return $_[1]=~/:([^:]+)$/ ? $1: $_[1]},
     # try to discard namespace prefixes
   }}

   sub config_dispatched{{
     transform_suffix => sub{my $_ =  $_[1]; s/__/:/g; s/_/-/g; $_},
     # try to work around the fact that `-' and `:' aren't allowed characters for perl subroutine names
   }}

Note that the allowed characters for perl's subroutine names
and XML-Identifiers aren't the same, so you might want to use the default handlers or C<transform_gi> in some cases (namespaces, tagnames with a dash).

=head1 DIAGNOSTICS

  the sub %s1 overrides the handler for %s2

You most probably have two subroutines that
have the same name exept one with an underscore and one without.
The warning issued tells you wich of the subroutines will be used as a handler.
Since the underlying mechanism is based on the C<each> iterator, this behavior
can vary from time to time running, so you might want to change your sub names.

  %s1 and %s2 translate to the same handler

There is an sub called C<%s1> that translates to the same handler as a sub C<%s2> after applying C<transform_gi>. The sub C<%s1> will be used.

=head2 INTERNALS

The following things might break this module so be aware of them:

=over 4



=back

* Your parser will be a L<XML::Parser::Expat|XML::Parser::Expat> so consider checking the methods of this class if you write methods other than handler methods
.
* Using C<AUTOLOAD> without updating the symbol table before C<new> is called.

* Calling C<set_handlers> on your parser. This module calls C<set_handlers> and if you do, you overwrite the handlers it had installed (why do you use this module anyway?).

=head1 SEE ALSO

Obviously L<XML::Parser::Expat|XML::Parser::Expat> as it is a simple extension of that class.

You also should chekout these modules for parsing XML:

=over 4

=item *

L<XML::Twig>

=item *

L<XML::LibXML>

=item *

L<XML::TokeParser>

=item *

Many other modules in the XML::Parser Namespace

=back

=head1 AUTHOR

Patrick Seebauer <patpatpat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Patrick Seebauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
