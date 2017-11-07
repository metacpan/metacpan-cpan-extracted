#!/use/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Win32::Packer;
use Log::Any::Adapter;

my $app_name = 'PerlApp';;
my $keep_work_dir;
my @extra_inc;
my @extra_modules;
my @extra_exe;
my @extra_dll;
my $fake_os = $^O;
my $log_file;
my $log_level = 'info';
my $work_dir;
my $strawberry;
my $strawberry_c_bin;
my $cache;
my $clean_cache;

GetOptions('app-name|a=s' => \$app_name,
           'work-dir|work|w=s' => \$work_dir,
           'keep-work-dir|k' => \$keep_work_dir,
           'extra-inc|I=s' => \@extra_inc,
           'extra-module|module|M=s' => \@extra_modules,
           'extra-exe|exe|e=s' => \@extra_exe,
           'extra-dll|dll|d=s' => \@extra_dll,
           'fake-os|O=s' => \$fake_os,
           'log-file|log|l=s' => \$log_file,
           'log-level|L=s' => \$log_level,
           'cache-dir|cache|c=s' => \$cache,
           'clean-cache|C' => \$clean_cache,
           '_strawberry=s' => \$strawberry,
           '_strawberry-c-bin=s' => \$strawberry_c_bin );

s/(\.exe)?$/.EXE/i for @extra_dll;
s/(\.dll)?$/.DLL/i for @extra_dll;

Log::Any::Adapter->set((defined $log_file ? ('File', $log_file) : 'Stderr'),
                       log_level => $log_level);

my %args = ( app_name => $app_name,
             work_dir => $work_dir,
             keep_work_dir => $keep_work_dir,
             scripts => [ @ARGV ],
             extra_inc => \@extra_inc,
             extra_modules => \@extra_modules,
             extra_exe => \@extra_exe,
             extra_dll => \@extra_dll,
             _OS => $fake_os,
             cache => $cache,
             clean_cache => $clean_cache,
             strawberry => $strawberry,
             strawberry_c_bin => $strawberry_c_bin);

delete $args{$_} for grep !defined $args{$_}, keys %args;

my $p = Win32::Packer->new(%args);

$p->build;
