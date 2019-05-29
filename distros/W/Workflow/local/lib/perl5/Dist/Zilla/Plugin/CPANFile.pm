package Dist::Zilla::Plugin::CPANFile 6.010;
# ABSTRACT: produce a cpanfile prereqs file

use Moose;
with 'Dist::Zilla::Role::FileGatherer';

use namespace::autoclean;

use Dist::Zilla::File::FromCode;

#pod =head1 SYNOPSIS
#pod
#pod     # dist.ini
#pod     [CPANfile]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin will add a F<cpanfile> file to the distribution.
#pod
#pod =attr filename
#pod
#pod If given, parameter allows you to specify an alternate name for the generated
#pod file.  It defaults, of course, to F<cpanfile>.
#pod
#pod     # dist.ini
#pod     [CPANfile]
#pod     filename = dzil-generated-cpanfile
#pod
#pod =cut

has filename => (
  is  => 'ro',
  isa => 'Str',
  default => 'cpanfile',
);

sub _hunkify_hunky_hunk_hunks {
  my ($self, $indent, $type, $req) = @_;

  my $str = '';
  for my $module (sort $req->required_modules) {
    my $vstr = $req->requirements_for_module($module);
    $str .= qq{$type "$module" => "$vstr";\n};
  }
  $str =~ s/^/'  ' x $indent/egm;
  return $str;
}

sub gather_files {
  my ($self, $arg) = @_;

  my $zilla = $self->zilla;

  my $file  = Dist::Zilla::File::FromCode->new({
    name => $self->filename,
    code => sub {
      my $prereqs = $zilla->prereqs;

      my @types  = qw(requires recommends suggests conflicts);
      my @phases = qw(runtime build test configure develop);

      my $str = '';
      for my $phase (@phases) {
        for my $type (@types) {
          my $req = $prereqs->requirements_for($phase, $type);
          next unless $req->required_modules;
          $str .= qq[\non '$phase' => sub {\n] unless $phase eq 'runtime';
          $str .= $self->_hunkify_hunky_hunk_hunks(
            ($phase eq 'runtime' ? 0 : 1),
            $type,
            $req,
          );
          $str .= qq[};\n]                     unless $phase eq 'runtime';
        }
      }

      return $str;
    },
  });

  $self->add_file($file);
  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CPANFile - produce a cpanfile prereqs file

=head1 VERSION

version 6.010

=head1 SYNOPSIS

    # dist.ini
    [CPANfile]

=head1 DESCRIPTION

This plugin will add a F<cpanfile> file to the distribution.

=head1 ATTRIBUTES

=head2 filename

If given, parameter allows you to specify an alternate name for the generated
file.  It defaults, of course, to F<cpanfile>.

    # dist.ini
    [CPANfile]
    filename = dzil-generated-cpanfile

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
