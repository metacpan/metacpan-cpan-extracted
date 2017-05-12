( function($) {

    function msort(array, compare) {
        if(array.length < 2)
            return array;
        var middle = Math.ceil(array.length/2);
        return _merge(  msort(array.slice(0,middle),compare),
                        msort(array.slice(middle),compare),
                        compare);

        function _merge(left, right, compare) {
            var result = [];
            while((left.length > 0) && (right.length > 0)) {
                if(compare(left[0],right[0]) <= 0)
                    result.push(left.shift());
                else
                    result.push(right.shift());
            }
            while (left.length > 0)
                result.push(left.shift());
            while (right.length > 0)
                result.push(right.shift());
            return result;
        }
    }

    $.fn.sortableTable = function() {
        this.each(function() {
            var $table = $(this);
            if (! $table.is('table')) {
                return; // Only works for tables
            }
            var sorted_column;
            $table.on('click', 'th', function(e) {
                var $th = $(e.currentTarget),
                    index = $th.index()+1,
                    rows = $table.find('tbody tr');

                rows = msort(rows.get(), function(a,b) {
                    var selector = 'td:nth-child('+index+')';
                    var a_text = $(a).find(selector).text().replace(/^\s+|\s+$/g,''),

                        b_text = $(b).find(selector).text().replace(/^\s+|\s+$/g,'');
                    var sort_result = a_text.localeCompare(b_text);
                    if (index === sorted_column) {
                        // Already sorted by this column, do a reverse sort
                        sort_result = 0-sort_result;
                    }
                    return sort_result;
                });

                // Update the sorted column.  If we just did a reverse sort, then
                // forget the previous sorted column so that if the user clicks
                // the same column yet again, they'll get that same column sorted
                // the normal way
                sorted_column = ( index === sorted_column ) ? undefined : index
                
                var $last;
                rows.forEach(function(tr) {
                    var $tr = $(tr);
                    if ($last) {
                        $last.after($tr);
                    } else {
                        $table.find('tbody').prepend($tr);
                    }
                    $last = $tr;
                });
            });
        });
    };
})(jQuery);
