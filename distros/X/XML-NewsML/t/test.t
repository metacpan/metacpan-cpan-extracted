use Test::More tests => 1;

use XML::NewsML;

my $newsml = new XML::NewsML(
	datetime	=> '20070913T145700',
	provider	=> 'example.com',
	timezone	=> '+0300',
);

$newsml->addNews(
	datetime	=> '20070913T102417',
	title		=> 'News Title',
	keywords	=> 'keyword line, first',
	content		=> 'News Content',
);

$newsml->addNews(
	datetime	=> '20070913T102418',
	id			=> 342,
	title		=> 'News Title 2',
	keywords	=> 'keyword line, second',
	content		=> 'News Content 2',
	image		=> '/img/x.jpg',
);

$newsml->addNews(
	datetime	=> '20070913T102419',
	id			=> 343,
	revision	=> 14,
	title		=> 'News Title 3',
	keywords	=> 'alpha, beta, gamma',
	content		=> 'News Content 2',
	image		=> ['/img/y.jpg', '/img/z.png'],
);

$result = <<RESULT;
<?xml version="1.0"?>
<NewsML>
  <NewsEnvelope>
    <DateAndTime>20070913T145700+0300</DateAndTime>
    <Priority FormalName="1"/>
    <NewsProduct FormalName="1"/>
  </NewsEnvelope>
  <NewsItem>
    <Identification>
      <NewsIdentifier>
        <ProviderId>example.com</ProviderId>
        <DateId>20070913</DateId>
        <NewsItemId>1</NewsItemId>
        <RevisionId PreviousRevision="0" Update="N">1</RevisionId>
        <PublicIdentifier/>
      </NewsIdentifier>
    </Identification>
    <NewsManagement>
      <NewsItemType FormalName="News"/>
      <FirstCreated>20070913T102417+0300</FirstCreated>
      <ThisRevisionCreated>20070913T102417+0300</ThisRevisionCreated>
      <Status FormalName="Usable"/>
    </NewsManagement>
    <NewsComponent>
      <NewsLines>
        <HeadLine>News Title</HeadLine>
        <KeywordLine>keyword line, first</KeywordLine>
      </NewsLines>
      <ContentItem>
        <MediaType FormalName="Text"/>
        <MimeType FormalName="text/plain"/>
        <Format FormalName="Text"/>
        <DataContent>News Content</DataContent>
      </ContentItem>
    </NewsComponent>
  </NewsItem>
  <NewsItem>
    <Identification>
      <NewsIdentifier>
        <ProviderId>example.com</ProviderId>
        <DateId>20070913</DateId>
        <NewsItemId>342</NewsItemId>
        <RevisionId PreviousRevision="0" Update="N">1</RevisionId>
        <PublicIdentifier/>
      </NewsIdentifier>
    </Identification>
    <NewsManagement>
      <NewsItemType FormalName="News"/>
      <FirstCreated>20070913T102418+0300</FirstCreated>
      <ThisRevisionCreated>20070913T102418+0300</ThisRevisionCreated>
      <Status FormalName="Usable"/>
    </NewsManagement>
    <NewsComponent>
      <NewsLines>
        <HeadLine>News Title 2</HeadLine>
        <KeywordLine>keyword line, second</KeywordLine>
      </NewsLines>
      <ContentItem>
        <MediaType FormalName="Text"/>
        <MimeType FormalName="text/plain"/>
        <Format FormalName="Text"/>
        <DataContent>News Content 2</DataContent>
      </ContentItem>
      <ContentItem Href="/img/x.jpg">
        <MediaType FormalName="Photo"/>
        <MimeType FormalName="image/jpeg"/>
        <Format FormalName="JPEG Baseline"/>
      </ContentItem>
    </NewsComponent>
  </NewsItem>
  <NewsItem>
    <Identification>
      <NewsIdentifier>
        <ProviderId>example.com</ProviderId>
        <DateId>20070913</DateId>
        <NewsItemId>343</NewsItemId>
        <RevisionId PreviousRevision="0" Update="N">14</RevisionId>
        <PublicIdentifier/>
      </NewsIdentifier>
    </Identification>
    <NewsManagement>
      <NewsItemType FormalName="News"/>
      <FirstCreated>20070913T102419+0300</FirstCreated>
      <ThisRevisionCreated>20070913T102419+0300</ThisRevisionCreated>
      <Status FormalName="Usable"/>
    </NewsManagement>
    <NewsComponent>
      <NewsLines>
        <HeadLine>News Title 3</HeadLine>
        <KeywordLine>alpha, beta, gamma</KeywordLine>
      </NewsLines>
      <ContentItem>
        <MediaType FormalName="Text"/>
        <MimeType FormalName="text/plain"/>
        <Format FormalName="Text"/>
        <DataContent>News Content 2</DataContent>
      </ContentItem>
      <ContentItem Href="/img/y.jpg">
        <MediaType FormalName="Photo"/>
        <MimeType FormalName="image/jpeg"/>
        <Format FormalName="JPEG Baseline"/>
      </ContentItem>
      <ContentItem Href="/img/z.png">
        <MediaType FormalName="Photo"/>
        <MimeType FormalName="image/png"/>
        <Format FormalName="PNG"/>
      </ContentItem>
    </NewsComponent>
  </NewsItem>
</NewsML>
RESULT
my $r = $newsml->toString();
ok($r eq $result);
