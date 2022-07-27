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

    readonly property bool refetchSignal: wallpaper.configuration.RefetchSignal
    readonly property int fillMode: wallpaper.configuration.FillMode
    readonly property string configColor: wallpaper.configuration.Color
    readonly property bool blur: wallpaper.configuration.Blur
    readonly property size sourceSize: Qt.size(root.width * Screen.devicePixelRatio, root.height * Screen.devicePixelRatio)
    readonly property string subreddit: wallpaper.configuration.Subreddit
    readonly property string subredditSection: wallpaper.configuration.SubredditSection
    readonly property string subredditSectionTime: wallpaper.configuration.SubredditSectionTime
    readonly property string preferOrientation: wallpaper.configuration.PreferOrientation
    readonly property bool showPostTitle: wallpaper.configuration.ShowPostTitle
    readonly property bool allowNSFW: wallpaper.configuration.AllowNSFW
    readonly property int wallpaperDelay: wallpaper.configuration.WallpaperDelay
    property int errorTimerDelay: 20000
    property string currentUrl: "blackscreen.jpg"
    property string currentMessage: ""
    property string lastSubreddit: ""
    property bool hasError: false

    Timer {
        id: myTimer
        interval: wallpaperDelay * 60 * 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            getRedditPosts();
        }
    }

    Timer {
        id: retryOnErrorTimer
        interval: errorTimerDelay
        repeat: false
        triggeredOnStart: false
        onTriggered: {
            getRedditPosts();
        }
    }

    onRefetchSignalChanged: {
        log("got refetch signal in main");
        myTimer.restart();
    }
    onFillModeChanged: Qt.callLater(loadImage)
    onConfigColorChanged: Qt.callLater(loadImage)
    onBlurChanged: Qt.callLater(loadImage)
    onWidthChanged: Qt.callLater(loadImage)
    onHeightChanged: Qt.callLater(loadImage)
    onSubredditChanged: {
        log("subreddit changed in main " + subreddit);
        myTimer.restart();
    }
    onSubredditSectionChanged: {
        log("subreddit section changed in main " + subredditSection);
        myTimer.restart();
    }
    onSubredditSectionTimeChanged: {
        log("subreddit section time changed in main " + subredditSectionTime);
        myTimer.restart();
    }
    onPreferOrientationChanged: {
        log("prefer orientation changed in main " + preferOrientation);
        myTimer.restart();
    }
    onShowPostTitleChanged: {
        log("show post title changed in main " + showPostTitle);
    }
    onAllowNSFWChanged: {
        log("allow NSFW changed in main " + allowNSFW);
        myTimer.restart();
    }
    onWallpaperDelayChanged: {
        log("delay changed in main " + wallpaperDelay);
        myTimer.restart();
    }

    function log(...args) {
        console.log("reddit wallpaper:", ...args);
    }

    function loadImage() {
        var isFirst = (root.currentItem == undefined);
        var pendingImage = root.baseImage.createObject(root, {
            "source": root.currentUrl,
            "fillMode": root.fillMode,
            "sourceSize": root.sourceSize,
            "color": root.configColor,
            "blur": root.blur,
            "opacity": isFirst ? 1 : 0,
            "imgTitle": root.currentMessage,
            "playing": true,
            "cache": true,
        })

        function replaceWhenLoaded() {
            if (pendingImage.status !== Image.Loading) {
                root.replace(pendingImage, {},
                    isFirst ? QQC2.StackView.Immediate : QQC2.StackView.Transition); // don't animate first show
                pendingImage.statusChanged.disconnect(replaceWhenLoaded);
            }
        }
        pendingImage.statusChanged.connect(replaceWhenLoaded);
        replaceWhenLoaded();
    }

    function getRedditPosts() {
        const allSubreddits = (subreddit || '').toLowerCase().trim().split(/[ ,]+/).map(sub => sub.replace(/^r\//, ''));
        let candidateSubs = allSubreddits.filter(sub => sub !== lastSubreddit);
        if (candidateSubs.length === 0) {
            candidateSubs = allSubreddits;
        }
        const sub = candidateSubs[Math.floor(Math.random() * candidateSubs.length)] || '';
        lastSubreddit = sub;
        fetchRedditData(sub).then(pickImage).catch(e => {
            log(e);
            setError(e);
            loadImage();
        });
    }

    function fetchRedditData(sub) {
        log("fetching new wallpaper! Using sub: " + sub);
        return new Promise((res, rej) => {
            const url = `https://www.reddit.com/r/${sub}/${subredditSection}.json?sort=top&t=${subredditSectionTime}&limit=100`;
            log('using url: ' + url);
            const xhr = new XMLHttpRequest();
            xhr.onload = () => {
                if (!xhr.responseText) {;
                    return rej("connection failed");
                }
                let data = {};
                try {
                    data = JSON.parse(xhr.responseText);
                } catch (e) {
                    return rej("couldnt parse json");
                }
                res(data);
            };
            xhr.open('GET', url);
            xhr.setRequestHeader('User-Agent','reddit-wallpaper-kde-plugin');
            xhr.timeout = 15000;
            xhr.send();
        });
    }

    function get(obj, path, def) {
        const pathParts = path.split('.');
        let current = obj;
        for (let x = 0; x < pathParts.length && current; x++) {
            current = current[pathParts[x]];
        }
        return current !== undefined ? current : def;
    }

    function filterImages(imageObjs) {
        const domainMapFunctions = {
            'https://i.redd.it': a => a,
            'https://i.imgur.com': a => a,
            'https://imgur.com': url => url.replace('https://imgur.com/', 'https://i.imgur.com/') + '.jpg'
        };
        const allowedDomains = Object.keys(domainMapFunctions);
        const preFilteredImages = imageObjs.filter(c => {
            const data = c.data || {};
            const url = (data.url || '').replace('http:', 'https:');
            const allowed = allowedDomains.some(d => {
                if (url.startsWith(d)) {
                    data.url = domainMapFunctions[d](url);
                    return true;
                }
                return false;
            });
            return allowed && (allowNSFW || !data.over_18);
        });
        let filteredImages = preFilteredImages;
        if (preferOrientation === 'landscape') {
            filteredImages = filteredImages.filter(c => {
                const imageInfo = get(c, 'data.preview.images.0.source');
                return imageInfo && imageInfo.width >= imageInfo.height;
            });
        } else if (preferOrientation === 'portrait') {
            filteredImages = filteredImages.filter(c => {
                const imageInfo = get(c, 'data.preview.images.0.source');
                return imageInfo && imageInfo.width <= imageInfo.height;
            });
        }
        if (filteredImages.length === 0) {
            filteredImages = preFilteredImages;
        }
        return filteredImages;
    }

    function pickImage(d) {
        const allImages = d.data && d.data.children || [];
        if (allImages.length === 0) {
            log("Failed to fetch. Status: " + d.error);
            setError("404, 403 or empty");
            loadImage();
            return;
        }
        let filteredImages = filterImages(allImages);
        if (filteredImages.length === 0) {
            setError("No images found. Bad subreddit? Only NSFW?");
            loadImage();
            return;
        }

        const imageObj = filteredImages[Math.floor(Math.random() * filteredImages.length)] || {};
        if (imageObj.data && imageObj.data.preview) {
            let url = imageObj.data.url;
            if (url.indexOf("imgur.com") !== -1 && url.indexOf("i.imgur.com") === -1) {
                url = url.replace('imgur.com', 'i.imgur.com') + '.jpg';
            }
            log("using image: " + url);
            root.currentUrl = url;
            root.currentMessage = imageObj.data.title;
            root.hasError = false;
            errorTimerDelay = 20000;
            retryOnErrorTimer.stop();
            loadImage();
        } else {
            log("no image");
            setError("No images found. Bad subreddit? Only NSFW?");
            loadImage();
        }
    }

    function setError(msg) {
        root.currentUrl = "blackscreen.jpg";
        root.currentMessage = msg;
        root.hasError = true;
        errorTimerDelay *= 1.5;
        retryOnErrorTimer.start();
    }

    property Component baseImage: Component {
        AnimatedImage {
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
                width: root.width * Screen.devicePixelRatio - 100
                horizontalAlignment: Text.AlignRight
                style: Text.Outline
                styleColor: "#000000"
                font.pixelSize: 12
                text: imgTitle
                visible: showPostTitle || root.hasError
                // hardcoded positioning sucks
                // we need a way to know how much space user toolbars take
                // to avoid positioning the label behind
                y: (root.height * Screen.devicePixelRatio) - 100
                x: 0
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
