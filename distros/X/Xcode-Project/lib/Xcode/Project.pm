package Xcode::Project;

our $VERSION = '0.001001';

use strict;
use warnings;

use utf8;
use Cwd;
use FileHandle;
use File::Basename;
use JSON -convert_blessed_universally;
use Data::Structure::Util qw(unbless);
use open ':encoding(utf8)';

# OO
my $dst_dir;

sub new() {
  my $class = shift;
  my $file_path = shift;
  my $data = _read_data_from_file($file_path);
  my $self = $data;
  bless($self, $class);
  $self->_init();
  return $self;
}

sub save() {
  my $self = $_[0];
  my $json_string;
  unbless $self;
  delete $self->{'project'}; # delete the project from origin data
  $json_string = to_json($self,{allow_blessed=>1,convert_blessed=>1}); # convert object  to json
  open(my $fh, '>', "$dst_dir/project_mutable.json");
  print $fh $json_string;
  close $fh;

  unlink "$dst_dir/project.pbxproj"; # remvoe the origin project.pbxproj file
  # file handle
  system("/usr/bin/plutil -convert xml1 $dst_dir/project_mutable.json -o $dst_dir/project.pbxproj");
  die 'convert xml format file failured : $!' if $? == -1;
  unlink "$dst_dir/project_mutable.json"; # remvoe origin json file
}

sub target() {
  my $self = shift;
  my $target_name = shift;
  die "please speicfy the target name" until defined $target_name;
  my $targets = $self->targets;
  foreach (@$targets) {
   # PBXNativeTarget
    if ($_->{name} eq $target_name) {
     return $_;
   }
  }
  die "not the speicfy target name";
}

# Debug Release 
sub configuration() {
  my $self = shift;
  my $target = shift;
  my $configuration = shift;
  die "please speicfy the target name" until defined $target;
  $configuration = 'Release'  until defined $configuration;
  return $self->get_configuration_with_name($target, $configuration);
}

# keyVakue like 'key=value'
sub set_buildSettings_with_keyValue() {
  my $self = shift;
  my $target_name = shift;
  my $configuration_name = shift;
  die "please speicfy the target name" until defined $target_name;
  my $target = $self->target($target_name);
  my $configuration;
  $configuration = $self->get_configuration_with_name($target, $configuration_name);
  $self->set_entries($configuration, @_);
}

sub set_entries() {
  my $self = shift;
  $self = shift;
  foreach (@_) {
    my @words = split /=/, $_;
    my $key = shift @words;
    my $value = shift @words;
    my $find_it = 0;
    # first seach buildConfiguration key
    foreach (keys %$self) {
      if ($_ eq $key) {
	$self->{$key} = $value;
	$find_it = 1;
	last;
      }
    }

    # second seach buildSetting key
    if (not $find_it) {
      $self->{buildSettings}->{$key} = $value if exists $self->{buildSettings}->{$key};
      }
  }
}


# Getter & Setter
sub rootObject() {
  $_[0]->{'rootObject'} = $_[1] if defined $_[1];
   return $_[0]->{'rootObject'};
}

sub objects() {
  $_[0]->{'objects'} = $_[1] if defined $_[1];
  return $_[0]->{'objects'};
}

sub classes() {
  $_[0]->{'classes'} = $_[1] if defined $_[1];
  return $_[0]->{'classes'};
}

sub targets() {
  my $self = shift;
  my $rootObject = $self->rootObject;
  my $rootObjectHash = $self->get_value_by_key_in_objects($rootObject);
  my $key = $rootObjectHash->{'targets'};
  my $targets = [];
  foreach (@$key) {
    my $targetHash = $self->get_value_by_key_in_objects($_);
    push $targets, $targetHash;
  }
  return $targets;
}

sub get_value_by_key_in_objects() {
  my $self = shift;
  return $self->objects->{shift @_};
}

# get buildConfigurationList from the speicy target
sub buildConfigurationList_with_target() {
  my $self = shift;
  my $target = shift;
  my $buildConfigurationList = $target->{buildConfigurationList};
  return $self->get_value_by_key_in_objects($buildConfigurationList);
}

sub get_configuration_with_name() {
  my $self = shift;
  my $target = shift;
  my $configName = shift;
  my $buildConfigurationList = $self->buildConfigurationList_with_target($target);
  my $configurations = $buildConfigurationList->{buildConfigurations};
  foreach (@$configurations) {
    my $config = $self->get_value_by_key_in_objects($_);
    next if not defined $config->{name};
    if ($config->{'name'} eq $configName) {
      return $config;
    }
  }
  die "can't find the specify configuration name $configName with target ", $target->{"name"}, " line number:", __LINE__, "\n";
}

# private method
sub _init() {
  my $self = $_[0];
}

# private method

sub _read_data_from_file() {
  my $file_path = $_[0] or _get_default_path(); # if unpass the path then use default path
  my $dst_filename;
  
  if (defined $file_path && $file_path =~ m/project.pbxproj$/) {
    my $file_dir = dirname($file_path);
    $dst_dir = $file_dir;
    $dst_filename = "$file_dir/project_tmp.json";
    unlink $dst_filename;
    system("/usr/bin/plutil -convert json $file_path -o $dst_filename");
    die "failed to execute plutil: $!\n" unless $? != -1;
  } else {
    die "please specify the project.pbxproj file path line number: ", __LINE__;
  }
  
  my $fh = FileHandle->new;
  my $data;
  if ($fh->open($dst_filename)) {
    my $json = <$fh>;
    $data = decode_json($json);
    $fh->close;
  }
  unlink $dst_filename; # remvoe temp json file
  return $data;
}

sub _get_default_path () {
  # default is current dir is project root path
  my $current_dir = cwd();
  opendir (DIR, $current_dir) or die $!;
  
  while (my $file = readdir(DIR)) {
    # seach the *.xcodeproj directory
    if ($file =~ m/\.xcodeproj$/) {
      $current_dir = join '', $current_dir, "/", $file, '/project.pbxproj';
      last;
    }
  }

  closedir(DIR);
  return  $current_dir;
}

1;
