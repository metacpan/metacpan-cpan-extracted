package Util::EvalSnippet;
use 5.020;
use strict;
use warnings;
use PadWalker qw(peek_my peek_our);
use File::Slurp qw(read_file);
use Cwd 'abs_path';

our $VERSION = '0.02';

sub import {
  my ($package, $msg) = @_;
  if ($msg and $msg eq 'safe' and !$ENV{ALLOW_SNIPPETS}) {
    die "\n\nCan't use Util::EvalSnippet in 'safe' mode if ALLOW_SNIPPETS env var is not set";
  }
  my $callerpkg = caller(0);
  no strict 'refs';
  *{"$callerpkg\::eval_snippet"} = \&eval_snippet;
}

our $snippet_intro=q{# --snippet-info-header--
# This is a snippet. It will run in the context of the place where it was called from
# For documentation, "perldoc Util::EvalSnippet"
# This snippet was created here:
# line: %s
# file: %s
# (note, line number may have changed since this snippet was created!)
# --snippet-info-header--
};

sub eval_snippet {

  my $snippet_name = shift || '';
  $snippet_name =~ /^\w*$/ or die "Snippet name must be word characters only";

  my ($caller_package,$caller_filename,$caller_line) = (caller(0));

  my $snippet_dir = _snippet_dir();

  my $snippet_path = $snippet_dir.'/'.$caller_package;
  $snippet_name and $snippet_path.="-$snippet_name";

  unless (-f $snippet_path) {
    unless (-d $snippet_dir) {
      mkdir($snippet_dir) or die "Can't make snippet dir ($snippet_dir): $!";
    }
    open(my $fh,">",$snippet_path)
      or die "Can't create snippet ($snippet_path)";
    my $path = abs_path($caller_filename);
    printf $fh $snippet_intro,$caller_line,$path;
    close($fh);
  }

  # interpolate variables
  my $peek_my  = peek_my(1);
  my $peek_our = peek_our(1);

  my $content = read_file($snippet_path);

  $content = _process(
               content => $content,
               type    => 'my',
               vars    => [keys %$peek_my],
             );

  $content = _process(
               content => $content,
               type    => 'our',
               vars    => [keys %$peek_our],
             );

  # we want all symbols to be in the scope of the caller, so switch to the caller's namespace
  $content = "package $caller_package;".$content;
  my $return_val = eval $content;
  $@ and die $@;
  return $return_val;
}

sub _delete {
  my $snippet_id = shift;
  my ($snippet_filename) = (caller(0));
  $snippet_id
    and $snippet_filename .= "-$snippet_id";

  my $snippet_path = _snippet_dir().'/'.$snippet_filename;
  -f $snippet_path
    or die "Can't delete snippet, it doesn't exist: ".$snippet_path;
  unlink($snippet_path)
    or die "Can't delete snippet: $!";
}

sub _process {
  my %arg = @_;
  my $content = $arg{content};
  my $type    = $arg{type};
  my @vars    = @{$arg{vars}};

  foreach my $var (@vars) {
    # array
    if ($var =~ /^\@(.*)/) {
      my $dollar_var = '$'.$1;

      # array elements - $x[0]
      $content =~ s/
                    (?<!peek_${type}->\{')
                    \Q$dollar_var\E\b
                    \[
                   /\${\$peek_${type}->{'$var'}}[/gsx;

      # array @x
      $content =~ s/
                    (?<!peek_${type}->\{')
                    \Q$var\E\b
                   /\@{\$peek_${type}->{'$var'}}/gsx;
    }
    # hash
    elsif ($var =~ /^\%(.*)/) {
      my $dollar_var = '$'.$1;

      # hash element $x{key}
      $content =~ s/
                    (?<!peek_${type}->\{')
                    \Q$dollar_var\E\b
                    \{
                   /\${\$peek_${type}->{'$var'}}\{/gsx;

      # hash %x
      $content =~ s/
                    (?<!peek_${type}->\{')
                    \Q$var\E\b
                   /\%{\$peek_${type}->{'$var'}}/gsx;
    }
    # scalar / ref
    elsif ($var =~ /^\$/) {

      $content =~ s/
                    (?<!peek_${type}->\{')
                    \Q$var\E\b
                    (?![\[\{])
                   /\${\$peek_${type}->{'$var'}}/gsx;
    }
    else {
      warn "no idea how to deal with sigil for $var";
    }
  }
  return $content;
}

sub _snippet_dir {
  return $ENV{SNIPPET_DIR} || $ENV{HOME}.'/eval-snippets';
}

1;

=head1 NAME

Util::EvalSnippet - eval snippets of code in the context of a caller marker

=head1 SYNOPSIS

Use snippet files to make instant changes to apps that normally require a
restart. Example usage:

    use Util::EvalSnippet;

    sub some_method {
      eval_snippet();
    }

=head1 DESCRIPTION

When developing in many frameworks (Catalyst, mod_perl etc), every save involves
an app reload that can take from a few seconds to over a minute on your dev
server.  This module helps you minimize the inconvenience by allowing you to 
develop code in snippets, saving as you go, and then merge your changes back 
into your application's module when you're done.

=head1 EXPORTS

Default: L</eval_snippet>

=head1 FUNCTIONS

=head2 eval_snippet([SNIPPET_NAME])

Place the function in your module, in a method that the app is not caching, and
reload the app that will call that code.

A snippet will automatically appear in the ~/eval-snippets directory.

You can change the eval snippets directory by setting the SNIPPET_DIR environment
variable, if you prefer.

If you need more than one snippet in a module, name them:

    package Some::Module;
    use Util::EvalSnippet;

    sub some_method {
      eval_snippet('one');
      eval_snippet('two');
    }

When you run the code, the module creates the following snippet files in your
snippets directory:

    Some::Module-one
    Some::Module-two

Snippets are created with header comments. Do not delete them.

Make changes and save in your snippets directory, then reload your view to
see the updated code in action without having to wait for an app restart.

When you're finished with development, merge the module's snippets back
into the module by running, in a shell:

    perl-eval-snippet --merge Some::Module

That will merge the snippets into the module, and remove the
"use Util::EvalSnippet;" statement.

After merging, it's probably a good idea for you to examine the code in situ
to confirm the spacing looks good and, of course, to confirm all is well.

If you're only done with one snippet, you can merge it in on it's own using:

    perl-eval-snippet --merge Some::Module-one

The "use Util::EvalSnippet;" statement is only removed if there are no more
eval_snippet() calls left in the code.

Note: If you're working on multiple instances of a module namespace (different
branches etc), either ensure you neame snippets uniquely, or ensure the
SNIPPET_DIR environment variable is set differently for each. This tool is
not designed (yet :D) to work across multiple instances of the same file.

=head1 ENVIRONMENT

=item SNIPPET_DIR

By default, snippets are created in the ~/eval-snippets directory. If you
want to change that, set the environment var SNIPPET_DIR to point to where
you would like snippets saved.

=item ALLOW_SNIPPETS

If you want to, you can add a sanity check so that snippet code won't run
outside of your development environment. If you set the ALLOW_SNIPPETS
env var to a true value and use the module like this:

    use Util::EvalSnippet 'safe';

it will die unless the env var is set.

That way, the paranoid amongst you can be sure that the snippets are never run
outside of your dev environment - since the code involves blind eval of a
text file, this may or may not be a security concern for you.

If you end up using the module a lot, adding a git hook to reject commits
containing Util::EvalSnippet code may also be useful.

=head1 CAVEATS

As, basically, a templating solution, there are some things that are not easily
dealt with.

For example, this module does not do anything clever with string interpolation,
so some things will not work. The main inconvenience is embedded literal
variables in strings. Eg, say you have a view that returns content to the
browser:

    sub some_view {
      my $self = shift;
      eval_snippet();
    }

and you have this in a snippet:

    return '<p>The variable is called $x</p>';

it will not do what you think it should.

This should not be issues in most environments as you should be using templates
for your views.

Another place where this may not work is for dynamically created variables.

Both of these issues involve bad design patterns anyway, so they won't affect
you, right? :D

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Clive Holloway

Licensed for distribution under the GNU GENERAL PUBLIC LICENSE
