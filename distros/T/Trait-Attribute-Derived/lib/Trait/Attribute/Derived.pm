package Trait::Attribute::Derived;

use 5.008;
use strict;

BEGIN {
	$Trait::Attribute::Derived::AUTHORITY = 'cpan:TOBYINK';
	$Trait::Attribute::Derived::VERSION   = '0.005';
}

use MooseX::Role::Parameterized;
use Sub::Install 'install_sub';
use Sub::NonRole;
use namespace::autoclean;

my @saved;
sub make_trait :NonRole
{
	my ($pkg, %args) = @_;
	push @saved, $pkg->meta->generate_role(parameters => \%args);
	return $saved[-1]->name;
}

sub import :NonRole
{
	my $pkg    = shift;
	my $caller = caller;
	while (@_)
	{
		my $name  = shift;
		my $trait = $pkg->make_trait(%{+shift});
		install_sub {
			into => $caller,
			as   => $name,
			code => sub () { $trait },
		}
	}
}

parameter processor => (
	is        => 'ro',
	isa       => 'CodeRef',
	required  => 1,
);

parameter fields => (
	is        => 'ro',
	isa       => 'HashRef',
	default   => sub{ +{} },
);

parameter is => (
	is        => 'ro',
	isa       => 'Str',
	default   => 'ro',
);

parameter source => (
	is        => 'ro',
	isa       => 'Str',
	required  => 0,
	predicate => 'has_source',
);

role {
	my $p  = shift;
	$p->fields->{source} ||= 'Str' unless $p->has_source;
	my @fields = keys %{ $p->fields };
	
	has postprocessor => (is => 'ro', isa => 'CodeRef', predicate => 'has_postprocessor');
	
	for my $attr (@fields)
	{
		has $attr => (is => 'ro', isa => $p->fields->{$attr});
	}
	
	method derived_from => sub
	{
		my $attr = shift;
		return $attr->source
			if exists $p->fields->{source} && defined $attr->source;
		return $p->source;
	};
	
	method derived_attribute_builder => sub
	{
		my $attr = shift;
		
		my %data        = map { ; $_ => $attr->$_ } @fields;
		my $processor   = $p->processor;
		my $postprocess = $attr->postprocessor;
		
		my $source = defined $data{source} ? $data{source} : $p->source
			or Moose->throw_error("No source attribute given for derived attribute ${\ $attr->name }");
		
		return sub
		{
			my $self = shift;
			local %_ = %data;
			local $_ = $self->$source;
			$_ = $self->$processor($_, +{%data});
			return $_ unless $postprocess;
			return $self->$postprocess($_, +{%data});
		};
	};
	
	before _process_options => sub
	{
		my ($meta, $name, $spec) = @_;
		$spec->{is}      = $p->is         unless exists $spec->{is};
		$spec->{lazy}    = 1              unless exists $spec->{lazy};
		$spec->{builder} = "_build_$name" unless exists $spec->{builder};
	};
	
	after attach_to_class => sub
	{
		my $attr   = shift;
		my $class  = $attr->associated_class;
		return if $class->has_method($attr->builder);
		
		$class->add_method($attr->builder, $attr->derived_attribute_builder);
	};
};

1;

__END__

=head1 NAME

Trait::Attribute::Derived - trait for lazy-built Moose attributes that are derived from another attribute

=head1 SYNOPSIS

   use strict;
   use warnings;
   use Test::More;
   
   {
      package Person;   
      use Moose;
      
      use Trait::Attribute::Derived Split => {
         fields    => { segment => 'Num' },
         processor => sub { (split)[$_{segment}] },
      };
      
      has full_name => (
         is            => 'ro',
         isa           => 'Str',
         required      => 1,
      );
      has first_name => (
         traits        => [ Split ],
         source        => 'full_name',
         segment       => 0,
      );
      has last_name => (
         traits       => [ Split ],
         source        => 'full_name',
         segment      => -1,
      );
      has initial => (
         traits        => [ Split ],
         source        => 'full_name',
         segment       => 0,
         postprocessor => sub { substr $_, 0, 1 },
      );
   }
   
   my $bob = Person->new(full_name => 'Robert Redford');
   is($bob->first_name, 'Robert');
   is($bob->initial, 'R');
   is($bob->last_name, 'Redford');
   done_testing;

=head1 DESCRIPTION

It is quite common in L<Moose> to have one attribute derived from another
via lazy builders. Often you will have several which are very similar:

   has first_name => (
      is           => 'ro',
      lazy         => 1,
      builder      => '_build_first_name',
   );
   
   sub _build_first_name {
      my $self = shift;
      (split /\s/, $self->full_name)[0];
   }
   
   has last_name => (
      is           => 'ro',
      lazy         => 1,
      builder      => '_build_last_name',
   );
   
   sub _build_last_name {
      my $self = shift;
      (split /\s/, $self->full_name)[-1];
   }

Other examples might be an attribute holding an XML DOM tree where several
attributes are lazily built using XPath queries; or an attribute holding a
DBI database handle where several attribues are lazily built by querying
the database; or where one attribute holds the binary contents of a file,
and others are fields extracted using C<unpack>.

Trait::Attribute::Derived allows you to automate some of this, reducing
duplicated code.

Trait::Attribute::Derived is a trait for Moose attributes; it a parameterized
role. The first step when using it is to create a variant of the role with
the parameters filled in.

   use Trait::Attribute::Derived Split => {
      fields    => { segment => 'Num' },
      processor => sub { (split)[$_{segment}] },
   };

This defines a variant called C<Split>. The C<processor> coderef is the
template for deriving a lazily built attribute from a source attribute.
Within this coderef, the special global C<< $_ >> is set to the value of
the source attribute, and the special global C<< %_ >> hash contains a
set of other fields useful in deriving the lazily built attributes.

Using our example from the SYNOPSIS, C<< $_ >> will be the string
C<< "Robert Redford" >> and C<< %_ >> will be a hash C<< (segment => 0) >>
when building the C<first_name> or C<< (segment => -1) >> when building
the C<last_name>.

If you'd rather not use magic global variables, the coderef is also passed
as arguments (C<< @_ >>): C<< $self >>, the source attribute value, and a
refernce to that hash.

The C<fields> hashref defines which fields will be available in C<< %_ >>
plus a type constraint for each.

Then when we define the attribute itself:

   has first_name => (
      traits        => [ Split ],
      source        => 'full_name',
      segment       => 0,
   );

First of all we reference the C<Split> trait variant; secondly we tell it
what source attribute to derive the first name from (C<full_name>); lastly
we tell it what segment of the name we want. This corresponds to the
C<segment> field we defined when creating the trait variant.

Here's another example:

   {
      package Text;
      use Moose;
      
      use Trait::Attribute::Derived FindReplace => {
         fields => {
            find    => 'RegexpRef',
            replace => 'Str',
         },
         processor => sub {
            my ($self, $value, $fields) = @_;
            $value =~ s/$fields->{find}/$fields->{replace}/g;
            return $value;
         },
      };
      
      has plain => (
         is       => 'ro',
         isa      => 'Str',
      );
      has vowels_only => (
         traits   => [ FindReplace ],
         source   => 'plain',
         find     => qr{[^AEIOU]}i,
         replace  => '',
      );
      has no_vowels  => (
         traits   => [ FindReplace ],
         source   => 'plain',
         find     => qr{[AEIOU]}i,
         replace  => '',
      );
   }

An alternative to setting C<source> on each derived attribute is to set it
once when creating the trait variant:

   use Trait::Attribute::Derived FindReplace => {
      source    => 'plain',
      fields    => { ... },
      processor => sub { ... },
   };

One last detail from the SYNOPSIS is postprocessing. An attribute can define
a C<postprocessor> coderef that executes after the C<processor> coderef. This
takes the same parameters as the C<processor> coderef (and has access to
C<< $_ >> and C<< %_ >>) but rather than operating on the source attribute,
operates on the output of the C<processor>.

   has first_three_vowels_only => (
      traits   => [ FindReplace ],
      source   => 'plain',
      find     => qr{[^AEIOU]}i,
      replace  => '',
      postprocessor => sub { substr($_, 0, 3) },
   );

=head2 Introspection

   use 5.010;
   
   # say "full_name"
   say Person->meta->get_attribute('first_name')->derived_from;
   
   # say "0"
   say Person->meta->get_attribute('first_name')->segment;
   
   # say "1"
   say Person->meta->get_attribute('initial')->has_postprocessor;

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Trait-Attribute-Derived>.

=head1 SEE ALSO

L<Moose::Cookbook::Meta::WhyMeta>,
L<Moose::Cookbook::Meta::Labeled_AttributeTrait>,
L<Moose::Meta::Attribute>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

