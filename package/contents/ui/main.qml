/*
 *  Copyright 2013 Marco Martin <mart@kde.org>
 *  Copyright 2014 Sebastian Kügler <sebas@kde.org>
 *  Copyright 2014 Kai Uwe Broulik <kde@privat.broulik.de>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.5
import QtQuick.Controls 2.1 as QQC2
import QtQuick.Window 2.2
import QtGraphicalEffects 1.0
import org.kde.plasma.wallpapers.image 2.0 as Wallpaper
import org.kde.plasma.core 2.0 as PlasmaCore

QQC2.StackView {
    id: root

    readonly property int fillMode: wallpaper.configuration.FillMode
    readonly property string configColor: wallpaper.configuration.Color
    readonly property bool blur: wallpaper.configuration.Blur
    readonly property size sourceSize: Qt.size(root.width * Screen.devicePixelRatio, root.height * Screen.devicePixelRatio)
    readonly property string subreddit: wallpaper.configuration.Subreddit
    readonly property int wallpaperDelay: wallpaper.configuration.WallpaperDelay
    property int errorTimerDelay: 20000
    property string currentUrl: "blackscreen.jpg"
    property string currentMessage: ""

    Timer {
        id : myTimer
        interval: wallpaperDelay * 60 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            getReddit("https://www.reddit.com/r/"+subreddit+"/new.json?limit=100",callback)
        }
    }

    Timer {
        id : retryOnErrorTimer
        interval: errorTimerDelay
        repeat: false
        triggeredOnStart: false
        onTriggered: {
            getReddit("https://www.reddit.com/r/"+subreddit+"/new.json?limit=100",callback)
        }
    }

    onFillModeChanged: Qt.callLater(loadImage)
    onConfigColorChanged: Qt.callLater(loadImage)
    onBlurChanged: Qt.callLater(loadImage)
    onWidthChanged: Qt.callLater(loadImage)
    onHeightChanged: Qt.callLater(loadImage)
    onSubredditChanged : {
        console.log("subreddit changed in main " + subreddit)
        myTimer.restart()
    }
    onWallpaperDelayChanged: {
        console.log("delay changed in main " + wallpaperDelay)
        myTimer.restart()
    }

    function loadImage() {
        var isFirst = (root.currentItem == undefined)
        var pendingImage = root.baseImage.createObject(root, {
            "source": root.currentUrl,
            "fillMode": root.fillMode,
            "sourceSize": root.sourceSize,
            "color": root.configColor,
            "blur": root.blur,
            "opacity": isFirst ? 1 : 0,
            "imgTitle": root.currentMessage
        })

        function replaceWhenLoaded() {
            if (pendingImage.status != Image.Loading) {
                root.replace(pendingImage, {},
                    isFirst ? QQC2.StackView.Immediate : QQC2.StackView.Transition) // don't animate first show
                pendingImage.statusChanged.disconnect(replaceWhenLoaded)
            }
        }
        pendingImage.statusChanged.connect(replaceWhenLoaded)
        replaceWhenLoaded()
    }

    function getReddit(url, callback) {
       var xhr = new XMLHttpRequest();
       
       xhr.onreadystatechange = (function f() {
            if (xhr.readyState == 4) { callback(xhr);}
       });
       xhr.open('GET', url, true);
       xhr.setRequestHeader('User-Agent','reddit-wallpaper-kde-plugin');
       XMLHttpRequest.timeout = 15000
       xhr.send();
   }

    function callback(x){
        if (x.responseText) {
          var d = JSON.parse(x.responseText);
          if  (d["error"] == "404" || d["data"]["children"] == ""){
              console.log("404 or empty")
              setError("404 or empty")
            loadImage()
          }else if (d["error"] == "403"){
              console.log("private subreddit")
              setError("connection failed, private subreddit")
            loadImage()
          }else{
            var N=Math.floor(Math.random()*d.data.children.length)
            if (d["data"]["children"][N]["data"]["preview"]){
                var url = d["data"]["children"][N]["data"].url
                if (url.indexOf("imgur.com") != -1 
                    && url.indexOf("i.imgur.com") == -1) {
                    console.log("imgur " + url)
                    url = url.replace('imgur.com', 'i.imgur.com')
                    url = url.concat('.jpg')
                    console.log("imgur " + url)
                }
                root.currentUrl = url
                root.currentMessage = d["data"]["children"][N]["data"].title
                loadImage()
            }else{
                console.log("no image")
                setError("no image could be fetched")
                loadImage()
            }
          }
        }else{
            console.log("connection failed")
            setError("connection failed")
            loadImage()
        }
    }

    function setError(msg) {
        root.currentUrl = "blackscreen.jpg"
        root.currentMessage = msg
        errorTimerDelay *= 1.5
        retryOnErrorTimer.start()
    }

    property Component baseImage: Component {
        Image {
            id: mainImage

            property alias color: backgroundColor.color
            property bool blur: false
            property string imgTitle: ""

            asynchronous: true
            cache: false
            autoTransform: true
            z: -1

            QQC2.StackView.onRemoved: destroy()

            Rectangle {
                id: backgroundColor
                anchors.fill: parent
                visible: mainImage.status === Image.Ready && !blurLoader.active
                z: -2
            }

            Loader {
                id: blurLoader
                anchors.fill: parent
                z: -3
                active: mainImage.blur && (mainImage.fillMode === Image.PreserveAspectFit || mainImage.fillMode === Image.Pad)
                sourceComponent: Item {
                    Image {
                        id: blurSource
                        anchors.fill: parent
                        asynchronous: true
                        cache: false
                        autoTransform: true
                        fillMode: Image.PreserveAspectCrop
                        source: mainImage.source
                        sourceSize: mainImage.sourceSize
                        visible: false // will be rendered by the blur
                    }

                    GaussianBlur {
                        id: blurEffect
                        anchors.fill: parent
                        source: blurSource
                        radius: 32
                        samples: 65
                        visible: blurSource.status === Image.Ready
                    }
                }
            }
    QQC2.Label {
        id: imageTitle
        color: "white"
        font.pixelSize: 12
        text : imgTitle
        // hardcoded positioning sucks
        // we need a way to know how much space user toolbars take
        // to avoid positioning the label behind
        y : (root.height * Screen.devicePixelRatio) - 50
        x: 30
    }
        }
    }

    replaceEnter: Transition {
        OpacityAnimator {
            from: 0
            to: 1
            duration: wallpaper.configuration.TransitionAnimationDuration
        }
    }
    // Keep the old image around till the new one is fully faded in
    // If we fade both at the same time you can see the background behind glimpse through
    replaceExit: Transition {
        PauseAnimation {
            duration: wallpaper.configuration.TransitionAnimationDuration
        }
    }
}
