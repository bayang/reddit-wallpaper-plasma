import org.kde.kitemmodels as KItemModels
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.core as PlasmaCore

import org.kde.taskmanager as TaskManager

Item {
	property alias screenGeometry: tasksModel.screenGeometry
	property bool noWindowActive: true
	property bool currentWindowMaximized: false
	property bool isActiveWindowPinned: false

	TaskManager.VirtualDesktopInfo { id: virtualDesktopInfo }
	TaskManager.ActivityInfo { id: activityInfo }
	TaskManager.TasksModel {
		id: tasksModel
		sortMode: TaskManager.TasksModel.SortVirtualDesktop
		groupMode: TaskManager.TasksModel.GroupDisabled

		activity: activityInfo.currentActivity
		virtualDesktop: virtualDesktopInfo.currentDesktop
		screenGeometry: wallpaper.screenGeometry // Warns "Unable to assign [undefined] to QRect" during init, but works thereafter.

		filterByActivity: true
		filterByVirtualDesktop: true
		filterByScreen: true

		onActiveTaskChanged: {
			// console.log('tasksModel.onActiveTaskChanged')
			updateActiveWindowInfo()
		}
		onDataChanged: {
			// console.log('tasksModel.onDataChanged')
			updateActiveWindowInfo()
		}
		Component.onCompleted: {
			// console.log('tasksModel.Component.onCompleted')
			activeWindowModel.sourceModel = tasksModel
		}
	}
	KItemModels.KSortFilterProxyModel {
		id: activeWindowModel
		filterRole: 'IsActive'
		filterRegExp: 'true'
		onDataChanged: {
			// console.log('activeWindowModel.onDataChanged')
			updateActiveWindowInfo()
		}
		onCountChanged: {
			// console.log('activeWindowModel.onCountChanged')
			updateActiveWindowInfo()
		}
	}

	function activeTask() {
		return activeWindowModel.get(0) || {}
	}

	function updateActiveWindowInfo() {
		var actTask = activeTask()
		noWindowActive = activeWindowModel.count === 0 || actTask.IsActive !== true
		currentWindowMaximized = !noWindowActive && actTask.IsMaximized === true
		isActiveWindowPinned = actTask.VirtualDesktop === -1
	}
}
