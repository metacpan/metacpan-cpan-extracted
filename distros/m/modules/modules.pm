package modules;

our $VERSION = '0.04';

our $DEBUG = 0;

use Carp;

our $force = 1;

sub import
{
	my $package = shift;

	my $context = scalar caller;

	my @failed;

		for ( @_ )
		{
			if( /^([\-\+])force$/ )
			{
				$force = ($1 eq '-') ? 0 : 1;

				warn "force turned $force\n" if $DEBUG;

				next;
			}

			if( ref( $_ ) eq 'HASH' )
			{
				foreach my $key ( keys %$_ )
				{
					printf "Hash: LOADING %s with %s\n", $key, $_->{$key} if $DEBUG;

					eval "package $context; use $key ".$_->{$key};

					if( $@ )
					{
						push @failed, $key;

						carp "Can't use module '$key'. $@";
					}
				}

				next;
			}

			eval "package $context; use $_";

			if( $@ )
			{
				push @failed, $_;

				carp "Can't use module '$_'. $@";
			}
		}

	if( @failed && $force )
	{
		use CPAN;

		CPAN::Shell->install( @failed );
	}
}

# Preloaded methods go here.

1;
__END__

=head1 NAME

modules - loads several modules with single use-command

=head1 SYNOPSIS

  use modules qw(strict warnings 5.006 Data::Dumper);

		# and now we can use i.e. Data::Dumper

	print Dumper { one => 1, two => 2 };

=head1 DESCRIPTION

If you are bored by multiple 'use'-statement and asked why you cannot load
several modules with one single 'use'-command: You will love 'modules', because
thats what it does.

Ironically 'modules' is a module. The name was choosen, because the 'use modules'
construct sounds self-explanatory.

=head1 OPTIONS
Following keywords can an be interspersed into the import list. They must be prepended
with an '-' (for turning the option OFF) or '+' (ON). The option may be turned multiple
times ON/OFF.

=over 4

=item force

This options controls whether modules which failed during loading become automatically
loaded from CPAN (if available).

Default: ON.

Example:

	use modules qw(strict warnings -force IO::Extended +force Class::Maker);

	(Meaning: If 'IO::Extended' is not loadable, do not try to install it via CPAN).

BTW the example is semantically identical to:

	use modules qw(strict warnings Class::Maker -force IO::Extended);

=back

=head2 EXAMPLE 1

use modules qw(5.006 strict warnings Data::Dumper);

becomes the short form for:

use 5.006;
use strict;
use warnings;
use Data::Dumper;

=head2 EXAMPLE 2

use modules ( qw(strict), { IO::Extended => '(:all)' } );

becomes the short form for:

use strict;
use IO::Extended qw(:all);

=head2 EXPORT

None by default.

=head1 AUTHOR

Murat Ünalan, E<lt>muenalan@cpan.orgE<gt>

=head1 COPYRIGHT NOTICE

Copyright (c) 2002 Murat Ünalan. All rights reserved.

This program is free software; you can redistribute it and/or modify it

under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>.

=cut
