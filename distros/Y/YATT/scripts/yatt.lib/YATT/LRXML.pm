# -*- mode: perl; coding: utf-8 -*-
package YATT::LRXML;
use strict;
use warnings qw(FATAL all NONFATAL misc);

use YATT::Util qw(call_type);

require YATT::LRXML::Node;

sub Parser () { 'YATT::LRXML::Parser' }

use Carp;

# Returns YATT::LRXML::Cursor
sub read_string {
  my $pack = shift;
  my $parser = $pack->call_type(Parser => 'new');
  $parser->parse_string(@_);
}

sub read_handle {
  my $pack = shift;
  my $parser = $pack->call_type(Parser => 'new');
  $parser->parse_handle(@_);
}

sub read {
  my ($pack, $filename) = splice @_, 0, 2;
  my $fh;
  if (ref $filename) {
    $fh = $filename;
  } else {
    open $fh, '<', $filename or croak "Can't open '$filename': $!";
    unshift @_, filename => $filename;
  }
  $pack->read_handle($fh, @_);
}

#========================================

package YATT::LRXML::Scanner; # To scan tokens.
use strict;
use warnings qw(FATAL all NONFATAL misc);
use base qw(YATT::Class::ArrayScanner);
use YATT::Fields
  (['^cf_linenum' => 1]
   , ['^cf_last_nol' => 0] # last number of lines
   , qw(cf_last_linenum
	cf_path cf_metainfo));

sub expect {
  (my MY $path, my ($patterns)) = @_;
  return unless $path->readable;
  my $value = $path->{cf_array}[$path->{cf_index}];
  my @match;
  foreach my $desc (@$patterns) {
    my ($toktype, $pat) = @$desc;
    next unless @match = $value =~ $pat;
    $path->after_read($path->{cf_index}++);
    return ($toktype, @match);
  }
  return;
}

sub number_of_lines {
  (my MY $path, my ($pos)) = @_;
  $pos = $path->{cf_index} unless defined $pos;
  return 0 unless @{$path->{cf_array}};
  defined (my $tok = $path->{cf_array}[$pos])
    or return undef;
  $tok =~ tr:\n::;
}

sub after_read {
  (my MY $path, my ($pos)) = @_;
  if (defined $pos) {
    $$path{cf_last_nol} = $path->{cf_array}[$pos] =~ tr:\n::;
  }
  $path->{cf_last_linenum} = $path->{cf_linenum};
  unless (defined $$path{cf_linenum}) {
    $$path{cf_linenum} = 1;
  } else {
    $$path{cf_linenum} += $$path{cf_last_nol} || 0;
  }
}

use YATT::Exception qw(Exception);

sub token_error {
  (my MY $self, my ($mesg)) = @_;
  $self->Exception->new(error_fmt => $mesg
			, file => $self->{cf_metainfo}->in_file
			, line => $self->{cf_linenum});
}

#========================================
package YATT::LRXML::Builder; # To build tree.
use strict;
use warnings qw(FATAL all NONFATAL misc);
use base qw(YATT::Class::Configurable);
use YATT::Fields qw(^product ^parent ^is_switched
		    cf_endtag cf_startpos cf_startline cf_linenum);

use YATT::LRXML::Node qw(node_set_nlines);
sub Scanner () {'YATT::LRXML::Scanner'}

sub initargs {qw(product parent)}

sub new {
  my $pack = shift;
  my MY $path = $pack->SUPER::new;
  $path->init(@_) if @_;
  $path;
}

sub init {
  my MY $path = shift;
  @{$path}{qw(product parent)} = splice @_, 0, 2;
  $path->configure(@_) if @_;
  $path;
}

sub open {
  (my MY $parent, my ($product)) = splice @_, 0, 2;
  ref($parent)->new($product, $parent, $parent->configure
		    , startline => $parent->{cf_linenum}
		    , @_);
}

use YATT::Exception qw(Exception);

sub error {
  (my MY $self, my ($mesg, $param, @other)) = @_;
  $self->Exception->new(error_fmt => $mesg
			, error_param => $param
			, @other);
}

sub verify_close {
  (my MY $self, my ($tagname, $scan)) = @_;
  unless (defined $self->{cf_endtag}) {
    die $self->error("TAG '/%s' without open", [$tagname]
		     , file => $scan->cget('metainfo')->filename
		     , line => $scan->linenum);
  }
  unless ($tagname eq $self->{cf_endtag}) {
    die $self->error("TAG '%s' line %d closed by /%s"
		     , [$self->{cf_endtag}, $self->{cf_startline}, $tagname]
		     , file => $scan->cget('metainfo')->filename
		     , line => $scan->linenum);
  }
}

sub add {
  (my MY $self, my Scanner $scan) = splice @_, 0, 2;
  push @{$self->{product}}, @_;
  $self->{cf_linenum} = $scan->{cf_linenum};
  $self;
}

sub switch {
  (my MY $self, my ($elem)) = @_;
  unless ($self->{is_switched}) {
    $self->{is_switched} = $self->{product};
  }
  push @{$self->{is_switched}}, $elem;
  $self->{product} = $elem;
  $self;
}

sub DESTROY {
  my MY $self = shift;
  # switch した場合は?
  node_set_nlines($self->{product}
		  , $self->{cf_linenum} - $self->{cf_startline});
}

1;
