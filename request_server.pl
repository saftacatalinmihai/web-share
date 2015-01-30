#!/usr/bin/env perl
#===============================================================================
#
#         FILE: request_server.pl
#
#        USAGE: ./request_server.pl
#
#  DESCRIPTION:
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Safta Catalin Mihai ,
# ORGANIZATION:
#      VERSION: 1.0
#      CREATED: 12/14/2014 06:57:25 PM
#     REVISION: ---
#===============================================================================

use 5.14.1;
use strict;
use warnings;
use utf8;
use Mojolicious::Lite;
use Data::Printer;

my $websocket_listeners = {};

sub send_json_listeners{
	my ($channel, $hash) =  @_;

	if (exists $websocket_listeners->{$channel}) {
		for my $l (keys %{$websocket_listeners->{$channel}} )  {
			$websocket_listeners->{$channel}->{$l}->send({json =>$hash});
		}
	}
}

sub get_listener_count {
	my $channel = shift;
	return 0 if not defined $websocket_listeners->{$channel};
	my $listener_count = keys %{$websocket_listeners->{$channel}};
	return $listener_count;
}

sub refresh_listener_count_on_channel{
	my $channel = shift;
	send_json_listeners($channel, {listener_count => get_listener_count($channel)});
}

get '/' => sub {
	my $c = shift;
	$c->stash(ch => 'public');
	$c->render(template => 'index', format => 'html');
};

get '/channel/*ch' => sub {
		my $c = shift;
		$c->stash(listener_count => get_listener_count($c->param('ch')) );
		$c->render(template => 'index', format => 'html' );
};

websocket '/listener/register' => sub {
	my $c= shift;
	return $c->redirect_to("/listener/register/public");
};

websocket '/listener/register/*channel' => sub {
	my $c = shift;
	my $channel = $c->param("channel");

	# Remove inactivity timeout
	$c->inactivity_timeout(0);

  	# Opened
  	$c->app->log->debug("Client connected on channel [$channel]");

	# Save the tx to send messeges to it later
	my $id = "$c->tx";
	$websocket_listeners->{$channel}->{$id} = $c->tx;

	$c->on(json => sub {
		my ($c, $hash) = @_;
		$c->app->log->debug("Recieved: $hash->{msg}");

		# keepalive
		$c->send({json => {msg => "pong"}}) if $hash->{msg} eq 'ping';

		# Update all existing listeners to the new listener count on channel
		if ( $hash->{msg} =~ /refresh_channel/) {
			$c->app->log->debug("Sending listener count to listeners on channel [$channel]");
			refresh_listener_count_on_channel($channel);
		}
	});

	# Delete the reference to that listener and refresh the remaining ones with the new count
	$c->on(finish => sub {
			$c->app->log->debug("Client disconected from channel [$channel]");
			delete $websocket_listeners->{$channel}->{$id};
			refresh_listener_count_on_channel($channel);
		});
};

get '/open' => sub {
		my $c = shift;
		my $ch = $c->param('ch') ? $c->param('ch') : "public";
		my $url_param = defined $c->param('url') ? $c->param('url') :  ${\$c->param()};

		my $page_url_target = $c->param("target") ?  $c->param("target") : "new_tab";
		$page_url_target = 'new_tab' if ( !($page_url_target  =~ /^(new_tab|iframe|replace)$/));

		$c->app->log->debug("Open request for url: [$url_param], on channel: [$ch], taget: [$page_url_target]");
		send_json_listeners($ch, {url => $url_param, page_url_target => $page_url_target});
		$c->render(text => $url_param);
};

app->start;

__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
	<head>
		<title>Web-Share</title>
		<style>
			body {
				position: relative;
				margin: 0;
				height: 100%;
				padding-top: 100px;
			}
			iframe {
				width: 100%;
				height: 100%;
				border: none;
			}
			.info {
				position: absolute;
				top: 0;
				left: 0;
				width: 100%;
				height: 100px;
			}
		</style>
	</head>
	<body>

		<div class='info'>
			<p>Listener registered, awaiting requests...</p>
			<p> Channel:  <%= $ch %></p>
			<p id='listener_count'> Listeners on channel: <%= $listener_count %> </p>
 		</div>
		<iframe src=""></iframe>
		<script>

			var ws = new WebSocket('<%= url_for('listenerregister')->to_abs %>/<%= $ch %>');

			var set_callbacks = function() {
				// Incoming messages
				ws.onmessage = function(event) {

					var msg = JSON.parse(event.data).msg;
					var url = JSON.parse(event.data).url;
					var listener_count = JSON.parse(event.data).listener_count;
					var page_url_target = JSON.parse(event.data).page_url_target;


					if ( (typeof listener_count !== 'undefined')) {
						 document.getElementById("listener_count").innerHTML = "Listeners on channel: " + listener_count
					}

					if (typeof msg !== 'undefined') {
						if ( msg === "pong" ) {
							console.log('pong recieved');
						}
					}
					if ( typeof url !== 'undefined') {
						// console.log(url);
						// console.log(page_url_target);
						document.body.innerHTML += url + '<br/>';
						var href = "http://"+url;

						switch (page_url_target) {
							case "new_tab":
								window.open(href,  "_blank");
								break;
							case "replace":
								window.location.href = href;
								break;
							case "iframe":
								document.getElementsByTagName('iframe')[0].src = href;
								break;
						}
					}
				};

				// Keepalive the server connection to this listener
				window.setInterval(function () { ws.send(JSON.stringify({msg: 'ping'})) }, 50000);
				//window.setInterval(function () { ws.send(JSON.stringify({msg: 'ping'}))}, 3000);

				ws.onopen=function(){
					ws.send(JSON.stringify({msg: 'refresh_channel'}));
					// console.log("sent refresh request");
				};

				ws.onclose=function(){
					// console.log("Closed");
					var retry_ws_connect_with_timout = function( retrys_left ) {
						// console.log("Retries left: " + retrys_left);
						if (retrys_left != 0 ) {
							// console.log("Attempting reconnect");
							ws = new WebSocket('<%= url_for('listenerregister')->to_abs %>/<%= $ch %>');
							set_callbacks(ws);
							if (ws.readyState == 0 || ws.readyState == 1 ) {
								// console.log("Connection reestablished");
								return;
							} else {
								setTimeout(function(){
									retry_ws_connect_with_timout(retrys_left - 1);
								},3000);
							}
						}
					};
					retry_ws_connect_with_timout(10);
					return;
				}
			};
			set_callbacks(ws);
		</script>

	</body>
</html>
