package Test::Puppet::Compile;
{
  $Test::Puppet::Compile::VERSION = '0.04';
}
BEGIN {
  $Test::Puppet::Compile::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Puppet catalog testing

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

use Test::More;
use File::Temp;
use Template;
use File::ShareDir;
use File::Basename;
use Try::Tiny;


# manifests to scan for nodes
has 'manifests' => (
  'is'        => 'ro',
  'isa'       => 'ArrayRef[Str]',
  'required'  => 1,
);

# just an identifier for this set of tests
has 'name' => (
  'is'        => 'ro',
  'isa'       => 'Str',
  'default'   => 'main',
);

# if set: only parse those nodes
has 'nodes' => (
  'is'      => 'rw',
  'isa'     => 'ArrayRef[Str]',
  'default' => sub { [] },
);

# basedir where your puppet config is located
# used as source for sync jobs
has 'basedir' => (
  'is'      => 'ro',
  'isa'     => 'Str',
  'default' => '.',
);

# custom template directory, will be used instead
# of the default, shipped, templates if present
has 'tpldir' => (
  'is'      => 'ro',
  'isa'     => 'Str',
);

# make sure these enviroments are found/defined, otherwise fail
has 'reqenvs' => (
  'is'      => 'ro',
  'isa'     => 'ArrayRef[Str]',
  'default' => sub { [qw(development staging production)] },
);

# module directories to sync to working dir
has 'moduledirs' => (
  'is'      => 'ro',
  'isa'     => 'ArrayRef[Str]',
  'default' => sub { [qw(modules services)] },
);

has 'domainpattern' => (
  'is'      => 'ro',
  'isa'     => 'ArrayRef',
  'default' => sub { [] },
);

has 'defaultdomain' => (
  'is'      => 'ro',
  'isa'     => 'Str',
  'default' => 'localdomain',
);

# set to true to show warnings
has 'warnings' => (
  'is'      => 'rw',
  'isa'     => 'Bool',
  'default' => 0,
);

# if set create the named directory and place reports there
has 'reportsdir' => (
  'is'      => 'rw',
  'isa'     => 'Str',
  'default' => '',
);

# if set use the specified ENC
has 'enc' => (
  'is'      => 'rw',
  'isa'     => 'Str',
  'default' => '',
);

# set to false to keep temporary files/directories
has 'cleanup' => (
  'is'      => 'ro',
  'isa'     => 'Bool',
  'default' => 1,
);

#
# Internal attributes from here on ...
#

has 'tt' => (
    'is'      => 'ro',
    'isa'     => 'Template',
    'lazy'    => 1,
    'builder' => '_init_tt',
);

has 'tempdir' => (
  'is'      => 'ro',
  'isa'     => 'Str',
  'lazy'    => 1,
  'builder' => '_init_tempdir',
);

has '_reports' => (
  'is'      => 'rw',
  'isa'     => 'HashRef',
  'default' => sub { {} },
);

#
# Initializers
#
sub _init_tempdir {
  my $self = shift;
  return File::Temp::tempdir( CLEANUP => $self->cleanup() );
}

sub _init_tt {
    my $self = shift;

    my @inc = ( 'share/tpl', '../share/tpl', );
    try {
      my $dist_dir = File::ShareDir::dist_dir('Test-Puppet-Compile');
      if(-d $dist_dir) {
          push(@inc, $dist_dir.'/tpl');
      }
    };
    if($self->tpldir() && -d $self->tpldir()) {
        unshift(@inc,$self->tpldir());
    }

    my $tpl_config = {
        INCLUDE_PATH => [ @inc, ],
        POST_CHOMP   => 0,
        FILTERS      => {
            'substr'   => [
                sub {
                    my ( $context, $len ) = @_;

                    return sub {
                        my $str = shift;
                        if ($len) {
                            $str = substr $str, 0, $len;
                        }
                        return $str;
                      }
                },
                1,
            ],
            'ucfirst'       => sub { my $str = shift; return ucfirst($str); },
            'localtime'     => sub { my $str = shift; return localtime($str); },
        },
    };
    my $TT = Template::->new($tpl_config);

    return $TT;
}
#
# Public API
#
sub test {
  my $self = shift;

  diag('Tempdir: '.$self->tempdir());

  # set up dir structure
  ok($self->_setup(),'Setup for tests successfull');

  my $node_ref = $self->_scan_nodes();

  is(ref($node_ref),'HASH','Node_ref is an hashref');
  ok(scalar(keys %$node_ref) > 0,'Found at least one environment');
  foreach my $env (@{$self->reqenvs()}) {
    is(ref($node_ref->{$env}),'HASH','Found Env '.$env);
  }

  # loop over each environment
  EMV: foreach my $env (sort keys %$node_ref) {
    ok(exists $node_ref->{$env},'Env '.$env.' is defined');
    is(ref($node_ref->{$env}),'HASH','Env '.$env.' is a valid hash');
    my @nodes = keys %{$node_ref->{$env}};
    if(scalar(@{$self->nodes()}) > 0) {
      @nodes = @{$self->nodes()};
    }
    NODE: foreach my $node (sort @nodes) {
      next NODE unless $node_ref->{$env}->{$node};

      my $hostname = $node_ref->{$env}->{$node}->{'hostname'};
      my $domain   = $node_ref->{$env}->{$node}->{'domain'};
      ok(defined($hostname),'Got hostname for '.$node);
      ok(length($hostname) > 0,'Got valid hostname for '.$node);
      ok(defined($domain),'Got domain for '.$node);
      ok(length($domain) > 0, 'Got valid domain for '.$node);
      ok($self->_write_facts($hostname,$domain,$env),'Wrote facts for '.$env.'-'.$hostname.'.'.$domain);

      my $logfile = $self->tempdir().'/out/'.$env.'-'.$hostname.'.'.$domain.'.log';
      my $errfile = $self->tempdir().'/out/'.$env.'-'.$hostname.'.'.$domain.'.err';
      #
      # This is where we actually compile a catalog, done for every node in every environment
      #
      my $rv = system('puppet master --color false --compile '.$hostname.'.'.$domain.' --environment '.$env.' --config '.$self->tempdir().'/puppet.conf >'.$logfile.' 2>'.$errfile) >> 8;
      is($rv,0,'Manifest for '.$hostname.'.'.$domain.'/'.$env.' compiled w/o error');
      #
      # check manifest content against defined services
      # i.e. make sure we actually got a usefull catalog back.
      # puppet may return a useless catalog under certain circumstances so got this extra step
      ok(-e $logfile,'Got logfile for '.$node);
      if(-e $logfile && ref($node_ref->{$env}->{$node}->{'services'})) {
        open(my $FH, '<', $logfile);
        my @lines = <$FH>;
        close($FH);
        foreach my $service (sort @{$node_ref->{$env}->{$node}->{'services'}}) {
          ok(scalar(grep { /$service/ } @lines),'Got service '.$service.' defined for '.$node);
        }
      }
      # in case something went wrong we print any errors from error log
      # the avoid to much noise we ignore warnings unless otherwise told
      if($rv != 0 && -e $errfile) {
        open(my $FH, '<', $errfile);
        my @lines = <$FH>;
        close($FH);
        if(!$self->warnings()) {
          @lines = grep { /Error: / } @lines;
        }
        foreach my $line (@lines) {
          diag('Puppet Compile: '.$line);
        }
      }
      # archive reports
      if(-e $errfile) {
        $self->_archive_report($env,$hostname,$domain,$errfile);
      }
    }
  }

  done_testing();

  $self->_archive_summary();
  return 1;
}
#
# Private helper methods
#

sub _archive_report {
  my $self = shift;
  my $env  = shift;
  my $hostname = shift;
  my $domain   = shift;
  my $errfile  = shift;

  return unless $self->reportsdir();
  my $rd = $self->basedir().'/'.$self->reportsdir();
  return unless -d $rd;
  return unless -e $errfile;

  mkdir $rd.'/'.$env;
  mkdir $rd.'/'.$env.'/'.$domain;
  my $filename_rel = $env.'/'.$domain.'/'.$hostname.'.html';
  my $filename_abs = $rd.'/'.$filename_rel;

  open(my $FH, '<', $errfile);
  my @lines = <$FH>;
  close($FH);

  open($FH, '>', $filename_abs)
    or return;
  print $FH "<html><head><title>Puppet Errors and Warnings for $env/$hostname.$domain</title></head><body><pre>\n";
  foreach my $line (@lines) {
    print $FH $line, "\n"
      or return;
  }
  print $FH "</pre></body></html>\n";
  close($FH);

  $self->_reports()->{$env}->{$domain}->{$hostname} = $filename_rel;

  return 1;
}

sub _archive_summary {
  my $self = shift;
  return unless $self->reportsdir();
  my $rd = $self->basedir().'/'.$self->reportsdir();
  return unless -d $rd;

  my $filename = $rd.'/'.$self->name().'.html';

  open(my $FH, '>', $filename);
  print $FH "<html><head><title>Puppet Error and Warning Overview for Test ".$self->name()."</title></head><body>\n";
  print $FH "<ul>\n";
  foreach my $env (sort keys %{$self->_reports()}) {
    print $FH "<li>Environment: $env\n<ul>\n";
    foreach my $domain (sort keys %{$self->_reports()->{$env}}) {
      print $FH "<li>Domain: $domain\n<ul>\n";
      foreach my $hostname (sort keys %{$self->_reports()->{$env}->{$domain}}) {
        my $filename = $self->_reports()->{$env}->{$domain}->{$hostname};
        print $FH '<li>Host: <a href="'.$filename.'">'.$hostname.'</a></li>',"\n";
      }
      print $FH "</ul>\n</li>\n";
    }
    print $FH "</ul>\n</li>\n";
  }
  print $FH "</ul>\n";
  print $FH "</html>\n";
  close($FH);

  return 1;
}

# setup - prepare the test environemnt
sub _setup {
  my $self = shift;
  ok($self->_check_prereq(),'Prerequistes satisfied');
  ok($self->_create_skeleton(),'Created test skeleton');
  ok($self->_write_puppetconf(),'Wrote Puppet Master config');
  ok($self->_write_hieraconf(),'Wrote hiera.yaml');
  ok($self->_sync_modules(),'Copied modules');
  ok($self->_sync_other(),'Copied supporting dirs');
  return 1;
}

# check_prereq - make sure all prerequisites are satisfied
# otherwise these tests will fail
sub _check_prereq {
  my $pv = qx(puppet help | tail -1);
  my $major = 0;
  if($pv =~ m/v(\d)/) {
    $major = $1;
  }
  return if $major < 3;
  my $rsbin = qx(which rsync);
  chomp($rsbin);
  return unless -x $rsbin;
  return 1;
}

sub _create_skeleton {
  my $self = shift;
  foreach my $d (qw(out log run ssl var var/yaml var/yaml/facts var/yaml/node)) {
    mkdir($self->tempdir().'/'.$d)
      or return;
  }
  system('chmod -R 777 '.$self->tempdir());
  if($self->reportsdir() && !-e $self->reportsdir()) {
    mkdir($self->basedir().'/'.$self->reportsdir());
  }
  return 1;
}

sub _write_puppetconf {
  my $self = shift;
  my $filename = $self->tempdir().'/puppet.conf';
  my $body;
  my $vars = {
    'tempdir'     => $self->tempdir(),
    'manifest'    => $self->tempdir().'/manifests/$environment.pp',
    'modulepath'  => $self->tempdir().'/'.join( ':'.$self->tempdir().'/', @{$self->moduledirs}),
    'hieraconfig' => $self->tempdir().'/hiera.yaml',
  };
  if ($self->enc() && -e $self->basedir().'/'.$self->enc()) {
    $vars->{'use_enc'} = 1;
    $vars->{'enc'} = $self->enc();
  }
  $self->tt()->process(
      'puppet.conf.tt',
      $vars,
      \$body,
  ) or return;
  open(my $FH, '>', $filename);
  print $FH $body;
  close($FH);
  return 1;
}

sub _write_hieraconf {
  my $self = shift;
  my $filename = $self->tempdir().'/hiera.yaml';
  my $body;
  $self->tt()->process(
      'hiera.yaml.tt',
      {
          'tempdir'    => $self->tempdir(),
      },
      \$body,
  ) or return;
  open(my $FH, '>', $filename);
  print $FH $body;
  close($FH);
  return 1;
}

sub _sync_modules {
  my $self = shift;
  foreach my $d (@{$self->moduledirs()}) {
    $self->__sync($d)
      or return;
  }
  return 1;
}

sub _sync_other {
  my $self = shift;
  foreach my $d (qw(hieradata manifests)) {
    $self->__sync($d)
      or return;
  }
  return 1;
}

sub __sync {
  my $self = shift;
  my $d    = shift;
  if(-e $d) {
    my $rv = system('rsync -Hax '.$self->basedir().'/'.$d.'/ '.$self->tempdir().'/'.$d.'/') >> 8;
    return unless $rv == 0;
  } else {
    return;
  }
  return 1;
}

sub _scan_nodes {
  my $self = shift;
   my %nodes = ();
   foreach my $path (@{$self->manifests()}) {
    my $file = File::Basename::basename($path);
     my $env;
     if($file =~ m#(.*)\.pp#) {
       $env = $1;
     }
     length($env) > 0
      or return;
     diag('Parsing env '.$env);
     # scan environment manifest and populate hashref
     $self->_scan_env($env,$path,\%nodes);
   }
   return \%nodes;
}

sub _scan_env {
  my $self = shift;
  my $env = shift;
  my $path = shift;
  my $node_ref = shift;
  # loop over each node
  open(my $FH, '<', $path)
   or return;
  my $current_node;
  while (my $line = <$FH>) {
    if($line =~ m/^\s*node\s+(\S+)\s+/) {
      my $node = $1;
      if($node =~ m#^/#) {
         note('Parsing RE node '.$node);
         $node = $self->_parse_re_node($node);
      }
      $node =~ s/^['"]//g;
      $node =~ s/['"]$//g;
      note('Parsing node '.$node);
      my ($hostname, $domain);
      if($node =~ m/\./) {
        ($hostname, $domain) = split /\./, $node, 2;
      } else {
        # no domain found in node name, look up in lookup table or use default
        $hostname = $node;
        PTRN: foreach my $ptrn (@{$self->domainpattern()}) {
         my $re = $ptrn->{'match'};
         my $do = $ptrn->{'domain'};
         if($node =~ m/$re/) {
           $domain = $do;
           last PTRN;
         }
        }
        $domain = $self->defaultdomain() unless $domain;
      }
      $node_ref->{$env}->{$node}->{'hostname'} = $hostname;
      $node_ref->{$env}->{$node}->{'domain'}   = $domain;
      $current_node = $node;
    } elsif($line =~ m/^}/) {
     # this RE is a diry hack since it relies on proper formating but
     # much easier than parsing matching brackets ... and
     # we want to enforce proper formating anyway, don't we?
     $current_node = undef;
    } elsif($current_node && $line =~ m/^\s*include\s+(\S+)\s*/) {
     push(@{$node_ref->{$env}->{$current_node}->{'services'}},$1);
    }
  }
  close($FH);
  return 1;
}
# simple heuristic for turning a RE node definition into a real node name
sub _parse_re_node {
  my $self = shift;
  my $node = shift;

  # remove delimiters
  $node =~ s#^/##;
  $node =~ s#/$##;
  # replace '\w+' by 'word'
  $node =~ s#\\w[+*]?#word#g;
  # replace '\d+' by '01'
  $node =~ s#\\d[+*]?#01#g;

  # remove re escapes
  $node =~ s/^\^//g;
  $node =~ s/\$$//g;
  $node =~ s/\\//g;

  return $node;
}

sub _write_facts {
  my $self = shift;
  my $hostname = shift;
  my $domain   = shift;
  my $env      = shift;
  my $body;
  $self->tt()->process(
      'node.yaml.tt',
      {
          'tempdir'     => $self->tempdir(),
          'hostname'    => $hostname,
          'domain'      => $domain,
          'environment' => $env,
      },
      \$body,
  ) or return;
  # write node facts to $self->tempdir()/var/yaml/facts/$node.yaml
  my $facts_file = $self->tempdir().'/var/yaml/facts/'.$hostname.'.'.$domain.'.yaml';
  open(my $FH, '>', $facts_file);
  print $FH $body;
  close($FH);
  return 1;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Test::Puppet::Compile - Puppet catalog testing

=head1 SYNOPSIS

  use Test::Puppet::Compile;

  my $TPC = Test::Puppet::Compile::->new({
    'name'          => 'synopsis',
    'manifests'     => [glob 'manifests/*.pp'],
    'basedir'       => `pwd`,
    'tpldir'        => '/your/template/dir', # must contain: hiera.yaml.tt, node.yaml.tt and puppet.conf.tt
    'reqenvs'       => [qw(development staging superlive)],
    'moduledirs'    => [qw(modules supermodules services subservices)],
    'warnings'      => 1,
    'domainpattern' => [
      { match => qr/^int-/, domain => 'integrationdomain', }
    ],
    'defaultdomain' => 'localdomain',
  });
  $TPC->test();

=head1 METHODS

=head2 test

After successfull initializtation call this method to detect all nodes and compile
a catalog for each node.

=head1 HOWTO

=head2 USE THIS MODULE

See the synopsis

=head2 REDHAT

If you want to simulate another OS just copy all templates
to a directory of your choice and adjust them acording to your needs.

Then set tpldir to point to that directory.

=head1 Q&A

=head2 WHY PERL

Because I'm most prolific with perl.

=head2 WHY IS IT SO SLOW

Because it does lots of computations.

Some performance hints:

=over 4

=item Use a ramfs

Your temp directory, usually /tmp, should be located on a sufficiently large ramdisk

=item Use forkprove

You should split your tests into multiple t files, each testing on environment, and process them w/ forkprove, e.g. forkprove -j<NUMCORES> -MMoose -MTest::More -MTest::Puppet::Compile t/

=back

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
