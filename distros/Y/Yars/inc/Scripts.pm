package inc::Scripts;

use Moose;
use 5.010;
use Dist::Zilla::File::InMemory;

with 'Dist::Zilla::Role::FileMunger';
with 'Dist::Zilla::Role::FileGatherer';

sub gather_files
{
}

sub munge_files
{
  my($self) = @_;
  
  my @mods = grep { $_->name =~ m{^lib/Yars/Command/.*\.pm$} } @{ $self->zilla->files };
  
  foreach my $mod (@mods)
  {
    $mod->name =~ m{^lib/Yars/Command/(.*)\.pm$};
    my $basename = $1;
    
    my $content = $mod->content;
    $content =~ s{^(=pod.*)}{}ms;
    my $pod = $1;

    $content .= join "\n",
      "=pod",
      "",
      "=head1 NAME",
      "",
      "Yars::Command::$basename - code for $basename",
      "",
      "=head1 DESCRIPTION",
      "",
      "This module contains the machinery for the command line program L<$basename>",
      "",
      "=head1 SEE ALSO",
      "",
      "L<yars_disk_scan>",
      "",
      "=cut";
    
    $mod->content($content);
    
    my $script = Dist::Zilla::File::InMemory->new(
      name    => "bin/$basename",
      mode    => 0755,
      content => join("\n",
        "#!/usr/bin/perl",
        "",
        "use strict;",
        "use warnings;",
        "use 5.010;",
        "use Yars::Command::$basename;",
        "",
        "Yars::Command::$basename->main(\@ARGV);",
        "",
        "__END__",
        "",
        $pod,
      ),
    );
    
    $self->log($mod->name . ' => ' . $script->name);
    $self->add_file($script);
  }
}

1;
