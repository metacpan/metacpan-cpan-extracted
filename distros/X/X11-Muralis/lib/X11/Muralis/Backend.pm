package X11::Muralis::Backend;
$X11::Muralis::Backend::VERSION = '0.1003';
use strict;
use warnings;

=head1 NAME

X11::Muralis::Backend - display backend for X11::Muralis

=head1 VERSION

version 0.1003

=head1 SYNOPSIS

    muralis --use I<backend>

=head1 DESCRIPTION

This is the base class for backend modules for X11::Muralis.
Generally speaking, the only methods that backends need to override
are "new" and "display".

=cut

use File::Spec;

=head1 METHODS

=head2 new

There are two parameters that need to be set in "new";

=over

=item prog

The name of the program which is used as the backend.

=item can_do

A hash containing the features that the backend provides.

=back

=cut

sub new {
    my $class = shift;
    my %parameters = @_;
    my $self = bless ({%parameters}, ref ($class) || $class);
    return ($self);
} # new

=head2 name

The name of the backend; this is basically the last component
of the module name.  This works as either a class function or a method.

$name = $self->name();

$name = X11::Muralis::Backend::name($class);

=cut

sub name {
    my $class = shift;
    
    my $fullname = (ref ($class) ? ref ($class) : $class);

    my @bits = split('::', $fullname);
    return pop @bits;
} # name

=head2 active

Returns true if the backend program is available to run.
This is checked by searching the PATH environment variable and checking
for the existence of $self->{prog}

=cut

sub active {
    my $self = shift;

    my @path = split(':', $ENV{PATH});
    my $found = 0;
    foreach my $dir (@path)
    {
	my $file = File::Spec->catfile($dir, $self->{prog});
	if (-f $file)
	{
	    $found = 1;
	    last;
	}
    }
    return $found;
} # active

=head2 provides

Returns a hash of the features the backend has enabled.

=cut

sub provides {
    my $self = shift;

    my %prov = ();
    if (defined $self->{can_do})
    {
	%prov = %{$self->{can_do}};
    }
    return %prov;
} # provides

=head2 display

Display the file, with the given options.
THis must be overridden by the specific backend class.

=cut

sub display {
    my $self = shift;

    return 0;
} # display

=head1 REQUIRES

    File::Spec

=head1 INSTALLATION

To install this module, run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you're on a platform (like DOS or Windows) that doesn't like the
"./" notation, you can do this:

   perl Build.PL
   perl Build
   perl Build test
   perl Build install

In order to install somewhere other than the default, such as
in a directory under your home directory, like "/home/fred/perl"
go

   perl Build.PL --install_base /home/fred/perl

as the first step instead.

This will install the files underneath /home/fred/perl.

You will then need to make sure that you alter the PERL5LIB variable to
find the modules, and the PATH variable to find the script.

Therefore you will need to change:
your path, to include /home/fred/perl/script (where the script will be)

	PATH=/home/fred/perl/script:${PATH}

the PERL5LIB variable to add /home/fred/perl/lib

	PERL5LIB=/home/fred/perl/lib:${PERL5LIB}

=head1 SEE ALSO

perl(1).

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 AUTHOR

    Kathryn Andersen RUBYKAT
    perlkat AT katspace DOT org
    www.katspace.org

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2008 by Kathryn Andersen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of X11::Muralis::Backend
__END__
