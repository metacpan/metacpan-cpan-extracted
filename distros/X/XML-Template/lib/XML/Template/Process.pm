###############################################################################
# XML::Template::Process
#
# Copyright (c) 2002-2003 Jonathan A. Waxman <jowaxman@law.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package XML::Template::Process;
use base qw(XML::Template::Base);

use strict;
use CGI qw(header);
use IO::String; # XXX
use Mail::Mailer; # XXX
use Data::Dumper;
use XML::SAX::ParserFactory;
use XML::Template::Exception;


=pod

=head1 NAME

XML::Template::Process - The main XML::Template document processing 
module.

=head1 SYNOPSIS

This module is the main XML::Template document processing module.  It
loads, compiles, stores (and caches), and evaluates XML documents.  In
addition is contains many useful subroutines for processing documents.

=head1 CONSTRUCTOR

A constructor method C<new> is provided by L<XML::Template::Base>.  A list
of named configuration parameters may be passed to the constructor.  The
constructor returns a reference to a new parser object or under if an
error occurred.  If undef is returned, you can use the method C<error> to
retrieve the error.  For instance:

  my $parser = XML::Template::Process->new (%config)
    || die XML::Template::Process->error;

The following named configuration parameters may be passed to the
constructor:

=over 4

=item CGIHeader

Whether to print a CGI header.  The default is 1.

=item Cache

A blessed object that handles caching compiled XML documents to memory.  
This value will override the default value C<$CACHE> in 
L<XML::Template::Config>.  The default cache object is of the class
L<XML::Template::Cache>.

=item NoCache

Whether to cache compiled XML documents to memory.  If 1, a Cache object
is prepended to the load and put chains of responsibility.  The default is
1.

=item FileCache

A blessed object that handles caching compiled XML documents to files.  
This value will override the default value C<$FILE_CACHE> in 
L<XML::Template::Config>.  The default file cache object is of the class 
L<XML::Template::Cache::File>.

=item NoFileCache

Whether to cache compiled XML documents to files.  If 1, a FileCache
object is prepended to the load and put chains of responsibility.  The
default is 1.

=item Load

A single object or reference to an array of objects to be added to the 
load chain of responsibility.

=item Handler

A blessed XML::SAX handler object used to parse XML document.  This value 
will override the default value C<$HANDLER> in L<XML::Template::Config>.  
The default parser handler is of the class L<XML::Template::Parser>.

=item Subroutine

A blessed object for default XML::Template subroutine handling.  This 
value will override the default value C<$SUBROUTINE> in 
L<XML::Template::Config>.  The default subroutine object is of the class 
L<XML::Template::Subroutine>.

=item Put

A single object or reference to an array of objects to be added to the 
put chain of responsibility.

=item Vars

A blessed object for XML::Template variable handling.  This value will 
override the default value C<$VARS> in L<XML::Template::Config>.  The 
default vars object is of the class L<XML::Template::Vars>.

=back

=head1 PRIVATE METHODS

=head2 _init

This method is the internal initialization function called from
L<XML::Template::Base> when a new process object is created.

=cut

sub _init {
  my $self   = shift;
  my %params = @_;

  print "XML::Template::Process::_init\n" if $self->{_debug};

  # Whether to print a CGI header.
  $self->{_cgi_header} = 1;
  $self->{_cgi_header} = $params{CGIHeader} if defined $params{CGIHeader};
  $self->{_cgi_header_printed} = 0;

  # Whether to print at all.
  $self->{_print} = 1;

  # Create the load Chain of Responsibility list.
  if (defined $params{Load}) {
    push (@{$self->{_load}}, ref ($params{Load}) eq 'ARRAY'
                               ? @{$params{Load}}
                               : $params{Load});
  } else {
    require 'XML/Template/Element/File/Load.pm';
    $self->{_load} = [XML::Template::Element::File::Load->new ()];
  }

  $self->{_nofilecache} = defined $params{NoFileCache}
                            ? $params{NoFileCache}
                            : 0;
  my $file_cache;
  if (! $self->{_nofilecache}) {
    $file_cache = $params{FileCache}
      || XML::Template::Config->file_cache (%params)
      || return $self->error (XML::Template::Config->error);
    unshift (@{$self->{_load}}, $file_cache);
  }

  $self->{_nocache} = defined $params{NoCache}
                        ? $params{NoCache}
                        : 0;
  my $cache;
  if (! $self->{_nocache}) {
    $cache = $params{Cache}
      || XML::Template::Config->cache (%params)
      || return $self->error (XML::Template::Config->error);
    unshift (@{$self->{_load}}, $cache);
  }

  # Get SAX handler.
  $self->{_handler} = $params{Handler} || XML::Template::Config->handler (%params)
    || return $self->error (XML::Template::Config->error);

  $self->{_subroutine} = $params{Subroutine} || XML::Template::Config->subroutine (%params)
    || return $self->error (XML::Template::Config->error);

  # Create the put Chain of Responsibility list.
  $self->{_put} = [];
  push (@{$self->{_put}}, $cache) if ! $self->{_nocache};
  push (@{$self->{_put}}, $file_cache) if ! $self->{_nofilecache};
  push (@{$self->{_put}}, ref ($params{Put}) eq 'ARRAY'
                            ? @{$params{Put}}
                            : $params{Put}) if defined $params{Put};

  # Get vars.
  $self->{_vars} = $params{Vars} || XML::Template::Config->vars (%params)
                   || return $self->error (XML::Template::Config->error);
  $self->{_vars}->create_context ();

  return 1;
}

=pod

=head1 PUBLIC METHODS

=head2 print

  my $code = "\$process->print ($text);\n";

This method is used to print text from XML documents.  Typically it will
be used in Perl code generated by XML::Template.  A CGI header will be
printed if the onstructor parameter C<CGIHeader> is set to 1 and one has
not yet been printed.

=cut

sub print {
  my $self = shift;
  my $text = join ('', @_);

  my $print = 0;

  my $cfh = select;
  if (ref ($cfh) ne 'IO::String'
      && $self->{_cgi_header}
      && ! $self->{_cgi_header_printed}) {
    if ($text !~ /^\s*$/) {
      $self->{_cgi_header_printed} = 1;
      print CGI::header;
      print $text if $self->{_print};
    }
  } else {
    print $text if $self->{_print};
  }

  return 1;
}

=pod

=head2 subroutine

  my $code = "\$process->subroutine ('$subname', $text, \@params)";

This method is used to handle XML::Template subroutine calls.  It is
typically not used directly, but called from Perl code generated by
XML::Template.  The first parameter is the XML::Template subroutine name,
the second is the variable on which the XML::Template subroutine is being
called, and the remaining parameters are additional parameters that are
being passed to the XML::Template subroutine.  If no modules is associated
with the XML::Template subroutine in the XML::Template configuration file,
the default subroutine module (specified by the constructor parameter
C<Subroutine>) is used.

=cut

sub subroutine {
  my $self = shift;
  my ($subroutine, $var, @params) = @_;

  my $value = $self->{_vars}->get ($var);

  my $subroutine_info = $self->get_subroutine_info ($subroutine, 'module');
  my $module = defined $subroutine_info ? $subroutine_info->{module}
                                        : $self->{_subroutine};

  eval "use $module";
  die $@ if $@;
  return ($module->$subroutine ($self, $var, $value, @params));
}

=pod

=head2 process

  $process->process ($name, $vars)
    || die $process->error ();

This is the main XML document processing subroutine.  The first parameter 
is the name of the XML document.  The format of this parameter depends on 
loader.  For instance, a block loader will interpret the name as a primary 
key in a database table.  The file loader will interpret the name as a 
file.  The second parameter is a reference to a hash containing name/value 
pairs of defined variables.

=cut

sub process {
  my $self   = shift;
  my ($name, $vars) = @_;

  print ref ($self) . "::process\n" if $self->{_debug};

  # Load XML, calling each method in the load chain of command.
  my $document;
  foreach my $load (@{$self->{_load}}) {
    next if ! $load->{_enabled};

    print "XML::Temoplate::Process::process : Calling " . ref ($load) . "->load.\n" if $self->{_debug};

    $document = eval { $load->load ($name) };
    return $self->error ('Process', "Could not load document '$name': $@") if $@;
    return $self->error ($load->error) if $load->error;

    last if defined $document;
  }
  return $self->error ('Process', "Could not find document '$name'") if ! defined $document;

  if (defined $document) {
    # Add passed vars.
    $self->{_vars}->create_context ();
    while (my ($var, $value) = each %$vars) {
# XXX
      $var =~ s/^\01//;
      $self->{_vars}->set ($var => $value);
    }

    # If document not yet compiled, compile.
    if (! $document->compiled) {
      # Create a new handler object.
      my $module = $self->{_handler};
      XML::Template::Config->load ($module)
        || return $self->error ('Process', XML::Template::Config->error);
      my $handler = $module->new ();

      # Replace variable tags with 'core:element' tag.
      my $xml = $document->xml;
      $xml =~ s/<\/([^\s]*\${[^}]*}[^\s>]*>)/<\/core:element>/g;
      $xml =~ s/<([^\s>]*\${[^}]*}[^\s>]*)/<core:element core:name="$1"/g;

      # Parse XML document.
      my $parser = XML::SAX::ParserFactory->parser (Handler => $handler);
      my $code = eval { $parser->parse_string ("<__xml>$xml</__xml>") };
      return $self->error ('Process', $@) if $@;
      $document->code ($code);
    }

    # Put code, calling each method in the put chain of command.
    foreach my $put (@{$self->{_put}}) {
      print "XML::Template::Process::process : Calling " . ref ($put) . "->put.\n" if $self->{_debug};

      eval { $put->put ($name, $document) };
      return $self->error ('Process', "Could not put document '$name': $@") if $@;
#      return $self->error ($put->error) if $put->error;
    }

    # Run code.
    my $code = eval $document->{_code};
    return $self->error ('Process', "Error evaluating document code: $@") if $@;
    eval { &$code ($self); };
    if ($@) {
      my ($type, $error) = ref ($@) ? ($@->type, $@->info) : ('Unknown', $@);
      return $self->error ($type, $error);
    }

    # Remove variable context.
    $self->{_vars}->delete_context ();

    # Error if document is empty.
    if (! $self->{_cgi_header_printed}) {
      return $self->error ('Empty', "Document \"$name\" contains no content.");
    }
  }
  
  return 1;
}

=pod

=head2 get_load

  my %loaded = $process->get_load ()

This method returns a hash that contains module name / enabled flag pairs 
that lists which loader modules are loaded and enabled.  This is used with 
the method C<set_load> to selectively dis/enable loader modules.  It is 
definately not the best way to handle this sort of thing!

=cut

sub get_load {
  my $self = shift;
  my @modules = @_;

  # Slurp current load modules into a hash indexed by module name.
  my %modules;
  foreach my $module (@{$self->{_load}}) {
    $modules{ref ($module)} = $module;
  }
  @modules = keys %modules if ! scalar (@modules);

  my %loaded;
  foreach my $module (@modules) {
    $loaded{$module} = defined $modules{$module} ? $modules{$module}->{_enabled}
                                                 : undef;
  }

  return %loaded;
}

=pod

=head2 set_load

  $process->set_load (%load)

This method is used to selectively dis/enable loader modules.  It takes a 
hash containing loader module names / enable flag pairs.  For each loader 
module listed, if the flag is set to 1, the module will be enabled, 
otherwise it will be disabled.  I would like to replace this with 
something more sensible if it's even necessary.

=cut

sub set_load {
  my $self = shift;
  my %params = @_;

  # Slurp current load modules into a hash indexed by module name.
  my %modules;
  foreach my $module (@{$self->{_load}}) {
    $modules{ref ($module)} = $module;
  }

  my %delete;
  while (my ($module, $loaded) = each %params) {
    my $module_params = {};
    ($loaded, $module_params) = @$loaded if ref ($loaded);

    if (defined $loaded) {
      if (defined $modules{$module}) {
        $modules{$module}->{_enabled} = $loaded;
      } else {
        if ($loaded) {
          XML::Template::Config->load ($module)
            || return $self->error (XML::Template::Config->error ());
          push (@{$self->{_load}}, $module->new (%$module_params));
        }
      }
    } else {
      $delete{$module} = 1;
    }
  }
  if (scalar (keys %delete)) {
    my @new_load;
    foreach my $module (@{$self->{_load}}) {
      push (@new_load, $module) if ! $delete{ref ($module)};
    }
    $self->{_load} = \@new_load;
  }

  return 1;
}

=pod

=head2 generate_where

  my $where = $self->generate_where (\%attribs, $table);

This method returns the where clause of an SQL statement.  The first
parameter is a reference to a hash containing attributes which are the
column names/values to be matched in the where clause.  The second
parameter is the name of the default table to use for columns given in
C<%attribs>.  If column names do not have C<.> in them, they are prepended
by C<$table>.  If column values have C<%> in them, C<LIKE> is used for the
comparison test.  Otherwise C<=> is used.  For instance,

  my $where = $self->generate_where ({type      => 'newsletter',
                                      'map.num' => 5,
                                      date      => '2002%'},
                                     'items')

will return the following SQL where clause:

  items.type='newsletter' and map.num='5' and items.date like '2002%'

=cut

sub generate_where {
  my $self = shift;
  my ($attribs, $table) = @_;

  my $where;
  while (my ($attrib, $value) = each %$attribs) {
    my ($attrib_namespace, $attrib_name);
    if ($attrib =~ /^{([^}]+)}(.*)$/) {
      $attrib_namespace = $1;
      $attrib_name = $2;
    } else {
      $attrib_namespace = '';
      $attrib_name = $attrib;
    }

    $where .= ' and ' if defined $where;
    $where .= '(';
    my $twhere;
    foreach my $tvalue (split (/\s*,\s*/, $value)) {
      $twhere .= ' or ' if defined $twhere;
      $twhere .= "$table." if $attrib_name !~ /\./;
# xxx
die if $value =~ /;/;
      $tvalue =~ s/;/\\;/g;
      $tvalue =~ s/'/\\'/g;
      if ($tvalue =~ /%/) {
        $twhere .= "$attrib_name like '$tvalue'";
      } else {
        $twhere .= "$attrib_name='$tvalue'";
      }
    }
    $where .= "$twhere)";
  }

  return $where;
}

sub load {
  my $self = shift;
  my @load = @_;

  my $pos = 0;
  $pos++ if ! $self->{_nocache};
  $pos++ if ! $self->{_nofilecache};
  my @old_load = splice (@{$self->{_load}}, $pos);
  push (@{$self->{_load}}, @load);

  return @old_load;
}

=pod

=head1 AUTHOR

Jonathan Waxman
<jowaxman@bbl.med.upenn.edu>

=head1 COPYRIGHT

Copyright (c) 2002-2003 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


1;
