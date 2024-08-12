
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

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import org.kde.plasma.wallpapers.image as Wallpaper
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

QQC2.StackView {
    id: view
    required property int fillMode
    required property string configColor
    required property bool blur
    required property size sourceSize
    required property string subreddit
    required property int wallpaperDelay
    required property QtObject wallpaperInterface
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
        var isFirst = (view.currentItem == undefined)
        var pendingImage = view.baseImage.createObject(view, {
            "source": view.currentUrl,
            "fillMode": view.fillMode,
            "sourceSize": view.sourceSize,
            "color": view.configColor,
            "blur": view.blur,
            "opacity": isFirst ? 1 : 0,
            "imgTitle": view.currentMessage
        })

        function replaceWhenLoaded() {
            if (pendingImage.status === Image.Error) {
                console.log("img err")
            }
            if (pendingImage.status !== Image.Loading) {
                pendingImage.statusChanged.disconnect(replaceWhenLoaded)
                pendingImage.QQC2.StackView.onActivated.connect(() => {
                    if (Qt.colorEqual(mediaProxy.customColor, "transparent") && Qt.colorEqual(wallpaperInterface.accentColor, "transparent")) {
                        wallpaperInterface.accentColorChanged();
                    } else {
                        wallpaperInterface.accentColor = mediaProxy.customColor;
                    }
                });
                pendingImage.QQC2.StackView.onDeactivated.connect(pendingImage.destroy);
                pendingImage.QQC2.StackView.onRemoved.connect(pendingImage.destroy);
                view.replace(pendingImage, {},
                    isFirst ? QQC2.StackView.Immediate : QQC2.StackView.Transition) // don't animate first show
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
                view.currentUrl = image
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
                view.currentMessage = d["data"]["children"][N]["data"].title
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
        view.currentUrl = "blackscreen.jpg"
        view.currentMessage = msg
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
        y : (view.height * Screen.devicePixelRatio) - 50
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
    Wallpaper.MediaProxy {
        id: mediaProxy

        targetSize: view.sourceSize

        onActualSizeChanged: Qt.callLater(loadImage);
        onColorSchemeChanged: loadImage();
        onSourceFileUpdated: loadImage()
    }
}
