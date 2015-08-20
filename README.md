* Roku proof-of-concept for Charter Communications 
* By Joe Testa 
* Aug 20. 2015 

The zip (charter-demo.zip) is the roku channel that can be "side-loaded" onto a developer-mode enabled roku.
It includes a custom video player with transparent overlay and navigable control menus.

All source code for the channel is included in the 'channel/source' folder. 
The channel uses the m3u8 video stream provided with the assignment and called through the 'json/feed.json' file.

Something I learned is to separate items that need to refresh into their own layer, this was done with the 'nav'
items and I would expand the use of this if i had more time.

I've updated the channel to separate source the code into logical files.