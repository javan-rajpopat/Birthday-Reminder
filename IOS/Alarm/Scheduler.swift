import Foundation
import UIKit


class Scheduler : AlarmSchedulerDelegate
{
    var alarmModel: Alarms = Alarms()
    func setupNotificationSettings() -> UIUserNotificationSettings {
        // Specify the notification types.
        let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert, UIUserNotificationType.sound]
        
        // Specify the notification actions.
        let stopAction = UIMutableUserNotificationAction()
        stopAction.identifier = Id.stopIdentifier
        stopAction.title = "OK"
        stopAction.activationMode = UIUserNotificationActivationMode.background
        stopAction.isDestructive = false
        stopAction.isAuthenticationRequired = false
        
        let actionsArray = [UIUserNotificationAction](arrayLiteral: stopAction)
        
        let actionsArrayMinimal = [UIUserNotificationAction](arrayLiteral: stopAction)
        
        // Specify the category related to the above actions.
        let alarmCategory = UIMutableUserNotificationCategory()
        alarmCategory.identifier = "myAlarmCategory"
        alarmCategory.setActions(actionsArray, for: .default)
        alarmCategory.setActions(actionsArrayMinimal, for: .minimal)
        
        
        let categoriesForSettings = Set(arrayLiteral: alarmCategory)
        // Register the notification settings.
        let newNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: categoriesForSettings)
        UIApplication.shared.registerUserNotificationSettings(newNotificationSettings)
        return newNotificationSettings
    }
    
    private func correctDate(_ date: Date) -> Date
    {
        var correctedDate: Date = Date()
        let calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        let now = Date()
        let flags: NSCalendar.Unit = [NSCalendar.Unit.weekday, NSCalendar.Unit.weekdayOrdinal, NSCalendar.Unit.day]
        let dateComponents = (calendar as NSCalendar).components(flags, from: date)
            if date < now {
                correctedDate = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.day, value: 0, to: date, options:.matchStrictly)!
            }
            else { //later
                correctedDate = date
            }
            return correctedDate
    }
    
    public static func correctSecondComponent(date: Date, calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian))->Date {
        let second = calendar.component(.second, from: date)
        let d = (calendar as NSCalendar).date(byAdding: NSCalendar.Unit.second, value: -second, to: date, options:.matchStrictly)!
        return d
    }
    
    internal func setNotificationWithDate(_ date: Date, soundName: String, index: Int) {
        let AlarmNotification: UILocalNotification = UILocalNotification()
        AlarmNotification.alertBody = "Wake Up!"
        AlarmNotification.alertAction = "Open App"
        AlarmNotification.category = "myAlarmCategory"
        AlarmNotification.soundName = soundName + ".mp3"
        AlarmNotification.timeZone = TimeZone.current
        AlarmNotification.userInfo = [ "index": index, "soundName": soundName]
        
        let datesForNotification = correctDate(date)
        
        
        syncAlarmModel()
        
        
        alarmModel.alarms[index].date = datesForNotification
        AlarmNotification.fireDate = datesForNotification
        UIApplication.shared.scheduleLocalNotification(AlarmNotification)
        
        setupNotificationSettings()
        
    }
    
    func reSchedule() {
        //cancel all and register all is often more convenient
        UIApplication.shared.cancelAllLocalNotifications()
        syncAlarmModel()
        for i in 0..<alarmModel.count{
            let alarm = alarmModel.alarms[i]
            if alarm.enabled {
                setNotificationWithDate(alarm.date as Date,  soundName: alarm.mediaLabel, index: i)
            }
        }
    }

    // workaround for some situation that alarm model is not setting properly (when app on background or not launched)
    func checkNotification() {
        alarmModel = Alarms()
        let notifications = UIApplication.shared.scheduledLocalNotifications
        if notifications!.isEmpty {
            for i in 0..<alarmModel.count {
                alarmModel.alarms[i].enabled = false
            }
        }
        else {
            for (i, alarm) in alarmModel.alarms.enumerated() {
                var isOutDated = true
                for n in notifications! {
                    if alarm.date >= n.fireDate! {
                        isOutDated = false
                    }
                }
                if isOutDated {
                    alarmModel.alarms[i].enabled = false
                }
            }
        }
    }
    
    private func syncAlarmModel() {
        alarmModel = Alarms()
    }

    
    private func minFireDateWithIndex(notifications: [UILocalNotification]) -> (Date, Int)? {
        if notifications.isEmpty {
            return nil
        }
        var minIndex = -1
        var minDate: Date = notifications.first!.fireDate!
        for n in notifications {
            let index = n.userInfo!["index"] as! Int
            if(n.fireDate! <= minDate) {
                minDate = n.fireDate!
                minIndex = index
            }
        }
        return (minDate, minIndex)
    }
}
