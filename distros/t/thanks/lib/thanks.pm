package thanks;

$thanks::USELESS_VARIABLE = "
use 5.005;
" unless $thanks::USELESS_VARIABLE;

BEGIN {
	$thanks::AUTHORITY = 'cpan:TOBYINK' unless $thanks::AUTHORITY;
	$thanks::VERSION   = '0.005'        unless $thanks::VERSION;
}

sub _module_notional_filename
{
	(my $name = shift) =~ s!(::|')!/!g;
	return $name . q[.pm];
}

sub unimport
{
	my $class = shift;
	my @caller = caller(0);
	@_ = $caller[0] unless @_;
	my $file = $caller[1];
	for (@_)
		{ $INC{ _module_notional_filename($_) } = $file }
}

1;

__END__

=head1 NAME

thanks - inline packages easily

=head1 SYNOPSIS

	BEGIN {
		package My::Package;
		no thanks;
		# everything else goes here
	};
	
	use My::Package;  # No error message about missing
	                  # file "My/Package.pm".
	                  #

Or:

	BEGIN {
		package My::Package;
		# everything else goes here
	};
	
	no thanks qw( My::Package Another::Package Yet::Another::Package );
	
	use My::Package;  # No error message about missing
	                  # file "My/Package.pm".
	                  #

=head1 ELEVATOR PITCH

Defining multiple Perl packages in the same file can be fraught with
difficulty. C<< no thanks >> makes it a bit easier. To define a package
just do...

	BEGIN {
		package My::Package;
		no thanks;
		# everything else goes here
	};

Then everything should more or less work exactly if My::Package had
been a package defined in an external file and loaded like:

	use My::Package ();

(The exception being that the inlined My::Package can see file-scoped
lexicals.)

Why define multiple packages in the same file? Because often namespacing
concerns and code organisation concerns don't align. For example, you
have many small packages which it is important don't share namespaces,
but you want to be able to edit them all in the same window/tab of your
editor.

=head1 DESCRIPTION

This module asks Perl politely not to load a module you don't want loading.
It's just a polite request; we're not forcing Perl to do anything it doesn't
want to. And if the module is already loaded, then we won't try to unload
it or anything like that.

Specifically, Perl's C<< use Module::Name >> syntax does two things. It reads,
compiles and executes C<< Module/Name.pm >>, and calls the class method
C<< Module::Name->import >>. This module is designed to prevent the first
thing happening, not the second thing.

How does it work? Perl keeps a record of what modules have already been
loaded in the C<< %INC >> global hash, to avoid reloading them. This module
just adds an entry to that hash to trick Perl into thinking that a module
has already been loaded.

C<thanks> is a deliberately light-weight module. It has no dependencies (not
even L<strict> or L<warnings>) and is believed to work in any release of Perl
5. (The installation and testing scripts have more dependencies, but if push
comes to shove, you can manually copy thanks.pm to an appropriate location.)

=head2 Methods

=over

=item C<< unimport >>

	no thanks @LIST;

If C<< @LIST >> is empty, then the caller package is assumed.

=back

=head2 Use Case 1: Multiple Packages in the Same File

Perl's C<< use >> keyword muddies the distinction between packages (which
are just namespaces) and modules (which are just files). Sometimes you wish
to define two packages (say C<< My::Package >> and
C<< My::Package::Helper >>) in the same file (say C<< My/Package.pm >>). If
anybody tries to load C<< My::Package::Helper >> with C<use>, then they'll
get an error message. If C<< My/Package.pm >> includes:

	no thanks 'My::Package::Helper';

then this will prevent C<< use My::Package::Helper >> from throwing an error
message, provided C<< My/Package.pm >> is already loaded.

=head2 Use Case 2: You Really Want to Prevent a Module from Loading

It's quite a messy thing to do, but if you really need to silently prevent
a module from being loaded, then C<< no thanks >> will do the trick. Just
make sure you do it early.

This is almost always a bad idea.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=thanks>.

=head1 SEE ALSO

L<again>,
L<Module::Reload>,
L<Class::Unload>.

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

