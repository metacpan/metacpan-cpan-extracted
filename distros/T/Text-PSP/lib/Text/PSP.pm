package Text::PSP;
$VERSION = '1.013';
use strict;

use Carp qw(croak carp);
use File::Path qw(mkpath);

=pod

=head1 NAME

Text::PSP - Perl extension implementing a JSP-like templating system.

=head1 SYNOPSIS

  use Text::PSP;
  
  my $psp_engine = Text::PSP->new(
	template_root	=> 'templates',
	workdir	=> '/tmp/psp_work',
  );
  my $template_object = $psp_engine->template('/home/joost/templates/index.psp');
  my @out = $template_object->run(@arguments);

  print @out;

=head1 DESCRIPTION

The Text::PSP system consists of 3 modules: L<Text::PSP>, L<Text::PSP::Parser|Text::PSP::Parser> and L<Text::PSP::Template|Text::PSP::Template>. The parser creates perl modules from the input files, which are subclasses of Text::PSP::Template. Text::PSP is the module overseeing the creation and caching of the templates.

You can use the basics of the JSP system:

	<% 
		my $self = shift;
		# code mode
		my @words = qw(zero one two three);
	%>
		Hello, World - this is text mode
	<%=
		map { $i++ . ' = ' . $_ } @words
	%>
		That was an expression 
	<%!
		# define mode
		sub method {
			return "method called";
		}
	%>
	<%= $self->method %>
		And insert mode again

	includes
	<%@file include="some/page.psp"%>

	and includes that search for a file upwards to the template
	root
	<%@file find="header.psp"%>

For a complete description of the template constructs, see L<Text::PSP::Syntax>.

=head1 METHODS

=head2 new

	my $psp = Text::PSP->new( 
		template_root => './templates',
		workdir       => './work',
	);


Instantiates a new Text::PSP object.

=head3 Parameters

=over 4

=item template_root

The root directory for the template files. No templates outside the template_root can be run by this Text::PSP object. This is a required parameter.

=item workdir

The directory in which to store the translated templates. This is a required parameter.

=item create_workdir

If this parameter is true and the workdir doesn't exist, one will be created. Default is false.

=back


=cut

sub new {
	my $class = shift;
	my $self = bless { 
		workdir => undef,
		remove_spaces => 0,     # currently unused
		template_root => undef,
                create_workdir => 0,
		@_ 
	},$class;
	croak "No workdir given" unless defined $self->{workdir};
	croak "No template_root given" unless defined $self->{template_root};
        unless (-d $self->{workdir}) {
            if ($self->{create_workdir}) {
                mkpath $self->{workdir} or croak "Can't create workdir '$self->{workdir}': $!"
            }
            else {
    	        croak "Workdir $self->{workdir} does not exist" unless (-d $self->{workdir});
            }
        }
	return $self;
}

=head2 template

	my $template = $psp->template("index.psp");
        # or
        my $template = $psp->template("index.psp", force_rebuild => 1);


Get a template object from a template file. This will translate the template file into a Text::PSP::Template module if needed.

Optional arguments:

=over 4

=item force_rebuild

Always rebuild the resulting .pm file and reload it (useful for development). Normally, the .pm file is only built if the I<top most> template file is newer than the resulting module. This can be really annoying if you're developing and are only changing some included file.

=back

=cut

sub template {
	croak "Text::PSP template method takes 1+ argument" if @_ < 2;
	my ($self,$filename,%options) = @_;
	my ($pmfile,$classname) = $self->translate_filename($filename);
	if ( $options{force_rebuild} or ( !-f $pmfile ) or  -M _ > -M "$self->{template_root}/$filename" ) {
		delete $INC{ $pmfile };
		$self->write_pmfile($filename,$pmfile,$classname);
	}
	require $pmfile;
	return $classname->new( engine => $self, filename => $filename);
}

=head2 find_template

	my $template = $psp->find_template("some/path/index.psp");
        # or
        my $template = $psp->find_template("some/path/index.psp", force_rebuild => 1);


Similar to the C<template()> method, but searches for a file starting at the specified path, working up to the template_root.

The returned template object will behave as if it really were in the specified path, regardless of the real location of the template in the file system, so for instance any C<include> and C<find> directives will work from that path.
=cut

sub find_template {
	croak "Text::PSP find_template method takes 1+ argument" if @_ < 2;
	my ($self,$directory,%options) = @_;
	$directory =~ s#([^/]+)$## or croak "Cannot find a filename from $directory";
	my $filename = $1;
	$directory = $self->normalize_path($directory);
	my $path = $directory;
	my $found = 0;
	while (1) {
#		warn "testing $path/$filename";
		$found =1,last if -f $self->normalize_path("$self->{template_root}/$path/$filename");
		last if $path eq '';
		$path =~ s#/?[^/]+$##;
	}
	croak "Cannot find $filename from directory $directory" unless $found;
	my ($pmfile,$classname) = $self->translate_filename("$directory/$filename");
	if ( $options{force_rebuild} or ( !-f $pmfile ) or  -M _ > -M "$self->{template_root}/$path/$filename" ) {
		delete $INC{ $pmfile };
		$self->write_pmfile($filename,$pmfile,$classname,$directory);
	}
	require $pmfile;
	return $classname->new( engine => $self, filename => "$path/$filename");
}



=head2 clear_workdir

    $psp->clear_workdir();

This will remove the entire content of the work directory, cleaning up disk space and forcing new calls to C<< $psp->template() >> to recompile the template file.

=cut

sub clear_workdir {
	my ($self) = shift;
	require File::Path;
	my $workdir = $self->{workdir};
	File::Path::rmtree( [ <$workdir/*> ],0);
}




# ===================================================================
# 
#       The following methods are private and subject to change
#
# ===================================================================





#
# Translate template filename into package name & module filename
#

sub translate_filename {
	my ($self,$filename) = @_;
	$filename = $self->normalize_path($filename);
	croak "Filename $filename outsite template_root" if $filename =~ /\.\./;
	my $classname = $self->normalize_path("$self->{template_root}/$filename");
	$classname =~ s#[^\w/]#_#g;
	$classname =~ s#^/#_ROOT_/#;
	my $pmfile = $classname;
	$classname =~ s#/#::#g;
	$classname = "Text::PSP::Generated::$classname";
	$pmfile = $self->normalize_path("$self->{workdir}/$pmfile.pm");
	return ($pmfile,$classname);
}

#
# Parse the template and write out the resulting module
#

sub write_pmfile {
	my ($self,$filename,$pmfile,$classname,$directory) = @_;
	open INFILE,"< $self->{template_root}/$filename" or croak "Cannot open template file $filename: $!";
	require Text::PSP::Parser;
	my $parser = Text::PSP::Parser->new($self);
	my @dir_opts;
	if (defined $directory) {
		@dir_opts = ( directory => $directory );
	}
	my ($head,$define,$out) = $parser->parse_template(input => \*INFILE, classname => $classname, filename => $filename, @dir_opts);
	close INFILE;
	my ($outpath) = $pmfile =~ m#(.*)/#;
	require File::Path;
	File::Path::mkpath([$outpath]);
	open OUTFILE,"> $pmfile" or die "Cannot open $pmfile for writing: $!";
	print OUTFILE @$head,@$define,'sub run { my @o;',"\n",@$out,"\n",'return \@o;}',"\n1\n";
	close OUTFILE;
}

#
# Translate path into "canonical" equivalent. Relative paths will remain 
# relative but things like "some/path/../other/thing" will be turned into
# "some/other/thing" and excess slashes will be removed.
#

sub normalize_path {
	my ($self,$inpath) = @_;
	my @inpath = split '/',$inpath;
	my $relative = (@inpath > 0 and $inpath[0] ne '') ? 1 : 0;
	my @outpath;
	for (@inpath) {
		next if $_ eq '';
		pop @outpath,next if $_ eq '..';
		push @outpath,$_;
	}
	my $outpath = join('/',@outpath);
	$outpath = "/$outpath" unless $relative;
	return $outpath;
}

1;

=head1 COPYRIGHT

Copyright 2002 - 2005 Joost Diepenmaat, jdiepen@cpan.org. All rights reserved.

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=head1 THANKS TO

Christian Hansen for supplying a patch to make the force_reload option work
under mod_perl.

=head1 SEE ALSO

L<Text::PSP::Syntax>, L<Text::PSP::Template>.

=cut

