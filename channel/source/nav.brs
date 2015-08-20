'****************************************
'* nav.brs 
'* Joe Testa August 2015
'* contains navigation buttons layer
'****************************************

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
		stop: 	"pkg:/images/stop.png",
		rw: 	"pkg:/images/rw.png",
		play: 	"pkg:/images/pause.png",
		ff: 	"pkg:/images/ff.png",
		cc: 	"pkg:/images/cc.png",
		info:	"pkg:/images/info.png"
	}
	
	' if the player is paused, show a play button instead of pause
	if m.paused controls.play = "pkg:/images/play.png"
	
	' if controlState is 0,no nav item is selected, until the user presses 'ok' or a direction other than down
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

Function switchImgOn(img As Object) As Object
  ' Function to show a different image for the currently selected nav item
  ' do a regex on image name to change x.png to x_on.png
  r1 = CreateObject("roRegex", "(.*).png", "")
  img = r1.Replace( img, "\1"+"_on.png")
  return img
End Function