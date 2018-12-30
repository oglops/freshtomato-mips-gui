<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<!--
Tomato GUI
Copyright (C) 2006-2010 Jonathan Zarate
http://www.polarcloud.com/tomato/
For use with Tomato Firmware only.
No part of this file may be used without permission.
-->
<html>
<head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<meta name="robots" content="noindex,nofollow">
<title>[<% ident(); %>] 恢复初始设置...</title>
<script type="text/javascript">
var n = 130;
function tick() {
	var e = document.getElementById('continue');
	e.value = n--;
	if (n < 0) {
		e.value = "Continue";
		return;
	}
	if (n == 19) {
		e.style = "cursor:pointer";
		e.disabled = false;
	}
	setTimeout(tick, 1000);
}
function go() {
	window.location = "http://192.168.1.1/";
}
function init() {
	tick();
}
</script>
<style type="text/css">
body {
	background:rgb(0,0,0) url(tomatousb_bg.png);
	font:14px Tahoma,Arial,sans-serif;
	color:rgb(255,255,255);
}
input {
	width:80px;
	height:24px;
}
.div {
	width:600px;
	height:80px;
	background-color:rgb(47,61,64);
	position:absolute;
	top:0;
	bottom:0;
	left:0;
	right:0;
	text-align:center;
	margin:auto;
	padding:10px 10px;
	border-radius:5px;
}
</style>
</head>
<body onload="init()">
	<div class="div">
		<form action="">
			<div style="display:inline-block">
				请稍等,正在恢复默认值... &nbsp;
				<input type="button" value="" id="continue" onclick="go()" disabled="disabled">
				<div style="width:600px;border-top:1px dashed #888;margin:5px auto;padding:5px 0" id="msg">路由器的 IP 将重置为 192.168.1.1. 你可能需要刷新计算机的 DHCP 或重启计算机后才能继续操作.</div>
			</div>
		</form>
	</div>
</body>
</html>