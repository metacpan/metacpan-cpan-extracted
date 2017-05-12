package Import::Client;

use utf8;

use XML::LibXML;
use Import::Datasource;

my $MAX = 10;

sub import
{
	my $class = shift;
	
	my $this = {};
	
	return bless $this, $class;
}

sub keywordList
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $args = shift;
	my $dbh = $Import::Datasource::handler;

	my $sth = $dbh->prepare ("select keyword, uri from keywords order by keyword");
	$sth->execute();
	while (my ($keyword, $uri) = $sth->fetchrow_array())
	{
		my $item = $page->{'xml'}->createElement ('item');
		$item->appendText ($keyword);
		$item->setAttribute ('uri', $uri);
		$node->appendChild ($item);
	}

	return $node;
}

sub monthCalendar
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $args = shift;
	my $dbh = $Import::Datasource::handler;

	my $sth = $dbh->prepare ("select distinct count(*), month(date), year(date) from message where site_id=1 and is_published=1 and date <= now() group by concat(month(date), year(date)) order by date desc");
	$sth->execute();
	while (my ($count, $month, $year) = $sth->fetchrow_array())
	{
		my $item = $page->{'xml'}->createElement ('item');
		$item->setAttribute ('count', $count);
		$item->setAttribute ('month', sprintf ("%02i", $month));
		$item->setAttribute ('year', $year);
		$node->appendChild ($item);
	}

	return $node;
}

sub currentView
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $args = shift;
	my $dbh = $Import::Datasource::handler;

	my $uri = $ENV{'REQUEST_URI'};
	$uri =~ s{/}{}g;
	$uri =~ s{\?.*}{};
	$uri =~ s{%20}{ }g;
	if (length $uri)
	{
		my $sth = $dbh->prepare ("select count(*) from keywords where uri = " . $dbh->quote ($uri));
		$sth->execute();
		my ($count) = $sth->fetchrow_array();
		$sth->finish();
		if ($count)
		{
			return $this->viewCategory ($page, $node, $uri);
		}
		else
		{
			my $site_id = getSiteID();

			my $sth = $dbh->prepare ("select count(*) from message where is_published = 1 and site_id = $site_id and message.date <= now() and uri = " . $dbh->quote ($uri));
			$sth->execute();
			($count) = $sth->fetchrow_array();
			$sth->finish();
			if ($count)
			{
				return $this->viewMessage ($page, $node, $uri);
			}
			else
			{
				print "Location: http://$ENV{'SERVER_NAME'}/\n\n";
				exit;
			}
		}
	}

	return $node;
}

sub mainView
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $args = shift;
	my $dbh = $Import::Datasource::handler;
	
	my $site_id = getSiteID();

    my $count = $args->{'count'} || $MAX;
	my $sth = $dbh->prepare ("select keywords.keyword, message.id, message.uri, dayofmonth(message.date), month(message.date), year(message.date), message.title, message.content from message left join keyword2message on keyword2message.message_id = message.id left join keywords on keywords.id = keyword2message.keyword_id where message.is_published = 1 and message.site_id = ? and message.date <= now() group by message.id order by message.date desc, message.id desc limit ?");
	$sth->execute($site_id, $count);

	my @message_ids = ();
	
	while (my ($keyword, $message_id, $message_uri, $day, $month, $year, $title, $content) = $sth->fetchrow_array())
	{
		push @message_ids, $message_id;

		my $messageNode = $page->{'xml'}->createElement ('message');
		$node->appendChild ($messageNode);
		
		$messageNode->setAttribute ('day', $day);
		$messageNode->setAttribute ('month', $month);
		$messageNode->setAttribute ('year', $year);
		$messageNode->setAttribute ('id', $message_id);
		$messageNode->setAttribute ('uri', $message_uri);

		my $titleNode = $page->{'xml'}->createElement ('title');
		$messageNode->appendChild ($titleNode);
		$titleNode->appendText ($title);

		my $contentNode = $page->{'xml'}->createElement ('content');
		$messageNode->appendChild ($contentNode);
		$contentNode->appendText ($content);
	}
	$sth->finish();


	my $keywordMap = $page->{'xml'}->createElement ('keyword-map');
	$node->appendChild ($keywordMap);

	if (@message_ids)
	{
		$sth = $dbh->prepare ("select message_id, keywords.uri from keywords join keyword2message on keywords.id = keyword2message.keyword_id where message_id in (". join (',', @message_ids) . ") order by keyword2message.id");
		$sth->execute();
		while (my ($message_id, $uri) = $sth->fetchrow_array())
		{
			my $item = $page->{'xml'}->createElement ('item');
			$item->setAttribute ('message-id', $message_id);
			$item->setAttribute ('uri', $uri);
			$keywordMap->appendChild ($item);
		}
		$sth->finish();
	}

	return $node;
}

sub monthView
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $uri = shift;
	my $dbh = $Import::Datasource::handler;

	my ($year, $month) = $ENV{'REQUEST_URI'} =~ m{^/(\d{4})/(\d+\d?)/?};
	unless ($year && $month)
	{
		print "Location: http://$ENV{'SERVER_NAME'}/\n\n";
		exit;
	}

	my $site_id = getSiteID();

	my $sth = $dbh->prepare ("select keywords.keyword, message.id, message.uri, dayofmonth(message.date), month(message.date), year(message.date), message.title, message.content from message left join keyword2message on keyword2message.message_id = message.id left join keywords on keywords.id = keyword2message.keyword_id where message.is_published = 1 and message.site_id = $site_id and year(date) = $year and month(date) = $month and message.date <= now() group by message.id order by message.date desc, message.id desc");
	$sth->execute();

	my @message_ids = ();
	
	while (my ($keyword, $message_id, $message_uri, $day, $month, $year, $title, $content) = $sth->fetchrow_array())
	{
		push @message_ids, $message_id;

		my $messageNode = $page->{'xml'}->createElement ('message');
		$node->appendChild ($messageNode);
		
		$messageNode->setAttribute ('day', $day);
		$messageNode->setAttribute ('month', $month);
		$messageNode->setAttribute ('year', $year);
		$messageNode->setAttribute ('id', $message_id);
		$messageNode->setAttribute ('uri', $message_uri);

		my $titleNode = $page->{'xml'}->createElement ('title');
		$messageNode->appendChild ($titleNode);
		$titleNode->appendText ($title);

		my $contentNode = $page->{'xml'}->createElement ('content');
		$messageNode->appendChild ($contentNode);
		$contentNode->appendText ($content);
	}
	$sth->finish();

	unless (@message_ids)
	{
		print "Location: http://$ENV{'SERVER_NAME'}/\n\n";
		exit;
	}

	$node->setAttribute ('month', $month);
	$node->setAttribute ('year', $year);

	my $keywordMap = $page->{'xml'}->createElement ('keyword-map');
	$node->appendChild ($keywordMap);

	$sth = $dbh->prepare ("select message_id, keywords.uri from keywords join keyword2message on keywords.id = keyword2message.keyword_id where message_id in (". join (',', @message_ids) . ") order by keyword2message.id");
	$sth->execute();
	while (my ($message_id, $uri) = $sth->fetchrow_array())
	{
		my $item = $page->{'xml'}->createElement ('item');
		$item->setAttribute ('message-id', $message_id);
		$item->setAttribute ('uri', $uri);
		$keywordMap->appendChild ($item);
	}
	$sth->finish();

	return $node;
}

sub rssView
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $uri = shift;
	my $dbh = $Import::Datasource::handler;

	use Date::Manip qw(ParseDate UnixDate);
	my $rfc822_format = "%a, %d %b %Y %H:%M:%S +0300";
	my $today = ParseDate ("Now");
	my $rfc822_date = UnixDate ($today, $rfc822_format);
	
	my $pubDate = $page->{'xml'}->createElement ('pub-date');
	$pubDate->appendText ($rfc822_date);
	$node->appendChild ($pubDate);

	my $site_id = getSiteID();

	my $sth = $dbh->prepare ("select message.uri, date, message.title, message.content from message where message.is_published = 1 and message.site_id = $site_id and message.date <= now() order by message.date desc, message.id desc limit $MAX");
	$sth->execute();

	while (my ($message_uri, $date, $title, $content) = $sth->fetchrow_array())
	{
		my $messageNode = $page->{'xml'}->createElement ('message');
		$node->appendChild ($messageNode);

		my $rfc822_date = UnixDate (ParseDate ($date), $rfc822_format);

		$messageNode->setAttribute ('uri', $message_uri);
		$messageNode->setAttribute ('date', $rfc822_date);

		my $titleNode = $page->{'xml'}->createElement ('title');
		$messageNode->appendChild ($titleNode);
		$titleNode->appendText (clearEntities ($title));

		my $contentNode = $page->{'xml'}->createElement ('content');
		$messageNode->appendChild ($contentNode);
		$contentNode->appendText (clearEntities ($content));
	}
	$sth->finish();

	return $node;
}

sub viewCategory
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $uri = shift;
	my $dbh = $Import::Datasource::handler;
    
	my $site_id = getSiteID();

	my $sth = $dbh->prepare ("select keywords.keyword, message.id, message.uri, dayofmonth(message.date), month(message.date), year(message.date), message.title, message.content from message join keyword2message on keyword2message.message_id = message.id join keywords on keywords.id = keyword2message.keyword_id where message.is_published = 1 and message.site_id = $site_id and keywords.uri = " . $dbh->quote ($uri) . " and message.date <= now() order by message.date desc, message.id desc");
	$sth->execute();

	my @message_ids = ();
	my $groupKeyword;
	
	while (my ($keyword, $message_id, $message_uri, $day, $month, $year, $title, $content) = $sth->fetchrow_array())
	{
		push @message_ids, $message_id;

		unless ($groupKeyword)
		{
			$groupKeyword = $keyword;
			my $groupKeyword = $page->{'xml'}->createElement ('group-keyword');
			$groupKeyword->appendText ($keyword);
			$groupKeyword->setAttribute ('uri', $uri);
			$node->appendChild ($groupKeyword);
		}

		my $messageNode = $page->{'xml'}->createElement ('message');
		$node->appendChild ($messageNode);
		
		$messageNode->setAttribute ('day', $day);
		$messageNode->setAttribute ('month', $month);
		$messageNode->setAttribute ('year', $year);
		$messageNode->setAttribute ('id', $message_id);
		$messageNode->setAttribute ('uri', $message_uri);

		my $titleNode = $page->{'xml'}->createElement ('title');
		$messageNode->appendChild ($titleNode);
		$titleNode->appendText ($title);

		my $contentNode = $page->{'xml'}->createElement ('content');
		$messageNode->appendChild ($contentNode);
		$contentNode->appendText ($content);
	}
	$sth->finish();


	my $keywordMap = $page->{'xml'}->createElement ('keyword-map');
	$node->appendChild ($keywordMap);

	$sth = $dbh->prepare ("select message_id, keywords.uri from keywords join keyword2message on keywords.id = keyword2message.keyword_id where message_id in (". join (',', @message_ids) . ") order by keyword2message.id");
	$sth->execute();
	while (my ($message_id, $uri) = $sth->fetchrow_array())
	{
		my $item = $page->{'xml'}->createElement ('item');
		$item->setAttribute ('message-id', $message_id);
		$item->setAttribute ('uri', $uri);
		$keywordMap->appendChild ($item);
	}

	$sth->finish();

	return $node;
}

sub viewMessage
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $uri = shift;
	my $dbh = $Import::Datasource::handler;

	my $site_id = getSiteID();

	my $sth = $dbh->prepare ("select id, dayofmonth(date), month(date), year(date), title, content from message where is_published = 1 and site_id = $site_id and message.date <= now() and uri = " . $dbh->quote ($uri));
	$sth->execute();
	my ($message_id, $day, $month, $year, $title, $content) = $sth->fetchrow_array();
	$sth->finish();

	my $messageNode = $page->{'xml'}->createElement ('message');
	$node->appendChild ($messageNode);

	$messageNode->setAttribute ('type', 'single-message');
	
	$messageNode->setAttribute ('day', $day);
	$messageNode->setAttribute ('month', $month);
	$messageNode->setAttribute ('year', $year);

	my $titleNode = $page->{'xml'}->createElement ('title');
	$messageNode->appendChild ($titleNode);
	$titleNode->appendText ($title);

	my $contentNode = $page->{'xml'}->createElement ('content');
	$messageNode->appendChild ($contentNode);
	$contentNode->appendText ($content);


	my $keywordsNode = $page->{'xml'}->createElement ('keywords');
	$messageNode->appendChild ($keywordsNode);
	$sth = $dbh->prepare ("select keyword, uri from keywords join keyword2message on keywords.id = keyword2message.keyword_id where message_id = $message_id order by keyword2message.id");
	$sth->execute();
	while (my ($keyword, $uri) = $sth->fetchrow_array())
	{
		my $item = $page->{'xml'}->createElement ('item');
		$item->setAttribute ('uri', $uri);
		$item->appendText ($keyword);
		$keywordsNode->appendChild ($item);
	}
	$sth->finish();

	return $node;
}

sub messageList
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $args = shift;
	my $dbh = $Import::Datasource::handler;

	my $sth = $dbh->prepare ("select id, dayofmonth(date), month(date), year(date), title, is_published, site_id from message and message.date <= now() order by date desc, id desc");
	$sth->execute();
	while (my ($id, $day, $month, $year, $title, $is_published, $site_id) = $sth->fetchrow_array())
	{
		my $item = $page->{'xml'}->createElement ('item');
		$item->setAttribute ('id', $id);
		$item->setAttribute ('day', $day);
		$item->setAttribute ('month', $month);
		$item->setAttribute ('year', $year);
		$item->setAttribute ('is_published', $is_published);
		$item->setAttribute ('site_id', $site_id);
		$item->appendText ($title);
		$node->appendChild ($item);
	}
	$sth->finish();

	return $node;
}

sub tagCloud
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $args = shift;
	my $dbh = $Import::Datasource::handler;

	my $site_id = getSiteID();

	my $sth = $dbh->prepare ("select count(*) from message where site_id = $site_id and is_published = 1");
	$sth->execute();
	my ($total) = $sth->fetchrow_array();
	$sth->finish();
	$total = 1 unless $total;
	$node->setAttribute ('total', $total);

	$sth = $dbh->prepare ("select keyword, keywords.uri, count(*) from keywords join keyword2message on keywords.id = keyword2message.keyword_id join message on message.id = keyword2message.message_id where site_id = $site_id and is_published = 1 and message.date <= now() group by keywords.id order by keywords.keyword");
	$sth->execute();
	my ($min, $max) = ($total, 0);
	while (my ($keyword, $keyword_uri, $count) = $sth->fetchrow_array())
	{
		my $item = $page->{'xml'}->createElement ('item');
		$item->setAttribute ('uri', $keyword_uri);
		$item->setAttribute ('count', $count);
		$item->appendText ($keyword);
		$node->appendChild ($item);

		$min = $count if $count < $min;
		$max = $count if $count > $max;
	}
	$sth->finish();

	$node->setAttribute ('min', $min);
	$node->setAttribute ('max', $max);

	return $node;
}

sub clearEntities
{
	my $text = shift;

	$text =~ s{&nbsp;}{ }gm;
	$text =~ s{&mdash;}{&#8212;}gm;
	$text =~ s{&laquo;}{&#171;}gm;
	$text =~ s{&raquo;}{&#187;}gm;
	$text =~ s{&bdquo;}{&#132;}gm;
	$text =~ s{&ldquo;}{&#148;}gm;

	$text =~ s{&\w+;}{ }gm;

	return $text;
}

sub messageCounter
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $args = shift;
	my $dbh = $Import::Datasource::handler;

	my $site_id = getSiteID();

	my $sth = $dbh->prepare ("select count(*) from message where is_published = 1 and site_id = $site_id and message.date <= now()");
	$sth->execute();
	my ($count) = $sth->fetchrow_array();
	$sth->finish();

	$node->appendText ($count);

	return $node;
}

sub searchResults
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $args = shift;
	my $dbh = $Import::Datasource::handler;

	my $site_id = getSiteID();

	my $query = $page->param ('text');

	my $sth = $dbh->prepare (
			"select
				id,
				uri,
				title,
				content
			from
				message
			where
				match(content, title) against (". $dbh->quote ($query) . ")
				and is_published = 1
				and site_id = $site_id"
			);
	$sth->execute();
	while (my ($id, $uri, $title, $content) = $sth->fetchrow_array())
	{
		my $item = $page->{'xml'}->createElement ('item');
		$node->appendChild ($item);
		$item->setAttribute ('id', $id);
		$item->setAttribute ('uri', $uri);
	
		my $titleNode = $page->{'xml'}->createElement ('title');
		$item->appendChild ($titleNode);
		$titleNode->appendText (highlight ($title, $query, 1));
		
		my $contentNode = $page->{'xml'}->createElement ('content');
		$item->appendChild ($contentNode);
		$contentNode->appendText (highlight ($content, $query));		
	}
	$sth->finish();

	my $query = $page->{'xml'}->createElement ('query');
	$query->appendText ($page->param ('text'));
	$node->addChild ($query);

	return $node;
}

sub highlight
{
	my $content = shift;
	my $query = shift;
	my $type = shift;
	
	$query =~ s{^\s+}{};
	$query =~ s{\s+$}{};
	$query =~ s{[^\w\d\s]}{}g;
	my @query = split / +/, $query;
	
	foreach my $q (@query)
	{
		$content =~ s{($q\w*)}{<span class="highlight">$1</span>}gims;
	}

	return $content if $type == 1;

	$content =~ s{^[\s\n]*<p[^>]*>}{}i;
	$content =~ s{</p>[\s\n]*$}{}i;
	my @p = split /<\/p>\s*?<p[^>]*>/i, $content;
	my $result = '';
	foreach my $p (@p)
	{
		if ($p =~ m{<span class="highlight">})
		{
			$result .= "<p>$p</p>";
		}
	}
	if ($result eq '')
	{
		$result = "<p>$p[0]</p>";
	}

	return $result;
}

sub searchKeywords
{
    my $this = shift;
	my $page = shift;
	my $node = shift;
	my $args = shift;
	my $dbh = $Import::Datasource::handler;

	my $query = $page->param ('text');
	$query =~ s{^\s+}{};
	$query =~ s{\s+$}{};
	$query =~ s{[^\w\d\s]}{}g;
	my @query = split / +/, $query;

	$query = join ', ', map "'$_'", @query;
	
	my $sth = $dbh->prepare ("select keyword, uri from keywords where keyword in ($query)");
	$sth->execute();
	while (my ($keyword, $uri) = $sth->fetchrow_array())
	{
		my $item = $page->{'xml'}->createElement ('item');
		$item->setAttribute ('uri', $uri);
		$item->appendText ($keyword);
		$node->appendChild ($item);
	}
	$sth->finish();

	return $node;
}

sub getSiteID()
{
	my $site_id = 1;

	return $site_id;
}

1;		
