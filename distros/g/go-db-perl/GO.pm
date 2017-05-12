# $Id: GO.pm,v 1.3 2007/10/16 19:03:34 sjcarbon Exp $
#
# This GO module is maintained by Chris Mungall <cjm@fruitfly.org>
#
# see also - http://www.geneontology.org
#          - http://www.godatabase.org/dev
#
# You may distribute this module under the same terms as perl itself

package GO;

=head1 NAME

  GO     - Gene Ontology Simple Utility Class

=head1 SYNOPSIS

  use GO;

  # --- simple procedural interface ---
  # parsing a file
  goparsefile("function.ontology");   # results go in graph()
  print graph->node_count;
  $nodes = $graph->get_all_nodes;  

  # connecting to an existing GO database
  goconnect('go@localhost');

  # ----

  # creating and loading a new GO database from some files
  gomakedb("mygo", "localhost");

  # OO usage [advanced users]
  $go = new GO;
  

=cut



=head1 DESCRIPTION

This is a simple interface to the GO toolkit

TIP FOR PROGRAMMERS: If you are already familiar with object oriented
perl, you should use the GO::AppHandle class; this module is intended
as a simple convenience wrapper for a small section of the perl
API. Warning! contains some serious hacks!

=cut


use strict;
use Carp;

use vars qw(@EXPORT);
use base qw(Exporter);
use GO::Parser;
use GO::AppHandle

@EXPORT = qw(GO gomakedb goconnect goparsefile goloaddb);

# this module works in OO and procedural mode
# - procedural mode is actually really OO mode is
# disguise - we have a global/static instance called $GO

our $GO;

sub GO {
    if (!$GO) {
        print STDERR "new...\n";
        $GO = new GO;
    }
    return $GO;
}

# as if perl OO couldnt get any weirder....
# we want this to work in OO and proc mode
# in OO mode self is always the first argument.
sub self {
    my $args = shift || [];
    my $s;
    if (scalar(@$args) &&
        UNIVERSAL::isa($args->[0], "GO")) {
        $s = shift @$args;
    }
    else {
        $s = GO;
    }
    return $s;
}

sub new {
    my $proto = shift; my $class = ref($proto) || $proto;;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub graph {
    my $self = self(\@_);
    $self->{_graph} = shift if @_;
    return $self->{_graph};
}

sub apph {
    my $self = self(\@_);
    $self->{_apph} = shift if @_;
    return $self->{_apph};
}

sub handler {
    my $self = self(\@_);
    $self->{_handler} = shift if @_;
    return $self->{_handler};
}

sub parser {
    my $self = self(\@_);
    $self->{_parser} = shift if @_;
    return $self->{_parser};
}

sub goconnect {
    my $self = self(\@_);
    require "GO/AppHandle.pm";
    print "ARGS=@_;;\n";
    if (UNIVERSAL::isa($_[0], "GO::AppHandle")) {
        $self->apph(shift);
    }
    else {
        $self->apph(GO::AppHandle->connect(@_));
    }
    return;
}

sub yesno {
    my $yn = <STDIN>;
    $yn =~ /^y/i;
}

sub gomakedb {
    my $self = self(\@_);
    my ($dbname, $dbhost, $dbms, $sqldir) =
      rearrange([['DBNAME','D', 'DB'], 
                 ['DBHOST','H', 'HOST'], 
                 ['DBMS'],
		 ['SQLDIR', 'SQL']], @_);
    if (!$dbms) {
        $dbms = "mysql";
    }
    if (!$dbname) {
        print STDERR "What do you want to call this db?\n";
        print STDERR "(must be a valid $dbms name)?\n";
        $dbname = <STDIN>;
        chomp $dbname;
    }

    print "Connect parameters.\n";
    print "\$dbname    = $dbname\n";
    print "\$dbhost    = $dbhost\n";
    print "\$dbms      = $dbms\n";

    if (!$dbname) {
        print STDERR "must supply dbname!\n";
        return;
    }

    print "\nIs this correct?\n";
    print "\nWARNING: db will be cleared if it already exists?\n";
    my $yn = yesno();
    if (!$yn) {
        print "\nWill not make db\n";
        return;
    }
    
    if (!$sqldir) {
	$sqldir = "$ENV{GO_ROOT}/sql"; 
    }
    my $cmd = 
      "cd $sqldir; ./configure $dbms $dbname $dbhost; pwd; cd $dbhost.$dbname;  pwd; gmake destroydb > /dev/null 2>1;  gmake db";
    print "cmd=$cmd\n";
    my $out = `$cmd`;
    print $out if $ENV{SQL_TRACE};
    
    print "\nOK, I think it worked....\n";
    
}

sub goloaddb {
    my $self = self(\@_);
    if (!$self->apph) {
        $self->goconnect(@_);
    }
    my $parser = new GO::Parser ({handler=>'db'});
    $parser->handler->apph($self->apph);
    $self->parser($parser);
    $self->goparsefile(@_);
    $self->apph->commit;
    return;
}

sub goparsefile {
    my $self = self(\@_);
    my $parser = $self->parser;
    if (!$parser) {
        $parser = new GO::Parser;
        $self->parser($parser);
    }
    $parser->handler({handler=>'obj'});
    my $dtype;
    my @files = $parser->normalize_files(@_);
    my @errors = ();
    while (@files) {
        my $fn = shift @files;
        if ($fn =~ /^\-datatype/) {
            $dtype = shift @files;
            next;
        }
        $parser->parse_file($fn, $dtype);
        push(@errors, @{$parser->error_list || []});
    }
    $self->graph($parser->handler->graph);
    return @errors;
}


# CUT AND PASTED FROM Lincoln Stein's CGI.pm code....

# Smart rearrangement of parameters to allow named parameter
# calling.  We do the rearangement if:
# the first parameter begins with a -
sub rearrange {
    my($order,@param) = @_;
    return () unless @param;

    if (ref($param[0]) eq 'HASH') {
	@param = %{$param[0]};
    } else {
	return @param 
	    unless (defined($param[0]) && substr($param[0],0,1) eq '-');
    }

    # map parameters into positional indices
    my ($i,%pos);
    $i = 0;
    foreach (@$order) {
	foreach (ref($_) eq 'ARRAY' ? @$_ : $_) { $pos{lc($_)} = $i; }
	$i++;
    }

    my (@result,%leftover);
    $#result = $#$order;  # preextend
    while (@param) {
	my $key = lc(shift(@param));
	$key =~ s/^\-//;
	if (exists $pos{$key}) {
	    $result[$pos{$key}] = shift(@param);
	} else {
	    $leftover{$key} = shift(@param);
	}
    }

    push (@result,make_attributes(\%leftover,1)) if %leftover;
    @result;
}

sub make_attributes {
    my $attr = shift;
    return () unless $attr && ref($attr) && ref($attr) eq 'HASH';
    my $escape = shift || 0;
    my(@att);
    foreach (keys %{$attr}) {
	my($key) = $_;
	$key=~s/^\-//;     # get rid of initial - if present
	$key=~tr/A-Z_/a-z-/; # parameters are lower case, use dashes
	my $value = $escape ? simple_escape($attr->{$_}) : $attr->{$_};
	push(@att,defined($attr->{$_}) ? qq/$key="$value"/ : qq/$key/);
    }
    return @att;
}

sub simple_escape {
  return unless defined(my $toencode = shift);
  $toencode =~ s{&}{&amp;}gso;
  $toencode =~ s{<}{&lt;}gso;
  $toencode =~ s{>}{&gt;}gso;
  $toencode =~ s{\"}{&quot;}gso;
# Doesn't work.  Can't work.  forget it.
#  $toencode =~ s{\x8b}{&#139;}gso;
#  $toencode =~ s{\x9b}{&#155;}gso;
  $toencode;
}

1;


