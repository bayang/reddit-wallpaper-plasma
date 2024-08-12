// Version 2

/*
 *  Copyright 2013 Marco Martin <mart@kde.org>
 *  Copyright 2014 Sebastian Kügler <sebas@kde.org>
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
import QtQuick.Controls as QtControls2
import Qt5Compat.GraphicalEffects
import org.kde.kquickcontrolsaddons
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.GridDelegate {
    id: wallpaperDelegate

    property alias color: backgroundRect.color
    property bool selected: (wallpapersGrid.currentIndex === index)
    opacity: model.pendingDeletion ? 0.5 : 1

    text: model.display
    
    toolTip: model.author.length > 0 ? i18ndc("plasma_wallpaper_org.kde.image", "<image> by <author>", "By %1", model.author) : ""

    hoverEnabled: true

    actions: [
        Kirigami.Action {
            icon.name: "document-open-folder"
            tooltip: i18nd("plasma_wallpaper_org.kde.image", "Open Containing Folder")
            onTriggered: imageModel.openContainingFolder(index)
        },
        Kirigami.Action {
            icon.name: "edit-undo"
            visible: model.pendingDeletion
            tooltip: i18nd("plasma_wallpaper_org.kde.image", "Restore wallpaper")
            onTriggered: imageModel.setPendingDeletion(index, !model.pendingDeletion)
        },
        Kirigami.Action {
            icon.name: "edit-delete"
            tooltip: i18nd("plasma_wallpaper_org.kde.image", "Remove Wallpaper")
            visible: model.removable && !model.pendingDeletion && !cfg_Slideshow
            onTriggered: {
                imageModel.setPendingDeletion(index, true);
                if (wallpapersGrid.currentIndex === index) {
                    wallpapersGrid.currentIndex = (index + 1) % wallpapersGrid.count;
                }
            }
        }
    ]

    thumbnail: Rectangle {
        id: backgroundRect
        color: cfg_Color
        anchors.fill: parent

        QIconItem {
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.large
            height: width
            icon: "view-preview"
            visible: !walliePreview.visible
        }

        QPixmapItem {
            id: blurBackgroundSource
            visible: cfg_Blur
            anchors.fill: parent
            smooth: true
            pixmap: model.screenshot
            fillMode: QPixmapItem.PreserveAspectCrop
        }

        FastBlur {
            visible: cfg_Blur
            anchors.fill: parent
            source: blurBackgroundSource
            radius: 4
        }

        QPixmapItem {
            id: walliePreview
            anchors.fill: parent
            visible: model.screenshot !== null
            smooth: true
            pixmap: model.screenshot
            fillMode: {
                if (cfg_FillMode === Image.Stretch) {
                    return QPixmapItem.Stretch;
                } else if (cfg_FillMode === Image.PreserveAspectFit) {
                    return QPixmapItem.PreserveAspectFit;
                } else if (cfg_FillMode === Image.PreserveAspectCrop) {
                    return QPixmapItem.PreserveAspectCrop;
                } else if (cfg_FillMode === Image.Tile) {
                    return QPixmapItem.Tile;
                } else if (cfg_FillMode === Image.TileVertically) {
                    return QPixmapItem.TileVertically;
                } else if (cfg_FillMode === Image.TileHorizontally) {
                    return QPixmapItem.TileHorizontally;
                }
                return QPixmapItem.PreserveAspectFit;
            },
            layer.enabled: cfg_ActiveBlur
            layer.effect: FastBlur {
                anchors.fill: parent
                radius: wallpaperDelegate.hovered ? cfg_BlurRadius : 0
                source: Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: walliePreview
                }
                // animate the blur apparition
                Behavior on radius {
                    NumberAnimation {
                        duration: cfg_AnimationDuration
                    }
                }
            }
        }

        QtControls2.CheckBox {
            visible: cfg_Slideshow
            anchors.right: parent.right
            anchors.top: parent.top
            checked: visible ? model.checked : false
            onToggled: imageWallpaper.toggleSlide(model.path, checked)
        }
    }

    onClicked: {
        cfg_Image = model.path;
        wallpapersGrid.forceActiveFocus();
    }
}
