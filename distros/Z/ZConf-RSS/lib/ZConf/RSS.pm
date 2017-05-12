package ZConf::RSS;

use warnings;
use strict;
use ZConf;
use XML::FeedPP;
use Text::NeatTemplate;
use HTML::FormatText::WithLinks;

=head1 NAME

ZConf::RSS - ZConf backed RSS fetching.

=head1 VERSION

Version 2.2.0

=cut

our $VERSION = '2.2.0';


=head1 SYNOPSIS

    use ZConf::RSS;

    my $zcrss = ZConf::RSS->new();
    ...

=head1 METHODS

=head2 new

This initializes it.

One arguement is taken and that is a hash value.

=head3 hash values

=head4 zconf

This is the a ZConf object. If not passed, another one will be created.

    my $zcrss=ZConf::RSS->new();
    if($zcrss->{error}){
        print "Error!\n";
    }

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='new';

	my $self={error=>undef,
			  errorString=>undef,
			  zconfconfig=>'rss',
			  perror=>1,
			  module=>'ZConf-RSS',
			  };
	bless $self;

	#get the ZConf object
	if (!defined($args{zconf})) {
		#creates the ZConf object
		$self->{zconf}=ZConf->new();
		if(defined($self->{zconf}->{error})){
			$self->{error}=1;
			$self->{perror}=1;
			$self->{errorString}="Could not initiate ZConf. It failed with '"
			                     .$self->{zconf}->{error}."', '".
			                     $self->{zconf}->{errorString}."'";
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
	}else {
		$self->{zconf}=$args{zconf};
	}

	#create the config if it does not exist
	#if it does exist, make sure the set we are using exists
    my $returned = $self->{zconf}->configExists($self->{zconfconfig});
	if($self->{zconf}->{error}){
		$self->{error}=2;
		$self->{perror}=1;
		$self->{errorString}="Checking if '".$self->{zconfconfig}."' exists failed. error='".
		                     $self->{zconf}->{error}."', errorString='".
		                     $self->{zconf}->{errorString}."'";
		warn($self->{module}.' '.$function.':'.$self->{error}.':'.$self->{errorString});
		return $self;
	}

	#initiate the config if it does not exist
	if (!$returned) {
		#init it
		$self->init;
		if ($self->{zconf}->{error}) {
			$self->{perror}=1;
			$self->{errorString}='Init failed.';
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
	}else {
		#if we have a set, make sure we also have a set that will be loaded
		$returned=$self->{zconf}->defaultSetExists($self->{zconfconfig});
		if ($self->{zconf}->{error}) {
			$self->{error}=2;
			$self->{perror}=1;
			$self->{errorString}="Checking if '".$self->{zconfconfig}."' exists failed. error='".
			$self->{zconf}->{error}."', errorString='".
			$self->{zconf}->{errorString}."'";
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return $self;
		}
		
		#if we don't have a default set, initialize it
		if (!$returned) {
			#init it
			$self->init;
			if ($self->{zconf}->{error}) {
				$self->{perror}=1;
				$self->{errorString}='Init failed.';
				warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
				return $self;
			}
		}
	}

	#read the config
	$self->{zconf}->read({config=>$self->{zconfconfig}});
	if ($self->{zconf}->{error}) {
		$self->{error}=1;
		$self->{perror}=1;
		$self->{errorString}="Reading the ZConf config '".$self->{zconfconfig}."' failed. error='".
		                     $self->{zconf}->{error}."', errorString='".
		                     $self->{zconf}->{errorString}."'";
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return $self;
	}


	return $self;
}

=head2 feedExists

This makes sure a specified template exists.

    my $returned=$zcrss->feedExists('someFeed');
    if($zcw->{error}){
        print "Error!\n";
    }else{
        if($returned){
            print "It exists.\n";
        }
    }

=cut

sub feedExists{
	my $self=$_[0];
	my $template=$_[1];
	my $function='feedExists';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}


	my @templates=$self->listFeeds;
	if ($self->{error}) {
		warn('ZConf-RSS feedExists:2: listFeeds errored');
		return undef;
	}

	my $int=0;
	while (defined($templates[$int])) {
		if ($templates[$int] eq $template) {
			return 1;
		}
		
		$int++;
	}

	return undef;
}

=head2 delFeed

This removes a feed.

One arguement is required and that is the name of the feed.

    $zcrss->delFeed('someFeed');
    if($self->{error}){
        print "Error!\n";
    }

=cut

sub delFeed{
	my $self=$_[0];
	my $feed=$_[1];
	my $function='delFeed';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	#makes sure a feed is specified
	if (!defined($feed)) {
		$self->{error}=3;
		$self->{errorString}='No feed specified.';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure it exists
	if (!$self->feedExists($feed)) {
		$self->{error}=5;
		$self->{errorString}='The feed, "'.$feed.'", does not exist';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#remove them
	my @deleted=$self->{zconf}->regexVarDel('rss', '^feeds\/'.quotemeta($feed).'\/');
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}="regexVarDel errored ".
		                     "error='".$self->{zconf}->{error}."' errorString='"
		                     .$self->{zconf}->{errorString}."'";
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'rss'});
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}=" writeSetFromLoadedConfig for 'rss'.".
		                     "failed with '".$self->{zconf}->{error}."', '"
		                     .$self->{zconf}->{errorString}."'";
		#remove any that were added
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 delTemplate

This removes a template.

One arguement is taken and it is the template name.

    $zcrss->delTemplate('someTemplate');
    if($zcrss->{error}){
        print "Error!\n";
    }

=cut

sub delTemplate{
	my $self=$_[0];
	my $template=$_[1];
	my $function='delFeed';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	#makes sure a feed is specified
	if (!defined($template)) {
		$self->{error}=3;
		$self->{errorString}='No template specified.';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure it exists
	my $returned=$self->templateExists($template);
	if (!$returned) {
		$self->{error}=7;
		$self->{errorString}='The template, "'.$template.'", does not exist';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#remove them
	my @deleted=$self->{zconf}->regexVarDel('rss', '^templates\/'.quotemeta($template).'$');
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}="regexVarDel errored ".
		                     "error='".$self->{zconf}->{error}."' errorString='"
		                     .$self->{zconf}->{errorString}."'";
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#saves it
	$self->{zconf}->writeSetFromLoadedConfig({config=>'rss'});
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}=" writeSetFromLoadedConfig for 'rss'.".
		                     "failed with '".$self->{zconf}->{error}."', '"
		                     .$self->{zconf}->{errorString}."'";
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 getFeed

This creates a 'XML::FeedPP' object based on a feed.

One arguement is taken and it is the name of the feed.

    my $feedobj=$zcrss->getFeed;
    if($zcrss->{error}){
        print "Error!\n";
    }

=cut

sub getFeed{
	my $self=$_[0];
	my $feed=$_[1];
	my $function='getFeed';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	#get the arguements for the feed
	my %args=$self->getFeedArgs($feed);
	if ($self->{error}) {
		warn('ZConf-RSS getFeed: getFeedArgs for "'.$feed.'" failed');
		return undef;
	}

	#
	my $feedobj = XML::FeedPP->new($args{feed});
	if (!defined($feedobj)) {
		$self->{error}=7;
		$self->{errorString}='Failed to load the feed "'.$feed.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return $feedobj;
}

=head2 getFeedArgs

This fetches the arguements for the feed.

    my %args=$zcrss->getFeedArgs('someFeed');
    if($zcrss->{error}){
        print "Error!\n";
    }

=cut

sub getFeedArgs{
	my $self=$_[0];
	my $feed=$_[1];
	my $function='getFeedArgs';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	if (!defined($feed)) {
		$self->{error}=3;
		$self->{errorString}='No feed name given.';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	if (!$self->feedExists($feed)) {
		$self->{error}=5;
		$self->{errorString}='The feed, "'.$feed.'", does not exist';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#
	if ($feed=~/\//) {
		warn('ZConf-RSS getFeedArgs:4: The feed name "'.$feed.'" matches /\//');
		$self->{error}=4;
		$self->{errorString}='The feed name "'.$feed.'" matches /\//';
		return undef;
	}

	#blanks any previous variables
	my %vars=$self->{zconf}->regexVarGet('rss', '^feeds/'.$feed.'/');
	if($self->{zconf}->{error}){
		$self->{error}=2;
		$self->{errorString}='regexVarGet failed for "rss".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}	

	my @keys=keys(%vars);
	my $int=0;
	my %args;
	while (defined($keys[$int])) {
		my @split=split(/\//, $keys[$int], 3);
		$args{$split[2]}=$vars{$keys[$int]};

		$int++;
	}

	return %args;
}

=head2 getFeedAsTemplatedString

This fetches a feed, processes it using the specified templates
and returns a string.

    my $string=$zcrss->getFeedAsTemplatedString('someFeed');
    if($zcrss->{error}){
        print "Error!\n";
    }

=cut

sub getFeedAsTemplatedString{
	my $self=$_[0];
	my $feed=$_[1];
	my $function='getFeedAsTemplatedString';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	#get the arguements for the feed
	my %args=$self->getFeedArgs($feed);
	if ($self->{error}) {
		warn('ZConf-RSS getFeed: getFeedArgs for "'.$feed.'" failed');
		return undef;
	}

	#gets the feed object
	my $fo=$self->getFeed($feed);

	#this is the hash that will be passed to the template system
	my %thash=(ctitle=>'', cdesc=>'', cpubdate=>'', ccopyright=>'', clink=>'',
			   clang=>'', cimage=>'', ititle=>'', idesc=>'', ipubdate=>'',
			   icat=>'', iauthor=>'', iguid=>'', ilink=>'');

	#used for checking to make sure everything is defined
	my @hashItems=keys(%thash);

	#gets the channel stuff
	$thash{ctitle}=$fo->title();
	$thash{cdesc}=$fo->description();
	$thash{cpubdate}=$fo->pubDate();
	$thash{ccopyright}=$fo->copyright();
	$thash{clink}=$fo->link();
	$thash{clang}=$fo->language();
	$thash{cimage}=$fo->image();

	#makes sure everything in the hash is defined
	foreach (@hashItems) {
		if (!defined($thash{$_})) {
			$thash{$_}='';
		}
	}

	#get the templates
	my $topT=$self->getTemplate($args{topTemplate});
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': getTemplate errored');
		return undef;
	}
	my $itemT=$self->getTemplate($args{itemTemplate});
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': getTemplate errored');
		return undef;
	}
	my $bottomT=$self->getTemplate($args{bottomTemplate});
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': getTemplate errored');
		return undef;
	}

	my $tobj = Text::NeatTemplate->new();

	my $string=$tobj->fill_in(data_hash=>\%thash, template=>$topT);
	
	#process each item
	foreach my $item ($fo->get_item())  {
		#gets the channel stuff
		$thash{ititle}=$item->title();
		$thash{idesc}=$item->description();
		$thash{ipubdate}=$item->pubDate();
		$thash{ilink}=$item->link();
		#it will either return a string or array ref
		my $categories=$item->category;
		if (ref($categories) eq 'ARRAY') {
			$categories=join(', ', @{$categories});
		}
		$thash{icat}=$categories;
		$thash{iauthor}=$item->author();
		$thash{iguid}=$item->guid();

		#makes sure everything in the hash is defined
		foreach (@hashItems) {
			if (!defined($thash{$_})) {
				$thash{$_}='';
			}
		}

		#If you don't put this here, it add each previous link as well. :(
		my $f = HTML::FormatText::WithLinks->new(unique_links=>'1');
		$thash{idescFTWL}=$f->parse($thash{idesc});

		my $itemS=$tobj->fill_in(data_hash=>\%thash, template=>$itemT);

		$string=$string.$itemS;
	}

		$string=$string.$tobj->fill_in(data_hash=>\%thash, template=>$bottomT);

	return $string;
}

=head2 getSet

This gets what the current set is.

    my $set=$zcrss->getSet;
    if($zcrss->{error}){
        print "Error!\n";
    }

=cut

sub getSet{
	my $self=$_[0];
	my $function='getSet';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	my $set=$self->{zconf}->getSet('rss');
	if($self->{zconf}->{error}){
		$self->{error}=2;
		$self->{errorString}='ZConf error getting the loaded set the config "rss".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return $set;
}

=head2 getTemplate

This returns a template as a string.

    my $template=$zcrss->getTemplate('some/template');
    if ($zcrss->{error}) {
        print "Error!\n";
    }

=cut

sub getTemplate{
	my $self=$_[0];
	my $template=$_[1];
	my $function='getTemplate';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	if (!defined($template)) {
		$self->{error}=6;
		$self->{errorstring}='No template specified.';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	my $returned=$self->templateExists($template);
	if ($self->{error}) {
		warn('ZConf-RSS getTemplate: templateExists errored');
		return undef;
	}

	if (!$returned) {
		$self->{error}=7;
		$self->{errorString}='The template, "'.$template.'", does not exist';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return $self->{zconf}{conf}{rss}{'templates/'.$template};
}

=head2 init

This initializes it or a new set.

If the specified set already exists, it will be reset.

One arguement is required and it is the name of the set. If
it is not defined, ZConf will use the default one.

    #creates a new set named foo
    $zcw->init('foo');
    if($zcrss->{error}){
        print "Error!\n";
    }

    #creates a new set with ZConf choosing it's name
    $zcrss->init();
    if($zcrss->{error}){
        print "Error!\n";
    }

=cut

sub init{
	my $self=$_[0];
	my $set=$_[1];
	my $function='init';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	my $returned = $self->{zconf}->configExists("rss");
	if(defined($self->{zconf}->{error})){
		$self->{error}=2;
		$self->{errorString}="Could not check if the config 'rss' exists.".
		                     " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#create the config if it does not exist
	if (!$returned) {
		$self->{zconf}->createConfig("rss");
		if ($self->{zconf}->{error}) {
			$self->{error}=2;
			$self->{errorString}="Could not create the ZConf config 'rss'.".
			                 " It failed with '".$self->{zconf}->{rss}."', '"
			                 .$self->{zconf}->{errorString}."'";
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return undef;
		}
	}

	#default templates setup...
	my $top="Channel: {\$ctitle}\n".
	        "Date: {\$cpubdate}\n".
			"Language: {\$clang}\n".
			"Copywright: {\$ccopyright}\n".
			"Link: {\$clink}\n".
			"\n".
			"{\$cdesc}\n";
	my $item="--------------------------------------------------------------------------------\n".
	         "Title: {\$ititle}\n".
             "Date: {\$ipubdate}\n".
             "Author: {\$iauthor}\n".
			 "Category: {\$icat}\n".
			 "Link: {\$ilink}\n".
			 "".
			 "{\$idescFTWL}\n";

	my $bottom='';


	#create the new set
	$self->{zconf}->writeSetFromHash({config=>"rss", set=>$set},{
																 'templates/defaultTop'=>$top,
																 'templates/defaultItem'=>$item,
																 'templates/defaultBottom'=>$bottom,
																 });
	#error if the write failed
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}="writeSetFromHash failed.".
			                 " It failed with '".$self->{zconf}->{error}."', '"
			                 .$self->{zconf}->{errorString}."'";
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 listFeeds

This lists the available feeds.

   my @feeds=$zcrss->listFeeds();
   if($zcrss->{error}){
       print "Error!\n";
   }

=cut

sub listFeeds{
	my $self=$_[0];
	my $function='listFeeds';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	my @feedsA=$self->{zconf}->regexVarSearch('rss', '^feeds/');
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}='ZConf error listing feeds for the config "rss".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#removes feeds/ from the beginning of the variable name
	my $int=0;
	my %feeds;
	while (defined($feedsA[$int])) {
		my @split=split(/\//, $feedsA[$int]);
		$feeds{$split[1]}='';

		$int++;
	}

	return keys(%feeds);
}

=head2 listSets

This lists the available sets.

    my @sets=$zcrss->listSets;
    if($zcrss->{error}){
        print "Error!";
    }

=cut

sub listSets{
	my $self=$_[0];
	my $function='listSets';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	my @sets=$self->{zconf}->getAvailableSets('rss');
	if($self->{zconf}->{error}){
		$self->{error}=2;
		$self->{errorString}='ZConf error listing sets for the config "rss".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return @sets;
}

=head2 listTemplates

This gets a list of available templates.

    my @templates=$zcrss->listTemplates;
    if($zcrss->{error}){
        print "Error!\n";
    }

=cut

sub listTemplates{
	my $self=$_[0];
	my $function='listTemplates';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	my @templates=$self->{zconf}->regexVarSearch('rss', '^templates/');
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}='ZConf error listing templates for the config "rss".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#removes templates/ from the beginning of the variable name
	my $int=0;
	while (defined($templates[$int])) {
		$templates[$int]=~s/^templates\///;

		$int++;
	}

	return @templates;
}

=head2 readSet

This reads a specific set. If the set specified
is undef, the default set is read.

    #read the default set
    $zcrss->readSet();
    if($zcrss->{error}){
        print "Error!\n";
    }

    #read the set 'someSet'
    $zcrss->readSet('someSet');
    if($zcrss->{error}){
        print "Error!\n";
    }

=cut

sub readSet{
	my $self=$_[0];
	my $set=$_[1];
	my $function='readSet';
	
	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	$self->{zconf}->read({config=>'rss', set=>$set});
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}='ZConf error reading the config "rss".'.
			                 ' ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 setFeed

This adds a new feed or modifies a existing one.

One arguement is taken and it is a hash.

=head3 hash args

=head4 feed

This the feed to be added.

=head4 name

This is the name to use for it.

=head4 topTemplate

This is the name of the top template to use.

=head4 itemTemplate

This is the name of the template that will be used for each item.

=head4 bottomTemplate

This is the name of the bottom template to use.

    $zcrss->setFeed({
                    feed=>'http://foo.bar/rss.xml',
                    name=>'Foo Bar',
                    topTemplate=>'defaultTop',
                    itemTemplate=>'defaultItem',
                    bottomTemplate=>'defaultBottom',
                    });
    if($zrss->{error}){
        print "Error!\n";
    }

=cut

sub setFeed{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}
	my $function='setFeed';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	#required hash arguements
	my @required=('feed', 'name', 'topTemplate', 'itemTemplate',
				  'bottomTemplate');


	my $rint=0;
	#make sure everything is defined
	while (defined($required[$rint])) {
		if (!defined($required[$rint])) {
			$self->{error}=3;
			$self->{errorString}='%args is missing the key "'.
			                     $required[$rint].'"';
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return undef;	
		}
		$rint++;
	}

	if ($args{name} =~ /\//) {
		$self->{error}=4;
		$self->{errorString}='The feed name, "'.$args{name}.'", can\'t match /\//';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#adds each one
	$rint=0;
	while (defined($required[$rint])) {
		$self->{zconf}->setVar('rss', 'feeds/'.$args{name}.'/'.$required[$rint],
							   $args{$required[$rint]});
		if ($self->{zconf}->{error}) {
			$self->{error}=2;
			$self->{errorString}=" Setting variable for 'rss'.".
			                     "failed with '".$self->{zconf}->{error}."', '"
			                     .$self->{zconf}->{errorString}."'";
			#remove any that were added
			$self->{zconf}->regexVarDel('rss', '^feeds/'.$args{name}.'/');
			warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
			return undef;
		}

		$rint++;
	}

	$self->{zconf}->writeSetFromLoadedConfig({config=>'rss'});
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}=" writeSetFromLoadedConfig for 'rss'.".
		                     "failed with '".$self->{zconf}->{error}."', '"
		                     .$self->{zconf}->{errorString}."'";
		#remove any that were added
		$self->{zconf}->regexVarDel('rss', '^feeds/'.$args{name}.'/');
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 setTemplate

This sets a specified template to the given value.

    $zcrss->setTemplate($templateName, $template);
    if ($zcw->{error}) {
        print "Error!\n";
    }

=cut

sub setTemplate{
	my $self=$_[0];
	my $name=$_[1];
	my $template=$_[2];
	my $function='setTemplate';

	#blanks any previous errors
	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	#make sure a name for the template is specified
	if (!defined($name)) {
		$self->{error}=3;
		$self->{errorstring}='No template specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	#make sure a template is specified
	if (!defined($template)) {
		$self->{error}=3;
		$self->{errorstring}='No template specified';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	$self->{zconf}->setVar('rss', 'templates/'.$name, $template);
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}=' Error set the variable "templates/'.$name.'"'.
		                     'for "rss" ZConf error="'.$self->{zconf}->{error}.'" '.
			                 'ZConf error string="'.$self->{zconf}->{errorString}.'"';
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	$self->{zconf}->writeSetFromLoadedConfig({config=>'rss'});
	if ($self->{zconf}->{error}) {
		$self->{error}=2;
		$self->{errorString}=" writeSetFromLoadedConfig for 'rss'.".
		                     "failed with '".$self->{zconf}->{error}."', '"
		                     .$self->{zconf}->{errorString}."'";
		#remove any that were added
		$self->{zconf}->regexVarDel('rss', '^templates/'.$name.'/');
		warn($self->{module}.' '.$function.':'.$self->{error}.': '.$self->{errorString});
		return undef;
	}

	return 1;
}

=head2 templateExists

This makes sure a specified template exists.

    my $returned=$zcrss->templateExists('someTemplate');
    if($zcw->{error}){
        print "Error!\n";
    }else{
        if($returned){
            print "It exists.\n";
        }
    }

=cut

sub templateExists{
	my $self=$_[0];
	my $template=$_[1];
	my $function='templateExists';

	$self->errorblank;
	if ($self->{error}) {
		warn($self->{module}.' '.$function.': A permanent error is set');
	}

	my @templates=$self->listTemplates;
	if ($self->{error}) {
		warn('ZConf-RSS templateExists: listTemplates errored');
		return undef;
	}

	my $int=0;
	while (defined($templates[$int])) {
		if ($templates[$int] eq $template) {
			return 1;
		}
		
		$int++;
	}

	return undef;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
        my $self=$_[0];

		if ($self->{perror}) {
			return undef;
		}

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
}

=head1 TEMPLATE VARIABLES

The templating system used is 'Text::NeatTemplate'. The varialbes are as below.

=head2 CHANNEL

=head3 ctitle

This is the title for the channel.

=head3 cdesc

This is the description for the channel.

=head3 cpubdate

This is the publication date for the channel.

=head3 ccopyright

This is the copyright info for the channel.

=head3 clink

This is the link for the channel.

=head3 clang

This is the language for the channel.

=head3 cimage

This is the image for the channel.

=head2 ITEM

=head3 ititle

This is the title for a item.

=head3 idesc

This is the description for a item.

=head3 idescFTWL

This is the description for a item that has been
has been formated with 'HTML::FormatText::WithLinks'

=head3 ipubdate

This is the date published for a item.

=head3 icat

This is the category for a item.

=head3 iauthor

This is the author for a item.

=head3 iguid

This is the item's guid element.

=head3 ilink

This is the link for a item.

=head1 DEFAULT TEMPLATES

=head2 defaultTop

    Channel: {$ctitle}
    Date: {$cpubdate}
    Language: {$clang}
    Copywright: {$ccopyright}
    Link: {$clink}
    
    {$cdesc}

=head2 defaultItem


    --------------------------------------------------------------------------------
    Title: {$ititle}
    Date: {$ipubdate}
    Author: {$iauthor}
    Category: {$icat} 
    Link: {$ilink}
    
    {$idescFTWL}

=head2 defaultBottom

This one is blank by default.

=head1 ERROR CODES

=head2 1

Could not initialize ZConf.

=head2 2

ZConf error.

=head2 3

Missing required arguement.

=head2 4

Feed name can't match /\//.

=head2 5

Feed does not exist.

=head2 6

Feed not defined.

=head2 7

Failed to load feed.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-zconf-rss at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ZConf-RSS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ZConf::RSS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ZConf-RSS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/ZConf-RSS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/ZConf-RSS>

=item * Search CPAN

L<http://search.cpan.org/dist/ZConf-RSS>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of ZConf::RSS
