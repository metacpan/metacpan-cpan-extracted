package YATT::Lite::Breakpoint;
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Exporter qw(import);

our @EXPORT_OK = qw(
		     break_load_parser
		     break_load_parsebody
		     break_load_parseentpath
		     break_parser

		     break_load_cgen
		     break_cgen

		     break_load_myapp

		     break_psgi_call

		     breakpoint
	       );
our @EXPORT = qw(breakpoint);

sub break_psgi_call {}

sub break_load_parser {}
sub break_load_parsebody {}
sub break_load_parseentpath {}
sub break_parser {}

sub break_load_cgen {}
sub break_cgen {}

sub break_load_entns {}
sub break_entns {}

sub break_load_core {}
sub break_core {}

sub break_load_xhf {}

sub break_load_vfs {}
sub break_load_facade {}

sub break_load_dirhandler {}

sub break_load_dispatcher {}
sub break_load_dispatcher_cgi {}
sub break_load_dispatcher_fcgi {}

sub break_load_myapp {}

sub break_load_dbschema {}
sub break_load_dbschema_dbic {}

sub breakpoint {}


1;
