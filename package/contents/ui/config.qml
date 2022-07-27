/*
 *  Copyright 2013 Marco Martin <mart@kde.org>
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
import QtQuick.Controls 1.0 as QtControls
import QtQuick.Controls 2.3 as QtControls2
import QtQuick.Layouts 1.0
import QtQuick.Window 2.0 // for Screen
import org.kde.plasma.core 2.0 as Plasmacore
import org.kde.plasma.wallpapers.image 2.0 as Wallpaper
import org.kde.kquickcontrols 2.0 as KQuickControls
import org.kde.kquickcontrolsaddons 2.0
import org.kde.kconfig 1.0 // for KAuthorized
import org.kde.draganddrop 2.0 as DragDrop
import org.kde.kcm 1.1 as KCM
import org.kde.kirigami 2.5 as Kirigami

ImageConfigPage {
    id: root

    property int cfg_WallpaperDelay: 60
    property string cfg_Subreddit: "earthporn wallpaper"
    property string cfg_SubredditSection: "top"
    property string cfg_SubredditSectionTime: "month"
    property string cfg_PreferOrientation: "landscape"
    property bool cfg_ShowPostTitle: false
    property bool cfg_AllowNSFW: false

    QtControls2.TextField {
        id: subredditInput
        text: cfg_Subreddit
        Kirigami.FormData.label: i18n("Subreddits:")
        onTextChanged: {
            cfg_Subreddit = text;
        }
    }
    QtControls2.ComboBox {
        id: subredditSectionDropdown
        Kirigami.FormData.label: i18n("Section:")
        model: [
            {
                'label': i18n("Hot"),
                'value': "hot"
            },
            {
                'label': i18n("New"),
                'value': "new"
            },
            {
                'label': i18n("Rising"),
                'value': "rising"
            },
            {
                'label': i18n("Controversial"),
                'value': "controversial"
            },
            {
                'label': i18n("Top"),
                'value': "top"
            },
            {
                'label': i18n("Gilded"),
                'value': "gilded"
            }
        ]
        textRole: "label"
        onCurrentIndexChanged: cfg_SubredditSection = model[currentIndex].value
        Component.onCompleted: {
            for (var i = 0; i < model.length; i++) {
                if (model[i].value === wallpaper.configuration.SubredditSection) {
                    subredditSectionDropdown.currentIndex = i;
                }
            }
        }
    }
    QtControls2.ComboBox {
        id: subredditSectionTimeDropdown
        Kirigami.FormData.label: i18n("Find images in last:")
        model: [
            {
                'label': i18n("Hour"),
                'value': "hour"
            },
            {
                'label': i18n("Day"),
                'value': "day"
            },
            {
                'label': i18n("Week"),
                'value': "week"
            },
            {
                'label': i18n("Month"),
                'value': "month"
            },
            {
                'label': i18n("Year"),
                'value': "year"
            },
            {
                'label': i18n("Forever"),
                'value': "forever"
            }
        ]
        textRole: "label"
        onCurrentIndexChanged: cfg_SubredditSectionTime = model[currentIndex].value
        Component.onCompleted: {
            for (var i = 0; i < model.length; i++) {
                if (model[i].value === wallpaper.configuration.SubredditSectionTime) {
                    subredditSectionTimeDropdown.currentIndex = i;
                }
            }
        }
    }
    QtControls2.ComboBox {
        id: preferOrientationDropdown
        Kirigami.FormData.label: i18n("Prefer Image Orientation:")
        model: [
            {
                'label': i18n("Any"),
                'value': "any"
            },
            {
                'label': i18n("Landscape"),
                'value': "landscape"
            },
            {
                'label': i18n("Portrait"),
                'value': "portrait"
            }
        ]
        textRole: "label"
        onCurrentIndexChanged: cfg_PreferOrientation = model[currentIndex].value
        Component.onCompleted: {
            for (var i = 0; i < model.length; i++) {
                if (model[i].value === wallpaper.configuration.PreferOrientation) {
                    preferOrientationDropdown.currentIndex = i;
                }
            }
        }
    }
    QtControls2.SpinBox {
        id: delaySpinBox
        value: cfg_WallpaperDelay
        onValueChanged: cfg_WallpaperDelay = value
        Kirigami.FormData.label: i18n("Wallpaper Timer (min):")
        stepSize: 1
        from: 1
        to: 50000
        editable: true
    }
    QtControls2.CheckBox {
        Kirigami.FormData.label: i18n("Show Post Title:")
        checked: cfg_ShowPostTitle
        onToggled: {
            cfg_ShowPostTitle = checked;
        }
    }
    QtControls2.CheckBox {
        Kirigami.FormData.label: i18n("Allow NSFW:")
        checked: cfg_AllowNSFW
        onToggled: {
            cfg_AllowNSFW = checked;
        }
    }
    QtControls2.Button {
        text: "Reroll Wallpaper"
        onClicked: {
            wallpaper.configuration.RefetchSignal = !wallpaper.configuration.RefetchSignal;
        }
    }
}
