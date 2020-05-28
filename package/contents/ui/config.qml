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
import QtQuick.Controls 2.1 as QtControls2
import QtQuick.Layouts 1.0
import QtQuick.Window 2.2 // for Screen
//We need units from it
import org.kde.plasma.core 2.0 as Plasmacore
import org.kde.plasma.wallpapers.image 2.0 as Wallpaper
import org.kde.kquickcontrols 2.0 as KQuickControls
import org.kde.kquickcontrolsaddons 2.0
import org.kde.kconfig 1.0 // for KAuthorized
import org.kde.draganddrop 2.0 as DragDrop
import org.kde.kcm 1.1 as KCM
import org.kde.kirigami 2.0 as Kirigami

ImageConfigPage {
    id: root

    property int cfg_WallpaperDelay: 1440
    property string cfg_Subreddit: "EarthPorn"

    Column {
        id: pluginSpecificColumn
        spacing: units.largeSpacing / 2
        Kirigami.FormData.label: i18n("Reddit config:")
        QtControls2.Label {
            text: i18n("Source subreddit : ")
        }
        QtControls2.TextField {
            id: subredditInput
            text: cfg_Subreddit
            onTextChanged: {
                cfg_Subreddit = text
            }
        }
        QtControls2.Label {
            text: i18n("Delay between changes (in minutes) : ")
        }
        QtControls2.SpinBox {
            id: delaySpinBox
            value: cfg_WallpaperDelay
            onValueChanged: cfg_WallpaperDelay = value
            stepSize: 1
            from: 1
            to: 50000
            editable: true
        }
    }
}
