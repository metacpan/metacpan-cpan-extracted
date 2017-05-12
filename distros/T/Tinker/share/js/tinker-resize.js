// http://jsfiddle.net/mygoare/44fKg/13/
$(function () {
  var onSampleResized = function(e) {
    var cols = $(e.currentTarget).find("td");
    var rows = $(e.currentTarget).find("tr");
    var colsize;
    var rowsize;
    cols.each(function () {
      colsize += $(this).attr('id') + "" + $(this).width() + "" + $(this).height() + ";";
    });
    rows.each(function () {
      rowsize += $(this).attr('id') + "" + $(this).width() + "" + $(this).height() + ";";
    });
    document.getElementById("hf_columndata").value = colsize;
    document.getElementById("hf_rowdata").value = rowsize;
  };
});
