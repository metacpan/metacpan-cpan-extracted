package Text::Treesitter::Bash;
# ABSTRACT: Parse Bash with Text::Treesitter and extract executable commands
our $VERSION = '0.001';
use strict;
use warnings;
use Carp qw( croak );
use File::ShareDir qw( dist_dir );
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use Text::Treesitter;
use Text::Treesitter::Language;

sub new {
  my ( $class, %args ) = @_;

  return bless {
    lang_dir => $args{lang_dir},
    _tmpdir  => undef,
    _ts      => undef
  }, $class;
}

sub parse {
  my ( $self, $source ) = @_;
  croak 'Source required' unless defined $source;
  return $self->_treesitter->parse_string($source);
}

sub commands {
  my ( $self, $source ) = @_;

  my $tree = $self->parse($source);
  my @commands;
  $self->_walk_node( $tree->root_node, [], \@commands, undef );
  return @commands;
}

sub findings {
  my ( $self, $source ) = @_;

  my @commands = $self->commands($source);
  my @findings;

  for my $command (@commands) {
    my $name = _command_basename( $command->{command} );

    if ( _is_shell_interpreter($name) ) {
      push @findings, {
        type    => 'shell_interpreter',
        message => "shell interpreter '$command->{command}' is executed",
        command => $command
      };
    }

    if ( _is_dynamic_shell( $name, $command->{argv} ) ) {
      push @findings, {
        type    => 'dynamic_shell',
        message => "dynamic code flag used with '$command->{command}'",
        command => $command
      };
    }

    if ( $name eq 'eval' || $name eq 'source' || $name eq '.' ) {
      push @findings, {
        type    => 'shell_eval',
        message => "shell evaluation command '$command->{command}' is executed",
        command => $command
      };
    }
  }

  for my $index ( 1 .. $#commands ) {
    my $left  = $commands[ $index - 1 ];
    my $right = $commands[$index];

    next unless ( $left->{after_op} // '' ) =~ m/^\|/;
    next unless ( $right->{before_op} // '' ) =~ m/^\|/;
    next unless _is_network_fetcher( _command_basename( $left->{command} ) );
    next unless _is_shell_interpreter( _command_basename( $right->{command} ) );

    push @findings, {
      type     => 'network_to_shell',
      message  => "network command '$left->{command}' pipes into shell '$right->{command}'",
      commands => [ $left, $right ]
    };
  }

  return @findings;
}

sub _treesitter {
  my ( $self ) = @_;

  return $self->{_ts} if $self->{_ts};

  my $lang_dir = $self->{lang_dir} // $self->_build_runtime_lang_dir;
  my $lang_lib = path($lang_dir)->child('tree-sitter-bash.so');

  if ( !-f $lang_lib ) {
    my $stdout = q{};
    open my $capture, '>', \$stdout or croak "Unable to capture build output: $!";
    local *STDOUT = $capture;
    Text::Treesitter::Language::build( "$lang_lib", "$lang_dir" );
  }

  return $self->{_ts} = Text::Treesitter->new(
    lang_name => 'bash',
    lang_dir  => "$lang_dir",
    lang_lib  => "$lang_lib"
  );
}

sub _build_runtime_lang_dir {
  my ( $self ) = @_;

  my $share = $self->_find_share_dir->child('tree-sitter-bash');
  my $tmp   = path( tempdir( 'text-treesitter-bash-XXXXXX', TMPDIR => 1, CLEANUP => 1 ) );

  for my $file (
    qw(
      LICENSE
      package.json
      src/parser.c
      src/scanner.c
      src/node-types.json
    )
  ) {
    my $source = $share->child( split m{/}, $file );
    my $target = $tmp->child( split m{/}, $file );

    next unless -f $source;

    $target->parent->mkpath;
    $source->copy($target);
  }

  $self->{_tmpdir} = $tmp;
  return $tmp;
}

sub _find_share_dir {
  my ( $self ) = @_;

  my $installed = eval { path( dist_dir('Text-Treesitter-Bash') ) };
  return $installed if $installed && -d $installed;

  my $module_path = $INC{'Text/Treesitter/Bash.pm'};
  if ($module_path) {
    my $share = path($module_path)->parent(4)->child('share');
    return $share if -d $share;
  }

  croak 'Could not find Text-Treesitter-Bash share directory';
}

sub _walk_node {
  my ( $self, $node, $context, $commands, $before_op ) = @_;

  my $type = $node->type;

  if ( $type eq 'command' ) {
    push @$commands, $self->_command_entry( $node, $context, $before_op );
    $self->_walk_command_children( $node, $context, $commands );
    return;
  }

  if ( $type eq 'declaration_command' || $type eq 'unset_command' || $type eq 'test_command' ) {
    push @$commands, $self->_simple_command_entry( $node, $context, $before_op );
    $self->_walk_command_children( $node, $context, $commands );
    return;
  }

  if ( $type eq 'command_substitution' || $type eq 'process_substitution' || $type eq 'subshell' ) {
    $self->_walk_children( $node, [ @$context, $type ], $commands, undef );
    return;
  }

  if ( $type eq 'pipeline' ) {
    $self->_walk_children( $node, [ @$context, 'pipeline' ], $commands, $before_op );
    return;
  }

  if ( $type eq 'negated_command' ) {
    $self->_walk_children( $node, [ @$context, 'negated' ], $commands, $before_op );
    return;
  }

  if ( $type eq 'redirected_statement' ) {
    my $body = $node->try_child_by_field_name('body');
    if ($body) {
      $self->_walk_node( $body, $context, $commands, $before_op );
      return;
    }
  }

  $self->_walk_children( $node, $context, $commands, $before_op );
}

sub _walk_children {
  my ( $self, $node, $context, $commands, $initial_before_op ) = @_;

  my $pending_op = $initial_before_op;

  for my $child ( $node->child_nodes ) {
    if ( !$child->is_named ) {
      my $operator = _operator_text( $child->text );
      if ( defined $operator ) {
        $commands->[-1]{after_op} = $operator if @$commands;
        $pending_op = $operator;
      }
      next;
    }

    my $before_count = @$commands;
    $self->_walk_node( $child, $context, $commands, $pending_op );
    $pending_op = undef if @$commands > $before_count;
  }
}

sub _walk_command_children {
  my ( $self, $node, $context, $commands ) = @_;

  for my $child ( $node->child_nodes ) {
    next if !$child->is_named;
    next if $child->type eq 'command_name';
    $self->_walk_node( $child, $context, $commands, undef );
  }
}

sub _command_entry {
  my ( $self, $node, $context, $before_op ) = @_;

  my ( $name, @args );
  my $seen_name = 0;
  my @fields = $node->field_names_with_child_nodes;

  while (@fields) {
    my $field = shift @fields;
    my $child = shift @fields;

    if ( defined $field && $field eq 'name' ) {
      $name = _clean_word( $child->text );
      $seen_name = 1;
    }
    elsif ( defined $field && $field eq 'argument' ) {
      push @args, $child->text;
    }
    elsif ( !defined $field && $seen_name && _is_argument_node($child) ) {
      push @args, $child->text;
    }
  }

  $name //= _clean_word( _first_child_text($node) );

  return {
    source     => $node->text,
    command    => $name,
    argv       => [ $name, @args ],
    start_byte => $node->start_byte,
    end_byte   => $node->end_byte,
    context    => [@$context],
    before_op  => $before_op,
    after_op   => undef
  };
}

sub _simple_command_entry {
  my ( $self, $node, $context, $before_op ) = @_;

  my $source = $node->text;
  my @argv = grep { length $_ } split m/\s+/, $source;
  my $name = _clean_word( $argv[0] // _first_child_text($node) );

  return {
    source     => $source,
    command    => $name,
    argv       => \@argv,
    start_byte => $node->start_byte,
    end_byte   => $node->end_byte,
    context    => [@$context],
    before_op  => $before_op,
    after_op   => undef
  };
}

sub _first_child_text {
  my ( $node ) = @_;

  for my $child ( $node->child_nodes ) {
    next if $child->is_extra;
    return $child->text;
  }

  return $node->text;
}

sub _operator_text {
  my ( $text ) = @_;

  return $text if $text eq '&&';
  return $text if $text eq '||';
  return $text if $text eq '|';
  return $text if $text eq '|&';
  return $text if $text eq ';';
  return ';' if $text =~ m/^\s*\n\s*$/;

  return undef;
}

sub _is_argument_node {
  my ( $node ) = @_;

  return !!{
    word                 => 1,
    raw_string           => 1,
    string               => 1,
    ansi_c_string        => 1,
    translated_string    => 1,
    concatenation        => 1,
    command_substitution => 1,
    expansion            => 1,
    simple_expansion     => 1
  }->{ $node->type };
}

sub _clean_word {
  my ( $word ) = @_;

  return q{} unless defined $word;
  $word =~ s/^\s+//;
  $word =~ s/\s+$//;

  if ( $word =~ m/\A'([^']*)'\z/ || $word =~ m/\A"([^"]*)"\z/ ) {
    return $1;
  }

  return $word;
}

sub _command_basename {
  my ( $command ) = @_;

  $command = _clean_word($command);
  $command =~ s{\A.*/}{};
  return $command;
}

sub _is_shell_interpreter {
  my ( $name ) = @_;

  return !!{
    sh   => 1,
    bash => 1,
    dash => 1,
    zsh  => 1,
    fish => 1,
    ksh  => 1
  }->{$name};
}

sub _is_network_fetcher {
  my ( $name ) = @_;

  return !!{
    curl   => 1,
    wget   => 1,
    fetch  => 1,
    aria2c => 1
  }->{$name};
}

sub _is_dynamic_shell {
  my ( $name, $argv ) = @_;

  return 0 if !@$argv;

  if ( _is_shell_interpreter($name) ) {
    return scalar grep { $_ eq '-c' } @$argv;
  }

  if ( $name eq 'perl' || $name eq 'ruby' || $name eq 'node' ) {
    return scalar grep { $_ eq '-e' } @$argv;
  }

  if ( $name =~ m/\Apython(?:\d+(?:\.\d+)?)?\z/ ) {
    return scalar grep { $_ eq '-c' } @$argv;
  }

  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Text::Treesitter::Bash - Parse Bash with Text::Treesitter and extract executable commands

=head1 VERSION

version 0.001

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-text-treesitter-bash/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
