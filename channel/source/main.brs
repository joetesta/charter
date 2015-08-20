'****************************************************************
'* Example of a custom videoplayer screen with navigable overlay
'* For Charter Communications
'* by Joe Testa, August 2015
'* 
'* This is a basic example that demonstrates how a transparent 
'* overlay can be used for navigation over a playing video.
'*
'* One thing I learned is to separate items that need to 
'* refresh into their own layer, this was done with the 'nav'
'* items and I would expand the use of this if i had more time
'*
'****************************************************************

Sub RunUserInterface()
    o = Setup()
    o.setup()
    o.paint()
    o.eventloop()
End Sub

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
		nav:	   PaintNav
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

Sub EventLoop()
    while true
        msg = wait(0, m.port)
        if msg <> invalid
            if msg.isStatusMessage() and msg.GetMessage() = "startup progress"
                m.paused = false
                print "Raw progress: " + stri(msg.GetIndex())
                progress% = msg.GetIndex() / 10
                if m.progress <> progress%
                    m.progress = progress%
                    m.paint()
                endif

            'Playback progress (in seconds):
            else if msg.isPlaybackPosition()
                m.position = msg.GetIndex()
                print "Playback position: " + stri(m.position)

            else if msg.isRemoteKeyPressed()
                index = msg.GetIndex()
                print "Remote button pressed: " + index.tostr()
                if index = 4  	'<LEFT>
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
                else if index = 2 '<Up>
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
                else if index = 3 '<Down>
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
				else if index = 6 'OK
					if m.sideOverlay
						m.sideOverlay = false					
						if m.playing <> m.playingPrev
                            m.player.SetNext(m.playing)						
							m.player.Play()
							m.playingPrev = m.playing
						endif
					else if m.overlay
						if m.controlState > 0 
							' perform selected control
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
								' Stop / Exit
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
							m.controlState = 1
							m.nav()
						endif
					else
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
