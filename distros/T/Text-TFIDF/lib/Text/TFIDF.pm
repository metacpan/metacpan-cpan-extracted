package Text::TFIDF;

use 5.012003;
use strict;
use warnings;
use Carp;
require Encode;

our $VERSION = '0.04';


sub new {
	my $class = shift;
	my $self = {};

	bless $self, $class;

	my %args = @_;

	if ($args{file}) {
		$self->process_files(@{$args{file}});
	}

	return $self;
}

sub TFIDF {
	my $self = shift;
	my $file = shift;
	my $word = shift;

	if (!defined $file) { 
		carp("You must give a filename for the TFIDF measure.\n");
		return undef;
	}

	if (!defined $word) {
		carp("You must give a word for the TFIDF measure.\n");
		return undef;
	}

#	$word =~  s/[?;:!,.'"]//g;
        $word =~ s/[?;:!,."\(\)]//g; 
	return undef if (!defined $self->{file}->{$file});
	return $self->TF($file,$word)*$self->IDF($word);
}


sub TF {
	my $self = shift;
	my $file = shift;
	my $word = shift;

	return $self->{file}->{$file}->{$word};
}


#IDF = log(number of documents/(number of documents containing the word))
sub IDF {

	my $self = shift;
	my $word = shift;

	my $count = 0;

	foreach my $el (keys %{$self->{file}}) {
		$count++ if (defined $self->{file}->{$el}->{$word});
	}

	return log(scalar(keys %{$self->{file}})/($count))/log(10);
}

sub process_files {

	my $self = shift;
        my @documents = @_;

        foreach my $el (@documents) {
                $self->_process_file($el);
        }

	return 1;
}

sub _process_file {
	my $self = shift;
        my $file = shift;

        my $hash;
	return undef if (!-r $file);
	open my $handle, '<:encoding(UTF-8)', $file || die $file," ",$!;
        while (<$handle>) {
                chop;
                my $line = lc($_);
                my @words = split(/\s+/,$line);
                foreach my $el (@words) {
                        $el =~ s/[?;:!,."\(\)]//g; 
			my $word = Encode::encode("utf8",$el);
                        if (defined $hash->{$word}) {
                                $hash->{$word}++;
                        }
                        else {
                                $hash->{$word} = 1;
                        }
                }
        }
	close($handle);
	
	$self->{file}->{$file} = $hash;

}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Text::TFIDF - Perl extension for computing the TF-IDF measure

=head1 SYNOPSIS

  use Text::TFIDF;
  my $Obj = new Text::TFIDF(file=>[file1,file2...]);
  print $Obj->TFIDF($file,$word);

=head1 DESCRIPTION

The TF-IDF weight (ie, Frequency-Inverse Document Frequency) weight is used in information retrieval and text mining.  It is a statistical measure used to see how important a word is in a document or collection of documents.  This module is designed to only work on text documents at this time.

Currently, the module reads everything into memory.  This should be altered in the future.

=head2 EXPORT

None by default.

=head2 new(file=>\@files) 

Creates a new module.  If the file argument is passed in, populates the module using those files.

=head2 TFIDF(file,word)

Computes the TF-IDF weight for the given document and word.  If the file is not in the corpus used to populate the module, returns undef

=head2 TF(file,word)

Returns the frequency of the given word in the document.

=head2 IDF(word)

Returns the inverse document frequency of a word.  That is, the ratio of the number of documents in the corpus divided by the number of documents containing the term and taking the logarithm of the result.  Since the number of documents containing the term can be zero, we add one to the result to ensure a rational result.

=head2 process_files(@files)

Populates the document with the given list of files.  This does not replace data currently in the document, rather, it adds to the list.


=head1 SEE ALSO

See http://en.wikipedia.org/wiki/Tf-idf for more information.

=head1 AUTHOR

Leigh Metcalf, E<lt>leigh@fprime.net<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Leigh Metcalf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
