package YATT::Lite::Error; sub Error () {__PACKAGE__}
use strict;
use warnings qw(FATAL all NONFATAL misc);
use parent qw(YATT::Lite::Object);
use constant DEBUG_VERBOSE => $ENV{YATT_DEBUG_VERBOSE};

use Exporter qw/import/;
our @EXPORT_OK = qw/Error/;
our @EXPORT = @EXPORT_OK;

use YATT::Lite::MFields qw/file line tmpl_file tmpl_line
			   http_status_code
	      backtrace
	      reason format args/;
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
  $msg .= $error->{backtrace} // '' if DEBUG_VERBOSE;
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
  if ($error->{reason}) {
    $error->{reason};
  } elsif ($error->{format}) {
    if (Scalar::Util::tainted($error->{format})) {
      croak "Format is tainted in error reason("
	.join(" ", map {
	  if (defined $_) {
	    untaint_any($_)
	  } else {
	    '(undef)'
	  }
	} $error->{format}, lexpand($error->{args})).")";
    }
    BEGIN {
      warnings->unimport(qw/redundant/) if $] >= 5.021002; # for sprintf
    }
    sprintf $error->{format}, map {
      defined $_ ? $_ : '(undef)'
    } lexpand($error->{args});
  } else {
    "Unknown reason!"
  }
}

sub place {
  (my Error $err) = @_;
  my $place = '';
  $place .= " at file $err->{tmpl_file}" if $err->{tmpl_file};
  $place .= " line $err->{tmpl_line}" if $err->{tmpl_line};
  if ($err->{file}) {
    $place .= ",\n reported from YATT Engine: $err->{file} line $err->{line}";
  }
  $place .= "\n" if $place ne ""; # To make 'warn/die' happy.
  $place;
}

1;
