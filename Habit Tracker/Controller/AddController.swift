//
//  AddController.swift
//  Habit Tracker
//
//  Created by Dennis Münchow on 17.10.23.
//

import UIKit
import CoreData
import UserNotifications

class AddController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var noteField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var itemArray = [Item]()
    var selectedCategory: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        titleField.delegate = self
        noteField.delegate = self
    }
    
    @IBAction func savePressed(_ sender: UIBarButtonItem) {
        guard let titleText = titleField.text, !titleText.isEmpty,
              let noteText = noteField.text else {
            return
        }

        // Add new item
        let targetDate = datePicker.date
        let newItem = Item(context: self.context)
        newItem.title = titleText
        newItem.done = false
        newItem.category = self.selectedCategory
        newItem.date = targetDate
        newItem.note = noteText

        self.itemArray.append(newItem)
        self.saveItems()

        // User Notifications
        let content = UNMutableNotificationContent()
        content.title = titleText
        content.body = noteText
        content.sound = UNNotificationSound.default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: "newTask", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Fehler beim Hinzufügen der Benachrichtigung: \(error.localizedDescription)")
            } else {
                print("Benachrichtigung hinzugefügt")
            }
        }

        // UI Update
        NotificationCenter.default.post(name: Notification.Name("DataSaved"), object: nil)
        dismiss(animated: true, completion: nil)
    }
    

    @IBAction func cancelPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    func saveItems () {
        do {
            try context.save()
        } catch {
            print("Error saving contect \(error)")
        }
    }
}
