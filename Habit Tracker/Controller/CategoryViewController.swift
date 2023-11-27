//
//  ViewController.swift
//  Habit Tracker
//
//  Created by Dennis Münchow on 14.10.23.
//

import UIKit
import CoreData
import UserNotifications


class CategoryViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var healthButton: UIButton!
    @IBOutlet weak var relationshipsButton: UIButton!
    @IBOutlet weak var skillsButton: UIButton!
    @IBOutlet weak var careerButton: UIButton!
    @IBOutlet weak var gesundheitAnzahl: UILabel!
    @IBOutlet weak var beziehungenAnzahl: UILabel!
    @IBOutlet weak var skillsAnzahl: UILabel!
    @IBOutlet weak var karriereAnzahl: UILabel!
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    private let segueToItems = "goToItems"
    var itemArray = [Item]()
    var selectedCategory: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        setupUI()
        //updateCategoryCounts()
        gesundheitAnzahl.text = "07"
        beziehungenAnzahl.text = "26"
        skillsAnzahl.text = "15"
        karriereAnzahl.text = "12"
            
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateCategoryController), name: Notification.Name("updateCategoryController"), object: nil)
        loadItems()
    }
    
    //MARK: - Setup & Update
    
    private func setupUI() {
        let buttons = [healthButton, relationshipsButton, skillsButton, careerButton]
        buttons.forEach { button in
            button?.layer.cornerRadius = 10
        }
        tableView.backgroundColor = UIColor.clear
    }
    
    // Update Item-Anzahl je Kategorie
    func countItemsWithCategory(category: String) -> String {
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "category == %@", category)
        
        do {
            let itemCount = try context.count(for: fetchRequest)
            return String(itemCount)
        } catch {
            return "Fehler beim Zählen der Einträge: \(error.localizedDescription)"
        }
    }
    private func updateCategoryCounts() {
        let categories = ["Gesundheit", "Beziehungen", "Skills", "Karriere"]
    
        for category in categories {
            let count = countItemsWithCategory(category: category)
            setCategoryCountLabel(category: category, count: count)
        }
    }
    private func setCategoryCountLabel(category: String, count: String) {
        switch category {
        case "Gesundheit":
            gesundheitAnzahl.text = count
        case "Beziehungen":
            beziehungenAnzahl.text = count
        case "Skills":
            skillsAnzahl.text = count
        case "Karriere":
            karriereAnzahl.text = count
        default:
            break
        }
    }

    // Update-Funktion
    @objc func updateCategoryController() {
        loadItems()
        updateCategoryCounts()
    }
    
    //MARK: - Segue
    
    @IBAction func healthPressed(_ sender: UIButton) {
        selectedCategory = "Gesundheit"
        performSegue(withIdentifier: segueToItems, sender: self)
    }
    @IBAction func relationshipsPressed(_ sender: UIButton) {
        selectedCategory = "Beziehungen"
        performSegue(withIdentifier: segueToItems, sender: self)
    }
    @IBAction func skillsPressed(_ sender: UIButton) {
        selectedCategory = "Skills"
        performSegue(withIdentifier: segueToItems, sender: self)
    }
    @IBAction func careerPressed(_ sender: UIButton) {
        selectedCategory = "Karriere"
        performSegue(withIdentifier: segueToItems, sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueToItems {
            if let ItemController = segue.destination as? ItemController {
                ItemController.selectedCategory = selectedCategory
            }
        }
    }
    
    // MARK: - Model Mamipulation Methods

    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
        do {
            itemArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        tableView.reloadData()
    }
    func saveItems () {
        do {
            try context.save()
        } catch {
            print("Error saving contect \(error)")
        }
        tableView.reloadData()
    }
}

//MARK: - TableView

extension CategoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        saveItems()
        tableView.deselectRow(at: indexPath, animated: true)}
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        itemArray.sort { $0.date! < $1.date! }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath)
        let item = itemArray[indexPath.row]
        
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done == true ? .checkmark : .none
        
        let date = item.date
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MMM, HH:mm"
        
        cell.detailTextLabel?.text = item.category! + " | " + formatter.string(from: date!)
        
        return cell
    }
    
    // Swipe Delete-Funktion
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // delete
        let delete = UIContextualAction(style: .normal, title: "Delete") { (action, view, completionHandler) in
            self.context.delete(self.itemArray[indexPath.row])
            self.itemArray.remove(at: indexPath.row)
            tableView.reloadData()
            self.saveItems()
            completionHandler(true)
            self.updateCategoryCounts()
        }
        delete.image = UIImage(systemName: "trash")
        delete.backgroundColor = .red
        let swipe = UISwipeActionsConfiguration(actions: [delete])
        return swipe
    }
}


