use strict;
use XML::Rules;

my $parser = XML::Rules->new(
	rules => [
		_default => 'content',
		'other,
		Author' => 'as array',
		AuthorList => sub { return Authors => $_[1]->{Author} },
		PubmedArticle => 'pass',
	],
	stripspaces => 7,
);
my $data = $parser->parse( \*DATA);

use Data::Dumper;
print Dumper($data);

foreach my $author (@{$data->{Authors}}) {
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
