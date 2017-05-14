#!/usr/bin/perl


use strict;
use ExtUtils::MakeMaker;
use ExtUtils::Manifest;
use File::Basename;
use File::Spec;


my $PACKAGE = 'XML-TEMPLATE';
my $package = lc ($PACKAGE);
my $NAME    = 'XML-Template';

my %config = (
     "${PACKAGE}_INSTALL"		=> "/usr/local/$package",
     "${PACKAGE}_INSTALL_ADMIN"		=> 'admin',
     "${PACKAGE}_INSTALL_DOCS"		=> 'docs',
     "${PACKAGE}_VERBOSE"		=> 0
   );

# Update configuration from command line.
my %mmconfig = (
     NAME               => $NAME,
     VERSION_FROM       => 'lib/XML/Template.pm',
     PREREQ_PM          => {
       'CGI'                    => '2.91',
       'Data::Dumper'		=> '2.12',
       'DBI::Wrap'              => '1.00',
       'HTML::Strip'		=> '1.01',
       'IO::String'		=> '1.02',
       'Mail::Sender'		=> '0.8.06',
       'Parse::RecDescent'	=> '1.80',
       'WWW::Auth'              => '1.00',
       'XML::GDOME'		=> '0.83',
       'XML::SAX'		=> '0.12',
     },
     ($] >= 5.005 ?
       (ABSTRACT_FROM	=> 'lib/XML/Template.pm',
        AUTHOR		=> 'Jonathan Waxman <jowaxman@bbl.med.upenn.edu>') :())
   );
while (my $arg = shift @ARGV) {
  my ($name, $value) = split (/=/, $arg);
  if ($name =~ /^$PACKAGE/) {
    $config{$name} = $value || 0;
  } else {
    $mmconfig{$name} = $value || 0;
  }
}

# Defined build directory to install directory mappings.
my %inst = (
     '.'		=> $config{"${PACKAGE}_INSTALL"},
     'admin'		=> $config{"${PACKAGE}_INSTALL_ADMIN"},
     'docs'		=> $config{"${PACKAGE}_INSTALL_DOCS"},
   );

# Exclude these MANIFEST files.
my @exclude = (
     'CHANGES',
     'COPYING',
     'INSTALL',
     'Makefile.PL',
     'MANIFEST',
     'README',
     'TODO'
   );
my %exclude = map {$_ => 1} @exclude;

# Group files from MANIFEST by directory.
my %files;
if (! -f 'MANIFEST') {
  print "Making manifest\n";
  ExtUtils::Manifest->mkmanifest ();
}
open (MANIFEST, "MANIFEST") ||
  die "Could not open MANIFEST: $!";
while (my $line = <MANIFEST>) {
  chomp ($line);
  $line =~ s/(\s+.*)$//;
  my $dirname  = dirname ($line);
  my $filename = basename ($line);

  push (@{$files{$dirname}}, $filename) if ! exists $exclude{$line};
}
close (MANIFEST);

# Create MakeMaker options.
my %opts = (%mmconfig);

# Create Makefile.
WriteMakefile (%opts);

##############################################################################
# MakeMake subroutines.
##############################################################################

sub MY::install {
  package MY;
  my $inherited = shift->SUPER::install (@_);

  $inherited =~ s/^(install :: .*)$/$1 inst_$package/gm;

  return $inherited;
}

sub MY::clean {
  package MY;
  my $inherited = shift->SUPER::clean (@_);

  $inherited .= "	-rm .inst_${package}_*";

  return $inherited;
}

sub MY::postamble {
  my $postamble;

  # Create Makefile from MANIFEST files.
  my $target_list;
  foreach my $dir (sort keys %files) {
    my $files = $files{$dir};

    # Get install directory for build directory.
    my $install_dir;
    if (exists $inst{$dir}) {
      if ($inst{$dir} =~ m[^/]) {
        $install_dir = $inst{$dir};
      } else {
        $install_dir = File::Spec->catfile ($config{"${PACKAGE}_INSTALL"}, $inst{$dir});
      }
    } else {
      next;
    }

    # Create makefile target and append to target list.
    my $target;
    if ($dir eq '.') {
      $target = ".inst_${package}_main";
    } else {
      my $tdir = $dir;
      $tdir =~ s[/][_];
      $target = ".inst_${package}_$tdir";
    }
    $target_list .= ' ' if defined $target_list;
    $target_list .= $target;

    my $file_list = join (' ', @$files);
    my $filespec_list = join (' ', map (File::Spec->catfile ($dir, $_), @$files));
    $postamble .= qq{
$target: $filespec_list
	\@echo "Installing $dir -> $install_dir"
	\@\$(MKPATH) $install_dir
	\@for file in $file_list; do \\};
    if ($config{"${PACKAGE}_VERBOSE"}) {
       $postamble .= qq{
		echo "  Installing \$\$file"; \\};
    }
    $postamble .= qq{
		\$(CP) $dir/\$\$file $install_dir/\$\$file; \\
	done
	\@touch $target};
  }

  $postamble = qq{
inst_${package}: $target_list}
    . $postamble;

  return $postamble;
}
