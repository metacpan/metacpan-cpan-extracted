package Text::Corpus::NewYorkTimes;

use strict;
use warnings;
use File::Spec::Functions;
use File::Find;
use Log::Log4perl;
use Text::Corpus::NewYorkTimes::Document;
use Data::Dump qw(dump);

BEGIN
{
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = '1.01';
	@ISA         = qw(Exporter);
	@EXPORT      = qw();
	@EXPORT_OK   = qw();
	%EXPORT_TAGS = ();
}
# To do:
# TODO: add method to write file list to a file (make it a script).

#12345678901234567890123456789012345678901234
#Interface to New York Times corpus.

=head1 NAME

C<Text::Corpus::NewYorkTimes> - Interface to New York Times corpus.

=head1 SYNOPSIS

  use Text::Corpus::NewYorkTimes;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::NewYorkTimes->new (fileList => $fileList, corpusDirectory => $corpusDirectory);
  dump $corpus->getTotalDocuments;

=head1 DESCRIPTION

C<Text::Corpus::NewYorkTimes> provides an interface for accessing the documents
in the New York Times corpus from Linguistic Data Consortium. The categories, description, title, etc... of a specified document
are accessed using L<Text::Corpus::NewYorkTimes::Document>. Also, all errors and
warnings are logged using L<Log::Log4perl>, which should be L<initialized|Log::Log4perl/How_to_use_it>.

=head1 CONSTRUCTOR

=head2 C<new>

The method C<new> creates an instance of the C<Text::Corpus::NewYorkTimes> class with the following
parameters:

=over

=item C<corpusDirectory>

 corpusDirectory => '...'

C<corpusDirectory> is the path to the top most directory of the corpus;
it usually is the path to the directory named C<nyt_corpus>. It is needed to
locate all the documents in the corpus. If it is not defined, then the enviroment variable
C<TEXT_CORPUS_NEWYORKTIMES_CORPUSDIRECTORY> is used if it is defined; if neither of these are
defined then all the paths in the
file specified by C<fileList> are assumed to be full path names. C<corpusDirectory> and
C<fileList> can both be defined to locate the documents in the corpus by having the path
names in C<fileList> be defined relative to C<corpusDirectory>.

=item C<fileList>

 fileList => '...'

C<fileList> is an optional parameter that can be used to save time when creating the list of documents in the corpus;
each line in the file must be the path to an XML document in the corpus.
If C<fileList> is not defined, then the environment variable C<TEXT_CORPUS_NEWYORKTIMES_FILELIST> is used if it is defined;
otherwise all the XML documents in the corpus are located by searching the directory specified by C<corpusDirectory>.
If the file defined by C<fileList> or C<TEXT_CORPUS_NEWYORKTIMES_FILELIST> does
not exist, it will be created and the path to each XML document in the corpus,
relative to C<corpusDirectory>, will be written to it. This is done to speed-up
subsequent invocations of the object.

=back

=cut

sub new
{
	# create the class object.
	my ($Class, %Parameters) = @_;
	my $Self = bless {}, ref($Class) || $Class;
	
  # set the fileList.
  unless (exists ($Parameters{fileList}))
  {
    if (defined (%ENV) && exists ($ENV{TEXT_CORPUS_NEWYORKTIMES_FILELIST}))
    {
      $Parameters{fileList} = $ENV{TEXT_CORPUS_NEWYORKTIMES_FILELIST};
    }
  }

  # set the corpusDirectory.
  unless (exists ($Parameters{corpusDirectory}))
  {
    if (defined (%ENV) && exists ($ENV{TEXT_CORPUS_NEWYORKTIMES_CORPUSDIRECTORY}))
    {
      $Parameters{corpusDirectory} = $ENV{TEXT_CORPUS_NEWYORKTIMES_CORPUSDIRECTORY};
    }
  }

  my $corpusFileList;
	if (!exists($Parameters{fileList}) || !defined($Parameters{fileList}) ||
	   (exists ($Parameters{fileList}) && defined ($Parameters{fileList}) && ! -e $Parameters{fileList}))
	{
		# at this point no file containing the list of files exists, so find all the files.
		
		# corpusDirectory not defined, log and die.
		unless (exists($Parameters{corpusDirectory}))
		{
			my $logger = Log::Log4perl->get_logger();
			$logger->logdie ("corpusDirectory not defined.\n");
		}

    # if corpusDirectory not a directory, log and die.
		unless (-d $Parameters{corpusDirectory})
		{
			my $logger = Log::Log4perl->get_logger();
			$logger->logdie("base directory for corpus, '" . $Parameters{corpusDirectory} . "', not a directory or does not exist: " . $!);
		}

    # store the directory of the corpus.
		$Self->{corpusDirectory} = $Parameters{corpusDirectory};

		# find all the corpus files in the base directory.
		$Self->_computeListOfCorpusFiles(corpusDirectory => $Parameters{corpusDirectory});
		
    # write the list of files to disk if fileList defined.	
    if (exists ($Parameters{fileList}) && defined ($Parameters{fileList}) && ! -e $Parameters{fileList})
    {
      $Self->{fileList} = $Parameters{fileList};
      $Self->_writeListOfCorpusFiles;
    }

    $corpusFileList = $Self->{corpusFileList};
	}
  else
  {
  	# at this point fileList exists, so make sure it is a path to a file.
  	my $fileList = $Parameters{fileList};
  	unless (-f $fileList)
  	{
  		my $logger = Log::Log4perl->get_logger();
  		$logger->logdie("'$fileList' is not a file.");
  	}

  	# open the file of paths for reading.
  	local *IN;
  	unless (open(IN, $fileList))
  	{
  		my $logger = Log::Log4perl->get_logger();
  		$logger->logdie("could not open file '" . $fileList . ". for reading: " . $!);
  	}

  	# read in the list of file paths and close the file.
  	my @filePathName = map { chomp; $_; } <IN>;
  	close IN;

  	# if there are no files, log a warning now.
  	if (@filePathName == 0)
  	{
      my $logger = Log::Log4perl->get_logger();
      $logger->logwarn ("file '" . $fileList . ". is empty.\n");
  	}

  	# add the base directory to each path name.
  	if (exists($Parameters{corpusDirectory}))
  	{
  		unless (-d $Parameters{corpusDirectory})
  		{
  			my $logger = Log::Log4perl->get_logger();
  			$logger->logdie ("base directory for corpus, '" . $Parameters{corpusDirectory} . "', does not exist." . $!);
  		}

  		foreach my $filePath (@filePathName)
  		{
  			$filePath = File::Spec->catfile($Parameters{corpusDirectory}, $filePath);
  		}
  	}
  	else
  	{
  		# check if the first file exists, if not see if the file fileList is in the base directory.
  		if ((@filePathName > 0) && !(-e $filePathName[0]))
  		{
  			my ($volume, $path, $fileName) = File::Spec->splitpath($Parameters{fileList});
  			my $maybeBaseDir = File::Spec->catfile($volume, $path);
  			if (-e File::Spec->catfile($maybeBaseDir, $filePathName[0]))
  			{

  				# looks like $maybeBaseDir is the base directory, so prefix it each file.
  				foreach my $filePath (@filePathName)
  				{
  					$filePath = File::Spec->catfile($maybeBaseDir, $filePath);
  				}
  			}
  		}
  	}
  	
  	$corpusFileList = \@filePathName;
  }

	$Self->{corpusFileList} = $corpusFileList;
  $Self->buildCorpusFileHash;
	return $Self;
}

=head1 METHODS

=head2 C<getDocument>

 getDocument (index => $documentIndex)
 getDocument (uri => $uri)

C<getDocument> returns a L<Text::Corpus::NewYorkTimes::Document> object for the
document with index C<$documentIndex> or uri C<$uri>. The document
indices range from zero to C<getTotalDocument()-1>; C<getDocument> returns
C<undef> if any errors occurred and logs them using L<Log::Log4perl>.

For example:

  use Text::Corpus::NewYorkTimes;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::NewYorkTimes->new (fileList => $fileList, corpusDirectory => $corpusDirectory);
  my $document = $corpus->getDocument (index => 0);
  dump $document->getBody;
  dump $document->getCategories;
  dump $document->getContent;
  dump $document->getDate;
  dump $document->getTitle;
  dump $document->getUri;

=cut

sub getDocument
{
  my ($Self, %Parameters) = @_;
  my $corpusFileHash =  $Self->{corpusFileHash};

  # get the documents path.
  my $documentPath;
  $documentPath = $Self->getFilePathOfDocument ($Parameters{index}) if exists $Parameters{index};
  $documentPath = $Parameters{uri} if (exists $Parameters{uri} && exists $corpusFileHash->{$Parameters{uri}});
  return undef unless defined $documentPath;

  # get the document object.
  my $document;
  eval
  {
    $document =  Text::Corpus::NewYorkTimes::Document->new (filename => $documentPath);
  };
  if ($@)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn(  "caught exception, probably xml parsing error in file '"
                    . $documentPath . "', skipping over the file: " . $@);
    $document = undef;
  }
  return $document;
}

# find all the corpus files in the base directory.
{
	my @corpusFileList;

	sub _computeListOfCorpusFiles
	{
		my ($Self, %Parameters) = @_;
		@corpusFileList = ();
		find ({ wanted => \&_storeCorpusFiles, follow => 1 }, $Parameters{corpusDirectory});
		@corpusFileList = sort @corpusFileList;
		$Self->{corpusFileList} = \@corpusFileList;
		$Self->buildCorpusFileHash;
	}

	sub _storeCorpusFiles
	{
		if ((-f $File::Find::name) && ($File::Find::name =~ /\d+\.xml$/))
		{
			push @corpusFileList, $File::Find::name;
		}
	}
}

# write the list of corpus files to disk.
sub _writeListOfCorpusFiles
{
  my ($Self) = @_;

  # open the fileList for writing.
  local *OUT;
  my $fileList = $Self->{fileList};
	unless (open (OUT, '>' . $fileList))
	{
		my $logger = Log::Log4perl->get_logger();
		$logger->logdie("could not open file '" . $fileList . ". for writing: " . $!);
	}

  # get the corpus directory.
  my $corpusDirectory = $Self->{corpusDirectory};

  # write the list of relative paths to the file list.
  my @relativeCorpusFileList;
  my $corpusFileList = $Self->{corpusFileList};
  foreach my $filePath (@$corpusFileList)
  {
    my $relativePath = File::Spec->abs2rel ($filePath, $corpusDirectory);
    print OUT $relativePath . "\n";
  }
  close OUT;

  return undef;
}

# builds the hash of the corpus files.
sub buildCorpusFileHash
{
  my $Self = shift;

  # build the hash or corpus files.
  my $corpusFileList = $Self->{corpusFileList};
  my %corpusFileHash;
  for (my $i = 0; $i < @$corpusFileList; $i++)
  {
    $corpusFileHash{$corpusFileList->[$i]} = $i;
  }
  $Self->{corpusFileHash} = \%corpusFileHash;
  return;
}

=head2 C<getTotalDocuments>

 getTotalDocuments ()

C<getTotalDocuments> returns the total number of documents in the corpus. The index to the
documents in the corpus ranges from zero to C<getTotalDocuments() - 1>.

=cut

# returns the total number of documents in the corpus.
sub getTotalDocuments
{
  my $Self = shift;
  return scalar($#{ $Self->{corpusFileList} } + 1);
}

# returns the path of a file given an index.
sub getFilePathOfDocument
{
  my $Self        = shift;
  my $indexOfFile = shift;
  return undef unless defined $indexOfFile;
  return $Self->{corpusFileList}->[$indexOfFile];
}

=head2 C<test>

 test ()

C<test> does tests to ensure the documents in the corpus are accessible
and can be parsed. It returns true if all tests pass, otherwise a
description of the test that failed is logged using L<Log::Log4perl> and
false is returned.

For example:

  use Text::Corpus::NewYorkTimes;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::NewYorkTimes->new (fileList => $fileList, corpusDirectory => $corpusDirectory);
  dump $corpus->test;

=cut

sub test
{
  my ($Self, %Parameters) = @_;

  # make sure a corpus file list created.
  unless (exists $Self->{corpusFileList})
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("list of corpus files not created; were corpusFileList and/or fileList defined correctly?\n");
    return 0;
  }

  # make sure some files were found.
  my $totalDocuments = $Self->getTotalDocuments ();
  unless ($totalDocuments)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("list of corpus files is empty; were corpusFileList and/or fileList defined correctly?\n");
    return 0;
  }

  # test for missing files.
  my $numberOfFilesToTest = 20;
  my @listOfMissingFiles;
  my $corpusFileList = $Self->{corpusFileList};
  for (my $i = 0; $i < $numberOfFilesToTest; $i++)
  {
    my $index = int rand scalar @$corpusFileList;
    my $filePath = $corpusFileList->[$index];
    push @listOfMissingFiles, $filePath unless -f $filePath;
  }

  # make sure some of the files exist.
  if (@listOfMissingFiles)
  {
    my $logger = Log::Log4perl->get_logger();
    my $totalMissingFiles = scalar @listOfMissingFiles;
    my $message = "randomly selected $numberOfFilesToTest files fron list of corpus files and found\n$totalMissingFiles of them are missing:\n";
    $message .= join ("\n", @listOfMissingFiles, "were corpusFileList and/or fileList defined correctly?\n");
    $logger->logwarn ($message);
    return 0;
  }

  # randomly test some of the files for parsing errors.
  for (my $i = 0; $i < $numberOfFilesToTest; $i++)
  {
    my $index = int rand scalar @$corpusFileList;
    my $totalTextInfo = 0;
    eval
      {
        my $document = $Self->getDocument(index => $index);
        next unless defined $document;
        my %documentInfo;
        $documentInfo{title} = $document->getTitle();
        $documentInfo{body} = $document->getBody();
        $documentInfo{date} = [$document->getDate()];
        $documentInfo{content} = $document->getContent();
        $documentInfo{categories} = $document->getCategories();
        $documentInfo{description} = $document->getDescription();
        $documentInfo{uri} = [$document->getUri()];
        foreach my $key (keys %documentInfo)
        {
          $totalTextInfo += @{$documentInfo{$key}};
        }
      };
    if ($@)
    {
      my $logger = Log::Log4perl->get_logger();
      my $totalMissingFiles = scalar @listOfMissingFiles;
      my $message = "parsing of one of the corpus documents through an exception: $@\n";
      $logger->logwarn ($message);
      return 0;
    }
    if ($totalTextInfo < 2)
    {
      my $logger = Log::Log4perl->get_logger();
      my $totalMissingFiles = scalar @listOfMissingFiles;
      my $message = "parsing of one of the corpus documents returned insufficient information.\nwere corpusFileList and/or fileList defined correctly?\n";
      $logger->logwarn ($message);
      return 0;
    }
  }

  return 1;
}

=head1 EXAMPLES

The example below will print out all the information for each document in the corpus.

  use Text::Corpus::NewYorkTimes;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::NewYorkTimes->new (fileList => $fileList, corpusDirectory => $corpusDirectory);
  my $totalDocuments = $corpus->getTotalDocuments;

  for (my $i = 0; $i < $totalDocuments; $i++)
  {
    eval
      {
        my $document = $corpus->getDocument(index => $i);
        next unless defined $document;
        my %documentInfo;
        $documentInfo{title} = $document->getTitle();
        $documentInfo{body} = $document->getBody();
        $documentInfo{content} = $document->getContent();
        $documentInfo{categories} = $document->getCategories();
        $documentInfo{description} = $document->getDescription();
        $documentInfo{uri} = $document->getUri();
        dump \%documentInfo;
      };
  }

=head1 INSTALLATION

To install the module set the environment variable 
C<TEXT_CORPUS_NEWYORKTIMES_CORPUSDIRECTORY> to the path of the
New York Times corpus and run the following commands:

  perl Makefile.PL
  make
  make test
  make install

If you are on a windows box you should use 'nmake' rather than 'make'.

The module will install if C<TEXT_CORPUS_NEWYORKTIMES_CORPUSDIRECTORY> is not defined, but
less testing will be performed. After the New York Times corpus is installed testing
of the module can be performed by running:

  use Text::Corpus::NewYorkTimes;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::NewYorkTimes->new (corpusDirectory => $corpusDirectory);
  dump $corpus->test;

=head1 AUTHOR

 Jeff Kubina<jeff.kubina@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2009 Jeff Kubina. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 KEYWORDS

nyt, new york times, english corpus, information processing

=head1 SEE ALSO

=begin html

This module requires the <a href="http://www.ldc.upenn.edu/Catalog/CatalogEntry.jsp?catalogId=LDC2008T19">The New York Times Annotated Corpus</a>
from the Linguistic Data Consortium; discussions about the corpus are moderated at the
Google Group called <a href="http://groups.google.com/group/nytnlp">The New York Times Annotated Corpus Community</a>.

=end html

L<Log::Log4perl>, L<Text::Corpus::NewYorkTimes::Document>

=cut

1;
# The preceding line will help the module return a true value
