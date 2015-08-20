'***************************************************
'* feed.brs
'*
'* Gets the content data from the included json file
'* In production this would get data from a web service
'*
'********************************************************

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