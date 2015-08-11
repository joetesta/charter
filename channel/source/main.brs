'*********************************************
'*
'* Demo by Joe Testa
'* For Tek Systems / Charter Communications
'*
'*

' Channel entry point
Sub RunUserInterface()
    ' create the global object
    o = Setup()
    o.setup()
    o.paint()
    ' listen for events
    o.eventloop()
End Sub

' Create object containing everything needed including videoplayer and canvas ( 'this' = 'm' )
Sub Setup() As Object
    this = {
        port:      CreateObject("roMessagePort")
        progress:  0 'buffering progress
        position:  0 'playback position (in seconds)
        paused:    false 'is the video currently paused?
        feedData:  invalid
        playing:   0
        playingPrev: 0
        playlistSize: 0
        controlState: 0
        canvas:    CreateObject("roImageCanvas") 'user interface
        player:    CreateObject("roVideoPlayer")
        load:      LoadFeed
        setup:     SetupFullscreenCanvas
        paint:     PaintFullscreenCanvas
        nav:       PaintNav
        overlay:  false
        sideOverlay: false
        eventloop: EventLoop
    }

    this.targetRect = this.canvas.GetCanvasRect()
    this.textRect = {x: 520, y: 280, w: 274, h:64} 

    ' Load the video playlist
    this.load()

    ' Setup blank canvas
    this.canvas.SetMessagePort(this.port)
    this.canvas.SetLayer(0, { Color: "#000000" })
    this.canvas.Show()

    this.player.SetMessagePort(this.port)
    this.player.SetLoop(true)
    this.player.SetPositionNotificationPeriod(1)
    this.player.SetDestinationRect(this.targetRect)
    
    this.player.Play()

    return this
End Sub

' Loop to listen for events while the video is playing
Sub EventLoop()
    while true
        msg = wait(0, m.port)
        if msg <> invalid
            if msg.isStatusMessage() and msg.GetMessage() = "startup progress"
                m.paused = false
                print "Raw progress: " + stri(msg.GetIndex())
                progress% = msg.GetIndex() / 10
                ' this can be used to display an incremental "loading" message or image
                if m.progress <> progress%
                    m.progress = progress%
                    m.paint()
                endif

            'Playback progress (in seconds):
            else if msg.isPlaybackPosition()
                m.position = msg.GetIndex()
                print "Playback position: " + stri(m.position)
                ' redraw the time on the overlay every 1 minute
                if m.position mod 60 = 1 m.paint()

            ' if the user pressed a key
            else if msg.isRemoteKeyPressed()
                index = msg.GetIndex()
                print "Remote button pressed: " + index.tostr()
                if index = 4    '<LEFT>
                    print "left pressed, navigate controls"                 
                    if m.sideOverlay
                        m.sideOverlay = false
                        m.overlay = true
                        m.controlState = 4
                        m.paint()
                    else if m.controlState > 0 then
                        ' navigation controls
                        m.controlState = m.controlState - 1
                        if m.controlState = 4
                            m.overlay = false
                            m.controlState = 0
                            m.sideOverlay = true
                            m.paint()
                        else
                            if m.controlState < 1
                                m.controlState = 6
                            endif
                            m.nav()
                        endif
                    else
                        if m.overlay
                            m.controlState = 1
                            m.nav()
                        endif
                    endif  
                else if index = 8 '<REV>
                    if m.position > 60
                        m.position = m.position - 60
                        m.player.Seek(m.position * 1000)
                    else
                        m.position = 0
                        m.player.Seek(0)
                    endif
                else if index = 5 '<RIGHT>
                    print "right pressed, navigate controls"                    
                    if m.sideOverlay
                        m.sideOverlay = false
                        m.overlay = true
                        m.controlState = 5
                        m.paint()
                    else if m.controlState > 0 then
                        ' navigation controls
                        m.controlState = m.controlState + 1
                        if m.controlState = 5
                            m.overlay = false
                            m.controlState = 0
                            m.sideOverlay = true
                            m.paint()
                        else
                            if m.controlState > 6
                                m.controlState = 1
                            endif
                            m.nav()
                        endif
                    else
                        if m.overlay
                            m.controlState = 1
                            m.nav()
                        endif
                    endif   
                else if index = 9 '<FWD>
                    ' keep within 90 minutes for now
                    if m.position < 5340
                        m.position = m.position + 60
                        m.player.Seek(m.position * 1000)
                    endif
                else if index = 2 '<UP>
                    if m.sideOverlay
                        'move up the list
                        m.playing = m.playing - 1
                        if (m.playing < 0)
                            m.playing = m.playlistSize-1
                        endif
                        m.paint()
                    else if m.overlay
                        ' Enable navigation controls
                        if m.controlState = 0 then 
                            m.controlState = 1
                            m.nav() 
                        endif
                    else
                        m.overlay = true
                        m.paint()
                    endif                
                else if index = 3   '<DOWN>
                    if m.sideOverlay
                        ' move down the list
                        m.playing = m.playing + 1
                        if (m.playing > m.playlistSize-1)
                            m.playing = 0
                        endif
                        m.paint()
                    else if m.overlay
                        if m.controlstate = 0 then
                            ' Hide overlay
                            m.overlay = false
                            m.paint()
                        else
                            ' Disable navigation controls
                            m.controlState = 0
                            m.nav()
                        endif
                    endif                
                else if index = 13  '<PAUSE/PLAY>
                    if m.paused m.player.Resume() else m.player.Pause()
                else if index = 6   '<OK>
                    if m.sideOverlay
                        ' play selected title
                        m.sideOverlay = false                   
                        if m.playing <> m.playingPrev
                            m.player.SetNext(m.playing)                     
                            m.player.Play()
                            m.playingPrev = m.playing
                        endif
                    else if m.overlay
                        if m.controlState > 0 
                            ' perform selected nav control
                            if m.controlState = 1
                                ' toggle play / pause
                                if m.paused m.player.Resume() else m.player.Pause()
                                m.nav()
                            else if m.controlState = 2
                                ' hit FF button ' keep within 90 minutes for now
                                if m.position < 5340
                                    m.position = m.position + 60
                                    m.player.Seek(m.position * 1000)
                                endif
                            else if m.controlState = 3
                                ' Enable CC 
                                'captions = player.GetCaptionRenderer()
                                ' does the stream include subtitles?
                            else if m.controlState = 4
                                ' Show Info panel
                                ' open the side overlay
                                m.overlay = false
                                m.controlState = 0
                                m.sideOverlay = true
                                m.paint()
                            else if m.controlState = 5
                                ' Stop / Exit - leave channel
                                exit while
                            else if m.controlState = 6
                                ' hit Rewind button
                                if m.position > 60
                                    m.position = m.position - 60
                                    m.player.Seek(m.position * 1000)
                                else
                                    m.position = 0
                                    m.player.Seek(0)
                                endif
                            endif
                        else
                            ' activate nav controls, highlight pause / play
                            m.controlState = 1
                            m.nav()
                        endif
                    else
                        ' bring up the overlay
                        m.overlay = true
                        m.paint()
                    endif
                endif

            else if msg.isPaused()
                m.paused = true
                m.paint()

            else if msg.isResumed()
                m.paused = false
                m.paint()

            endif
        endif
    end while
End Sub

Sub SetupFullscreenCanvas()
    m.canvas.AllowUpdates(false)
    m.paint()
    m.canvas.AllowUpdates(true)
End Sub

Sub PaintNav()
    ' Updates the nav controls layer
    navItems = []
        
    ' get the canvas area
    canvasRect = m.targetRect
        
    ' Set the offsets for the controls
    controlxoff = int( canvasRect.w / 2 ) - 22
    controlyoff = canvasRect.h  - 100
    
    ' Set up the Controls navigation
    controls = {
        stop:   "pkg:/images/stop.png",
        rw:     "pkg:/images/rw.png",
        play:   "pkg:/images/pause.png",
        ff:     "pkg:/images/ff.png",
        cc:     "pkg:/images/cc.png",
        info:   "pkg:/images/info.png"
    }
    
    ' if the player is paused, show a play button instead of pause
    if m.paused controls.play = "pkg:/images/play.png"
    
    if m.controlState > 0 then
        print "changing highlighted controls image"
        ' the player controls are active, show highlighted one
        if m.controlState = 1 controls.play = switchImgOn(controls.play)
        if m.controlState = 2 controls.ff = switchImgOn(controls.ff)
        if m.controlState = 3 controls.cc = switchImgOn(controls.cc)
        if m.controlState = 4 controls.info = switchImgOn(controls.info)
        if m.controlState = 5 controls.stop = switchImgOn(controls.stop)
        if m.controlState = 6 controls.rw = switchImgOn(controls.rw)
    endif
    
    navItems = [
        {
            url: "pkg:/images/menu.png"
            TargetRect:{x:controlxoff-510, y:controlyoff, w:100,h:36}
        },
        {
            url: controls.stop
            TargetRect:{x:controlxoff-300, y:controlyoff, w:45,h:45}
        },
        {
            url: controls.rw
            TargetRect:{x:controlxoff-150, y:controlyoff, w:45,h:45}
        },
        {
            url: controls.play
            TargetRect:{x:controlxoff, y:controlyoff, w:45,h:45}
        },
        {
            url: controls.ff
            TargetRect:{x:controlxoff+150, y:controlyoff, w:45,h:45}
        },
        {
            url: controls.cc
            TargetRect:{x:controlxoff+300, y:controlyoff, w:45,h:45}
        },
        {
            url: controls.info
            TargetRect:{x:controlxoff+350, y:controlyoff, w:45,h:45}
        },
        {
            url: "pkg:/images/guide.png"
            TargetRect:{x:controlxoff+425, y:controlyoff, w:100,h:36}
        }
    ]

    if (m.progress < 100)
        m.canvas.ClearLayer(3)
        m.canvas.SetLayer(3, navItems)
    else
        m.canvas.ClearLayer(2)
        m.canvas.SetLayer(2, navItems)
    endif
    
    navItems.Clear()
End Sub

Sub PaintFullscreenCanvas()
    splash = []
    canvasItems = []
    
    'Clear previous contents
    m.canvas.ClearLayer(0)
    m.canvas.ClearLayer(1)
    m.canvas.ClearLayer(2)
    m.canvas.ClearLayer(3)

    ' display a custom loading image
    if m.progress < 100
        splash.Push({
            url: "pkg:/images/splash.png"
            TargetRect: m.textRect
        })
    endif

    if m.overlay
        ' Display overlay with a list of dynamic canvasItems
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
        
        ' Get values from the json feed for the selected show
        myshow   = m.feedData.Videos[m.playing]
        mytitle  = myshow.title
        mydesc   = myshow.desc
        mytag    = myshow.tag
        myepisode = myshow.episode
        
        ' Use Font tools to calculate horizontal offset when there is a highlight tag
        font_registry = CreateObject("roFontRegistry")
        font_regular = font_registry.getdefaultfont()
        
        ' Need to factor the length to get a good fit
        tagOffset = 110 + int( 2/3 * font_regular.GetOneLineWidth( mytag, 999 ) )
        
        ' Calculate horizontal offset for Station & 3 symbols
        stationoff = tagOffset + int( 2/3 * font_regular.GetOneLineWidth( myepisode, 999 ) ) - 30
        symbol_1off = stationoff + 125
        symbol_2off = stationoff + 225
        symbol_3off = stationoff + 300
        
        ' normally the times would come from the feed or device. hardcode for demo:
        starttime = "11:00 AM"
        endtime = "1:00 PM"
        
        ' Calculatation for the time display and for the orange bar
        print m.position " is the current position in seconds"
        ' Set time bars gray by default
        bar2color = "#FF999999"
        bar3color = "#FF999999"
        
        ' the width of the bar highlighted orange is barwidth times m.position divided by half hour (1800 sec)
        ' 0 makes it unlimited width so use 1 in that case:
        if m.position
            worange = int( barwidth * m.position / 1800 )
        else
            worange = 1
        end if
        
        print "width of orange on the second time bar is " str(worange)
        
        ' Format the current time display
        mymin = int ( m.position / 60 )

        if mymin < 30 then
            ' Set current time display
            mytime = "11:" + str(30 + mymin).trim()
            
            ' horizontal starting point of highlighted time bar
            hloffset = 195+barwidth
            
            ' set the placement offset for the current time
            offsettime = 217 + worange + int ( barwidth * 2 / 3 )
        
        else
            ' ultimately all bars will be dynamic
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
                ' limit the display for now
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

        ' show side overlay
        canvasRect = m.targetRect
        ' cover less than half the canvas - xVal is the coverage area
        xVal = int(0.45 * canvasRect.w)
        ' Set the starting X value, left edge of the overlay
        xoffset = canvasRect.w - xVal
        
        ' Get the overall height
        yVal = canvasRect.h

        ' Get values from the json feed for the selected title
        myshow   = m.feedData.Videos[m.playing]
        mytitle  = myshow.title
        mydesc   = myshow.desc
        mytag    = myshow.tag
        myepisode = myshow.episode
        
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
        for each show in m.feedData.Videos
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
                Text: show.title
                TextAttrs: {color: textColor, font: "Small", HAlign:"Left", VAlign:"VCenter",
            Direction:"LeftToRight"}
                TargetRect: {x:xoffset+120, y:yTxt, w: 500, h: 100}
            })
            yTxt = yTxt + 100
            index = index + 1
        end for

    else
        ' No overlay
        canvasItems = []
    endif
    
    m.canvas.SetLayer(0, { Color: "#00000000", CompositionMode: "Source" })
    if (splash.Count() > 0)
        m.canvas.SetLayer(1, splash)
        m.canvas.SetLayer(2, canvasItems)
    else
        m.canvas.SetLayer(1, canvasItems)
    endif
    
    ' Show the nav controls on the bottom overlay
    if m.overlay
        m.nav()
    endif
    
    canvasItems.Clear()
    splash.Clear()
End Sub

' read the included json file to get data about content
Function LoadFeed() as void
    jsonAsString = ReadAsciiFile("pkg:/json/feed.json")
    m.feedData = ParseJSON(jsonAsString)
    m.playlistSize = m.feedData.Videos.Count()
    ? "playlist size is " m.playlistSize
    contentList = []
    for each video in m.feedData.Videos
        contentList.Push({
            Stream: { url: video.url }
            StreamFormat: "hls"
        })
    end for    
    m.player.SetContentList(contentList)    
End Function

' regex to add '_on' to the image filename for highighted nav
Function switchImgOn(img As Object) As Object
  ' do a regex on image name to change x.png to x_on.png
  r1 = CreateObject("roRegex", "(.*).png", "")
  img = r1.Replace( img, "\1"+"_on.png")
  return img
End Function
