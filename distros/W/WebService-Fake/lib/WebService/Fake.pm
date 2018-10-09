package WebService::Fake;

use strict;
{ our $VERSION = '0.004'; }

use Mojo::Base 'Mojolicious';
use Log::Any qw< $log >;
use YAML::XS qw< LoadFile >;
use Try::Tiny;
use Scalar::Util qw< blessed >;
use Template::Perlish;
use 5.010;

sub load_config {
   my $config;
   try {
      my $config_file = $ENV{WEBSERVICE_FAKE} // 'webservice-fake.yml';
      $config = LoadFile($config_file);

      my $custom = delete $config->{custom};
      if ($custom && !blessed($custom)) {
         $custom = {class => $custom} unless ref $custom;
         local @INC = @INC;
         unshift @INC, @{$custom->{include} // []};
         (my $path = "$custom->{class}.pm") =~ s{::}{/}gmxs;
         require $path;
      } ## end if ($custom && !blessed...)
      $config->{custom} = $custom->new($config)
        if defined $custom;

      $config->{defaults}{template_start} //= '[%';
      $config->{defaults}{template_stop}  //= '%]';
      $config->{defaults}{code}           //= 200;
      $config->{v} //= {};
   } ## end try
   catch {
      my $msg = $_;
      if (ref $_) {
         require Data::Dumper;
         local $Data::Dumper::Indent = 1;
         $msg = Data::Dumper::Dumper($_);
      }
      $log->error($msg);
      die $_;
   };
   return $config;
} ## end sub load_config

sub startup {
   my $self = shift;

   my $config = $self->load_config;
   $self->helper(config => sub { $config });
   $self->secrets($config->{secrets} // ['Fake off!']);

   my $r = $self->routes;
   for my $spec (@{$config->{routes}}) {
      my $route = $r->route($spec->{path});
      my @methods =
          exists($spec->{methods}) ? @{$spec->{methods}}
        : exists($spec->{method})  ? $spec->{method}
        :                            ();
      $route->via(map { uc($_) } @methods) if @methods;
      $route->to(cb => $self->callback($spec, $config));
   } ## end for my $spec (@{$config...})

   return $self;
} ## end sub startup

sub callback {
   my ($self, $spec, $config) = @_;
   my $defaults = $config->{defaults};

   my $body_expander = $self->body_expander($spec, $config);
   my $headers_expander = $self->headers_expander($spec, $config);
   my $body_wrapper = $self->body_wrapper($spec, $config);

   return sub {
      my $c = shift;

      my $variables = {
         body_params  => $c->req->body_params->to_hash,
         controller   => $c,
         headers      => $c->req->headers->to_hash,
         params       => $c->req->params->to_hash,
         query_params => $c->req->query_params->to_hash,
         stash        => scalar($c->stash()),
      };
      $log->debug($c->req->to_string());

      # body, with exception handling for empty one, and wrapping
      my $body = $body_expander->($variables);
      if (!length $body) {
         if ($spec->{on_empty}) {
            my $r = $c->match()->root();
            my $match = Mojolicious::Routes::Match->new(root => $r);
            $match->match($c => $spec->{on_empty});
            my $frame = $match->stack()->[0];
            $c->stash($_ => $frame->{$_}) for keys %$frame;
            return $frame->{cb}->($c);
         } ## end if ($spec->{on_empty})
         return $c->render_not_found()
           if $spec->{not_found_on_empty};
      } ## end if (!length $body)
      $body = $body_wrapper->({%$variables, content => $body})
        if $body_wrapper;

      # headers
      my $headers = $headers_expander->($variables);

      my $response = $c->res;
      $response->body($body);
      my $rhs = $response->headers();
      $rhs->header($_, @{$headers->{$_}}) for keys %$headers;
      $response->fix_headers();

      $c->rendered($spec->{code} // $defaults->{code});
   };

} ## end sub callback

sub headers_expander {
   my ($self, $spec, $config) = @_;
   my $defaults = $config->{defaults};

   my $start = $spec->{template_start} // $defaults->{template_start};
   my $stop  = $spec->{template_stop}  // $defaults->{template_stop};

   my %hef;
   for my $hs (
      @{$defaults->{headers} // []},    # take them
      @{$spec->{headers}     // []},    # all
     )
   {
      for my $name (keys %$hs) {
         my $template = $hs->{$name};
         my $expander = Template::Perlish->new(
            start     => $start,
            stop      => $stop,
            variables => {
               spec   => $spec,
               config => $config,
               v      => $config->{v},
            }
         )->compile_as_sub($template);
         push @{$hef{$name} //= []}, $expander;
      } ## end for my $name (keys %$hs)
   } ## end for my $hs (@{$defaults...})

   # Ensure there will be a Content-Type
   $hef{'Content-Type'} //=
     [sub { return 'application/json' }];

   return sub {
      my ($variables) = @_;
      return {
         map {
            $_ => [map { $_->($variables) } @{$hef{$_}}];
         } keys %hef
      };
   };
} ## end sub headers_expander

sub body_expander {
   my ($self, $spec, $config) = @_;
   my $defaults = $config->{defaults};

   my $body  = $spec->{body}           // '[%%]';
   my $start = $spec->{template_start} // $defaults->{template_start};
   my $stop  = $spec->{template_stop}  // $defaults->{template_stop};

   my $be = Template::Perlish->new(
      start     => $start,
      stop      => $stop,
      variables => {
         spec   => $spec,
         config => $config,
         v      => $config->{v},
      }
   )->compile_as_sub($body);

   my $trim = $spec->{trim} //= '';
   return sub {
      (my $body = $be->(@_)) =~ s{^\s+|\s+$}{}gmxs;
      return $body;
     }
     if $trim eq 'lines';
   return sub {
      (my $body = $be->(@_)) =~ s{\A\s+|\s+\z}{}gmxs;
      return $body;
     }
     if $trim eq 'ends';
   return $be;
} ## end sub body_expander

sub body_wrapper {
   my ($self, $spec, $config) = @_;
   my $defaults = $config->{defaults};

   my $wrapper =
       exists($spec->{body_wrapper})     ? $spec->{body_wrapper}
     : exists($defaults->{body_wrapper}) ? $defaults->{body_wrapper}
     :                                     undef;
   return unless defined $wrapper;

   my $start = $spec->{template_start} // $defaults->{template_start};
   my $stop  = $spec->{template_stop}  // $defaults->{template_stop};
   return Template::Perlish->new(
      start     => $start,
      stop      => $stop,
      variables => {
         spec   => $spec,
         config => $config,
         v      => $config->{v},
      }
   )->compile_as_sub($wrapper);
} ## end sub body_wrapper

1;
__END__
