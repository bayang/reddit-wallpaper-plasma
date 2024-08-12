// Version 2

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

import QtQuick
import QtQuick.Controls as QtControls2
import QtQuick.Layouts
import QtQuick.Window // for Screen
import org.kde.plasma.wallpapers.image as Wallpaper
import org.kde.kquickcontrols as KQuickControls
import org.kde.kquickcontrolsaddons
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: root
    property alias cfg_Color: colorButton.color
    property int cfg_FillMode
    property alias cfg_Blur: blurRadioButton.checked
    property var screen : Screen
    property var screenSize: !!screen.geometry ? Qt.size(screen.geometry.width, screen.geometry.height):  Qt.size(screen.width, screen.height)

    function saveConfig() {
        imageWallpaper.wallpaperModel.commitDeletion();
    }

    Wallpaper.ImageBackend {
        id: imageWallpaper
        targetSize: {
            return Qt.size(root.screenSize.width * root.screen.devicePixelRatio, root.screenSize.height * root.screen.devicePixelRatio)
        }
    }

    Kirigami.FormLayout {
        id: twinFormLayout
        twinFormLayouts: parentLayout
        QtControls2.ComboBox {
            id: resizeComboBox
            Kirigami.FormData.label: i18nd("plasma_wallpaper_org.kde.image", "Positioning:")
            model: [
                {
                    'label': i18nd("plasma_wallpaper_org.kde.image", "Scaled and Cropped"),
                    'fillMode': Image.PreserveAspectCrop
                },
                {
                    'label': i18nd("plasma_wallpaper_org.kde.image","Scaled"),
                    'fillMode': Image.Stretch
                },
                {
                    'label': i18nd("plasma_wallpaper_org.kde.image","Scaled, Keep Proportions"),
                    'fillMode': Image.PreserveAspectFit
                },
                {
                    'label': i18nd("plasma_wallpaper_org.kde.image", "Centered"),
                    'fillMode': Image.Pad
                },
                {
                    'label': i18nd("plasma_wallpaper_org.kde.image","Tiled"),
                    'fillMode': Image.Tile
                }
            ]

            textRole: "label"
            onCurrentIndexChanged: cfg_FillMode = model[currentIndex]["fillMode"]
            Component.onCompleted: setMethod();

            function setMethod() {
                for (var i = 0; i < model.length; i++) {
                    if (model[i]["fillMode"] === wallpaper.configuration.FillMode) {
                        resizeComboBox.currentIndex = i;
                        var tl = model[i]["label"].length;
                    }
                }
            }
        }

        QtControls2.ButtonGroup { id: backgroundGroup }

        QtControls2.RadioButton {
            id: blurRadioButton
            visible: cfg_FillMode === Image.PreserveAspectFit || cfg_FillMode === Image.Pad
            Kirigami.FormData.label: i18nd("plasma_wallpaper_org.kde.image", "Background:")
            text: i18nd("plasma_wallpaper_org.kde.image", "Blur")
            QtControls2.ButtonGroup.group: backgroundGroup
        }

        RowLayout {
            id: colorRow
            visible: cfg_FillMode === Image.PreserveAspectFit || cfg_FillMode === Image.Pad
            QtControls2.RadioButton {
                id: colorRadioButton
                text: i18nd("plasma_wallpaper_org.kde.image", "Solid color")
                checked: !cfg_Blur
                QtControls2.ButtonGroup.group: backgroundGroup
            }
            KQuickControls.ColorButton {
                id: colorButton
                dialogTitle: i18nd("plasma_wallpaper_org.kde.image", "Select Background Color")
            }
        }
    }

    default property alias contentData: contentLayout.data
    Kirigami.FormLayout {
        id: contentLayout
        twinFormLayouts: parentLayout
    }
}
