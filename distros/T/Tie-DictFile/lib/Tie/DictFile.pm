package Tie::DictFile;

use IO::File;
use Carp;

$VERSION="0.03";

use strict;

use vars qw($AUTOLOAD $CACHE_SIZE $DEBUG $DICTIONARY $MAX_WORD_LENGTH);

$CACHE_SIZE=1024;
$DEBUG=0;
$DICTIONARY="/usr/share/dict/words";
$MAX_WORD_LENGTH=62;


#######################################################
################ PUBLIC METHODS #######################

sub TIEHASH {
    my $class = shift;
    my $dictionary = @_ ? shift : $DICTIONARY;

    my $fh = new IO::File $dictionary, "r"
        or croak "we can't open this file for reading: $dictionary, $!";
    return bless {	fh			=> $fh, 
		            dictionary	=> $dictionary}, $class ;
}


sub EXISTS {

    croak "this module can not support strings longer than $MAX_WORD_LENGTH characters"
        if(length($_[1]) > $MAX_WORD_LENGTH) ;
    
    return defined $_[0]->_fetch($_[1]);

}


sub FIRSTKEY { 

    my $self = shift;
    $self->{fh}->seek(0,SEEK_SET);
    
    my $word;
    do { 
        $word= $self->_fetch_next_line(); 
    } while (exists $self->{delete_from_file}->{lc($word)});

    return $word;
}


sub NEXTKEY { 
    my $self = shift;
    my $word;
    do { 
        $word= $self->_fetch_next_line(); 
    } while (exists $self->{delete_from_file}->{lc($word)});
    if(! defined $word) {
        my($k,$v)=each %{$self->{add_to_file}};
        if(defined $k) 
            { return $v;}
    }

    return $word;
}


sub FETCH { 
    return $_[0]->_fetch($_[1]);
}


sub STORE {
    my($self,$word,$value)=@_;

    croak "this module can not support strings longer than $MAX_WORD_LENGTH characters"
        if(length($word) > $MAX_WORD_LENGTH) ;
    
    croak "this module can not support strings containing line feed/carriage return characters"
        if($word =~ /[\r\n]/s); 
    
    croak "you cannot store empty strings with this module"
        if(! length($word));
    
    if(! defined $value) {
        $self->DELETE($word);
    } elsif(! $self->EXISTS($word)) {
        ## because we have no previous knowledge of this word, 
		## let's queue it for addition by DESTROY method
        $self->{add_to_file}->{lc($word)}=$word;
		## clean up side-effect of failed called to EXISTS
        delete $self->{not_in_file}->{lc($word)};
    }
    return $value;

}


sub DELETE {
    my $self = shift;
    my $word = shift;

    my $lcword=lc($word);
    my $found_word=undef;
    ## we looked this up earlier, and it did not
    ## exist, we don't need to do anything
    if(exists $self->{not_in_file}->{$lcword}) { 

    ## we have already asked to delete this
    ## word which DOES exist physically, do nothing
    } elsif(exists $self->{delete_from_file}->{$lcword}) { 
    
    ## this is a word which does NOT exist physically, and 
    ## was queued for addition (by DESTROY method), so let's 
    ## just remove it from the queue
    } elsif(exists $self->{add_to_file}->{$lcword}) { 
        delete $self->{add_to_file}->{$lcword};

    ## this is a word which DOES exist physically, 
    ## let's queue it for removeal (by DESTROY method)
    } elsif(exists $self->{in_file}->{$lcword}) { 
        $self->{delete_from_file}->{$lcword}=$self->{in_file}->{$lcword}[0];

    ## we don't know about thiw word, if we can look it up
    ## let's queue it for removal
    } elsif(defined ($found_word= $self->_exists_in_file($word))) { 
        $self->{delete_from_file}->{$lcword}=$found_word;
    }
    return undef;
}


sub UNTIE {
    $_[0]->DESTROY();
}

sub DESTROY {
    my $self = shift;

    if(keys %{$self->{delete_from_file}} 
		or keys %{$self->{add_to_file}}) {

		croak "requested changes to dictionary, but do not have write permissions on: " . $self->{dictionary} 
	        if(! -w $self->{dictionary});
    
        my @operations;    
        foreach my $word (sort(keys %{$self->{add_to_file}}, 
                                keys %{$self->{delete_from_file}})) {
            if(exists $self->{add_to_file}->{$word}) {
				croak "fatal error, we should have an insertion position for: $word"
                	if(! exists $self->{insert_pos}->{$word});
                push(@operations,['insert_at',
                                  $self->{insert_pos}->{$word},   
                                  $self->{add_to_file}->{$word}]);
                                   
            } else {
				croak "we should be able to find this word: $word"
	                if(! exists $self->{in_file}->{$word} && ! $self->_exists_in_file($word)) ;

                push(@operations,['copy_until', $self->{in_file}->{$word}[1] ]);
                push(@operations,['copy_from', $self->{in_file}->{$word}[2] ]);
    
            }
        
        }

        my $filename= "/tmp/" . __PACKAGE__ . ".$$";
        my $fhout = new IO::File "> $filename"
            or croak "can't write to temporary file: $filename";

        $self->{fh}->seek(0,SEEK_SET);
        my $last_position=0;
        my $size = (stat($self->{fh}))[7];

        while(@operations) {
            my $operation=shift(@operations);

            if($operation->[0] eq "insert_at") {
                if($operation->[1] > $last_position) {

                    $self->_destroy_read_write($filename,$operation->[1],$last_position,\$fhout);
                }    
                print $fhout $operation->[2],"\n";
                    
            } elsif($operation->[0] eq "copy_until") {         
                $self->_destroy_read_write($filename,$operation->[1],$last_position,\$fhout);
                    
            }

            $last_position=$operation->[1];
        }

        if($last_position < $size ) {
            $self->_destroy_read_write($filename,$size,$last_position,\$fhout,1);
    
        }
        
        undef $self->{fh};
        undef $fhout;

        $fhout=new IO::File ">" . $self->{dictionary};
        my $fhin=new IO::File "<$filename";

        while(<$fhin>) {
            print $fhout $_;
        }
                
        undef $fhout;
        undef $fhin;
        unlink $filename;
    
    
        
    }

    if($self->{fh}) {
        undef $self->{fh};    
    }

    undef $_[0];

}

######################################################
############## PRIVATE METHODS #######################

sub _fetch {
    my $self = shift;
    my $word= shift;
    
    croak "this module can not support strings longer than $MAX_WORD_LENGTH characters\n" 
        if(length($word) > $MAX_WORD_LENGTH);
    
    my $lcword=lc($word);

    ## we previously asked to add this word, return VALUE
    if(exists $self->{add_to_file}->{$lcword} ) { 
        return $self->{add_to_file}->{$lcword};
    ## we previously asked to delete this word, return UNDEF
    } elsif(exists $self->{delete_from_file}->{$lcword} ) {
        return undef;
    ## it's was recently read from file, return VALUE
    } elsif(exists $self->{in_file}->{$lcword} ) {
        return $self->{in_file}->{$lcword}[0];
    ## we looked it up before, and it didn't exist, return UNDEF
    } elsif(exists $self->{not_in_file}->{$lcword} ) {
        return undef;
    ## ok, let's actually try and look it up in the file
    } else {
        return $self->_exists_in_file($word);
    } 

}

sub _exists_in_file {
    my $self = shift;
    my $word = shift;

    my $lcword=lc($word);        

    
    my $fh = $self->{fh};
    $fh->seek(0,SEEK_SET);

      my(@stat) = stat($fh)
           or croak "could not stat filehandle";
    
    my $size = $stat[7];
    my $blksize=($MAX_WORD_LENGTH +2)*2;

       ## find the right block
       my($min, $max) = (0, int($size / $blksize));

    while ($max - $min > 1) {
        $self->_read_block_cache($lcword,\$min,\$max,$blksize);
       }
       $min *= $blksize;
       $fh->seek($min,SEEK_SET) 
			or croak "could not seek to position $min when we previously could";
            
       <$fh> if $min;
    
    my $read_word;
    my $result = undef;

    while($read_word=$self->_fetch_next_line()) {
        my $lcread_word=lc($read_word);
        next if($lcread_word lt $lcword);

        if($lcread_word eq $lcword) {
            return $read_word;
        }  else {
            $self->{not_in_file}->{$lcword}=$word;
            $self->{insert_pos}->{$lcword}=$self->{last_tell};
            return undef;
        }
    }

}

sub _fetch_next_line {
    my $self = shift;

    my $line=undef;
    $self->{last_tell}=$self->{fh}->tell();
    
    if($self->{fh} && ($line= $self->{fh}->getline)) {
        chomp $line;
        $self->_cache_insert_removable($line);
        return $line;
    } else {
        return undef;
    }
}


sub _cache_insert_removable {
    my $self = shift;
    my $word = shift;
    my $lcword=lc($word);

    if(exists $self->{in_file_a} && @{$self->{in_file_a}} == $CACHE_SIZE) { 
        my $old_word = shift(@{$self->{in_file_a}});
        delete $self->{in_file}->{$old_word};
    }

    push(@{$self->{in_file_a}},$lcword);
    $self->{in_file}->{$lcword}=[$word,$self->{last_tell},$self->{fh}->tell()];

}


sub _read_block_cache {
    my $self = shift;
    my ($word,$min,$max,$blksize)=@_;

    ## based on Jarkko Hietaniemi's Search::Dict lookup routine    
    my ($mid,$line_read);
    my $fh = $self->{fh};
       $mid = int(($$max + $$min) / 2);
    if(exists $self->{block_cache}->{$mid}) {
        $line_read =$self->{block_cache}->{$mid} ;
    } else { 

        $fh->seek($mid * $blksize, SEEK_SET)
			or croak "could not seek to position " . $mid * $blksize ;

    
        <$fh> if $mid;                  # probably a partial line
        $line_read = lc(<$fh>);
        chomp $line_read;
        $self->{block_cache}->{$mid}=$line_read ;
    }

    if (defined($line_read) && $line_read le $word) {
           $$min = $mid;
       } else {
           $$max = $mid;
    }
}

###################################################
############### PRIVATE METHODS ###################

sub _debug {

    my $level= shift;
    if($level !~ /^\d+$/) {
        unshift(@_,$level);
        $level=1;
    }    
    if($DEBUG >= $level) {
        my($sub)=(caller(1))[3];
        my $x=join("","Debugging $sub: " ,@_);
        $x.="\n" if($x !~ /\n$/);    
        print STDERR $x;
    }
}


sub _destroy_read_write {
    my($self,$filename,$byte_mark, $last_position,$reffh,$last)=@_;
    my $fhout = $$reffh;

    my $buffer;
    $self->{fh}->sysseek($last_position,SEEK_SET);
    my @args = $last ? ($byte_mark - $last_position) : ($byte_mark, $last_position);
    my $bytes = $self->{fh}->sysread($buffer,@args); 
    if($bytes != ($byte_mark-$last_position)) {
        undef $fhout;
        unlink($filename);
        croak "error reading dictionary, got unexpectedly short string";    
    }
    print $fhout $buffer;

}


## TODO

## croak in DESTROY should work (and not need subsequent returns)
## installer looks for canditate file locations 
## more efficient copy of temporary file during DESTROY

1;

__END__

=head1 NAME

Tie::DictFile - tie a hash to local dictionary file

=head1 SYNOPSIS

    use Tie::DictFile;

    tie %hash, Tie::DictFile;

    if(exists $hash{'aword'}) {
        print "aword is in dictionary\n";
    } 

    $hash{'newword'}=1;

    delete $hash{'spell'};

    untie %hash;

=head1 DESCRIPTION

Ties a hash to a local dictionary file (typically C</usr/dict/words> or C</usr/share/dict/words>)  to allow easy dictionary lookup,
insertion and deletion. Lookup operations are cached for 
performance, and any insertions/deletions are only written to the dictionary file when the hash is untied or DESTROY'ed.

By default, a hash is tied to the dictionary file
specified by C<$Tie::DictFile::DICTIONARY>. Pass
a third argument to C<tie> to specify an alternative file, eg:

    tie %hash, Tie::DictFile, '/usr/dict/words';

Dictionary lookups can either be performed by using
the C<exists> function, eg:

    exists $hash{'appetite'} ? "yes" : "no" 

or by directly attempting to fetch the hash element:

    defined $hash{'appetite'} ? "yes" : "no"

New words can be added to the dictionary by assigning any non-C<undef>
value a hash element, eg:

    $hash{'KitKat'}=1;

Words can be deleted from the dictionary, either by assigning
C<undef> to the hash element:

    $hash{'KitKat'}=undef;

or

    undef $hash{'KitKat'};

or by using the C<delete> method:

    delete $hash{'KitKat'};

When the hash is untied (or DESTROY'ed as it goes out of scope), 
the module will attempt to write the requested insertions and
deletions to the dictionary file. The module will C<croak> if the
correct write permissions have not been set.


=head2 Case sensitivity

Searches are performed in a case-insensitive manner, so 
C<$hash{'foo'}> and C<$hash{'Foo'}> return the same result.
The result will either be matching word in the dictionary file:

    $hash{'CraZy'} eq 'crazy'

or the key which was used to assign a new hash element which is 
not already present in the dictionary file, eg:

    $hash{'KitKat'}=1;

    $hash{'kitkat'] eq 'KitKat'


=head2 Options

To enhance performance, it is assumed that the dictionary has
a maximum word length of 62 characters (which biases lookups towards
more C<seek>'s against C<readline> loops). This assumption can be
changed by assigning the variable:

    $Tie::DictFile::MAX_WORD_LENGTH

Another performance enhancement is to cache any words encountered
in the dictionary file. Only the 1024 most recent words are cached.
To enhance performance (at a cost of memory), re-assign the variable:

    $Tie::DictFile::CACHE_SIZE


=head1 SEE ALSO

L<Tie::Dict>, L<Search::Dict>

=head1 AUTHOR

Alex Nunes <cpan@noptr.com>

=head1 CREDITS

Elements of the lookup code are based on 
Jarko Hietaniemi's L<Search::Dict> module.

=head1 BUGS

Does not address concurrent writes to the dictionary file.

Will not behave properly with a file whose lines are not
sorted in dictionary order.
