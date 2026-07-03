package Text::AsciidocDown::Include;

use strict;
use warnings;

our $VERSION = '0.1.0';

use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Spec;

use Text::AsciidocDown::Subs ();

sub expand_includes {
  my ($text, $opts) = @_;
  $text = '' unless defined $text;
  $opts ||= {};

  my $include = ref($opts->{include}) eq 'HASH' ? $opts->{include} : {};
  return $text unless $include->{enabled};

  my $base_dir = defined($include->{base_dir}) ? $include->{base_dir} : getcwd();
  $base_dir = abs_path($base_dir) || $base_dir;

  my $ctx = {
    include => {
      max_depth => defined($include->{max_depth}) ? int($include->{max_depth}) : 64,
      on_missing => $include->{on_missing} || 'error',
      on_cycle => $include->{on_cycle} || 'error',
      on_missing_tag => $include->{on_missing_tag} || 'error',
      on_bad_selector => $include->{on_bad_selector} || 'error',
      restrict_to_base_dir => $include->{restrict_to_base_dir} ? 1 : 0,
      base_dir => $base_dir,
    },
    attributes => ref($opts->{attributes}) eq 'HASH' ? $opts->{attributes} : {},
  };

  return _expand_text($text, $ctx, {
    source_path => $opts->{source_path},
    depth => 0,
    stack => [],
  });
}

sub _expand_text {
  my ($text, $ctx, $state) = @_;

  if ($state->{depth} > $ctx->{include}{max_depth}) {
    die "include recursion depth exceeded at " . _where($state->{source_path}, 0) . "\n";
  }

  my @lines = split /\n/, $text, -1;
  my @out;
  my %attrs = %{ $ctx->{attributes} || {} };

  for my $idx (0 .. $#lines) {
    my $line = $lines[$idx];

    if ($line =~ /^:([^:-][^:]*):(?:\s(.*))?$/) {
      my ($name, $value) = ($1, defined($2) ? $2 : '');
      $attrs{$name} = Text::AsciidocDown::Subs::substitute_attributes($value, \%attrs);
      push @out, $line;
      next;
    }

    if ($line =~ /^\\include::([^[]+)\[(.*)\]$/) {
      push @out, $line;
      next;
    }

    unless ($line =~ /^include::([^[]+)\[(.*)\]$/) {
      push @out, $line;
      next;
    }

    my ($target_raw, $attrlist) = ($1, $2);
    my $target = Text::AsciidocDown::Subs::substitute_attributes($target_raw, \%attrs);
    my $selectors = _parse_selector_attrlist($attrlist, \%attrs);

    if ($target =~ m{^[a-z]+://}i) {
      push @out, $line;
      next;
    }

    my $resolved = _resolve_target($target, $state->{source_path}, $ctx->{include}{base_dir});
    unless (defined $resolved && -f $resolved) {
      my $mode = $ctx->{include}{on_missing};
      if ($mode eq 'keep') {
        push @out, $line;
        next;
      }
      if ($mode eq 'drop') {
        next;
      }
      die "missing include target '$target' resolved to '$resolved' at " . _where($state->{source_path}, $idx + 1) . "\n";
    }

    if ($ctx->{include}{restrict_to_base_dir} && !_is_under_base($resolved, $ctx->{include}{base_dir})) {
      die "include target '$resolved' is outside base dir '$ctx->{include}{base_dir}' at " . _where($state->{source_path}, $idx + 1) . "\n";
    }

    if (grep { $_ eq $resolved } @{$state->{stack}}) {
      my $mode = $ctx->{include}{on_cycle};
      if ($mode eq 'keep') {
        push @out, $line;
        next;
      }
      if ($mode eq 'drop') {
        next;
      }
      my $chain = join(' -> ', @{$state->{stack}}, $resolved);
      die "include cycle detected: $chain at " . _where($state->{source_path}, $idx + 1) . "\n";
    }

    my $content = _read_file($resolved);
    my $expanded = _expand_text($content, $ctx, {
      source_path => $resolved,
      depth => $state->{depth} + 1,
      stack => [@{$state->{stack}}, $resolved],
    });

    my ($ok, $selected, $action) = _apply_selectors($expanded, $selectors, $ctx, $line, $state, $idx + 1);
    if (!$ok) {
      if ($action eq 'keep') {
        push @out, $line;
        next;
      }
      if ($action eq 'drop') {
        next;
      }
      die $selected;
    }

    push @out, split /\n/, $selected, -1;
  }

  return join("\n", @out);
}

sub _parse_selector_attrlist {
  my ($attrlist, $attrs) = @_;
  my %s;
  return \%s unless defined $attrlist && $attrlist ne '';

  for my $tok (split /,/, $attrlist) {
    $tok =~ s/^\s+|\s+$//g;
    next if $tok eq '';
    my ($k, $v) = split /=/, $tok, 2;
    next unless defined $k && defined $v;
    $v = Text::AsciidocDown::Subs::substitute_attributes($v, $attrs);
    $s{$k} = $v;
  }
  return \%s;
}

sub _apply_selectors {
  my ($text, $selectors, $ctx, $line, $state, $line_no) = @_;
  $selectors ||= {};

  my $work = $text;

  if (exists $selectors->{tags} || exists $selectors->{tag}) {
    my @tags = exists($selectors->{tags}) ? split(/;/, $selectors->{tags}) : ($selectors->{tag});
    @tags = map { my $x = $_; $x =~ s/^\s+|\s+$//g; $x } grep { defined && $_ ne '' } @tags;
    my ($ok, $res, $action) = _filter_by_tags($work, \@tags, $ctx, $state, $line_no);
    return ($ok, $res, $action) unless $ok;
    $work = $res;
  }

  if (exists $selectors->{lines}) {
    my ($ok, $res, $action) = _filter_by_lines($work, $selectors->{lines}, $ctx, $state, $line_no);
    return ($ok, $res, $action) unless $ok;
    $work = $res;
  }

  return (1, $work, '');
}

sub _filter_by_tags {
  my ($text, $tags, $ctx, $state, $line_no) = @_;
  my %wanted = map { $_ => 1 } @{$tags};
  my %regions;
  my @stack;

  my @lines = split /\n/, $text, -1;
  for my $line (@lines) {
    if ($line =~ /^tag::([A-Za-z0-9_.:-]+)\[\]$/) {
      my $name = $1;
      if (grep { $_ eq $name } @stack) {
        return _selector_error('nested same-name tag not supported', $ctx->{include}{on_bad_selector}, $state, $line_no);
      }
      push @stack, $name;
      next;
    }
    if ($line =~ /^end::([A-Za-z0-9_.:-]+)\[\]$/) {
      my $name = $1;
      if (!@stack || $stack[-1] ne $name) {
        return _selector_error("mismatched tag terminator '$name'", $ctx->{include}{on_bad_selector}, $state, $line_no);
      }
      pop @stack;
      next;
    }
    for my $name (@stack) {
      push @{$regions{$name}}, $line;
    }
  }

  if (@stack) {
    return _selector_error('unclosed tag region', $ctx->{include}{on_bad_selector}, $state, $line_no);
  }

  my @out;
  for my $name (@{$tags}) {
    if (!exists $regions{$name}) {
      return _selector_error("missing tag '$name'", $ctx->{include}{on_missing_tag}, $state, $line_no);
    }
    push @out, @{$regions{$name}};
  }

  return (1, join("\n", @out), '');
}

sub _filter_by_lines {
  my ($text, $expr, $ctx, $state, $line_no) = @_;
  my @lines = split /\n/, $text, -1;
  my @picked;

  for my $range (split /;/, $expr) {
    $range =~ s/^\s+|\s+$//g;
    next if $range eq '';
    if ($range !~ /^(-?\d*)\.\.(-?\d*)$/) {
      return _selector_error("invalid lines selector '$range'", $ctx->{include}{on_bad_selector}, $state, $line_no);
    }
    my ($s, $e) = ($1, $2);
    my $start = ($s eq '') ? 1 : int($s);
    my $end = ($e eq '') ? scalar(@lines) : int($e);
    $end = scalar(@lines) if $end == -1;
    $start = 1 if $start < 1;
    $end = scalar(@lines) if $end > scalar(@lines);
    next if $start > $end;
    for my $i ($start .. $end) {
      push @picked, $lines[$i - 1];
    }
  }

  return (1, join("\n", @picked), '');
}

sub _selector_error {
  my ($msg, $policy, $state, $line_no) = @_;
  if ($policy eq 'keep') {
    return (0, $msg, 'keep');
  }
  if ($policy eq 'drop') {
    return (0, $msg, 'drop');
  }
  return (0, $msg . ' at ' . _where($state->{source_path}, $line_no), 'error');
}

sub _resolve_target {
  my ($target, $source_path, $base_dir) = @_;
  return abs_path($target) if File::Spec->file_name_is_absolute($target);

  my $dir = defined($source_path) ? dirname($source_path) : $base_dir;
  my $path = File::Spec->catfile($dir, $target);
  return abs_path($path) || $path;
}

sub _read_file {
  my ($path) = @_;
  open my $fh, '<:encoding(UTF-8)', $path or die "cannot read include file '$path': $!\n";
  local $/;
  my $content = <$fh>;
  close $fh;
  return defined($content) ? $content : '';
}

sub _is_under_base {
  my ($path, $base) = @_;
  my $p = abs_path($path) || $path;
  my $b = abs_path($base) || $base;
  return index($p, $b) == 0;
}

sub _where {
  my ($source_path, $line_no) = @_;
  $line_no ||= 0;
  return (defined($source_path) ? $source_path : '<input>') . ($line_no ? ':' . $line_no : '');
}

1;

__END__

=head1 NAME

Text::AsciidocDown::Include - Include directive pre-expansion for AsciiDoc

=head1 SYNOPSIS

  use Text::AsciidocDown::Include;

  my $expanded = Text::AsciidocDown::Include::expand_includes($text, \%opts);

=head1 DESCRIPTION

This module handles the C<include::[]> directive expansion for
Text::AsciidocDown. It is not intended for direct use; callers should use
the OO interface provided by L<Text::AsciidocDown>.

Include pre-merge supports:

=over 4

=item * Local filesystem includes with absolute and relative paths

=item * Selector filtering: C<tag>, C<tags>, and C<lines>

=item * Recursion depth control

=item * Policy-based error handling for missing files, cycles, and
selector issues (C<error>, C<keep>, C<drop>)

=item * Restriction to a base directory for security

=back

=head1 INTERFACE

=head2 expand_includes

  my $expanded = Text::AsciidocDown::Include::expand_includes($text, \%opts);

Expands C<include::[]> directives in the input text. Returns the expanded
text with included file contents substituted inline.

B<Options:>

=over 4

=item C<include> - HashRef controlling behavior (see L<Text::AsciidocDown/"convert">)

=item C<attributes> - HashRef of AsciiDoc attributes

=item C<source_path> - Path to the source document for relative resolution

=back

=head1 AUTHOR

Sandor Patocs

=head1 LICENSE

Same terms as Perl itself.

=cut