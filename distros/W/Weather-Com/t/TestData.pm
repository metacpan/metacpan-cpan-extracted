#
# Test data for Weather::Com::Base and ::Cached location search
#
$NY_HTML = <<END;
<?xml version="1.0" encoding="ISO-8859-1"?>
<search ver="2.0">
  <loc id="USNY0996" type="1">New York, NY</loc>
  <loc id="USNY0998" type="1">New York/Central Park, NY</loc>
  <loc id="USNY0999" type="1">New York/JFK Intl Arpt, NY</loc>
  <loc id="USNY1000" type="1">New York/La Guardia Arpt, NY</loc>
</search>
END

$NY_Hash = {
			 'USNY0996' => 'New York, NY',
			 'USNY0998' => 'New York/Central Park, NY',
			 'USNY0999' => 'New York/JFK Intl Arpt, NY',
			 'USNY1000' => 'New York/La Guardia Arpt, NY',
};

#
# HTML returned by a seach for NY, Central Park with 10 days forecast
#
$NYCP_HTML = <<NYCP;
<?xml version="1.0" encoding="ISO-8859-1"?>
<!--This document is intended only for use by authorized licensees of The Weather Channel. Unauthorized use is prohibited. Copyright 1995-2004, The Weather Channel Enterprises, Inc. All Rights Reserved.-->
<weather ver="2.0">
  <head>
    <locale>en_US</locale>
    <form>MEDIUM</form>
    <ut>C</ut>
    <ud>km</ud>
    <us>km/h</us>
    <up>mb</up>
    <ur>mm</ur>
  </head>
  <loc id="USNY0998">
    <dnam>New York/Central Park, NY</dnam>
    <tm>5:35 PM</tm>
    <lat>40.79</lat>
    <lon>-73.96</lon>
    <sunr>6:08 AM</sunr>
    <suns>7:42 PM</suns>
    <zone>-4</zone>
  </loc>
  <lnks type="prmo">
    <link pos="1">
      <l>http://www.weather.com/outlook/health/allergies/USNY0998?par=xoap</l>
      <t>Pollen Reports</t>
    </link>
    <link pos="2">
      <l>http://www.weather.com/outlook/travel/flights/citywx/USNY0998?par=xoap</l>
      <t>Airport Delays</t>
    </link>
    <link pos="3">
      <l>http://www.weather.com/outlook/events/special/result/USNY0998?when=thisweek&amp;par=xoap</l>
      <t>Special Events</t>
    </link>
    <link pos="4">
      <l>http://www.weather.com/services/desktop.html?par=xoap</l>
      <t>Download Desktop Weather</t>
    </link>
  </lnks>
  <cc>
    <lsup>4/21/05 4:51 PM EDT</lsup>
    <obst>Central Park, NY</obst>
    <tmp>14</tmp>
    <flik>10</flik>
    <t>Fair</t>
    <icon>34</icon>
    <bar>
      <r>1,014.6</r>
      <d>steady</d>
    </bar>
    <wind>
      <s>19</s>
      <gust>29</gust>
      <d>160</d>
      <t>SSE</t>
    </wind>
    <hmid>62</hmid>
    <vis>16.1</vis>
    <uv>
      <i>2</i>
      <t>Low</t>
    </uv>
    <dewp>7</dewp>
    <moon>
      <icon>12</icon>
      <t>Waxing Gibbous</t>
    </moon>
  </cc>
  <dayf>
    <lsup>4/21/05 5:03 PM EDT</lsup>
    <day d="0" t="Thursday" dt="Apr 21">
      <hi>N/A</hi>
      <low>8</low>
      <sunr>6:08 AM</sunr>
      <suns>7:42 PM</suns>
      <part p="d">
        <icon>44</icon>
        <t>N/A</t>
        <wind>
          <s>N/A</s>
          <gust>N/A</gust>
          <d>N/A</d>
          <t>N/A</t>
        </wind>
        <bt>N/A</bt>
        <ppcp>10</ppcp>
        <hmid>N/A</hmid>
      </part>
      <part p="n">
        <icon>33</icon>
        <t>Mostly Clear</t>
        <wind>
          <s>13</s>
          <gust>N/A</gust>
          <d>153</d>
          <t>SSE</t>
        </wind>
        <bt>M Clear</bt>
        <ppcp>10</ppcp>
        <hmid>55</hmid>
      </part>
    </day>
    <day d="1" t="Friday" dt="Apr 22">
      <hi>16</hi>
      <low>11</low>
      <sunr>6:06 AM</sunr>
      <suns>7:43 PM</suns>
      <part p="d">
        <icon>30</icon>
        <t>Partly Cloudy</t>
        <wind>
          <s>18</s>
          <gust>N/A</gust>
          <d>139</d>
          <t>SE</t>
        </wind>
        <bt>P Cloudy</bt>
        <ppcp>10</ppcp>
        <hmid>44</hmid>
      </part>
      <part p="n">
        <icon>12</icon>
        <t>Rain</t>
        <wind>
          <s>29</s>
          <gust>N/A</gust>
          <d>104</d>
          <t>ESE</t>
        </wind>
        <bt>Rain</bt>
        <ppcp>80</ppcp>
        <hmid>69</hmid>
      </part>
    </day>
    <day d="2" t="Saturday" dt="Apr 23">
      <hi>18</hi>
      <low>11</low>
      <sunr>6:05 AM</sunr>
      <suns>7:44 PM</suns>
      <part p="d">
        <icon>12</icon>
        <t>Rain</t>
        <wind>
          <s>27</s>
          <gust>N/A</gust>
          <d>148</d>
          <t>SSE</t>
        </wind>
        <bt>Rain</bt>
        <ppcp>80</ppcp>
        <hmid>70</hmid>
      </part>
      <part p="n">
        <icon>11</icon>
        <t>Light Rain</t>
        <wind>
          <s>11</s>
          <gust>N/A</gust>
          <d>62</d>
          <t>ENE</t>
        </wind>
        <bt>Light Rain</bt>
        <ppcp>60</ppcp>
        <hmid>61</hmid>
      </part>
    </day>
    <day d="3" t="Sunday" dt="Apr 24">
      <hi>13</hi>
      <low>6</low>
      <sunr>6:03 AM</sunr>
      <suns>7:45 PM</suns>
      <part p="d">
        <icon>11</icon>
        <t>Few Showers</t>
        <wind>
          <s>16</s>
          <gust>N/A</gust>
          <d>22</d>
          <t>NNE</t>
        </wind>
        <bt>Few Showers</bt>
        <ppcp>30</ppcp>
        <hmid>47</hmid>
      </part>
      <part p="n">
        <icon>29</icon>
        <t>Partly Cloudy</t>
        <wind>
          <s>8</s>
          <gust>N/A</gust>
          <d>349</d>
          <t>N</t>
        </wind>
        <bt>P Cloudy</bt>
        <ppcp>10</ppcp>
        <hmid>53</hmid>
      </part>
    </day>
    <day d="4" t="Monday" dt="Apr 25">
      <hi>11</hi>
      <low>7</low>
      <sunr>6:02 AM</sunr>
      <suns>7:46 PM</suns>
      <part p="d">
        <icon>11</icon>
        <t>Showers</t>
        <wind>
          <s>11</s>
          <gust>N/A</gust>
          <d>59</d>
          <t>ENE</t>
        </wind>
        <bt>Showers</bt>
        <ppcp>40</ppcp>
        <hmid>48</hmid>
      </part>
      <part p="n">
        <icon>29</icon>
        <t>Partly Cloudy</t>
        <wind>
          <s>8</s>
          <gust>N/A</gust>
          <d>162</d>
          <t>SSE</t>
        </wind>
        <bt>P Cloudy</bt>
        <ppcp>10</ppcp>
        <hmid>53</hmid>
      </part>
    </day>
    <day d="5" t="Tuesday" dt="Apr 26">
      <hi>13</hi>
      <low>9</low>
      <sunr>6:01 AM</sunr>
      <suns>7:47 PM</suns>
      <part p="d">
        <icon>30</icon>
        <t>Partly Cloudy</t>
        <wind>
          <s>10</s>
          <gust>N/A</gust>
          <d>197</d>
          <t>SSW</t>
        </wind>
        <bt>P Cloudy</bt>
        <ppcp>20</ppcp>
        <hmid>50</hmid>
      </part>
      <part p="n">
        <icon>33</icon>
        <t>Mostly Clear</t>
        <wind>
          <s>5</s>
          <gust>N/A</gust>
          <d>264</d>
          <t>W</t>
        </wind>
        <bt>M Clear</bt>
        <ppcp>10</ppcp>
        <hmid>54</hmid>
      </part>
    </day>
    <day d="6" t="Wednesday" dt="Apr 27">
      <hi>17</hi>
      <low>11</low>
      <sunr>5:59 AM</sunr>
      <suns>7:48 PM</suns>
      <part p="d">
        <icon>11</icon>
        <t>Few Showers</t>
        <wind>
          <s>10</s>
          <gust>N/A</gust>
          <d>106</d>
          <t>ESE</t>
        </wind>
        <bt>Few Showers</bt>
        <ppcp>30</ppcp>
        <hmid>52</hmid>
      </part>
      <part p="n">
        <icon>12</icon>
        <t>Rain</t>
        <wind>
          <s>10</s>
          <gust>N/A</gust>
          <d>170</d>
          <t>S</t>
        </wind>
        <bt>Rain</bt>
        <ppcp>60</ppcp>
        <hmid>60</hmid>
      </part>
    </day>
    <day d="7" t="Thursday" dt="Apr 28">
      <hi>14</hi>
      <low>9</low>
      <sunr>5:58 AM</sunr>
      <suns>7:49 PM</suns>
      <part p="d">
        <icon>11</icon>
        <t>Few Showers</t>
        <wind>
          <s>11</s>
          <gust>N/A</gust>
          <d>254</d>
          <t>WSW</t>
        </wind>
        <bt>Few Showers</bt>
        <ppcp>30</ppcp>
        <hmid>52</hmid>
      </part>
      <part p="n">
        <icon>29</icon>
        <t>Partly Cloudy</t>
        <wind>
          <s>10</s>
          <gust>N/A</gust>
          <d>240</d>
          <t>WSW</t>
        </wind>
        <bt>P Cloudy</bt>
        <ppcp>20</ppcp>
        <hmid>55</hmid>
      </part>
    </day>
    <day d="8" t="Friday" dt="Apr 29">
      <hi>16</hi>
      <low>10</low>
      <sunr>5:57 AM</sunr>
      <suns>7:50 PM</suns>
      <part p="d">
        <icon>30</icon>
        <t>Partly Cloudy</t>
        <wind>
          <s>13</s>
          <gust>N/A</gust>
          <d>237</d>
          <t>WSW</t>
        </wind>
        <bt>P Cloudy</bt>
        <ppcp>20</ppcp>
        <hmid>51</hmid>
      </part>
      <part p="n">
        <icon>11</icon>
        <t>Light Rain</t>
        <wind>
          <s>8</s>
          <gust>N/A</gust>
          <d>284</d>
          <t>WNW</t>
        </wind>
        <bt>Light Rain</bt>
        <ppcp>60</ppcp>
        <hmid>60</hmid>
      </part>
    </day>
    <day d="9" t="Saturday" dt="Apr 30">
      <hi>17</hi>
      <low>11</low>
      <sunr>5:56 AM</sunr>
      <suns>7:51 PM</suns>
      <part p="d">
        <icon>11</icon>
        <t>Light Rain</t>
        <wind>
          <s>11</s>
          <gust>N/A</gust>
          <d>358</d>
          <t>N</t>
        </wind>
        <bt>Light Rain</bt>
        <ppcp>60</ppcp>
        <hmid>53</hmid>
      </part>
      <part p="n">
        <icon>29</icon>
        <t>Partly Cloudy</t>
        <wind>
          <s>10</s>
          <gust>N/A</gust>
          <d>217</d>
          <t>SW</t>
        </wind>
        <bt>P Cloudy</bt>
        <ppcp>20</ppcp>
        <hmid>58</hmid>
      </part>
    </day>
  </dayf>
</weather>
NYCP

#
# Hash corresponding to HTML returned by a seach for
# NY, Central Park with 10 days forecast
#
$NYCP_Hash = {
	'dayf' => {
				'lsup' => '4/21/05 5:03 PM EDT',
				'day'  => [
						   {
							 'hi'   => 'N/A',
							 'suns' => '7:42 PM',
							 'dt'   => 'Apr 21',
							 'part' => [
										 {
										   'hmid' => 'N/A',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => 'N/A',
													   's'    => 'N/A',
													   't'    => 'N/A'
										   },
										   'icon' => '44',
										   'p'    => 'd',
										   'ppcp' => '10',
										   'bt'   => 'N/A',
										   't'    => 'N/A'
										 },
										 {
										   'hmid' => '55',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '153',
													   's'    => '13',
													   't'    => 'SSE'
										   },
										   'icon' => '33',
										   'p'    => 'n',
										   'ppcp' => '10',
										   'bt'   => 'M Clear',
										   't'    => 'Mostly Clear'
										 }
							 ],
							 'd'    => '0',
							 'sunr' => '6:08 AM',
							 'low'  => '8',
							 't'    => 'Thursday'
						   },
						   {
							 'hi'   => '16',
							 'suns' => '7:43 PM',
							 'dt'   => 'Apr 22',
							 'part' => [
										 {
										   'hmid' => '44',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '139',
													   's'    => '18',
													   't'    => 'SE'
										   },
										   'icon' => '30',
										   'p'    => 'd',
										   'ppcp' => '10',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 },
										 {
										   'hmid' => '69',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '104',
													   's'    => '29',
													   't'    => 'ESE'
										   },
										   'icon' => '12',
										   'p'    => 'n',
										   'ppcp' => '80',
										   'bt'   => 'Rain',
										   't'    => 'Rain'
										 }
							 ],
							 'd'    => '1',
							 'sunr' => '6:06 AM',
							 'low'  => '11',
							 't'    => 'Friday'
						   },
						   {
							 'hi'   => '18',
							 'suns' => '7:44 PM',
							 'dt'   => 'Apr 23',
							 'part' => [
										 {
										   'hmid' => '70',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '148',
													   's'    => '27',
													   't'    => 'SSE'
										   },
										   'icon' => '12',
										   'p'    => 'd',
										   'ppcp' => '80',
										   'bt'   => 'Rain',
										   't'    => 'Rain'
										 },
										 {
										   'hmid' => '61',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '62',
													   's'    => '11',
													   't'    => 'ENE'
										   },
										   'icon' => '11',
										   'p'    => 'n',
										   'ppcp' => '60',
										   'bt'   => 'Light Rain',
										   't'    => 'Light Rain'
										 }
							 ],
							 'd'    => '2',
							 'sunr' => '6:05 AM',
							 'low'  => '11',
							 't'    => 'Saturday'
						   },
						   {
							 'hi'   => '13',
							 'suns' => '7:45 PM',
							 'dt'   => 'Apr 24',
							 'part' => [
										 {
										   'hmid' => '47',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '22',
													   's'    => '16',
													   't'    => 'NNE'
										   },
										   'icon' => '11',
										   'p'    => 'd',
										   'ppcp' => '30',
										   'bt'   => 'Few Showers',
										   't'    => 'Few Showers'
										 },
										 {
										   'hmid' => '53',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '349',
													   's'    => '8',
													   't'    => 'N'
										   },
										   'icon' => '29',
										   'p'    => 'n',
										   'ppcp' => '10',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 }
							 ],
							 'd'    => '3',
							 'sunr' => '6:03 AM',
							 'low'  => '6',
							 't'    => 'Sunday'
						   },
						   {
							 'hi'   => '11',
							 'suns' => '7:46 PM',
							 'dt'   => 'Apr 25',
							 'part' => [
										 {
										   'hmid' => '48',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '59',
													   's'    => '11',
													   't'    => 'ENE'
										   },
										   'icon' => '11',
										   'p'    => 'd',
										   'ppcp' => '40',
										   'bt'   => 'Showers',
										   't'    => 'Showers'
										 },
										 {
										   'hmid' => '53',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '162',
													   's'    => '8',
													   't'    => 'SSE'
										   },
										   'icon' => '29',
										   'p'    => 'n',
										   'ppcp' => '10',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 }
							 ],
							 'd'    => '4',
							 'sunr' => '6:02 AM',
							 'low'  => '7',
							 't'    => 'Monday'
						   },
						   {
							 'hi'   => '13',
							 'suns' => '7:47 PM',
							 'dt'   => 'Apr 26',
							 'part' => [
										 {
										   'hmid' => '50',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '197',
													   's'    => '10',
													   't'    => 'SSW'
										   },
										   'icon' => '30',
										   'p'    => 'd',
										   'ppcp' => '20',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 },
										 {
										   'hmid' => '54',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '264',
													   's'    => '5',
													   't'    => 'W'
										   },
										   'icon' => '33',
										   'p'    => 'n',
										   'ppcp' => '10',
										   'bt'   => 'M Clear',
										   't'    => 'Mostly Clear'
										 }
							 ],
							 'd'    => '5',
							 'sunr' => '6:01 AM',
							 'low'  => '9',
							 't'    => 'Tuesday'
						   },
						   {
							 'hi'   => '17',
							 'suns' => '7:48 PM',
							 'dt'   => 'Apr 27',
							 'part' => [
										 {
										   'hmid' => '52',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '106',
													   's'    => '10',
													   't'    => 'ESE'
										   },
										   'icon' => '11',
										   'p'    => 'd',
										   'ppcp' => '30',
										   'bt'   => 'Few Showers',
										   't'    => 'Few Showers'
										 },
										 {
										   'hmid' => '60',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '170',
													   's'    => '10',
													   't'    => 'S'
										   },
										   'icon' => '12',
										   'p'    => 'n',
										   'ppcp' => '60',
										   'bt'   => 'Rain',
										   't'    => 'Rain'
										 }
							 ],
							 'd'    => '6',
							 'sunr' => '5:59 AM',
							 'low'  => '11',
							 't'    => 'Wednesday'
						   },
						   {
							 'hi'   => '14',
							 'suns' => '7:49 PM',
							 'dt'   => 'Apr 28',
							 'part' => [
										 {
										   'hmid' => '52',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '254',
													   's'    => '11',
													   't'    => 'WSW'
										   },
										   'icon' => '11',
										   'p'    => 'd',
										   'ppcp' => '30',
										   'bt'   => 'Few Showers',
										   't'    => 'Few Showers'
										 },
										 {
										   'hmid' => '55',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '240',
													   's'    => '10',
													   't'    => 'WSW'
										   },
										   'icon' => '29',
										   'p'    => 'n',
										   'ppcp' => '20',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 }
							 ],
							 'd'    => '7',
							 'sunr' => '5:58 AM',
							 'low'  => '9',
							 't'    => 'Thursday'
						   },
						   {
							 'hi'   => '16',
							 'suns' => '7:50 PM',
							 'dt'   => 'Apr 29',
							 'part' => [
										 {
										   'hmid' => '51',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '237',
													   's'    => '13',
													   't'    => 'WSW'
										   },
										   'icon' => '30',
										   'p'    => 'd',
										   'ppcp' => '20',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 },
										 {
										   'hmid' => '60',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '284',
													   's'    => '8',
													   't'    => 'WNW'
										   },
										   'icon' => '11',
										   'p'    => 'n',
										   'ppcp' => '60',
										   'bt'   => 'Light Rain',
										   't'    => 'Light Rain'
										 }
							 ],
							 'd'    => '8',
							 'sunr' => '5:57 AM',
							 'low'  => '10',
							 't'    => 'Friday'
						   },
						   {
							 'hi'   => '17',
							 'suns' => '7:51 PM',
							 'dt'   => 'Apr 30',
							 'part' => [
										 {
										   'hmid' => '53',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '358',
													   's'    => '11',
													   't'    => 'N'
										   },
										   'icon' => '11',
										   'p'    => 'd',
										   'ppcp' => '60',
										   'bt'   => 'Light Rain',
										   't'    => 'Light Rain'
										 },
										 {
										   'hmid' => '58',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '217',
													   's'    => '10',
													   't'    => 'SW'
										   },
										   'icon' => '29',
										   'p'    => 'n',
										   'ppcp' => '20',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 }
							 ],
							 'd'    => '9',
							 'sunr' => '5:56 AM',
							 'low'  => '11',
							 't'    => 'Saturday'
						   }
				]
	},
	'head' => {
				'ur'     => 'mm',
				'ud'     => 'km',
				'us'     => 'km/h',
				'form'   => 'MEDIUM',
				'up'     => 'mb',
				'locale' => 'en_US',
				'ut'     => 'C',
	},
	'cc' => {
			  'icon' => '34',
			  'flik' => '10',
			  'obst' => 'Central Park, NY',
			  'lsup' => '4/21/05 4:51 PM EDT',
			  'tmp'  => '14',
			  'hmid' => '62',
			  'wind' => {
						  'gust' => '29',
						  'd'    => '160',
						  's'    => '19',
						  't'    => 'SSE'
			  },
			  'bar' => {
						 'r' => '1,014.6',
						 'd' => 'steady'
			  },
			  'moon' => {
						  'icon' => '12',
						  't'    => 'Waxing Gibbous'
			  },
			  'dewp' => '7',
			  'uv'   => {
						't' => 'Low',
						'i' => '2'
			  },
			  'vis' => '16.1',
			  't'   => 'Fair'
	},
	'lnks' => {
		'link' => [
			{
			   'l' =>
'http://www.weather.com/outlook/health/allergies/USNY0998?par=xoap',
			   'pos' => '1',
			   't'   => 'Pollen Reports'
			},
			{
			   'l' =>
'http://www.weather.com/outlook/travel/flights/citywx/USNY0998?par=xoap',
			   'pos' => '2',
			   't'   => 'Airport Delays'
			},
			{
			   'l' =>
'http://www.weather.com/outlook/events/special/result/USNY0998?when=thisweek&par=xoap',
			   'pos' => '3',
			   't'   => 'Special Events'
			},
			{
			   'l'   => 'http://www.weather.com/services/desktop.html?par=xoap',
			   'pos' => '4',
			   't'   => 'Download Desktop Weather'
			}
		],
		'type' => 'prmo'
	},
	'loc' => {
			   'suns' => '7:42 PM',
			   'zone' => '-4',
			   'lat'  => '40.79',
			   'tm'   => '5:35 PM',
			   'sunr' => '6:08 AM',
			   'dnam' => 'New York/Central Park, NY',
			   'id'   => 'USNY0998',
			   'lon'  => '-73.96'
	},
	'ver' => '2.0'
};

#
# Hash corresponding to HTML returned by a seach for
# NY, Central Park with 10 days forecast
#
$NYCP_HashCached = {
	'dayf' => {
				'lsup'   => '4/21/05 5:03 PM EDT',
				'cached' => '1110000000',
				'day'    => [
						   {
							 'hi'   => 'N/A',
							 'suns' => '7:42 PM',
							 'dt'   => 'Apr 21',
							 'part' => [
										 {
										   'hmid' => 'N/A',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => 'N/A',
													   's'    => 'N/A',
													   't'    => 'N/A'
										   },
										   'icon' => '44',
										   'p'    => 'd',
										   'ppcp' => '10',
										   'bt'   => 'N/A',
										   't'    => 'N/A'
										 },
										 {
										   'hmid' => '55',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '153',
													   's'    => '13',
													   't'    => 'SSE'
										   },
										   'icon' => '33',
										   'p'    => 'n',
										   'ppcp' => '10',
										   'bt'   => 'M Clear',
										   't'    => 'Mostly Clear'
										 }
							 ],
							 'd'    => '0',
							 'sunr' => '6:08 AM',
							 'low'  => '8',
							 't'    => 'Thursday'
						   },
						   {
							 'hi'   => '16',
							 'suns' => '7:43 PM',
							 'dt'   => 'Apr 22',
							 'part' => [
										 {
										   'hmid' => '44',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '139',
													   's'    => '18',
													   't'    => 'SE'
										   },
										   'icon' => '30',
										   'p'    => 'd',
										   'ppcp' => '10',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 },
										 {
										   'hmid' => '69',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '104',
													   's'    => '29',
													   't'    => 'ESE'
										   },
										   'icon' => '12',
										   'p'    => 'n',
										   'ppcp' => '80',
										   'bt'   => 'Rain',
										   't'    => 'Rain'
										 }
							 ],
							 'd'    => '1',
							 'sunr' => '6:06 AM',
							 'low'  => '11',
							 't'    => 'Friday'
						   },
						   {
							 'hi'   => '18',
							 'suns' => '7:44 PM',
							 'dt'   => 'Apr 23',
							 'part' => [
										 {
										   'hmid' => '70',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '148',
													   's'    => '27',
													   't'    => 'SSE'
										   },
										   'icon' => '12',
										   'p'    => 'd',
										   'ppcp' => '80',
										   'bt'   => 'Rain',
										   't'    => 'Rain'
										 },
										 {
										   'hmid' => '61',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '62',
													   's'    => '11',
													   't'    => 'ENE'
										   },
										   'icon' => '11',
										   'p'    => 'n',
										   'ppcp' => '60',
										   'bt'   => 'Light Rain',
										   't'    => 'Light Rain'
										 }
							 ],
							 'd'    => '2',
							 'sunr' => '6:05 AM',
							 'low'  => '11',
							 't'    => 'Saturday'
						   },
						   {
							 'hi'   => '13',
							 'suns' => '7:45 PM',
							 'dt'   => 'Apr 24',
							 'part' => [
										 {
										   'hmid' => '47',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '22',
													   's'    => '16',
													   't'    => 'NNE'
										   },
										   'icon' => '11',
										   'p'    => 'd',
										   'ppcp' => '30',
										   'bt'   => 'Few Showers',
										   't'    => 'Few Showers'
										 },
										 {
										   'hmid' => '53',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '349',
													   's'    => '8',
													   't'    => 'N'
										   },
										   'icon' => '29',
										   'p'    => 'n',
										   'ppcp' => '10',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 }
							 ],
							 'd'    => '3',
							 'sunr' => '6:03 AM',
							 'low'  => '6',
							 't'    => 'Sunday'
						   },
						   {
							 'hi'   => '11',
							 'suns' => '7:46 PM',
							 'dt'   => 'Apr 25',
							 'part' => [
										 {
										   'hmid' => '48',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '59',
													   's'    => '11',
													   't'    => 'ENE'
										   },
										   'icon' => '11',
										   'p'    => 'd',
										   'ppcp' => '40',
										   'bt'   => 'Showers',
										   't'    => 'Showers'
										 },
										 {
										   'hmid' => '53',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '162',
													   's'    => '8',
													   't'    => 'SSE'
										   },
										   'icon' => '29',
										   'p'    => 'n',
										   'ppcp' => '10',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 }
							 ],
							 'd'    => '4',
							 'sunr' => '6:02 AM',
							 'low'  => '7',
							 't'    => 'Monday'
						   },
						   {
							 'hi'   => '13',
							 'suns' => '7:47 PM',
							 'dt'   => 'Apr 26',
							 'part' => [
										 {
										   'hmid' => '50',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '197',
													   's'    => '10',
													   't'    => 'SSW'
										   },
										   'icon' => '30',
										   'p'    => 'd',
										   'ppcp' => '20',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 },
										 {
										   'hmid' => '54',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '264',
													   's'    => '5',
													   't'    => 'W'
										   },
										   'icon' => '33',
										   'p'    => 'n',
										   'ppcp' => '10',
										   'bt'   => 'M Clear',
										   't'    => 'Mostly Clear'
										 }
							 ],
							 'd'    => '5',
							 'sunr' => '6:01 AM',
							 'low'  => '9',
							 't'    => 'Tuesday'
						   },
						   {
							 'hi'   => '17',
							 'suns' => '7:48 PM',
							 'dt'   => 'Apr 27',
							 'part' => [
										 {
										   'hmid' => '52',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '106',
													   's'    => '10',
													   't'    => 'ESE'
										   },
										   'icon' => '11',
										   'p'    => 'd',
										   'ppcp' => '30',
										   'bt'   => 'Few Showers',
										   't'    => 'Few Showers'
										 },
										 {
										   'hmid' => '60',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '170',
													   's'    => '10',
													   't'    => 'S'
										   },
										   'icon' => '12',
										   'p'    => 'n',
										   'ppcp' => '60',
										   'bt'   => 'Rain',
										   't'    => 'Rain'
										 }
							 ],
							 'd'    => '6',
							 'sunr' => '5:59 AM',
							 'low'  => '11',
							 't'    => 'Wednesday'
						   },
						   {
							 'hi'   => '14',
							 'suns' => '7:49 PM',
							 'dt'   => 'Apr 28',
							 'part' => [
										 {
										   'hmid' => '52',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '254',
													   's'    => '11',
													   't'    => 'WSW'
										   },
										   'icon' => '11',
										   'p'    => 'd',
										   'ppcp' => '30',
										   'bt'   => 'Few Showers',
										   't'    => 'Few Showers'
										 },
										 {
										   'hmid' => '55',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '240',
													   's'    => '10',
													   't'    => 'WSW'
										   },
										   'icon' => '29',
										   'p'    => 'n',
										   'ppcp' => '20',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 }
							 ],
							 'd'    => '7',
							 'sunr' => '5:58 AM',
							 'low'  => '9',
							 't'    => 'Thursday'
						   },
						   {
							 'hi'   => '16',
							 'suns' => '7:50 PM',
							 'dt'   => 'Apr 29',
							 'part' => [
										 {
										   'hmid' => '51',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '237',
													   's'    => '13',
													   't'    => 'WSW'
										   },
										   'icon' => '30',
										   'p'    => 'd',
										   'ppcp' => '20',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 },
										 {
										   'hmid' => '60',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '284',
													   's'    => '8',
													   't'    => 'WNW'
										   },
										   'icon' => '11',
										   'p'    => 'n',
										   'ppcp' => '60',
										   'bt'   => 'Light Rain',
										   't'    => 'Light Rain'
										 }
							 ],
							 'd'    => '8',
							 'sunr' => '5:57 AM',
							 'low'  => '10',
							 't'    => 'Friday'
						   },
						   {
							 'hi'   => '17',
							 'suns' => '7:51 PM',
							 'dt'   => 'Apr 30',
							 'part' => [
										 {
										   'hmid' => '53',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '358',
													   's'    => '11',
													   't'    => 'N'
										   },
										   'icon' => '11',
										   'p'    => 'd',
										   'ppcp' => '60',
										   'bt'   => 'Light Rain',
										   't'    => 'Light Rain'
										 },
										 {
										   'hmid' => '58',
										   'wind' => {
													   'gust' => 'N/A',
													   'd'    => '217',
													   's'    => '10',
													   't'    => 'SW'
										   },
										   'icon' => '29',
										   'p'    => 'n',
										   'ppcp' => '20',
										   'bt'   => 'P Cloudy',
										   't'    => 'Partly Cloudy'
										 }
							 ],
							 'd'    => '9',
							 'sunr' => '5:56 AM',
							 'low'  => '11',
							 't'    => 'Saturday'
						   }
				]
	},
	'head' => {
				'ur'     => 'mm',
				'ud'     => 'km',
				'us'     => 'km/h',
				'form'   => 'MEDIUM',
				'up'     => 'mb',
				'locale' => 'en_US',
				'ut'     => 'C',
				'cached' => '1110000000',
	},
	'cc' => {
			  'cached' => '1110000000',
			  'icon'   => '34',
			  'flik'   => '10',
			  'obst'   => 'Central Park, NY',
			  'lsup'   => '4/21/05 4:51 PM EDT',
			  'tmp'    => '14',
			  'hmid'   => '62',
			  'wind'   => {
						  'gust' => '29',
						  'd'    => '160',
						  's'    => '19',
						  't'    => 'SSE'
			  },
			  'bar' => {
						 'r' => '1,014.6',
						 'd' => 'steady'
			  },
			  'moon' => {
						  'icon' => '12',
						  't'    => 'Waxing Gibbous'
			  },
			  'dewp' => '7',
			  'uv'   => {
						't' => 'Low',
						'i' => '2'
			  },
			  'vis' => '16.1',
			  't'   => 'Fair'
	},
	'lnks' => {
		'cached' => '1110000000',
		'link'   => [
			{
			   'l' =>
'http://www.weather.com/outlook/health/allergies/USNY0998?par=xoap',
			   'pos' => '1',
			   't'   => 'Pollen Reports'
			},
			{
			   'l' =>
'http://www.weather.com/outlook/travel/flights/citywx/USNY0998?par=xoap',
			   'pos' => '2',
			   't'   => 'Airport Delays'
			},
			{
			   'l' =>
'http://www.weather.com/outlook/events/special/result/USNY0998?when=thisweek&par=xoap',
			   'pos' => '3',
			   't'   => 'Special Events'
			},
			{
			   'l'   => 'http://www.weather.com/services/desktop.html?par=xoap',
			   'pos' => '4',
			   't'   => 'Download Desktop Weather'
			}
		],
		'type' => 'prmo'
	},
	'loc' => {
			   'cached' => '1110000000',
			   'suns'   => '7:42 PM',
			   'zone'   => '-4',
			   'lat'    => '40.79',
			   'tm'     => '5:35 PM',
			   'sunr'   => '6:08 AM',
			   'dnam'   => 'New York/Central Park, NY',
			   'id'     => 'USNY0998',
			   'lon'    => '-73.96'
	},
	'ver' => '2.0'
};

#
# Testdata for Weather::Com::Simple::get_weather
#
$simpleWeather =[{
				'place'                  => 'New York/Central Park, NY',
				'updated'                => '4:51 PM EDT on April 21, 2005',
				'celsius'                => '14',
				'temperature_celsius'    => '14',
				'windchill_celsius'      => '10',
				'fahrenheit'             => '57',
				'temperature_fahrenheit' => '57',
				'windchill_fahrenheit'   => '50',
				'wind'                   => '11 mph 19 km/h from the South Southeast',
				'windspeed_kmh'          => '19',
				'windspeed_mph'          => '11',
				'humidity'               => '62',
				'conditions'             => 'Fair',
				'pressure'               => '29.96 in / 1014.6 hPa'                           
}];
