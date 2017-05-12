package Text::Corpus::Inspec;

use strict;
use warnings;
use File::Spec::Functions;
use File::Find;
use Log::Log4perl;
use Text::Corpus::Inspec::Document;
use Data::Dump qw(dump);

BEGIN
{
  use Exporter ();
  use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
  $VERSION     = '1.00';
  @ISA         = qw(Exporter);
  @EXPORT      = qw();
  @EXPORT_OK   = qw();
  %EXPORT_TAGS = ();
}

#12345678901234567890123456789012345678901234
#Interface to Inspec abstracts corpus.

=head1 NAME

C<Text::Corpus::Inspec> - Interface to Inspec abstracts corpus.

=head1 SYNOPSIS

  use Text::Corpus::Inspec;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::Inspec->new (corpusDirectory => $corpusDirectory);
  dump $corpus->getTotalDocuments;

=head1 DESCRIPTION

C<Text::Corpus::Inspec> provides a simple interface for accessing the documents
in the Inspec corpus.

The categories, description, title, etc... of a specified document
are accessed using L<Text::Corpus::Inspec::Document>. Also, all errors and
warnings are logged using L<Log::Log4perl>, which should be L<initialized|Log::Log4perl/How_to_use_it>.

=head1 CONSTRUCTOR

=head2 C<new>

The method C<new> creates an instance of the C<Text::Corpus::Inspec> class with the following
parameters:

=over

=item C<corpusDirectory>

 corpusDirectory => '...'

C<corpusDirectory> is the path to the top most directory of the corpus documents. It is
the path to the directory containing the sub-directories named C<Test>, C<Training>,
and C<Validation> of the corpus and is needed to locate all the documents in the corpus.
If it is not defined, then the enviroment variable
C<TEXT_CORPUS_INSPEC_CORPUSDIRECTORY> is used if it is defined. 
A message is logged and an exception is thrown if no directory is specified.

=back

=cut

sub new
{
  # create the class object.
  my ($Class, %Parameters) = @_;
  my $Self = bless {}, ref($Class) || $Class;

  # set the names of the document set subset types.
  $Self->{test} = 'test';
  $Self->{training} = 'training';
  $Self->{validation} = 'validation';
  $Self->{all} = 'all';

  # set the corpusDirectory.
  unless (exists ($Parameters{corpusDirectory}))
  {
    if (defined (%ENV) && exists ($ENV{TEXT_CORPUS_INSPEC_CORPUSDIRECTORY}))
    {
      $Parameters{corpusDirectory} = $ENV{TEXT_CORPUS_INSPEC_CORPUSDIRECTORY};
    }
  }

  # got to at least have corpusDirectory defined.
  unless (exists($Parameters{corpusDirectory}))
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie ("corpusDirectory not defined.\n");
  }

  # corpusDirectory must be a directory.
  unless (-d $Parameters{corpusDirectory})
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logdie("base directory for corpus, '" . $Parameters{corpusDirectory} . "', not a directory or does not exist: " . $!);
  }

  # find all the corpus files in the base directory.
  $Self->_computeListOfCorpusFiles(corpusDirectory => $Parameters{corpusDirectory});

  return $Self;
}

=head1 METHODS

=head2 C<getDocument>

  getDocument (index => $index, subsetType => $subsetType)

C<getDocument> returns a L<Text::Corpus::Inspec::Document> object of the document with the specified C<index>
and C<subsetType>, which is either C<'all'>, C<'test'>, C<'training'>,
or C<'validation'>; the default is C<'all'>.

  getDocument (uri => $uri)

C<getDocument> returns a L<Text::Corpus::Inspec::Document> object of the document with specified C<uri>.

=cut

sub getDocument
{
  my ($Self, %Parameters) = @_;

  # get the subsetType parameter.
  my $subsetType = $Self->{all};
  $subsetType = lc $Parameters{subsetType} if exists $Parameters{subsetType};

  # get the index if defined.
  my $indexOfDocument;
  $indexOfDocument = abs $Parameters{index} if exists $Parameters{index};

  # compute the path from the index or uri if defined.
  my $documentPath;
  $documentPath = $Self->getFilePathOfDocument ($indexOfDocument, $subsetType) if defined $indexOfDocument;
  my $corpusFileHash = $Self->{corpusFileHash};
  $documentPath = $Parameters{uri} if exists ($Parameters{uri}) && exists $corpusFileHash->{$Parameters{uri}};

  # if we have no path defined, return undef.
  return undef unless defined $documentPath;

  # get the document object.
  my $document;
  eval
  {
    $document =  Text::Corpus::Inspec::Document->new (filename => $documentPath);
  };
  if ($@)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn(  "caught exception, probably parsing error in file '"
                    . $documentPath . "', skipping the file: " . $@);
    $document = undef;
  }
  return $document;
}

=head2 C<getTotalDocuments>

  getTotalDocuments (subsetType => 'all')

C<getTotalDocuments> returns the total number of documents in the specified subset-type
of the corpus; which is either C<'all'>, C<'test'>, C<'training'>,
or C<'validation'>; the default is C<'all'>. The index to the
documents in each subset ranges from zero to C<getTotalDocuments(subsetType =E<gt> $subsetType) - 1>.

=cut

# returns the total number of documents in the corpus.
sub getTotalDocuments
{
  my ($Self, %Parameters) = @_;

  # get the type of the document set whose size is to be returned.
  my $subsetType = $Self->{all};
  $subsetType = lc $Parameters{subsetType} if exists $Parameters{subsetType};
  $subsetType = $Self->{all} unless defined $subsetType;

  # return the document set size.
  return $#{$Self->{testDocuments}} + 1 if ($subsetType eq $Self->{test});
  return $#{$Self->{trainingDocuments}} + 1 if ($subsetType eq $Self->{training});
  return $#{$Self->{validationDocuments}} + 1 if ($subsetType eq $Self->{validation});
  return $#{$Self->{testDocuments}} + $#{$Self->{trainingDocuments}} + $#{$Self->{validationDocuments}} + 3;
}

# returns the path of a file given an index and type.
sub getFilePathOfDocument
{
  my ($Self, @Parameters) = @_;

  # get the parameters.
  my $type = $Self->{all};
  my $indexOfDocument = 0;

  foreach my $parameter (@Parameters)
  {
    if ($parameter =~ m/^\d+$/)
    {
      $indexOfDocument = $parameter;
    }
    else
    {
      $type = lc $parameter;
    }
  }

  # force $indexOfDocument to a valid range given the document type.
  my $totalDocuments = $Self->getTotalDocuments (subsetType => $type);
  $indexOfDocument = 0 if ($indexOfDocument < 0);
  $indexOfDocument = $totalDocuments - 1 if ($indexOfDocument >= $totalDocuments);

  # return the file path of the document given the data type specified.
  if ($type eq $Self->{test})
  {
    return $Self->{testDocuments}->[$indexOfDocument];
  }
  elsif ($type eq $Self->{training})
  {
    return $Self->{trainingDocuments}->[$indexOfDocument];
  }
  elsif ($type eq $Self->{validation})
  {
    return $Self->{validationDocuments}->[$indexOfDocument];
  }
  else
  {
    foreach my $type ($Self->{test}, $Self->{training}, $Self->{validation})
    {
      return $Self->getFilePathOfDocument ($indexOfDocument, $type) if ($indexOfDocument < $Self->getTotalDocuments (subsetType => $type));
      $indexOfDocument -= $Self->getTotalDocuments (subsetType => $type);
    }
  }
}

# find all the corpus files in the base directory.
{
  my @listOfCorpuseFiles;

  sub _computeListOfCorpusFiles
  {
    my ($Self, %Parameters) = @_;
    @listOfCorpuseFiles = ();
    find(\&_storeCorpusFiles, $Parameters{corpusDirectory});
    @listOfCorpuseFiles = sort @listOfCorpuseFiles;
    my %corpusFileHash;
    for (my $i = 0; $i < @listOfCorpuseFiles; $i++)
    {
      $corpusFileHash{$listOfCorpuseFiles[$i]} = $i;
    }
    $Self->{corpusFileList} = \@listOfCorpuseFiles;
    $Self->{corpusFileHash} = \%corpusFileHash;
    $Self->_buildListsOfCorpusFiles ();
  }

  sub _storeCorpusFiles
  {
    if ((-e $File::Find::name) && ($File::Find::name =~ /\d+\.abstr$/))
    {
      push @listOfCorpuseFiles, $File::Find::name;
    }
  }
}


# build the list of all the files in the corpus.
sub _buildListsOfCorpusFiles
{
  my ($Self, %Parameters) = @_;

  # separate the files into Test, Training, Validation.
  my (@test, @training, @validation);

  my $corpusFileList = $Self->{corpusFileList};
  foreach my $filePath (@$corpusFileList)
  {
    if ($filePath =~ m/Test.\d+\.abstr$/)
    {
      push @test, $filePath;
    }
    elsif ($filePath =~ m/Training.\d+\.abstr$/)
    {
      push @training, $filePath;
    }
    elsif ($filePath =~ m/Validation.\d+\.abstr$/)
    {
      push @validation, $filePath;
    }
  }

  $Self->{testDocuments} = $Self->_getDocumentList (fileList => \@test);
  $Self->{trainingDocuments} = $Self->_getDocumentList (fileList => \@training);
  $Self->{validationDocuments} = $Self->_getDocumentList (fileList => \@validation);
}


sub _getDocumentList
{
  my ($Self, %Parameters) = @_;

  # build the list of files associated with each document.
  my %newFileList;
  foreach my $filename (@{$Parameters{fileList}})
  {
    # split off the file number.
    if ($filename =~ /(\d+)\.abstr$/)
    {
      $newFileList{$1 + 0} = $filename;
    }
  }

  # get the sorted list of document numbers.
  my @docNumbers = sort {$a <=> $b} keys %newFileList;

  # convert the list of documents to an array.
  my @documentList;
  for (my $i = 0; $i < @docNumbers; $i++)
  {
    $documentList[$i] = $newFileList{$docNumbers[$i]};
  }

  return \@documentList;
}


sub _testDocumentPath
{
  my $Self = shift;
  my $totalTest = $Self->getTotalDocuments (subsetType => 'test');
  my $totalTraining = $Self->getTotalDocuments (subsetType => 'training');
  my $totalValidation = $Self->getTotalDocuments (subsetType => 'validation');

  my $offset = 0;
  for (my $i = 0; $i < $totalTest; $i++)
  {
    return 0 if ($Self->getFilePathOfDocument($i, 'test') ne $Self->getFilePathOfDocument($offset + $i));
  }

  $offset += $totalTest;
  for (my $i = 0; $i < $totalTraining; $i++)
  {
    return 0 if ($Self->getFilePathOfDocument($i, 'training') ne $Self->getFilePathOfDocument($offset + $i));
  }

  $offset += $totalTraining;
  for (my $i = 0; $i < $totalValidation; $i++)
  {
    return 0 if ($Self->getFilePathOfDocument($i, 'validation') ne $Self->getFilePathOfDocument($offset + $i));
  }

  return 1;
}

=head2 C<test>

 test ()

C<test> does tests to ensure the documents in the corpus are accessible
and can be parsed. It returns true if all tests pass, otherwise a
description of the test that failed is logged using L<Log::Log4perl> and
false is returned.

For example:

  use Text::Corpus::Inspec;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::Inspec->new (corpusDirectory => $corpusDirectory);
  dump $corpus->test;

=cut

sub test
{
  my ($Self, %Parameters) = @_;

  # make sure a corpus file list created.
  unless ($Self->_testDocumentPath)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("list of corpus files corrupt; was corpusDirectory defined correctly?\n");
    return 0;
  }

  # make sure some files were found.
  my $totalDocuments = $Self->getTotalDocuments ();
  unless ($totalDocuments)
  {
    my $logger = Log::Log4perl->get_logger();
    $logger->logwarn ("list of corpus files is empty; was corpusDirectory defined correctly?\n");
    return 0;
  }

  # test for missing files.
  my $numberOfFilesToTest = 20;
  my @listOfMissingFiles;
  my $corpusFileList = $Self->{corpusFileList};
  for (my $i = 0; $i < $numberOfFilesToTest; $i++)
  {
    my $index = int rand scalar @$corpusFileList;
    my $filePath = $Self->getFilePathOfDocument($index);
    push @listOfMissingFiles, $filePath unless -f $filePath;
  }

  # make sure some of the files exist.
  if (@listOfMissingFiles)
  {
    my $logger = Log::Log4perl->get_logger();
    my $totalMissingFiles = scalar @listOfMissingFiles;
    my $message = "randomly selected $numberOfFilesToTest files fron list of corpus files and found\n$totalMissingFiles of them are missing:\n";
    $message .= join ("\n", @listOfMissingFiles, "was corpusDirectory defined correctly?\n");
    $logger->logwarn ($message);
    return 0;
  }

  # randomly test some of the files for parsing errors.
  for (my $i = 0; $i < $numberOfFilesToTest; $i++)
  {
    my $index = int rand scalar $totalDocuments;
    my $totalTextInfo = 0;
    eval
      {
        my $document = $Self->getDocument(index => $index);
        next unless defined $document;
        my %documentInfo;
        $documentInfo{title} = $document->getTitle();
        $documentInfo{body} = $document->getBody();
        $documentInfo{content} = $document->getContent();
        $documentInfo{categories} = $document->getCategories();
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
      my $message = "parsing of one of the corpus documents returned insufficient information.\nwas corpusDirectory defined correctly?\n";
      $logger->logwarn ($message);
      return 0;
    }
  }

  return 1;
}

=head1 EXAMPLES

The example below will print out all the information for each document in the corpus.

  use Text::Corpus::Inspec;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::Inspec->new (corpusDirectory => $corpusDirectory);
  my $totalDocuments = $corpus->getTotalDocuments ();
  for (my $i = 0; $i < $totalDocuments; $i++)
  {
    eval
    {
      my $document = $corpus->getDocument (index => $i);
      my %documentInfo;
      $documentInfo{title} = $document->getTitle ();
      $documentInfo{body} = $document->getBody ();
      $documentInfo{content} = $document->getContent ();
      $documentInfo{categories} = $document->getCategories ();
      $documentInfo{uri} = $document->getUri ();
      dump \%documentInfo;
    };
  } 

=head1 INSTALLATION

To install the module set the environment variable 
C<TEXT_CORPUS_INSPEC_CORPUSDIRECTORY> to the path of the
Inspec corpus and run the following commands:

  perl Makefile.PL
  make
  make test
  make install

If you are on a windows box you should use 'nmake' rather than 'make'.

The module will install if C<TEXT_CORPUS_INSPEC_CORPUSDIRECTORY> is not defined, but
little testing will be performed. After the Inspec corpus is installed testing
of the module can be performed by running:

  use Text::Corpus::Inspec;
  use Data::Dump qw(dump);
  use Log::Log4perl qw(:easy);
  Log::Log4perl->easy_init ($INFO);
  my $corpus = Text::Corpus::Inspec->new (corpusDirectory => $corpusDirectory);
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

inspec, english corpus, information processing

=head1 SEE ALSO

L<Text::Corpus::Inspec::Document>, L<Log::Log4perl>

=cut

1;
# The preceding line will help the module return a true value
