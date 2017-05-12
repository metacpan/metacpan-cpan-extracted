package only::matching;

=pod

=head1 NAME

only::matching - Check that two Perl files are version-locked

=head1 SYNOPSIS

At the start of your application's main module...

  package Foo;
  
  use strict;
  use vars qw{$VERSION};
  BEGIN {
      $VERSION = '1.00';
  }

  # ...code...

And at the top of your front-end script that loads the module...

  #!/usr/bin/perl
  
  use strict;
  use vars qw{$VERSION};
  BEGIN {
      $VERSION = '1.00';
  }
  
  # Load our matching module
  use only::matching 'Foo';
  
  # ...code...

=head1 DESCRIPTION

The L<only> module provides a great deal of interesting and rich
functionality, allowing you to install multiple copies of modules
and limit the version of a module you load to various arbitrary
patterns.

However, installing it creates some additional directories to your
library tree for the multi-version support, and you have to be
explicit about the versions you want to be compatible with.

This means for the case where you have a script and a module
and it is important that no matter what happens with system paths
or @INC paths, the script B<always> loads the matching module,
you need to change the code each revision to refer to the new
version, or you have to do something like...

  use only 'Foo' => $VERSION;

Like L<only::latest>, B<only::matching> is a task-specific version
of L<only> for the specific case of having version-locked script
to module loading.

Instead of the above, you say...

  use only::matching 'Foo';

... and you are guaranteed to get the correctly matching module
version.

Because it only needs such limited and specific functionality
B<only::matching> also removes the multiversion support and is
contained entirely in one small .pm file, to make bundling it a
little easier as well.

=head2 Providing Params

The syntax for B<only::matching> is the same as for L<only>,
except without the version number string.

Thus to load a module with default imports:

  # These are equivalent
  use Foo;
  use only::matching 'Foo';

To load a module passing params

  # These are also equivalent
  use Foo => 'bar', 'baz';
  use only::matching Foo => 'bar', 'baz';

To load a module explicitly without calling import

  # And these are equivalent
  use Foo ();
  use only::matching 'Foo', [];

Other than this, there's very little that you need to know.

=cut

use 5.005;
use strict;
use Carp ();
use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

sub import {
	my $class = shift;

	# What are we loading
	my($mod, @imports) = @_;
	@imports = () unless @imports;

	# What called us
	my $pkg = caller();

	SCOPE: {
		# eval sometimes interferes with $!
		local ($!);

		if ( @imports == 1 and $imports[0] =~ /^\d+(?:\.\d+)?$/ ) {
			# probably a version check.  Perl needs to see the bare number
			# for it to work with non-Exporter based modules.
			eval <<"END_PERL";
package $pkg;
use $mod $imports[0];
END_PERL

		} elsif ( @imports == 1 and ref($imports[0]) eq 'ARRAY' and  @{$imports[0]} == 0 ) {
			# Called with [], which turns into "use module ();"
			eval <<"END_PERL";
package $pkg;
use $mod ();
END_PERL

		} else {
			# Just a regular call, pass on imports
			eval <<"END_PERL";
package $pkg;
use $mod \@imports;
END_PERL
		}
	}

	# Rethrow any errors
	Carp::croak($@) if $@;

	# Get the versions of caller and module via official channels
	my $pkg_version = $pkg->VERSION;
	my $mod_version = $mod->VERSION;

	# Check that both exist and are the same thing.
	# Since they should be IDENTICAL, check with BOTH of == and eq
	unless ( defined $pkg_version ) {
		Carp::croak("Calling package $pkg does not have a version");
	}
	unless ( defined $mod_version ) {
		Carp::croak("$mod does not have a version");
	}
	unless ( ref($pkg_version) eq ref($mod_version) ) {
		Carp::croak("Caller $pkg and module $mod version ref type mismatch");
	}
	local $^W = 0;
	unless ( $pkg_version eq $mod_version and $pkg_version == $mod_version ) {
		Carp::croak("$mod version $mod_version does not match caller $pkg $pkg_version");
	}

	# Looks good
	return 1;
}

1;

=pod

=head1 SUPPORT

This module is stored in an Open Repository at the following address.

L<http://svn.ali.as/cpan/trunk/only-matching>

Write access to the repository is made available automatically to any
published CPAN author, and to most other volunteers on request.

If you are able to submit your bug report in the form of new (failing)
unit tests, or can apply your fix directly instead of submitting a patch,
you are B<strongly> encouraged to do so as the author currently maintains
over 100 modules and it can take some time to deal with non-Critcal bug
reports or patches.

This will guarentee that your issue will be addressed in the next
release of the module.

If you cannot provide a direct test or fix, or don't have time to do so,
then regular bug reports are still accepted and appreciated via the CPAN
bug tracker.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=only-matching>

For other issues, for commercial enhancement or support, or to have your
write access enabled for the repository, contact the author at the email
address above.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<only>, L<only::latest>

=head1 COPYRIGHT

Copyright 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
