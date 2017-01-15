'******************************************
'* paint.brs
'* display the screen and dynamic overlay
'******************************************

Sub PaintFullscreenCanvas()
    splash = []
    canvasItems = []
	navItems = []
	
	'Clear previous contents
    m.canvas.ClearLayer(0)
    m.canvas.ClearLayer(1)
    
    if m.previousControl <> m.currentControl
	    ' control changed; clear controls layers '
	    m.canvas.ClearLayer(2)
		m.canvas.ClearLayer(3)
		m.previousControl = m.currentControl
	end if

	' display a custom loading image
    if m.progress < 100
        splash.Push({
            url: "pkg:/images/splash.png"
            TargetRect: m.textRect
        })
    endif

	if m.overlay
		m.currentControl = "overlay"
		' Display overlay with a list of canvasItems
		' Get the canvas size to work with
		canvasRect = m.targetRect
		
		' Set the starting Y value, top of the overlay
		yVal = canvasRect.h - 300
		
		' Get the overall width
		wVal = canvasRect.w
		
		' Set the offsets for the controls
		controlxoff = int( canvasRect.w / 2 ) - 115
		controlyoff = yVal+200
		
		' Set the width of the time bars
		barwidth = int( wVal / 6 )
		
		' Get values from the json feed for the selected title, this should be loaded in a sub
		mytitle = m.feedData.Videos[m.playing].title
		mydesc = m.feedData.Videos[m.playing].desc
		mytag = m.feedData.Videos[m.playing].tag
		myepisode = m.feedData.Videos[m.playing].episode
		
		' Calculate horizontal offset when there is a highlight tag
		font_registry = CreateObject("roFontRegistry")
		font_regular = font_registry.getdefaultfont()
		
		' Need to factor the length to get a good fit - research font behavior
		tagOffset = 110 + int( 2/3 * font_regular.GetOneLineWidth( mytag, 999 ) )
		
		' Calculate horizontal offset for Station, symbols
		stationoff = tagOffset + int( 2/3 * font_regular.GetOneLineWidth( myepisode, 999 ) ) - 30
		
		symbol_1off = stationoff + 125
		symbol_2off = stationoff + 225
		symbol_3off = stationoff + 300
		
		' normally the times would come from the feed or device. hardcode for demo:
		starttime = "11:00 AM"
		endtime = "1:00 PM"
		
		' Calculatation for the time display and for the orange bar
		print m.position " is the current position in seconds"
		' time bars are gray by default
		bar2color = "#FF999999"
		bar3color = "#FF999999"
		
		' the percent of the bar shown orange is m.position divided by half hour (1800 sec)
		' multiply by barwidth to get the width of the orange portion
		' need to add 1 since 0 makes it unlimited width
		worange = 1 + int( barwidth * m.position / 1800 )
		
		print "width of orange on the second time bar is " str(worange)
		
		' Format the current time display
		mymin = int ( m.position / 60 )
		'mysec = m.position mod 60
		if mymin < 30 then
			' Hack to set current time display
			mytime = "11:" + str(30 + mymin).trim()
			
			' horizontal starting point of highlighted time bar
			hloffset = 195+barwidth
			
			' set the placement offset for the current time
			offsettime = 217 + worange + int ( barwidth * 2 / 3 )
		
		else
			' hack for demo - ultimately all bars would be dynamic
			' 2nd bar full orange
			bar2color = "#FFFFA500"

			' set the placement offset for the current time
			offsettime = 217 + worange + int ( barwidth * 2 / 3 )
			
			if mymin > 59
				' 3rd bar full orange
				bar3color = "#FFFFA500"
				' horizontal starting point of highlighted time bar
				hloffset = 195+barwidth*3
				' width of highlight
				worange = worange - (2*barwidth)
			else
				' horizontal starting point of highlighted time bar
				hloffset = 195+barwidth*2
				' width of highlight
				worange = worange - barwidth
			endif
			
			if mymin > 89
				' went past the end, go to beginning?
				' hack the display for now
				mymin = 30
			endif

			if mymin > 39
				mytime = "12:"
			else
				mytime = "12:0"
			endif
			mytime = mytime + str(mymin - 30).trim()
		endif
		
		print "current time to display " + mytime
		
		canvasItems = [
		{ 
            color:"#AA000000"
            TargetRect:{x:0,y:yVal,w:wVal,h:350}
        },
        { 
            Text:mytitle
            TextAttrs:{Color:"#FFFFFFFF", Font:"Medium",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:110,y:yVal+20,w:500,h:60}
        },
		{ 
            Text:mytag
            TextAttrs:{Color:"#FF4169E1", Font:"Small",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:110,y:yVal+75,w:50,h:40}
        },
		{ 
            Text:myepisode
            TextAttrs:{Color:"#FFFFFFFF", Font:"Small",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:tagOffset,y:yVal+75,w:550,h:40}
        },
		{ 
            Text:"001KUSA"
            TextAttrs:{Color:"#FFFFFFFF", Font:"Small",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:stationoff,y:yVal+75,w:150,h:40}
        },
		{
			url: "pkg:/images/check.png"
			TargetRect:{x:symbol_1off,y:yVal+80,w:20,h:22}
		},
		{ 
            Text:"age 14+"
            TextAttrs:{Color:"#FFFFFFFF", Font:"Mini",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:symbol_1off+21,y:yVal+80,w:100,h:20}
        },
		{
			url: "pkg:/images/tomato.png"
			TargetRect:{x:symbol_2off,y:yVal+80,w:17,h:21}
		},
		{ 
            Text:"84%"
            TextAttrs:{Color:"#FFFFFFFF", Font:"Mini",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:symbol_2off+21,y:yVal+80,w:50,h:20}
        },
		{
			url: "pkg:/images/popcorn.png"
			TargetRect:{x:symbol_3off,y:yVal+79,w:14,h:22}
		},
		{ 
            Text:"92%"
            TextAttrs:{Color:"#FFFFFFFF", Font:"Mini",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:symbol_3off+20,y:yVal+80,w:50,h:20}
        },
        { 
            Text:mydesc
            TextAttrs:{Color:"#FFFFFFFF", Font:"Mini",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:110,y:yVal+115,w:wVal-100,h:20}
        },
		{
            Text:starttime
            TextAttrs:{Color:"#FFFFFFFF", Font:"Mini",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:110,y:yVal+155,w:100,h:20}
        },
		{
		    color:"#FFFFA500"
			TargetRect: {x:195, y:yVal+163, w:barwidth-3, h:4}
		},
		{
		    color:bar2color
			TargetRect: {x:195+barwidth, y:yVal+163, w:barwidth-3, h:4}
		},
		{
		    color:bar3color
			TargetRect: {x:195+barwidth*2, y:yVal+163, w:barwidth-3, h:4}
		},
		{
		    color:"#FF999999"
			TargetRect: {x:195+barwidth*3, y:yVal+163, w:barwidth-3, h:4}
		},
		{
            Text:endtime
            TextAttrs:{Color:"#FFFFFFFF", Font:"Mini",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:200+barwidth*4,y:yVal+155,w:100,h:20}
        },
		{
			color:"#FFFFA500"
			TargetRect: {x:hloffset, y:yVal+163, w:worange, h:4}
		},
		{
			color:"#EFFFFFFF"
			TargetRect: {x:hloffset+worange, y:yVal+163, w:2, h:4}
		},		
		{
            Text:mytime
            TextAttrs:{Color:"#FFFFFFFF", Font:"Mini",
            HAlign:"HCenter", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:offsettime,y:yVal+148,w:100,h:12}
        }
		]
	else if m.sideOverlay
		m.currentControl = "sideoverlay"
		' show side overlay
		canvasRect = m.targetRect
		' cover less than half the canvas - xVal is the coverage area
		xVal = int(0.45 * canvasRect.w)
		' Set the starting X value, left edge of the overlay
		xoffset = canvasRect.w - xVal
		
		' Get the overall height
		yVal = canvasRect.h
		
		' copying this stuff
		' Get values from the json feed for the selected title, this should be loaded in a sub
		mytitle = m.feedData.Videos[m.playing].title
		mydesc = m.feedData.Videos[m.playing].desc
		mytag = m.feedData.Videos[m.playing].tag
		myepisode = m.feedData.Videos[m.playing].episode
		
		' Calculate horizontal offset when there is a highlight tag
		font_registry = CreateObject("roFontRegistry")
		font_regular = font_registry.getdefaultfont()
		
		tagOffset = xoffset+40 + int( 2/3 * font_regular.GetOneLineWidth( mytag, 999 ) )
		
		symbol_1off = tagOffset + 125
		symbol_2off = tagOffset + 225
		symbol_3off = tagOffset + 300

		canvasItems = [
		{ 
            color:"#AA000000"
            TargetRect:{x:xoffset,y:0,w:xVal,h:yVal}
        },
		{ 
            Text:mytitle
            TextAttrs:{Color:"#FFFFFFFF", Font:"Medium",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:xoffset+40,y:40,w:250,h:40}
        },
		
		{ 
            Text:mytag
            TextAttrs:{Color:"#FF4169E1", Font:"Small",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:xoffset+40,y:75,w:50,h:40}
        },
		{ 
            Text:myepisode
            TextAttrs:{Color:"#FFFFFFFF", Font:"Small",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:tagOffset,y:75,w:550,h:40}
        },
		{
			url: "pkg:/images/check.png"
			TargetRect:{x:symbol_1off,y:45,w:20,h:22}
		},
		{ 
            Text:"age 14+"
            TextAttrs:{Color:"#FFFFFFFF", Font:"Mini",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:symbol_1off+21,y:45,w:100,h:20}
        },
		{
			url: "pkg:/images/tomato.png"
			TargetRect:{x:symbol_2off,y:45,w:17,h:21}
		},
		{ 
            Text:"84%"
            TextAttrs:{Color:"#FFFFFFFF", Font:"Mini",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:symbol_2off+21,y:45,w:50,h:20}
        },
		{
			url: "pkg:/images/popcorn.png"
			TargetRect:{x:symbol_3off,y:44,w:14,h:22}
		},
		{ 
            Text:"92%"
            TextAttrs:{Color:"#FFFFFFFF", Font:"Mini",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:symbol_3off+20,y:45,w:50,h:20}
        },
        { 
            Text:mydesc
            TextAttrs:{Color:"#FFFFFFFF", Font:"Mini",
            HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
            TargetRect:{x:xoffset+40,y:115,w:xVal-100,h:20}
        },
		]
		' loop over the shows and add to the canvasItems to be displayed
		yTxt = 150
		index = 0
		for each showitem in m.feedData.Videos
		    if index = m.playing
				textColor = "#FF4169E1"
				' Put a box around the selected title
				boxColor = "#FFFFA500"
				canvasItems.Push({
					color:boxColor
					TargetRect: {x:xoffset+100, y:yTxt, w:xVal-100, h:1}
				})
				canvasItems.Push({
					color:boxColor
					TargetRect: {x:xoffset+100, y:yTxt+90, w:xVal-100, h:1}
				})
				canvasItems.Push({
					color:boxColor
					TargetRect: {x:xoffset+100, y:yTxt+1, w:1, h:88}
				})
				canvasItems.Push({
					color:boxColor
					TargetRect: {x:canvasRect.w - 25, y:yTxt+1, w:1, h:88}
				})
		    else
		      textColor = "#FFFFFFFF"
		    endif
    		canvasItems.Push({
    			Text: showitem.title
    			TextAttrs: {color: textColor, font: "Small", HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
    			TargetRect: {x:xoffset+120, y:yTxt, w: 500, h: 100}
    		})
    		yTxt = yTxt + 100
    		index = index + 1
		end for

	else
		m.currentControl = "none"
		' No overlay
		canvasItems = []
	endif
	
	m.canvas.SetLayer(0, { Color: "#00000000", CompositionMode: "Source" })

    if (splash.Count() > 0)
        m.canvas.SetLayer(1, splash)
    end if

    ' now we always use layer 2 for controls, layer 3 for nav buttons '
    m.canvas.SetLayer(2, canvasItems)
	
	' Show the nav controls on the bottom overlay
	if m.overlay
		m.nav()
	endif
	
    canvasItems.Clear()
    splash.Clear()
End Sub