# $Id: Groups.pm,v 1.18 2004/01/03 19:09:42 cvspub Exp $
package WWW::Google::Groups;

use strict;
our $VERSION = '0.09';

use Data::Dumper;

use WWW::Google::Groups::NewsGroup;
use WWW::Google::Groups::Vars;

use WWW::Google::Groups::Search;
our @ISA = qw(WWW::Google::Groups::Search);

use WWW::Mechanize;


# ----------------------------------------------------------------------
sub new {
    my $pkg = shift;
    my %arg = @_;
    foreach my $key (qw(server proxy)){
	next unless $arg{$key};
	$arg{$key} = 'http://'.$arg{$key} if $arg{$key} !~ m,^\w+?://,o;
    }

    my $a = new WWW::Mechanize onwarn => undef, onerror => undef;
    $a->proxy(['http'], $arg{proxy}) if $arg{proxy};

    bless {
	_server => ($arg{server} || 'http://groups.google.com/'),
	_proxy => $arg{proxy},
	_agent => $a,
    }, $pkg;
}

# ----------------------------------------------------------------------
sub select_group($$) { new WWW::Google::Groups::NewsGroup(@_) }


# ----------------------------------------------------------------------
use Date::Parse;
sub save2mbox {
    my $self = shift;
    my %arg = @_;
    my $article_count = 0;
    my $thread_count = 0;
    my $max_article_count = $arg{max_article_count};
    my $max_thread_count = $arg{max_thread_count};

    my $group = $self->select_group($arg{group});
    $group->starting_thread($arg{starting_thread});

    open F, '>', $arg{target_mbox} or die "Cannot create mbox $arg{target_mbox}";
  MIRROR:
    while( my $thread = $group->next_thread() ){
	while( my $article = $thread->next_article() ){
#	    print join q/ /, map{$article->header($_)} qw(From Date Subject);
#	    print $/;
	    my $email;
	    $article->header("From")=~ /\s*(?:[<\(])(.+?@.+?)(?:[>\)])\s*/;
	    unless($1){
		$article->header("From")=~ /\s*(.+?@.+?)\s/o;
		$email = $1;
	    }
	    else {
		$email = $1;
	    }
	    my $date = scalar localtime str2time($article->header("Date"));
	    my $content = $article->as_string;
	    $content = "From $email $date\n".$content;
	    print F $content;
	    $article_count++;
	    last MIRROR if
		defined($max_article_count) and
		$article_count >= $max_article_count;
        }
	$thread_count++;
	last MIRROR if
	    defined($max_thread_count) and
	    $thread_count >= $max_thread_count;
    }
    close F;
}


# ----------------------------------------------------------------------
sub post {
    my $self = shift;
    my %arg = @_;

    $self->{_agent}->get("http://posting.google.com/post?cmd=post&enc=ISO-8859-1&group=$arg{group}&gs=/groups%3Fhl%3Den%26lr%3D%26ie%3DUTF-8%26oe%3DUTF-8%26group%3D$arg{group}");
    return unless $self->{_agent}->success();

    $self->{_agent}->submit_form(
				 form_number => 1,
				 fields      => {
				     Email    => $arg{email},
				     Passwd   => $arg{passwd},
				 }
				 );
    return unless $self->{_agent}->success();

    $self->{_agent}->content=~/location\.replace\("(.+?)"\)/o;
    $self->{_agent}->get("$1");
    return unless $self->{_agent}->success();

    $self->{_agent}->submit_form(
				 form_number => 1,
				 fields      => {
				     group    => $arg{group},
				     subject   => $arg{subject},
				     body      => $arg{message},
				 },
				 button    => 'actYes',
				 );
    return unless $self->{_agent}->success();

    $self->{_agent}->follow_link( text_regex => qr/Sign out/i );
    1;
}


1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

WWW::Google::Groups - Google Groups Agent

=head1 SYNOPSIS

=head2 BROWSING

    use WWW::Google::Groups;

    $agent = new WWW::Google::Groups
                   (
                    server => 'groups.google.com',
                    proxy => 'my.proxy.server:port',
                   );


    $group = $agent->select_group('comp.lang.perl.misc');

    $group->starting_thread(0);     # Set the first thread to fetch
                                    # Default starting thread is 0

    while( $thread = $group->next_thread() ){
	while( $article = $thread->next_article() ){

            # the returned $article is an Email::Simple object
            # See Email::Simple for its methods

	    print join q/ /, $thread->title, '<'.$article->header('From').'>', $/;
        }
    }

If you push 'raw' to the argument stack of $thread->next_article(), it will return the raw format of messages.

    while( $thread = $group->next_thread() ){
	while( $article = $thread->next_article('raw') ){
	    print $article;
        }
    }



Even, you can use this more powerful method. It will try to mirror the whole newsgroup and save the messages to a Unix mbox.

    $agent->save2mbox(
		      group => 'comp.lang.perl.misc',
		      starting_thread => 0,
		      max_article_count => 10000,
		      max_thread_count => 1000,
		      target_mbox => 'perl.misc.mbox',
		      );

=head2 SEARCHING

Also, you can utilize the searching capability of google, and the interface is much alike as the above.


    $result = $agent->search(

			     # your query string
			     query => 'groups',

			     # the limit on the number of threads to fetch
			     limit => 10,

			     );

    while( $thread = $result->next_thread ){
	while($article = $thread->next_article()){
	    print $thread->title;
	    print length $article->body();
	}
    }


=head1 POSTING

Posting function is supported since version 0.09. The agent logins to the system, uploads your data to google, and then signs out. Use it with your own caution. Please don't make any flood. 
 
   $agent->post(
		group => 'alt.test',
		email => 'my@email.address',
		passwd => 'my.passwd',
		subject => 'A test',
		message => 'BANG-BANG!',
		);




=head1 OH OH

It is heard that the module (is/may be) violating Google's term of service. So use it at your risk. It is written for crawling back the whole histories of several newsgroups, for my personal interests. Since many NNTP servers do not have huge and complete collections, Google becomes my final solution. However, the www interface of google groups cannot satisfy me well, kind of a keyboard/console interface addict and I would like some sort of perl api. That's why I design this module. And hope Google will not notify me of any concern on this evil.


=head1 TO DO

=over

=item * Advanced Search

=back


=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
