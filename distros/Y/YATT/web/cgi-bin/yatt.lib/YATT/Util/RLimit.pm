package YATT::Util::RLimit;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use Exporter qw(import);

use BSD::Resource;

our @EXPORT_OK = qw(rlimit rlimit_vmem);
our @EXPORT = qw(rlimit_vmem);

sub rlimit_vmem {
  my ($limit_meg) = @_;
  rlimit(RLIMIT_VMEM, $limit_meg * 1024 * 1024);
}

sub rlimit {
  my ($resource, $limit) = @_;
  croak "rlimit: resource is undef!" unless defined $resource;
  croak "rlimit: limit is undef!" unless defined $limit;
  my ($soft, $hard) = getrlimit($resource)
    or croak "getrlimit($resource) failed: $!";

  unless (setrlimit($resource, $limit, $hard)) {
    croak "setrlimit($resource, $limit) failed: $!";
  }
}

1;
