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
            if (pendingImage.status == Image.Error) {
                console.log("img err")
            }
            if (pendingImage.status != Image.Loading) {
                root.replace(pendingImage, {},
                    isFirst ? QQC2.StackView.Immediate : QQC2.StackView.Transition) // don't animate first show
                pendingImage.statusChanged.disconnect(replaceWhenLoaded)
            }
        }
        pendingImage.statusChanged.connect(replaceWhenLoaded)
        replaceWhenLoaded()
    }

    function imgType(url) {
        if (url.endsWith('.png') || url.endsWith('.PNG')) {
            return 'png'
        } else {
            return 'jpeg'
        }
    }

    function imgToB64(url) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = (function f() {
            if (xhr.readyState == 4) { 
                var response = new Uint8Array(xhr.response);
                var raw = "";
                for (var i = 0; i < response.byteLength; i++) {
                    raw += String.fromCharCode(response[i]);
                }
                // Qt.btoa is broken https://stackoverflow.com/questions/53888158/download-and-convert-image-to-data-uri-in-qml
                //FROM https://cdnjs.cloudflare.com/ajax/libs/Base64/1.0.1/base64.js
                function base64Encode (input) {
                    var chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
                    var str = String(input);
                    for (
                        // initialize result and counter
                        var block, charCode, idx = 0, map = chars, output = '';
                        str.charAt(idx | 0) || (map = '=', idx % 1);
                        output += map.charAt(63 & block >> 8 - idx % 1 * 8)
                        ) {
                        charCode = str.charCodeAt(idx += 3/4);
                        if (charCode > 0xFF) {
                            throw new Error("Base64 encoding failed: The string to be encoded contains characters outside of the Latin1 range.");
                        }
                        block = block << 8 | charCode;
                    }
                    return output;
                }
                var image = 'data:image/' + imgType(url) +';base64,' + base64Encode(raw);
                root.currentUrl = image
                 loadImage()
            }
       });
       xhr.open('GET', url, true);
       xhr.setRequestHeader('User-Agent','reddit-wallpaper-plugin');
       xhr.setRequestHeader('accept', 'image/avif,image/webp,*/*');
       xhr.responseType = 'arraybuffer';
       XMLHttpRequest.timeout = 15000
       xhr.send();
    }

    function getReddit(url, callback) {
       var xhr = new XMLHttpRequest();
       xhr.onreadystatechange = (function f() {
            if (xhr.readyState == 4) { callback(xhr);}
       });
       xhr.open('GET', url, true);
       xhr.setRequestHeader('User-Agent','reddit-wallpaper-plugin');
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
                    url = url.replace('imgur.com', 'i.imgur.com')
                    url = url.concat('.jpg')
                }
                root.currentMessage = d["data"]["children"][N]["data"].title
                imgToB64(url)
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
