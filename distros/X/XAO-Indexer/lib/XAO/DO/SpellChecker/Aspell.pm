=head1 NAME

XAO::DO::SpellChecker::Aspell -- Text::Aspell based spellchecker

=head1 SYNOPSIS

=head1 DESCRIPTION

Provides a Text::Aspell specific methods for the spellchecker.

Methods are:

=over

=cut

###############################################################################
package XAO::DO::SpellChecker::Aspell;
use strict;
use IO::File;
use Text::Aspell;
use XAO::Utils;
use XAO::Objects;
use XAO::Projects qw(get_current_project);
use base XAO::Objects->load(objname => 'SpellChecker::Base');

###############################################################################

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Aspell.pm,v 1.7 2008/05/03 02:53:12 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

sub local_spellchecker ($) {
    my $self=shift;

    my $index=$self->{'current_index'} || '_default_';
    my $checker=$self->{'checkers_cache'}->{$index};

    return $checker if $checker;

    $checker=Text::Aspell->new;

    my $options=$self->{'config'}->{'options'} || { };
    foreach my $k (keys %$options) {
        if($k eq 'master') {
            $checker->set_option(lang => $self->master_language);
            $checker->set_option($k => $self->master_filename);
        }
        elsif($k eq 'lang' && $options->{'master'}) {
            # Nothing, set with master
        }
        else {
            $checker->set_option($k => $options->{$k});
        }
    }

    return $checker;
}

###############################################################################

sub local_suggest_replacements ($$) {
    my ($self,$phrase)=@_;

    my $speller=$self->local_spellchecker;

    ##
    # Some day, when spellchecker learns to concatenate mistakenly
    # separated words, we should change this.
    #
    my %pairs;
    foreach my $word (split(/[\s[:punct:]]+/,$phrase)) {
        next unless $word =~ /^\w+$/;
        $pairs{lc($word)}=[ map { defined $_ ? (/-/ ? () : (lc)) : () } $speller->suggest($word) ];
    }

    return \%pairs;
}

###############################################################################

sub dictionary_create ($) {
    my $self=shift;

    my $filename=$self->master_filename;
    dprint ".using filename='$filename'";
    my $tmpname="$filename.tmp";

    my $lang=$self->master_language;
    my $cmd="aspell --lang $lang create master $tmpname";
    my $file=IO::File->new("|$cmd") ||
        die "Can't open pipe to '$cmd': $!";

    return {
        file        => $file,
        filename    => $filename,
        tmpname     => $tmpname,
        count       => 0,
    };
}

###############################################################################

sub dictionary_add ($$$$) {
    my ($self,$wh,$word,$count)=@_;

    return $wh->{'count'} unless $word=~/^[a-z]+$/i;

    $wh->{'file'}->print($word."\n");
    $wh->{'file'}->error &&
        throw $self "Got an error writing dictionary: $!\n";

    ++$wh->{'count'};
}

###############################################################################

sub dictionary_close ($$) {
    my ($self,$wh)=@_;

    $wh->{'file'}->close;
    if($?) {
        throw $self "dictionary_close - error building dictionary";
    }
    else {
        rename($wh->{'tmpname'},$wh->{'filename'}) ||
            throw $self "dictionary_close - error renaming the dictionary";
        dprint "Done building dictionary, words count $wh->{'count'}";
    }
}

###############################################################################

sub master_filename ($) {
    my $self=shift;

    my $filename=$self->{'config'}->{'options'}->{'master'} || return undef;

    my $lang=$self->master_language;
    $filename=~s/%L/$lang/g;

    if($filename=~/%I/) {
        my $index_id=$self->{'current_index'} ||
            throw $self "master_filename - need an 'index' for filename '$filename'";
        $filename=~s/%I/$index_id/g;
    }

    return $filename;
}

###############################################################################

sub master_language ($) {
    my $self=shift;
    return $self->{'config'}->{'options'}->{'lang'} || 'en';
}

###############################################################################
1;
__END__

=back

=head1 EXPORTS

Nothing.

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::Indexer>,
L<XAO::DO::Indexer::Base>,
L<XAO::DO::Data::Index>.

=cut
