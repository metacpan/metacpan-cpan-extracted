package XML::ApacheFOP;
use strict;
our $VERSION = '0.03';

=head1 NAME

XML::ApacheFOP - Access Apache FOP from Perl to create PDF files using XSL-FO.

=head1 SYNOPSIS

    use XML::ApacheFOP;
    
    my $Fop = XML::ApacheFOP->new();
    
    # create a PDF using a xml/xsl tranformation
    $Fop->fop(xml=>"foo.xml", xsl=>"bar.xsl", outfile=>"temp1.pdf") || die "cannot create pdf: " . $Fop->errstr;
    
    # create a PDF using an xsl-fo file
    $Fop->fop(fo=>"foo.fo", outfile=>"temp2.pdf") || die "cannot create pdf: " . $Fop->errstr;
    
    # create a PostScript file using an xsl-fo file
    $Fop->fop(fo=>"foo.fo", outfile=>"temp3.ps", rendertype=>"ps") || die "cannot create ps file: " . $Fop->errstr;
	
	# reset FOP's image cache (available starting with FOP version 0.20.5)
	$Fop->reset_image_cache() || die "could not reset FOP's image cache: " . $Fop->errstr;

=head1 DESCRIPTION

XML::ApacheFOP allows you to create PDFs (or other output types, explained below) using Apache FOP.

Since FOP is written in Java, this module relies on Java.pm.
You will need to have FOP and Java.pm installed before installing this module.

=head1 SETUP

The biggest hurdle in getting this module to work will be installing and setting up FOP and Java.pm.
I recommend you thoroughly read the FOP and Java.pm documentation.

You will also need Java2 1.2.x or later installed.
See the L<"SEE ALSO"> section below for a download link.

Once you have them installed, you will need to make a change to the JavaServer startup so that FOP will be accessible.
The -classpath will need to be tailored to suit your system.
Hopefully the following example will help you get it right though. Here is the command I use:

    /path/to/java -classpath \
    /path/to/JavaServer.jar\
    :/usr/local/xml-fop/build/fop.jar\
    :/usr/local/xml-fop/lib/avalon-framework-cvs-20020806.jar\
    :/usr/local/xml-fop/lib/batik.jar\
    :/usr/local/xml-fop/lib/xalan-2.4.1.jar\
    :/usr/local/xml-fop/lib/xercesImpl-2.2.1.jar \
    com.zzo.javaserver.JavaServer

Once your JavaServer is running you'll be ready to start using this module.

The README file included with this distribution contains more help
for getting this module setup.

=head1 METHODS

=cut

use Carp;
use Java;

=head2 new

This will connect to the JavaServer and return a Fop object.
It will die if it cannot connect to the JavaServer.

The new call accepts a hash with the following keys:
(note that many of these options are the same as those in Java.pm)

    host => hostname of remote machine to connect to
                    default is 'localhost'
                    
    port => port the JVM is listening on (JavaServer)
                    default is 2000
                    
    event_port => port that the remote JVM will send events to
                    default is -1 (off)
                    Since this module doesn't do any GUI work, leaving this
                    off is a good idea as the second event port will NOT
                    get used/opened saving some system resources.
                    
    authfile => The path to a file whose first line is used as a 
                    shared 'secret' which will be passed to 
                    JavaServer.  To use this feature you must start 
                    JavaServer with the '--authfile=<filename>' 
                    command-line option.
                    If the secret words match access will be granted
                    to this client.  By default there is no shared
                    secret.  See the 'Authorization' section in Java.pm docs for more info.
                    
    debug => when set to true it will print various warn messages stating what
                    the module is doing. Default is false.
                    
    allowed_paths => this is an array ref containing the allowed paths for any filename
                    passed to this module (such as xml, xsl, fo, or pdf filenames).
                    For example, if set to ['/home/foo'], then only files within
                    /home/foo or its children directories will be allowed. If any files
                    outside of this path are passed, the fop call will fail.
                    Default is undef, meaning files from anywhere are allowed.

=cut

sub new
{
  my $Class = shift;
  my $Self = {};
  bless $Self, $Class;
  $Self->_init(@_);
  return $Self;
}

sub _init
{
  my $Self = shift;
  my %Args = @_;
  
  $Self->{host} = $Args{host} ? $Args{host} : 'localhost';
  $Self->{port} = $Args{port} ? $Args{port} : 2000;
  $Self->{event_port} = $Args{event_port} ? $Args{event_port} : -1;
  $Self->{authfile} = $Args{authfile} ? $Args{authfile} : undef; # see Authentication section in Java.pm documentation
  $Self->debug($Args{debug});
  # only allow input/output files to be from directories in these paths
  # this should be an array ref (if used)
  $Self->allowed_paths($Args{allowed_paths});
  
  # create the java object
  warn "Debug mode On. Connecting to JavaServer at $Self->{host} port $Self->{port}." if $Self->{debug};
  warn "Using authfile: $Self->{authfile}" if $Self->{debug} and $Self->{authfile};
  eval { $Self->{_java} = new Java(host=>$Self->{host}, port=>$Self->{port}, event_port=>$Self->{event_port}, authfile=>$Self->{authfile},) };
  croak "could not connect to JavaServer" if $@;
}

sub allowed_paths
{
  my $Self = shift;
  if ($_[0] && ref($_[0]) eq 'ARRAY')
  {
    $Self->{allowed_paths} = $_[0];
  }
  return $Self->{allowed_paths};
}

sub debug
{
  my $Self = shift;
  if (defined $_[0])
  {
    $Self->{debug} = $_[0] ? 1 : 0;
  }
  return $Self->{debug};
}

=head2 fop

This makes the actual call to FOP.

The fop call accepts a hash with the following keys:

    fo => path to the xsl-fo file, must I<not> be used with xml and xsl
    
    xml => path to the xml file, must be used together with xsl
    xsl => path to xsl stylesheet, must be used together with xml
    
    outfile => filename to save the generated file as
    
    rendertype => the type of file that should be generated.
            Default is pdf. Also supports the following formats:
    
            mif - will be rendered as mif file
            pcl - will be rendered as pcl file
            ps - will be rendered as PostScript file
            txt - will be rendered as text file
            svg - will be rendered as a svg slides file
            at - representation of area tree as XML
            
    txt_encoding => if the 'txt' rendertype is used, this is the
            output encoding used for the outfile.
            The encoding must be a valid java encoding.

    s => if the 'at' rendertype is used, setting this to true
            will omit the tree below block areas.
            
    c => the path to an xml configuration file of options
            such as baseDir, fontBaseDir, and strokeSVGText.
            See http://xmlgraphics.apache.org/fop/configuration.html

Will return 1 if the call is successfull.

Will return undef if there was a problem.
In this case, $Fop->errstr will contain a string explaining what went wrong.

=cut

sub fop
{
  my $Self = shift;
  my %Args = @_;
  
  warn "starting fop call" if $Self->{debug};
  
  croak "java object doesn't seem to exist" unless $Self->{_java};
  
  # will be used for error messages
  $Self->{'errstr'} = "";
  
  my @Options;
  
  # let fop run quietly unless debug mode is on
  push @Options, ('-q') unless $Self->{debug};
  
  #
  # Set the rendering files
  #
  
  # outfile will be created using an fo file
  if ($Args{fo})
  {
    # Although I like the idea of making sure a file exists,
    # doing so would prevent running the JavaServer on a remote host.
    # So I'm commenting out the -e check for now.
    #return $Self->_error("$Args{fo} doesn't exist") unless -e $Args{fo};
    push @Options, ('-fo',  $Args{fo});
  }
  # outfile will be created using an xml/xsl transforamtion
  elsif ($Args{xml} and $Args{xsl})
  {
    #return $Self->_error("$Args{xml} doesn't exist") unless -e $Args{xml};
    #return $Self->_error("$Args{xsl} doesn't exist") unless -e $Args{xsl};
    push @Options, ('-xml', $Args{xml});
    push @Options, ('-xsl', $Args{xsl});
  }
  else
  {
    return $Self->_error('Not enough formatting information to run fop. (need fo=>$fofile or (xml=>$xmlfile and xsl=>$xslfile))');
  }
  
  #
  # Set the rendering type and outfile
  #
  
  my $RenderType = $Args{rendertype};
  $RenderType = 'pdf' unless $RenderType;
  $RenderType = lc($RenderType);
  return $Self->_error("Invalid option for 'rendertype'. (valid values: pdf mif pcl ps txt svg at)") unless $RenderType =~ /^(pdf|mif|pcl|ps|txt|svg|at)$/;
  
  my $Outfile = $Args{outfile};
  return $Self->_error("'outfile' is not set") unless $Outfile;
  push @Options, ("-$RenderType", $Outfile);
  
  # 'txt' render type has unique option
  if ($RenderType eq 'txt' and $Args{'txt_encoding'})
  {
    # -txt output encoding use the encoding for the output file.
    # The encoding must be a valid java encoding.
    push @Options, ('-txt.encoding', $Args{'txt_encoding'});
  }
  # 'at' render type has unique option
  if ($RenderType eq 'at' and $Args{'s'})
  {
    # omit tree below block areas
    push @Options, ('-s');
  }
  
  # read in configuration file
  if ($Args{'c'})
  {
    push @Options, ('-c',  $Args{'c'});
  }
  
  # if allowed_paths is set, verify that all files are in the given paths
  if ($Self->{allowed_paths})
  {
    my $OutfileIsOk = 0;
    my $FoIsOk = 0;
    my $XmlIsOk = 0;
    my $XslIsOk = 0;
    if ($Args{fo})
    {
      return $Self->_error('fo file cannot contain ".."') if $Args{fo} =~ /\.\./;
    }
    else
    {
      return $Self->_error('xml file cannot contain ".."') if $Args{xml} =~ /\.\./;
      return $Self->_error('xsl file cannot contain ".."') if $Args{xsl} =~ /\.\./;
    }
    foreach my $Path (@{$Self->{allowed_paths}})
    {
      $OutfileIsOk = 1 if $Outfile =~ /^$Path/;
      if ($Args{fo})
      {
	$FoIsOk = 1 if $Args{fo} =~ /^$Path/;
      }
      else
      {
	$XmlIsOk = 1 if $Args{xml} =~ /^$Path/;
	$XslIsOk = 1 if $Args{xsl} =~ /^$Path/;
      }
    }
    if ( !$OutfileIsOk or ($Args{fo} and !$FoIsOk) or ($Args{xml} and $Args{xsl} and (!$XmlIsOk or !$XslIsOk)) )
    {
      return $Self->_error("Some files are from forbidden paths! Allowed paths are: @{$Self->{allowed_paths}}");
    }
  }
  
  # create a java array of the FOP options
  my $OptionsLength = @Options; # java array lengths must be declared
  my $Options = $Self->{_java}->create_array("java.lang.String", $OptionsLength);
  for (my $Element = 0; $Element < $OptionsLength; $Element++)
  {
    $Options->[$Element] = $Options[$Element];
  }
  
  warn "creating fop object with options: @Options" if $Self->{debug};
  # this is where fop is first called
  my $Fop;
  eval { $Fop = $Self->{_java}->create_object('org.apache.fop.apps.CommandLineOptions', $Options) };
  return $Self->_eval_error("could not create java fop object") if $@;
  
  warn "creating fop starter object" if $Self->{debug};
  my $Starter;
  eval { $Starter = $Fop->getStarter() };
  return $Self->_eval_error("could not create Starter object") if $@;
  
  # create the pdf file (or whatever rendering filetype was selected)
  warn "generating $RenderType file" if $Self->{debug};
  eval { $Starter->run() };
  return $Self->_eval_error("$RenderType file generation failed") if $@;
  
  warn "$RenderType file generated successfully" if $Self->{debug};
  
  return 1;
}

=head2 reset_image_cache

Instruct FOP to clear its image cache.  This method is available 
starting with FOP version 0.20.5. For more information, see 
L<http://xmlgraphics.apache.org/fop/graphics.html#caching>

Will return 1 on success. Will return undef on failure, in which case
the error message will be accessible via $Fop->errstr.

=cut

sub reset_image_cache
{
  my $Self = shift;
  
  $Self->{'errstr'} = "";
  
  warn "resetting FOP image cache" if $Self->{debug};
  eval { $Self->{_java}->org_apache_fop_image_FopImageFactory('resetCache') };
  return $Self->_eval_error("could not reset FOP image cache") if $@;
  
  return 1;
}

=head2 errstr

Will return an error message if the previous $Fop method call failed.

=cut

sub errstr
{
  my $Self = shift;
  return $Self->{errstr};
}

sub _error
{
  my $Self = shift;
  $Self->{'errstr'} = $_[0];
  return undef;
}

sub _eval_error
{
  my $Self = shift;

  my $Error = $@;
  chomp($Error);

  # Gets rid of 'ERROR: '
  $Error =~ s/^ERROR: //;

  # Gets rid of the fop exception class in the message
  $Error =~ s/org.apache.fop.apps.FOPException: //;

  # Gets rid of 'croak' generated stuff
  # I'm reversing the error string because the non-greedy *? only works from left-to-right
  # If you have a better way to do this, let me know :)
  $Error = reverse $Error;
  $Error =~ s/^\d+ enil .*?(\/|[\/\\]:[a-zA-Z]) ta //;
  $Error = reverse $Error;

  return $Self->_error("$_[0]: $Error");
}

=head1 AUTHOR

Ken Prows (perl@xev.net)

=head1 SEE ALSO

Please let me know if any of the below links are broken.

Java2: 
L<http://java.sun.com/j2se/>

Java.pm: 
L<http://search.cpan.org/perldoc?Java>

SourceForge page for Java.pm/JavaServer: 
L<http://sourceforge.net/projects/javaserver/>

FOP: 
L<http://xmlgraphics.apache.org/fop/>

Ken Neighbors has created Debian packages for Java.pm/JavaServer and XML::ApacheFOP.
This greatly eases the installation for the Debian platform:
L<http://www.nsds.com/software/>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 Online-Rewards. All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
