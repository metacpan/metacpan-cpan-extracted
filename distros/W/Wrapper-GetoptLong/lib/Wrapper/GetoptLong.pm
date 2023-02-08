package Wrapper::GetoptLong;

use 5.006;
use strict;
use warnings;

use File::Basename qw(basename);
use Getopt::Long qw(GetOptions);

# @(#) NMG/2WM - $Id: GetoptLong.pm,v 1.1.1.1 2023/02/08 02:16:13 user Exp $

=head1 NAME
Wrapper::GetoptLong - A wrapper for the Getopt::Long module

=head1 VERSION
Version 0.01

=head1 ABSTRACT 
A wrapper to the Getopt::Long module

=cut

our $VERSION = '0.01';

# Add your own module that defines the supporting functions, pass an instance of it to the constructor (new) as $obj.

our @EXPORT = qw($obj print_usage_and_die);

my  %opts=();
my  @usage_arr=();
my  $usage='';
our $obj;
my  $config_href=();
my  @opts_arr=();
my  $retval='';


# opt_arg_eg : is option argument example, to be used in the usage message.
# the -help option is a freebie, added by this module to the %OPT_CONFIG hash.
# with the print_usage_and_die exported function.

my $dflt_help_opt= {
     'desc'         => 'Will print this usage message and exit',
     'func'         => 'print_usage_and_die()',
     'opt_arg_eg'   => '',
     'opt_arg_type' => '',
};


=head1 SYNOPSIS

A wrapper for the Getopts::Long module.

use MyMainModule;  # has the definition for function the_date. In real practice, not a demo,
                   # MyMainModule defines all the support functions for the options.
 
use Wrapper::GetoptLong;
my $mmm=MyMainModule->new();
my %OPTS_CONFIG=(
   'the_date'  => {
     'desc'       => q^Print today's date. Takes date_format as argument.^,
     'func'       => q^MyModule::the_date($obj->opts{'the_date'})^,
     'opt_arg_eg'   => '%m/%d/%Y',
     'opt_arg_type' => 's',
     },
);

@ARGV=('--the_date', '%m/%d/%Y');
my $golw_obj=new Wrapper::GetoptLong(\%OPTS_CONFIG, $mmm);
$golw->run_getopt();
my $rc=$golw->execute_opt();
if(ref($rc))
  {
  use Data::Dumper;
  print Dumper $rc;
  }
else
  {
  print $rc, "\n";
  }
=cut

=head2 DEMO
A full demo is available on GitHub.
Requires a database , mySQL or MariaDB - the repository includes a file to create and populate the database.
https://github.com/ngabriel8/WGOLDemo

=head1 EXPORT

obj
print_usage_and_die

=head1 METHODS

=over 4

=cut


=item I<new>

  my $golw = new Wrapper::GetoptLong($config_href, $MyObj);

The constructor takes two arguments: a reference to an OPTS_CONFIG hash and an object ref (optional).

=cut

sub new
{
my $name                                = basename(__FILE__, '.pm');
my $golw_usage=sprintf('Usage: my $gow=new %s(\%%OPTS_CONFIG, $object);', $name);
$!=0;
(scalar(@_) == 1) && die $golw_usage;
my $class=shift;
($config_href, $obj)=@_;
my $self=();
$self->{'name'}=$name;
bless($self, $class);
my @opts=sort keys %{$config_href};
my @fnd=grep /^help$/i, @opts;
($#fnd == -1) && ($config_href->{'help'}=$dflt_help_opt);

push(@usage_arr, "Usage $0: ");
$self->init_getopts();
return $self;
} # new

=back

=head2 print_usage_and_die
Prints Usage message for the calling script and exists.
=cut

sub print_usage_and_die
{
my($self, $extra_msg)=@_;
$extra_msg ||=undef;

(defined $extra_msg) && print STDERR $extra_msg;
print STDERR $usage;
exit 0;
} # print_usage_and_die

=head2 init_getopts
Called by the constructor. Initializes usage, opts_array ...etc, for the GetOption call.
=cut

sub init_getopts
{
my ($self)=@_;
my @opts_no_arg=();
my @opts_with_arg=();
$self->mk_get_opt_array(\@opts_no_arg, \@opts_with_arg);
# cmd_str looks like this : GetOptions(\%opts, @opts_arr) || print_usage_and_die($usage, 'Invalid command line option');^;
my $no_arg_str='';
my $count=scalar(@opts_no_arg);
if($count > 0)
  {
  $no_arg_str = ($count == 1) ? sprintf('-%s', $opts_no_arg[0]) : sprintf('-[%s]', join('|', @opts_no_arg));
  # push(@usage_arr, $no_arg_str);
  $usage_arr[0] .= " $no_arg_str";
  }
my $with_arg_str='';
$count=scalar(@opts_with_arg);
if($count > 0)
  {
  $with_arg_str = join("\n", @opts_with_arg);
  push(@usage_arr, $with_arg_str);
  }
$self->add_desc();
my @desc_arr=();
foreach (@usage_arr)
  {
  (/^$/) && next;
  push(@desc_arr, $_);
  }
$usage=join("\n", @desc_arr) . "\n";
($#ARGV == -1) && print_usage_and_die();
} # init_getopts

=head2 mk_get_opt_array
Makes the array of valid options to pass to GetOption.
=cut

sub mk_get_opt_array
{
my ($self, $no_arg_aref, $with_arg_aref)=@_;
@opts_arr=();
my @no_args=();
foreach my $opt (sort keys %{$config_href})
  {
  my $opt_str=$opt;
  if($config_href->{$opt}->{'opt_arg_type'} eq '')
    {
    push(@no_args, $opt);
    }
  else
    {
    $opt_str .= sprintf(':%s', $config_href->{$opt}->{'opt_arg_type'});
    my $eg=$config_href->{$opt}->{'opt_arg_eg'};
    push(@{$with_arg_aref}, "--$opt $eg");
    } 
  push(@opts_arr, $opt_str);
  } # foreach $opt
if(scalar(@no_args))
  {
  my @tmp=();
  my $help=undef;
  foreach (@no_args)
    {
    (/^help$/i) ? ($help=$_) : push(@tmp, $_);
    } # foreach @no_args
  (defined $help) && unshift(@tmp, $help);
  push(@{$no_arg_aref}, @tmp);
  } # if scalar(@no_args)
} # mk_get_opt_array


=head2 add_desc
Makes the description part of the usage message.

=cut

sub add_desc
{
my ($self)=@_;
my @desc=();
my $help='';
foreach my $opt (sort keys %{$config_href})
  {
  my $str='';
  if($opt =~ /^help$/i)
    {
    $help="-$opt $config_href->{$opt}->{'desc'}";
    }
  elsif($config_href->{$opt}->{'opt_arg_type'} eq '')
    {
    $str="-$opt  $config_href->{$opt}->{'desc'}";
    }
  else
    {
    $str="--$opt  $config_href->{$opt}->{'desc'}";
    }
  push(@desc, $str);
  } # foreach $opt

($help) && unshift(@desc, $help);
push(@usage_arr, @desc);
} # add_desc

=head2 run_getopt
Calls the GetOptions function to populate the %opts hash.

=cut

sub run_getopt
{
my ($self)=@_;
GetOptions(\%opts, @opts_arr) || print_usage_and_die('Invalid command line option');
} # run_getopt

=head2 execute_opt
If %opts is not empty, executes the function associated with that option (passed from the command line).

=cut

sub execute_opt
{
my ($self)=@_;
my $rc=0;

foreach my $opt (sort keys %opts)
  {
  if(defined $config_href->{$opt})
    {
    my $cmd=sprintf('$retval=%s;', $config_href->{$opt}->{'func'});
    # print "Working on $opt, evaluating $cmd\n";
    eval($cmd);
    if(!$@)
      {
      ($cmd =~ /print_usage_and_die/) && exit(0);
      $rc=$retval;
      }
    else
      {
      print STDERR $@;
      $rc=1;
      }
    last; # There should be only one opt active. But, be safe...
    }
  } # foreach $opt
return $rc;
} # run_getopt

=head1 AUTHOR

Nazar Gabriel, C<< <ngabriel@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-wrapper-getoptlong at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Wrapper-GetoptLong>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Wrapper::GetoptLong

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Wrapper-GetoptLong>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Wrapper-GetoptLong>

=item * Search CPAN

L<https://metacpan.org/release/Wrapper-GetoptLong>

=back


=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Nazar Gabriel.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Wrapper::GetoptLong
