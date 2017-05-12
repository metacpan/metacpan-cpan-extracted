package Ubic::Credentials::OS::Windows;
$Ubic::Credentials::OS::Windows::VERSION = '1.60';
use strict;
use warnings;

# ABSTRACT: dummy credentials module


use parent qw(Ubic::Credentials);

sub new {
    my $class = shift;
    return bless {} => $class;
}

sub set_effective {}
sub reset_effective {}
sub eq { 1 }
sub set {}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ubic::Credentials::OS::Windows - dummy credentials module

=head1 VERSION

version 1.60

=head1 DESCRIPTION

This module does nothing and always says that credentials are good.

If you are interested in proper Win32 credentials support, look for the patch I<9581a96> in git repo.

You might also want to contact CPAN user I<MITHALDU>, he provided that patch and was generally interested in Win32 port some time ago.

=head1 AUTHOR

Vyacheslav Matyukhin <mmcleric@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
