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

WallpaperItem {
    id: root

    ImageStackView {
        id: imageView
        anchors.fill: parent

        fillMode: root.configuration.FillMode
        configColor: root.configuration.Color
        blur: root.configuration.Blur
        subreddit: root.configuration.Subreddit
        sourceSize: Qt.size(root.width * Screen.devicePixelRatio, root.height * Screen.devicePixelRatio)
        wallpaperInterface: root
        wallpaperDelay: root.configuration.WallpaperDelay
    }

}
