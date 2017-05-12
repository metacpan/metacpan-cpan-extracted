package Thorium::Log::Apache;
{
  $Thorium::Log::Apache::VERSION = '0.510';
}
BEGIN {
  $Thorium::Log::Apache::AUTHORITY = 'cpan:AFLOTT';
}

# ABSTRACT: Apache specific log class

use Thorium::Protection;

use Moose;

extends 'Thorium::Log';

has '+prefix' => (
    'default' => sub {
        if (exists($ENV{'MOD_PERL'})) {
            return sprintf('[id:%s] ', $ENV{'UNIQUE_ID'} || '?');
        }
    },
    'lazy' => 1
);

1;

no Moose;

1;



=pod

=head1 NAME

Thorium::Log::Apache - Apache specific log class

=head1 VERSION

version 0.510

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>, CIDC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__