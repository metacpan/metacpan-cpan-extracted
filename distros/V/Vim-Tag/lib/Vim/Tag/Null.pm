use 5.008;
use strict;
use warnings;

package Vim::Tag::Null;
BEGIN {
  $Vim::Tag::Null::VERSION = '1.110690';
}
# ABSTRACT: Empty base package for fake packages to aid tag generation
our $null = bless {}, __PACKAGE__;
sub AUTOLOAD { $null }
1;


__END__
=pod

=head1 NAME

Vim::Tag::Null - Empty base package for fake packages to aid tag generation

=head1 VERSION

version 1.110690

=head1 SYNOPSIS

    use base 'Vim::Tag';
    my $gen = main->new;
    $gen->setup_fake_package('Foo::Bar');

=head1 DESCRIPTION

This empty package serves as the base class for fake packages that you don't
want to install - maybe they're needed only on another platform, on the
production system, need libraries that are impossible or difficult to install
etc.

You will probably not need to use this package directly. It is used when
calling C<setup_fake_package()> in L<Vim::Tag>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Vim-Tag>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Vim-Tag/>.

The development version lives at L<http://github.com/hanekomu/Vim-Tag>
and may be cloned from L<git://github.com/hanekomu/Vim-Tag.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

