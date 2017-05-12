/******************************************************************************
 * TAP-Formatter-HTML: default javascript for report
 * Copyright (c) 2008-2010 Steve Purkis.  All rights reserved.
 * Released under the same terms as Perl itself.
 *****************************************************************************/

jQuery.fn.extend({
  scrollTo : function(speed, easing) {
    return this.each(function() {
      var targetOffset = $(this).offset().top;
      $('html,body').animate({scrollTop: targetOffset}, speed, easing);
    });
  }
});

$(document).ready(function(){
	$("div.test-detail").hide();
	$("div#summary").find("a").click(function(){return false;});

	$("td.file").append('<div class="back-up" style="display: none">up &uarr;</div>');
	$("td.file > div.back-up").click(function(){
		$(this).parent().scrollTo(1000);
		return false;
	});

	$("td.file").hover(function(e){
		var topTd   = $(this).offset().top;
		var a       = $(this).children('a.file');
		var aHeight = $(a).height();
		// is the top of the td visible?
		if ($(window).scrollTop() > topTd + aHeight) {
		    // if (topDelta > $(window).height()) {
		    // no: show the back up link
		    var up = $(this).children('div.back-up');
		    var newTop = e.pageY - topTd - aHeight;
		    $(up).stop().hide().css({ top: newTop + 'px', opacity: '' });
		    $(up).fadeIn();
		}
	    }, function(){
		$(this).children('div.back-up').stop().fadeOut();
	    });

	// expand test detail when user clicks on a test file
	$("a.file").click(function(){
		// go all the way to the tr incase table structure changes:
		$(this).parents("tr:first").find("div.test-detail").slideToggle();
		return false;
	});

	// expand test detail when user clicks on an individual test
	$("a.TS").click(function(){
		// go all the way to the tr incase table structure changes:
		var $detail = $(this).parents("td.results").parents("tr:first").find("div.test-detail");
		$detail.filter(":hidden").slideDown();

		// highlight a particular test?
		var testId = $(this).attr("href");
		if (testId && testId != "#") {
		    var $testElem = $detail.find(testId);
		    $testElem.show().scrollTo(1000);
		    var bgColor = $testElem.css("background-color");
		    $testElem.css({ backgroundColor: "yellow" });
		    // shame you can't animate bg color w/o a plugin...
		    setTimeout(function(){$testElem.css({ backgroundColor: bgColor })}, 3000);
		}

		return false;
	});

	// set test title on mouse-over so we don't have to include it
	// in the rendered template (saves a *lot* of space)
	$("a.TS")
	    .one('mouseover',
		  function(){
		      var href = $(this).attr('href');
		      if (href && href != "#") {
			  var desc = $(href).text();
			  $(this).attr('title', desc);
		      }
		  });

	// initialize the menu
	$("#show-all").hide();
	$("#menu")
	    .show().fadeTo('fast', '0.2')
	    .hover(function(){ $(this).stop().fadeTo('fast', '0.9') },
		   function(){ $(this).stop().fadeTo('fast', '0.2') });
	$("#show-all > a")
	    .bind('click',
		  function(){
		      $('tr.passed').stop().fadeIn();
		      $('#show-all').hide();
		      $('#show-failed').show();
		      return false;
		  });
	$("#show-failed > a")
	    .bind('click',
		  function(){
		      $('tr.passed').stop().hide();
		      $('#show-failed').hide();
		      $('#show-all').show();
		      return false;
		  });

	// enable table sorting, if available:
	if ($().tablesorter) {
	    $("table.detail").tablesorter({ headers: { 1: {sorter: false} } });
	}
});
