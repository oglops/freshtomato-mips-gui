<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<!--
	Tomato GUI
	Copyright (C) 2006-2008 Jonathan Zarate
	http://www.polarcloud.com/tomato/

	Portions Copyright (C) 2008-2010 Keith Moyer, tomatovpn@keithmoyer.com

	For use with Tomato Firmware only.
	No part of this file may be used without permission.
-->
<html>
<head>
<meta http-equiv="content-type" content="text/html;charset=utf-8">
<meta name="robots" content="noindex,nofollow">
<title>[<% ident(); %>] VPN设置: OpenVPN服务器</title>
<link rel="stylesheet" type="text/css" href="tomato.css">
<% css(); %>
<script type="text/javascript" src="tomato.js"></script>
<script type="text/javascript" src="vpn.js"></script>
<script type="text/javascript">

//	<% nvram("vpn_server_eas,vpn_server_dns,vpn_server1_poll,vpn_server1_if,vpn_server1_proto,vpn_server1_port,vpn_server1_firewall,vpn_server1_sn,vpn_server1_nm,vpn_server1_local,vpn_server1_remote,vpn_server1_dhcp,vpn_server1_r1,vpn_server1_r2,vpn_server1_crypt,vpn_server1_comp,vpn_server1_digest,vpn_server1_cipher,vpn_server1_ncp_enable,vpn_server1_ncp_ciphers,vpn_server1_reneg,vpn_server1_hmac,vpn_server1_plan,vpn_server1_plan1,vpn_server1_plan2,vpn_server1_plan3,vpn_server1_ccd,vpn_server1_c2c,vpn_server1_ccd_excl,vpn_server1_ccd_val,vpn_server1_pdns,vpn_server1_rgw,vpn_server1_userpass,vpn_server1_nocert,vpn_server1_users_val,vpn_server1_custom,vpn_server1_static,vpn_server1_ca,vpn_server1_ca_key,vpn_server1_crt,vpn_server1_key,vpn_server1_dh,vpn_server1_br,vpn_server2_poll,vpn_server2_if,vpn_server2_proto,vpn_server2_port,vpn_server2_firewall,vpn_server2_sn,vpn_server2_nm,vpn_server2_local,vpn_server2_remote,vpn_server2_dhcp,vpn_server2_r1,vpn_server2_r2,vpn_server2_crypt,vpn_server2_comp,vpn_server2_digest,vpn_server2_cipher,vpn_server2_ncp_enable,vpn_server2_ncp_ciphers,vpn_server2_reneg,vpn_server2_hmac,vpn_server2_plan,vpn_server2_plan1,vpn_server2_plan2,vpn_server2_plan3,vpn_server2_ccd,vpn_server2_c2c,vpn_server2_ccd_excl,vpn_server2_ccd_val,vpn_server2_pdns,vpn_server2_rgw,vpn_server2_userpass,vpn_server2_nocert,vpn_server2_users_val,vpn_server2_custom,vpn_server2_static,vpn_server2_ca,vpn_server2_ca_key,vpn_server2_crt,vpn_server2_key,vpn_server2_dh,vpn_server2_br,lan_ifname,lan1_ifname,lan2_ifname,lan3_ifname"); %>

function CCDGrid() { return this; }
CCDGrid.prototype = new TomatoGrid;

function UsersGrid() {return this;}
UsersGrid.prototype = new TomatoGrid;

tabs = [['server1', 'VPN服务器1'],['server2', 'VPN服务器2']];
sections = [['basic', '基本设置'],['advanced', '高级设置'],['keys','密钥设置'],['status','运行状态']];
ccdTables = [];
usersTables = [];
statusUpdaters = [];
for (i = 0; i < tabs.length; ++i)
{
	ccdTables.push(new CCDGrid());
	usersTables.push(new UsersGrid());
	usersTables[i].servername = tabs[i][0];
	statusUpdaters.push(new StatusUpdater());
}
ciphers = [['default','使用默认'],['none','无']];
for (i = 0; i < vpnciphers.length; ++i) ciphers.push([vpnciphers[i],vpnciphers[i]]);
digests = [['default','Use Default'],['none','None']];
for (i = 0; i < vpndigests.length; ++i) digests.push([vpndigests[i],vpndigests[i]]);

changed = 0;
vpn1up = parseInt('<% psup("vpnserver1"); %>');
vpn2up = parseInt('<% psup("vpnserver2"); %>');

function updateStatus(num) {
	var xob = new XmlHttp();
	xob.onCompleted = function(text, xml) {
		statusUpdaters[num].update(text);
		xob = null;
	}
	xob.onError = function(ex) {
		statusUpdaters[num].errors.innerHTML += 'ERROR! '+ex+'<br />';
		xob = null;
	}

	xob.post('/vpnstatus.cgi', 'server=' + (num+1));
}

function tabSelect(name) {
	tgHideIcons();

	tabHigh(name);

	for (var i = 0; i < tabs.length; ++i)
	{
		var on = (name == tabs[i][0]);
		elem.display(tabs[i][0] + '-tab', on);
	}

	cookie.set('vpn_server_tab', name);
}

function sectSelect(tab, section) {
	tgHideIcons();

	for (var i = 0; i < sections.length; ++i)
	{
		if (section == sections[i][0])
		{
			elem.addClass(tabs[tab][0]+'-'+sections[i][0]+'-tab', 'active');
			elem.display(tabs[tab][0]+'-'+sections[i][0], true);
		}
		else
		{
			elem.removeClass(tabs[tab][0]+'-'+sections[i][0]+'-tab', 'active');
			elem.display(tabs[tab][0]+'-'+sections[i][0], false);
		}
	}

	cookie.set('vpn_server'+tab+'_section', section);
}

function toggle(service, isup) {
	if (changed && !confirm("未保存的设置将会丢失.继续?")) return;

	E('_' + service + '_button').disabled = true;
	form.submitHidden('service.cgi', {
		_redirect: 'vpn-server.asp',
		_sleep: '3',
		_service: service + (isup ? '-stop' : '-start')
	});
}

function verifyFields(focused, quiet) {
	tgHideIcons();

	var ret = 1;

	// When settings change, make sure we restart the right services
	if (focused)
	{
		changed = 1;

		var fom = E('t_fom');
		var serverindex = focused.name.indexOf("server");
		if (serverindex >= 0)
		{
			var servernumber = focused.name.substring(serverindex+6,serverindex+7);
			if (eval('vpn'+servernumber+'up') && fom._service.value.indexOf('server'+servernumber) < 0)
			{
				if ( fom._service.value != "" ) fom._service.value += ",";
				fom._service.value += 'vpnserver'+servernumber+'-restart';
			}

			if ((focused.name.indexOf("_dns")>=0 || (focused.name.indexOf("_if")>=0 && E('_f_vpn_server'+servernumber+'_dns').checked)) &&
			    fom._service.value.indexOf('dnsmasq') < 0)
			{
				if ( fom._service.value != "" ) fom._service.value += ",";
				fom._service.value += 'dnsmasq-restart';
			}

			if (focused.name.indexOf("_c2c") >= 0)
				ccdTables[servernumber-1].reDraw();
		}
	}

	// Element varification
	for (i = 0; i < tabs.length; ++i)
	{
		t = tabs[i][0];

		if (!v_range('_vpn_'+t+'_poll', quiet, 0, 1440)) ret = 0;
		if (!v_port('_vpn_'+t+'_port', quiet)) ret = 0;
		if (!v_ip('_vpn_'+t+'_sn', quiet, 0)) ret = 0;
		if (!v_netmask('_vpn_'+t+'_nm', quiet)) ret = 0;
		if (!v_ip('_vpn_'+t+'_r1', quiet, 1)) ret = 0;
		if (!v_ip('_vpn_'+t+'_r2', quiet, 1)) ret = 0;
		if (!v_ip('_vpn_'+t+'_local', quiet, 1)) ret = 0;
		if (!v_ip('_vpn_'+t+'_remote', quiet, 1)) ret = 0;
		if (!v_range('_vpn_'+t+'_reneg', quiet, -1, 2147483647)) ret = 0;
	}

	// Visibility changes
	for (i = 0; i < tabs.length; ++i)
	{
		t = tabs[i][0];

		auth = E('_vpn_'+t+'_crypt').value;
		iface = E('_vpn_'+t+'_if');
		hmac = E('_vpn_'+t+'_hmac');
		dhcp = E('_f_vpn_'+t+'_dhcp');
		ccd = E('_f_vpn_'+t+'_ccd');
		userpass = E('_f_vpn_'+t+'_userpass');
		dns = E('_f_vpn_'+t+'_dns');
		ncp = E('_vpn_'+t+'_ncp_enable').value;

		elem.display(PR('_vpn_'+t+'_ca'), PR('_vpn_'+t+'_crt'), PR('_vpn_'+t+'_dh'), PR('_vpn_'+t+'_key'),
		             PR('_vpn_'+t+'_hmac'), PR('_f_vpn_'+t+'_rgw'), PR('_vpn_'+t+'_reneg'), auth == "tls");
		elem.display(PR('_vpn_'+t+'_static'), auth == "secret" || (auth == "tls" && hmac.value >= 0));
		elem.display(PR('_vpn_keygen_static_'+t+'_button'), auth == "secret" || (auth == "tls" && hmac.value >= 0));
		elem.display(E(t+'_custom_crypto_text'), auth == "custom");
/* KEYGEN-BEGIN */
		elem.display(PR('_vpn_keygen_'+t+'_button'), auth == "tls");
/* KEYGEN-END */
		elem.display(PR('_vpn_'+t+'_sn'), PR('_f_vpn_'+t+'_plan'), PR('_f_vpn_'+t+'_plan1'),
 		             PR('_f_vpn_'+t+'_plan2'), PR('_f_vpn_'+t+'_plan3'), auth == "tls" && iface.value == "tun");
		elem.display(PR('_f_vpn_'+t+'_dhcp'), auth == "tls" && iface.value == "tap");
		elem.display(PR('_vpn_'+t+'_br'), iface.value == "tap");
		elem.display(E(t+'_range'), !dhcp.checked);
		elem.display(PR('_vpn_'+t+'_local'), auth == "secret" && iface.value == "tun");
		elem.display(PR('_f_vpn_'+t+'_ccd'), auth == "tls");
		elem.display(PR('_f_vpn_'+t+'_userpass'), auth == "tls");
		elem.display(PR('_f_vpn_'+t+'_nocert'),PR('table_'+t+'_users'), auth == "tls" && userpass.checked);
		elem.display(PR('_f_vpn_'+t+'_c2c'),PR('_f_vpn_'+t+'_ccd_excl'),PR('table_'+t+'_ccd'), auth == "tls" && ccd.checked);
		elem.display(PR('_f_vpn_'+t+'_pdns'), auth == "tls" && dns.checked );
		elem.display(PR('_vpn_'+t+'_cipher'), (ncp != 2));
		elem.display(PR('_vpn_'+t+'_ncp_enable'), (auth == "tls"));
		elem.display(PR('_vpn_'+t+'_ncp_ciphers'), ((ncp > 0) && (auth == "tls")));

		keyHelp = E(t+'-keyhelp');
		switch (auth.value)
		{
		case "tls":
			keyHelp.href = helpURL['TLSKeys'];
			break;
		case "secret":
			keyHelp.href = helpURL['staticKeys'];
			break;
		default:
			keyHelp.href = helpURL['howto'];
			break;
		}
		E('_vpn_'+t+'_ncp_ciphers').disabled = true;
	}

	var bridge1 = E('_vpn_server1_br');
	if(nvram.lan_ifname.length < 1)
		bridge1.options[0].disabled=true;
	if(nvram.lan1_ifname.length < 1)
		bridge1.options[1].disabled=true;
	if(nvram.lan2_ifname.length < 1)
		bridge1.options[2].disabled=true;
	if(nvram.lan3_ifname.length < 1)
		bridge1.options[3].disabled=true;

	var bridge2 = E('_vpn_server2_br');
	if(nvram.lan_ifname.length < 1)
		bridge2.options[0].disabled=true;
	if(nvram.lan1_ifname.length < 1)
		bridge2.options[1].disabled=true;
	if(nvram.lan2_ifname.length < 1)
		bridge2.options[2].disabled=true;
	if(nvram.lan3_ifname.length < 1)
		bridge2.options[3].disabled=true;

	<!-- disable and un-check push lanX (*_plan) if lanX_ifname length < 1 -->
	if(nvram.lan_ifname.length < 1)
	{
		E('_f_vpn_server1_plan').checked = false;
		E('_f_vpn_server2_plan').checked = false;
		E('_f_vpn_server1_plan').disabled = true;
		E('_f_vpn_server2_plan').disabled = true;
	}
	if(nvram.lan1_ifname.length < 1)
	{
		E('_f_vpn_server1_plan1').checked = false;
		E('_f_vpn_server2_plan1').checked = false;
		E('_f_vpn_server1_plan1').disabled = true;
		E('_f_vpn_server2_plan1').disabled = true;
	}
	if(nvram.lan2_ifname.length < 1)
	{
		E('_f_vpn_server1_plan2').checked = false;
		E('_f_vpn_server2_plan2').checked = false;
		E('_f_vpn_server1_plan2').disabled = true;
		E('_f_vpn_server2_plan2').disabled = true;
	}
	if(nvram.lan3_ifname.length < 1)
	{
		E('_f_vpn_server1_plan3').checked = false;
		E('_f_vpn_server2_plan3').checked = false;
		E('_f_vpn_server1_plan3').disabled = true;
		E('_f_vpn_server2_plan3').disabled = true;
	}

	return ret;
}

CCDGrid.prototype.verifyFields = function(row, quiet) {
	var ret = 1;

	// When settings change, make sure we restart the right server
	var fom = E('t_fom');
	var servernum = 1;
	for (i = 0; i < tabs.length; ++i)
	{
		if (ccdTables[i] == this)
		{
			servernum = i+1;
			if (eval('vpn'+(i+1)+'up') && fom._service.value.indexOf('server'+(i+1)) < 0)
			{
				if ( fom._service.value != "" ) fom._service.value += ",";
				fom._service.value += 'vpnserver'+(i+1)+'-restart';
			}
		}
	}

	var f = fields.getAll(row);

	// Verify fields in this row of the table
	if (f[1].value == "") { ferror.set(f[1], "通用名称必须填写.", quiet); ret = 0; }
	if (f[1].value.indexOf('>') >= 0 || f[1].value.indexOf('<') >= 0) { ferror.set(f[1], "通用名称不能包含 '<' 或 '>' 字符.", quiet); ret = 0; }
	if (f[2].value != "" && !v_ip(f[2],quiet,0)) ret = 0;
	if (f[3].value != "" && !v_netmask(f[3],quiet)) ret = 0;
	if (f[2].value == "" && f[3].value != "" ) { ferror.set(f[2], "子网和子网掩码必须一起提供,否则请留空.", quiet); ret = 0; }
	if (f[3].value == "" && f[2].value != "" ) { ferror.set(f[3], "子网和子网掩码必须一起提供,否则请留空.", quiet); ret = 0; }
	if (f[4].checked && (f[2].value == "" || f[3].value == "")) { ferror.set(f[4], "如果不提供路由则无法推送,请提供子网/子网掩码.", quiet); ret = 0; }

	return ret;
}

CCDGrid.prototype.fieldValuesToData = function(row) {
	var f = fields.getAll(row);
	return [f[0].checked?1:0, f[1].value, f[2].value, f[3].value, f[4].checked?1:0];
}

CCDGrid.prototype.dataToView = function(data) {
	var c2c = false;
	for (i = 0; i < tabs.length; ++i)
	{
		if (ccdTables[i] == this && E('_f_vpn_server'+(i+1)+'_c2c').checked )
			c2c = true;
	}

	var temp = ['<input type=\'checkbox\' style="opacity:1" disabled'+(data[0]!=0?' checked':'')+'>',
	            data[1],
	            data[2],
	            data[3],
	            c2c?'<input type=\'checkbox\' style="opacity:1" disabled'+(data[4]!=0?' checked':'')+'>':'N/A'];

	var v = [];
	for (var i = 0; i < temp.length; ++i)
		v.push(i==0||i==4?temp[i]:escapeHTML('' + temp[i]));

	return v;
}

CCDGrid.prototype.dataToFieldValues = function(data) {
	return [data[0] == 1, data[1], data[2], data[3], data[4] == 1];
}

CCDGrid.prototype.reDraw = function() {
	var i, j, header, data, view;
	data = this.getAllData();
	header = this.header ? this.header.rowIndex + 1 : 0;
	for (i = 0; i < data.length; ++i)
	{
		view = this.dataToView(data[i]);
		for (j = 0; j < view.length; ++j)
			this.tb.rows[i+header].cells[j].innerHTML = view[j];
	}
}

UsersGrid.prototype.verifyFields = function(row, quiet) {
	var ret = 1;
	var fom = E('t_fom');
	var servernum = 1;
	for (i = 0; i < tabs.length; ++i)
	{
		if (usersTables[i] == this)
		{
			servernum = i+1;
			if (eval('vpn'+(i+1)+'up') && fom._service.value.indexOf('server'+(i+1)) < 0)
			{
				if ( fom._service.value != "" )
					fom._service.value += ",";
				fom._service.value += 'vpnserver'+(i+1)+'-restart';
			}
		}
	}
	var f = fields.getAll(row);

	// Verify fields in this row of the table
	if (f[1].value == "") { ferror.set(f[1], "用户名必须填写.", quiet); ret = 0; }
	if (f[1].value.indexOf('>') >= 0 || f[1].value.indexOf('<') >= 0) { ferror.set(f[1], "用户名不能包含 '<' 或 '>' 字符.", quiet); ret = 0; }
	if (f[2].value == "" ) { ferror.set(f[2], "密码必须填写.", quiet); ret = 0; }
	if (f[2].value.indexOf('>') >= 0 || f[1].value.indexOf('<') >= 0) { ferror.set(f[2], "密码不能包含 '<' 或 '>' 字符.", quiet); ret = 0; }
	return ret;
}
UsersGrid.prototype.fieldValuesToData = function(row) {
	var f = fields.getAll(row);
	return [f[0].checked?1:0, f[1].value, f[2].value];
}
UsersGrid.prototype.dataToView = function(data) {
	var temp = ['<input type=\'checkbox\' style="opacity:1" disabled'+(data[0]!=0?' checked':'')+'>', data[1], 'Secret'];

	var v = [];
	for (var i = 0; i < temp.length; ++i){
		v.push(i==0?temp[i]:escapeHTML('' + temp[i]));
	}
	return v;
}
UsersGrid.prototype.dataToFieldValues = function(data) {
	return [data[0] == 1, data[1], data[2]];
}
function save() {
	if (!verifyFields(null, false)) return;

	var fom = E('t_fom');

	E('vpn_server_eas').value = '';
	E('vpn_server_dns').value = '';

	for (i = 0; i < tabs.length; ++i)
	{
		if (ccdTables[i].isEditing()) return;
		if (usersTables[i].isEditing()) return;

		t = tabs[i][0];

		if ( E('_f_vpn_'+t+'_eas').checked )
			E('vpn_server_eas').value += ''+(i+1)+',';

		if ( E('_f_vpn_'+t+'_dns').checked )
			E('vpn_server_dns').value += ''+(i+1)+',';

		var data = ccdTables[i].getAllData();
		var ccd = '';

		for (j = 0; j < data.length; ++j)
			ccd += data[j].join('<') + '>';
		var userdata = usersTables[i].getAllData();
		var users = '';
		for (j = 0; j < userdata.length; ++j)
			users += userdata[j].join('<') + '>';

		E('vpn_'+t+'_dhcp').value = E('_f_vpn_'+t+'_dhcp').checked ? 1 : 0;
		E('vpn_'+t+'_plan').value = E('_f_vpn_'+t+'_plan').checked ? 1 : 0;
		E('vpn_'+t+'_plan1').value = E('_f_vpn_'+t+'_plan1').checked ? 1 : 0;
		E('vpn_'+t+'_plan2').value = E('_f_vpn_'+t+'_plan2').checked ? 1 : 0;
		E('vpn_'+t+'_plan3').value = E('_f_vpn_'+t+'_plan3').checked ? 1 : 0;
		E('vpn_'+t+'_ccd').value = E('_f_vpn_'+t+'_ccd').checked ? 1 : 0;
		E('vpn_'+t+'_c2c').value = E('_f_vpn_'+t+'_c2c').checked ? 1 : 0;
		E('vpn_'+t+'_ccd_excl').value = E('_f_vpn_'+t+'_ccd_excl').checked ? 1 : 0;
		E('vpn_'+t+'_ccd_val').value = ccd;
		E('vpn_'+t+'_userpass').value = E('_f_vpn_'+t+'_userpass').checked ? 1 : 0;
		E('vpn_'+t+'_nocert').value = E('_f_vpn_'+t+'_nocert').checked ? 1 : 0;
		E('vpn_'+t+'_users_val').value = users;
		E('vpn_'+t+'_pdns').value = E('_f_vpn_'+t+'_pdns').checked ? 1 : 0;
		E('vpn_'+t+'_rgw').value = E('_f_vpn_'+t+'_rgw').checked ? 1 : 0;
	}

	form.submit(fom, 1);

	changed = 0;
}

function init() {
	tabSelect(cookie.get('vpn_server_tab') || tabs[0][0]);

	for (i = 0; i < tabs.length; ++i)
	{
		sectSelect(i, cookie.get('vpn_server'+i+'_section') || sections[0][0]);

		t = tabs[i][0];

		ccdTables[i].init('table_'+t+'_ccd', 'sort', 0, [{ type: 'checkbox' }, { type: 'text', maxlen: 15 }, { type: 'text', maxlen: 15 }, { type: 'text', maxlen: 15 }, { type: 'checkbox' }]);
		ccdTables[i].headerSet(['启用', '通用名称', '子网', '子网掩码', '推送网络']);
		var ccdVal = eval( 'nvram.vpn_'+t+'_ccd_val' );
		if (ccdVal.length)
		{
			var s = ccdVal.split('>');
			for (var j = 0; j < s.length; ++j)
			{
				if (!s[j].length) continue;
				var row = s[j].split('<');
				if (row.length == 5)
					ccdTables[i].insertData(-1, row);
			}
		}
		ccdTables[i].showNewEditor();
		ccdTables[i].resetNewEditor();

		usersTables[i].init('table_' + t + '_users','sort', 0, [{ type: 'checkbox' }, { type: 'text', maxlen: 15 }, { type: 'text', maxlen: 15 }]);
		usersTables[i].headerSet(['启用', '用户名', '密码']);
		var usersVal = eval('nvram.vpn_' + t + '_users_val');
		if(usersVal.length) {
			var s = usersVal.split('>');
			for (var j = 0; j < s.length; ++j)
			{
				if (!s[j].length) continue;
				var row = s[j].split('<');
				if (row.length == 3)
					usersTables[i].insertData(-1, row);
			}
		}
		usersTables[i].showNewEditor();
		usersTables[i].resetNewEditor();

		statusUpdaters[i].init(t+'-status-clients-table',t+'-status-routing-table',t+'-status-stats-table',t+'-status-time',t+'-status-content',t+'-no-status',t+'-status-errors');
		updateStatus(i);
	}

	verifyFields(null, true);
}

var keyGenRequest = null

function updateStaticKey(serverNumber)
{
	if (keyGenRequest) return;
	disableKeyButtons(serverNumber, true);
	changed = 1;
	elem.display(E('server'+serverNumber+'_static_progress_div'), true);
	keyGenRequest = new XmlHttp();
	keyGenRequest.onCompleted = function(text, xml) {
		E('_vpn_server'+serverNumber+'_static').value = text;
		keyGenRequest = null;
		elem.display(E('server'+serverNumber+'_static_progress_div'), false);
		disableKeyButtons(serverNumber, false);
	}
	keyGenRequest.onError = function(ex) { keyGenRequest = null; }
	keyGenRequest.post('vpngenkey.cgi', '_mode=static');
}
/* KEYGEN-BEGIN */
function generateDHParams(serverNumber)
{
	if (keyGenRequest) return;
	if (confirm('WARNING: DH Parameters generation can take long time.\nDo you want to proceed?')) {
		changed = 1;
		disableKeyButtons(serverNumber, true);
		elem.display(E('server'+serverNumber+'_dh_progress_div'), true);
		keyGenRequest = new XmlHttp();
		keyGenRequest.onCompleted = function(text, xml) {
			E('_vpn_server'+serverNumber+'_dh').value = text;
			keyGenRequest = null;
			elem.display(E('server'+serverNumber+'_dh_progress_div'), false);
			disableKeyButtons(serverNumber, false);
		}
		keyGenRequest.onError = function(ex) { keyGenRequest = null; }
		keyGenRequest.post('vpngenkey.cgi', '_mode=dh');
	}
}

function generateKeys(serverNumber)
{
	if (keyGenRequest) return;
	changed = 1;
	let caKeyTextArea = E('_vpn_server'+serverNumber+'_ca_key');
	let doGeneration = true;
	if (caKeyTextArea.value == "") {
		doGeneration = confirm("WARNING: You haven't provided Certificate Authority Key.\n \
			This means, that CA Key needs to be regenerated, but it WILL break ALL your existing client certificates.\n \
			You will need to reconfigure all your existing VPN clients!\n Are you sure to continue?");
	}
	if (doGeneration) {
		disableKeyButtons(serverNumber,true);
		showTLSProgressDivs(serverNumber,true);
		var cakey, cacert, generated_crt, generated_key;
		keyGenRequest = new XmlHttp();
		keyGenRequest.onCompleted = function(text, xml) {
			eval(text);
			E('_vpn_server'+serverNumber+'_ca_key').value = cakey;
			E('_vpn_server'+serverNumber+'_ca').value = cacert;
			E('_vpn_server'+serverNumber+'_crt').value = generated_crt;
			E('_vpn_server'+serverNumber+'_key').value = generated_key;
			keyGenRequest = null;
			disableKeyButtons(serverNumber,false);
			showTLSProgressDivs(serverNumber,false);
		}
		keyGenRequest.onError = function(ex) { keyGenRequest = null; }
		keyGenRequest.post('vpngenkey.cgi', '_mode=key&_server=' + serverNumber);
	}
}
/* KEYGEN-END */

function disableKeyButtons(serverNumber, state)
{
	E('_vpn_keygen_static_server'+serverNumber+'_button').disabled = state;
/* KEYGEN-BEGIN */
	E('_vpn_keygen_server'+serverNumber+'_button').disabled = state;
	E('_vpn_dhgen_server'+serverNumber+'_button').disabled = state;
/* KEYGEN-END */
}

function showTLSProgressDivs(serverNumber, state)
{
	elem.display(E('server'+serverNumber+'_key_progress_div'), state);
/* KEYGEN-BEGIN */
	elem.display(E('server'+serverNumber+'_cert_progress_div'), state);
	elem.display(E('server'+serverNumber+'_ca_progress_div'), state);
	elem.display(E('server'+serverNumber+'_ca_key_progress_div'), state);
/* KEYGEN-END */
}
/* KEYGEN-BEGIN */

function downloadClientConfig(serverNumber)
{
	if (keyGenRequest) return;
	let caKeyTextArea = E('_vpn_server'+serverNumber+'_ca_key');
	let caTextArea = E('_vpn_server'+serverNumber+'_ca');
	let serverCrtTextArea = E('_vpn_server'+serverNumber+'_crt');
	let serverCrtKeyTextArea = E('_vpn_server'+serverNumber+'_key');
	if (caKeyTextArea.value == "" || caTextArea.value == "" || serverCrtTextArea.value == "" || serverCrtKeyTextArea.value == "") {
				alert("Not all key fields has been entered!");
				return;
	}
	if (changed) {
		alert("Changes has been made. You need to save before continue!");
		return;
	}
	elem.display(E('server'+serverNumber+'_gen_progress_div'), true);
	keyGenRequest = new XmlHttp();
	keyGenRequest.onCompleted = function(text, xml) {
		elem.display(E('server'+serverNumber+'_gen_progress_div'), false);
		keyGenRequest = null;

		var downloadedFileFakeLink = document.createElement('a');
		downloadedFileFakeLink.setAttribute('href', 'data:application/tomato-binary-file,' + encodeURIComponent(text));
		downloadedFileFakeLink.setAttribute('download', 'ClientConfig.tgz');

		downloadedFileFakeLink.style.display = 'none';
		document.body.appendChild(downloadedFileFakeLink);

		downloadedFileFakeLink.click();

		document.body.removeChild(downloadedFileFakeLink);
	}
	keyGenRequest.onError = function(ex) { keyGenRequest = null; }
	keyGenRequest.responseType = 'blob';
	keyGenRequest.get('vpn/ClientConfig.tgz','_server=' + serverNumber);
}
/* KEYGEN-END */

</script>

<style type="text/css">
textarea
{
	width: 98%;
	height: 10em;
}
p.keyhelp
{
	font-size: smaller;
	font-style: italic;
}
div.status-header p
{
	font-weight: bold;
	padding-bottom: 4px;
}
table.status-table
{
	width: auto;
	margin-left: auto;
	margin-right: auto;
	text-align: center;
}
</style>

</head>
<body>
<form id="t_fom" method="post" action="tomato.cgi">
<table id="container" cellspacing="0">
<tr><td colspan="2" id="header">
	<div class="title">Tomato</div>
	<div class="version">Version <% version(); %></div>
</td></tr>
<tr id="body"><td id="navi"><script type="text/javascript">navi()</script></td>
<td id="content">
<div id="ident"><% ident(); %></div>

<input type="hidden" name="_nextpage" value="vpn-server.asp">
<input type="hidden" name="_nextwait" value="5">
<input type="hidden" name="_service" value="">
<input type="hidden" name="vpn_server_eas" id="vpn_server_eas" value="">
<input type="hidden" name="vpn_server_dns" id="vpn_server_dns" value="">

<div class="section-title">OpenVPN 服务器设置</div>
<div class="section">
<script type="text/javascript">
tabCreate.apply(this, tabs);

for (i = 0; i < tabs.length; ++i)
{
	t = tabs[i][0];
	W('<div id=\''+t+'-tab\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_dhcp\' name=\'vpn_'+t+'_dhcp\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_plan\' name=\'vpn_'+t+'_plan\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_plan1\' name=\'vpn_'+t+'_plan1\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_plan2\' name=\'vpn_'+t+'_plan2\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_plan3\' name=\'vpn_'+t+'_plan3\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_ccd\' name=\'vpn_'+t+'_ccd\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_c2c\' name=\'vpn_'+t+'_c2c\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_ccd_excl\' name=\'vpn_'+t+'_ccd_excl\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_ccd_val\' name=\'vpn_'+t+'_ccd_val\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_userpass\' name=\'vpn_'+t+'_userpass\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_nocert\' name=\'vpn_'+t+'_nocert\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_users_val\' name=\'vpn_'+t+'_users_val\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_pdns\' name=\'vpn_'+t+'_pdns\'>');
	W('<input type=\'hidden\' id=\'vpn_'+t+'_rgw\' name=\'vpn_'+t+'_rgw\'>');

	W('<ul class="tabs">');
	for (j = 0; j < sections.length; j++)
	{
		W('<li><a href="javascript:sectSelect('+i+',\''+sections[j][0]+'\')" id="'+t+'-'+sections[j][0]+'-tab">'+sections[j][1]+'<\/a><\/li>');
	}
	W('<\/ul><div class=\'tabs-bottom\'><\/div>');

	W('<div id=\''+t+'-basic\'>');
	createFieldTable('', [
		{ title: '同 WAN 一起启动', name: 'f_vpn_'+t+'_eas', type: 'checkbox', value: nvram.vpn_server_eas.indexOf(''+(i+1)) >= 0 },
		{ title: '接口类型', name: 'vpn_'+t+'_if', type: 'select', options: [ ['tap','TAP'], ['tun','TUN'] ], value: eval( 'nvram.vpn_'+t+'_if' ) },
		{ title: '桥接 TAP 与', indent: 2, name: 'vpn_'+t+'_br', type: 'select', options: [
			['br0','LAN (br0)*'],
			['br1','LAN1 (br1)'],
			['br2','LAN2 (br2)'],
			['br3','LAN3 (br3)']
			], value: eval ( 'nvram.vpn_'+t+'_br' ), suffix: ' <small>* 默认<\/small> ' },
		{ title: '协议', name: 'vpn_'+t+'_proto', type: 'select', options: [ ['udp','UDP'], ['tcp-server','TCP'] ], value: eval( 'nvram.vpn_'+t+'_proto' ) },
		{ title: '端口', name: 'vpn_'+t+'_port', type: 'text', maxlen: 5, size: 10, value: eval( 'nvram.vpn_'+t+'_port' ) },
		{ title: '防火墙', name: 'vpn_'+t+'_firewall', type: 'select', options: [ ['auto', '自动'], ['external', '仅外部'], ['custom', '自定义'] ], value: eval( 'nvram.vpn_'+t+'_firewall' ) },
		{ title: '授权模式', name: 'vpn_'+t+'_crypt', type: 'select', options: [ ['tls', 'TLS'], ['secret', '静态密钥'], ['custom', '自定义'] ], value: eval( 'nvram.vpn_'+t+'_crypt' ),
			suffix: '<span id=\''+t+'_custom_crypto_text\'>&nbsp;<small>(必须手动配置...)<\/small><\/span>' },
		{ title: 'HMAC 授权(TLS认证)', name: 'vpn_'+t+'_hmac', type: 'select', options: [ [-1, '关闭'], [2, '双向'], [0, '流入 (0)'], [1, '流出 (1)'] ], value: eval( 'nvram.vpn_'+t+'_hmac' ) },
		{ title: 'Auth digest', name: 'vpn_'+t+'_digest', type: 'select', options: digests, value: eval( 'nvram.vpn_'+t+'_digest' ) },
		{ title: 'VPN 子网/掩码', multi: [
			{ name: 'vpn_'+t+'_sn', type: 'text', maxlen: 15, size: 17, value: eval( 'nvram.vpn_'+t+'_sn' ) },
			{ name: 'vpn_'+t+'_nm', type: 'text', maxlen: 15, size: 17, value: eval( 'nvram.vpn_'+t+'_nm' ) } ] },
		{ title: '客户端地址池', multi: [
			{ name: 'f_vpn_'+t+'_dhcp', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_dhcp' ) != 0, suffix: ' DHCP ' },
			{ name: 'vpn_'+t+'_r1', type: 'text', maxlen: 15, size: 17, value: eval( 'nvram.vpn_'+t+'_r1' ), prefix: '<span id=\''+t+'_range\'>', suffix: '-' },
			{ name: 'vpn_'+t+'_r2', type: 'text', maxlen: 15, size: 17, value: eval( 'nvram.vpn_'+t+'_r2' ), suffix: '<\/span>' } ] },
		{ title: '本地/远程端点地址', multi: [
			{ name: 'vpn_'+t+'_local', type: 'text', maxlen: 15, size: 17, value: eval( 'nvram.vpn_'+t+'_local' ) },
			{ name: 'vpn_'+t+'_remote', type: 'text', maxlen: 15, size: 17, value: eval( 'nvram.vpn_'+t+'_remote' ) } ] }
	]);
	W('<\/div>');
	W('<div id=\''+t+'-advanced\'>');
	createFieldTable('', [
		{ title: '轮询间隔', name: 'vpn_'+t+'_poll', type: 'text', maxlen: 4, size: 5, value: eval( 'nvram.vpn_'+t+'_poll' ), suffix: '&nbsp;<small>(单位分，0为禁用)<\/small>' },
		{ title: '推送 LAN (br0) 到客户端', name: 'f_vpn_'+t+'_plan', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_plan' ) != 0 },
		{ title: '推送 LAN1 (br1) 到客户端', name: 'f_vpn_'+t+'_plan1', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_plan1' ) != 0 },
		{ title: '推送 LAN2 (br2) 到客户端', name: 'f_vpn_'+t+'_plan2', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_plan2' ) != 0 },
		{ title: '推送 LAN3 (br3) 到客户端', name: 'f_vpn_'+t+'_plan3', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_plan3' ) != 0 },
		{ title: 'Direct clients to<br />redirect Internet traffic', name: 'f_vpn_'+t+'_rgw', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_rgw' ) != 0 },
		{ title: 'Cipher Negotiation', name: 'vpn_'+t+'_ncp_enable', type: 'select', options: [[0, 'Disabled'],[1, 'Enabled (with fallback)'],[2, 'Enabled']], value: eval( 'nvram.vpn_'+t+'_ncp_enable' ) },
		{ title: 'Negotiable ciphers', name: 'vpn_'+t+'_ncp_ciphers', type: 'text', size: 50, maxlen: 50, value: eval ( 'nvram.vpn_'+t+'_ncp_ciphers' ) },
		{ title: 'Legacy/fallback cipher', name: 'vpn_'+t+'_cipher', type: 'select', options: ciphers, value: eval( 'nvram.vpn_'+t+'_cipher' ) },
		{ title: '压缩', name: 'vpn_'+t+'_comp', type: 'select', options: [ ['-1', '关闭'], ['no', 'None'], ['yes', 'LZO'], ['adaptive', 'LZO Adaptive'], ['lz4', 'LZ4'], ['lz4-v2', 'LZ4-V2']], value: eval( 'nvram.vpn_'+t+'_comp' ) },
		{ title: 'TLS 重新协商时间', name: 'vpn_'+t+'_reneg', type: 'text', maxlen: 10, size: 7, value: eval( 'nvram.vpn_'+t+'_reneg' ),
			suffix: '&nbsp;<small>(in seconds, -1 for default)<\/small>' },
		{ title: '管理客户端选项', name: 'f_vpn_'+t+'_ccd', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_ccd' ) != 0 },
		{ title: '允许 客户端<->客户端', name: 'f_vpn_'+t+'_c2c', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_c2c' ) != 0 },
		{ title: '仅允许这些客户端', name: 'f_vpn_'+t+'_ccd_excl', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_ccd_excl' ) != 0 },
		{ title: '', suffix: '<div class="tomato-grid" id="table_'+t+'_ccd"><\/div>' },
		{ title: '允许用户名/密码验证', name: 'f_vpn_'+t+'_userpass', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_userpass' ) != 0 },
		{ title: '仅允许下列用户名/密码(无证书)验证', name: 'f_vpn_'+t+'_nocert', type: 'checkbox', value: eval( 'nvram.vpn_'+t+'_nocert' ) != 0 },
		{ title: '', suffix: '<div class="tomato-grid" id="table_'+t+'_users"><\/div>' },
		{ title: '自定义配置', name: 'vpn_'+t+'_custom', type: 'textarea', value: eval( 'nvram.vpn_'+t+'_custom' ) }
	]);
	W('<\/div>');
	W('<div id=\''+t+'-keys\'>');
	W('<p class=\'keyhelp\'>关于生成密钥的帮助,请参考 OpenVPN 的 <a id=\''+t+'-keyhelp\'>教程</a>. 所有的6组key共占用14kB NVRAM，请事先检查是否有足够的剩余空间!<\/p>');
	createFieldTable('', [
		{ title: 'Static Key', name: 'vpn_'+t+'_static', type: 'textarea', value: eval( 'nvram.vpn_'+t+'_static' ),
			prefix: '<div id="'+t+'_static_progress_div" style="display: none;"><p class="keyhelp">Please wait while we\'re generating static key...<img src="spin.gif" alt=""><\/p><\/div>' },
		{ title: '', custom: '<input type="button" value="Generate static key" onclick="updateStaticKey('+(i+1)+')" id="_vpn_keygen_static_'+t+'_button">' },
		{ title: 'Certificate Authority Key', name: 'vpn_'+t+'_ca_key', type: 'textarea', value: eval( 'nvram.vpn_'+t+'_ca_key' ),
			prefix: '<div id="'+t+'_ca_key_progress_div" style="display: none;"><p class="keyhelp">Please wait while we\'re generating CA key...<img src="spin.gif" alt=""><\/p><\/div>' },
		{ title: '', custom: '<div id="'+t+'_ca_key_div_help"><p class="keyhelp">Optional, only used for client certificate generation.<br />Uncrypted (-nodes) private keys are supported.<\/p><\/div>' },
		{ title: 'Certificate Authority', name: 'vpn_'+t+'_ca', type: 'textarea', value: eval( 'nvram.vpn_'+t+'_ca' ),
/* KEYGEN-BEGIN */
			prefix: '<div id="'+t+'_ca_progress_div" style="display: none;"><p class="keyhelp">Please wait while we\'re generating CA certificate...<img src="spin.gif" alt=""><\/p><\/div>'
/* KEYGEN-END */
		},
		{ title: 'Server Certificate', name: 'vpn_'+t+'_crt', type: 'textarea', value: eval( 'nvram.vpn_'+t+'_crt' ),
/* KEYGEN-BEGIN */
			prefix: '<div id="'+t+'_cert_progress_div" style="display: none;"><p class="keyhelp">Please wait while we\'re generating certificate...<img src="spin.gif" alt=""><\/p><\/div>'
/* KEYGEN-END */
		},
		{ title: 'Server Key', name: 'vpn_'+t+'_key', type: 'textarea', value: eval( 'nvram.vpn_'+t+'_key' ),
/* KEYGEN-BEGIN */
			prefix: '<div id="'+t+'_key_progress_div" style="display: none;"><p class="keyhelp">Please wait while we\'re generating key...<img src="spin.gif" alt=""><\/p><\/div>' },
		{ title: '', custom: '<input type="button" value="Generate keys" onclick="generateKeys('+(i+1)+')" id="_vpn_keygen_'+t+'_button">'
/* KEYGEN-END */
		},
		{ title: 'Diffie Hellman parameters', name: 'vpn_'+t+'_dh', type: 'textarea', value: eval( 'nvram.vpn_'+t+'_dh' ),
/* KEYGEN-BEGIN */
			prefix: '<div id="'+t+'_dh_progress_div" style="display: none;"><p class="keyhelp">Please wait while we\'re generating DH parameters...<img src="spin.gif" alt=""><\/p><\/div>' },
		{ title: '', custom: '<input type="button" value="Generate DH Params" onclick="generateDHParams('+(i+1)+')" id="_vpn_dhgen_'+t+'_button">' },
		null,
		{ title: '', custom: '<input type="button" value="Generate client config" onclick="downloadClientConfig('+(i+1)+')" id="_vpn_client_gen_'+t+'_button">',
			suffix: '<div id="'+t+'_gen_progress_div" style="display: none;"><p class="keyhelp">Please wait while your configuration is being generated...<img src="spin.gif" alt=""><\/p><\/div>'
/* KEYGEN-END */
		}
	]);
	W('<\/div>');
	W('<div id=\''+t+'-status\'>');
		W('<div id=\''+t+'-no-status\'><p>服务器没有运行或无法获取状态.<\/p><\/div>');
		W('<div id=\''+t+'-status-content\' style=\'display:none\' class=\'status-content\'>');
			W('<div id=\''+t+'-status-header\' class=\'status-header\'><p>当前的数据 <span id=\''+t+'-status-time\'><\/span>.<\/p><\/div>');
			W('<div id=\''+t+'-status-clients\'><div class=\'section-title\'>客户端列表<\/div><div class="tomato-grid status-table" id="'+t+'-status-clients-table"><\/div><br /><\/div>');
			W('<div id=\''+t+'-status-routing\'><div class=\'section-title\'>当前路由表<\/div><div class="tomato-grid status-table" id="'+t+'-status-routing-table"><\/div><br /><\/div>');
			W('<div id=\''+t+'-status-stats\'><div class=\'section-title\'>综合统计<\/div><div class="tomato-grid status-table" id="'+t+'-status-stats-table"><\/div><br /><\/div>');
			W('<div id=\''+t+'-status-errors\' class=\'error\'><\/div>');
		W('<\/div>');
		W('<div style=\'text-align:right\'><a href=\'javascript:updateStatus('+i+')\'>刷新状态<\/a><\/div>');
	W('<\/div>');
	W('<input type="button" value="' + (eval('vpn'+(i+1)+'up') ? '停止' : '启动') + ' " onclick="toggle(\'vpn'+t+'\', vpn'+(i+1)+'up)" id="_vpn'+t+'_button">');
	W('<\/div>');
}

</script>
</div>

</td></tr>
	<tr><td id="footer" colspan="2">
	<span id="footer-msg"></span>
	<input type="button" value="保存设置" id="save-button" onclick="save()">
	<input type="button" value="取消设置" id="cancel-button" onclick="reloadPage();">
</td></tr>
</table>
</form>
<script type="text/javascript">init();</script>
</body>
</html>