use 5.008;
use strict;
use warnings;

use Moo 1.000006 ();
use MooX::Struct 0.009 ();
use Throwable::Error 0.200000 ();

{
	package Throwable::Factory;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.007';
	
	our @SHORTCUTS;
	
	use MooX::Struct -retain,
		Base => [
			-class   => \'Throwable::Factory::Struct',
			-extends => ['Throwable::Factory::Base'],
			-with    => ['Throwable', 'StackTrace::Auto'],
			'$message',
		],
	;
	
	sub import
	{
		my $class  = shift() . '::Struct';
		unshift @_, $class;
		goto \&MooX::Struct::import;
	}
	
	{
		package Throwable::Taxonomy::Caller;
		use Moo::Role;
		push @SHORTCUTS, __PACKAGE__;
	}
	
	{
		package Throwable::Taxonomy::Environment;
		use Moo::Role;
		push @SHORTCUTS, __PACKAGE__;
	}
	
	{
		package Throwable::Taxonomy::NotImplemented;
		use Moo::Role;
		push @SHORTCUTS, __PACKAGE__;
	}
	
	Base;
}

{
	package Throwable::Factory::Base;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.007';
	
	use Data::Dumper ();
	use Moo;
	use namespace::clean;
	extends 'MooX::Struct';
	
	sub description { 'Generic exception' }
	sub error       { shift->message }
	sub package     { shift->stack_trace->frame(0)->package }
	sub file        { shift->stack_trace->frame(0)->filename }
	sub line        { shift->stack_trace->frame(0)->line }
	
	sub BUILDARGS
	{
		my $class = shift;
		return +{} unless @_;
		unshift @_, 'message' if @_ % 2 and not ref $_[0];
		$class->SUPER::BUILDARGS(@_);
	}
	
	sub TO_STRING
	{
		local $Data::Dumper::Terse = 1;
		local $Data::Dumper::Indent = 0;
		local $Data::Dumper::Useqq = 1;
		local $Data::Dumper::Deparse = 0;
		local $Data::Dumper::Quotekeys = 0;
		local $Data::Dumper::Sortkeys = 1;
		
		my $self = shift;
		my $str  = $self->message . "\n\n";
		
		for my $f ($self->FIELDS) {
			next if $f eq 'message';
			my $v = $self->$f;
			$str .= sprintf(
				"%-8s = %s\n",
				$f,
				ref($v) ? Data::Dumper::Dumper($v) : $v,
			);
		}
		$str .= "\n";
		$str .= $self->stack_trace->as_string;
		return $str;
	}
}

{
	package Throwable::Factory::Struct::Processor;
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.007';
	
	use Moo;
	use Carp;
	use namespace::clean;
	extends 'MooX::Struct::Processor';
	
	has '+base' => (
		default => sub { Throwable::Factory::Base },
	);
	
	sub process_meta
	{
		my ($self, $klass, $name, $value) = @_;
		
		if ($name !~ /^-(isa|extends|with|class)$/) {
			my $k = substr $name, 1;
			my @matches = grep /::$k$/i, @Throwable::Factory::SHORTCUTS;
			croak "Shortcut '$name' has too many matches: @matches" if @matches > 1;
			croak "Shortcut '$name' has no matches" if @matches < 1;
			$name  = '-with';
			$value = \@matches;
		}
		
		$self->SUPER::process_meta($klass, $name, $value);
	}
	
	# Allow make_sub to accept Exception::Class-like hashrefs.
	sub make_sub
	{
		my ($self, $name, $proto) = @_;
		if (ref $proto eq 'HASH')
		{
			my %proto = %$proto;
			$proto = [];
			
			if (defined $proto{isa}) {
				my $isa = delete $proto{isa};
				push @$proto, -extends => [$isa];
			}
			if (defined $proto{description}) {
				my $desc = delete $proto{description};
				push @$proto, description => sub { $desc };
			}
			if (defined $proto{fields}) {
				my $fields = delete $proto{fields};
				push @$proto, ref $fields ? @$fields : $fields;
			}
			
			if (keys %proto) {
				croak sprintf(
					"Exception::Class-style %s option not supported",
					join('/', sort keys %proto),
				);
			}
		}
		return $self->SUPER::make_sub($name, $proto);
	}
}

1;

__END__

=head1 NAME

Throwable::Factory - lightweight Moo-based exception class factory

=head1 SYNOPSIS

   use Throwable::Factory
      GeneralException => undef,
      FileException    => [qw( $filename )],
      NetworkException => [qw( $remote_addr $remote_port )],
   ;
   
   # Just a message...
   #
   GeneralException->throw("Something bad happened");
   
   # Or use named parameters...
   #
   GeneralException->throw(message => "Something awful happened");

   # The message can be a positional parameter, even while the
   # rest are named.
   #
   FileException->throw(
      "Can't open file",
      filename => '/tmp/does-not-exist.txt',
   );

   # Or, they all can be a positional using an arrayref...
   #
   NetworkException->throw(["Timed out", "11.22.33.44", 555]);

=head1 DESCRIPTION

C<Throwable::Factory> is an L<Exception::Class>-like exception factory
using L<MooX::Struct>.

All exception classes built using C<Throwable::Factory> are L<MooX::Struct>
structs, but will automatically include a C<message> attribute, will compose
the L<Throwable> and L<StackTrace::Auto> roles, and contain the following
convenience methods:

=over

=item C<error>

Read-only alias for the C<message> attribute/field.

=item C<package>

Get the package for the first frame on the stack trace.

=item C<file>

Get the file name for the first frame on the stack trace.

=item C<line>

Get the line number for the first frame on the stack trace.

=back

They provide a C<BUILDARGS> method which means that if their constructor
is called with an odd number of arguments, the first is taken to be the
message, and the rest named parameters.

Additionally, the factory can be called with Exception::Class-like hashrefs
to describe the exception classes. The following two definitions are
equivalent:

   # MooX::Struct-style
   use Throwable::Factory FooBar => [
      -extends => ['Foo'],
      qw( foo bar ),
   ];
   
   # Exception::Class-style
   use Throwable::Factory FooBar => {
      isa    => 'Foo',
      fields => [qw( foo bar )],
   };

=head2 Exception Taxonomy

It can be useful to divide your exceptions into broad categories to allow
your caller to catch great swathes of exceptions easily, including new
exceptions you add in future versions of your module.

Throwable::Factory includes three exception categories that you may use
for this purpose. These are implemented as role packages with no associated
methods, so can be tested for using the C<DOES> method (see L<UNIVERSAL>).

=over

=item *

Throwable::Taxonomy::Caller - the caller passed bad or unexpected
parameters.

=item *

Throwable::Taxonomy::Environment - a problem was found in the software's
operating environment; e.g. network connection unavailable, lack of
disk space.

=item *

Throwable::Taxonomy::NotImplemented - the caller requested a feature that
is not currently implemented, but may be in the future.

=back

It is easy to apply these roles to your exception classes:

   use Throwable::Factory
      ErrTooBig   => [qw( $maximum! -notimplemented )],
      ErrTooSmall => [qw( $minimum! -notimplemented )],
   ;
   use Try::Tiny::ByClass;
   
   sub calculation
   {
      my $input = shift;
      if ($input > 12) {
         ErrTooBig->throw(
            "Inputs over 12 are not currently supported",
            maximum => 12,
         );
      }
      ...;
   }
   
   try {
      calculation(13);
   }
   catch_case [
      +ErrTooBig                            => sub { warn "Too big!" },
      +ErrTooSmall                          => sub { warn "Too small!" },
      "Throwable::Taxonomy::NotImplemented" => sub { warn $_ },
   ];

The C<< -notimplemented >> shortcut expands to
C<< -with => ['Throwable::Taxonomy::NotImplemented'] >>. Similarly
C<< -caller >> and C<< -environment >> shortcuts exist.

(Note the plus signs in the C<catch_case> above; this ensures C<ErrTooBig>
and C<ErrToString> are not auto-quoted by the fat comma.)

=head1 CAVEATS

Exceptions built by this factory inherit from L<MooX::Struct>; see the
B<CAVEATS> section from the MooX::Struct documentation.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Throwable-Factory>.

=head1 SEE ALSO

Exceptions built by this factory inherit from L<MooX::Struct> and compose
the L<Throwable> and L<StackTrace::Auto> roles.

This factory is inspired by L<Exception::Class>, and for simple uses should
be roughly compatible.

Use L<Try::Tiny>, L<Try::Tiny::ByClass> or L<TryCatch> if you need a
try/catch mechanism.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

