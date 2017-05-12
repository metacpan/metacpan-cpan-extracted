#
# WebFetch::Output::TWiki - save data into a TWiki web site
#
# Copyright (c) 2009 Ian Kluft. This program is free software; you can
# redistribute it and/or modify it under the terms of the GNU General Public
# License Version 3. See  http://www.webfetch.org/GPLv3.txt

package WebFetch::Output::TWiki;

use warnings;
use strict;
use WebFetch;
use base "WebFetch";
use DB_File;

# define exceptions/errors
use Exception::Class (
	"WebFetch::Output::TWiki::Exception::NoRoot" => {
		isa => "WebFetch::Exception",
		alias => "throw_twiki_no_root",
		description => "WebFetch::Output::TWiki needs to be provided "
			."a twiki_root parameter",
	},
	"WebFetch::Output::TWiki::Exception::NotFound" => {
		isa => "WebFetch::Exception",
		alias => "throw_twiki_not_found",
		description => "the directory in the twiki_root parameter "
			."doesn't exist or doesn't have a lib subdirectory",
	},
	"WebFetch::Output::TWiki::Exception::Require" => {
		isa => "WebFetch::Exception",
		alias => "throw_twiki_require",
		description => "failed to import TWiki or TWiki::Func modules",
	},
	"WebFetch::Output::TWiki::Exception::NoConfig" => {
		isa => "WebFetch::Exception",
		alias => "throw_twiki_no_config",
		description => "WebFetch::Output::TWiki needs to be provided "
			."a config_topic parameter",
	},
	"WebFetch::Output::TWiki::Exception::ConfigMissing" => {
		isa => "WebFetch::Exception",
		alias => "throw_twiki_config_missing",
		description => "WebFetch::Output::TWiki is missing a required "
			."configuration parameter",
	},
	"WebFetch::Output::TWiki::Exception::Oops" => {
		isa => "WebFetch::Exception",
		alias => "throw_twiki_oops",
		description => "WebFetch::Output::TWiki returned errors from "
			."saving one or more entries",
	},
	"WebFetch::Output::TWiki::Exception::FieldNotSpecified" => {
		isa => "WebFetch::Exception",
		alias => "throw_field_not_specified",
		description => "a required field was not defined or found",
	},
);

=head1 NAME

WebFetch::Output::TWiki - WebFetch output to TWiki web site

=cut

# globals/defaults
our @Options = ( "twiki_root=s", "config_topic=s", "config_key=s" );
our $Usage = "--twiki_root path-to-twiki --config_topic web.topic "
	."--config_key keyword";
our @default_field_names = ( qw( key web parent prefix template form
	options ));

# no user-servicable parts beyond this point

# register capabilities with WebFetch
__PACKAGE__->module_register( "cmdline", "output:twiki" );

=head1 SYNOPSIS

This is an output module for WebFetch which places the data in pages
on a TWiki web site.  Some of its configuration information is read from
a TWiki page.  Calling or command-line parameters point to the TWiki page
which has the configuration and a search key to locate the correct line
in a table.

From the command line...

    perl -w -I$libdir -MWebFetch::Input::Atom -MWebFetch::Output::TWiki -e "&fetch_main" -- --dir "/path/to/fetch/worskspace" --source "http://search.twitter.com/search.atom?q=%23twiki" --dest=twiki --twiki_root=/var/www/twiki --config_topic=Feeds.WebFetchConfig --config_key=twiki

From Perl code...

    use WebFetch;

    my $obj = WebFetch->new(
        "dir" => "/path/to/fetch/workspace",
	"source" => "http://search.twitter.com/search.atom?q=%23twiki",
	"source_format" => "atom",
	"dest" => "twiki",
	"dest_format" = "twiki",
	"twiki_root" => "/var/www/twiki",
	"config_topic" => "Feeds.WebFetchConfig",
	"config_key" => "twiki",
    );
    $obj->do_actions; # process output
    $obj->save; # save results

=head1 configuration from TWiki topic

The configuration information on feeds is kept in a TWiki page.  You can
specify any page with a web and topic name, for example C<--config_topic=Feeds.WebFetchConfig> .

The contents of that configuration page could look like this, though with
any feeds you want to configure.  The "Key" field matches the --config_key
command-line parameter, and then brings in the rest of the configuration
info from that line.  An example is shown below.

=over
C<< ---+ !WebFetch Configuration >>

C<< The following table is used by !WebFetch to configure news feeds >>

C<< %STARTINCLUDE% >>
C<< | *Key* | *Web* | *Parent* | *Prefix* | *Template* | *Form* | *Options* | *Modul >>
e* | *Source* |
C<< | ikluft-twitter | Feeds | TwitterIkluftFeed | TwitterIkluft | AtomFeedTemplate | AtomFeedForm | separate_topics | Atom | http://twitter.com/statuses/user_timeline/37786023.rss | >>
C<< | twiki-twitter | Feeds | TwitterTwikiFeed | TwitterTwiki | AtomFeedTemplate | AtomFeedForm | separate_topics | Atom | http://search.twitter.com/search.atom?q=%23twiki | >>
C<< | cnn | Feeds | RssCnn | RssCnn | RssFeedTemplate | RssFeedForm | separate_topics | RSS | http://rss.cnn.com/rss/cnn_topstories.rss | >>
C<< %STOPINCLUDE% >>
=back

The C<%STARTINCLUDE%> and C<%STOPINCLUDE%> are not required.  However, if
present, they are used as boundaries for the inclusion like in a normal
INCLUDE operation on TWiki.

=cut

# read the TWiki configuation
sub get_twiki_config
{
	my $self = shift;
	WebFetch::debug "in get_twiki_config";

	# find the TWiki modules
	if ( ! exists $self->{twiki_root}) {
		throw_twiki_no_root( "TWiki root directory not defined" );
	}
	if (( ! -d $self->{twiki_root}) or ( ! -d $self->{twiki_root}."/lib" ))
	{
		throw_twiki_not_found( "can't find TWiki root or lib at "
			.$self->{twiki_root});
	}

	# load the TWiki modules
	WebFetch::debug "loading TWiki modules";
	push @INC, $self->{twiki_root}."/lib";
	eval { require TWiki; require TWiki::Func; };
	if ( $@ ) {
		throw_twiki_require ( $@ );
	}

	# initiate TWiki library, create session as user "WebFetch"
	$self->{twiki_obj} = TWiki->new( "WebFetch" );

	# get the contents of the TWiki topic which contains our configuration 
	if ( !exists $self->{config_topic}) {
		throw_twiki_no_config( "TWiki configuration page for WebFetch "
			."not defined" );
	}
	my ( $web, $topic ) = split /\./, $self->{config_topic};
	WebFetch::debug "config_topic: ".$self->{config_topic}
		." -> $web, $topic";
	if (( ! defined $web ) or ( ! defined $topic )) {
		throw_twiki_no_config( "TWiki configuration page for WebFetch "
			."must be defined in the format web.topic" );
	}

	# check if a config_key was specified before we read the configuration
	if ( !exists $self->{config_key}) {
		throw_twiki_no_config( "TWiki configuration key for WebFetch "
			."not defined" );
	}

	# read the configuration info
	my $config = TWiki::Func::readTopic( $web, $topic );

	# if STARTINCLUDE and STOPINCLUDE are present, use only what's between
	if ( $config =~ /%STARTINCLUDE%\s*(.*)\s*%STOPINCLUDE%/s ) {
		$config = $1;
	}

	# parse the configuration
	WebFetch::debug "parsing configuration";
	my ( @fnames, $line );
	$self->{twiki_config_all} = [];
	$self->{twiki_keys} = {};
	foreach $line ( split /\r*\n+/s, $config ) {
		if ( $line =~ /^\|\s*(.*)\s*\|\s*$/ ) {
			my @entries = split /\s*\|\s*/, $1;
			WebFetch::debug "read entries: ".join( ', ', @entries );

			# first line contains field headings
			if ( ! @fnames) {
				# save table headings as field names
				my $field;
				foreach $field ( @entries ) {
					my $tmp = lc($field);
					$tmp =~ s/\W//g;
					push @fnames, $tmp;
				}
				next;
			}
			WebFetch::debug "field names: ".join " ", @fnames;

			# save the entries
			# it isn't a heading row if we got here
			# transfer array @entries to named fields in %config
			WebFetch::debug "data row: ".join " ", @entries;
			my ( $i, $key, %config );
			for ( $i=0; $i < scalar @fnames; $i++ ) {
				$config{ $fnames[$i]} = $entries[$i];
				if ( $fnames[$i] eq "key" ) {
					$key = $entries[$i];
				}
			}

			# save the %config row in @{$self->{twiki_config_all}}
			if (( defined $key )
				and ( !exists $self->{twiki_keys}{$key}))
			{
				push @{$self->{twiki_config_all}}, \%config;
				$self->{twiki_keys}{$key} = ( scalar
					@{$self->{twiki_config_all}}) - 1;
			}
		}
	}

	# select the line which is for this request
	if ( ! exists $self->{twiki_keys}{$self->{config_key}}) {
		throw_twiki_no_config "no configuration found for key "
			.$self->{config_key};
	}
	$self->{twiki_config} = $self->{twiki_config_all}[$self->{twiki_keys}{$self->{config_key}}];
	WebFetch::debug "twiki_config: ".join( " ", %{$self->{twiki_config}});
}

# write to a TWiki page
sub write_to_twiki
{
	my $self = shift;
	my ( $config, $name );

	# get config variables
	$config = $self->{twiki_config};

	# parse options
	my ( $option );
	$self->{twiki_options} = {};
	foreach $option ( split /\s+/, $self->{twiki_config}{options}) {
		if ( $option =~ /^([^=]+)=(.*)/ ) {
			$self->{twiki_options}{$1} = $2;
		} else {
			$self->{twiki_options}{$option} = 1;
		}
	}

	# determine unique identifier field
	my $id_field;
	if ( exists $self->{twiki_options}{id_field}) {
		$id_field = $self->{twiki_options}{id_field};
	}
	if ( ! defined $id_field ) {
		$id_field = $self->wk2fname( "id" );
	}
	if ( ! defined $id_field ) {
		$id_field = $self->wk2fname( "url" );
	}
	if ( ! defined $id_field ) {
		$id_field = $self->wk2fname( "title" );
	}
	if ( ! defined $id_field ) {
		throw_field_not_specified "identifier field not specified";
	}
	$self->{id_field} = $id_field;

	# determine from options whether each item is making metadata or topics
	if ( exists $self->{twiki_options}{separate_topics}) {
		$self->write_to_twiki_topics;
	} else {
		$self->write_to_twiki_metadata;
	}
}

# write to separate TWiki topics
sub write_to_twiki_topics
{
	my $self = shift;

	# get config variables
	my $config = $self->{twiki_config};
	my $name;
	foreach $name ( qw( key web parent prefix template form )) {
		if ( !exists $self->{twiki_config}{$name}) {
			throw_twiki_config_missing( "missing config parameter "
				.$name );
		}
	}

	# get text of template topic
	my ($meta, $template ) = TWiki::Func::readTopic( $config->{web},
		$config->{template});

	# open DB file for tracking unique IDs of articles already processed
	my %id_index;
	tie %id_index, 'DB_File',
		$self->{dir}."/".$config->{key}."_id_index.db",
		&DB_File::O_CREAT|&DB_File::O_RDWR, 0640;

	# determine initial topic name
	my ( %topics, @topics );
	@topics = TWiki::Func::getTopicList( $config->{web});
	foreach ( @topics ) {
		$topics{$_} = 1;
	}
	my $tnum_counter = 0;
	my $tnum_format = $config->{prefix}."-%07d";

	# create topics with metadata from each WebFetch data record
	my $entry;
	my @oopses;
	my $id_field = $self->{id_field};
	$self->data->reset_pos;
	while ( $entry = $self->data->next_record ) {

		# check that this entry hasn't already been forwarded to TWiki
		if ( exists $id_index{$entry->byname( $id_field )}) {
			next;
		}
		$id_index{$entry->byname( $id_field )} = time;

		# select topic name
		my $topicname = sprintf $tnum_format, $tnum_counter;
		while ( exists $topics{$topicname}) {
			$tnum_counter++;
			$topicname = sprintf $tnum_format, $tnum_counter;
		}
		$tnum_counter++;
		$topics{$topicname} = 1;
		my $text = $template;
		WebFetch::debug "write_to_twiki_topics: writing $topicname";

		# create topic metadata
		#my $meta = TWiki::Meta->new ( $self->{twiki_obj}, $config->{web}, $topicname );
		$meta->put( "TOPICPARENT",
			{ name => $config->{parent}});
		$meta->put( "FORM", { name => $config->{form}});
		my $fnum;
		for ( $fnum = 0; $fnum <= $self->data->num_fields; $fnum++ ) {
			WebFetch::debug "meta: "
				.$self->data->field_bynum($fnum)
				." = ".$entry->bynum($fnum);
			( defined $self->data->field_bynum($fnum)) or next;
			( $self->data->field_bynum($fnum) eq "xml") and next;
			( defined $entry->bynum($fnum)) or next;
			WebFetch::debug "meta: OK";
			$meta->putKeyed( "FIELD", {
				name => $self->data->field_bynum($fnum),
				value => $entry->bynum($fnum)});
		}

		# save a special title field for TWiki indexes
		my $index_title = $entry->title;
		$index_title =~ s/[\t\r\n\|]+/ /gs;
		$index_title =~ s/^\s*//;
		$index_title =~ s/\s*$//;
		if ( length($index_title) > 60 ) {
			substr( $index_title, 56 ) = "...";
		}
		WebFetch::debug "title: $index_title";
		$meta->putKeyed( "FIELD", {
			name => "IndexTitle",
			title => "Indexing title",
			value => $index_title });

		# save the topic
		my $oopsurl = TWiki::Func::saveTopic( $config->{web},
			$topicname, $meta, $text );
		if ( $oopsurl ) {
			WebFetch::debug "write_to_twiki_topics: "
				."$topicname - $oopsurl";
			push @oopses, $entry->title." -> "
				.$topicname." ".$oopsurl;
		}
	}

	# check for errors
	if ( @oopses ) {
		throw_twiki_oops( "TWiki saves failed:\n".join "\n", @oopses );
	}
}

# write to successive items of TWiki metadata
sub write_to_twiki_metadata
{
	my $self = shift;

	# get config variables
	my $config = $self->{twiki_config};
	my $name;
	foreach $name ( qw( key web parent )) {
		if ( !exists $self->{twiki_config}{$name}) {
			throw_twiki_config_missing( "missing config parameter "
				.$name );
		}
	}

	# determine metadata title field
	my $title_field;
	if ( exists $self->{twiki_options}{title_field}) {
		$title_field = $self->{twiki_options}{title_field};
	}
	if ( ! defined $title_field ) {
		$title_field = $self->wk2fname( "title" );
	}
	if ( ! defined $title_field ) {
		throw_field_not_specified "title field not specified";
	}

	# determine metadata value field
	my $value_field;
	if ( exists $self->{twiki_options}{value_field}) {
		$value_field = $self->{twiki_options}{value_field};
	}
	if ( ! defined $value_field ) {
		$value_field = $self->wk2fname( "summary" );
	}
	if ( ! defined $value_field ) {
		throw_field_not_specified "value field not specified";
	}

	# open DB file for tracking unique IDs of articles already processed
	my %id_index;
	tie %id_index, 'DB_File',
		$self->{dir}."/".$config->{key}."_id_index.db",
		&DB_File::O_CREAT|&DB_File::O_RDWR, 0640;

	# get text of topic
	my ($meta, $text) = TWiki::Func::readTopic( $config->{web},
		$config->{parent});
	
	# start metadata line counter
	my $mnum_counter = 0;
	my $mnum_format = "line-%07d";

	# create metadata lines for each entry
	my $entry;
	my @oopses;
	my $id_field = $self->{id_field};
	$self->data->reset_pos;
	while ( $entry = $self->data->next_record ) {
		# check that this entry hasn't already been forwarded to TWiki
		if ( exists $id_index{$entry->byname( $id_field )}) {
			next;
		}
		$id_index{$entry->byname( $id_field )} = time;

		# select metadata field name
		my ( $value, $metaname );
		$value = $meta->get( "FIELD",
			$metaname = sprintf( $mnum_format, $mnum_counter ));
		while ( defined $value ) {
			$value = $meta->get( "FIELD",
				$metaname = sprintf( $mnum_format,
					++$mnum_counter ));
		}

		# write the value
		$meta->putKeyed( "FIELD", {
			name => $metaname,
			title => $entry->byname( $title_field ),
			value => $entry->byname( $value_field ),
			});
	}

	# save the topic
	my $oopsurl = TWiki::Func::saveTopic( $config->{web},
		$config->{parent}, $meta, $text );
	if ( $oopsurl ) {
		throw_twiki_oops "TWiki saves failed: "
			.$config->{parent}." ".$oopsurl;
	}
}

# TWiki format handler
sub fmt_handler_twiki
{
        my $self = shift;
        my $filename = shift;

	# get configuration from TWiki
	$self->get_twiki_config;

	# write to TWiki topic
	$self->write_to_twiki;

	# no savables - mark it OK so WebFetch::save won't call it an error
	$self->no_savables_ok;
        1;
}

=head1 TWiki software

TWiki is a wiki (user-editable web site) with features enabling
collaboration in an enterprise environment.
It implements the concept of a "structured wiki", allowing structure
and automation as needed and retaining the informality of a wiki.
Automated input/updates such as from WebFetch::Output::TWiki is one example.

See http://twiki.org/ for the Open Source community-maintained software
or http://twiki.net/ for enterprise support.

WebFetch::Output::TWiki was developed for TWiki Inc (formerly TWiki.Net).

=head1 AUTHOR

WebFetch was written by Ian Kluft
Send patches, bug reports, suggestions and questions to
C<maint@webfetch.org>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-webfetch-output-twiki at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebFetch-Output-TWiki>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

=for html
<a href="WebFetch.html">WebFetch</a>

=for text
WebFetch

=for man
WebFetch

=cut

1; # End of WebFetch::Output::TWiki
