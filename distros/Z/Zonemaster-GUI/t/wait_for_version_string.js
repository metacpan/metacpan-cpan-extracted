

var tickCounter = 0;
var stepRunnerStatus = { "stepRunnerCounter": 0, "stepRunning": false};
var steps = [
	{"method": "WAIT_FOR_XPATH", "xpath": "//a[contains(., 'FAQ')]", "time_seconds": 5}, // PhantomJS bug workaraound
	{"method": "CLICK_NODE", "xpath": "//a[contains(., 'FAQ')]"},     // PhantomJS bug workaraound
	{"method": "WAIT_FOR_XPATH", "xpath": "//div[@version and contains(., 'TRAVIS')]", "time_seconds": 5},
//	{"method": "SLEEP", "time": 5 },
];


function moveToNextStep () {
	stepRunnerStatus["stepRunning"] = false;
	stepRunnerStatus["stepRunnerCounter"]++;
};

function sleep (time_seconds) {
	setTimeout(function() {
		moveToNextStep();
	}, steps[stepRunnerStatus["stepRunnerCounter"]]["time"] * 1000);
};

function waitForXPath(xpath, time_secs) {
	var maxtimeOutMillis = time_secs ? time_secs*1000 : 60000, 
		start = new Date().getTime(),
		condition = false,
		interval = setInterval(function() {
//			console.log('Stripped down page text:\n' + page.plainText);
			if ( (new Date().getTime() - start < maxtimeOutMillis) && !condition ) {
				// If not time-out yet and condition not yet fulfilled
				var testFx = function(path) {
					return page.evaluate(function(path) {
						var getElementByXpath = function () {
							return document.evaluate(path, document, null, 9, null).singleNodeValue;
						};
						
						return (getElementByXpath(path) ? true : false);
					}, path);
				}
				
				condition = testFx(xpath);
			} else {
				if(!condition) {
					// If condition still not fulfilled (timeout but condition is 'false')
					console.log("WAIT_FOR_XPATH:["+xpath+"] TIMEOUT");
					phantom.exit(1);
				} else {
					console.log("WAIT_FOR_XPATH:["+xpath+"] Finished");
					moveToNextStep();
					clearInterval(interval); //< Stop this interval
				}
			}
		}, 500); //< repeat check every 250ms
};

function clickNode (xpath) {
	page.evaluate(function (xpath) {
		var getElementByXpath = function (path) {
			return document.evaluate(path, document, null, 9, null).singleNodeValue;
		};
						
		var clickNode = function click(el){
			var ev = document.createEvent("MouseEvent");
			ev.initMouseEvent("click", true, true, window, null, 0, 0, 0, 0, false, false, false, false, 0, null);
			el.dispatchEvent(ev);
		};

		var element = getElementByXpath(xpath);
		if (element) {
			clickNode(element);
			console.log('Clicked on XPath -> '+xpath);
		}
		else {
			console.log('Element with XPath -> '+xpath+' NOT FOUND');
		}
		
		return;
	}, xpath );
	
	moveToNextStep();
}

var system = require('system');
if (system.args.length === 1) {
    console.log('This script requires the hostname:port of the Zonemaster server as parameter');
	phantom.exit(1);
}
else {
	var page = require('webpage').create();
	var url = 'http://'+system.args[1]+'/';

	page.onError = function (msg, trace) {
		console.log(msg);
		trace.forEach(function(item) {
			console.log('  ', item.file, ':', item.line);
		});
	};
	
	page.onConsoleMessage = function(msg) {
		system.stdout.writeLine('page.evaluate console: ' + msg);
	};

	page.open(url, function (status) {
		// Check for page load success
		if (status !== "success") {
			console.log("Unable to access network");
		} else {
			var interval = setInterval(function() {
				if (tickCounter < 100) {
					tickCounter++;
					if (!stepRunnerStatus["stepRunning"]) {
						if (stepRunnerStatus["stepRunnerCounter"] < steps.length) {
							console.log("["+tickCounter+"]No step currently executing");
							stepRunnerStatus["stepRunning"] = true;

							if (steps[stepRunnerStatus["stepRunnerCounter"]]["method"] == "SLEEP") {
								sleep(5);
							}
							else if (steps[stepRunnerStatus["stepRunnerCounter"]]["method"] == "WAIT_FOR_XPATH") {
								waitForXPath(steps[stepRunnerStatus["stepRunnerCounter"]]["xpath"], steps[stepRunnerStatus["stepRunnerCounter"]]["time_seconds"]);
							}
							else if (steps[stepRunnerStatus["stepRunnerCounter"]]["method"] == "CLICK_NODE") {
								clickNode(steps[stepRunnerStatus["stepRunnerCounter"]]["xpath"]);
							}
							else {
								console.log("UNKNOWN METHOD: "+steps[stepRunnerStatus["stepRunnerCounter"]]["method"]);
								phantom.exit(1);
							}
						}
						else {
							console.log("["+tickCounter+"]All steps executed: DONE");
							phantom.exit(0);
						}
					}
					else {
						console.log("["+tickCounter+"]Executing setp: "+stepRunnerStatus["stepRunnerCounter"]+" -> "+steps[stepRunnerStatus["stepRunnerCounter"]]["method"]);
					}
				}
				else {
					console.log("tickCounter:EXPIRED");
					clearInterval(interval);
					phantom.exit(1);
				}
			}
			, 1000);
		}
	});
}

