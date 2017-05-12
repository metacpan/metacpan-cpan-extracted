package YATT::Exception;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use base qw(YATT::Class::Configurable);
BEGIN {require Exporter; *import = \&Exporter::import}

use overload '""' => 'string';

sub Exception () {__PACKAGE__}

our @EXPORT_OK = qw(Exception is_normal_end can_retry);
our @EXPORT = @EXPORT_OK;

use YATT::LRXML::Node qw(stringify_node);

use YATT::Fields qw(cf_normal cf_error
		    cf_caller
		    cf_other
		    cf_retry
		    cf_node_obj cf_node cf_file cf_line
		    cf_error_title
		    cf_error_fmt
		    cf_error_param
		    cf_original_error
		  );
# cf_phase cf_target

sub title {
  (my MY $err) = @_;
  $err->{cf_error_title} || do {
    my $msg = $err->simple;
    $msg =~ s/[\(:\n].*// if defined $msg;
    $msg;
  };
}

sub simple {
  (my MY $err) = @_;
  $err->{cf_error} || do {
    my $msg = '';
    $msg .= sprintf($err->{cf_error_fmt}
		    , map {defined $_ ? $_ : "(null)"}
		    map {$_ ? @$_ : ()} $err->{cf_error_param})
      if $err->{cf_error_fmt};
    $msg
  };
}

sub string {
  (my MY $err) = @_;
  $err->{cf_error} || do {
    $err->simple . " " . $err->error_place . "\n";
  };
}

sub error_node {
  (my MY $err) = @_;
  $err->{cf_node} || do {
    $err->{cf_node_obj} ? stringify_node($err->{cf_node_obj}) : ""
  };
}

sub error_place {
  (my MY $err) = @_;
  my $place = '';
  $place .= "($err->{cf_node}), " if $err->{cf_node};
  $place .= "at file $err->{cf_file}" if $err->{cf_file};
  $place .= " line $err->{cf_line}" if $err->{cf_line};
  $place;
}

sub is_normal_end {
  (my MY $err) = @_;
  ref $err
    and UNIVERSAL::isa($err, MY)
      and not $err->{cf_error}
	and $err->{cf_normal};
}

sub can_retry {
  (my MY $err) = @_;
  return unless
    ref $err
      and UNIVERSAL::isa($err, MY)
	and not $err->{cf_error}
	  and $err->{cf_retry}
	    and ref $err->{cf_retry} eq 'ARRAY';
  wantarray ? @{$err->{cf_retry}} : $err->{cf_retry};
}

1;
