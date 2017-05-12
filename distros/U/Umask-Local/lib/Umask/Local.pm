=head1 NAME

Umask::Local - Class for localizing the umask

=head1 SYNOPSIS

  use Umask::Local;
  {
      my $umask_local = Umask::Local->new(0077);
      open(FILE,">only_me");
      close(FILE);
  }
  open(FILE,">default");
  close(FILE);

=head1 DESCRIPTION

    Umask::Local is use to set and reset the umask for the life of the object

=cut

package Umask::Local;

our $VERSION = '1.0';

use strict;
use warnings;
use base qw(Exporter);

our @EXPORTS = qw(umask_localize);

=head1 Methods

=head2 new

Set the umask saving the previous umask
Accepts only one parameter the umask

    Umask::Local->new(0077)

=cut

sub new {
    my $proto = shift;
    my $mask = shift;
    my $class = ref($proto) || $proto;
    my $old_umask = umask($mask);
    return bless \$old_umask,$class;
}

=head2 val

    return the the previous umask

=cut

sub val { ${$_[0]} }

=head2 umask_localize

    Convenience function

=cut

sub umask_localize { Umask::Local->new($_[0]) }

=head2 DESTROY

    Will reset the umask to the previous umask

=cut

sub DESTROY { umask ${$_[0]}; }


1;
__END__

=head1 SEE ALSO

    L<umask>

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

=head1 SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Umask::Local

You can also look for information at:

    RT, CPAN's request tracker
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Umask-Local

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Umask-Local

    CPAN Ratings
        http://cpanratings.perl.org/d/Umask-Local

    Search CPAN
        http://search.cpan.org/dist/Umask-Local/

=head1 AUTHOR

James Jude Rouzier, E<lt>rouzier@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by James Jude Rouzier

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
