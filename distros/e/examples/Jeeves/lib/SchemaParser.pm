package SchemaParser;
use Ast;
use Carp;
#-----------------------------------------------------------------------------
# This file parses a schema file of the following structure:
#
# class Personnel {
#    int x,                         // Attribute type and name
#        key = 1, get = 1, set = 1; // Properties
#    double y;
# };
#
# 
# Parse() creates an abstract syntax tree and returns the root object
# of the AST in $ROOT.
# The AST looks like this ...
#     ROOT has a property called "class_list" with a list of all classes.
#     Each class has  properties "class_name" and "attr_list"
#     Each attribute is an AST node with properties "attr_name" and "attr_type"
#                                   ... Sriram
#-----------------------------------------------------------------------------
sub parse{
    my ($package, $filename) = @_;
    open (P, $filename) || die "Could not open $filename : $@";

    my $root = Ast->new("Root");

    eval {
        while (1) {
            get_line();
            next unless ($line =~ /^\s*class +(\w+)/);
            $c = Ast->new($1);
            $c->add_prop("class_name" => $1);

            $root->add_prop_list("class_list", $c);
            while (1) {
                get_line();
                last if $line =~ /^\s*}/;
                if ($line =~ s/^\s*(\w+)\s*(\w+)//) {
                    $a = Ast->new($2);  #attribute name
                    $a->add_prop ("attr_name", $2);  #attribute type
                    $a->add_prop ("attr_type", $1);  #attribute type
                    $c->add_prop_list("attr_list", $a);
                }
                $curr_line = $line;
                while ($curr_line !~ /;/) {
                    get_line();
                    $curr_line .= $line;
                }
                @props = split (/[,;]/,$curr_line);
                foreach $prop (@props) {
                    if ($prop =~ /\s*(\w*)\s*=\s*(.*)\s*/) {
                         $a->add_prop($1, $2);
                    }
                }
            }
        }
    };
    # Comes here if "END OF FILE" exception is thrown
    die $@ if ($@ &&  ($@  !~ /END OF FILE/));
    return $root;
}

sub get_line {
    while (defined($line = <P>)) {
        chomp $line;
        $line =~ s#//.*$##;          # remove comments
        return if $line !~ /^\s*$/;  # return if not white-space
    } 
    die "END OF FILE"; # Trapped by the eval above. This is a convenient
                       # way of dropping everything and jumping to the 
                       # end. Callers of get_line don't have to check for
                       # if $line is defined or not.
}

1;


