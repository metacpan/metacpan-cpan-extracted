package Test::SpellCheck::Plugin::PerlPOD;

use strict;
use warnings;
use 5.026;
use Pod::Simple::Words;
use experimental qw( signatures );
use Ref::Util qw( is_plain_arrayref );
use PPI::Document;
use PPIx::DocumentName 1.00 -api => 1;

# ABSTRACT: Test::SpellCheck plugin for checking spelling in POD
our $VERSION = '0.02'; # VERSION


sub new ($class, %args)
{
  my $skip_sections;

  if(defined $args{skip_sections})
  {
    $skip_sections = is_plain_arrayref $args{skip_sections} ? [$args{skip_sections}->@*] : [$args{skip_sections}];
  }
  else
  {
    $skip_sections = ['contributors', 'author', 'copyright and license'];
  }

  bless {
    skip_sections => $skip_sections,
  }, $class;
}

sub stream ($self, $filename, $splitter, $callback)
{
  {
    my $ppi = PPI::Document->new($filename);
    my $result = PPIx::DocumentName->extract($ppi);
    if(defined $result)
    {
      $callback->('name', $filename, $result->node->location->[0], $result->name);
    }
  }

  {
    my $parser = Pod::Simple::Words->new;
    $parser->callback($callback);
    $parser->splitter($splitter);
    $parser->skip_sections($self->{skip_sections}->@*);
    $parser->parse_file($filename);
  }
  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::SpellCheck::Plugin::PerlPOD - Test::SpellCheck plugin for checking spelling in POD

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 # these are the default options
 spell_check [PerlPOD, skip_sections => ['contributors', 'author', 'copyright and license']];

Or from C<spellcheck.ini>:

 [PerlPOD]
 skip_sections = contributors
 skip_sections = author
 skip_sections = copyright and license

=head1 DESCRIPTION

This plugin adds checking of POD for spelling errors.  It will also check for POD syntax errors.

=head1 OPTIONS

=head2 skip_sections

You can skip sections, which is typically useful for "author" or "copyright and license" sections,
since these are often generated and contain a number of names.

=head1 CONSTRUCTOR

=head2 new

 my $plugin = Test::SpellCheck::Plugin::PerlPOD->new(%options);

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
