package WWW::AdventCalendar::Config;
# ABSTRACT: Config::MVP-based configuration reader for WWW::AdventCalendar
$WWW::AdventCalendar::Config::VERSION = '1.112';
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

version 1.112

=head1 DESCRIPTION

You probably want to read about L<WWW::AdventCalendar> or L<Config::MVP>.

This is just a L<Config::MVP::Reader::INI> subclass that will begin its
assembler in a section named "C<_>" with a few multivalue args and aliases
pre-configured.

Apart from that, there is nothing to say.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
