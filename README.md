# Web-Share

Live Server: http://web-share.herokuapp.com/

Web-Share is a simple web app that allows for sharing web pages from one device to another using only HTTP get methods.
The idea is to open a page that registeres itself as a listener on a channel for new url open requests, and when a request comes, it will open the url either by replacing itself with the new page or open it in a new tab.

## Features
- Public and private (user defined) channels
- Allow for new tab or page replace operation

## API
* /
  * This registeres the listener on the public channel. 
*  /channel/< user defined channel > 
    * Any alphanumeric characters and "/"
    

TODO: finish this
