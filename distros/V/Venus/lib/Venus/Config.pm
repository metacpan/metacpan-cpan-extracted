package Venus::Config;

use 5.018;

use strict;
use warnings;

# IMPORTS

use Venus::Class 'base', 'with';

# INHERITS

base 'Venus::Kind::Utility';

# INTEGRATES

with 'Venus::Role::Buildable';
with 'Venus::Role::Valuable';

use Scalar::Util ();

# STATE

state $reader = {
  env => 'read_env_file',
  js => 'read_json_file',
  json => 'read_json_file',
  perl => 'read_perl_file',
  pl => 'read_perl_file',
  yaml => 'read_yaml_file',
  yml => 'read_yaml_file',
};

state $writer = {
  env => 'write_env_file',
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

sub read_env {
  my ($self, $lines) = @_;

  my $data = {};

  my $content = $lines // '';
  my $length = length($content);
  my $pos = 0;

  while ($pos < $length) {
    # Skip whitespace and newlines
    if (substr($content, $pos, 1) =~ /[\s\n]/) {
      $pos++;
      next;
    }

    # Skip comments (lines starting with #)
    if (substr($content, $pos, 1) eq '#') {
      while ($pos < $length && substr($content, $pos, 1) ne "\n") {
        $pos++;
      }
      next;
    }

    # Parse key (alphanumeric, underscore, and dot)
    my $key = '';
    while ($pos < $length && substr($content, $pos, 1) =~ /[\w\.]/) {
      $key .= substr($content, $pos, 1);
      $pos++;
    }

    # Skip if no key found
    next if !length($key);

    # Skip whitespace before =
    while ($pos < $length && substr($content, $pos, 1) =~ /[ \t]/) {
      $pos++;
    }

    # Expect =
    if ($pos >= $length || substr($content, $pos, 1) ne '=') {
      # Skip to end of line if no =
      while ($pos < $length && substr($content, $pos, 1) ne "\n") {
        $pos++;
      }
      next;
    }
    $pos++; # Skip =

    # Skip whitespace after =
    while ($pos < $length && substr($content, $pos, 1) =~ /[ \t]/) {
      $pos++;
    }

    # Parse value
    my $value = '';
    my $char = substr($content, $pos, 1);

    if ($char eq '"') {
      # Double-quoted value (can be multiline)
      $pos++; # Skip opening quote
      while ($pos < $length) {
        $char = substr($content, $pos, 1);
        if ($char eq '\\' && $pos + 1 < $length) {
          # Handle escape sequences
          my $next = substr($content, $pos + 1, 1);
          if ($next eq 'n') {
            $value .= "\n";
            $pos += 2;
          }
          elsif ($next eq 't') {
            $value .= "\t";
            $pos += 2;
          }
          elsif ($next eq '"') {
            $value .= '"';
            $pos += 2;
          }
          elsif ($next eq '\\') {
            $value .= '\\';
            $pos += 2;
          }
          else {
            $value .= $char;
            $pos++;
          }
        }
        elsif ($char eq '"') {
          $pos++; # Skip closing quote
          last;
        }
        else {
          $value .= $char;
          $pos++;
        }
      }
    }
    elsif ($char eq "'") {
      # Single-quoted value (can be multiline, no escape processing)
      $pos++; # Skip opening quote
      while ($pos < $length) {
        $char = substr($content, $pos, 1);
        if ($char eq "'") {
          $pos++; # Skip closing quote
          last;
        }
        else {
          $value .= $char;
          $pos++;
        }
      }
    }
    else {
      # Unquoted value (single line, until whitespace or comment)
      while ($pos < $length) {
        $char = substr($content, $pos, 1);
        last if $char =~ /[\s#\n]/;
        $value .= $char;
        $pos++;
      }
    }

    $data->{$key} = $value;
  }

  return $self->class->new($data);
}

sub read_env_file {
  my ($self, $file) = @_;

  return $self->read_env(Venus::Path->new($file)->read);
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

sub write_env {
  my ($self) = @_;

  my @data;

  for my $key (sort keys %{$self->value}) {
    my $value = $self->value->{$key};

    next if !defined $value || ref $value;

    # Check if value needs quoting (contains whitespace, newlines, or special chars)
    my $needs_quotes = $value =~ /[\s\n\t"'#\\]/;

    if ($needs_quotes) {
      # Escape special characters for double-quoted values
      $value =~ s/\\/\\\\/g;
      $value =~ s/"/\\"/g;
      $value =~ s/\n/\\n/g;
      $value =~ s/\t/\\t/g;
      $value = qq("$value");
    }

    push @data, "$key=$value";
  }

  return join "\n", @data;
}

sub write_env_file {
  my ($self, $file) = @_;

  Venus::Path->new($file)->write($self->write_env);

  return $self;
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

=head2 new

  new(any @args) (Venus::Config)

The new method constructs an instance of the package.

I<Since C<4.15>>

=over 4

=item new example 1

  package main;

  use Venus::Config;

  my $config = Venus::Config->new;

  # bless(..., "Venus::Config")

=back

=over 4

=item new example 2

  package main;

  use Venus::Config;

  my $config = Venus::Config->new(value => {password => 'secret'});

  # bless(..., "Venus::Config")

=back

=cut

=head2 read_env

  read_env(string $data) (Venus::Config)

The read_env method returns a new L<Venus::Config> object based on the string
of key/value pairs provided. This method supports multiline values when
enclosed in double or single quotes.

I<Since C<4.15>>

=over 4

=item read_env example 1

  # given: synopsis

  package main;

  my $read_env = $config->read_env(
    "APPNAME=Example\nAPPVER=0.01\n# Comment\n\n\nAPPTAG=\"Godzilla\"",
  );

  # bless(..., 'Venus::Config')

=back

=over 4

=item read_env example 2

  # given: synopsis

  package main;

  my $read_env = $config->read_env(
    "MESSAGE=\"Hello\nWorld\"\nSIGNATURE='Best,\nTeam'",
  );

  # bless(..., 'Venus::Config')

=back

=over 4

=item read_env example 3

  # given: synopsis

  package main;

  my $read_env = $config->read_env(
    'ESCAPE="line1\nline2\ttabbed"',
  );

  # bless(..., 'Venus::Config')

=back

=cut

=head2 read_env_file

  read_env_file(string $file) (Venus::Config)

The read_env_file method uses L<Venus::Path> to return a new L<Venus::Config>
object based on the file provided.

I<Since C<4.15>>

=over 4

=item read_env_file example 1

  # given: synopsis

  package main;

  $config = $config->read_env_file('t/conf/read.env');

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

=head2 write_env

  write_env() (string)

The write_env method returns a string representing environment variable
key/value pairs based on the L</value> held by the underlying L<Venus::Config>
object. Multiline values are escaped using C<\n> notation and enclosed in
double quotes.

I<Since C<4.15>>

=over 4

=item write_env example 1

  # given: synopsis

  package main;

  my $value = $config->value({
    APPNAME => "Example",
    APPTAG => "Godzilla",
    APPVER => 0.01,
  });

  my $write_env = $config->write_env;

  # "APPNAME=Example\nAPPTAG=Godzilla\nAPPVER=0.01"

=back

=over 4

=item write_env example 2

  # given: synopsis

  package main;

  my $value = $config->value({
    MESSAGE => "Hello\nWorld",
    NOTE => "line1\ttabbed",
  });

  my $write_env = $config->write_env;

  # "MESSAGE=\"Hello\\nWorld\"\nNOTE=\"line1\\ttabbed\""

=back

=over 4

=item write_env example 3

  # given: synopsis

  package main;

  my $value = $config->value({
    APPNAME => "Example",
    MESSAGE => "Hello\nWorld\nGoodbye",
    APPTAG => "Godzilla",
  });

  my $write_env = $config->write_env;

  my $read_env = $config->read_env($write_env);

  # bless(..., 'Venus::Config')

  # round-trip: read_env(write_env($value)) == $value

=back

=cut

=head2 write_env_file

  write_env_file(string $path) (Venus::Config)

The write_env_file method saves a environment configuration file and returns a new
L<Venus::Config> object.

I<Since C<4.15>>

=over 4

=item write_env_file example 1

  # given: synopsis

  my $value = $config->value({
    APPNAME => "Example",
    APPTAG => "Godzilla",
    APPVER => 0.01,
  });

  $config = $config->write_env_file('t/conf/write.env');

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