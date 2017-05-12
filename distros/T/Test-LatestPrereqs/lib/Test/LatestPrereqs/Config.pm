package Test::LatestPrereqs::Config;

use strict;
use warnings;
use File::Spec;
use CPAN::Version;

our $CONFIG;

sub load {
  my $class = shift;

  unless ($CONFIG) {
    if (open my $fh, '<', _file()) {
      while(<$fh>) {
        chomp;
        my ($module, $version) = split /\s+/, $_, 2;
        $CONFIG->{$module} = $version || 0;
      }
    }

    $CONFIG ||= $class->_recommend;
  }

  return $CONFIG;
}

sub save {
  my ($class, @requires) = @_;

  $class->load;
  foreach my $require (@requires) {
    my ($module, $version) = @{ $require };
    next unless $version;
    if (!$CONFIG->{$module} or CPAN::Version->vgt($version, $CONFIG->{$module})) {
      $CONFIG->{$module} = $version;
    }
  }
  if (open my $fh, '>', _file()) {
    foreach my $module (keys %{ $CONFIG }) {
      print $fh $module, "\t", $CONFIG->{$module}, "\n";
    }
  }
}

sub _file {
  File::Spec->catfile(_home(), '.test_prereqs_version');
}

sub _home {
  eval "require File::HomeDir";
  return $@ ? '.' : File::HomeDir->my_home;
}

sub _recommend {
  return {
    # better error handling
    'CLI::Dispatch'       => '0.03',

    # better DBD::SQLite support
    'DBI'                 => '1.608',
    'DBD::SQLite'         => '1.25',

    # file_or_die() support
    'Path::Extended'      => '0.12',

    # for better trap and japanese test messages
    'Test::Classy'        => '0.07',

    # t/lib support
    'Test::UseAllModules' => '0.11',
  };
}

1;

__END__

=head1 NAME

Test::LatestPrereqs::Config

=head1 SYNOPSIS

  my $required = Test::LatestPrereqs::Config->load;
  Test::LatestPrereqs::Config->save($arrayref_of_requirements);

=head1 DESCRIPTION

This is used internally to handle configuration.

=head1 METHODS

=head2 load

loads a configuration file from your home directory (or current directory if L<File::HomeDir> is not available).

=head2 save

stores the configuration into the file.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
