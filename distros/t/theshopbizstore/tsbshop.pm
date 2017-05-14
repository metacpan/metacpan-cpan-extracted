package Theshopbizstore;

my $html = get_html(); # sub name corrected

# later...

sub get_html{
my $html = <<HTML;
<hr width='100px'><h4>CREATE YOUR OWN<br> 
ONLINE STORE NOW <br>
 ON PERL SITES <br> WITHOUT LEAVING <br>THEM.</h4>
<img src='http://theshop.biz/hand.gif'><br>
<a href='#openModal' style='background-color:#132030; padding:5px; color:white;'>
Create Now!</a>&nbsp;<a href='#opensModal' style='padding:5px; background-color:#132030; color:white;'>Login</a>


<hr width='100px'><br>
<br><img src='http://t0.gstatic.com/images?q=tbn:ANd9GcT6Oyt3L0NifqzrKnT9VRSX3KZip-hWEF4qvsBp35bfWHug2BEJdusRng' width='20' height='20'>
<img src='http://theshop.biz/fav.png' width='20' height='20'>
<img src='http://t0.gstatic.com/images?q=tbn:ANd9GcT6Oyt3L0NifqzrKnT9VRSX3KZip-hWEF4qvsBp35bfWHug2BEJdusRng' width='20' height='20'>
<img src='http://theshop.biz/fav.png' width='20' height='20'>
<img src='http://t0.gstatic.com/images?q=tbn:ANd9GcT6Oyt3L0NifqzrKnT9VRSX3KZip-hWEF4qvsBp35bfWHug2BEJdusRng' width='20' height='20'>
<img src='http://theshop.biz/fav.png' width='20' height='20'>


<style>


.modaleDialog {
	position: fixed;
	font-family: Arial, Helvetica, sans-serif;
	top: 0;
	right: 0;
	bottom: 0;
	left: 0;
background: rgba(0,0,0,0.8);
	z-index: 99999;
	opacity:0;
	-webkit-transition: opacity 400ms ease-in;
	-moz-transition: opacity 400ms ease-in;
	
transition: opacity 400ms ease-in;
	pointer-events: none;
}
.modaleDialog:target {
	opacity:1;
	pointer-events: auto;
}

.modaleDialog > div {
	width: 400px;
	position: relative;
	margin: 10% auto;
	padding: 5px 20px 13px 20px;
	border-radius: 10px;
	background: #fff;
	background: -moz-linear-gradient(#fff, #999);
	background: -webkit-linear-gradient(#fff, #999);
	background: -o-linear-gradient(#fff, #999);
}
.closss {
	background: #606061;
	color: #FFFFFF;
	line-height: 25px;
	position: absolute;
	right: -12px;
	text-align: center;
	top: -10px;
	width: 24px;
	text-decoration: none;
	font-weight: bold;
	-webkit-border-radius: 12px;
	-moz-border-radius: 12px;
	border-radius: 12px;
	-moz-box-shadow: 1px 1px 3px #000;
	-webkit-box-shadow: 1px 1px 3px #000;
	box-shadow: 1px 1px 3px #000;
}

.closss:hover { background: #00d9ff; }
</style>




<style>

.close {
	background: #606061;
	color: #FFFFFF;
	line-height: 25px;
	position: absolute;
	right: -12px;
	text-align: center;
	top: -10px;
	width: 24px;
	text-decoration: none;
	font-weight: bold;
	-webkit-border-radius: 12px;
	-moz-border-radius: 12px;
	border-radius: 12px;
	-moz-box-shadow: 1px 1px 3px #000;
	-webkit-box-shadow: 1px 1px 3px #000;
	box-shadow: 1px 1px 3px #000;
}

.close:hover { background: #00d9ff; }
.modalDialog {
	position: fixed;
	font-family: Arial, Helvetica, sans-serif;
	top: 0;
	right: 0;
	bottom: 0;
	left: 0;
	background: rgba(0,0,0,0.8);
	z-index: 99999;
	opacity:0;
	-webkit-transition: opacity 400ms ease-in;
	-moz-transition: opacity 400ms ease-in;
	transition: opacity 400ms ease-in;
	pointer-events: none;
}
.modalDialog:target {
	opacity:1;
	pointer-events: auto;
}

.modalDialog > div {
	width: 400px;
	position: relative;
	margin: 10% auto;
	padding: 5px 20px 13px 20px;
	border-radius: 10px;
	background: #fff;
	background: -moz-linear-gradient(#fff, #999);
	background: -webkit-linear-gradient(#fff, #999);
	background: -o-linear-gradient(#fff, #999);
}
.closes {
	background: #606061;
	color: #FFFFFF;
	line-height: 25px;
	position: absolute;
	right: -12px;
	text-align: center;
	top: -10px;
	width: 24px;
	text-decoration: none;
	font-weight: bold;
	-webkit-border-radius: 12px;

	-moz-border-radius: 12px;
	border-radius: 12px;
	-moz-box-shadow: 1px 1px 3px #000;
	-webkit-box-shadow: 1px 1px 3px #000;

	box-shadow: 1px 1px 3px #000;
}

.closes:hover { background: #00d9ff; }
</style>

<style>


.modalsDialog {
	position: fixed;
	font-family: Arial, Helvetica, sans-serif;
	top: 0;
	right: 0;
	bottom: 0;
	left: 0;
	background: rgba(0,0,0,0.8);
	z-index: 99999;
	opacity:0;
	-webkit-transition: opacity 400ms ease-in;
	-moz-transition: opacity 400ms ease-in;
	transition: opacity 400ms ease-in;
	pointer-events: none;
}
.modalsDialog:target {
	opacity:1;
	pointer-events: auto;
}

.modalsDialog > div {
	width: 400px;
	position: relative;
	margin: 10% auto;
	padding: 5px 20px 13px 20px;
	border-radius: 10px;
	background: #fff;
	background: -moz-linear-gradient(#fff, #999);
	background: -webkit-linear-gradient(#fff, #999);
	background: -o-linear-gradient(#fff, #999);
}
</style>
<style>

.closse {
	background: #606061;
	color: #FFFFFF;
	line-height: 25px;
	position: absolute;
	right: -12px;
	text-align: center;
	top: -10px;
	width: 24px;
	text-decoration: none;
	font-weight: bold;
	-webkit-border-radius: 12px;
	-moz-border-radius: 12px;
	border-radius: 12px;
	-moz-box-shadow: 1px 1px 3px #000;
	-webkit-box-shadow: 1px 1px 3px #000;
	box-shadow: 1px 1px 3px #000;
}


.closse:hover { background: #00d9ff; }
</style>

<style>


.modalseDialog {
	position: fixed;
	font-family: Arial, Helvetica, sans-serif;
	top: 0;
	right: 0;
	bottom: 0;
	left: 0;
	background: rgba(0,0,0,0.8);
	z-index: 99999;
	opacity:0;
	-webkit-transition: opacity 400ms ease-in;
	-moz-transition: opacity 400ms ease-in;
	transition: opacity 400ms ease-in;
	pointer-events: none;
}
.modalseDialog:target {
	opacity:1;
	pointer-events: auto;
}

.modalseDialog > div {
	width: 400px;
	position: relative;
	margin: 10% auto;
	padding: 5px 20px 13px 20px;
	border-radius: 10px;
	background: #fff;
	background: -moz-linear-gradient(#fff, #999);
	background: -webkit-linear-gradient(#fff, #999);
	background: -o-linear-gradient(#fff, #999);
}
</style>
<div id='opensModal' class='modalsDialog'>
	<div><a href='#close' title='Close' class='close'>X</a>
		<b>Login</b>\n
<iframe src='http://theshop.biz/copy/login' style='border:none;' width='380px' height='300px'></iframe>
	</div>
</div>

<div id='openModal' class='modalDialog'>
	<div><a href='#closes' title='Close' class='closes'>X</a>
		
<b>Register</b>\n
<iframe src='http://theshop.biz/copy/login/register.php' style='border:none;' width='380px' height='500px'></iframe>

	</div>
</div>

HTML
return $html;
}