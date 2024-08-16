package YATT::Lite::NSBuilder; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use mro 'c3';

use YATT::Lite::Util qw(lexpand);

use constant DEBUG => $ENV{DEBUG_YATT_NSBUILDER} // 0;

{
  # bootscript が決まれば、root NS も一つに決まる、としよう。 MyYATT 、と。
  # instpkg の系列も決まる、と。 MyYATT::INST1, 2, ... だと。
  # XXX: INST を越えて共有される *.ytmpl/ は、 TMPL1, 2, ... と名づけたいが、...
  # それ以下のディレクトリ名・ファイル名はそのまま pkgname に使う。

  # MyYATT::INST1::dir::dir::dir::file
  # MyYATT::TMPL1::dir::dir::dir::file
  use parent qw(YATT::Lite::Object);
  use YATT::Lite::Partial::MarkAfterNew -as_base;

  use Carp;
  use YATT::Lite::Util qw(ckeval ckrequire set_inc symtab globref);
  our %SEEN_NS;
  use YATT::Lite::MFields qw/cf_app_ns app_ns
			     cf_default_app default_app
                             cf_auto_rename_ns
			     subns/;
  sub _before_after_new {
    (my MY $self) = @_;
    $self->SUPER::_before_after_new;
    if ($self->{cf_app_ns} and $SEEN_NS{$self->{cf_app_ns}}) {
      confess "app_ns '$self->{cf_app_ns}' is already used!";
    }
    $self->{cf_auto_rename_ns} //= $self->default_auto_rename_ns;
    $self->init_default_app;
    $self->init_app_ns;
  }

  sub default_subns {'INST'}
  sub default_default_app {'YATT::Lite'}
  sub default_app_ns {'MyYATT'}
  sub default_auto_rename_ns { 1 }

  sub init_default_app {
    (my MY $self) = @_;
    # This usually loads YATT::Lite (or YATT::Lite::WebMVC0::DirApp)
    $self->{default_app}
      = $self->{cf_default_app} || $self->default_default_app;
    ckrequire($self->{default_app});
  }
  sub init_app_ns {
    (my MY $self) = @_;
    # This usually set 'MyYATT'
    my $app_ns = $self->{cf_app_ns} // $self->default_app_ns;
    if (my $count = $SEEN_NS{$app_ns}++) {
      if ($self->{cf_auto_rename_ns}) {
        $app_ns .= $count+1;
      } else {
        Carp::croak "Namespace collision is detected! app_ns: $app_ns";
      }
    }
    $self->{app_ns} = $app_ns;
    try_require($app_ns);

    Carp::carp("init_app_ns called") if DEBUG;

    my $site_entns = $self->{default_app}->ensure_entns
      (ref $self, $self->{default_app}->list_entns(ref $self));

    my @base_entns = ($self->{default_app}->EntNS, $site_entns);

    # print "default_app is $self->{default_app}\n";
    # print "base entns for $app_ns is: @base_entns\n";

    unless ($app_ns->isa($self->{default_app})) {
      $self->define_base_of($app_ns, $self->{default_app});
    }

    # Then MyYATT::EntNS is composed
    $self->{default_app}->ensure_entns($app_ns, @base_entns);

  }
  sub try_require {
    my ($app_ns) = @_;
    (my $modfn = $app_ns) =~ s|::|/|g;
    local $@;
    eval qq{require $app_ns};
    unless ($@) {
      # $app_ns.pm is loaded successfully.
    } elsif ($@ =~ m{^Can't locate $modfn}) {
      # $app_ns.pm can be missing.
    } else {
      die $@;
    }
  }
  sub buildns {
    (my MY $self, my ($subns, $baselist, $path)) = @_;
    Carp::carp("buildns called") if DEBUG;
    unless (defined $self->{app_ns}) {
      croak "buildns is called without app_ns!";
    }
    # This usually creates MyYATT::INST$n and set it's ISA.
    $subns ||= $self->default_subns;
    my @base = map {ref $_ || $_} @$baselist;
    if (@base) {
      try_require($_) for @base;
      unless (grep {$_->isa($self->{default_app})} @base) {
	croak "None of baseclass inherits $self->{default_app}: @base";
      }
    }
    my $newns = sprintf q{%s::%s%d}, $self->{app_ns}, $subns
      , ++$self->{subns}{$subns};
    $self->define_base_of($newns, @base ? @base : $self->{app_ns});

    YATT::Lite::Util::globref_default(globref($newns, 'filename')
                                      , sub { $path });

    my $entns = $self->{default_app}->ensure_entns($newns, map {
      $_->EntNS
    } @base ? @base : $self->{app_ns});

    YATT::Lite::Util::globref_default(globref($entns, 'filename')
                                      , sub { $path });

    set_inc($newns, 1);
    $newns;
  }
  sub define_base_of {
    (my MY $self, my ($newns, @base)) = @_;
    YATT::Lite::MFields->add_isa_to($newns, @base)
	->define_fields($newns);
  }
  sub lineinfo { shift; sprintf qq{#line %d "%s"\n}, @_}
}

1;
