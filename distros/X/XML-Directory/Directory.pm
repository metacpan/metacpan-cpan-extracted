package XML::Directory;

require 5.005_03;
BEGIN { require warnings if $] >= 5.006; }

use strict;
use vars qw(@ISA @EXPORT_OK $VERSION);
use File::Spec::Functions ();
use DirHandle;
use Carp;
use Cwd;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(get_dir);

$VERSION = '1.00';

######################################################################
# object interface

sub new {
    my ($class, $path, $details, $depth) = @_;
    $path = cwd   unless @_ > 1;
    $details = 2  unless @_ > 2;
    $depth = 1000 unless @_ > 3;

    $path = cwd if $path eq '.';

    my $self = {
	path    => File::Spec::Functions::canonpath($path),
	details => $details,
	depth   => $depth,
	error   => 0,
	catch_error => 0,	
	ns_enabled  => 0,
	doctype     => 0,
	rdf_enabled => 0,	
	n3_index    => '',	
	ns_uri      => 'http://gingerall.org/directory/1.0/',
	ns_prefix   => 'xd',
	encoding    => 'utf-8',	
    };
    bless $self, $class;
    return $self;
}

sub parse {
    my $self = shift;

    if ($self->{details} !~ /^[123]$/) {
	$self->doError(1,$self->{details})
    }
    if ($self->{depth} !~ /^\d+$/) {
	$self->doError(2,$self->{depth})
    }
    if ($self->{error} == 0) {

	$self->{seq} = 1; # a sequence used for doc:Position

	eval {
	    chdir ($self->{path}) or die "Path $self->{path} not found!\n";
	    # turning relative paths to absolute ones
	    $self->{path} = cwd;
	    my @dirs = File::Spec::Functions::splitdir($self->{path});
	    my $dirname = pop @dirs;

	    $self->doStartDocument;

	    if ($self->{ns_enabled}) {
		my @attr = ();
		my $decl = $self->_ns_declaration;
		push @attr, [$decl => $self->{ns_uri}];
		push @attr, ['xmlns:doc' => 
			     'http://gingerall.org/charlie-doc/1.0/']
		  if $self->{rdf_enabled};
		$self->doStartElement('dirtree', \@attr);
	    } else {
		$self->doStartElement('dirtree', undef);
	    }

	    if ($self->{details} > 1) {
		my @attr = ();
		push @attr, [version => $XML::Directory::VERSION];
	
		$self->doStartElement('head', \@attr);
		$self->doElement('path', undef, $self->{path});
		$self->doElement('details', undef, $self->{details});
		$self->doElement('depth', undef, $self->{depth});
		$self->doElement('orderby', [[code=>$self->order_by()]], undef);
		$self->doEndElement('head');
	    }
	    
	    my $rc = $self->_directory('', $dirname, 0);
	    return 0 if $rc == -1;
	    
	    $self->doEndElement('dirtree');
	    $self->doEndDocument;
	};
	  if ($@) {
	      chomp $@;
	      $self->doError(3,$@);
	  }
    }
}

sub set_path {
    my ($self, $path) = @_;
    $path = cwd unless @_ > 1;
    $self->{path} = File::Spec::Functions::canonpath($path),;
}

sub set_details {
    my ($self, $details) = @_;
    $details = 2 unless @_ > 1;
    $self->{details} = $details;
}

sub set_maxdepth {
    my ($self, $depth) = @_;
    $depth = 1000 unless @_ > 1;
    $self->{depth} = $depth;
}

sub get_path {
    my $self = shift;
    return $self->{path};
}

sub get_details {
    my $self = shift;
    return $self->{details};
}

sub get_maxdepth {
    my $self = shift;
    return $self->{depth};
}

sub enable_ns {
    my $self = shift;
    $self->{ns_enabled} = 1;
}

sub disable_ns {
    my $self = shift;
    $self->{ns_enabled} = 0;
}

sub enable_doctype {
    my $self = shift;
    $self->{doctype} = 1;
}

sub disable_doctype {
    my $self = shift;
    $self->{doctype} = 0;
}

sub get_ns_data {
    my $self = shift;
    return {
	    ns_enabled => $self->{ns_enabled},
	    ns_uri     => $self->{ns_uri},
	    ns_prefix  => $self->{ns_prefix},
	   };
}

sub encoding {
    my ($self, $code) = @_;
    if (@_ > 1) {
	$self->{encoding} = $code;
    } else {
	return $self->{encoding};
    }
}

sub error_treatment {
    my ($self, $val) = @_;
    if (@_ > 1) {
	$self->{catch_error} = 0 if $val eq 'die';
	$self->{catch_error} = 1 if $val eq 'warn';
    } else {
	return 'die' if $self->{catch_error} == 0;
	return 'warn' if $self->{catch_error} == 1;
    }
}

sub enable_rdf {
    my ($self, $index) = @_;
    $self->{ns_enabled} = 1;
    $self->{rdf_enabled} = 1;
    $self->{n3_index} = $index;
    eval { require RDF::Notation3; };
    chomp $@;
    $self->doError(5,$@) if $@;
}

sub disable_rdf {
    my $self = shift;
    $self->{rdf_enabled} = 0;
}

sub order_by {
  my ($self, $code) = @_;

  if (defined($code)) {
    $self->{'__orderby'} = $code;

  }

  return $self->{'__orderby'} || "df";
}

######################################################################
# original interface

sub get_dir {
    
    require XML::Directory::String;
    my $h = XML::Directory::String->new(@_);
    $h->parse_dir;
    return @{$h->{xml}};
}

######################################################################
# private procedures

sub _directory {
    my ($self, $path, $dirname, $level, $rdf_data_P, $rdf_P) = @_;

    # rdf metadata
    my $rdf_data = 0;       # RDF/N3 meta-data found or not
    my $doc_prefix = 'doc'; # default prefix
    my $rdf;                # rdf object
    my $stop = 0;           # end of recursion controlled by meta-data

    if ($self->{rdf_enabled}) {

	if (-f $self->{n3_index}) {
	    require RDF::Notation3::PrefTriples;
	    $rdf = RDF::Notation3::PrefTriples->new();
	    eval {_try_to_parse($rdf, $self->{n3_index})};
	    if ($@) {
		$self->doError(6,"$dirname, $@");
		return -1;
	    } else {
		$rdf_data = 1;
	    }
	}
	# parent N3 is read for uppermost directories only
	if (not $rdf_data_P) {
	    # link-safe way to get a parent dir
	    my $p_n3 = $self->{path} . $path;
	    $p_n3 =~ s/[^\/\\]+$/$self->{n3_index}/;
	    $p_n3 = File::Spec::Functions::canonpath($p_n3);

	    if (-f $p_n3) {
		require RDF::Notation3::PrefTriples;
		$rdf_P = RDF::Notation3::PrefTriples->new();
		eval {$rdf_P->parse_file($p_n3)};
		if ($@) {
		    $self->doError(6,"$dirname, $@");
		    return -1;
		} else {
		    $rdf_data_P = 1;
		}
	    }
	}
    }

    my @stat = stat '.';
    $dirname =~ s/&/&amp;/;

    my @attr = ([name => $dirname]);
    push @attr, ['depth', $level] if $self->{details} > 1;
    push @attr, ['uid', $stat[4]] if $self->{details} > 2;
    push @attr, ['gid', $stat[5]] if $self->{details} > 2;

    # rdf metadata NS
    if ($rdf_data) {
	foreach (keys %{$rdf->{ns}->{$rdf->{context}}}) {
	    if ($rdf->{ns}->{$rdf->{context}}->{$_} eq 
		'http://gingerall.org/charlie-doc/1.0/') {
		$doc_prefix = $_;
	    }
	    push @attr, 
	      ["xmlns:$_" => $rdf->{ns}->{$rdf->{context}}->{$_}];
	} 
    }
    if ($rdf_data_P) {
	foreach (keys %{$rdf_P->{ns}->{$rdf_P->{context}}}) {

	    unless ($rdf_data and $rdf->{ns}->{$rdf->{context}}->{$_} and 
		    $rdf->{ns}->{$rdf->{context}}->{$_} eq 
		    $rdf_P->{ns}->{$rdf_P->{context}}->{$_}) {

		# the same prefix bound to different NS in $rdf and $rdf_P
		# launches an error to prevent not well-formed XML
		if ($rdf_data and $rdf->{ns}->{$rdf->{context}}->{$_} and 
		    $rdf->{ns}->{$rdf->{context}}->{$_} ne 
		    $rdf_P->{ns}->{$rdf_P->{context}}->{$_}) {
		    my $msg = "$_ -> $rdf->{ns}->{$rdf->{context}}->{$_}, "
		      . "$rdf_P->{ns}->{$rdf_P->{context}}->{$_} in "
			. $self->{path} . $path . ' and its parent';
		    $self->doError(7,$msg);
		}
		
		push @attr, 
		  ["xmlns:$_" => $rdf_P->{ns}->{$rdf_P->{context}}->{$_}];
	    }
	} 
    }

    $self->doStartElement('directory', \@attr);

    $self->doElement('path', undef, $path) if $self->{details} > 1;

    my $atime = localtime($stat[8]);
    my $mtime = localtime($stat[9]);
    $self->doElement('access-time', [[epoch => $stat[8]]], $atime) 
      if $self->{details} > 2;
    $self->doElement('modify-time', [[epoch => $stat[9]]], $mtime) 
      if $self->{details} > 1;

    # rdf metadata for nested or uppermost dirs dirs
    if ($self->{details} > 1) {
	my $position_set = 0;
	my $cnt = 0;
	if ($rdf_data_P) {
	    $cnt = scalar @{$rdf_P->{triples}};
	    for (my $i = 0; $i < $cnt; $i++) {
		if ($rdf_P->{triples}->[$i]->[0] eq "<$dirname>") {
		    $self->doElement("$doc_prefix:Position",undef,$i+1,1);
		    $position_set = 1;
		    last;
		}
	    }
	    my $triples = $rdf_P->get_triples("<$dirname>");
	    foreach (@$triples) {
		$_->[2] =~ s/^"(.*)"$/$1/;
		$self->doElement($_->[1],undef,_esc($_->[2]),1);

		# looking for doc:Type = 'document'
		$_->[1] =~ s/^([_a-zA-Z]\w*)*:/$rdf_P->{ns}->{'<>'}->{$1}/;
		$stop = 1
		  if $_->[1] eq 'http://gingerall.org/charlie-doc/1.0/Type' 
		    and $_->[2] eq 'document';
	    }
	}
	if ($self->{rdf_enabled} and not($position_set)) {
	    $self->_doUnknownPosition($cnt, $doc_prefix); 
	}
    }

    foreach my $d (@{$self->_readdir()}) {

      if (-d $d) {

	# nested dirs
	if ($self->{depth} > $level) {
	  $level++;
	  
	  my $path = File::Spec::Functions::catfile($path, $d);
	  
	  unless ($stop) {
	    my $parent_dir = $self->{path} . $path;
	    $parent_dir =~ s/[^\/\\]+$//;
	    $parent_dir = File::Spec::Functions::canonpath($parent_dir);
	    
	    chdir $d or croak "Cannot chdir to $d, $!\n";
	    $self->_directory($path, $d, $level, $rdf_data, $rdf);
	    chdir $parent_dir; 

	    $level--;
	  }
	}

	# final dirs
	if ($self->{depth} == $level) {
	  
	  my $path = File::Spec::Functions::catfile($path, $d);
	  my @stat = stat "$d";
	  
	  $d =~ s/&/&amp;/;
	  
	  my @attr = ([name => $d]);
	  push @attr, ['depth', $level] if $self->{details} > 1;
	  push @attr, ['uid', $stat[4]] if $self->{details} > 2;
	  push @attr, ['gid', $stat[5]] if $self->{details} > 2;
	  
	  if ($self->{details} == 1) {
	    $self->doElement('directory', \@attr, undef)
	  } else {
	    $self->doStartElement('directory', \@attr);
	    
	    $self->doElement('path', undef, $path);
	    my $atime = localtime($stat[8]);
	    my $mtime = localtime($stat[9]);
	    $self->doElement('access-time', [[epoch => $stat[8]]], $atime) 
	      if $self->{details} > 2;
	    $self->doElement('modify-time', [[epoch => $stat[9]]], $mtime);
	    
	    # rdf metadata
	    my $position_set = 0;
	    my $cnt = 0;
	    if ($rdf_data) {
	      $cnt = scalar @{$rdf->{triples}};
	      for (my $i = 0; $i < $cnt; $i++) {
		if ($rdf->{triples}->[$i]->[0] eq "<$d>") {
		  $self->doElement("$doc_prefix:Position",undef,$i+1,1);
		  $position_set = 1;
		  last;
		}
	      }
	      my $triples = $rdf->get_triples("<$d>");
	      foreach (@$triples) {
		$_->[2] =~ s/^"(.*)"$/$1/;
		$self->doElement($_->[1],undef,_esc($_->[2]),1);
	      }
	    }
	    if ($self->{rdf_enabled} and not($position_set)) {
	      $self->_doUnknownPosition($cnt, $doc_prefix);
	    }
	    $self->doEndElement('directory');
	  }
	}
      }

      else {
	# files
	unless ($stop) {
	  unless ($d eq $self->{n3_index}) {
	    $self->_file($d, $level, $rdf_data, $rdf, $doc_prefix);
	  }
	}
      }
    }

    $self->doEndElement('directory');
}

sub _readdir {
  my $self = shift;

  my $path = &Cwd::getcwd();
  my $dh   = DirHandle->new($path);

  if (! $dh) {
    carp $!;
    return [];
  }

  my @dirs  = ();
  my @files = ();
  
  foreach ($dh->read()) {
    next if $_ =~ /^(\.{1,2})$/;
    (-d "$path/$_") ? push @dirs, $_ : push @files, $_;
  }

  if ($self->order_by() eq "fd") {
    return [sort(@files),sort(@dirs)];
  }
  
  elsif ($self->order_by() eq "a") {
    return [sort(@files,@dirs)];
  }

  elsif ($self->order_by() eq "z") {
    return [sort {$b cmp $a} (@files,@dirs)];
  }

  else {
    return [sort(@dirs),sort(@files)];
  }
}

sub _file($$$$) {
    my ($self, $name, $level, $rdf_data, $rdf, $doc_prefix) = @_;

    my @stat = stat $name;

    my @attr = ();
    push @attr, [name => _esc($name)];
    push @attr, [uid => $stat[4]] if $self->{details} > 2;
    push @attr, [gid => $stat[5]] if $self->{details} > 2;

    if ($self->{details} == 1) {
	$self->doElement('file', \@attr, undef)
    } else {
	$self->doStartElement('file', \@attr);

	my $mode;
	if (-r $name) {$mode = 'r' }else {$mode = '-'}
	if (-w $name) {$mode .= 'w' }else {$mode .= '-'}
	if (-x $name) {$mode .= 'x' }else {$mode .= '-'}
	$self->doElement('mode', [[code => $stat[2]]], $mode)
	    if $self->{details} > 1;
	$self->doElement('size', [[unit => 'bytes']], $stat[7])
	    if $self->{details} > 1;

	my $atime = localtime($stat[8]);
	my $mtime = localtime($stat[9]);
	$self->doElement('access-time', [[epoch => $stat[8]]], $atime)
	    if $self->{details} > 2;
	$self->doElement('modify-time', [[epoch => $stat[9]]], $mtime)
	    if $self->{details} > 1;

	# rdf metadata
	my $position_set = 0;
	my $cnt = 0;
	if ($rdf_data) {
	    $cnt = scalar @{$rdf->{triples}};
	    for (my $i = 0; $i < $cnt; $i++) {
		if ($rdf->{triples}->[$i]->[0] eq "<$name>") {
		    $self->doElement("$doc_prefix:Position",undef,$i+1,1);
		    $position_set = 1;
		    last;
		}
	    }
	    my $triples = $rdf->get_triples("<$name>");
	    foreach (@$triples) {
		$_->[2] =~ s/^"(.*)"$/$1/;
		$self->doElement($_->[1],undef,_esc($_->[2]),1);
	    }
	}
	if ($self->{rdf_enabled} and not($position_set)) {
	    $self->_doUnknownPosition($cnt, $doc_prefix);
	}
	$self->doEndElement('file');
    }
}

sub _ns_declaration {
    my $self = shift;
    
    return '' unless $self->{ns_enabled};
    return $self->{ns_prefix} ? "xmlns:$self->{ns_prefix}" : 'xmlns';
}

sub _doUnknownPosition {
    my ($self, $cnt, $prefix) = @_;
    
    $self->doElement("$prefix:Position", undef, $cnt + $self->{seq}, 1);
    $self->{seq}++;
}

sub _esc {
    my $str = shift;

    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    return $str;
}

sub _try_to_parse {
    my ($rdf, $path) = @_;
    my $done = 0;
    my $count = 0;

    until ($done or $count == 10) {
	eval {$rdf->parse_file("$path")};
	unless ($@) {
	    $done = 1;
	} else {
	    select(undef, undef, undef, 0.02);
	    $count++;
	}
      }
    die $@ if $@;
}

sub _msg {
    my ($self, $no) = @_;

    my %msg = (
	1   => 'details value invalid',
	2   => 'depth value invalid',
	3   => 'parse error',
	4   => 'input source not supported',
	5   => 'required module not found',
	6   => 'RDF data parse error', 
	7   => 'prefix bound to 2 namespaces',
	8   => 'content handler not found',
	);

    return $msg{$no};
}

1;

__END__
# Below is a documentation.

=head1 NAME

XML::Directory - returns a content of directory as XML

=head1 LICENSING

Copyright (c) 2001 Ginger Alliance. All rights reserved. This program is free 
software; you can redistribute it and/or modify it under the same terms as 
Perl itself. 

=head1 AUTHOR

Petr Cimprich, petr@gingerall.cz
Duncan Cameron, dcameron@bcs.org.uk
Aaron Straup Cope, asc@vineyard.net

=head1 SEE ALSO

perl(1).

=cut

