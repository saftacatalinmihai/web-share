# Web-Share

Live Server: http://web-share.herokuapp.com/

Web-Share is a simple web app that allows for opening web pages from one device on another using only HTTP get methods.
The idea is to open a page that registeres itself as a listener on a channel for new url open requests, and when a request comes, from another device, it will open the url from the request.
It's built on top of Mojolicious with web-sockets.

## Synopsys
 - On a device open: http://web-share.heroku.com/channel/demo_channel
 - On a different device open: http://web-share.heroku.com/open?ch=demo_channel&url=teslamotors.com

## Features
- Public and private (user defined) channels
- Allow for new tab or page replace operation


 
## API
* GET /
  * This registeres the listener on the public channel.
* GET /channel/{user defined channel}
    * Registeres the listener on the specified channel 
        * Any alphanumeric characters and "/" are alowed in the user defined channel
* GET /open
    * Sends the page open request to all listeners on a channel
    * Prameters
        * url - the requested url to open on the recieving listeners
        * ch ( optional ) - channel to send the request to
        * target ( optional ) - specifies how to open the requested url. 
          - The options for target are: new_tab|iframe|replace
          
## Issues:
 - The default open requests the target new_tab, which is usually blocked on most browsers by default, or they ask the users weather to accept opening the page in a new tab. If the users accepts, new requests are ok
