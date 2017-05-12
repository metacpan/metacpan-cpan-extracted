package Web::Dispatch::Predicates;

use strictures 1;
use Exporter 'import';

our @EXPORT = qw(
  match_and match_or match_not match_method match_path match_path_strip
  match_extension match_query match_body match_uploads match_true match_false
);

sub _matcher { bless shift, 'Web::Dispatch::Matcher' }

sub match_true {
  _matcher(sub { {} });
}

sub match_false {
  _matcher(sub {});
}

sub match_and {
  my @match = @_;
  _matcher(sub {
    my ($env) = @_;
    my $my_env = { 'Web::Dispatch.original_env' => $env, %$env };
    my $new_env;
    my @got;
    foreach my $match (@match) {
      if (my @this_got = $match->($my_env)) {
        my %change_env = %{shift(@this_got)};
        @{$my_env}{keys %change_env} = values %change_env;
        @{$new_env}{keys %change_env} = values %change_env;
        push @got, @this_got;
      } else {
        return;
      }
    }
    return ($new_env, @got);
  })
}

sub match_or {
  my @match = @_;
  _matcher(sub {
    foreach my $try (@match) {
      if (my @ret = $try->(@_)) {
        return @ret;
      }
    }
    return;
  })
}

sub match_not {
  my ($match) = @_;
  _matcher(sub {
    if (my @discard = $match->($_[0])) {
      ();
    } else {
      ({});
    }
  })
}

sub match_method {
  my ($method) = @_;
  _matcher(sub {
    my ($env) = @_;
    $env->{REQUEST_METHOD} eq $method ? {} : ()
  })
}

sub match_path {
  my ($re, $names) = @_;
  _matcher(sub {
    my ($env) = @_;
    if (my @cap = ($env->{PATH_INFO} =~ /$re/)) {
      $cap[0] = {};
      $cap[1] = do { my %c; @c{@$names} = splice @cap, 1; \%c } if $names;
      return @cap;
    }
    return;
  })
}

sub match_path_strip {
  my ($re, $names) = @_;
  _matcher(sub {
    my ($env) = @_;
    if (my @cap = ($env->{PATH_INFO} =~ /$re/)) {
      $cap[0] = {
        SCRIPT_NAME => ($env->{SCRIPT_NAME}||'').$cap[0],
        PATH_INFO => pop(@cap),
      };
      $cap[1] = do { my %c; @c{@$names} = splice @cap, 1; \%c } if $names;
      return @cap;
    }
    return;
  })
}

sub match_extension {
  my ($extension) = @_;
  my $wild = (!$extension or $extension eq '*');
  my $re = $wild
             ? qr/\.(\w+)$/
             : qr/\.(\Q${extension}\E)$/;
  _matcher(sub {
    if ($_[0]->{PATH_INFO} =~ $re) {
      ($wild ? ({}, $1) : {});
    } else {
      ();
    }
   });
}

sub match_query {
  _matcher(_param_matcher(query => $_[0]));
}

sub match_body {
  _matcher(_param_matcher(body => $_[0]));
}

sub match_uploads {
  _matcher(_param_matcher(uploads => $_[0]));
}

sub _param_matcher {
  my ($type, $spec) = @_;
  # We're probably parsing a match spec while building the parser, and
  # on 5.8.8, loading ParamParser loads Encode which blows away $_ and pos.
  # Furthermore, localizing $_ doesn't restore pos afterwards. So do this
  # stupid thing instead to work on 5.8.8
  my $saved_pos = pos;
  {
    local $_;
    require Web::Dispatch::ParamParser;
  }
  pos = $saved_pos;
  my $unpack = Web::Dispatch::ParamParser->can("get_unpacked_${type}_from");
  sub {
    _extract_params($unpack->($_[0]), $spec)
  };
}

sub _extract_params {
  my ($raw, $spec) = @_;
  foreach my $name (@{$spec->{required}||[]}) {
    return unless exists $raw->{$name};
  }
  my @ret = (
    {},
    map {
      $_->{multi} ? $raw->{$_->{name}}||[] : $raw->{$_->{name}}->[-1]
    } @{$spec->{positional}||[]}
  );
  # separated since 'or' is short circuit
  my ($named, $star) = ($spec->{named}, $spec->{star});
  if ($named or $star) {
    my %kw;
    if ($star) {
      @kw{keys %$raw} = (
        $star->{multi}
          ? values %$raw
          : map $_->[-1], values %$raw
      );
    }
    foreach my $n (@{$named||[]}) {
      next if !$n->{multi} and !exists $raw->{$n->{name}};
      $kw{$n->{name}} = 
        $n->{multi} ? $raw->{$n->{name}}||[] : $raw->{$n->{name}}->[-1];
    }
    push @ret, \%kw;
  }
  @ret;
}

1;
