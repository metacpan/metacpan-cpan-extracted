package Venus::Config;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base', 'with';

base 'Venus::Kind::Utility';

with 'Venus::Role::Buildable';
with 'Venus::Role::Valuable';

use Scalar::Util ();

state $reader = {
  js => 'read_json_file',
  json => 'read_json_file',
  perl => 'read_perl_file',
  pl => 'read_perl_file',
  yaml => 'read_yaml_file',
  yml => 'read_yaml_file',
};

state $writer = {
  js => 'write_json_file',
  json => 'write_json_file',
  perl => 'write_perl_file',
  pl => 'write_perl_file',
  yaml => 'write_yaml_file',
  yml => 'write_yaml_file',
};

# BUILDERS

sub build_args {
  my ($self, $data) = @_;

  if (keys %$data == 1 && exists $data->{value}) {
    return $data;
  }
  return {
    value => $data
  };
}

# METHODS

sub edit_file {
  my ($self, $file, $code) = @_;

  $self = $self->read_file($file);

  $self->value($self->$code($self->value));

  return $self->write_file($file);
}

sub read_file {
  my ($self, $file) = @_;

  if (!$file) {
    return $self->class->new;
  }
  elsif (my $method = $reader->{(split/\./, $file)[-1]}) {
    return $self->$method($file);
  }
  else {
    return $self->class->new;
  }
}

sub read_json {
  my ($self, $data) = @_;

  require Venus::Json;

  return $self->class->new(Venus::Json->new->decode($data));
}

sub read_json_file {
  my ($self, $file) = @_;

  require Venus::Path;

  return $self->read_json(Venus::Path->new($file)->read);
}

sub read_perl {
  my ($self, $data) = @_;

  require Venus::Dump;

  return $self->class->new(Venus::Dump->new->decode($data));
}

sub read_perl_file {
  my ($self, $file) = @_;

  require Venus::Path;

  return $self->read_perl(Venus::Path->new($file)->read);
}

sub read_yaml {
  my ($self, $data) = @_;

  require Venus::Yaml;

  return $self->class->new(Venus::Yaml->new->decode($data));
}

sub read_yaml_file {
  my ($self, $file) = @_;

  require Venus::Path;

  return $self->read_yaml(Venus::Path->new($file)->read);
}

sub write_file {
  my ($self, $file) = @_;

  if (!$file) {
    return $self->class->new;
  }
  elsif (my $method = $writer->{(split/\./, $file)[-1]}) {
    return $self->do($method, $file);
  }
  else {
    return $self->class->new;
  }
}

sub write_json {
  my ($self) = @_;

  require Venus::Json;

  return Venus::Json->new($self->value)->encode;
}

sub write_json_file {
  my ($self, $file) = @_;

  require Venus::Path;

  Venus::Path->new($file)->write($self->write_json);

  return $self;
}

sub write_perl {
  my ($self) = @_;

  require Venus::Dump;

  return Venus::Dump->new($self->value)->encode;
}

sub write_perl_file {
  my ($self, $file) = @_;

  require Venus::Path;

  Venus::Path->new($file)->write($self->write_perl);

  return $self;
}

sub write_yaml {
  my ($self) = @_;

  require Venus::Yaml;

  return Venus::Yaml->new($self->value)->encode;
}

sub write_yaml_file {
  my ($self, $file) = @_;

  require Venus::Path;

  Venus::Path->new($file)->write($self->write_yaml);

  return $self;
}

1;



=head1 NAME

Venus::Config - Config Class

=cut

=head1 ABSTRACT

Config Class for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Venus::Config;

  my $config = Venus::Config->new;

  # $config = $config->read_file('app.pl');

  # "..."

=cut

=head1 DESCRIPTION

This package provides methods for loading Perl, YAML, and JSON configuration
files, and fetching configuration information.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Venus::Kind::Utility>

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Venus::Role::Buildable>

L<Venus::Role::Valuable>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 edit_file

  edit_file(string $file, string | coderef $code) (Venus::Config)

The edit_file method does an in-place edit, i.e. it loads a Perl, YAML, or JSON
configuration file, passes the decoded data to the method or callback provided,
and writes the results of the method or callback to the file.

I<Since C<3.10>>

=over 4

=item edit_file example 1

  package main;

  use Venus::Config;

  my $config = Venus::Config->edit_file('t/conf/edit.perl', sub {
    my ($self, $data) = @_;

    $data->{edited} = 1;

    return $data;
  });

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_file

  read_file(string $path) (Venus::Config)

The read_file method load a Perl, YAML, or JSON configuration file, based on
the file extension, and returns a new L<Venus::Config> object.

I<Since C<2.91>>

=over 4

=item read_file example 1

  package main;

  use Venus::Config;

  my $config = Venus::Config->read_file('t/conf/read.perl');

  # bless(..., 'Venus::Config')

=back

=over 4

=item read_file example 2

  package main;

  use Venus::Config;

  my $config = Venus::Config->read_file('t/conf/read.json');

  # bless(..., 'Venus::Config')

=back

=over 4

=item read_file example 3

  package main;

  use Venus::Config;

  my $config = Venus::Config->read_file('t/conf/read.yaml');

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_json

  read_json(string $data) (Venus::Config)

The read_json method returns a new L<Venus::Config> object based on the JSON
string provided.

I<Since C<2.91>>

=over 4

=item read_json example 1

  # given: synopsis

  package main;

  $config = $config->read_json(q(
  {
    "$metadata": {
      "tmplog": "/tmp/log"
    },
    "$services": {
      "log": { "package": "Venus/Path", "argument": { "$metadata": "tmplog" } }
    }
  }
  ));

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_json_file

  read_json_file(string $file) (Venus::Config)

The read_json_file method uses L<Venus::Path> to return a new L<Venus::Config>
object based on the file provided.

I<Since C<2.91>>

=over 4

=item read_json_file example 1

  # given: synopsis

  package main;

  $config = $config->read_json_file('t/conf/read.json');

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_perl

  read_perl(string $data) (Venus::Config)

The read_perl method returns a new L<Venus::Config> object based on the Perl
string provided.

I<Since C<2.91>>

=over 4

=item read_perl example 1

  # given: synopsis

  package main;

  $config = $config->read_perl(q(
  {
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => { package => "Venus/Path", argument => { '$metadata' => "tmplog" } }
    }
  }
  ));

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_perl_file

  read_perl_file(string $file) (Venus::Config)

The read_perl_file method uses L<Venus::Path> to return a new L<Venus::Config>
object based on the file provided.

I<Since C<2.91>>

=over 4

=item read_perl_file example 1

  # given: synopsis

  package main;

  $config = $config->read_perl_file('t/conf/read.perl');

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_yaml

  read_yaml(string $data) (Venus::Config)

The read_yaml method returns a new L<Venus::Config> object based on the YAML
string provided.

I<Since C<2.91>>

=over 4

=item read_yaml example 1

  # given: synopsis

  package main;

  $config = $config->read_yaml(q(
  '$metadata':
    tmplog: /tmp/log
  '$services':
    log:
      package: "Venus/Path"
      argument:
        '$metadata': tmplog
  ));

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_yaml_file

  read_yaml_file(string $file) (Venus::Config)

The read_yaml_file method uses L<Venus::Path> to return a new L<Venus::Config>
object based on the YAML string provided.

I<Since C<2.91>>

=over 4

=item read_yaml_file example 1

  # given: synopsis

  package main;

  $config = $config->read_yaml_file('t/conf/read.yaml');

  # bless(..., 'Venus::Config')

=back

=cut

=head2 write_file

  write_file(string $path) (Venus::Config)

The write_file method saves a Perl, YAML, or JSON configuration file, based on
the file extension, and returns a new L<Venus::Config> object.

I<Since C<2.91>>

=over 4

=item write_file example 1

  # given: synopsis

  my $value = $config->value({
    '$services' => {
      log => { package => "Venus/Path", argument => { value => "." } }
    }
  });

  $config = $config->write_file('t/conf/write.perl');

  # bless(..., 'Venus::Config')

=back

=over 4

=item write_file example 2

  # given: synopsis

  my $value = $config->value({
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => { package => "Venus/Path", argument => { '$metadata' => "tmplog" } }
    }
  });

  $config = $config->write_file('t/conf/write.json');

  # bless(..., 'Venus::Config')

=back

=over 4

=item write_file example 3

  # given: synopsis

  my $value = $config->value({
    '$metadata' => {
      tmplog => "/tmp/log"
    },
    '$services' => {
      log => { package => "Venus/Path", argument => { '$metadata' => "tmplog" } }
    }
  });

  $config = $config->write_file('t/conf/write.yaml');

  # bless(..., 'Venus::Config')

=back

=cut

=head2 write_json

  write_json() (string)

The write_json method returns a JSON encoded string based on the L</value> held
by the underlying L<Venus::Config> object.

I<Since C<2.91>>

=over 4

=item write_json example 1

  # given: synopsis

  my $value = $config->value({
    '$services' => {
      log => { package => "Venus::Path" },
    },
  });

  my $json = $config->write_json;

  # '{ "$services":{ "log":{ "package":"Venus::Path" } } }'

=back

=cut

=head2 write_json_file

  write_json_file(string $path) (Venus::Config)

The write_json_file method saves a JSON configuration file and returns a new
L<Venus::Config> object.

I<Since C<2.91>>

=over 4

=item write_json_file example 1

  # given: synopsis

  my $value = $config->value({
    '$services' => {
      log => { package => "Venus/Path", argument => { value => "." } }
    }
  });

  $config = $config->write_json_file('t/conf/write.json');

  # bless(..., 'Venus::Config')

=back

=cut

=head2 write_perl

  write_perl() (string)

The write_perl method returns a FILE encoded string based on the L</value> held
by the underlying L<Venus::Config> object.

I<Since C<2.91>>

=over 4

=item write_perl example 1

  # given: synopsis

  my $value = $config->value({
    '$services' => {
      log => { package => "Venus::Path" },
    },
  });

  my $perl = $config->write_perl;

  # '{ "\$services" => { log => { package => "Venus::Path" } } }'

=back

=cut

=head2 write_perl_file

  write_perl_file(string $path) (Venus::Config)

The write_perl_file method saves a Perl configuration file and returns a new
L<Venus::Config> object.

I<Since C<2.91>>

=over 4

=item write_perl_file example 1

  # given: synopsis

  my $value = $config->value({
    '$services' => {
      log => { package => "Venus/Path", argument => { value => "." } }
    }
  });

  $config = $config->write_perl_file('t/conf/write.perl');

  # bless(..., 'Venus::Config')

=back

=cut

=head2 write_yaml

  write_yaml() (string)

The write_yaml method returns a FILE encoded string based on the L</value> held
by the underlying L<Venus::Config> object.

I<Since C<2.91>>

=over 4

=item write_yaml example 1

  # given: synopsis

  my $value = $config->value({
    '$services' => {
      log => { package => "Venus::Path" },
    },
  });

  my $yaml = $config->write_yaml;

  # '---\n$services:\n\s\slog:\n\s\s\s\spackage:\sVenus::Path'

=back

=cut

=head2 write_yaml_file

  write_yaml_file(string $path) (Venus::Config)

The write_yaml_file method saves a YAML configuration file and returns a new
L<Venus::Config> object.

I<Since C<2.91>>

=over 4

=item write_yaml_file example 1

  # given: synopsis

  my $value = $config->value({
    '$services' => {
      log => { package => "Venus/Path", argument => { value => "." } }
    }
  });

  $config = $config->write_yaml_file('t/conf/write.yaml');

  # bless(..., 'Venus::Config')

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2022, Awncorp, C<awncorp@cpan.org>.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut