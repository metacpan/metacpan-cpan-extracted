package OO_Schema;
use Ast;
use strict;
my $line;                           # The current line from the input file
sub parse{
   shift;
	my $file_name = shift;
	my $ROOT;  
   my $c;                           # Contains the current class name
	open (P, $file_name) || die "Could not open $file_name : $@";
	$ROOT = Ast->new("Root");
	while (get_line()) {
   	next unless ($line =~ /^\s*class *(\w*)/);
		$c = Ast->new($1);
		$c->add_prop("class_name" => $1);
		$ROOT->add_prop_list("class_list", $c);
		while (get_line()) {
			last if ($line =~ /^\s*}/);
			if ($line =~ s/^\s*(\w*)\s*(\w*)//) {
				$a = Ast->new($2);  #attribute name
				$a->add_prop ("attr_name", $2);  #attribute type
				$a->add_prop ("attr_type", $1);  #attribute type
				$c->add_prop_list("attr_list", $a);
			}
			my $curr_line = $line;
			while ($curr_line !~ /;/) {
				$curr_line .= get_line();
			}
			my @props = split (/[,;]/,$curr_line);
           my $prop;
			foreach $prop (@props) {
			    	if ($prop =~ /\s*(\w*)\s*=\s*(.*)\s*/) {
					$a->add_prop($1, $2);
				}
			}
		}
	}
	return ($ROOT);
}

sub get_line {
   while ($line = <P>) {
		$line =~ s#//.*$##;            # Remove comments
		last if ($line !~ /^\s*$/);  # return non-blank line
   }
   $line;
}
1;


