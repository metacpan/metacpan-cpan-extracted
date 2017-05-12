package underscore;
use warnings;
use strict;
use Carp ();
our $VERSION = sprintf "%d.%02d", q$Revision: 0.1 $ =~ /(\d+)/g;

sub TIESCALAR{
    my ($pkg, $code, $msg) = @_;
    bless [$code, $msg], $pkg;
}

sub unimport {
    my $pkg    = shift;
    my $action = shift;
    no strict 'refs';
    my $code =
        ref $action ? $action
      : $action     ? \&{ 'Carp::' . $action }
      :               \&Carp::croak;
    my $msg = shift || '$_ is forbidden';
    untie $_ if tied $_;
    tie $_, __PACKAGE__, $code, $msg;
}

sub import{  untie $_ }

sub FETCH{ $_[0]->[0]($_[0]->[1]) }
sub STORE{ $_[0]->[0]($_[0]->[1]) }

1; # End of underscore
__END__

=head1 NAME

underscore - outlaws global $_

=head1 VERSION

$Id: underscore.pm,v 0.1 2007/12/25 08:30:14 dankogai Exp dankogai $

=cut

=head1 SYNOPSIS

  no underscore; # outlaws $_
  while(<>){ # croaks here!
    print;
  }
  use underscore;
  # back to normal

=head1 DESCRIPTION

This module detects the use of global C<$_> and croaks.  If you want
it to carp or confess, simply

  no underscore 'carp';

You can also use your custom subroutine like

  no underscore sub { ... }

You can also customize the error message like

  no undersocore 'croak', 'I said not to use $_'!

=head1 EXPORT

None

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

Original Idea by Tom Christiansen in Perl Cookbook, p. 543

=head1 BUGS

Please report any bugs or feature requests to C<bug-underscore at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=underscore>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc underscore

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=underscore>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/underscore>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/underscore>

=item * Search CPAN

L<http://search.cpan.org/dist/underscore>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
