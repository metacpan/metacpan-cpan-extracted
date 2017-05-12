package Test::Valgrind::Session;

use strict;
use warnings;

=head1 NAME

Test::Valgrind::Session - Test::Valgrind session object.

=head1 VERSION

Version 1.19

=cut

our $VERSION = '1.19';

=head1 DESCRIPTION

This class supervises the execution of the C<valgrind> process.
It also acts as a dispatcher between the different components.

=cut

use Config       ();
use File::Spec   ();
use ExtUtils::MM (); # MM->maybe_command()
use Scalar::Util ();

use Fcntl       (); # F_SETFD
use IO::Select;
use POSIX       (); # SIGKILL, _exit()

use base qw<Test::Valgrind::Carp>;

use Test::Valgrind::Version;

=head1 METHODS

=head2 C<new>

    my $tvs = Test::Valgrind::Session->new(
     search_dirs    => \@search_dirs,
     valgrind       => $valgrind,  # One candidate
     valgrind       => \@valgrind, # Several candidates
     min_version    => $min_version,
     regen_def_supp => $regen_def_supp,
     no_def_supp    => $no_def_supp,
     allow_no_supp  => $allow_no_supp,
     extra_supps    => \@extra_supps,
    );

The package constructor, which takes several options :

=over 4

=item *

All the directories from C<@search_dirs> will have F<valgrind> appended to create a list of candidates for the C<valgrind> executable.

Defaults to the current C<PATH> environment variable.

=item *

If a simple scalar C<$valgrind> is passed as the value to C<'valgrind'>, it will be the only candidate.
C<@search_dirs> will then be ignored.

If an array refernce C<\@valgrind> is passed, its values will be I<prepended> to the list of the candidates resulting from C<@search_dirs>.

=item *

C<$min_version> specifies the minimal C<valgrind> version required.
The constructor will croak if it's not able to find an adequate C<valgrind> from the supplied candidates list and search path.

Defaults to none.

=item *

If C<$regen_def_supp> is true, the default suppression file associated with the tool and the command will be forcefully regenerated.

Defaults to false.

=item *

If C<$no_def_supp> is true, C<valgrind> won't read the default suppression file associated with the tool and the command.

Defaults to false.

=item *

If C<$allow_no_supp> is true, the command will always be run into C<valgrind> even if no appropriate suppression file is available.

Defaults to false.

=item *

C<$extra_supps> is a reference to an array of optional suppression files that will be passed to C<valgrind>.

Defaults to none.

=back

=cut

sub new {
 my $class = shift;
 $class = ref($class) || $class;

 my %args = @_;

 my @paths;
 my $vg = delete $args{valgrind};
 if (defined $vg and not ref $vg) {
  @paths = ($vg);
 } else {
  push @paths, @$vg if defined $vg and ref $vg eq 'ARRAY';
  my $dirs = delete $args{search_dirs};
  $dirs = [ File::Spec->path ] unless defined $dirs;
  my $exe_name = 'valgrind';
  $exe_name   .= $Config::Config{exe_ext} if defined $Config::Config{exe_ext};
  push @paths, map File::Spec->catfile($_, $exe_name), @$dirs
                                                        if ref $dirs eq 'ARRAY';
 }
 $class->_croak('Empty valgrind candidates list') unless @paths;

 my $min_version = delete $args{min_version};
 if (defined $min_version) {
  $min_version = Test::Valgrind::Version->new(string => $min_version);
 }

 my ($valgrind, $version);
 for my $path (@paths) {
  next unless defined($path) and MM->maybe_command($path);
  my $output = qx/$path --version/;
  my $ver    = do {
   local $@;
   eval { Test::Valgrind::Version->new(command_output => $output) };
  };
  if (defined $ver) {
   next if defined $min_version and $ver < $min_version;
   $valgrind = $path;
   $version  = $ver;
   last;
  }
 }
 $class->_croak('No appropriate valgrind executable could be found')
                                                       unless defined $valgrind;

 my $extra_supps = delete $args{extra_supps};
 $extra_supps    = [ ] unless $extra_supps and ref $extra_supps eq 'ARRAY';
 @$extra_supps   = grep { defined && -f $_ && -r _ } @$extra_supps;

 bless {
  valgrind       => $valgrind,
  version        => $version,
  regen_def_supp => delete($args{regen_def_supp}),
  no_def_supp    => delete($args{no_def_supp}),
  allow_no_supp  => delete($args{allow_no_supp}),
  extra_supps    => $extra_supps,
 }, $class;
}

=head2 C<valgrind>

    my $valgrind_path = $tvs->valgrind;

The path to the selected C<valgrind> executable.

=head2 C<version>

    my $valgrind_version = $tvs->version;

The L<Test::Valgrind::Version> object associated to the selected C<valgrind>.

=head2 C<regen_def_supp>

    my $regen_def_supp = $tvs->regen_def_supp;

Read-only accessor for the C<regen_def_supp> option.

=cut

=head2 C<no_def_supp>

    my $no_def_supp = $tvs->no_def_supp;

Read-only accessor for the C<no_def_supp> option.

=head2 C<allow_no_supp>

    my $allow_no_supp = $tvs->allow_no_supp;

Read-only accessor for the C<allow_no_supp> option.

=cut

eval "sub $_ { \$_[0]->{$_} }" for qw<
 valgrind
 version
 regen_def_supp
 no_def_supp
 allow_no_supp
>;

=head2 C<extra_supps>

    my @extra_supps = $tvs->extra_supps;

Read-only accessor for the C<extra_supps> option.

=cut

sub extra_supps { @{$_[0]->{extra_supps} || []} }

=head2 C<run>

    $tvs->run(
     action  => $action,
     tool    => $tool,
     command => $command,
    );

Runs the command C<$command> through C<valgrind> with the tool C<$tool>, which will report to the action C<$action>.

If the command is a L<Test::Valgrind::Command::Aggregate> object, the action and the tool will be initialized once before running all the aggregated commands.

=cut

sub run {
 my ($self, %args) = @_;

 for (qw<action tool command>) {
  my $base = 'Test::Valgrind::' . ucfirst;
  my $value = $args{$_};
  $self->_croak("Invalid $_") unless Scalar::Util::blessed($value)
                                                         and $value->isa($base);
  $self->$_($args{$_})
 }

 my $cmd = $self->command;
 if ($cmd->isa('Test::Valgrind::Command::Aggregate')) {
  for my $subcmd ($cmd->commands) {
   $args{command} = $subcmd;
   $self->run(%args);
  }
  return;
 }

 $self->report($self->report_class->new_diag(
  'Using valgrind ' . $self->version . ' located at ' . $self->valgrind
 ));

 my $env = $self->command->env($self);

 my @supp_args;
 if ($self->do_suppressions) {
  push @supp_args, '--gen-suppressions=all';
 } else {
  if (!$self->no_def_supp) {
   my $def_supp = $self->def_supp_file;
   my $forced;
   if ($self->regen_def_supp and -e $def_supp) {
    1 while unlink $def_supp;
    $forced = 1;
   }
   if (defined $def_supp and not -e $def_supp) {
    $self->report($self->report_class->new_diag(
     'Generating suppressions' . ($forced ? ' (forced)' : '') . '...'
    ));
    require Test::Valgrind::Suppressions;
    Test::Valgrind::Suppressions->generate(
     tool    => $self->tool,
     command => $self->command,
     target  => $def_supp,
    );
    $self->_croak('Couldn\'t generate suppressions') unless -e $def_supp;
    $self->report($self->report_class->new_diag(
     "Suppressions for this perl stored in $def_supp"
    ));
   }
  }
  my @supp_files = grep {
   -e $_ and $self->command->check_suppressions_file($_)
  } $self->suppressions;
  if (@supp_files > 1) {
   my $files_list = join "\n", map "    $_", @supp_files;
   $self->report($self->report_class->new_diag(
    "Using suppressions from:\n$files_list"
   ));
  } elsif (@supp_files) {
   $self->report($self->report_class->new_diag(
    "Using suppressions from $supp_files[0]"
   ));
  } elsif ($self->allow_no_supp) {
   $self->report($self->report_class->new_diag("No suppressions used"));
  } else {
   $self->_croak("No compatible suppressions available");
  }
  @supp_args = map "--suppressions=$_", @supp_files;
 }

 my $error;
 GUARDED: {
  my $guard = Test::Valgrind::Session::Guard->new(sub { $self->finish });
  $self->start;

  pipe my $vrdr, my $vwtr or $self->_croak("pipe(\$vrdr, \$vwtr): $!");
  {
   my $oldfh = select $vrdr;
   $|++;
   select $oldfh;
  }

  pipe my $erdr, my $ewtr or $self->_croak("pipe(\$erdr, \$ewtr): $!");
  {
   my $oldfh = select $erdr;
   $|++;
   select $oldfh;
  }

  my $pid = fork;
  $self->_croak("fork(): $!") unless defined $pid;

  if ($pid == 0) {
   {
    local $@;
    eval { setpgrp(0, 0) };
   }

   close $erdr or POSIX::_exit(255);

   local $@;
   eval {
    close $vrdr or $self->_croak("close(\$vrdr): $!");

    fcntl $vwtr, Fcntl::F_SETFD(), 0
                              or $self->_croak("fcntl(\$vwtr, F_SETFD, 0): $!");

    my @args = (
     $self->valgrind,
     $self->tool->args($self),
     @supp_args,
     $self->parser->args($self, $vwtr),
     $self->command->args($self),
    );

    {
     no warnings 'exec';
     exec { $args[0] } @args;
    }
    $self->_croak("exec @args: $!");
   };

   print $ewtr $@;
   close $ewtr;

   POSIX::_exit(255);
  }

  local $@;
  eval {
   local $SIG{INT} = sub {
    die 'valgrind analysis was interrupted';
   };

   close $vwtr or $self->_croak("close(\$vwtr): $!");
   close $ewtr or $self->_croak("close(\$ewtr): $!");

   SEL: {
    my $sel = IO::Select->new($vrdr, $erdr);

    my $child_err;
    while (my @ready = $sel->can_read) {
     last SEL if @ready == 1 and fileno $ready[0] == fileno $vrdr;

     my $buf;
     my $bytes_read = sysread $erdr, $buf, 4096;
     if (not defined $bytes_read) {
      $self->_croak("sysread(\$erdr): $!");
     } elsif ($bytes_read) {
      $sel->remove($vrdr) unless $child_err;
      $child_err .= $buf;
     } else {
      $sel->remove($erdr);
      die $child_err if $child_err;
     }
    }
   }

   my $aborted = $self->parser->parse($self, $vrdr);

   if ($aborted) {
    $self->report($self->report_class->new_diag("valgrind has aborted"));
    return 0;
   }

   1;
  } or do {
   $error = $@;
   kill -(POSIX::SIGKILL()) => $pid if kill 0 => $pid;
   close $erdr;
   close $vrdr;
   waitpid $pid, 0;
   # Force the guard destructor to trigger now so that old perls don't lose $@
   last GUARDED;
  };

  $self->{exit_code} = (waitpid($pid, 0) == $pid) ? $? >> 8 : 255;

  close $erdr or $self->_croak("close(\$erdr): $!");
  close $vrdr or $self->_croak("close(\$vrdr): $!");

  return;
 }

 die $error if $error;

 return;
}

sub Test::Valgrind::Session::Guard::new     { bless \($_[1]), $_[0] }

sub Test::Valgrind::Session::Guard::DESTROY { ${$_[0]}->() }

=head2 C<action>

Read-only accessor for the C<action> associated to the current run.

=head2 C<tool>

Read-only accessor for the C<tool> associated to the current run.

=head2 C<parser>

Read-only accessor for the C<parser> associated to the current tool.

=head2 C<command>

Read-only accessor for the C<command> associated to the current run.

=cut

my @members;
BEGIN {
 @members = qw<action tool command parser>;
 for (@members) {
  eval "sub $_ { \@_ <= 1 ? \$_[0]->{$_} : (\$_[0]->{$_} = \$_[1]) }";
  die if $@;
 }
}

=head2 C<do_suppressions>

Forwards to C<< ->action->do_suppressions >>.

=cut

sub do_suppressions { $_[0]->action->do_suppressions }

=head2 C<parser_class>

Calls C<< ->tool->parser_class >> with the current session object as the unique argument.

=cut

sub parser_class { $_[0]->tool->parser_class($_[0]) }

=head2 C<report_class>

Calls C<< ->tool->report_class >> with the current session object as the unique argument.

=cut

sub report_class { $_[0]->tool->report_class($_[0]) }

=head2 C<def_supp_file>

Returns an absolute path to the default suppression file associated to the current session.

C<undef> will be returned as soon as any of C<< ->command->suppressions_tag >> or C<< ->tool->suppressions_tag >> are also C<undef>.
Otherwise, the file part of the name is builded by joining those two together, and the directory part is roughly F<< File::HomeDir->my_home / .perl / Test-Valgrind / suppressions / $VERSION >>.

=cut

sub def_supp_file {
 my ($self) = @_;

 my $tool_tag = $self->tool->suppressions_tag($self);
 return unless defined $tool_tag;

 my $cmd_tag = $self->command->suppressions_tag($self);
 return unless defined $cmd_tag;

 require File::HomeDir; # So that it's not needed at configure time.

 return File::Spec->catfile(
  File::HomeDir->my_home,
  '.perl',
  'Test-Valgrind',
  'suppressions',
  $VERSION,
  "$tool_tag-$cmd_tag.supp",
 );
}

=head2 C<suppressions>

    my @suppressions = $tvs->suppressions;

Returns the list of all the suppressions that will be passed to C<valgrind>.
Honors L</no_def_supp> and L</extra_supps>.

=cut

sub suppressions {
 my ($self) = @_;

 my @supps;
 unless ($self->no_def_supp) {
  my $def_supp = $self->def_supp_file;
  push @supps, $def_supp if defined $def_supp;
 }
 push @supps, $self->extra_supps;

 return @supps;
}

=head2 C<start>

    $tvs->start;

Starts the action and tool associated to the current run.
It's automatically called at the beginning of L</run>.

=cut

sub start {
 my $self = shift;

 delete @{$self}{qw<last_status exit_code>};

 $self->tool->start($self);
 $self->parser($self->parser_class->new)->start($self);
 $self->action->start($self);

 return;
}

=head2 C<abort>

    $tvs->abort($msg);

Forwards to C<< ->action->abort >> after unshifting the session object to the argument list.

=cut

sub abort {
 my $self = shift;

 $self->action->abort($self, @_);
}

=head2 C<report>

    $tvs->report($report);

Forwards to C<< ->action->report >> after unshifting the session object to the argument list.

=cut

sub report {
 my ($self, $report) = @_;

 return unless defined $report;

 for my $handler (qw<tool command>) {
  $report = $self->$handler->filter($self, $report);
  return unless defined $report;
 }

 $self->action->report($self, $report);
}

=head2 C<finish>

    $tvs->finish;

Finishes the action and tool associated to the current run.
It's automatically called at the end of L</run>.

=cut

sub finish {
 my ($self) = @_;

 my $action = $self->action;

 $action->finish($self);
 $self->parser->finish($self);
 $self->tool->finish($self);

 my $status = $action->status($self);
 $self->{last_status} = defined $status ? $status : $self->{exit_code};

 $self->$_(undef) for @members;

 return;
}

=head2 C<status>

    my $status = $tvs->status;

Returns the status code of the last run of the session.

=cut

sub status { $_[0]->{last_status} }

=head1 SEE ALSO

L<Test::Valgrind>, L<Test::Valgrind::Action>, L<Test::Valgrind::Command>, L<Test::Valgrind::Tool>, L<Test::Valgrind::Parser>.

L<File::HomeDir>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-valgrind at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Valgrind>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Valgrind::Session

=head1 COPYRIGHT & LICENSE

Copyright 2009,2010,2011,2013,2015,2016 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of Test::Valgrind::Session
