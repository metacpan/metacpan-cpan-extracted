#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use HTML::Parser;
use Text::Wrap qw(wrap);
use DBI;

# options
my $__help     = 0;
my $__verbose  = 0;
my $__database = "";
my $__user     = "";
my $__password = "";

# keeping track of truths
my $i     = 1;
my $li    = 0;
my $dbh   = undef;
my $sth   = undef;
my $truth = undef;

#
# subs
#

sub insert_truth {
    $truth =~ s/^\s*//;
    $truth =~ s/\s*$//;
    $truth =~ s/\s+/ /g;
    $sth->execute($truth) if ($__database);
    if ($__verbose) {
        my $indent = sprintf("%-8d", $i);
        $indent =~ s/(\d) /$1./;
        print wrap($indent, "        ", $truth);
        print "\n\n";
    } else {
        print "$i\n";
    }
}

sub start {
    my ($tagname) = @_;
    unless ($li) {
        if ($tagname eq "li") {
            $li = 1;
        }
    } else {
	# The behavior of HTML::Parser changed such that
	# end events don't automatically happen anymore.
	# In that case, we generate the end event ourselves
	# at the appropriate time.
	# Mon Mar  3 10:20:49 PST 2003
        if ($tagname eq "li") {
	    end("li");
	    $li = 1;
        } else {
	}
    }
}

sub end {
    my ($tagname) = @_;
    if ($li) {
        if ($tagname eq "li") {
            insert_truth();
            $li    = 0;
            $truth = "";
            $i++;
        }
    }
}

sub text {
    my ($text) = @_;
    if ($li) {
        $truth .= $text;
    }
}

#
# main
#

GetOptions (
    'h|help'       => \$__help,
    'v|verbose'    => \$__verbose,
    'd|database=s' => \$__database,
    'u|user=s'     => \$__user,
    'p|password=s' => \$__password,
);

if ($__help) {
print <<HELP;
Usage:
    parse-truth.pl [OPTION]... [FILE]...

Example:
    parse-truth.pl --database=truth truth*.htm

Options:
    -h, --help                  this help message
    -v, --verbose               print the text of the truth
    -d, --database=DATABASE     name of database to insert truths in to
                                (No insertions will be made unless the
                                 database option is specified.)

HELP
exit 0;
}

if ($__database) {
    $dbh = DBI->connect("dbi:mysql:database=$__database", $__user, $__password);
    $sth = $dbh->prepare("insert into Truth (data) values (?)");
}

my $p = HTML::Parser->new (
    api_version => 3,
    start_h     => [ \&start, "tagname" ],
    end_h       => [ \&end,   "tagname" ],
    text_h      => [ \&text,  "dtext"   ],
);

foreach (@ARGV) {
    $p->parse_file($_);
}

exit 0;

=head1 NAME

parse-truth.pl - parses srini's truths and inserts them into a database

=head1 SYNOPSIS

Just looking:

    parse-truth.pl truth{1,2}.htm -v

Insert them into the truth database:

    parse-truth.pl truth{1,2}.htm -d truth

=head1 DESCRIPTION

This parses truth*.htm in search of truth.  Once the truth is found,
it can either print it out or insert it into a MySQL database.

=head1 AUTHOR

John BEPPU <beppu@cpan.org>

=cut

# $Id: parse-truth.pl,v 1.4 2004/10/31 20:38:15 beppu Exp $
