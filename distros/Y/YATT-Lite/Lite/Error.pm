package YATT::Lite::Error; sub Error () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use parent qw(YATT::Lite::Object);
use constant DEBUG_VERBOSE => $ENV{YATT_DEBUG_VERBOSE};

use Exporter qw/import/;
our @EXPORT_OK = qw/Error/;
our @EXPORT = @EXPORT_OK;

use YATT::Lite::MFields qw/cf_file cf_line cf_tmpl_file cf_tmpl_line
			   cf_http_status_code
	      cf_backtrace
	      cf_reason cf_format cf_args/;
use overload qw("" message
		eq streq
		bool has_error
	      );
use YATT::Lite::Util qw(lexpand untaint_any);
use Carp;
require Scalar::Util;

sub has_error {
  defined $_[0];
}

sub streq {
  my ($obj, $other, $inv) = @_;
  ($obj, $other) = ($other, $obj) if $inv;
  $obj->message eq $other;
}

sub message {
  my Error $error = shift;
  my $msg = $error->reason . $error->place;
  $msg .= $error->{cf_backtrace} // '' if DEBUG_VERBOSE;
  $msg;
}

sub byte_message {
  (my Error $error) = @_;
  my $msg = $error->reason; # Place may not be useful for SiteApp->error_handler
  Encode::_utf8_off($msg);
  $msg;
}

sub reason {
  my Error $error = shift;
  if ($error->{cf_reason}) {
    $error->{cf_reason};
  } elsif ($error->{cf_format}) {
    if (Scalar::Util::tainted($error->{cf_format})) {
      croak "Format is tainted in error reason("
	.join(" ", map {
	  if (defined $_) {
	    untaint_any($_)
	  } else {
	    '(undef)'
	  }
	} $error->{cf_format}, lexpand($error->{cf_args})).")";
    }
    BEGIN {
      warnings->unimport(qw/redundant/) if $] >= 5.021002; # for sprintf
    }
    sprintf $error->{cf_format}, map {
      defined $_ ? $_ : '(undef)'
    } lexpand($error->{cf_args});
  } else {
    "Unknown reason!"
  }
}

sub place {
  (my Error $err) = @_;
  my $place = '';
  $place .= " at file $err->{cf_tmpl_file}" if $err->{cf_tmpl_file};
  $place .= " line $err->{cf_tmpl_line}" if $err->{cf_tmpl_line};
  if ($err->{cf_file}) {
    $place .= ",\n reported from YATT Engine: $err->{cf_file} line $err->{cf_line}";
  }
  $place .= "\n" if $place ne ""; # To make 'warn/die' happy.
  $place;
}

1;
