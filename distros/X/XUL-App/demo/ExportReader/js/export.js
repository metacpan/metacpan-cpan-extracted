$(document).ready(init);

function init () {
    $("#extract-button").click( function () {
        //alert("Extracting...");
        clear();
        var readerDoc = $("#reader-browser")[0].contentDocument;
        if (!readerDoc) { alert("Browser not loaded!"); return; }
        var list = [];
        $("div.entry", readerDoc).each( function () {
            var entry = {};
            entry.title = $(".entry-title", this).text();
            entry.date = $(".entry-date", this).text();
            entry.body = $(".entry-body", this).html();
            list.push(entry);
        } );
        alert("Found " + list.length + " items");
        print(JSON.stringify(list));
    } );
}

function clear () {
    $("#output-box").val("");
}

function print (msg) {
    $("#output-box")[0].value += msg;
}

