package YottaDB::Tie;

use YottaDB ":all";

sub TIEHASH ($;@) {
        my ($class, @args) = @_;
        bless \@args, $class;
}

sub FETCH ($$) {
        my ($self, $key) = @_;
        y_get @$self, $key;
}

sub STORE ($$$) {
        my ($self, $key, $value) = @_;
        y_set @$self, $key, $value;
}

sub DELETE ($$) {
        my ($self, $key) = @_;
        y_kill_node @$self, $key;
}

sub EXISTS ($$) {
        my ($self, $key) = @_;
        1 & y_data @$self, $key;
}

sub FIRSTKEY ($) {
        my ($self, $key) = (shift, "");
        do {
                $key = y_next @$self, $key;
        } while (defined $key && !(1 & y_data @$self, $key));
        $key;
}

sub NEXTKEY ($$) {
        my ($self, $key) = @_;
        do {
                $key = y_next @$self, $key;
        } while (defined $key && !(1 & y_data @$self, $key)); 
        $key;
}

sub CLEAR ($) {
        my ($self, $x) = (shift, "");
        y_kill_node (@$self, $x) while (defined ($x = y_next @$self, $x));
}

sub UNTIE ($) {
}

sub DESTROY ($) {
}

1;
__END__

