package Module::Install::PRIVATE::Configure_Programs;

use strict;
use warnings;

use lib 'inc';
use Module::Install::GetProgramLocations;

use vars qw( @ISA $VERSION );

use Module::Install::Base;
@ISA = qw( Module::Install::Base );

$VERSION = sprintf "%d.%02d%02d", q/0.1.0/ =~ /(\d+)/g;

# ---------------------------------------------------------------------------

sub configure_programs {
  my ($self, @args) = @_;

  $self->include('Module::Install::GetProgramLocations', 0);
  $self->include_deps('File::Slurper', 0);

  require File::Slurper;
  File::Slurper->import('read_text', 'write_text');

  print<<"EOF";
yagg uses a number of external programs. For security reasons, it is best if
you provide their full path. In the following prompts, we will try to guess
these paths from your Perl configuration and your \$PATH.

You MUST specify *GNU* make and yapp. ssh is only necessary if you plan to use
the remote execution capabilities of the -o flag. yapp is part of the
Parse::Yapp Perl module distribution.

EOF

  my %info = (
      'yapp'      => { default => 'yapp', argname => 'YAPP' },
      'ln'        => { default => 'ln', argname => 'LN' },
      'cp'        => { default => 'cp', argname => 'CP' },
      'cpp'       => { default => 'cpp', argname => 'CPP' },
      'rm'        => { default => 'rm', argname => 'RM' },
      'mv'        => { default => 'mv', argname => 'MV' },
      'grep'      => { default => 'grep', argname => 'GREP' },
      'chmod'     => { default => 'chmod', argname => 'CHMOD' },
      'rsync'     => { default => 'rsync', argname => 'RSYNC' },
      'c++'       => { default => 'c++', argname => 'CXX', },
      'ar'        => { default => 'ar', argname => 'AR' },
      'mkdir'     => { default => 'mkdir', argname => 'MKDIR' },
      'date'      => { default => 'date', argname => 'DATE' },
      'perl'      => { default => $^X, argname => 'PERL' },
      'dirname'   => { default => 'dirname', argname => 'DIRNAME' },
      'expr'      => { default => 'expr', argname => 'EXPR' },
      'make'      => { default => (($^O eq 'freebsd' || $^O eq 'openbsd') ? 'gmake' : 'make'), argname => 'MAKE',
                       types    => {
                          'GNU' => { fetch => \&get_gnu_version,
                                     numbers => '[1.0,)', },
                       },
                     },
      'rm'        => { default => 'rm', argname => 'RM' },
      'find'      => { default => (($^O eq 'freebsd' || $^O eq 'openbsd') ? 'gfind' : 'find'), argname => 'FIND',
                       types    => {
                          'Non-GNU' => { fetch => \&Get_NonGNU_Find_Version,
                                     numbers => '[0,)', },
                          'GNU' => { fetch => \&get_gnu_version,
                                     numbers => '[1.0,)', },
                       },
                     },
      'ssh'       => { default => 'ssh', argname => 'SSH' },
  );

  my %locations = $self->get_program_locations(\%info);

  die "Can't create parsers without \"yapp\"\n" 
    unless defined $locations{'yapp'}{'path'};

  {
    my @missing_programs;
    foreach my $program (qw(chmod perl rsync))
    {
      push @missing_programs, $program
        unless defined $locations{$program}{'path'};
    }

    die "You won't be able to use yapp to generate code without:\n" .
      "@missing_programs\n"
      if @missing_programs;
  }

  {
    my @missing_programs;
    foreach my $program (qw(ar cp cpp chmod dirname find grep c++ make mkdir rm mv perl))
    {
      push @missing_programs, $program
        unless defined $locations{$program}{'path'};
    }

    die "You won't be able to build the generated code without:\n" .
      "@missing_programs\n"
      if @missing_programs;
  }

  Update_Config('lib/yagg/Config.pm', \%locations);

  Update_Makefile('examples/ab/ab_parser/GNUmakefile', \%locations);
  Update_Makefile('examples/logical_expressions_constrained/logical_expression_parser/GNUmakefile', \%locations);

  Update_Makefile('lib/yagg/input_generator_code/GNUmakefile', \%locations);
  Update_Makefile('t/logical_expressions_simple/GNUmakefile', \%locations);

  return \%locations;
}

# --------------------------------------------------------------------------

sub Update_Config
{
  my $filename = shift;
  my %locations = %{ shift @_ };

  my $code = read_text($filename, undef, 1);

  foreach my $program (keys %locations)
  {
    if (defined $locations{$program}{'path'})
    {
      $locations{$program}{'path'} = "\'$locations{$program}{'path'}\'";
    }
    else
    {
      $locations{$program}{'path'} = "undef";
    }
  }

  if ($code =~ /'programs'\s*=>\s*{\s*?\n([^}]+?) *}/s)
  {
    my $original_programs = $1;
    my $new_programs = '';

    foreach my $program (sort keys %locations)
    {
      $new_programs .= "    '$program' => $locations{$program}{'path'},\n";
    }

    $code =~ s/\Q$original_programs\E/$new_programs/;
  }
  else
  {
    die "Couldn't find programs hash in $filename";
  }

  write_text($filename, $code, undef, 1);
}

# --------------------------------------------------------------------------

sub Update_Makefile
{
  my $filename = shift;
  my %locations = %{ shift @_ };

  my $code = read_text($filename, undef, 1);

  $code = _Update_Makefile_Program_Locations($code, \%locations);

  $code = _Update_Makefile_Find_Code($code, $locations{'find'});

  write_text($filename, $code, undef, 1);
}

# --------------------------------------------------------------------------

sub _Update_Makefile_Program_Locations
{
  my $code = shift;
  my %locations = %{ shift @_ };

  foreach my $program (keys %locations)
  {
    $locations{$program}{'path'} = "NONE"
      unless defined $locations{$program}{'path'};
  }

  my %symbol_lookup = (
    'LN' => 'ln',
    'CP' => 'cp',
    'CPP' => 'cpp',
    'RM' => 'rm',
    'MV' => 'mv',
    'GREP' => 'grep',
    'CHMOD' => 'chmod',
    'CXX' => 'c++',
    'LD' => 'c++',
    'AR' => 'ar',
    'MKDIR' => 'mkdir',
    'DATE' => 'date',
    'PERL' => 'perl',
    'DIRNAME' => 'dirname',
    'EXPR' => 'expr',
    'FIND' => 'find',
  );

  while ($code =~ /^([A-Z]+)(\s*=\s*)(.*)$/mg)
  {
    my $symbol = $1;
    my $middle = $2;
    my $value = $3;

    if (exists $symbol_lookup{$symbol} && exists $locations{ $symbol_lookup{$symbol} })
    {
      my $old_pos = pos $code;

      my $new_value = $locations{ $symbol_lookup{$symbol} }{'path'};
      $new_value = " $new_value" unless $middle =~ / $/;

      substr($code,pos($code) - length($value), length($value)) = $new_value;
      pos($code) = $old_pos - length($value) + length($new_value);

    }
  }

  return $code;
}

# --------------------------------------------------------------------------

sub _Update_Makefile_Find_Code
{
  my $code = shift;
  my %find_info = %{ shift @_ };

  # First add in all the -E flags if we need them.
  while ($code =~ /(\$\(FIND\) +)(-E +)?(\$\(\w+\) -regex)/mg)
  {
    my $prefix = $1;
    my $flag = $2;
    my $suffix = $3;

    $flag = '' unless defined $flag;

    my $value = "$prefix$flag$suffix";

    my $old_pos = pos $code;
    my $new_value = $value;

    $new_value = "$prefix$suffix"
      if defined $find_info{'type'} && $find_info{'type'} eq 'GNU';

    substr( $code, pos($code) - length($value), length($value)) = $new_value;
    pos($code) = $old_pos - length($value) + length($new_value);
  }

  if ($code =~ /(make_pattern\s*=\s*)(.*)$/mg)
  {
    my $prefix = $1;
    my $pattern = $2;

    my $value = "$prefix$pattern";

    my $old_pos = pos $code;
    my $new_value = "$prefix(\$(subst \$(SPACE),|,\$(1)))";

    $new_value = "$prefix\\(\$(subst \$(SPACE),\\|,\$(1))\\)"
      if defined $find_info{'type'} && $find_info{'type'} eq 'GNU';

    substr( $code, pos($code) - length($value), length($value)) = $new_value;
    pos($code) = $old_pos - length($value) + length($new_value);

  }
  else
  {
    warn "Couldn't find make_pattern in Makefile to configure it\n";
  }

  return $code;
}

# --------------------------------------------------------------------------

sub Get_NonGNU_Find_Version
{
  my $program = shift;
  
  my $command = "$program -E . -regex './(R|L).*E' 2>" . File::Spec->devnull();
  my @results = `$command`;
  
  return undef unless @results;
    
  return 0;
}

1;
