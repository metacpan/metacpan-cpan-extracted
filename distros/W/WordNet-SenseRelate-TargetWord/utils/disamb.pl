#! /usr/local/bin/perl -w
# (Updated: $Id: disamb.pl,v 1.12 2006/12/24 12:18:47 sidz1979 Exp $)
#
# disamb.pl version 0.09
#
# Program that reads in a Senseval-2 formatted lexical sample file, and
# disambiguates the instances using WordNet::SenseRelate::TargetWord.
#
# Copyright (c) 2005
#
# Ted Pedersen, University of Minnesota, Duluth
# tpederse@d.umn.edu
#
# Satanjeev Banerjee, Carnegie Mellon University
# banerjee+@cs.cmu.edu
#
# Siddharth Patwardhan, University of Utah
# sidd@cs.utah.edu
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
#-----------------------------------------------------------------------------

# Uses:
use strict;
use WordNet::SenseRelate::Reader::Senseval2;
use WordNet::SenseRelate::TargetWord;
use WordNet::SenseRelate::Tools;
use Getopt::Long;

# Now get the options!
our ($opt_config, $opt_wnpath, $opt_trace, $opt_help, $opt_version);
&GetOptions("config=s", "wnpath=s", "trace", "help", "version");

# If help is requested
if(defined $opt_help)
{
    &printHelp();
    exit;
}

# If version information is requested
if(defined $opt_version)
{
    &printVersion();
    exit;
}

# Options
my $options = {};

# Load options if any
if(defined $opt_config)
{
    # Make all the options undefined first
    $options                      = {};
    $options->{preprocess}        = [];
    $options->{preprocessconfig}  = [];
    $options->{postprocess}       = [];
    $options->{postprocessconfig} = [];
    $options->{context}           = undef;
    $options->{contextconfig}     = undef;
    $options->{algorithm}         = undef;
    $options->{algorithmconfig}   = undef;
    $options->{wntools}           = undef;

    # Read the configuration file
    my $optStruct = &readConfigFile($opt_config);
    &askHelp("disamb.pl: Configuration file format error.\n")
        if (!defined $optStruct);

    # Now get the options from the options structure
    # First, the preprocess modules and options
    if (defined $optStruct->{'PREPROCESS'})
    {
        foreach my $element (@{$optStruct->{'PREPROCESS'}})
        {
            push(@{$options->{preprocess}}, $element->{'name'});
            delete $element->{'name'};
            push(@{$options->{preprocessconfig}}, $element);
        }
    }

    # Next, the postprocess modules and options
    if (defined $optStruct->{'POSTPROCESS'})
    {
        foreach my $element (@{$optStruct->{'POSTPROCESS'}})
        {
            push(@{$options->{postprocess}}, $element->{'name'});
            delete $element->{'name'};
            push(@{$options->{postprocessconfig}}, $element);
        }
    }

    # Next, get the context selection module and options
    if (defined $optStruct->{'CONTEXT'})
    {
        # There should be only one context selection module specified
        &askHelp("disamb.pl: Multiple context selection modules specified in configuration file.\n")
            if(scalar(@{$optStruct->{'CONTEXT'}}) > 1);

        # Get the context selection module name, and options
        # If none are specified, the default will be used
        my $element = shift(@{$optStruct->{'CONTEXT'}});
        if(defined $element && defined $element->{'name'})
        {
            $options->{context} = $element->{'name'};
            delete $element->{'name'};
            $options->{contextconfig} = $element;
        }
    }

    # Next, get the algorithm module and options
    if (defined $optStruct->{'ALGORITHM'})
    {
        # Only one algorithm module must be specified
        &askHelp("disamb.pl: Multiple algorithm modules specified in configuration file.\n")
            if(scalar(@{$optStruct->{'ALGORITHM'}}) > 1);

        # Get the algorithm module name, and options
        # If none are specified, then the default will be used
        my $element = shift(@{$optStruct->{'ALGORITHM'}});
        if (defined $element && defined $element->{'name'})
        {
            $options->{algorithm} = $element->{'name'};
            delete $element->{'name'};
            $options->{algorithmconfig} = $element;
        }
    }
}

# Load WordNet::SenseRelate::Tools:
print STDERR "Loading WordNet::SenseRelate::Tools... ";
my $wntools = WordNet::SenseRelate::Tools->new($opt_wnpath);
&askHelp("disamb.pl: Unable to load WordNet::SenseRelate::Tools.\n")
    if (!defined $wntools);
print STDERR "done.\n";
$options->{'wntools'} = $wntools;

# Read Senseval2 data:
print STDERR "Reading XML data... ";
my $reader = WordNet::SenseRelate::Reader::Senseval2->new(shift);
&askHelp("disamb.pl: Unable to read XML file.\n") if (!defined $reader);
print STDERR "done.\n";

# Create WordNet::SenseRelate::TargetWord object:
my ($targetWord, $error) = WordNet::SenseRelate::TargetWord->new($options, ((defined $opt_trace) ? 1 : 0));
if (!defined $targetWord)
{
    print STDERR "$error\n";
    exit;
}

# Get each instance from the reader object, and disambiguate
foreach my $i (0 .. ($reader->instanceCount() - 1))
{
    my $instance = $reader->instance($i);
    my ($sense, $errString) = $targetWord->disambiguate($instance);
    if (!defined $sense && defined $errString && $errString ne "")
    {
        print STDERR "$errString\n";
        exit;
    }
    print STDERR $targetWord->getTraceString() if(defined $opt_trace);
    print $instance->{lexelt};
    print " ";
    print $instance->{id};
    print " $sense" if (defined $sense);
    print "\n";
}

# Subroutine that reads the options file
sub readConfigFile
{
    my $fname = shift;
    
    open(CONFIG, "$fname") || &askHelp("disamb.pl: Unable to open specified configuration file.\n");
    my $line = <CONFIG>;
    $line =~ s/[\r\f\n]//;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    &askHelp("disamb.pl: File format error (in header) in config file.\n")
        if ($line !~ /^WordNet::SenseRelate::TargetWord$/);
    my $struct  = {};
    my $section = "";
    my $modname = "";
    my $modata  = undef;
    
    while ($line = <CONFIG>)
    {
        $line =~ s/[\r\f\n]//;
        $line =~ s/\#.*//;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        if($line =~ /\[SECTION:([^\]]*)\]/)
        {
            $section = $1;
            $struct->{$section} = []
                if(defined $section
                   && $section ne ""
                   && !exists($struct->{$section}));
        }
        elsif($line =~ /\[START\s+([^\]]+)\]/)
        {
            return undef if(!defined $section || $section eq "");
            $modname = $1;
            $modata  = {};
        }
        elsif($line =~ /\[END\]/)
        {
            return undef
                if(!defined $section
                   || $section eq ""
                   || !defined $modname
                   || $modname eq "");
            return undef if (!defined $modata);
            $modata->{'name'} = $modname;
            push(@{$struct->{$section}}, $modata);
            $modname = "";
            $modata  = undef;
        }
        elsif($line =~ /([^=]+)\s*=\s*([^=]+)/)
        {
            return undef
                if(!defined $section
                   || !defined $modname
                   || $section eq ""
                   || $modname eq "");
            $modata->{$1} = $2;
        }
        elsif($line ne "")
        {
            return undef;
        }
    }
    close(CONFIG);

    return $struct;
}

# function to output help messages for this program
sub printHelp
{
    print "Performs Word Sense Disambiguation on Senseval-2 lexical sample data.\n";
    print "Usage: disamb.pl [ [--config FILE] [--wnpath WNPATH] [--trace] XMLFILE | --help | --version]\n";
    print "--config         Specifies a configuration file (FILE) to set up the\n";
    print "                 various configuration options.\n";
    print "--wnpath         WNPATH specifies the path of the WordNet data files.\n";
    print "                 Ordinarily, this path is determined from the \$WNHOME\n";
    print "                 environment variable. But this option overides this\n";
    print "                 behavior.\n";
    print "--trace          Indicates that trace information be printed.\n";
    print "--help           Displays this help screen.\n";
    print "--version        Displays version information.\n\n";
}

# function to output "ask for help" message when the user's goofed up!
sub askHelp
{
    my $message = shift;
    print STDERR "$message\n" if (defined $message && $message ne "");
    print STDERR "Type disamb.pl --help for help.\n";
    exit;
}

# Subroutine to print the version information
sub printVersion
{
    print "disamb.pl version 0.09\n";
    print "Copyright (c) 2005 Ted Pedersen, Satanjeev Banerjee, and Siddharth Patwardhan.\n";
}

__END__


=head1 NAME

disamb.pl - command line interface for WordNet::SenseRelate::TargetWord, a Word Sense Disambiguation 
module.

=head1 SYNOPSIS

disamb.pl [ [--config FILE] [--wnpath WNPATH] [--trace] XMLFILE | --help | --version ]

=head1 DESCRIPTION

This program is a command line interface to the WordNet::SenseRelate::TargetWord Word Sense Disambiguation
module. It takes as input a Senseval-2 formatted input file and disambiguated each instance specified in
file. The module is highly configurable. The user is allowed to choose different preprocessing and
postprocessing tasks for the data, the dismabiguation algorithm and the context selection algorithm.

=head1 OPTIONS

Usage: disamb.pl [ [--config FILE] [--wnpath WNPATH] [--trace] XMLFILE | --help | --version ]

B<--config>=I<FILE>         
    Specifies a configuration file (FILE) to set up the various configuration options.

B<--wnpath>=I<WNPATH>         
    WNPATH specifies the path of the WordNet data files. Ordinarily, this path is 
    determined from the $WNHOME environment variable. But this option overides this
    behavior.

B<--trace>          
    Indicates that trace information be printed.

B<--help>
    Displays this help screen.

B<--version>
    Displays version information.

=head1 AUTHORS

 Ted Pedersen, University of Minnesota, Duluth
 tpederse at d.umn.edu

 Siddharth Patwardhan, University of Utah, Salt Lake City
 sidd at cs.utah.edu

 Satanjeev Banerjee, Carnegie Mellon University, Pittsburgh
 banerjee+ at cs.cmu.edu

=head1 KNOWN BUGS

None.

=head1 SEE ALSO

perl(1)

I<WordNet::SenseRelate::TargetWord>(3pm)

I<WordNet::Similarity>(3pm)

L<ttp://www.cogsci.princeton.edu/~wn>

L<http://senserelate.sourceforge.net>

L<http://groups.yahoo.com/group/senserelate>

=head1 COPYRIGHT

Copyright (c) 2005 Ted Pedersen, Siddharth Patwardhan, Satanjeev
Banerjee

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 2 of the License, or (at your
option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
