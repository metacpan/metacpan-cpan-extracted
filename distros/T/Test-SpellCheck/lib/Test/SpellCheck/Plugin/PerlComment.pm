package Test::SpellCheck::Plugin::PerlComment;

use strict;
use warnings;
use 5.026;
use PPI;
use URI;
use experimental qw( signatures );

# ABSTRACT: Test::SpellCheck plugin for checking spelling in Perl comments
our $VERSION = '0.02'; # VERSION


sub new ($class)
{
  bless {}, $class;
}

sub stream ($self, $filename, $splitter, $callback)
{
  my $doc = PPI::Document->new($filename);
  foreach my $comment (($doc->find('PPI::Token::Comment') || [])->@*)
  {
    next if $comment->location->[0] == 1 &&
            "$comment" =~ /^#!/;
    foreach my $event ($splitter->split("$comment"))
    {
      my($type, $word) = @$event;
      my @row = ( $type, "$filename", $comment->location->[0], $word );
      $callback->(@row);
    }
  }
  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::SpellCheck::Plugin::PerlComment - Test::SpellCheck plugin for checking spelling in Perl comments

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 spell_check ['PerlComments'];

Or from C<spellcheck.ini>:

 [PerlComments]

=head1 DESCRIPTION

This plugin adds checking of Perl comments.

=head1 OPTIONS

None.

=head1 CONSTRUCTOR

=head2 new

 my $plugin = Test::SpellCheck::Plugin::PerlComment->new;

This creates a new instance of the plugin.

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
