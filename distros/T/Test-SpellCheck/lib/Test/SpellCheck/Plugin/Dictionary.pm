package Test::SpellCheck::Plugin::Dictionary;

use strict;
use warnings;
use 5.026;
use experimental qw( signatures );
use Carp qw( croak );

# ABSTRACT: Test::SpellCheck for adding additional dictionaries
our $VERSION = '0.02'; # VERSION


sub new ($class, %args)
{
  croak "must specify dictionary" unless defined $args{dictionary};
  croak "dictionary $args{dictionary} not found" unless -f $args{dictionary};
  bless { dictionary => $args{dictionary} }, $class;
}

sub dictionary ($self)
{
  return $self->{dictionary};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::SpellCheck::Plugin::Dictionary - Test::SpellCheck for adding additional dictionaries

=head1 VERSION

version 0.02

=head1 SYNOPSIS

In Perl:

 spell_check ['Dictionary', dictionary => '/foo/bar/baz.dic' ];

In C<spellcheck.ini>:

 [Dictionary]
 dictionary = /foo/bar/baz.dic

=head1 DESCRIPTION

This plugin allows you to add additional arbitrary dictionaries for your test.
This is most commonly useful when you want to have a distribution-level dictionary
for local jargon.

=head1 OPTIONS

=head2 dictionary

Path to the dictionary.

=head1 CONSTRUCTOR

=head2 new

 my $plugin = Test::SpellCheck::Plugin::Dictionary->new(%options);

This creates a new instance of the plugin.  Any of the options documented above
can be passed into the constructor.

=head1 SEE ALSO

=over 4

=item L<Test::SpellCheck>

=item L<Test::SpellCheck::Plugin>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
