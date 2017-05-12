package X11::Muralis::Backend::Xloadimage;
$X11::Muralis::Backend::Xloadimage::VERSION = '0.1003';
use strict;
use warnings;

our @ISA = qw(X11::Muralis::Backend);

=head1 NAME

X11::Muralis::Backend:Xloadimage - use xloadimage to display images on the desktop.

=head1 VERSION

version 0.1003

=head1 SYNOPSIS

    muralis --use Xloadimage

=head1 DESCRIPTION

This is a backend for muralis which uses the xloadimage program
to display images on the desktop.

=cut

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my %parameters =
	(
	 prog => 'xloadimage',
	 can_do => {
	    tile => 1,
	    fullscreen => 1,
	    centre => 1,
	    zoom => 1,
	    colours => 1,
	    window => 1,
	    'option:smooth' => 1,
	 },
	 @_
	);
    my $self = bless ({%parameters}, ref ($class) || $class);
    return ($self);
} # new

=head2 display

    $self->display($filename, %args);

=cut

sub display {
    my $class = shift;
    my $filename = shift;
    my %args = (
		@_
	       );

    my $options = '';
    $options .= " -tile" if $args{tile};
    $options .= " -fullscreen -border black" if $args{fullscreen};
    $options .= " -center" if $args{center};
    $options .= " -colors " . $args{colors} if $args{colors};
    $options .= " -zoom " . $args{zoom} if $args{zoom};
    $options = $args{option} . ' ' . $options if $args{option};
    my $window = '-onroot';
    $window = "-windowid $args{window}" if $args{window};
    my $command = "xloadimage $window $options '$filename'";
    print STDERR $command, "\n" if $args{verbose};
    system($command);
} # display

=head1 REQUIRES

    Test::More

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

1; # End of X11::Muralis::Backend::Xloadimage
__END__
