package WWW::AdventCalendar::Config 1.114;
# ABSTRACT: Config::MVP-based configuration reader for WWW::AdventCalendar

use Moose;
extends 'Config::MVP::Reader::INI';

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod You probably want to read about L<WWW::AdventCalendar> or L<Config::MVP>.
#pod
#pod This is just a L<Config::MVP::Reader::INI> subclass that will begin its
#pod assembler in a section named "C<_>" with a few multivalue args and aliases
#pod pre-configured.
#pod
#pod Apart from that, there is nothing to say.
#pod
#pod =cut

use Config::MVP::Assembler;

{
  package
    WWW::AdventCalendar::Config::Assembler;
  use Moose;
  extends 'Config::MVP::Assembler';
  use namespace::autoclean;
  sub expand_package { return undef }
}

{
  package
    WWW::AdventCalendar::Config::Palette;
  $INC{'WWW/AdventCalendar/Config/Palette.pm'} = 1;
}

sub build_assembler {
  my $assembler = WWW::AdventCalendar::Config::Assembler->new;

  my $section = $assembler->section_class->new({
    name => '_',
    aliases => {
      category => 'categories',
      css_href => 'css_hrefs',
    },
    multivalue_args => [ qw( categories css_hrefs ) ],
  });
  $assembler->sequence->add_section($section);

  return $assembler;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

WWW::AdventCalendar::Config - Config::MVP-based configuration reader for WWW::AdventCalendar

=head1 VERSION

version 1.114

=head1 DESCRIPTION

You probably want to read about L<WWW::AdventCalendar> or L<Config::MVP>.

This is just a L<Config::MVP::Reader::INI> subclass that will begin its
assembler in a section named "C<_>" with a few multivalue args and aliases
pre-configured.

Apart from that, there is nothing to say.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
