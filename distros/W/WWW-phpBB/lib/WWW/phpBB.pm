package WWW::phpBB;

use strict;
use warnings;
no warnings qw(uninitialized);
use WWW::Mechanize;
use Compress::Zlib;
use HTML::TokeParser::Simple;
use Time::Local;
use DBI();
use Carp;
use POSIX ":sys_wait_h";
use Encode;
use HTML::Entities;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ();
our @EXPORT_OK = ();
our @EXPORT = qw();
our $VERSION = '0.09';
my $children; # number of spawned processes

# defaults
my %default = (
    db_compression => 0,
    max_rows => 60,
    months => [qw(jan feb mar apr may jun jul aug sep oct nov dec)],
    post_date_format => qr/(\w+)\s+(\d+),\s+(\d+)\s+(\d+):(\d+)\s+(\w\w)/i,
    post_date_pos => [qw(month_name day_of_month year hour minutes am_pm)],
    reg_date_format => qr/(\d+)\s+(\w+)\s+(\d+)/i,
    reg_date_pos => [qw(day_of_month month_name year)],
    forum_link_regex => qr/f=(\d+)/,
    topic_link_regex_p => qr/viewtopic.*p=(\d+)/,
    topic_link_regex_t => qr/viewtopic.*t=(\d+)/,
    topic_link1 => "viewtopic.php",
    topic_link2 => "t=%d&postorder=asc",
    alternative_page_number_regex_forum => qr//,
    alternative_page_number_regex_topic => qr//,
    quote_string => "wrote",
    max_tries => 50,
    db_empty => [qw(users categories forums topics posts posts_text vote_desc vote_results groups user_group)],
    bbcode_uid => '48d712e388',
    db_insert => 1,
    update_overwrite => 0,
    verbose => 0,
    profile_info => 1,
    profile_string_occupation => "occupation",
    profile_string_msn => "msn messenger",
    max_children => 1,
    smiles => {
	icon_biggrin => ':D',
	icon_smile => ':)',
	icon_sad => ':(',
	icon_surprised => ':o',
	icon_eek => ':shock:',
	icon_confused => ':?',
	icon_cool => '8)',
	icon_lol => ':lol:',
	icon_mad => ':x',
	icon_razz => ':P',
	icon_redface => ':oops:',
	icon_cry => ':cry:',
	icon_evil => ':evil:',
	icon_twisted => ':twisted:',
	icon_rolleyes => ':roll:',
	icon_wink => ':wink:',
	icon_exclaim => ':!:',
	icon_question => ':?:',
	icon_idea => ':idea:',
	icon_arrow => ':arrow:',
	icon_neutral => ':|',
	icon_mrgreen => ':mrgreen:',
    },
);
# mysql tables as arrays of hashes
for (qw(categories forums topics users posts posts_text vote_desc vote_results groups user_group)) {
    $default{$_} = [];
}


package WWW::phpBB;

##################
# main functions #
##################

our %ok_field; # for accessors

for (qw(
    base_url
    db_host
    db_user
    db_passwd
    db_database
    db_prefix
    forum_user
    forum_passwd
    db_compression
    max_rows
    months
    post_date_format
    post_date_pos
    reg_date_format
    reg_date_pos
    forum_link_regex
    topic_link_regex_p
    topic_link_regex_t
    topic_link1
    topic_link2
    alternative_page_number_regex_forum
    alternative_page_number_regex_topic
    quote_string
    max_tries
    db_empty
    db_insert
    max_children
    verbose
    profile_info
)) { $ok_field{$_}++ };

sub AUTOLOAD {
    my $self = shift;
    my $attr = our $AUTOLOAD;
    $attr =~ s/.*:://;
    return unless $attr =~ /[^A-Z]/;
    croak "invalid attribute method: ->$attr( )" unless $ok_field{$attr};
    $self->$attr = shift if @_;
    $self->$attr;
}

sub new {
    my $self = {};
    bless($self, shift);
    if (@_) {
	my %args = @_;
	@$self{keys %args} = values %args;
    }

    # defaults
    while (my ($key, $value) = each %default) {
	$self->{$key} = $value unless exists $self->{$key};
    }

    # croak if the mandatory arguments are missing
    for (qw(base_url db_host db_user db_passwd db_database db_prefix)) {
	croak "you must specify a $_" unless exists $self->{$_};
    }

    # init
    $self->{mmech} = WWW::Mechanize->new(stack_depth => 1);
    $self->{mmech}->agent_alias('Linux Mozilla');
    #$self->{mmech}->add_header('Accept-Encoding' => 'gzip; deflate');
    for (1..$self->{max_tries}) {
	$self->{mmech}->get($self->{base_url});
	last if $self->{mmech}->success && $self->{mmech}->status == 200;
	print "Error fetching the start page (try $_ out of $self->{max_tries})\n";
    }
    croak "gave up...\n" unless $self->{mmech}->success && $self->{mmech}->status == 200;

    $self->{dbh} = DBI->connect("DBI:mysql:database=$self->{db_database};host=$self->{db_host};mysql_compression=$self->{db_compression}",
	$self->{db_user}, $self->{db_passwd}, {AutoCommit => 1, RaiseError => 1});
    unless ($self->{update_overwrite}) {
	$self->{dbh}->do("CREATE TABLE IF NOT EXISTS $self->{db_prefix}" . "topics_trans "
	    . "(new mediumint(8) unsigned NOT NULL,"
	    . "orig mediumint(8) unsigned NOT NULL,"
	    . "PRIMARY KEY (new) )");
	$self->{dbh}->do("CREATE TABLE IF NOT EXISTS $self->{db_prefix}" . "posts_trans "
	    . "LIKE $self->{db_prefix}" . "topics_trans");
    }

    $self;
}

sub forum_login_raw {
    my $self = shift;
    if (!exists $self->{forum_user} || !exists $self->{forum_passwd}) {
    	print "can't login without a forum_user and forum_passwd\n";
	return;
    }
    if ($self->{verbose}) {
    	print "logging in...";
    }
    for (1..$self->{max_tries}) {
	#$self->{mmech}->form_number(1);
	$self->{mmech}->field('username', $self->{forum_user});
	$self->{mmech}->field('password', $self->{forum_passwd});
	$self->{mmech}->click();
	if ($self->{mmech}->success && $self->{mmech}->status == 200) {
      	    if ($self->{verbose}) {
	  	print "\n";
            }
	    last;
	}
	print "Error logging in (try $_ out of $self->{max_tries})\n";
    }
    croak "gave up...\n" unless $self->{mmech}->success && $self->{mmech}->status == 200;
}

# wrapper for forum_login_raw() that retries in case of errors
sub forum_login {
    my $self = shift;
    for (1..$self->{max_tries}) {
        eval {
            $self->forum_login_raw(@_);
            1;
        } and last;
	    print "failed (try $_ out of $self->{max_tries})\n";
        sleep(1)
    }
}

sub forum_logout_raw {
    my $self = shift;
    return unless exists $self->{forum_user} && exists $self->{forum_passwd};
    if ($self->{verbose}) {
    	print "logging out...";
    }
    for (1..$self->{max_tries}) {
	$self->{mmech}->follow_link(url_regex => qr/logout/);
	if ($self->{mmech}->success && $self->{mmech}->status == 200) {
      	    if ($self->{verbose}) {
	  	print "\n";
            }
	    last
	}
	print "Error logging out (try $_ out of $self->{max_tries})\n";
    }
    croak "gave up...\n" unless $self->{mmech}->success && $self->{mmech}->status == 200;
    # reset the base_uri
    $self->{mmech}->get($self->{base_url})
}

# wrapper for forum_logout_raw() that retries in case of errors
sub forum_logout {
    my $self = shift;
    for (1..$self->{max_tries}) {
        eval {
            $self->forum_logout_raw(@_);
            1;
        } and last;
	    print "failed (try $_ out of $self->{max_tries})\n";
        sleep(1)
    }
}

sub get_categories_and_forums {
    my $self = shift;
    my $parse;
    $parse = HTML::TokeParser::Simple->new( \$self->{mmech}->content );
    $parse->unbroken_text( 1 );
    my $token;
    my $cat_order;
    my $rows;
    my $frows;

    while ($token = $parse->get_token) {
	next unless $token->get_attr('class') eq 'catLeft';
	my %row;
	my $cat_id;
	# cat_id
	$token = $parse->get_token until $token->is_start_tag('a') || $token == 0;
	$token->get_attr('href') =~ /c=(\d+)/;
	$row{cat_id} = $cat_id = $1;
	# cat_title
	$token = $parse->get_token until $token->is_text && $token->as_is =~ /\S/;
	$row{cat_title} = $token->as_is;
	# cat_order
	$cat_order += 10;
	$row{cat_order} = $cat_order;
	# store
	push @{$self->{categories}}, \%row;

	# get the forums
	my $forum_order;
	while ($token = $parse->get_token) {
	    last if $parse->peek =~ /catLeft/;
	    next unless $token->is_start_tag('a') && $token->get_attr('class') eq 'forumlink';
	    my %row;
	    # auth
	    $row{auth_post} = 1;
	    $row{auth_reply} = 1;
	    $row{auth_edit} = 1;
	    $row{auth_delete} = 1;
	    $row{auth_vote} = 1;
	    $row{auth_pollcreate} = 1;
	    $row{auth_sticky} = $row{auth_announce} = $row{auth_attachments} = 3;
	    # forum_id
	    $token->get_attr('href') =~ $self->{forum_link_regex};
	    $row{forum_id} = $1;
	    # cat_id
	    $row{cat_id} = $cat_id;
	    # forum_name
	    $token = $parse->get_token until $token->is_text && $token->as_is =~ /\S/;
	    $row{forum_name} = $token->as_is;
	    # forum_desc
	    $token = $parse->get_token;
	    $token = $parse->get_token until $token->is_text && $token->as_is =~ /\S/
	      || $token->is_end_tag('td');
	    $row{forum_desc} = $token->as_is if $token->is_text;
	    $row{forum_desc} =~ s/&nbsp;//g;
	    # forum_topics
	    $token = $parse->get_token until $token->is_start_tag('td');
	    $token = $parse->get_token until $token->is_text && $token->as_is =~ /\S/;
	    $row{forum_topics} = $token->as_is;
	    # forum_posts
	    $token = $parse->get_token until $token->is_start_tag('td');
	    $token = $parse->get_token until $token->is_text && $token->as_is =~ /\S/;
	    $row{forum_posts} = $token->as_is;
	    # forum_last_post_id
	    $token = $parse->get_token until $token->is_start_tag('a')
	      && $token->get_attr('href') =~ $self->{topic_link_regex_p}
	      || $token->is_end_tag('tr');
	    $row{forum_last_post_id} = $1 if $token->is_start_tag('a');
	    # forum_order
	    $forum_order += 10;
	    $row{forum_order} = $forum_order;
	    # store
	    push @{$self->{forums}}, \%row;
	}
    }
    if ($self->{db_insert}) {
	$self->insert_array($self->{categories}, "categories");
	$self->insert_array($self->{forums}, "forums");
    }
}

# $_[0]=$forum_id, $_[1]=$page_number
sub get_topics {
    my $self = shift;
    my ($forum_id, $page_number) = @_;
    my $success;
    my $rows;
    # make a copy of the $mech object
    my $mech = {%{$self->{mmech}}};
    bless $mech, "WWW::Mechanize";
    my $url = $self->compute_url("viewforum.php", "f=$forum_id");
    for (1..$self->{max_tries}) {
        eval {
	    $mech->get($url);
	    1;
	} or next;
	last if $mech->success && $mech->status == 200;
	print "Failed to enter forum_id $forum_id (try $_ out of $self->{max_tries})\n";
    }
    return unless $mech->success && $mech->status == 200;
    # cycle through pages
    my $pages = $self->number_of_pages($mech, 'forum');
    # get just one page ?
    if (defined $page_number) {
	if (-@$pages <= $page_number && $page_number < @$pages) {
	    $pages = [ $$pages[$page_number] ];
	} else { return }
    }
    #print " pages: ", join(", ", @$pages);
    for ( @$pages ) {
	my $url = $mech->uri;
	$url = $self->forum_url_for_page($url, $forum_id, $_);
	#print $url, "\n";
	for (1..$self->{max_tries}) {
	    eval {
		$mech->get($url);
		1;
	    } or next;
	    last if $mech->success && $mech->status == 200;
	    print "Failed to enter a page of forum_id $forum_id (try $_ out of $self->{max_tries})\n";
	}
	next unless $mech->success && $mech->status == 200;
	# extract topic info
	my $parse;
	$parse = HTML::TokeParser::Simple->new( \$mech->content );
	$parse->unbroken_text( 1 );
	my $token;
	$token = $parse->get_token;
	$token = $parse->get_token until (!defined $token || $token->get_attr('class') eq 'forumline');
	$token = $parse->get_token until $token->is_end_tag('tr');
	while ($token = $parse->get_token) {
	    last if $token->is_end_tag('table');
	    next unless $token->is_start_tag('tr');
	    $token = $parse->get_token until $token->is_start_tag('td');
	    last unless $token->get_attr('class') =~ /row/;
	    my %row;
	    # forum_id
	    $row{forum_id} = $forum_id;
	    # topic_type
	    $token = $parse->get_token until $token->is_start_tag('img')
	      || $token->is_end_tag('td');
	    last if $token->is_end_tag('td');
	    $row{topic_type} = 1 if $token->get_attr('src') =~ /sticky/;
	    $row{topic_type} = 2 if $token->get_attr('src') =~ /announce/;
	    # topic_id
	    $token = $parse->get_token until $token->is_start_tag('a')
	      && $token->get_attr('href') =~ $self->{topic_link_regex_t};
	    $row{topic_id} = $1;
	    # topic_title
	    $token = $parse->get_token until $token->is_text
	      && $token->as_is =~ /\S/;
	    $row{topic_title} = $token->as_is;
	    # topic_replies
	    $token = $parse->get_token until $token->is_start_tag('td');
	    $token = $parse->get_token until $token->is_text
	      && $token->as_is =~ /^(\d+)$/;
	    $row{topic_replies} = $1;
	    # topic_poster
	    $token = $parse->get_token until $token->is_start_tag('td');
	    while ($token = $parse->get_token) {
		last if $token->is_end_tag('td');
		if ($token->is_start_tag('a')) {
		    $row{topic_poster} = $1
		      if $token->is_start_tag('a')
		      && $token->get_attr('href') =~ /viewprofile.*u=(\d+)/;
		    last;
		}
		if ( ! exists $row{topic_poster}
		    && $token->is_text
		    && $token->as_is =~ /\S/ ) {
			my $username = $token->as_is;
			for (@{$self->{users}}) {
			    if ($_->{username} eq $username) {
				$row{topic_poster} = $_->{user_id};
				last;
			    }
			}
		    }
	    }
	    $row{topic_poster} = -1 unless exists $row{topic_poster};
	    # topic_views
	    $token = $parse->get_token until $token->is_start_tag('td');
	    $token = $parse->get_token until (!defined $token || ($token->is_text && $token->as_is =~ /^(\d+)$/));
	    $row{topic_views} = $1;
	    # topic_last_post_id
	    $token = $parse->get_token until $token->is_start_tag('a')
	      && $token->get_attr('href') =~ $self->{topic_link_regex_p};
	    $row{topic_last_post_id} = $1;

	    # manage the same topic appearing on more pages (like announcements)
	    my $unique = 1;
	    for (@{$self->{topics}}) {
		if ( $_->{topic_id} == $row{topic_id} ) {
		    $unique = 0;
		    last;
		}
	    }
	    # check also the db to see if it's the shadow of a moved topic
	    if ($unique && ! defined $page_number) {
		my $sth = $self->{dbh}->prepare("SELECT topic_id FROM $self->{db_prefix}"
		    . "topics WHERE topic_id=$row{topic_id}" );
		$sth->execute;
		if ($sth->fetch) {
		    $unique = 0;
		}
	    }

	    push @{$self->{topics}}, \%row if $unique;
	}
    }
}

# $_[0]=$page_number
sub get_users_raw {
    my $self = shift;
    if ($self->{verbose}) {
    	print "getting users...\n";
    }
    my ($page_number) = @_;
    my $success;
    my $rows;

    $self->get_new_admin();
    # make a copy of the $mech object
    my $mech = {%{$self->{mmech}}};
    bless $mech, "WWW::Mechanize";
    my $url = $self->compute_url("memberlist.php", "");
    for (1..$self->{max_tries}) {
	$mech->get($url);
	last if $mech->success && $mech->status == 200;
	print "Failed to enter memberlist (try $_ out of $self->{max_tries})\n";
    }
    return unless $mech->success && $mech->status == 200;
    # cycle through pages
    my $pages = $self->number_of_pages($mech);
    # get just one page ?
    if (defined $page_number) {
	if (-@$pages <= $page_number && $page_number < @$pages) {
	    $pages = [ $$pages[$page_number] ];
	} else { return }
    }
    for ( @$pages ) {
	my $url = $mech->uri;
	$url =~ s/&$//;
	$url = $self->memberlist_url_for_page($url, $_);

	for (1..$self->{max_tries}) {
	    $mech->get($url);
	    last if $mech->success && $mech->status == 200;
	    print "Failed to enter a page of the memberlist (try $_ out of $self->{max_tries})\n";
	}
	next unless $mech->success && $mech->status == 200;
	# extract memberlist info
	my $parse;
	$parse = HTML::TokeParser::Simple->new( \$mech->content );
	$parse->unbroken_text( 1 );
	my $token;
	$token = $parse->get_token;
	$token = $parse->get_token until $token->is_start_tag('table')
	  && $token->get_attr('class') eq 'forumline';
	$token = $parse->get_token until $token->is_end_tag('tr');
	while ($token = $parse->get_token) {
	    #print "|>", $parse->peek(7), "<|\n";
	    next unless $token->is_start_tag('tr');
	    $token = $parse->get_token until $token->is_start_tag('td');
	    my %row;
	    # various default fields
	    $row{user_sig_bbcode_uid} = $self->{bbcode_uid};
	    $row{user_style} = 1;
	    $row{user_lang} = 'english';
	    $row{user_viewemail} = 0;
	    $row{user_attachsig} = 1;
	    $row{user_allowhtml} = 0;
	    $row{user_notify} = 0;
	    $row{user_notify_pm} = 1;
	    $row{user_popup_pm} = 1;
	    # user_id
	    $token = $parse->get_token until !defined $token || ($token->is_start_tag('a') && $token->get_attr('href') =~ /viewprofile.*u=(\d+)(\D|$)/);
	    last if !defined $token;
	    $row{user_id} = $1;
	    # username
	    $token = $parse->get_token until $token->is_text
	      && $token->as_is =~ /\S/;
	    $row{username} = $token->as_is;
        die "the destination forum's admin has the same username as one user from the scraped forum ($row{username})! aborting...\n" if $row{username} eq $self->{new_admin_username};
	    #print $row{username}, "\n";
	    # user_email
	    $token = $parse->get_token until $token->is_start_tag('td');
	    while ($token = $parse->get_token) {
		last if $token->is_end_tag('td');
		if ($token->is_start_tag('a') && $token->as_is =~ /mailto:([^"]+)\"/) {
		    $row{user_email} = $1;
		}
	    }
	    # user_from
	    $token = $parse->get_token until $token->is_start_tag('td');
	    my $td_count = 0;
	    while ($token = $parse->get_token) {
		$td_count++ if $token->is_start_tag('td');
		$td_count-- if $token->is_end_tag('td');
		last if $td_count < 0;
		if ($token->is_text
		    && $token->as_is !~ /^(&nbsp;)+$/
		    && $token->as_is =~ /\S/) {
			$row{user_from} = $token->as_is;
		    }
	    }
	    # user_regdate
	    $token = $parse->get_token until $token->is_text
	      && $token->as_is =~ /\S/;
	    #print $token->as_is(), "\n";
	    $row{user_regdate} = $self->parse_date($token->as_is, $self->{reg_date_format},
		$self->{reg_date_pos});
	    # user_posts
	    $token = $parse->get_token until $token->is_text
	      && $token->as_is =~ /^(\d+)$/;
	    $row{user_posts} = $1;
	    # user_website
	    while ($token = $parse->get_token) {
		last if $token->is_end_tag('tr');
		if ($token->is_start_tag('a')
		    && $token->get_attr('target') eq "_userwww") {
			$row{user_website} = $token->get_attr('href');
		    }
	    }
	    #while( my ($k, $v) = each %row ) {
	     #print "$k : $v\n";
	    #}
	    #print "\n";

	    if($self->{profile_info}) {
            # get profile info
            if ($self->{verbose}) {
                print "getting the profile info for '$row{username}'\n";
            }
            # make a copy of the $mech object in order to get the profile page
            my $p_mech = {%{$mech}};
            bless $p_mech, "WWW::Mechanize";
            my $urlp = $self->compute_url("profile.php", "mode=viewprofile&u=$row{user_id}");
            for (1..$self->{max_tries}) {
                $p_mech->get($urlp);
                last if $p_mech->success && $p_mech->status == 200;
                print "Failed to enter profile (try $_ out of $self->{max_tries})\n";
            }
            next unless $p_mech->success && $p_mech->status == 200;
            my $p_parse;
            $p_parse = HTML::TokeParser::Simple->new( \$p_mech->content );
            $p_parse->unbroken_text( 1 );
            my $p_token;
            $p_token = $p_parse->get_token;
            $p_token = $p_parse->get_token until $p_token->get_attr('class')
              eq 'forumline';
            $p_token = $p_parse->get_token until $p_token->get_attr('class')
              =~ /row/ && $p_token->is_start_tag('td');
            # user_avatar
            while ($p_token = $p_parse->get_token) {
                last if $p_token->is_end_tag('td');
                if ($p_token->is_tag('img')) {
                    $row{user_avatar} = $p_token->get_attr('src');
                    (my $b_url = $p_mech->uri) =~ s%^(.*/).*$%$1%;
                    $row{user_avatar} = $b_url . $row{user_avatar} if $row{user_avatar} !~ m%^http://%;
                    $row{user_avatar_type} = 2;
                    last;
                }
            }
            #print "$row{username} - $row{user_avatar}\n";
            # user_occ
            #for (1..5) {
                #$p_token = $p_parse->get_token;
                #$p_token = $p_parse->get_token until $p_token->is_start_tag('tr');
            #}
            #$p_token = $p_parse->get_token until $p_token->is_end_tag('td');
            #$p_token = $p_parse->get_token until $p_token->is_text
              #&& $p_token->as_is !~ /^\s+$|^(&nbsp;)+$/
              #|| $p_token->is_end_tag('tr');
            $p_token = $p_parse->get_token until $p_token->is_text && $p_token->as_is =~ /^$self->{profile_string_occupation}:/i;
            $p_token = $p_parse->get_token until $p_token->is_start_tag('span');
            $p_token = $p_parse->get_token until $p_token->is_text;
            $row{user_occ} = $p_token->as_is if $p_token->as_is !~ /^\s+$|^(&nbsp;)+$/;
            # user_interests
            $p_token = $p_parse->get_token until $p_token->is_end_tag('tr');
            $p_token = $p_parse->get_token until $p_token->is_end_tag('td');
            $p_token = $p_parse->get_token until $p_token->is_text
              && $p_token->as_is !~ /^\s+$|^(&nbsp;)+$/
              || $p_token->is_end_tag('tr');
            $row{user_interests} = $p_token->as_is if $p_token->is_text;
            # user_msnm
            #$p_token = $p_parse->get_token until $p_token->is_start_tag('table');
            #for (1..3) {
                #$p_token = $p_parse->get_token;
                #$p_token = $p_parse->get_token until $p_token->is_start_tag('tr');
            #}
            #$p_token = $p_parse->get_token until $p_token->is_end_tag('td');
            #$p_token = $p_parse->get_token until $p_token->is_text
              #&& $p_token->as_is !~ /^\s+$|^(&nbsp;)+$/
              #|| $p_token->is_end_tag('tr');
            $p_token = $p_parse->get_token until $p_token->is_text && $p_token->as_is =~ /^$self->{profile_string_msn}:/i;
            $p_token = $p_parse->get_token until $p_token->is_start_tag('span');
            $p_token = $p_parse->get_token until $p_token->is_text;
            $row{user_msnm} = $p_token->as_is if $p_token->as_is !~ /^\s+$|^(&nbsp;)+$/;
            # user_yim
            $p_token = $p_parse->get_token until $p_token->is_end_tag('tr');
            $p_token = $p_parse->get_token until $p_token->is_end_tag('td');
            $p_token = $p_parse->get_token until $p_token->is_start_tag('a')
              && $p_token->get_attr('href') =~ /target=(.+?)(&|$)/
              || $p_token->is_end_tag('tr');
            $row{user_yim} = $1 if $p_token->is_start_tag('a');
            # user_aim
            $p_token = $p_parse->get_token until $p_token->is_end_tag('tr');
            $p_token = $p_parse->get_token until $p_token->is_end_tag('td');
            $p_token = $p_parse->get_token until $p_token->is_start_tag('a')
              && $p_token->get_attr('href') =~ /screenname=(.+?)(&|$)/
              || $p_token->is_end_tag('tr');
            $row{user_aim} = $1 if $p_token->is_start_tag('a');
            # user_icq
            $p_token = $p_parse->get_token until $p_token->is_end_tag('tr');
            $p_token = $p_parse->get_token until $p_token->is_end_tag('td');
            $p_token = $p_parse->get_token until $p_token->is_start_tag('a')
              && $p_token->get_attr('href') =~ /icq\.com.*=(\d+?)(&|$)/
              || $p_token->is_end_tag('tr');
            $row{user_icq} = $1 if $p_token->is_start_tag('a');
	    }
	    #while( my ($k, $v) = each %row ) {
	     #print "$k : $v\n";
	    #}
	    #print "\n";

	    push @{$self->{users}}, \%row;
	    if ($self->{db_insert} && ++$rows >= $self->{max_rows}) {
		$self->insert_array($self->{users}, "users");
		@{$self->{users}} = ();
	    }

	}
    }
    if ($self->{db_insert}) {
	$self->insert_array($self->{users}, "users");
	@{$self->{users}} = ();
    }
    $self->create_groups;
}

# wrapper for get_users_raw() that retries in case of errors
sub get_users {
    my $self = shift;
    for (1..$self->{max_tries}) {
        eval {
            $self->get_users_raw(@_);
            1;
        } and last;
	    print "failed (try $_ out of $self->{max_tries})\n";
        sleep(1)
    }
}

# $_[0]=$topic_id, $_[1]=$page_number
sub get_posts {
    my $self = shift;
    my ($topic_id, $page_number) = @_;
    my $success;
    my ($url, $url1, $url2);
    if ($self->{verbose}) {
    	print "getting the posts from topic #$topic_id\n";
    }
    # make a copy of the $mech object
    my $mech = {%{$self->{mmech}}};
    bless $mech, "WWW::Mechanize";
    $url1 = $self->{topic_link1};
    $url1 = sprintf($url1, $topic_id) if $url1 =~ m/%d/;
    $url2 = $self->{topic_link2};
    $url2 = sprintf($url2, $topic_id) if $url2 =~ m/%d/;
    $url = $self->compute_url($url1, $url2);
    for (1..$self->{max_tries}) {
        eval {
	    $mech->get($url);
	    1;
	} or next;
	last if $mech->success && $mech->status == 200;
	print "Failed to enter topic_id $topic_id (try $_ out of $self->{max_tries})\n";
    }
    return unless $mech->success && $mech->status == 200;
    # cycle through pages
    my $pages = $self->number_of_pages($mech, 'topic');
    # get just one page ?
    if (defined $page_number) {
	if (-@$pages <= $page_number && $page_number < @$pages) {
	    $pages = [ $$pages[$page_number] ];
	} else { return }
    }
    for ( @$pages ) {
	my $url = $mech->uri;
	$url = $self->topic_url_for_page($url, $topic_id, $_);
	for (1..$self->{max_tries}) {
	    eval {
		$mech->get($url);
		1;
	    } or next;
	    last if $mech->success && $mech->status == 200;
	    print "Failed to enter a page of topic_id $topic_id (try $_ out of $self->{max_tries})\n";
	}
	next unless $mech->success && $mech->status == 200;
	$self->get_posts_from_page($mech, $topic_id, $_);
    }
    # get last_post_id only if scraping the full topic or just the last page
    unless (defined $page_number && $page_number != -1) {
	for (@{$self->{topics}}) {
	    if ($_->{topic_id} == $topic_id) {
		$_->{topic_last_post_id} = $self->{posts}[-1]{post_id};
		last;
	    }
	}
    }
    if ($self->{db_insert}) {
	$self->insert_array($self->{posts}, "posts");
	$self->insert_array($self->{posts_text}, "posts_text");
	$self->insert_array($self->{vote_desc}, "vote_desc");
	$self->insert_array($self->{vote_results}, "vote_results");
	@{$self->{posts}} = ();
	@{$self->{posts_text}} = ();
	@{$self->{vote_desc}} = ();
	@{$self->{vote_results}} = ();
    }
}

sub get_posts_from_page {
    my $self = shift;
    my ($mech, $topic_id, $start_from) = @_;
    my $parse;
    $parse = HTML::TokeParser::Simple->new( \$mech->content );
    $parse->unbroken_text( 1 );
    my $token;
    my $rows;
    my %v_row;

    $token = $parse->get_token;
    $token = $parse->get_token until $token->get_attr('class') eq 'forumline';
    for (1..2) {
	$token = $parse->get_token;
	$token = $parse->get_token until $token->is_start_tag('tr');
    }
    my $counter;
    while (1) {
	$token = $parse->get_token;
	$counter++ if $token->is_start_tag('tr');
	$counter-- if $token->is_end_tag('tr');
	last if $counter < 0;
	# get the poll only on the first page
	if ($token->is_start_tag('table') && $start_from == 0) {
	    #################
	    ## it's a poll ##
	    #################
	    for (@{$self->{topics}}) {
		if ($_->{topic_id} == $topic_id) {
		    # topic_vote
		    $_->{topic_vote} = 1;
		    last;
		}
	    }
	    # topic_id
	    $v_row{topic_id} = $topic_id;
	    # vote_id
	    $v_row{vote_id} = ++$self->{vote_id};
	    # vote_text
	    $token = $parse->get_token until $token->is_text
	      && $token->as_is =~ /\S/;
	    $v_row{vote_text} = $token->as_is;
	    # @{$self->{vote_results}}
	    my $vote_option_id;
	    $token = $parse->get_token until $token->is_start_tag('table');
	    my $counter2;
	    while (1) {
		my %vr_row;
		$token = $parse->get_token;
		$counter2++ if $token->is_start_tag('table');
		$counter2-- if $token->is_end_tag('table');
		last if $counter2 < 0;
		next unless $token->is_start_tag('td');
		$token = $parse->get_token until $token->is_text
		  && $token->as_is =~ /\S/
		  && $token->as_is !~ /&nbsp;/
		  && $token->as_is !~ /^\s+$/;
		$vr_row{vote_id} = $self->{vote_id};
		$vr_row{vote_option_text} = $token->as_is;
		$vr_row{vote_option_id} = ++$vote_option_id;
		push @{$self->{vote_results}}, \%vr_row;
		my $counter3;
		while (1) {
		    $token = $parse->get_token;
		    if ($token->is_start_tag('tr')) {
			$counter++;
			$counter3++;
		    }
		    if ($token->is_end_tag('tr')) {
			$counter--;
			$counter3--;
		    }
		    last if $counter3 < 0;
		}
		# print "|>", $parse->peek(7), "<|\n";
	    }
	    push @{$self->{vote_desc}}, \%v_row;
	}
    }

    while ( $token = $parse->get_token ) {
	last if $token->get_attr('class') eq 'catBottom';
	# post_username
	next unless $token->get_attr('class') eq 'name';
	$token = $parse->get_token until $token->is_text;
	my $post_username = $token->as_is;
	# post_id
	$token = $parse->get_token until $token->is_start_tag('a')
	  && $token->get_attr('href') =~ $self->{topic_link_regex_p};
	my %row;
	$row{post_id} = $1;
	# topic_id
	$row{topic_id} = $topic_id;
	# forum_id
	for (@{$self->{topics}}) {
	    if ($_->{topic_id} == $topic_id) {
		$row{forum_id} = $_->{forum_id};
		last;
	    }
	}
	# post_time
	$token = $parse->get_token until $token->is_text
	  && $token->as_is =~ /\S/;
	$row{post_time} = $self->parse_date($token->as_is, $self->{post_date_format},
	    $self->{post_date_pos});
	if (@{$self->{posts}} && $row{post_time} <= $self->{posts}[-1]->{post_time}) {
	    $row{post_time} = $self->{posts}[-1]->{post_time} + 1
	}

	## fill some @{$self->{topics}} and @{$self->{vote_desc}} fields ##
	# just for the first page
	if ($start_from == 0) {
	    for (@{$self->{topics}}) {
		if ($_->{topic_id} == $topic_id) {
		    # topic_first_post_id
		    $_->{topic_first_post_id} = $row{post_id}
		    unless $_->{topic_first_post_id};
		    # vote_start and topic_time
		    $v_row{vote_start} = $_->{topic_time} = $row{post_time}
		    unless $_->{topic_time};
		    last;
		}
	    }
	}

        # @{$self->{posts_text}}
	my %t_row;
	# post_subject
	$token = $parse->get_token;
	$token = $parse->get_token until $token->is_text
	  && $token->as_is =~ /\S: (.*)$/;
	$t_row{post_subject} = $1;
	# post_id
	$t_row{post_id} = $row{post_id};
	# bbcode_uid
	$t_row{bbcode_uid} = $self->{bbcode_uid};
	# post_text
	$token = $parse->get_token until $token->is_start_tag('tr');
	$token = $parse->get_token;
	$token = $parse->get_token until $token->is_start_tag('tr');
	my $text;
	my $tr_count; # keep a track of <tr> tags
	while ($token = $parse->get_token) {
	    $tr_count++ if $token->is_start_tag('tr');
	    $tr_count-- if $token->is_end_tag('tr');
	    last if $tr_count < 0;
	    $text .= $token->as_is;
	}
	## bbcode
	$text = ${ $self->html_to_bbcode(\$text, 1) };
    # take care of HTML entities
    $text = decode_entities($text);
    $text = encode_entities($text);

	$t_row{post_text} = $text;
	# poster_id
	$token = $parse->get_token until $token->is_start_tag('table');
	while ($token = $parse->get_token) {
	    last if $token->is_end_tag('table');
	    if ($token->is_start_tag('a') && $token->get_attr('href')
		=~ /viewprofile.*u=(\d+)/) {
		    $row{poster_id} = $1;
		    last;
		}
	}
	# anonymous?
	unless ( exists $row{poster_id}) {
	    $row{poster_id} = -1;
	    $row{post_username} = $post_username;
	}

	push @{$self->{posts}}, \%row;
	push @{$self->{posts_text}}, \%t_row;
	if ($self->{db_insert} && ++$rows == $self->{max_rows}) {
	    $rows = 0;
	    # keep the last post
	    my $lastpost = pop @{$self->{posts}};
	    $self->insert_array($self->{posts}, "posts");
	    @{$self->{posts}} = ();
	    # put it back
	    push @{$self->{posts}}, $lastpost;

	    $self->insert_array($self->{posts_text}, "posts_text");
	    @{$self->{posts_text}} = ();
	}
    }
}

sub update_users_raw {
    my $self = shift;
    $self->{db_insert} = 0;
    my $page = -1;
    my @new;
    # max user_id
    my $sth = $self->{dbh}->prepare("SELECT MAX(user_regdate) AS regdate FROM $self->{db_prefix}" . "users");
    $sth->execute;
    $sth->bind_columns(\my ($max_regdate));
    $sth->fetch;
    MLOOP: while (1) {
	@{$self->{users}} = ();
	$self->get_users($page);
	last unless @{$self->{users}};
	for (reverse @{$self->{users}}) {
	    if ($_->{user_regdate} < $max_regdate) { # get out
		last MLOOP;
	    } elsif ($_->{user_regdate} == $max_regdate) {
		$sth = $self->{dbh}->prepare("SELECT user_id, username FROM $self->{db_prefix}"
		    . "users WHERE user_regdate=$max_regdate");
		$sth->execute;
		$sth->bind_columns(\my ($user_id, $username));
		while ($sth->fetch) {
		    if ($_->{user_id} == $user_id && $user_id != 1) {
			if ($_->{username} ne $username) {
			    # this user was deleted
			    $self->{dbh}->do("DELETE FROM $self->{db_prefix}" . "users WHERE user_id=$user_id");
			    $self->{dbh}->do("UPDATE $self->{db_prefix}"
				. "posts SET poster_id=-1, post_username="
				. $self->{dbh}->quote($_->{username})
				. " WHERE poster_id=$user_id");
			    push @new, $_;
			}
			last;
		    }
		}
	    } else { # insert
		push @new, $_;
	    }
	}
	$page--;
    }
    $self->insert_array(\@new, 'users');
    $self->create_groups;
}

# wrapper for update_users_raw() that retries in case of errors
sub update_users {
    my $self = shift;
    for (1..$self->{max_tries}) {
        eval {
            $self->update_users_raw(@_);
            1;
        } and last;
	    print "failed (try $_ out of $self->{max_tries})\n";
        sleep(1)
    }
}

sub update_topics {
    my $self = shift;
    my ($forum_id) = @_;
    my @modified_topics;
    my $page = 0;
    PAGE: while (1) {
	@{$self->{topics}} = ();
	$self->get_topics($forum_id, $page);
	last unless @{$self->{topics}};
	for (@{$self->{topics}}) {
	    my $sth = $self->{dbh}->prepare("SELECT post_time FROM $self->{db_prefix}"
		. "posts WHERE post_id=" . $_->{topic_last_post_id});
	    $sth->execute;
	    $sth->bind_columns(\my $post_time);
	    if ($sth->fetch) {
		# we have the last_post_id, but it can be a new post with the id of a deleted one
		if ($post_time >= $self->{last_timestamp}) {
		    push @modified_topics, $_;
		} elsif ($_->{topic_type} == 0) {
		    # normal topic - it won't appear on more pages
		    last PAGE;
		}
	    } else {
		# new topic
		push @modified_topics, $_;
	    }
	}
	$page++;
    }
    @{$self->{topics}} = @modified_topics;
}

sub update_topics_insert {
    my $self = shift;
    my ($t) = @_;
    unless ($self->{update_overwrite}) {
	my $sth = $self->{dbh}->prepare("SELECT topic_title FROM $self->{db_prefix}"
	    . "topics WHERE topic_id=" . $t->{topic_id});
	$sth->execute;
	$sth->bind_columns(\my $topic_title);
	if ($sth->fetch && $topic_title ne $t->{topic_title}) {
	    # it was probably deleted, create a new one
	    my $topic_id;
	    my $sth = $self->{dbh}->prepare("SELECT MAX(topic_id) FROM $self->{db_prefix}" . "topics");
	    $sth->execute;
	    $sth->bind_columns(\$topic_id);
	    $sth->fetch;
	    $topic_id++;
	    $self->{dbh}->do("REPLACE $self->{db_prefix}" . "topics_trans "
		. "SET new=$topic_id, orig=" . $t->{topic_id});
	    $t->{topic_id} = $topic_id;
	}
    }
    $self->insert_array([$t], 'topics');
}

sub update_posts {
    my $self = shift;
    my ($topic_id) = @_;
    my @new_posts;
    my @new_posts_text;
    my $page = -1;
    my $last_post_id; # that was used for a post
    my $sth = $self->{dbh}->prepare("SELECT MAX(post_id) FROM $self->{db_prefix}" . "posts");
    $sth->execute;
    $sth->bind_columns(\$last_post_id);
    $sth->fetch;

    PAGE: while (1) {
	@{$self->{posts}} = ();
	@{$self->{posts_text}} = ();
	$self->get_posts($topic_id, $page);
	last unless @{$self->{posts}};
	##$self->print_AoH($self->{posts});
	POST: for (reverse 0..$#{$self->{posts}}) {
	    my $sth;
	    last PAGE if $self->{posts}[$_]{post_time} < $self->{last_timestamp};
	    # don't get the posts that appeared betwen scraping the topic
	    # and scraping the posts, because it will mess up
	    # our last_timestamp at the next update
	    for my $t (@{$self->{topics}}) {
		if ($t->{topic_id} == $topic_id) {
		    next POST if $self->{posts}[$_]{post_id} > $t->{topic_last_post_id};
		    last;
		}
	    }

	    my ($in_table, $in_orig, $in_new);
	    my $new_id;

	    $sth = $self->{dbh}->prepare("SELECT post_id FROM $self->{db_prefix}"
		. "posts WHERE post_id=" . $self->{posts}[$_]{post_id});
	    $sth->execute;
	    if ($sth->fetch) {
		# we have that id
		$in_table = 1;
	    }
	    unless ($self->{update_overwrite}) {
		$sth = $self->{dbh}->prepare("SELECT new FROM $self->{db_prefix}"
		    . "posts_trans WHERE new=" . $self->{posts}[$_]{post_id});
		$sth->execute;
		if ($sth->fetch) {
		    # it's in the translation table, as a new id
		    $in_new = 1;
		}
		$sth = $self->{dbh}->prepare("SELECT new FROM $self->{db_prefix}"
		    . "posts_trans WHERE orig=" . $self->{posts}[$_]{post_id});
		$sth->execute;
		$sth->bind_columns(\$new_id);
		if ($sth->fetch) {
		    $in_orig = 1;
		}
	    }

	    if ($in_table) {
		# could be already scraped, check post_text
		my $against_id = $self->{posts}[$_]{post_id};
		if ($in_orig) {
		    # could be deleted, check against new_id
		    $against_id = $new_id;
		}
		unless ($in_new && ! $in_orig) {
		    # compare text
		    $sth = $self->{dbh}->prepare("SELECT post_text FROM $self->{db_prefix}"
			. "posts_text WHERE post_id=$against_id");
		    $sth->execute;
		    $sth->bind_columns(\my $post_text);
		    if ($sth->fetch) {
			# already scraped
			last PAGE if $post_text eq $self->{posts_text}[$_]{post_text};
		    }
		}
		unless ($self->{update_overwrite}) {
		    # set and record a new post_id
		    $last_post_id++;
		    $self->{dbh}->do("REPLACE $self->{db_prefix}" . "posts_trans "
			. "SET new=$last_post_id, orig=" . $self->{posts}[$_]{post_id});
		    $self->{posts_text}[$_]{post_id} = $self->{posts}[$_]{post_id} = $last_post_id;
		}
	    }

	    push @new_posts, $self->{posts}[$_];
	    push @new_posts_text, $self->{posts_text}[$_];
	}
	$page--;
    }
    ##$self->print_AoH(\@new_posts);
    @{$self->{posts}} = @new_posts;
    @{$self->{posts_text}} = @new_posts_text;
}

sub update_posts_insert {
    my $self = shift;
    my $sth;

    for (@{$self->{posts}}) {
	unless ($self->{update_overwrite}) {
	    # coordinate topic_id
	    my $new_topic_id;
	    $sth = $self->{dbh}->prepare("SELECT new FROM $self->{db_prefix}"
		. "topics_trans WHERE orig=" . $_->{topic_id});
	    $sth->execute;
	    $sth->bind_columns(\$new_topic_id);
	    if ($sth->fetch) {
		$_->{topic_id} = $new_topic_id;
	    }
	}

    }

    $self->insert_array($self->{posts}, 'posts');
    $self->insert_array($self->{posts_text}, 'posts_text');
}

####################
# helper functions #
####################

sub empty_tables {
    my $self = shift;
    for (@{$self->{db_empty}}) {
	if ($_ eq 'users') {
	    my $sth = $self->{dbh}->prepare("SELECT * FROM $self->{db_prefix}" . "users WHERE user_id=1");
	    $sth->execute;
	    $self->{dbh}->do("UPDATE $self->{db_prefix}" . "users SET user_id=1 WHERE user_id=2")
	      unless $sth->fetch;
	    $self->{dbh}->do("DELETE FROM $self->{db_prefix}" . "users WHERE user_id!=1 AND user_id!=-1");
	} elsif($_ eq 'groups') {
	    $self->{dbh}->do("DELETE FROM $self->{db_prefix}" . "groups WHERE group_id>2");
	} elsif($_ eq 'user_group') {
	    $self->{dbh}->do("DELETE FROM $self->{db_prefix}" . "user_group WHERE group_id>2");
	} else {
	    $self->{dbh}->do("DELETE FROM " . $self->{db_prefix} . $_);
	}
    }
}

# $_[0]=$array_ref, $_[1]=$table
sub insert_array {
    my $self = shift;
    my ($aref, $table) = @_;
    for my $row (@$aref) {
	my $query;
	my @cols = keys %$row;
	for (my $i = 0; $i < @cols; $i++) {
	    $query .= ',' if $i;
	    $query .= "$cols[$i]=" . $self->{dbh}->quote($$row{$cols[$i]});
	}
	$query = "INSERT $self->{db_prefix}$table SET " . $query . " ON DUPLICATE KEY UPDATE " . $query;
	eval {
	    $self->{dbh}->do($query);
	};
	croak ("$query\n$@\n") if $@;
	##print "$query\n";
    }
}

# $_[0]=$mech
# returns an array ref with page numbers
sub number_of_pages {
    my $self = shift;
    my ($mech, $type) = @_;
    my %page;
    $page{0} = 1;
    my $success;
    (my $url_ident = $mech->uri) =~ s%.*/(.*?)\?.*%$1%;
    $success = $mech->find_all_links(url_regex => qr/^${url_ident}.*start=\d+/);
    if (@$success) {
        for(@$success) {
            $_->url =~ /start=(\d+)(\D|$)/;
            $page{$1} = 1;
            #print $_->url . " : '$1'\n"
        }
    } elsif($self->{alternative_page_number_regex_forum} ne qr// && $type eq 'forum') {
        $success = $mech->find_all_links(url_regex => $self->{alternative_page_number_regex_forum});
        if (@$success) {
            for(@$success) {
            $_->url =~ $self->{alternative_page_number_regex_forum};
            $page{$1} = 1;
            }
        }
    } elsif($self->{alternative_page_number_regex_topic} ne qr// && $type eq 'topic') {
        $success = $mech->find_all_links(url_regex => $self->{alternative_page_number_regex_topic});
        if (@$success) {
            for(@$success) {
            $_->url =~ $self->{alternative_page_number_regex_topic};
            $page{$1} = 1;
            }
        }
    }
    # fill in missing pages
    my @page_keys = sort {$a <=> $b} keys %page;
    if (scalar(@page_keys) > 1) {
        my $per_page = $page_keys[1] - $page_keys[0];
        for(my $p=$page_keys[0]; $p<=$page_keys[-1]; $p+=$per_page) {
            $page{$p} = 1;
        }
    }
    # return array ref
    [sort {$a <=> $b} keys %page];
}

sub forum_url_for_page {
	my $self = shift;
	my ($url, $forum_id, $page) = @_;

	$url =~ s/&start=\d+//;
	$url .= "&start=$page";
	return $url;
}

sub topic_url_for_page {
	my $self = shift;
	my ($url, $topic_id, $page) = @_;

	$url =~ s/&start=\d+//;
	$url .= "&start=$page";
	return $url;
}

sub memberlist_url_for_page {
	my $self = shift;
	my ($url, $page) = @_;

	$url =~ s/&start=\d+//;
	$url .= "&start=$page";
	return $url;
}

# $_[0]=string_ref, $_[1]=$prepare_html
sub html_to_bbcode {
    my $self = shift;
    my ($html, $prepare_html) = @_;
    if ($prepare_html) {
	## discard excess whitespace
	$$html =~ s/\s{2,}/ /g; # trim spaces
	$$html =~ s/(>|^)\s+(<|$)/$1$2/smg; # delete whitespace between tags
	$$html =~ s/\n//g; # no need for that
	## replace <br /> with \n
	$$html =~ s(<br />)(\n)isg;
    }
    my $text;
    my @close_tag; # push and pop them as they come along (LIFO)
    my $parse;
    $parse = HTML::TokeParser::Simple->new( $_[0] );
    $parse->unbroken_text( 1 );
    my $token;
    while ($token = $parse->get_token) {
	if ($token->is_start_tag('span')) {
	    if ($token->get_attr('style') eq 'font-weight: bold') {
		$text .= "[b:$self->{bbcode_uid}]";
		push @close_tag, "[/b:$self->{bbcode_uid}]";
	    } elsif ($token->get_attr('style') eq 'font-style: italic') {
		$text .= "[i:$self->{bbcode_uid}]";
		push @close_tag, "[/i:$self->{bbcode_uid}]";
	    } elsif ($token->get_attr('style') eq 'text-decoration: underline') {
		$text .= "[u:$self->{bbcode_uid}]";
		push @close_tag, "[/u:$self->{bbcode_uid}]";
	    } elsif ($token->get_attr('style') =~ 'color: (.*)$') {
		$text .= "[color=$1:$self->{bbcode_uid}]";
		push @close_tag, "[/color:$self->{bbcode_uid}]";
	    } elsif ($token->get_attr('style') =~ 'font-size: (\d*)px') {
		$text .= "[size=$1:$self->{bbcode_uid}]";
		push @close_tag, "[/size:$self->{bbcode_uid}]";
	    } else { # some other <span> we don't care about
		push @close_tag, "";
	    }
	} elsif ($token->is_end_tag('span')) {
	    $text .= pop @close_tag;
	} elsif ($token->is_start_tag('table')) { # quote or code
	    #print "|>", $parse->peek(7), "<|\n";
	    $token = $parse->get_token until $token->is_start_tag('td');
	    #$token = $parse->get_token until $token->is_text && $token->as_is =~ /^(.*?) ?$self->{quote_string}:$/s;
	    my $author = '';
	    while($token = $parse->get_token) {
	    	if($token->is_text && $token->as_is =~ /^(.*?) ?$self->{quote_string}:$/s) {
		    #print $token->as_is, "\n";
		    $author = $1;
		    last;
		} elsif($token->is_end_tag('td')) {
		    last;
		}
	    }
	    #print $author, "\n";
	    $token = $parse->get_token until $token->is_start_tag('td');
	    #print "test\n";
	    if ($token->get_attr('class') eq 'quote') {
		if ($author eq '') {
		    $text .= "[quote:$self->{bbcode_uid}]";
		} else {
		    $text .= "[quote:$self->{bbcode_uid}=\"$author\"]";
		}
		push @close_tag, "[/quote:$self->{bbcode_uid}]";
	    } elsif ($token->get_attr('class') eq 'code') {
		$text .= "[code:$self->{bbcode_uid}]";
		push @close_tag, "[/code:$self->{bbcode_uid}]";
	    }
	    my $counter;
	    my $in_table;
	    while ($token = $parse->get_token) {
		$counter++ if $token->is_start_tag('td');
		$counter-- if $token->is_end_tag('td');
		last if $counter < 0;
		$in_table .= $token->as_is;
	    }
	    # catch the bbcode inside
	    $text .= ${ $self->html_to_bbcode(\$in_table) };
	    $text .= pop @close_tag;
	} elsif ($token->is_start_tag('ul')) {
	    $text .= "[list:$self->{bbcode_uid}]";
	    push @close_tag, "[/list:u:$self->{bbcode_uid}]";
	} elsif ($token->is_end_tag('ul')) {
	    $text .= pop @close_tag;
	} elsif ($token->is_start_tag('ol')
	    && $token->get_attr('type') eq '1') {
		$text .= "[list=1:$self->{bbcode_uid}]";
		push @close_tag, "[/list:o:$self->{bbcode_uid}]";
	    } elsif ($token->is_start_tag('ol')
		&& $token->get_attr('type') eq 'a') {
		    $text .= "[list=a:$self->{bbcode_uid}]";
		    push @close_tag, "[/list:o:$self->{bbcode_uid}]";
		} elsif ($token->is_end_tag('ol')) {
		    $text .= pop @close_tag;
		} elsif ($token->is_start_tag('li')) {
		    $text .= "[*:$self->{bbcode_uid}]";
		} elsif ($token->is_tag('img')) {
		    # check for smiles
		    my $is_smile;
		    my $src = $token->get_attr('src');
		    for (keys %{$self->{smiles}}) {
			if ( $src =~ /\/$_\.gif/ ) {
			    $text .= $self->{smiles}{$_};
			    $is_smile = 1;
			    last;
			}
		    }
		    unless ($is_smile) {
			# a simple image
			$text .= "[img:$self->{bbcode_uid}]"
			  . $token->get_attr('src')
			  . "[/img:$self->{bbcode_uid}]";
		    }
		} elsif ($token->is_start_tag('a')) {
		    if ($token->get_attr('href') =~ /mailto:/) {
			push @close_tag, "";
			next;
		    }
		    $text .= "[url="
		      . $token->get_attr('href')
		      . "]";
		    push @close_tag, "[/url]";
		} elsif ($token->is_end_tag('a')) {
		    $text .= pop @close_tag;
		} elsif ($token->is_text) {
		    $text .= $token->as_is;
		}
    }
    \$text;
}

# $_[0]=$string, $_[1]=$date_format_regex, $_[2]=$date_pos_arrray-ref
sub parse_date {
    my $self = shift;
    my ($str, $date_format, $date_pos) = @_;
    my %date_vars;
    my %month_number;
    for( my $i=0; $i<@{$self->{months}}; $i++ ) {
	$month_number{$self->{months}[$i]} = $i;
    }

    $_ = $str;
    return 0 unless /$date_format/i;
    my @res = /$date_format/i;
    for (my $i = 0; $i < @res; $i++) {
	$date_vars{$$date_pos[$i]} = $res[$i];
    }

    # strip leading zero
    for (qw(seconds minutes hour day_of_month)) {
	$date_vars{$_} =~ s/^0(\d)/$1/ if exists $date_vars{$_};
    }

    # AM/PM
    if (exists $date_vars{am_pm}) {
	$date_vars{hour} += 12 if $date_vars{am_pm} =~ /pm/i
	  && $date_vars{hour} != 12;
	$date_vars{hour} -= 12 if $date_vars{am_pm} =~ /am/i
	  && $date_vars{hour} == 12;
    }
    # month name
    $date_vars{mon} = $month_number{lc substr($date_vars{month_name}, 0, 3)}
    if exists $date_vars{month_name};
    # month
    $date_vars{mon} = $date_vars{month} - 1 if exists $date_vars{month};
    # get rid of warnings
    for (qw(seconds minutes day_of_month mon year)) {
	$date_vars{$_} = 0 unless exists $date_vars{$_};
    }
    $date_vars{hour} = 12 unless exists $date_vars{hour};
    # return timestamp
    timelocal( $date_vars{seconds}, $date_vars{minutes}, $date_vars{hour},
	$date_vars{day_of_month}, $date_vars{mon}, $date_vars{year} );
}

# $_[0]=$array_ref
sub print_AoH {
    my $self = shift;
    my $AoHr = $_[0];
    print scalar @$AoHr, " elements:\n";
    for my $row (@$AoHr) {
	print "==>";
	for (sort keys %$row) {
	    print "\t$_ => \"$row->{$_}\"\n";
	}
	print "\n";
    }
}

sub update_forum_first_last_post {
    my $self = shift;
    my ($forum_id) = @_;
    for (qw(ASC DESC)) {
	$self->{dbh}->do( "UPDATE $self->{db_prefix}" . "forums SET forum_last_post_id="
	    . "(SELECT p.post_id FROM $self->{db_prefix}" . "posts p, "
	    . "$self->{db_prefix}" . "topics t "
	    . "WHERE p.topic_id = t.topic_id "
	    . "AND t.forum_id =$forum_id "
	    . "ORDER BY p.post_time $_, p.post_id $_ "
	    . "LIMIT 1) WHERE forum_id=$forum_id");
    }
}

sub get_last_timestamp {
    my $self = shift;
    my $sth = $self->{dbh}->prepare("SELECT MAX(post_time) FROM $self->{db_prefix}" . "posts");
    $sth->execute;
    $sth->bind_columns(\$self->{last_timestamp});
    $sth->fetch;
}

sub get_new_admin {
    my $self = shift;
    my $sth = $self->{dbh}->prepare("SELECT user_id, username FROM $self->{db_prefix}" . "users ORDER BY user_id DESC LIMIT 1");
    $sth->execute;
    $sth->bind_columns(\$self->{new_admin_id}, \$self->{new_admin_username});
    $sth->fetch;
}

sub create_groups {
    my $self = shift;
    my $sth = $self->{dbh}->prepare("SELECT user_id FROM $self->{db_prefix}users WHERE user_id NOT IN ( SELECT user_id FROM $self->{db_prefix}user_group )");
    $sth->execute;
    my @row;
    while(@row = $sth->fetchrow_array) {
        #print "$row[0]\n";
        my $gsth = $self->{dbh}->prepare("INSERT INTO $self->{db_prefix}groups SET group_description='Personal User'");
        $gsth->execute;
        my $group_id = $gsth->{mysql_insertid};
        my $ugsth = $self->{dbh}->prepare("INSERT INTO $self->{db_prefix}user_group SET group_id=?, user_id=?, user_pending=0");
        $ugsth->execute($group_id, $row[0]);
    }
}

sub compute_url {
    my $self = shift;
    my ($url1, $url2) = @_;
    my $url;
    ($url = $self->{mmech}->uri) =~ s%^(.*)/.*?(\?)|$%$1/$url1$2%;
    if ($url =~ /\?/) {
	$url .= "&";
    } else {
	$url .= "?";
    }
    $url .= $url2;
}

sub reaper {
    while (waitpid(-1, WNOHANG) > 0) {
	$children--;
    }
    $SIG{CHLD} = \&reaper;
}
$SIG{CHLD} = \&reaper;

# takes a function reference as argument
# remember to "wait for 1..$children;" after the loop
sub parallelize {
    my $self = shift;
    my ($func_ref) = @_;
    if($self->{max_children} < 2) {
        # avoid forking when parallelism is not requested (workaround for a windoze bug)
	    &$func_ref;
    } else {
        if ($children < $self->{max_children}) { # fork a subprocess
            if (my $pid = fork) {
                # parent
                $children++;
                if ($children == $self->{max_children}) {
                    wait;
                    $children--;
                }
            } else {
                # child
                croak "can't fork" if undef $pid;
                # the db link was destroyed by forking. create it again
                $self->{dbh}{InactiveDestroy} = 1;
                $self->{dbh} = DBI->connect("DBI:mysql:database=$self->{db_database};host=$self->{db_host};mysql_compression=$self->{db_compression}",
                    $self->{db_user}, $self->{db_passwd}, {AutoCommit => 1, RaiseError => 1});
                # run function
                &$func_ref;
                exit;
            }
        }
    }
}

#########################
# integrating functions #
#########################

sub scrape_forum_common_raw {
    my $self = shift;
    if ($self->{verbose}) {
    	print "getting categories and forums...";
    }
    $self->get_categories_and_forums();
    if ($self->{verbose}) {
    	print "\n";
    }
    for (@{$self->{forums}}) {
    	if ($self->{verbose}) {
      	    print "getting the topics from forum #", $_->{forum_id}, "\n";
    	}
    	$self->get_topics( $_->{forum_id} );
    	for (@{$self->{topics}}) {
	    $self->parallelize(
		sub {
		    $self->get_posts( $_->{topic_id} );
		    $self->insert_array([$_], "topics");
		}
	    );
    	}
    	@{$self->{topics}} = ();
    }
    #wait for 1..$children;
    1 while waitpid(-1, WNOHANG)>0; # reaps childs
    $self->update_forum_first_last_post($_->{forum_id}) for @{$self->{forums}};
}

# wrapper for scrape_forum_common_raw() that retries in case of errors
sub scrape_forum_common {
    my $self = shift;
    for (1..$self->{max_tries}) {
        eval {
            $self->scrape_forum_common_raw(@_);
            1;
        } and last;
	    print "failed (try $_ out of $self->{max_tries})\n";
        sleep(1)
    }
}

sub update_forum_common_raw {
    my $self = shift;
    $self->{db_insert} = 0;
    if ($self->{verbose}) {
    	print "getting categories and forums...";
    }
    $self->get_categories_and_forums();
    if ($self->{verbose}) {
    	print "\n";
    }
    $self->insert_array($self->{categories}, 'categories');
    $self->insert_array($self->{forums}, 'forums');
    $self->get_last_timestamp();
    for (@{$self->{forums}}) {
	if ($self->{verbose}) {
	    print "updating topics from forum #", $_->{forum_id}, "\n";
	}
	$self->update_topics($_->{forum_id});
    	for (@{$self->{topics}}) {
    	    $self->update_posts($_->{topic_id});
    	    $self->update_topics_insert($_);
    	    $self->update_posts_insert();
    	}
    	@{$self->{topics}} = ();
	$self->update_forum_first_last_post($_->{forum_id});
    }
}

# wrapper for update_forum_common_raw() that retries in case of errors
sub update_forum_common {
    my $self = shift;
    for (1..$self->{max_tries}) {
        eval {
            $self->update_forum_common_raw(@_);
            1;
        } and last;
	    print "failed (try $_ out of $self->{max_tries})\n";
        sleep(1)
    }
}


1;
__END__
=head1 NAME

WWW::phpBB - phpBB2 forum scraper

=head1 SYNOPSIS

    use WWW::phpBB;

    # scrape as guest
    my $phpbb = WWW::phpBB->new(
        base_url => 'http://localhost/~stefan/forum1',
        db_host => 'localhost',
        db_user => 'stefan',
        db_passwd => 'somepass',
        db_database => 'stefan',
        db_prefix => 'phpbb2_',
    );

    $phpbb->empty_tables();
    $phpbb->get_users();
    $phpbb->scrape_forum_common();

    # scrape a german forum with a non-standard date format and a custom GET var
    my $phpbb = WWW::phpBB->new(
        base_url => 'http://localhost/~stefan/index.php?mforum=de',
        db_host => 'localhost',
        db_user => 'stefan',
        db_passwd => 'somepass',
        db_database => 'stefan',
        db_prefix => 'phpbb2_',
        post_date_format => qr/(\d+)\s+(\w+),\s+(\d+)\s+(\d+):(\d+)/,
        post_date_pos => [qw(day_of_month month_name year hour minutes)],
        forum_user => 'raDical',
        forum_passwd => 'lfdiugyh',
    );

    # login to access the private memberlist and some private forums
    $phpbb->empty_tables();
    $phpbb->forum_login();
    $phpbb->get_users();
    $phpbb->scrape_forum_common();
    $phpbb->forum_logout();

    # update an already scraped forum, maybe as a daily cron job
    # $phpbb->update_overwrite(1); # don't try to keep modified data
    $phpbb->update_users();
    $phpbb->update_forum_common();

=head1 FANCY EXAMPLE

    use WWW::phpBB;

    # custom subclass
    package WWW::phpBB::custom;
    use base 'WWW::phpBB';

    # override some methods
    sub forum_url_for_page {
	    my $self = shift;
	    my ($url, $forum_id, $page) = @_;

	    $url =~ s%[^/]*$%%;
	    $url .= "forum,$forum_id,$page.html";
	    return $url;
    }

    sub topic_url_for_page {
	    my $self = shift;
	    my ($url, $topic_id, $page) = @_;

	    $url =~ s%[^/]*$%%;
	    $url .= "topic,$topic_id,$page.html";
	    return $url;
    }


    my $phpbb = WWW::phpBB::custom->new(
     base_url => 'http://foobar.foren-city.de',
     db_host => 'localhost',
     db_user => '****',
     db_passwd => '****',
     db_database => '****',
     db_prefix => 'phpbb_',
     verbose => 1,
     months => [qw(jan feb mär apr mai jun jul aug sep okt nov dez)],
     forum_user => '****',
     forum_passwd => '****',
     post_date_format => qr/(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+)/,
     post_date_pos => [qw(day_of_month month_name year hour minutes)],
     reg_date_format => qr/(\d+)\.(\d+)\.(\d+)/,
     reg_date_pos => [qw(day_of_month month year)],
     quote_string => "hat folgendes geschrieben",
     forum_link_regex => qr/forum,(\d+),/,
     topic_link_regex_p => qr/topic,.*#(\d+)/,
     topic_link_regex_t => qr/topic,(\d+),/,
     topic_link1 => "topic,%d.html",
     topic_link2 => "",
     profile_string_occupation => "beruf",
     alternative_page_number_regex_forum => qr/forum,\d+,(\d+)/,
     alternative_page_number_regex_topic => qr/topic,\d+,(\d+)/,
    );

    $phpbb->empty_tables();
    $phpbb->forum_login();
    $phpbb->get_users();
    $phpbb->scrape_forum_common();
    $phpbb->forum_logout();

=head1 DESCRIPTION

This module can be used to scrape a phpBB2 instalation using the web interface.
It requires a local phpBB2 setup (you can download the old 2.x versions from
http://sourceforge.net/projects/phpbb/files/phpBB%202/ ) that will be
overwritten and it can only access what is available to the web browser (i.e. no
private messages or user settings). Make sure the username used during the
local installation doesn't exist in the remote forum. Scraping is possible as a
guest or as a loged in member. If used with an administrator name and password
it will copy all the member e-mails (not just the public ones) allowing them to
request a new random password from the new installation site and continue using
the forum. The current implementation lacks search support, but this can be fixed
by converting the forum to phpBB3 or SMF. The "mforum" script is supported.

=head1 REQUIRED MODULES

L<WWW::Mechanize>

L<Compress::Zlib>

L<HTML::TokeParser::Simple>

L<DBI>

L<DBD::mysql>

=head1 EXPORT

None.

=head1 CONSTRUCTOR

=head2 new()

Creates a new WWW::phpBB object.

Required parameters:

=over 4

=item * C<< base_url => $forum_url >>

URL of the original forum.

=item * C<< db_host => $mysql_server >>

Location of the mysql server where the forum will be copied to.

=item * C<< db_user => $mysql_user >>

=item * C<< db_passwd => $mysql_pass >>

=item * C<< db_database => $mysql_db >>

Database with an already installed phpBB forum.

=item * C<< db_prefix => $ >>

Prefix used by the local installation.

=back

Optional parameters:

=over 4

=item * C<< db_compression => [0|1] >>

Compress mysql trafic (only useful when using a remote server).

=item * C<< max_rows => $value >>

Maximum number of rows kept in memory. When the storage array reaches this
value, the data is commited to the database.

=item * C<< months => [qw(jan feb mar apr may jun jul aug sep oct nov dec)] >>

Month names as used by the forum. They vary with the translation used.
The default is for the english version.

=item * C<< post_date_format => regex >>

Date format used in posts.
The default is qr/(\w+)\s+(\d+),\s+(\d+)\s+(\d+):(\d+)\s+(\w\w)/ and matches
strings like "Tue May 30, 2006 5:17 pm" - note that the leading day of the week
is ignored as it's not necessary to compute the timestamp.

=item * C<< post_date_pos => [qw(month_name day_of_month year hour minutes am_pm)] >>

Position of the elements in the date string. The number of items must match the
number of parantesis in "post_date_format". Valid field names are:

am_pm - [am|pm] - case insensitive

month_name - must be one of the values in "months"

month - number of month. Has values from 1 to 12

year

hour

minutes

seconds

=item * C<< reg_date_format => regex >>

=item * C<< reg_date_pos => [] >>

Same requirements as for the post date, only that they refer to the registration
date as it appears in the memberlist.

=item * C<< forum_link_regex => regex >>

default: qr/f=(\d+)/

=item * C<< topic_link_regex_p => regex >>

Regex for the topic link with the post id. Defaults to qr/viewtopic.*p=(\d+)/

=item * C<< topic_link_regex_t => regex >>

Regex for the topic link with the topic id. Defaults to qr/viewtopic.*t=(\d+)/

=item * C<< topic_link1 => string >>

First part of the topic page link. The topic id will be inserted with sprintf if "%d" is found. Defaults to "viewtopic.php".

=item * C<< topic_link2 => string >>

Second part of the topic page link, consisting of GET vars. The topic id will be inserted with sprintf if "%d" is found. Defaults to "t=%d&postorder=asc".

=item * C<< verbose => [0|1] >>

Verbosity. Defaults to 0.

=item * C<< max_tries => $value >>

How many times to try fetching a forum page until giving up. Defaults to 50.

=item * C<< max_children => $value >>

How many parallel processes should be used for fetching. Defaults to 1.

=item * C<< db_empty => [qw(users categories forums topics posts posts_text vote_desc vote_results)] >>

Tables that will be epmtied before scraping. The administrator of the local forum
will be kept, anything else is deleted. This parameter is not used when updating.

=item * C<< db_insert => [0|1] >>

Insert scraped data into the database. Defaults to 1.

=item * C<< update_overwrite => [0|1] >>

Overwrite existing data when updating. Defaults to 0.

=back

=head1 ACCESSORS

The accessors have the same name as the constructor parameters. If called without
a param, they return the value. With a param, they set a value.

    $phpbb->max_rows(100);
    print $phpbb->max_tries, "\n";

=head1 PUBLIC METHODS

=head2 $phpbb->empty_tables()

Empties the tables af a local phpBB installation. It leaves the admin account
untouched.

=head2 $phpbb->forum_login()

Login into the original forum. Useful when access is restricted for a guest.

=head2 $phpbb->forum_logout()

=head2 $phpbb->get_users()

Scrape user data from the memberlist and profile pages.

=head2 $phpbb->scrape_forum_common()

Scrape categories, forums, topics and posts.

=head2 $phpbb->update_users()

Update the users for an already scraped forum.

=head2 $phpbb->update_forum_common()

Update categories, forums, topics and posts for an already scraped forum.

=head1 AUTHOR

Stefan Talpalaru, E<lt>stefantalpalaru@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2011 by Stefan Talpalaru

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
