# Copyrights 2003-2023 by [Mark Overmeer <markov@cpan.org>].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# This code is part of distribution User-Identity.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package User::Identity::Archive::Plain;
use vars '$VERSION';
$VERSION = '1.02';

use base 'User::Identity::Archive';

use strict;
use warnings;

use Carp;


my %abbreviations =
 ( user     => 'User::Identity'
 , email    => 'Mail::Identity'
 , location => 'User::Identity::Location'
 , system   => 'User::Identity::System'
 , list     => 'User::Identity::Collection::Emails'
 );

sub init($)
{   my ($self, $args) = @_;
    $self->SUPER::init($args) or return;

    # Define the keywords.

    my %only;
    if(my $only = delete $args->{only})
    {   my @only = ref $only ? @$only : $only;
        $only{$_}++ for @only;
    }

    while( my($k,$v) = each %abbreviations)
    {   $self->abbreviation($k, $v) unless keys %only && !$only{$k};
    }
    
    if(my $abbrevs = delete $args->{abbreviations})
    {   $abbrevs = { @$abbrevs } if ref $abbrevs eq 'ARRAY';
        while( my($k,$v) = each %$abbrevs)
        {   $self->abbreviation($k, $v) unless keys %only && !$only{$k};   
        }
    }

    foreach (keys %only)
    {   warn "Option 'only' specifies undefined abbreviation '$_'\n"
            unless defined $self->abbreviation($_);
    }

    $self->{UIAP_items}   = {};
    $self->{UIAP_tabstop} = delete $args->{tabstop} || 8;
    $self;
}


sub from($@)
{   my ($self, $in, %args) = @_;

    my $verbose = $args{verbose} || 0;
    my ($source, @lines);

    if(ref $in)
    {   ($source, @lines)
         = ref $in eq 'ARRAY'     ? ('array', @$in)
         : ref $in eq 'GLOB'      ? ('GLOB', <$in>)
         : $in->isa('IO::Handle') ? (ref $in, $in->getlines)
         : confess "Cannot read from a ", ref $in, "\n";
    }
    elsif(open IN, "<", $in)
    {   $source = "file $in";
        @lines  = <IN>;
    }
    else
    {   warn "Cannot read archive from file $in: $!\n";
        return $self;
    }

    print "reading data from $source\n" if $verbose;

    return $self unless @lines;
    my $tabstop = $args{tabstop} || $self->defaultTabStop;

    $self->_set_lines($source, \@lines, $tabstop);

    while(my $starter = $self->_get_line)
    {   $self->_accept_line;
#warn "$verbose: $starter\n";
        my $indent = $self->_indentation($starter);

        print "  adding $starter" if $verbose > 1;

        my $item   = $self->_collectItem($starter, $indent);
        $self->add($item->type => $item) if defined $item;
    }
    $self;
}

sub _set_lines($$$)
{   my ($self, $source, $lines, $tab) = @_;
    $self->{UIAP_lines}  = $lines;
    $self->{UIAP_source} = $source;
    $self->{UIAP_curtab} = $tab;
    $self->{UIAP_linenr} = 0;
    $self;
}

sub _get_line()
{   my $self = shift;
    my ($lines, $linenr, $line) = @$self{ qw/UIAP_lines UIAP_linenr UIAP_line/};

    # Accept old read line, if it was not accepted.
    return $line if defined $line;

    # Need to read a new line;
    $line = '';
    while($linenr < @$lines)
    {   my $reading = $lines->[$linenr];

        $linenr++, next if $reading =~ m/^\s*\#/;    # skip comments
        $linenr++, next unless $reading =~ m/\S/;    # skip blanks
        $line .= $reading;

        if($line =~ s/\\\s*$//)
        {   $linenr++;
            next;
        }

        if($line =~ m/^\s*tabstop\s*\=\s*(\d+)/ )
        {   $self->{UIAP_curtab} = $1;
            $line = '';
            next;
        }

        last;
    }
    return () unless length $line || $linenr < @$lines;
    
    $self->{UIAP_linenr} = $linenr;
    $self->{UIAP_line}   = $line;
    $line;
}

sub _accept_line()
{   my $self = shift;
    delete $self->{UIAP_line};
    $self->{UIAP_linenr}++;
}

sub _location()     { @{ (shift) }{ qw/UIAP_source UIAP_linenr/ } }

sub _indentation($)
{   my ($self, $line) = @_;
    return -1 unless defined $line;

    my ($indent) = $line =~ m/^(\s*)/;
    return length($indent) unless index($indent, "\t") >= 0;

    my $column = 0;
    my $tab    = $self->{UIAP_curtab};
    my @chars  = split //, $indent;
    while(my $char = shift @chars)
    {   $column++, next if $char eq ' ';
        $column = (int($column/$tab+0.0001)+1)*$tab;
    }
    $column;
}

sub _collectItem($$)
{   my ($self, $starter, $indent) = @_;
    my ($type, $name) = $starter =~ m/(\w+)\s*(.*?)\s*$/;
    my $class = $abbreviations{$type};
    my $skip  = ! defined $class;
#warn "Skipping type $type\n" if $skip;

    my (@fields, @items);

    while(1)
    {   my $line        = $self->_get_line;
        my $this_indent = $self->_indentation($line);
        last if $this_indent <= $indent;

        $self->_accept_line;
        $line           =~ s/[\r\n]+$//;
#warn "Skipping line $line\n" if $skip;
        next if $skip;

        my $next_line   = $self->_get_line;
        my $next_indent = $self->_indentation($next_line);

        if($this_indent < $next_indent)
        {   # start a collectable item
#warn "Accepting item $line, $this_indent\n";
            my $item = $self->_collectItem($line, $this_indent);
            push @items, $item if defined $item;
#warn "Item ready $line\n";
        }
        elsif(   $this_indent==$next_indent
              && $line =~ m/^\s*(\w*)\s*(\w+)\s*\=\s*(.*)/ )
        {   # Lookup!
            my ($group, $name, $lookup) = ($1,$2,$3);
#warn "Lookup ($group, $name, $lookup)";
            my $item;   # not implemented yet
            push @items, $item if defined $item;
        }
        else
        {   # defined a field
#warn "Accepting field $line\n";
            my ($group, $name) = $line =~ m/(\w+)\s*(.*)/;
            $name =~ s/\s*$//;
            push @fields, $group => $name;
            next;
        }
    }

    return () unless @fields || @items;

#warn "$class NAME=$name";
    my $warn     = 0;
    my $warn_sub = $SIG{__WARN__};
    $SIG{__WARN__}
       = sub {$warn++; $warn_sub ? $warn_sub->(@_) : print STDERR @_};

    my $item = $class->new(name => $name, @fields);
    $SIG{__WARN__} = $warn_sub;

    if($warn)
    {   my ($source, $linenr) = $self->_location;
        $linenr -= 1;
        warn "  found in $source around line $linenr\n";
    }
#warn $_->type foreach @items;

    $item->add($_->type => $_) foreach @items;
    $item;
}


sub defaultTabStop(;$)
{   my $self = shift;
    @_ ? ($self->{UIAP_tabstop} = shift) : $self->{UIAP_tabstop};
}


sub abbreviation($;$)
{   my ($self, $name) = (shift, shift);
    return $self->{UIAP_abbrev}{$name} unless @_;

    my $class = shift;
    return delete $self->{UIAP_abbrev}{$name} unless defined $class;

    eval "require $class";
    die "Class $class is not usable, because of errors:\n$@" if $@;

    $self->{UIAP_abbrev}{$name} = $class;
}


sub abbreviations() { sort keys %{shift->{UIAP_abbrev}} }


1;

