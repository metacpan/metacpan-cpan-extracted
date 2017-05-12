package YATT::Lite::NSBuilder; sub MY () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);

use YATT::Lite::Util qw(lexpand);

{
  # bootscript が決まれば、root NS も一つに決まる、としよう。 MyApp 、と。
  # instpkg の系列も決まる、と。 MyApp::INST1, 2, ... だと。
  # XXX: INST を越えて共有される *.ytmpl/ は、 TMPL1, 2, ... と名づけたいが、...
  # それ以下のディレクトリ名・ファイル名はそのまま pkgname に使う。

  # MyApp::INST1::dir::dir::dir::file
  # MyApp::TMPL1::dir::dir::dir::file
  use parent qw(YATT::Lite::Object);
  use Carp;
  use YATT::Lite::Util qw(ckeval ckrequire set_inc symtab globref);
  our %SEEN_NS;
  use YATT::Lite::MFields qw/cf_app_ns app_ns
			     cf_default_app default_app
			     subns/;
  sub _before_after_new {
    (my MY $self) = @_;
    $self->SUPER::_before_after_new;
    if ($self->{cf_app_ns} and $SEEN_NS{$self->{cf_app_ns}}++) {
      confess "app_ns '$self->{cf_app_ns}' is already used!";
    }
    $self->init_default_app;
    $self->init_app_ns;
  }

  sub default_subns {'INST'}
  sub default_default_app {'YATT::Lite'}

  sub init_default_app {
    (my MY $self) = @_;
    # This usually loads YATT::Lite (or YATT::Lite::WebMVC0::DirApp)
    $self->{default_app}
      = $self->{cf_default_app} || $self->default_default_app;
    ckrequire($self->{default_app});
  }
  sub init_app_ns {
    (my MY $self) = @_;
    # This usually set 'MyApp'
    $self->{app_ns} = my $app_ns = $self->{cf_app_ns}
      // $self->{default_app}->default_app_ns;
    try_require($app_ns);

    my $site_entns = $self->{default_app}->ensure_entns
      (ref $self, $self->{default_app}->list_entns(ref $self));

    my @base_entns = ($self->{default_app}->EntNS, $site_entns);

    # print "default_app is $self->{default_app}\n";
    # print "base entns for $app_ns is: @base_entns\n";

    unless ($app_ns->isa($self->{default_app})) {
      $self->define_base_of($app_ns, $self->{default_app});
    }

    # Then MyApp::EntNS is composed
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
    # This usually creates MyApp::INST$n and set it's ISA.
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
    my $entns = $self->{default_app}->ensure_entns($newns, map {
      $_->EntNS
    } @base ? @base : $self->{app_ns});

    foreach my $ns ($entns, $newns) {
      my $sym = globref($ns, 'filename');
      unless (*{$sym}{CODE}) {
	*$sym = sub { $path };
      }
    }

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
