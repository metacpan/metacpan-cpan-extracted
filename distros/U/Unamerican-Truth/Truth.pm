package Unamerican::Truth;

use base 'CGI::Application';
use HTML::Template;
use DBI;
use strict;
use vars qw($VERSION $LAST);

$VERSION = "1.08";
$LAST    = 2856;

sub setup {
    my $self = shift;
    $self->start_mode('display');
    $self->mode_param('rm');
    $self->run_modes (
        'display'  => 'display_truths',
        'popular'  => 'display_popular_truths',
        'add'      => 'add_comment',
        'submit'   => 'submit_comment',
        'read'     => 'read_comments',
    );
    my $dbh = $self->param("dbh");
    ($LAST) = $dbh->selectrow_array("select count(*) from Truth");
}


sub display_truths {
    my $self = shift;
    my $q    = $self->query;
    my $dbh  = $self->param("dbh");
    my $tmpl = $self->load_tmpl("truth.htm");

    # current truth
    my $i    = $q->param('i') || 1;
    $i = 1     if ($i =~ /\D/);     # be strictly numeric or else
    $i = 1     if ($i < 1);         # be greater than 1
    $i = $LAST if ($i > $LAST);     # be less than $LAST

    # find out which truth we're at and what's next and what's previous
    my $len  = $q->param('q') || $self->param("proverbs_per_page");
    my $prev = ($i - $len) > 0 ? ($i - $len) : 1;
    my $next = ($i + $len);

    # get truths
    my $sth  = $dbh->prepare(qq|
        select t.*,
               count(c.comment_id) as number_of_comments
          from Truth t
               left join Comment c on t.truth_id = c.truth_id
         where t.truth_id >= ? and
               t.truth_id <  ?
         group by truth_id
         order by truth_id
    |);
    $sth->execute($i, $i + $len);
    my $data = $sth->fetchall_arrayref({});

    # fill out template
    $tmpl->param (
        is_numbered      => $self->param("is_numbered"),
        truths           => $data,
        prev             => $prev,
        i                => $i,
        next             => $next,
        next_1           => ($LAST > $next - 1) ? $next - 1 : $LAST,
        not_at_beginning => ($i > 1),
        not_at_end       => ($i + $len <= $LAST),
    );
    return $tmpl->output();
}

sub display_popular_truths {
    my $self = shift;
    my $q    = $self->query;
    my $dbh  = $self->param("dbh");
    my $tmpl = $self->load_tmpl("popular.htm");

    # get truths
    my $sth  = $dbh->prepare(qq|
        select t.*,
               count(c.comment_id) as number_of_comments
          from Truth t
               left join Comment c on t.truth_id = c.truth_id
         group by truth_id
        having number_of_comments > 0
         order by number_of_comments DESC, truth_id
    |);
    $sth->execute();
    my $data = $sth->fetchall_arrayref({});

    # fill out template
    $tmpl->param (
        is_numbered      => $self->param("is_numbered"),
        truths           => $data,
    );
    return $tmpl->output();
}

sub add_comment {
    my $self = shift;
    my $q    = $self->query;
    my $dbh  = $self->param("dbh");
    my $t_id = $q->param("truth_id");
    my $tmpl = $self->load_tmpl("add_comment.htm");

    # get truth
    my ($truth) = $dbh->selectrow_array("select data from Truth where truth_id = $t_id");

    $tmpl->param (
        truth_id => $t_id,
        truth    => $truth,
    );
    return $tmpl->output;
}

sub make_legitimate_url {
    # if it's blank
    if ($_[0] =~ /^\s*$/) {
        $_[0] = "http://www.google.com/";
        return;

    # probably an email address
    } elsif ($_[0] =~ /@/) {
        unless ($_[0] =~ /^mailto:/) {
            $_[0] = "mailto:" . $_[0];
        }
        return;

    # probably an HTTP URL
    } else {
        unless ($_[0] =~ m{^\w+://}) {
            $_[0] = "http://" . $_[0];
        }
        return;
    }
}

sub submit_comment {
    my $self = shift;
    my $q    = $self->query;
    my $dbh  = $self->param("dbh");
    my $t_id = $q->param("truth_id");
    my $data = $q->param("data");
    my $auth = $q->param("author");
    my $url  = $q->param("url");
    make_legitimate_url($url);

    if ($auth =~/^\s*$/ || $data =~ /^\s*$/) {
        $self->read_comments;
    } else {
        $auth = $dbh->quote($auth);
        $url  = $dbh->quote($url);
        $data = $dbh->quote($data);
        $dbh->do(qq|
            insert into Comment (truth_id, author, url, posted_on, data)
            values ($t_id, $auth, $url, now(), $data)
        |);
        $self->header_type('redirect');
        $self->header_props (
            -location => $q->redirect("truth.cgi?rm=read&truth_id=$t_id#what")
        );
    }
}

sub read_comments {
    my $self = shift;
    my $q    = $self->query;
    my $dbh  = $self->param("dbh");
    my $t_id = $q->param("truth_id");
    my $tmpl = $self->load_tmpl("read_comments.htm", loop_context_vars => 1);

    # get truth
    my ($truth) = $dbh->selectrow_array("select data from Truth where truth_id = $t_id");

    # select comments;
    my $sth  = $dbh->prepare(qq|
        select author,
               url,
               posted_on,
               data
          from Comment
         where truth_id = ?
         order by comment_id
    |);
    $sth->execute($t_id);
    my $data = $sth->fetchall_arrayref({});

    $tmpl->param (
        truth_id => $t_id,
        truth    => $truth,
        comments => $data,
    );
    return $tmpl->output;
}

1;

__END__

=head1 NAME

Unamerican::Truth - !!!srini's lost story.

=head1 SYNOPSIS

From a script:

  use strict;
  use Unamerican::Truth;

  my $truth = Unamerican::Truth->new;
  $truth->run;

From a browser:

  http://truth.lbox.org/truth.cgi
  http://www.unamerican.com/truth/truth.cgi

If you'd rather view B<The Truth> as a text file, type this:

  bin/parse-truth.pl -v www/truth{1,2}.html > truth.txt

=head1 DESCRIPTION

Way back in 1999, I was wandering through the web, and I came across
http://www.unamerican.com/.  There used to be a set of pages
on there under the http://www.unamerican.com/truth/ URL that
had a journal in the form of proverbs, describing his state
of mind as he wandered through Europe trying to find...
something something deeper in life.

I really liked reading this, and I think it's a shame that it's
not on the web anymore.  That's why I'm releasing it on CPAN.
I've considered that maybe !!!srini doesn't want people to know
that much about this part of his life, but I think it's such a
good read, that I'm willing to take the risk of pissing him off
or making him sad, so that others may be able to read this and
take it to heart.

I originally wrote this L<CGI::Application>-derived webapp as
a gift for srini, because one of his proverbs said:

  I envision this - this is the spec.
  you've got this document - the "truth"
  as it were - and you invite commentary
  on each and every single point in it.
  every bullet point has "add comment"
  and "read comments" hyperlinks.
  Ideally, the "read comments"
  hyperlinks also indicate how many
  comments have been added to that
  particular truth.

I thought that my web monkey skills could easily make that happen, and
it was surely a better use of my skills to do this than to do what I
normally get paid for.  And thus, L<Unamerican::Truth> was reborn in
the form of a web application.

He sounded like he wanted to install it, but it never did happen for
whatever reason.

=head1 REQUIRES

Perl Modules

  DBI
  DBD::mysql
  CGI::Application
  HTML::Template

=head1 AUTHOR

John BEPPU <beppu@cpan.org>

=head1 SEE ALSO

CGI::Application(3pm)

=cut

# $Id: Truth.pm,v 1.13 2004/10/31 20:50:26 beppu Exp $
