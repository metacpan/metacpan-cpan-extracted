use strict;
use XML::Simple qw(XMLin);

my $data = XMLin( \*DATA, ForceArray => [qw(Author)]);

use Data::Dumper;
print Dumper($data);

foreach my $author (@{$data->{AuthorList}{Author}}) {
	print "$author->{ForeName} $author->{LastName}\n";
}

__DATA__
<PubmedArticle>
            <AuthorList CompleteYN="Y">
                <Author ValidYN="Y">
                    <LastName>van Beilen</LastName>
                    <ForeName>J B</ForeName>
                    <Initials>JB</Initials>
                </Author>
                <Author ValidYN="Y">
                    <LastName>Penninga</LastName>
                    <ForeName>D</ForeName>
                    <Initials>D</Initials>
                </Author>
                <Author ValidYN="Y">
                    <LastName>Witholt</LastName>
                    <ForeName>B</ForeName>
                    <Initials>B</Initials>
                </Author>
            </AuthorList>
</PubmedArticle>
